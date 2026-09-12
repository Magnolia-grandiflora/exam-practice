import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as p;

import 'markdown_exporter.dart' show ExportLabels;

class PdfPrintService {
  const PdfPrintService();

  static const int _minimumMarginBoxEngineMajor = 131;

  static const _engineCandidates = [
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
  ];

  bool get isSupported => Platform.isWindows;

  Future<File> printPack(
    Directory packDirectory, {
    ExportLabels labels = const ExportLabels(),
    List<String>? onlyFiles,
    String? outputName,
  }) async {
    if (!isSupported) {
      throw UnsupportedError('打印为 PDF 目前仅支持 Windows 版');
    }
    final engine = _findEngine();
    if (engine == null) {
      throw StateError('未找到 Microsoft Edge 或 Google Chrome，无法打印 PDF');
    }
    final manifest = _readManifest(packDirectory);
    final title = (manifest['title'] as String?)?.trim();
    final output = _uniqueFile(
      packDirectory,
      '${_safeFileName(
        title?.isNotEmpty == true ? title! : packDirectory.path,
        labels.paperFileName,
      )}.pdf',
      baseName: outputName,
    );
    final temporary = await Directory.systemTemp.createTemp(
      'personal-exam-pdf-',
    );
    try {
      final profile = Directory(p.join(temporary.path, 'browser-profile'))
        ..createSync(recursive: true);
      await _requireMarginBoxSupport(engine);
      final htmlFile = File(p.join(temporary.path, 'paper.html'));
      await htmlFile.writeAsString(
        buildPrintHtml(packDirectory, onlyFiles: onlyFiles),
        encoding: utf8,
        flush: true,
      );
      final url =
          'file:///${htmlFile.path.replaceAll('\\', '/').replaceAll(' ', '%20')}';
      var result = await _runEngine(engine, [
        '--headless=new',
        '--disable-gpu',
        '--no-pdf-header-footer',
        '--user-data-dir=${profile.path}',
        '--print-to-pdf=${output.path}',
        url,
      ]);
      if (!await _waitForPdf(output)) {
        result = await _runEngine(engine, [
          '--headless',
          '--disable-gpu',
          '--user-data-dir=${profile.path}',
          '--print-to-pdf-no-header',
          '--print-to-pdf=${output.path}',
          url,
        ]);
      }
      if (!await _waitForPdf(output)) {
        final detail = result.stderr.toString().trim();
        throw StateError(
          detail.isEmpty
              ? '浏览器未生成 PDF 文件（退出代码：${result.exitCode}；引擎：$engine）'
              : '浏览器打印失败（退出代码：${result.exitCode}；引擎：$engine）：$detail',
        );
      }
      return output;
    } finally {
      try {
        await temporary.delete(recursive: true);
      } on FileSystemException {
        // Edge 偶尔会稍晚释放临时配置文件；不影响已经生成的 PDF。
      }
    }
  }

  void retainOnlyPdf(Directory packDirectory, File pdf) {
    retainOnlyPdfs(packDirectory, [pdf]);
  }

  /// 只保留 [pdfs] 列出的 PDF，删除导出目录中的其余文件（pdfOnly 模式）。
  /// A3 排版会生成试卷与答题卡两个 PDF，需一并保留。
  void retainOnlyPdfs(Directory packDirectory, List<File> pdfs) {
    final pack = p.normalize(p.absolute(packDirectory.path));
    final keep = pdfs
        .map((file) => p.normalize(p.absolute(file.path)))
        .toSet();
    for (final pdf in pdfs) {
      if (!pdf.existsSync() || !p.equals(p.dirname(pdf.path), pack)) {
        throw StateError('PDF 不在当前试卷导出目录中，已停止清理');
      }
    }
    for (final entity in packDirectory.listSync()) {
      if (entity is File && keep.contains(p.normalize(p.absolute(entity.path)))) {
        continue;
      }
      entity.deleteSync(recursive: true);
    }
  }

  @visibleForTesting
  String buildPrintHtml(
    Directory packDirectory, {
    List<String>? onlyFiles,
  }) {
    final manifest = _readManifest(packDirectory);
    final names =
        (manifest['markdown_files'] as List?)?.whereType<String>().toList() ??
        const [];
    final wanted = onlyFiles?.toSet();
    final markdownFiles = names
        .where((name) => wanted == null || wanted.contains(name))
        .map((name) => File(p.join(packDirectory.path, name)))
        .where((file) => file.existsSync())
        .toList();
    if (markdownFiles.isEmpty) {
      throw const FormatException('试卷包中没有可打印的 Markdown 文件');
    }
    final cssFile = File(p.join(packDirectory.path, 'exam-print.css'));
    final css = cssFile.existsSync() ? cssFile.readAsStringSync() : '';
    final articles = <String>[];
    for (final file in markdownFiles) {
      final source = file.readAsStringSync(encoding: utf8);
      final frontmatter = _parseFrontmatter(source);
      final markdown = _embedImages(
        _preprocess(frontmatter.body),
        packDirectory,
      );
      final body = _wrapQuestions(
        markdownToHtml(markdown, extensionSet: ExtensionSet.gitHubFlavored),
      );
      final classes = <String>{
        'exam-print',
        ...frontmatter.cssClasses,
      }.join(' ');
      articles.add('<article class="$classes">$body</article>');
    }
    final title = const HtmlEscape(
      HtmlEscapeMode.element,
    ).convert((manifest['title'] as String?) ?? packDirectory.path);
    return '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<title>$title</title>
<style>
$css
$_fallbackCss
</style>
</head>
<body>
${articles.join('\n')}
</body>
</html>
''';
  }

  String _wrapQuestions(String html) {
    final question = RegExp(
      r'(<h2\b[^>]*>[\s\S]*?</h2>)([\s\S]*?)(?=<h2\b|$)',
      caseSensitive: false,
    );
    return html.replaceAllMapped(question, (match) {
      return '<section class="exam-question" data-print-question="true">'
          '${match.group(1)}${match.group(2)}</section>';
    });
  }

  Future<void> _requireMarginBoxSupport(String engine) async {
    // Edge/Chrome headless --version is silent on some Windows installations.
    // The PE product version is the engine version used by the executable.
    final escapedPath = engine.replaceAll("'", "''");
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      "(Get-Item -LiteralPath '$escapedPath').VersionInfo.ProductVersion",
    ]);
    final output = '${result.stdout}\n${result.stderr}';
    if (!supportsPageMarginBoxesVersion(output)) {
      throw StateError(
        'PDF 打印需要 Chromium $_minimumMarginBoxEngineMajor 或更高版本以输出页码；'
        '当前引擎版本无法确认或版本过低：${output.trim().isEmpty ? engine : output.trim()}',
      );
    }
  }

  @visibleForTesting
  static bool supportsPageMarginBoxesVersion(String versionOutput) {
    final match = RegExp(
      r'\b(\d+)\.\d+(?:\.\d+){1,2}\b',
    ).firstMatch(versionOutput);
    if (match == null) return false;
    final major = int.tryParse(match.group(1) ?? '');
    return major != null && major >= _minimumMarginBoxEngineMajor;
  }

  Map<String, dynamic> _readManifest(Directory directory) {
    final file = File(p.join(directory.path, 'manifest.json'));
    if (!file.existsSync()) {
      throw const FormatException('试卷包缺少 manifest.json');
    }
    final value = jsonDecode(file.readAsStringSync(encoding: utf8));
    if (value is! Map<String, dynamic>) {
      throw const FormatException('manifest.json 格式无效');
    }
    return value;
  }

  _Frontmatter _parseFrontmatter(String source) {
    final match = RegExp(
      r'^---\s*\r?\n([\s\S]*?)\r?\n---\s*\r?\n?',
    ).firstMatch(source);
    if (match == null) return _Frontmatter(const [], source);
    final classes = <String>[];
    for (final line in (match.group(1) ?? '').split(RegExp(r'\r?\n'))) {
      if (!line.trimLeft().startsWith('cssclasses:')) continue;
      final value = line.split(':').skip(1).join(':').trim();
      classes.addAll(
        value
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    }
    return _Frontmatter(classes, source.substring(match.end));
  }

  String _preprocess(String source) {
    final lines = <String>[];
    final heading = RegExp(r'^(##\s+.*?)\s*<p>(.*?)</p>\s*$');
    final option = RegExp(r'^[A-E]\.\s');
    var inQuestion = false;
    for (final line in source.split(RegExp(r'\r?\n'))) {
      final match = heading.firstMatch(line);
      if (match != null) {
        inQuestion = true;
        lines.addAll([match.group(1)!, '', match.group(2)!]);
      } else if (line.startsWith('## ')) {
        inQuestion = true;
        lines.add(line);
      } else if (inQuestion && option.hasMatch(line)) {
        if (lines.isNotEmpty && lines.last.trim().isNotEmpty) lines.add('');
        lines.add(line);
      } else {
        lines.add(line);
      }
    }
    return lines.join('\n');
  }

  String _embedImages(String source, Directory baseDirectory) {
    String dataUri(String rawPath) {
      var normalized = rawPath.trim().replaceAll('\\', '/');
      try {
        normalized = Uri.decodeComponent(normalized);
      } on ArgumentError {
        // 题目或文件名中可能包含普通百分号，不应把它当成 URI 编码。
      }
      final file = File(p.join(baseDirectory.path, normalized));
      if (!file.existsSync()) return rawPath;
      final extension = p.extension(file.path).toLowerCase();
      final mime = switch (extension) {
        '.jpg' || '.jpeg' => 'image/jpeg',
        '.gif' => 'image/gif',
        '.webp' => 'image/webp',
        '.svg' => 'image/svg+xml',
        _ => 'image/png',
      };
      return 'data:$mime;base64,${base64Encode(file.readAsBytesSync())}';
    }

    var output = source.replaceAllMapped(
      RegExp(r'!\[\[([^\]]+)\]\]'),
      (match) => '![](${dataUri(match.group(1)!)})',
    );
    output = output.replaceAllMapped(
      RegExp(
        r'''(<img\s[^>]*?src=["'])([^"']+)(["'][^>]*>)''',
        caseSensitive: false,
      ),
      (match) =>
          '${match.group(1)}${dataUri(match.group(2)!)}${match.group(3)}',
    );
    output = output.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\(([^)\s]+)\)'),
      (match) => '![${match.group(1)}](${dataUri(match.group(2)!)})',
    );
    return output;
  }

  String? _findEngine() {
    final configured = Platform.environment['PAPER_PDF_ENGINE'];
    if (configured != null && File(configured).existsSync()) return configured;
    for (final candidate in _engineCandidates) {
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  Future<ProcessResult> _runEngine(
    String engine,
    List<String> arguments,
  ) async {
    final process = await Process.start(engine, arguments);
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        process.kill();
        throw TimeoutException('浏览器打印 PDF 超时');
      },
    );
    return ProcessResult(
      process.pid,
      exitCode,
      await stdoutFuture,
      await stderrFuture,
    );
  }

  Future<bool> _waitForPdf(File file) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (file.existsSync() && file.lengthSync() > 0) return true;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  File _uniqueFile(
    Directory directory,
    String name, {
    String? baseName,
  }) {
    final base = p.basenameWithoutExtension(
      baseName == null || baseName.trim().isEmpty ? name : '$baseName.pdf',
    );
    var candidate = File(p.join(directory.path, '$base.pdf'));
    var sequence = 2;
    while (candidate.existsSync()) {
      candidate = File(
        p.join(
          directory.path,
          '${base}_${sequence.toString().padLeft(2, '0')}.pdf',
        ),
      );
      sequence++;
    }
    return candidate;
  }

  String _safeFileName(String value, String fallback) {
    final name = p
        .basename(value)
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .trim();
    return name.isEmpty ? fallback : name;
  }

  static const _fallbackCss = '''
@page {
  size: A4 portrait;
  margin: 9mm 9mm 12mm;
  @bottom-center {
    content: counter(page) " / " counter(pages);
    font-family: "Microsoft YaHei", "SimSun", sans-serif;
    font-size: 8pt;
    color: #444;
  }
}
@page a3paper {
  size: A3 portrait;
  margin: 12mm 12mm 14mm;
  @bottom-center {
    content: counter(page) " / " counter(pages);
    font-family: "Microsoft YaHei", "SimSun", sans-serif;
    font-size: 8pt;
    color: #444;
  }
}
.exam-paper-a3 { page: a3paper; column-count: 2; column-gap: 10mm; }
.exam-paper-a3 h1 { column-span: all; }
body { margin: 0; color: #000; font-family: "Microsoft YaHei", "SimSun", sans-serif; }
article.exam-print + article.exam-print { break-before: page; }
.exam-print { font-size: 10.5pt; line-height: 1.45; }
.exam-print h1 { font-size: 15pt; text-align: center; margin: 0 0 2mm; }
.exam-print > blockquote p { text-align: center; }
.exam-print > blockquote {
  margin: 0 0 4mm;
  padding: 0;
  border: 0;
  text-align: center;
  color: #333;
}
blockquote {
  margin: 1.5mm 0;
  padding: 0 3mm;
  border-left: 0.8mm solid #999;
  color: #333;
}
/* 按真实试卷习惯整题保持在同一页：任何题目都不跨页（自然涵盖偶数页跨奇数页），
   仅当单题高度超过整页内容区时才允许浏览器自然分段。 */
.exam-question { break-inside: avoid; }
.exam-print h2 {
  font-size: 10.5pt;
  font-weight: 400;
  margin: 3.5mm 0 1.5mm;
  text-align: justify;
  break-after: avoid;
}
.exam-print p { margin: 0 0 1.5mm; text-align: justify; orphans: 2; widows: 2; }
.exam-question p { padding-left: 7mm; }
img { max-width: 100%; }
table { border-collapse: collapse; }
th, td { border: 0.2mm solid #222; padding: 1mm; text-align: center; }
.exam-qa-space {
  height: 24mm;
  margin: 1mm 0 0 7mm;
  background: repeating-linear-gradient(
    to bottom,
    transparent 0,
    transparent calc(8mm - 0.25mm),
    #bbb calc(8mm - 0.25mm),
    #bbb 8mm
  );
}
''';
}

class _Frontmatter {
  const _Frontmatter(this.cssClasses, this.body);
  final List<String> cssClasses;
  final String body;
}
