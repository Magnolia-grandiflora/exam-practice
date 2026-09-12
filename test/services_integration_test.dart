import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:personal_exam_app/data/app_database.dart';
import 'package:personal_exam_app/data/app_paths.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/services/backup_service.dart';
import 'package:personal_exam_app/services/bank_importer.dart';
import 'package:personal_exam_app/services/markdown_exporter.dart';
import 'package:personal_exam_app/services/omr_identity.dart';
import 'package:zxing2/qrcode.dart';

void main() {
  test('题库提交、媒体、备份和 Markdown 试卷包形成完整本地闭环', () {
    final temp = Directory.systemTemp.createTempSync('personal-exam-services-');
    final paths = AppPaths.at(temp)..ensureCreated();
    final db = AppDatabase.open(paths.database.path);
    try {
      final importer = BankImporter(db, paths);
      final preview = importer.previewFile('assets/test-bank/test-bank.zip');
      expect(preview.canImport, isTrue);
      importer.commit(preview);
      expect(db.dashboard(preview.bankId).total, 15);
      expect(
        File(
          p.join(paths.media.path, preview.bankId, 'v1', 'flow.png'),
        ).existsSync(),
        isTrue,
      );

      final backup = BackupService(db, paths).create(reason: '测试备份');
      expect(File(backup).existsSync(), isTrue);

      final questions = db.listQuestions(bankId: preview.bankId);
      final paper = db.createPaper(
        bankId: preview.bankId,
        title: '本地闭环测试卷',
        questions: questions.take(7).toList(),
        suggestedDurationMs: 60000,
      );
      paper.questions.first.selected.add('A');
      paper.durationMs = 5000;
      db.submitPaper(paper);
      final exported = MarkdownExporter(db, paths).exportPaper(paper);
      for (final name in [
        '试卷.md',
        '答题卡.md',
        '答案与解析.md',
        '作答回顾.md',
        'manifest.json',
      ]) {
        expect(
          File(p.join(exported.path, name)).existsSync(),
          isTrue,
          reason: name,
        );
      }
      final templateFile = File(
        p.join(exported.path, '资源', 'omr-template.json'),
      );
      expect(templateFile.existsSync(), isTrue);
      final template = jsonDecode(templateFile.readAsStringSync()) as Map;
      expect(template['pageDimensions'], [2100, 2970]);
      expect(template['outputColumns'], ['q1..7']);
      expect(
        (template['fieldBlocks'] as Map).keys,
        unorderedEquals(['answers_1']),
      );
      expect(
        ((template['fieldBlocks'] as Map)['answers_1'] as Map)['origin'],
        [902, 746],
        reason: '首行气泡中心 = 9mm 页边距 + 56mm 表区顶 + 1.5×6.4mm（表头行之后）',
      );
      expect(
        File(
          p.join(exported.path, '资源', 'question-media-006-01.png'),
        ).existsSync(),
        isTrue,
      );
      final blankPaper = File(
        p.join(exported.path, '试卷.md'),
      ).readAsStringSync();
      expect(blankPaper, contains('![[资源/question-media-006-01.png]]'));
      expect(blankPaper, isNot(contains('**正确答案：')));
      expect(
        blankPaper.indexOf('A. 只能选择一个'),
        lessThan(blankPaper.indexOf('B. 至少选择两个')),
      );
      final answerSheet = File(
        p.join(exported.path, '答题卡.md'),
      ).readAsStringSync();
      expect(answerSheet, contains('layout: a4-omr-v4'));
      expect(answerSheet, contains('data-omr-label="q1"'));
      expect(answerSheet, contains('data-omr-label="q7"'));
      expect(answerSheet, contains('个人练习专用'));
      expect(answerSheet, contains('选择题答题区'));
      expect(answerSheet, contains('omr-head'), reason: 'ABCDE 表头行');
      expect(answerSheet, contains('<span>题号</span>'));
      expect(answerSheet, contains('omr-marker omr-marker-tl'));
      expect(answerSheet, contains('omr-marker omr-marker-tr'));
      expect(answerSheet, contains('omr-marker omr-marker-bl'));
      expect(answerSheet, contains('omr-marker omr-marker-br'));
      final qrMatch = RegExp(
        r'data:image/png;base64,([A-Za-z0-9+/=]+)',
      ).firstMatch(answerSheet);
      expect(qrMatch, isNotNull, reason: '答题卡二维码（base64 PNG）');
      final qrImage = img.decodeImage(base64Decode(qrMatch!.group(1)!));
      expect(qrImage, isNotNull);
      final rgba = qrImage!
          .convert(numChannels: 4)
          .getBytes(order: img.ChannelOrder.abgr)
          .buffer
          .asInt32List();
      final qrText = QRCodeReader().decode(
        BinaryBitmap(
          HybridBinarizer(
            RGBLuminanceSource(qrImage.width, qrImage.height, rgba),
          ),
        ),
      );
      final payload = OmrIdentity.parseAndValidate(qrText.text);
      expect(payload.questions, 7);
      expect(payload.bankId, preview.bankId);
      expect(payload.questionPositions, hasLength(7));
      expect(answerSheet, isNot(contains('姓名')));
      expect(answerSheet, isNot(contains('准考证号')));
      final manifest =
          jsonDecode(
                File(p.join(exported.path, 'manifest.json')).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final omr = manifest['omr'] as Map<String, dynamic>;
      expect(omr['engine'], 'paper-omr');
      expect(omr['layout'], 'a4-omr-v4');
      expect(omr['template'], '资源/omr-template.json');
      expect(omr['labels'], ['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7']);
      expect(jsonEncode(manifest), isNot(contains('correct_answers')));
      expect(
        (manifest['question_layout'] as List).first,
        containsPair('valid_options', ['A', 'B', 'C', 'D']),
      );
      final review = File(p.join(exported.path, '作答回顾.md')).readAsStringSync();
      expect(review, contains('用户选择：A'));
      expect(review, contains('正确答案：A'));
    } finally {
      db.dispose();
      temp.deleteSync(recursive: true);
    }
  });

  test('5000 题本地统计与 100 题组卷可用', () {
    final temp = Directory.systemTemp.createTempSync('personal-exam-100-');
    final paths = AppPaths.at(temp)..ensureCreated();
    final db = AppDatabase.memory();
    try {
      final questions = List.generate(
        5000,
        (index) => Question(
          id: 'q$index',
          bankId: 'large',
          externalId: 'L-$index',
          contentVersion: 1,
          type: index % 5 == 0 ? QuestionType.multiple : QuestionType.single,
          stem: '性能测试题 $index',
          options: const {'A': '甲', 'B': '乙', 'C': '丙', 'D': '丁'},
          answers: index % 5 == 0 ? const ['A', 'C'] : const ['A'],
          explanation: '解析',
          knowledgePoint: '性能',
          source: '测试',
          year: '${2020 + index % 6}',
          chapter: '第 ${index % 10} 章',
          tags: const ['性能'],
          media: const [],
          scoringRule: const ScoringRule(),
          isActive: true,
        ),
      );
      final watch = Stopwatch()..start();
      db.importBank(
        ImportPreview(
          packagePath: 'generated',
          bankId: 'large',
          name: '大题库',
          subject: '性能',
          contentVersion: 1,
          questions: questions,
          mediaFiles: const {},
          issues: const [],
        ),
        reportJson: '{}',
      );
      final stats = db.dashboard('large');
      final paperQuestions = db.listQuestions(
        bankId: 'large',
        limit: 100,
        random: true,
      );
      final paper = db.createPaper(
        bankId: 'large',
        title: '100 题',
        questions: paperQuestions,
        suggestedDurationMs: 0,
      );
      watch.stop();
      expect(stats.total, 5000);
      expect(paper.questions, hasLength(100));
      expect(watch.elapsed, lessThan(const Duration(seconds: 10)));

      final exported = MarkdownExporter(
        db,
        paths,
      ).exportPaper(paper, blankPaper: false, answerSheet: true);
      expect(File(p.join(exported.path, '试卷.md')).existsSync(), isFalse);
      expect(File(p.join(exported.path, '答案与解析.md')).existsSync(), isFalse);
      final answerSheet = File(
        p.join(exported.path, '答题卡.md'),
      ).readAsStringSync();
      expect(answerSheet, contains('data-omr-label="q1"'));
      expect(answerSheet, contains('data-omr-label="q21"'));
      expect(answerSheet, contains('data-omr-label="q41"'));
      expect(answerSheet, contains('data-omr-label="q61"'));
      expect(answerSheet, contains('data-omr-label="q81"'));
      expect(answerSheet, contains('data-omr-label="q100"'));
      expect(
        answerSheet
            .split('\n')
            .where((line) => line.contains('class="omr-group"')),
        hasLength(5),
      );
      final css = File(
        p.join(exported.path, 'exam-print.css'),
      ).readAsStringSync();
      expect(css, contains('@page { size: A4 portrait;'));
      expect(css, contains('height: 270mm;'));
      expect(css, contains('.omr-grid'));
      expect(css, contains('.omr-groups-5 .omr-grid { width: 180mm;'));
      expect(css, contains('height: 6.4mm;'));
      expect(css, contains('grid-template-columns: 8mm repeat(5, 1fr);'));
    } finally {
      db.dispose();
      temp.deleteSync(recursive: true);
    }
  });
}
