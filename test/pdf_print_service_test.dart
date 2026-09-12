import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_exam_app/services/pdf_print_service.dart';

void main() {
  test('试卷包可转换为内嵌图片和分页样式的打印 HTML', () {
    final temp = Directory.systemTemp.createTempSync('paper-pdf-html-');
    try {
      final resources = Directory(p.join(temp.path, '资源'))
        ..createSync(recursive: true);
      File(p.join(resources.path, '图.png')).writeAsBytesSync([1, 2, 3]);
      File(
        p.join(temp.path, 'exam-print.css'),
      ).writeAsStringSync('.exam-paper { color: #123456; }');
      File(p.join(temp.path, '试卷.md')).writeAsStringSync('''---
title: 测试卷
cssclasses: [exam-print, exam-paper]
---
# 测试卷

## 1. 【单选】题干
A. 甲
B. 乙

![[资源/图.png]]
''');
      File(p.join(temp.path, '答题卡.md')).writeAsStringSync('''---
cssclasses: [exam-print, exam-answer-sheet]
---
# 答题卡

| 题号 | A |
|---:|:---:|
| 1 | ○ |
''');
      File(p.join(temp.path, 'manifest.json')).writeAsStringSync(
        jsonEncode({
          'title': '测试卷',
          'markdown_files': ['试卷.md', '答题卡.md'],
        }),
      );

      final html = const PdfPrintService().buildPrintHtml(temp);
      expect(html, contains('<title>测试卷</title>'));
      expect(html, contains('class="exam-print exam-paper"'));
      expect(html, contains('data:image/png;base64,AQID'));
      expect(html, contains('<table>'));
      expect(html, contains('break-before: page'));
      expect(
        html,
        contains('class="exam-question" data-print-question="true"'),
      );
      expect(html, contains('@bottom-center'));
      expect(html, contains('counter(page) " / " counter(pages)'));
      expect(html, contains('.exam-question { break-inside: avoid; }'));
      expect(html, isNot(contains('prepareEvenToOddQuestions')));
      expect(html, isNot(contains('cssclasses:')));
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('仅保留 PDF 时清理其他导出文件', () {
    final temp = Directory.systemTemp.createTempSync('paper-pdf-only-');
    try {
      final resources = Directory(p.join(temp.path, '资源'))
        ..createSync(recursive: true);
      File(p.join(resources.path, 'marker.png')).writeAsBytesSync([1]);
      File(p.join(temp.path, '试卷.md')).writeAsStringSync('# 试卷');
      File(p.join(temp.path, 'manifest.json')).writeAsStringSync('{}');
      final pdf = File(p.join(temp.path, '试卷.pdf'))
        ..writeAsBytesSync([37, 80, 68, 70]);

      const PdfPrintService().retainOnlyPdf(temp, pdf);

      expect(temp.listSync().map((entity) => p.basename(entity.path)), [
        '试卷.pdf',
      ]);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('仅 Chromium 131 及以上允许使用页边距页码框', () {
    expect(
      PdfPrintService.supportsPageMarginBoxesVersion(
        'Microsoft Edge 152.0.4191.66',
      ),
      isTrue,
    );
    expect(
      PdfPrintService.supportsPageMarginBoxesVersion('Chromium 131.0.0.0'),
      isTrue,
    );
    expect(
      PdfPrintService.supportsPageMarginBoxesVersion('Google Chrome 130.0.1.2'),
      isFalse,
    );
    expect(PdfPrintService.supportsPageMarginBoxesVersion('unknown'), isFalse);
  });
}
