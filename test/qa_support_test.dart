import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/data/app_database.dart';
import 'package:personal_exam_app/data/app_paths.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/domain/paper_policy.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:personal_exam_app/services/bank_importer.dart';
import 'package:personal_exam_app/services/markdown_exporter.dart';
import 'package:personal_exam_app/services/windows_omr_scanner.dart';
import 'package:personal_exam_app/ui/app_theme.dart';
import 'package:personal_exam_app/ui/windows_omr_review_page.dart';

Question _question(
  QuestionType type,
  String id, {
  Map<String, String> options = const {},
  List<String> answers = const [],
}) => Question(
  id: id,
  bankId: 'bank-1',
  externalId: id,
  contentVersion: 1,
  type: type,
  stem: '题干 $id',
  options: options,
  answers: answers,
  explanation: '',
  knowledgePoint: '',
  source: '',
  year: '2025',
  chapter: '',
  tags: const [],
  media: const [],
  scoringRule: const ScoringRule(),
  isActive: true,
);

Question _single(String id) => _question(
  QuestionType.single,
  id,
  options: const {'A': '甲', 'B': '乙', 'C': '丙', 'D': '丁'},
  answers: const ['A'],
);

Question _multiple(String id) => _question(
  QuestionType.multiple,
  id,
  options: const {'A': '甲', 'B': '乙', 'C': '丙', 'D': '丁'},
  answers: const ['A', 'B'],
);

Question _qa(String id, {String reference = ''}) => _question(
  QuestionType.qa,
  id,
  answers: [if (reference.isNotEmpty) reference],
);


Map<String, List<List<double>>> _bubbleQuad() => {
  for (final option in const ['A', 'B', 'C', 'D', 'E'])
    option: const [
      [0.1, 0.1],
      [0.12, 0.1],
      [0.12, 0.12],
      [0.1, 0.12],
    ],
};

