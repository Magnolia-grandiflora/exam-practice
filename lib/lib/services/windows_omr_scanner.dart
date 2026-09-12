import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/coded_exceptions.dart';

typedef WindowsOmrProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class WindowsOmrQuestion {
  const WindowsOmrQuestion({
    required this.number,
    required this.selected,
    required this.confidence,
    required this.bubbleQuad,
  });

  final int number;
  final Set<String> selected;
  final double confidence;
  final Map<String, List<List<double>>> bubbleQuad;
}

class WindowsOmrResult {
  const WindowsOmrResult({
    required this.sourceWidth,
    required this.sourceHeight,
    required this.pageQuad,
    required this.questions,
  });

  final int sourceWidth;
  final int sourceHeight;
  final List<List<double>> pageQuad;
  final List<WindowsOmrQuestion> questions;
}

/// Runs only the packaged paper OMR bridge.  It deliberately has no fallback
/// recognizer so a Windows scan cannot silently use a different sheet format.
class WindowsOmrScanner {
  WindowsOmrScanner({WindowsOmrProcessRunner? runner, this.executable})
    : _runner = runner ?? _run,
      _usesDefaultRunner = runner == null;

  final WindowsOmrProcessRunner _runner;
  final bool _usesDefaultRunner;
  final File? executable;

  static const Duration defaultTimeout = Duration(seconds: 45);

  Future<WindowsOmrResult> check({
    required File image,
    required File template,
    required int expectedQuestions,
    Duration timeout = defaultTimeout,
  }) async {
    if (!Platform.isWindows) {
      throw CodedUnsupportedError(
        'omr.platform.unsupported',
        '答题卡阅卷仅支持 Windows',
      );
    }
    if (expectedQuestions < 1 || expectedQuestions > 100) {
      throw ArgumentError.value(expectedQuestions, 'expectedQuestions');
    }
    if (!image.existsSync()) throw ArgumentError.value(image, 'image');
    if (!template.existsSync() || pExtension(template.path) != '.json') {
      throw ArgumentError.value(template, 'template');
    }
    final extension = pExtension(image.path);
    if (!const {'.png', '.jpg', '.jpeg'}.contains(extension)) {
      throw CodedFormatException(
        'omr.image.format.unsupported',
        '仅支持 PNG/JPG/JPEG：${image.path}',
        [image.path],
      );
    }
    final executable = this.executable ?? _defaultExecutable();
    if (!executable.existsSync()) {
      throw CodedStateError(
        'omr.executable.missing',
        '缺少随程序发布的阅卷组件：${executable.path}',
        [executable.path],
      );
    }
    final temporary = await Directory.systemTemp.createTemp('paper-omr-');
    final output = File(
      '${temporary.path}${Platform.pathSeparator}result.json',
    );
    try {
      final arguments = [
        '--input',
        image.path,
        '--template',
        template.path,
        '--output',
        output.path,
      ];
      final result = _usesDefaultRunner
          ? await _runWithTimeout(executable.path, arguments, timeout)
          : await _runner(executable.path, arguments).timeout(
              timeout,
              onTimeout: () {
                throw CodedTimeoutException(
                  'omr.recognize.timeout',
                  '答题卡识别超时',
                  timeout,
                );
              },
            );
      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      if (result.exitCode != 0) {
        throw CodedStateError(
          'omr.bridge.exitCode',
          '阅卷组件退出码 ${result.exitCode}：$stderr',
          [result.exitCode, stderr],
        );
      }
      if (!output.existsSync()) {
        throw CodedStateError(
          'omr.bridge.noResult',
          '阅卷组件未生成结构化结果：$stdout',
          [stdout],
        );
      }
      return parseOutput(
        output.readAsStringSync(encoding: utf8),
        expectedQuestions: expectedQuestions,
      );
    } finally {
      if (temporary.existsSync()) temporary.deleteSync(recursive: true);
    }
  }

