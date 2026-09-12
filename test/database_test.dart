import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_exam_app/data/app_database.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/domain/paper_policy.dart';

Question q(
  String id, {
  QuestionType type = QuestionType.single,
  ScoringRule scoringRule = const ScoringRule(),
}) => Question(
  id: id,
  bankId: 'bank',
  externalId: id,
  contentVersion: 1,
  type: type,
  stem: '题干 $id',
  options: const {'A': 'a', 'B': 'b', 'C': 'c', 'D': 'd'},
  answers: type == QuestionType.single ? const ['A'] : const ['A', 'C'],
  explanation: '解析',
  knowledgePoint: '考点',
  source: '测试',
  year: '2026',
  chapter: '一',
  tags: const ['测试'],
  media: const [],
  scoringRule: scoringRule,
  isActive: true,
);

ImportPreview preview(List<Question> questions) => ImportPreview(
  packagePath: 'test',
  bankId: 'bank',
  name: '测试库',
  subject: '测试',
  contentVersion: 1,
  questions: questions,
  mediaFiles: const {},
  issues: const [],
);

AnswerEvent event(String id, {bool correct = false}) => AnswerEvent(
  eventId: id,
  deviceId: 'device',
  questionId: 'q1',
  questionVersion: 1,
  sessionId: 's',
  attemptId: null,
  mode: 'practice',
  selected: correct ? const ['A'] : const ['B'],
  correct: correct,
  score: correct ? 1 : 0,
  durationMs: 1000,
  answeredAtUtc: DateTime.utc(2026, 8, 19),
  source: 'screen',
);

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.memory();
    db.importBank(preview([q('q1'), q('q2')]), reportJson: '{}');
  });
  tearDown(() => db.dispose());

  test('手动添加题目后可在题库中读取', () {
    db.addQuestion(q('q3'));

    expect(db.managedQuestionCount('bank'), 3);
    expect(db.questionById('q3')?.stem, '题干 q3');
    expect(db.progress('q3').state, StudyState.unseen);
  });

  test('删除题库从可选列表移除但保留题目数据', () {
    db.archiveBank('bank');

    expect(db.listBanks(), isEmpty);
    expect(db.questionById('q1'), isNotNull);
    expect(db.questionById('q1')!.isActive, isFalse);
  });

  test('删除历史试卷后从列表隐藏但保留答题数据', () {
    final paper = db.createPaper(
      bankId: 'bank',
      title: '待删除试卷',
      questions: [q('q1')],
      suggestedDurationMs: 60000,
    );
    expect(db.history(), hasLength(1));

    db.archiveAttempt(paper.attemptId);

    expect(db.history(), isEmpty);
    expect(db.loadAttempt(paper.attemptId), isNotNull);
  });

  test('相同事件重放幂等且不重复计错', () {
    expect(db.submitAnswer(event('e1')), isTrue);
    expect(db.submitAnswer(event('e1')), isFalse);
    final progress = db.progress('q1');
    expect(progress.seenCount, 1);
    expect(progress.wrongCount, 1);
    expect(progress.state, StudyState.wrong);
  });

  test('可查看并删除待同步项且不删除本地作答记录', () {
    db.submitAnswer(event('e1'));
    final pending = db.pendingOutboxSummary();
    expect(pending, hasLength(1));
    expect(pending.single['entity_type'], 'answer_event');
    expect(pending.single['entity_id'], 'e1');

    expect(db.deletePendingOutbox([pending.single['outbox_id']! as String]), 1);
    expect(db.pendingOutboxSummary(), isEmpty);
    expect(db.answerHistory('q1'), hasLength(1));
  });

  test('删除待同步项后重启不重建，内容变化后允许重新入队', () {
    db.dispose();
    final root = Directory.systemTemp.createTempSync(
      'personal-exam-dismissed-',
    );
    addTearDown(() {
      db.dispose();
      db = AppDatabase.memory();
      root.deleteSync(recursive: true);
    });
    final databasePath = p.join(root.path, 'exam.sqlite');
    db = AppDatabase.open(databasePath, publishesQuestionBanks: true);
    db.importBank(preview([q('q1'), q('q2')]), reportJson: '{}');
    final initial = db.pendingOutboxSummary();
    expect(initial, hasLength(3));
    expect(
      db.deletePendingOutbox(
        initial.map((item) => item['outbox_id']! as String),
      ),
      3,
    );
    db.dispose();

    db = AppDatabase.open(databasePath, publishesQuestionBanks: true);
    db.enqueueExistingCatalog(p.join(root.path, 'media'));
    expect(db.pendingOutboxSummary(), isEmpty);

    final original = q('q1');
    db.editQuestion(
      Question(
        id: original.id,
        bankId: original.bankId,
        externalId: original.externalId,
        contentVersion: original.contentVersion,
        type: original.type,
        stem: '修改后的题干',
        options: original.options,
        answers: original.answers,
        explanation: original.explanation,
        knowledgePoint: original.knowledgePoint,
        source: original.source,
        year: original.year,
        chapter: original.chapter,
        tags: original.tags,
        media: original.media,
        scoringRule: original.scoringRule,
        isActive: original.isActive,
      ),
    );
    expect(db.pendingOutboxSummary(), hasLength(1));
    expect(db.pendingOutboxSummary().single['entity_id'], 'q1');
  });

  test('相同 event_id 不同内容拒绝覆盖', () {
    db.submitAnswer(event('e1'));
    expect(
      () => db.submitAnswer(event('e1', correct: true)),
      throwsA(isA<EventConflictException>()),
    );
    expect(db.progress('q1').wrongCount, 1);
  });

  test('试卷未答题不生成事件且重复交卷不重复', () {
    final paper = db.createPaper(
      bankId: 'bank',
      title: '卷',
      questions: [q('q1'), q('q2')],
      suggestedDurationMs: 60000,
    );
    paper.questions.first.selected.add('A');
    paper.durationMs = 5000;
    db.submitPaper(paper);
    expect(db.progress('q1').state, StudyState.mastered);
    expect(db.progress('q2').state, StudyState.unseen);
    expect(db.answerHistory('q1'), hasLength(1));
    expect(db.answerHistory('q2'), isEmpty);
    db.submitPaper(paper);
    expect(db.answerHistory('q1'), hasLength(1));
  });

  test('试卷统一评分策略经 SQLite scoring_rule_json 读回且百分比一致', () {
    final paper = db.createPaper(
      bankId: 'bank',
      title: '统一评分卷',
      questions: [
        q('q1', scoringRule: const ScoringRule(singleScore: 5)),
        q(
          'q2',
          type: QuestionType.multiple,
          scoringRule: const ScoringRule(multipleScore: 10),
        ),
      ],
      suggestedDurationMs: 0,
      compositionMode: PaperCompositionMode.realExam,
    );
    paper.questions[0].selected.add('A');
    paper.questions[1].selected.add('A');
    db.submitPaper(paper);

    expect(paper.score, 1.5);
    expect(paper.maxScore, 3);
    expect(paper.percentage, 50);
    final loaded = db.loadAttempt(paper.attemptId)!;
    expect(loaded.compositionMode, PaperCompositionMode.realExam);
    expect(loaded.scoringPolicy.toJson(), const {
          'kind': 'uniform_exam_v2',
          'single_score': 1.0,
          'multiple_score': 2.0,
          'partial_credit': true,
          'partial_per_correct_option': 0.5,
          'wrong_option_makes_zero': true,
        });
    expect(loaded.score, 1.5);
    expect(loaded.maxScore, 3);
    expect(loaded.percentage, 50);
  });

  test('阅卷识别与人工修正来源写入作答事件', () {
    final paper = db.createPaper(
      bankId: 'bank',
      title: '纸质卷',
      questions: [q('q1'), q('q2')],
      suggestedDurationMs: 0,
    );
    paper.questions[0].selected.add('A');
    paper.questions[1].selected.add('B');
    db.submitPaper(
      paper,
      sourceByPosition: const {0: 'paper_omr_scan', 1: 'manual_correction'},
    );
    expect(db.answerHistory('q1').single['source'], 'paper_omr_scan');
    expect(db.answerHistory('q2').single['source'], 'manual_correction');
  });

  test('答题卡压缩序号按题库顺序编码', () {
    final positions = db.omrQuestionPositions('bank', ['q2', 'q1']);
    expect(positions, [1, 0]);
  });

  test('题目更新不改变草稿试卷快照', () {
    final paper = db.createPaper(
      bankId: 'bank',
      title: '卷',
      questions: [q('q1')],
      suggestedDurationMs: 0,
    );
    db.editQuestion(
      Question(
        id: 'q1',
        bankId: 'bank',
        externalId: 'q1',
        contentVersion: 2,
        type: QuestionType.single,
        stem: '新题干',
        options: const {'A': 'a', 'B': 'b'},
        answers: const ['B'],
        explanation: '',
        knowledgePoint: '',
        source: '',
        year: '',
        chapter: '',
        tags: const [],
        media: const [],
        scoringRule: const ScoringRule(),
        isActive: true,
      ),
    );
    final loaded = db.loadAttempt(paper.attemptId)!;
    expect(loaded.questions.single.question.stem, '题干 q1');
    expect(loaded.questions.single.question.answers, ['A']);
  });

  test('已交卷试卷显示题库最新内容且不改写答题事件', () {
    final paper = db.createPaper(
      bankId: 'bank',
      title: '卷',
      questions: [q('q1')],
      suggestedDurationMs: 0,
    );
    paper.questions.first.selected.add('A');
    db.submitPaper(paper);
    expect(db.progress('q1').state, StudyState.mastered);

    db.editQuestion(
      Question(
        id: 'q1',
        bankId: 'bank',
        externalId: 'q1',
        contentVersion: 1,
        type: QuestionType.single,
        stem: '新题干',
        options: const {'A': 'a', 'B': 'b'},
        answers: const ['B'],
        explanation: '',
        knowledgePoint: '',
        source: '',
        year: '',
        chapter: '',
        tags: const [],
        media: const [],
        scoringRule: const ScoringRule(),
        isActive: true,
      ),
    );

    final loaded = db.loadAttempt(paper.attemptId)!;
    expect(loaded.questions.single.question.stem, '新题干');
    expect(loaded.questions.single.question.answers, ['B']);
    // 交卷时写入的答题事件保持不可变：仍按原答案 A 判定为答对。
    expect(db.answerHistory('q1').single['correct'], 1);
    expect(db.progress('q1').state, StudyState.mastered);
  });

  test('年份、章节、标签和题型筛选使用题库结构字段', () {
    expect(
      db.listQuestions(bankId: 'bank', year: '2026', tag: '测试'),
      hasLength(2),
    );
    expect(
      db.listQuestions(
        bankId: 'bank',
        chapter: '一',
        tag: '测试',
        type: QuestionType.single,
      ),
      hasLength(2),
    );
    expect(db.listQuestions(bankId: 'bank', tag: '不存在'), isEmpty);
    expect(db.tagStats('bank').single['label'], '测试');
  });

  test('题库管理支持计数和分页读取', () {
    db.importBank(
      preview([q('q1'), q('q2'), q('q3'), q('q4')]),
      reportJson: '{}',
    );

    expect(db.managedQuestionCount('bank'), 4);
    expect(
      db
          .managedQuestions('bank', limit: 2, offset: 1)
          .map((question) => question.id),
      ['q2', 'q3'],
    );
  });

  test('重置题库答题状态但保留收藏和笔记', () {
    db.submitAnswer(event('e1'));
    db.updateQuestionMeta(
      'q1',
      favorite: true,
      uncertain: true,
      excluded: true,
      note: '保留这条笔记',
    );
    db.createPaper(
      bankId: 'bank',
      title: '未完成试卷',
      questions: [q('q1')],
      suggestedDurationMs: 60000,
    );

    expect(db.latestDraft('bank'), isNotNull);
    expect(db.dashboard('bank').pendingSync, 2);

    db.resetProgress('bank');

    final progress = db.progress('q1');
    expect(progress.state, StudyState.unseen);
    expect(progress.seenCount, 0);
    expect(progress.correctCount, 0);
    expect(progress.wrongCount, 0);
    expect(progress.everWrong, isFalse);
    expect(progress.isFavorite, isTrue);
    expect(progress.isUncertain, isTrue);
    expect(progress.isExcluded, isTrue);
    expect(progress.personalNote, '保留这条笔记');
    expect(db.answerHistory('q1'), isEmpty);
    expect(db.latestDraft('bank'), isNull);
    expect(db.dashboard('bank').pendingSync, 1);
  });
}