void main() {
  group('组卷自定义题型数量', () {
    final pool = [
      for (var i = 1; i <= 20; i++) _single('s$i'),
      for (var i = 1; i <= 10; i++) _multiple('m$i'),
      for (var i = 1; i <= 5; i++) _qa('q$i'),
    ];

    test('按单选/多选/问答题数量组卷，顺序为单选→多选→问答', () {
      final result = PaperCompositionPolicy.compose(
        pool,
        mode: PaperCompositionMode.realExam,
        total: 0,
        random: false,
        counts: const PaperTypeCounts(single: 3, multiple: 2, qa: 2),
      );
      expect(result, hasLength(7));
      expect(result.take(3).map((q) => q.type), everyElement(QuestionType.single));
      expect(result.skip(3).take(2).map((q) => q.type),
          everyElement(QuestionType.multiple));
      expect(result.skip(5).map((q) => q.type), everyElement(QuestionType.qa));
      expect(result.last.id, 'q2');
    });

    test('库存不足时取现有全部，不抛错', () {
      final result = PaperCompositionPolicy.compose(
        pool,
        mode: PaperCompositionMode.realExam,
        total: 0,
        random: false,
        counts: const PaperTypeCounts(single: 50, multiple: 20, qa: 9),
      );
      expect(result.where((q) => q.type == QuestionType.single), hasLength(20));
      expect(result.where((q) => q.type == QuestionType.multiple), hasLength(10));
      expect(result.where((q) => q.type == QuestionType.qa), hasLength(5));
    });

    test('不传 counts 时保持历史 14:3 比例且不含问答题', () {
      final result = PaperCompositionPolicy.compose(
        pool,
        mode: PaperCompositionMode.realExam,
        total: 17,
        random: false,
      );
      expect(result.where((q) => q.type == QuestionType.single), hasLength(14));
      expect(result.where((q) => q.type == QuestionType.multiple), hasLength(3));
      expect(result.where((q) => q.type == QuestionType.qa), isEmpty);
    });
  });

  group('试卷判分策略 v2', () {
    final single = _single('s1');
    final multiple = _multiple('m1');
    final qa = _qa('q1', reference: '参考要点');

    test('可自定义分值与部分分规则', () {
      const policy = PaperScoringPolicy(
        singleScore: 2,
        multipleScore: 3,
        partialPerCorrectOption: 1,
        wrongOptionMakesZero: false,
      );
      final exactSingle = policy.score(single, const {'A'});
      expect(exactSingle.score, 2);
      // 少选且无错选：部分分 = 正确项数 × 每项分值。
      final partial = policy.score(multiple, const {'A'});
      expect(partial.score, 1);
      // 有错项但关闭整题零分：仍按部分分计。
      final wrongWithCredit = policy.score(multiple, const {'A', 'D'});
      expect(wrongWithCredit.score, 1);
      // 关闭部分分：错项/少选均 0。
      const strict = PaperScoringPolicy(partialCredit: false);
      expect(strict.score(multiple, const {'A'}).score, 0);
      expect(strict.score(multiple, const {'A', 'D'}).score, 0);
      // 默认策略：错项整题零分。
      expect(
        const PaperScoringPolicy().score(multiple, const {'A', 'D'}).score,
        0,
      );
    });

    test('问答题不判分：maxScore 0，作答文本即已作答', () {
      const policy = PaperScoringPolicy();
      final answered = policy.score(qa, const {'手写作答内容'});
      expect(answered.isAnswered, isTrue);
      expect(answered.score, 0);
      expect(answered.maxScore, 0);
      expect(policy.score(qa, const {}).isAnswered, isFalse);
      // 百分比换算只覆盖选择题。
      expect(policy.percentage(score: 3, maxScore: 3), 100);
    });

    test('旧版本 uniform_exam_v1 快照反序列化为默认值（历史试卷不变）', () {
      final policy = PaperScoringPolicy.fromJson(const {
        'kind': 'uniform_exam_v1',
      });
      expect(policy.singleScore, 1);
      expect(policy.multipleScore, 2);
      expect(policy.partialCredit, isTrue);
      expect(policy.partialPerCorrectOption, 0.5);
      expect(policy.wrongOptionMakesZero, isTrue);
    });
  });

  group('问答题导入', () {
    late Directory temp;
    late File file;
    setUp(() {
      temp = Directory.systemTemp.createTempSync('exam-qa-tsv-');
      file = File('${temp.path}${Platform.pathSeparator}qa.tsv');
      file.writeAsStringSync('''
# schema_version: 1
# bank_id: 6bb446a3-a893-4f12-88db-f0ac05f55302
# name: 问答测试题库
# subject: 法规
# content_version: 1
编号\t年份\t题型\t题干\t选项A\t选项B\t选项C\t选项D\t选项E\t答案\t解析\t考点\t来源\tTags
QA-001\t2025\t问答\t简述安全生产法的适用范围。\t\t\t\t\t\t在中华人民共和国领域内从事生产经营活动的单位。\t要点齐全即可。\t考点一\t来源一\t真题
QA-002\t2025\t问答\t简述应急预案的编制要求。\t\t\t\t\t\t\t解析可空。\t考点二\t来源二\t真题
QA-003\t2025\t问答\t带选项的问答题应被拒绝。\t甲\t\t\t\t\tB\t\t考点三\t来源三\t真题
'''
          .trimLeft());
    });
    tearDown(() => temp.deleteSync(recursive: true));

    test('问答行保留参考答案原文，空白答案不阻断，带选项为阻断项', () {
      final db = AppDatabase.memory();
      try {
        final importer = BankImporter(db, AppPaths.at(temp));
        final preview = importer.previewFile(file.path);
        expect(
          preview.issues
              .where((issue) => issue.code == 'import.blocked.qaWithOptions')
              .length,
          1,
          reason: preview.issues.map((issue) => issue.message).join('\n'),
        );
        final qaRows = preview.questions
            .where((question) => question.type == QuestionType.qa)
            .toList();
        expect(qaRows, hasLength(3));
        expect(qaRows[0].answers, ['在中华人民共和国领域内从事生产经营活动的单位。']);
        expect(qaRows[0].options, isEmpty);
        // 空参考答案允许（警告级），不阻断导入。
        expect(qaRows[1].answers, isEmpty);
        expect(
          preview.issues.any((issue) => issue.code == 'import.blocked.answerNotInOptions'),
          isFalse,
        );
        preview.issues.removeWhere((issue) => issue.blocking);
        expect(preview.issues.where((issue) => issue.blocking), isEmpty);
      } finally {
        db.dispose();
      }
    });
  });

  group('含问答题的试卷（数据库与导出）', () {
    late Directory temp;
    late AppDatabase db;
    late BankSummary bank;
    late PaperAttempt attempt;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('exam-qa-paper-');
      final tsv = File('${temp.path}${Platform.pathSeparator}qa.tsv')
        ..writeAsStringSync('''
# schema_version: 1
# bank_id: 6bb446a3-a893-4f12-88db-f0ac05f55303
# name: 综合测试题库
# subject: 法规
# content_version: 1
编号\t年份\t题型\t题干\t选项A\t选项B\t选项C\t选项D\t选项E\t答案\t解析\t考点\t来源\tTags
S-001\t2025\tsingle\t单选1\t甲\t乙\t丙\t丁\t\tB\t解析\t考点\t来源\t真题
M-001\t2025\tmultiple\t多选1\t甲\t乙\t丙\t丁\t\tAC\t解析\t考点\t来源\t真题
Q-001\t2025\t问答\t问答1\t\t\t\t\t\t要点一\t解析\t考点\t来源\t真题
Q-002\t2025\t问答\t问答2\t\t\t\t\t\t\t解析\t考点\t来源\t真题
'''
            .trimLeft());
      db = AppDatabase.memory();
      final importer = BankImporter(db, AppPaths.at(temp));
      final preview = importer.previewFile(tsv.path);
      importer.commit(preview);
      bank = db.listBanks().single;
      attempt = db.createPaper(
        bankId: bank.id,
        title: '问答试卷',
        questions: [
          db.questionById(
                db.listQuestions(bankId: bank.id).firstWhere((q) => q.externalId == 'S-001').id,
              )!,
          db.questionById(
                db.listQuestions(bankId: bank.id).firstWhere((q) => q.externalId == 'M-001').id,
              )!,
          db.questionById(
                db.listQuestions(bankId: bank.id).firstWhere((q) => q.externalId == 'Q-001').id,
              )!,
          db.questionById(
                db.listQuestions(bankId: bank.id).firstWhere((q) => q.externalId == 'Q-002').id,
              )!,
        ],
        suggestedDurationMs: 30 * 60000,
        compositionMode: PaperCompositionMode.realExam,
        scoringPolicy: const PaperScoringPolicy(
          singleScore: 2,
          multipleScore: 4,
          partialPerCorrectOption: 2,
        ),
      );
    });

    tearDown(() {
      db.dispose();
      temp.deleteSync(recursive: true);
    });

    void answerAll() {
      attempt.questions[0].selected.add('B');
      attempt.questions[1].selected.addAll(const {'A', 'C'});
      attempt.questions[2].selected.add('问答题手写作答内容');
      attempt.questions[3].selected.clear();
    }

    test('草稿保存/读取保留问答题原文，交卷不产生问答题事件', () {
      answerAll();
      db.savePaperDraft(attempt);
      final reloaded = db.loadAttempt(attempt.attemptId)!;
      expect(reloaded.questions[2].textAnswer, '问答题手写作答内容');
      expect(reloaded.questions[2].selected, hasLength(1));
      // 问答题不计入分值；总分只有选择题（2 + 4）。
      expect(reloaded.scoringPolicy.singleScore, 2);

      db.submitPaper(attempt);
      expect(attempt.maxScore, 6);
      expect(attempt.score, 6);
      // 选择题事件各 1 条，问答题无事件。
      expect(db.answerHistory(attempt.questions[0].question.id), hasLength(1));
      expect(db.answerHistory(attempt.questions[1].question.id), hasLength(1));
      expect(db.answerHistory(attempt.questions[2].question.id), isEmpty);
      // 交卷快照保留问答题原文。
      final submitted = db.loadAttempt(attempt.attemptId)!;
      expect(submitted.questions[2].textAnswer, '问答题手写作答内容');
    });

    test('答题卡气泡压缩编号且模板只覆盖选择题，导出渲染问答区', () {
      // 答案卷仅交卷后可导出，先交卷（选择题全对，问答题不计分）。
      attempt.questions[0].selected.add('B');
      attempt.questions[1].selected.addAll(const {'A', 'C'});
      db.submitPaper(attempt);
      final exporter = MarkdownExporter(db, AppPaths.at(temp));
      final directory = exporter.exportPaper(attempt);
      final sheet = File(
        '${directory.path}${Platform.pathSeparator}答题卡.md',
      ).readAsStringSync();
      // 气泡行行首显示试卷题号 1、2（选择题），不含问答题行。
      expect(sheet.contains('data-omr-label="q1"'), isTrue);
      expect(sheet.contains('data-omr-label="q2"'), isTrue);
      expect(sheet.contains('data-omr-label="q3"'), isFalse);
      expect(sheet.contains('>1<'), isTrue);
      expect(sheet.contains('问答题答题区'), isTrue);
      expect(sheet.contains('第 3 题'), isTrue);
      expect(sheet.contains('第 4 题'), isTrue);
      // 模板：输出列只到选择题数；几何仍为 a4-omr-v4。
      final template = File(
        '${directory.path}${Platform.pathSeparator}资源${Platform.pathSeparator}omr-template.json',
      ).readAsStringSync();
      expect(template.contains('"q1..2"'), isTrue);
      expect(template.contains('"q3"'), isFalse);
      expect(template.contains('a4-omr-v4'), isTrue);
      // 试卷 Markdown：空白卷问答留白、答案卷给参考答案。
      final paper = File(
        '${directory.path}${Platform.pathSeparator}试卷.md',
      ).readAsStringSync();
      expect(paper.contains('exam-qa-space'), isTrue);
      final answers = File(
        '${directory.path}${Platform.pathSeparator}答案与解析.md',
      ).readAsStringSync();
      expect(answers.contains('参考答案：要点一'), isTrue);
      expect(answers.contains('（未提供参考答案）'), isTrue);
    });

    test('纯问答题试卷导出答题卡被拒绝（需至少一道选择题）', () {
      final qaOnly = db.createPaper(
        bankId: bank.id,
        title: '纯问答',
        questions: [
          db.questionById(
                db.listQuestions(bankId: bank.id).firstWhere((q) => q.externalId == 'Q-001').id,
              )!,
        ],
        suggestedDurationMs: 60000,
      );
      final exporter = MarkdownExporter(db, AppPaths.at(temp));
      expect(
        () => exporter.exportPaper(qaOnly),
        throwsA(
          isA<FormatException>().having(
            (error) => '$error',
            'message',
            contains('答题卡需要至少一道单选或多选题'),
          ),
        ),
      );
    });
  });

  testWidgets('阅卷复核：问答题人工录入随确认写入快照且不产生事件', (tester) async {
    final root = Directory.systemTemp.createTempSync('exam-qa-review-');
    final image = File('${root.path}${Platform.pathSeparator}sheet.jpg')
      ..writeAsBytesSync([1]);
    final controller = await AppController.createForTesting(root);
    addTearDown(() {
      controller.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    // 导入 2 单选 + 1 多选 + 1 问答的题库，并构造试卷。
    final tsv = File('${root.path}${Platform.pathSeparator}qa.tsv')
      ..writeAsStringSync('''
# schema_version: 1
# bank_id: 6bb446a3-a893-4f12-88db-f0ac05f55304
# name: 复核题库
# subject: 法规
# content_version: 1
编号	年份	题型	题干	选项A	选项B	选项C	选项D	选项E	答案	解析	考点	来源	Tags
S-001	2025	single	单选1	甲	乙	丙	丁		B	解析	考点	来源	真题
S-002	2025	single	单选2	甲	乙	丙	丁		A	解析	考点	来源	真题
M-001	2025	multiple	多选1	甲	乙	丙	丁		AC	解析	考点	来源	真题
Q-001	2025	问答	问答1						参考要点	解析	考点	来源	真题
'''.trimLeft());
    final importer = BankImporter(
      controller.database,
      AppPaths.at(root),
    );
    final preview = importer.previewFile(tsv.path);
    importer.commit(preview);
    final byExternal = {
      for (final question
          in controller.database.listQuestions(bankId: preview.bankId))
        question.externalId: question,
    };
    final attempt = controller.database.createPaper(
      bankId: preview.bankId,
      title: '复核试卷',
      questions: [
        byExternal['S-001']!,
        byExternal['M-001']!,
        byExternal['Q-001']!,
      ],
      suggestedDurationMs: 60000,
    );

    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ExamTheme.light().copyWith(platform: TargetPlatform.windows),
        home: WindowsOmrReviewPage(
          controller: controller,
          attempt: attempt,
          pickImage: () async => image,
          recognize: (_, _, expected) async {
            expect(expected, 2, reason: '期望值应等于选择题数');
            return WindowsOmrResult(
              sourceWidth: 1000,
              sourceHeight: 1400,
              pageQuad: const [
                [0.02, 0.02],
                [0.98, 0.02],
                [0.98, 0.98],
                [0.02, 0.98],
              ],
              questions: List.generate(
                expected,
                (index) => WindowsOmrQuestion(
                  number: index + 1,
                  selected: const {'A'},
                  confidence: 0.9,
                  bubbleQuad: _bubbleQuad(),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 识别两道选择题。
    await tester.tap(find.byKey(const ValueKey('windows-omr-pick-image')));
    await tester.pumpAndSettle();

    // 识别两道选择题；滚动到问答题卡片（懒加载列表）。
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('windows-omr-question-3')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('windows-omr-qa-text-3')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('windows-omr-qa-text-3')),
      '人工录入的问答回答',
    );
    await tester.pump();

    // 确认写入：问答题不产生事件，选择题照常。
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('windows-omr-confirm-submit')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('windows-omr-confirm-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认交卷'));
    await tester.pumpAndSettle();

    expect(attempt.status, AttemptStatus.submitted);
    expect(attempt.questions[2].textAnswer, '人工录入的问答回答');
    expect(
      controller.database.answerHistory(attempt.questions[2].question.id),
      isEmpty,
    );
    expect(
      controller.database.answerHistory(attempt.questions[0].question.id),
      hasLength(1),
    );
  });
}