  static WindowsOmrResult parseOutput(
    String source, {
    required int expectedQuestions,
  }) {
    final decoded = jsonDecode(source);
    if (decoded is! Map ||
        decoded['schema_version'] != 2 ||
        decoded['layout'] != 'a4-omr-v4') {
      throw const CodedFormatException(
        'omr.result.versionInvalid',
        '阅卷结果版本无效',
      );
    }
    final sourceSize = decoded['source_size'];
    if (sourceSize is! Map) {
      throw const CodedFormatException(
        'omr.result.sourceSizeInvalid',
        '阅卷结果原图尺寸无效',
      );
    }
    final sourceWidth = _strictPositiveInt(sourceSize['width']);
    final sourceHeight = _strictPositiveInt(sourceSize['height']);
    if (sourceWidth == null || sourceHeight == null) {
      throw const CodedFormatException(
        'omr.result.sourceSizeInvalid',
        '阅卷结果原图尺寸无效',
      );
    }
    final pageQuad = _parseQuad(decoded['page_quad'], '页面几何');
    final rows = decoded['questions'];
    if (rows is! List || rows.length != expectedQuestions) {
      throw const CodedFormatException(
        'omr.result.questionCountMismatch',
        '阅卷结果题目数量不匹配',
      );
    }
    final used = <int>{};
    final questions = <WindowsOmrQuestion>[];
    for (final row in rows) {
      if (row is! Map) {
        throw const CodedFormatException(
          'omr.result.questionFormatInvalid',
          '阅卷结果题目格式无效',
        );
      }
      final match = RegExp(r'^q([1-9]\d*)$').firstMatch('${row['label']}');
      final number = match == null ? null : int.tryParse(match.group(1)!);
      if (number == null || number > expectedQuestions || !used.add(number)) {
        throw CodedFormatException(
          'omr.result.labelInvalid',
          '阅卷结果标签无效：${row['label']}',
          ['${row['label']}'],
        );
      }
      final values = row['selected'];
      if (values is! List || values.any((value) => value is! String)) {
        throw const CodedFormatException(
          'omr.result.optionsFormatInvalid',
          '阅卷结果选项格式无效',
        );
      }
      final selected = values.cast<String>().toSet();
      if (selected.length != values.length ||
          selected.any(
            (value) => !const {'A', 'B', 'C', 'D', 'E'}.contains(value),
          )) {
        throw const CodedFormatException(
          'omr.result.optionsOutOfRange',
          '阅卷结果选项越界',
        );
      }
      final confidence = (row['confidence'] as num?)?.toDouble();
      if (confidence == null || confidence < 0 || confidence > 1) {
        throw const CodedFormatException(
          'omr.result.confidenceInvalid',
          '阅卷结果置信度无效',
        );
      }
      final bubbles = row['bubble_quad'];
      if (bubbles is! Map || bubbles.length != 5) {
        throw const CodedFormatException(
          'omr.result.bubblesInvalid',
          '阅卷结果气泡几何无效',
        );
      }
      final bubbleQuad = <String, List<List<double>>>{};
      for (final option in const ['A', 'B', 'C', 'D', 'E']) {
        bubbleQuad[option] = _parseQuad(bubbles[option], '气泡 $option 几何');
      }
      questions.add(
        WindowsOmrQuestion(
          number: number,
          selected: selected,
          confidence: confidence,
          bubbleQuad: Map.unmodifiable(bubbleQuad),
        ),
      );
    }
    if (used.length != expectedQuestions) {
      throw const CodedFormatException(
        'omr.result.labelsIncomplete',
        '阅卷结果标签不完整',
      );
    }
    questions.sort((left, right) => left.number.compareTo(right.number));
    return WindowsOmrResult(
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      pageQuad: pageQuad,
      questions: List.unmodifiable(questions),
    );
  }

  static int? _strictPositiveInt(Object? value) => value is int && value > 0
      ? value
      : null;

  static List<List<double>> _parseQuad(Object? value, String field) {
    if (value is! List || value.length != 4) {
      throw CodedFormatException(
        'omr.result.quadInvalid',
        '阅卷结果 $field 无效',
        [field],
      );
    }
    final points = <List<double>>[];
    for (final point in value) {
      if (point is! List || point.length != 2) {
        throw CodedFormatException(
          'omr.result.quadInvalid',
          '阅卷结果 $field 无效',
          [field],
        );
      }
      final x = (point[0] as num?)?.toDouble();
      final y = (point[1] as num?)?.toDouble();
      if (x == null || y == null || !x.isFinite || !y.isFinite ||
          x < 0 || x > 1 || y < 0 || y > 1) {
        throw CodedFormatException(
          'omr.result.quadOutOfRange',
          '阅卷结果 $field 越界',
          [field],
        );
      }
      points.add(List.unmodifiable([x, y]));
    }
    return List.unmodifiable(points);
  }

  static File _defaultExecutable() => File(
    '${File(Platform.resolvedExecutable).parent.path}'
    '${Platform.pathSeparator}paper_omr_bridge.exe',
  );

  static Future<ProcessResult> _run(
    String executable,
    List<String> arguments,
  ) => Process.run(executable, arguments, runInShell: false);

  static Future<ProcessResult> _runWithTimeout(
    String executable,
    List<String> arguments,
    Duration timeout,
  ) async {
    final process = await Process.start(
      executable,
      arguments,
      runInShell: false,
    );
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();
    try {
      final exitCode = await process.exitCode.timeout(timeout);
      return ProcessResult(process.pid, exitCode, await stdout, await stderr);
    } on TimeoutException {
      process.kill();
      try {
        await process.exitCode.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
      }
      await stdout;
      await stderr;
      throw CodedTimeoutException('omr.recognize.timeout', '答题卡识别超时', timeout);
    }
  }
}

String pExtension(String path) {
  final name = path.split(Platform.pathSeparator).last;
  final index = name.lastIndexOf('.');
  return index < 0 ? '' : name.substring(index).toLowerCase();
}
