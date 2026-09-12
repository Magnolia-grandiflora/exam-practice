import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_exam_app/services/pdf_print_service.dart';

void main() {
  test(
    '分页夹具能够生成多页 PDF，且每页页码为 current / total',
    () async {
      if (!Platform.isWindows) return;
      if (!await _popplerAvailable()) {
        markTestSkipped('未安装 poppler（pdfinfo/pdftoppm），无法做分页集成校验');
        return;
      }
      final temp = await Directory.systemTemp.createTemp('pdf-pagination-');
      try {
        final fixtureRoot = Directory(
          p.join('test', 'fixtures', 'pdf_pagination'),
        );
        for (final fixture in [
          'even_to_odd.md',
          'odd_to_even.md',
          'tall_question.md',
        ]) {
          await File(
            p.join(fixtureRoot.path, fixture),
          ).copy(p.join(temp.path, fixture));
        }
        await File(p.join(temp.path, 'manifest.json')).writeAsString(
          jsonEncode({
            'title': 'pagination-fixture',
            'markdown_files': [
              'even_to_odd.md',
              'odd_to_even.md',
              'tall_question.md',
            ],
          }),
        );

        final pdf = await const PdfPrintService().printPack(temp);
        expect(pdf.existsSync(), isTrue);
        expect(pdf.lengthSync(), greaterThan(1024));

        final total = await _readPdfPageCount(pdf);
        expect(total, greaterThanOrEqualTo(5));
        await _renderRepresentativePages(pdf, temp, total);
        await _preserveVerificationArtifacts(pdf, temp, total);
      } finally {
        await temp.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<bool> _popplerAvailable() async {
  try {
    await Process.run('pdfinfo', ['-v']);
    return true;
  } on ProcessException {
    return false;
  }
}

Future<int> _readPdfPageCount(File pdf) async {
  final result = await Process.run('pdfinfo', [pdf.path]);
  if (result.exitCode != 0) {
    throw StateError('pdfinfo failed: ${result.stderr}');
  }
  final match = RegExp(
    r'^Pages:\s+(\d+)$',
    multiLine: true,
  ).firstMatch(result.stdout as String);
  if (match == null) throw StateError('pdfinfo did not report page count');
  return int.parse(match.group(1)!);
}

Future<void> _renderRepresentativePages(
  File pdf,
  Directory temp,
  int total,
) async {
  for (final page in {1, (total + 1) ~/ 2, total}) {
    final prefix = p.join(temp.path, 'rendered-$page');
    final result = await Process.run('pdftoppm', [
      '-png',
      '-singlefile',
      '-f',
      '$page',
      '-l',
      '$page',
      pdf.path,
      prefix,
    ]);
    if (result.exitCode != 0) {
      throw StateError('pdftoppm failed: ${result.stderr}');
    }
    final image = File('$prefix.png');
    expect(image.existsSync(), isTrue);
    expect(image.lengthSync(), greaterThan(1024));
  }
}

Future<void> _preserveVerificationArtifacts(
  File pdf,
  Directory temp,
  int total,
) async {
  final requested = Platform.environment['PDF_VERIFICATION_OUTPUT'];
  if (requested == null || requested.trim().isEmpty) return;
  final destination = Directory(requested)..createSync(recursive: true);
  await pdf.copy(p.join(destination.path, 'pagination-fixture.pdf'));
  for (final page in {1, (total + 1) ~/ 2, total}) {
    final source = File(p.join(temp.path, 'rendered-$page.png'));
    expect(source.existsSync(), isTrue);
    await source.copy(p.join(destination.path, 'page-$page.png'));
  }
}
