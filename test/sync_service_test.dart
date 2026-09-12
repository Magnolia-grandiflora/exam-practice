import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personal_exam_app/data/app_database.dart';
import 'package:personal_exam_app/data/app_paths.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/domain/paper_policy.dart';
import 'package:personal_exam_app/services/bank_importer.dart';
import 'package:personal_exam_app/services/sync_service.dart';

Question _question(String id) => Question(
  id: id,
  bankId: 'bank',
  externalId: id,
  contentVersion: 1,
  type: QuestionType.single,
  stem: '题干 $id',
  options: const {'A': '甲', 'B': '乙'},
  answers: const ['A'],
  explanation: '解析',
  knowledgePoint: '考点',
  source: '测试',
  year: '2026',
  chapter: '一',
  tags: const ['同步'],
  media: const [],
  scoringRule: const ScoringRule(),
  isActive: true,
);

void _seed(AppDatabase db) {
  db.importBank(
    ImportPreview(
      packagePath: 'test',
      bankId: 'bank',
      name: '测试库',
      subject: '同步',
      contentVersion: 1,
      questions: [_question('q1'), _question('q2')],
      mediaFiles: const {},
      issues: const [],
    ),
    reportJson: '{}',
  );
}

AnswerEvent _event(
  String eventId,
  String questionId, {
  String deviceId = 'android',
  bool correct = true,
}) => AnswerEvent(
  eventId: eventId,
  deviceId: deviceId,
  questionId: questionId,
  questionVersion: 1,
  sessionId: 'session',
  attemptId: null,
  mode: 'practice',
  selected: correct ? const ['A'] : const ['B'],
  correct: correct,
  score: correct ? 1 : 0,
  durationMs: 1200,
  answeredAtUtc: DateTime.utc(2026, 8, 19, 10),
  source: 'screen',
);

Map<String, Object?> _change(
  String type,
  Map<String, Object?> payload, {
  String? hash,
}) => {
  'entity_type': type,
  'entity_id':
      payload['event_id'] ??
      payload['attempt_id'] ??
      payload['question_id'] ??
      payload['bank_id'] ??
      payload['chunk_id'],
  'payload': payload,
  'payload_hash': ?hash,
};

class _FakeGateway implements CloudSyncGateway {
  _FakeGateway(this.handler);

  final SyncExchangeResult Function(
    String deviceId,
    String cursor,
    List<Map<String, Object?>> items,
  )
  handler;

  @override
  Future<SyncExchangeResult> exchange({
    required String deviceId,
    required String cursor,
    required List<Map<String, Object?>> outboxItems,
  }) async => handler(deviceId, cursor, outboxItems);
}

void main() {
  test('远端媒体拒绝目录穿越 bank_id 且不推进游标', () {
    final db = AppDatabase.memory();
    try {
      expect(
        () => db.applySyncExchange(
          acceptedOutboxIds: const {},
          changes: [
            _change('question_media_chunk', {
              'chunk_id': 'unsafe',
              'bank_id': '../escape',
              'relative_path': 'media/image.png',
              'catalog_version': 1,
              'file_sha256': List.filled(64, '0').join(),
              'total_size': 0,
              'chunk_index': 0,
              'chunk_count': 1,
            }),
          ],
          nextCursor: 'unsafe-cursor',
        ),
        throwsFormatException,
      );
      expect(db.syncCursor, isEmpty);
    } finally {
      db.dispose();
    }
  });

  test('Supabase 网关调用带 JWT 的 PostgREST RPC', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/rest/v1/rpc/sync_exchange');
      expect(request.headers['apikey'], 'sb_publishable_test');
      expect(request.headers['authorization'], 'Bearer access-token');
      expect(jsonDecode(request.body), {
        'p_schema_version': 2,
        'p_device_id': 'windows-device',
        'p_cursor': 17,
        'p_items': [
          {'outbox_id': 'answer_event:event-1'},
        ],
      });
      return http.Response(
        jsonEncode({
          'accepted_outbox_ids': ['answer_event:event-1'],
          'changes': const [],
          'next_cursor': '18',
        }),
        200,
      );
    });
    final result =
        await SupabaseSyncGateway(
          projectUrl: Uri.parse('https://example.supabase.co'),
          publishableKey: 'sb_publishable_test',
          accessToken: 'access-token',
          client: client,
        ).exchange(
          deviceId: 'windows-device',
          cursor: '17',
          outboxItems: const [
            {'outbox_id': 'answer_event:event-1'},
          ],
        );
    expect(result.acceptedOutboxIds, {'answer_event:event-1'});
    expect(result.nextCursor, '18');
  });

  test('同一道题再次修改后会重新进入 outbox 且携带最新内容', () {
    final db = AppDatabase.memory();
    _seed(db);
    try {
      db.updateQuestionMeta('q1', note: '第一次笔记');
      final first = db.pendingOutbox(includeDeferred: true).single;
      db.markOutboxComplete(first['outbox_id']! as String);

      db.updateQuestionMeta('q1', note: '第二次笔记');
      final pending = db.pendingOutbox(includeDeferred: true);
      expect(pending, hasLength(1));
      expect(
        jsonDecode(pending.single['payload_json']! as String),
        containsPair('personal_note_markdown', '第二次笔记'),
      );
    } finally {
      db.dispose();
    }
  });

  test('一次交换同时确认上传、合并远端事件并推进游标', () async {
    final db = AppDatabase.memory();
    _seed(db);
    try {
      db.submitAnswer(_event('local-1', 'q1', deviceId: 'windows'));
      final remote = _event('remote-1', 'q2');
      final gateway = _FakeGateway((device, cursor, items) {
        expect(device, isNotEmpty);
        expect(cursor, isEmpty);
        expect(
          items.map((item) => item['outbox_id']),
          contains('answer_event:local-1'),
        );
        return SyncExchangeResult(
          acceptedOutboxIds: {'answer_event:local-1'},
          changes: [_change('answer_event', remote.toJson())],
          nextCursor: 'cursor-1',
        );
      });

      final report = await SyncService(db).synchronize(gateway);
      expect(report.uploaded, 1);
      expect(report.downloaded, 1);
      expect(report.failed, 0);
      expect(db.syncCursor, 'cursor-1');
      expect(db.progress('q2').seenCount, 1);
      expect(db.progress('q2').state, StudyState.mastered);
      expect(db.pendingOutbox(includeDeferred: true), isEmpty);

      db.applySyncExchange(
        acceptedOutboxIds: const {},
        changes: [_change('answer_event', remote.toJson())],
        nextCursor: 'cursor-2',
      );
      expect(db.progress('q2').seenCount, 1, reason: '远端事件重放必须幂等');
      expect(db.syncCursor, 'cursor-2');
    } finally {
      db.dispose();
    }
  });

  test('Windows 题库、题目、媒体和答题可在空 Android 数据库完整落地', () {
    final sourceRoot = Directory.systemTemp.createTempSync('catalog-source-');
    final targetRoot = Directory.systemTemp.createTempSync('catalog-target-');
    final source = AppDatabase.memory(publishesQuestionBanks: true);
    final target = AppDatabase.memory(archivesRemotePapers: false);
    try {
      final importer = BankImporter(source, AppPaths.at(sourceRoot));
      final preview = importer.previewFile('assets/test-bank/test-bank.zip');
      importer.commit(preview);
      source.submitAnswer(
        _event(
          'catalog-answer',
          preview.questions.first.id,
          deviceId: 'windows',
        ),
      );
      final changes = source
          .pendingOutbox(includeDeferred: true)
          .map(
            (item) => <String, Object?>{
              'entity_type': item['entity_type'],
              'entity_id': item['entity_id'],
              'payload': jsonDecode(item['payload_json'] as String),
              'payload_hash': item['payload_hash'],
              'source_device_id': source.deviceId,
            },
          )
          .toList()
          .reversed
          .toList();

      target.applySyncExchange(
        acceptedOutboxIds: const {},
        changes: changes,
        nextCursor: 'catalog-complete',
        mediaRoot: AppPaths.at(targetRoot).media.path,
      );

      expect(target.listBanks().single.questionCount, 15);
      expect(target.questionById(preview.questions.first.id)!.stem, isNotEmpty);
      expect(target.progress(preview.questions.first.id).seenCount, 1);
      expect(target.deferredSyncCount, 0);
      for (final media in preview.mediaFiles.entries) {
        final materialized = File(
          '${AppPaths.at(targetRoot).media.path}${Platform.pathSeparator}'
          '${preview.bankId}${Platform.pathSeparator}v${preview.contentVersion}'
          '${Platform.pathSeparator}${media.key.split('/').last}',
        );
        expect(materialized.readAsBytesSync(), media.value);
      }
    } finally {
      source.dispose();
      target.dispose();
      sourceRoot.deleteSync(recursive: true);
      targetRoot.deleteSync(recursive: true);
    }
  });

  test('先到达的答题事件等待对应题目后自动重放', () {
    final source = AppDatabase.memory(publishesQuestionBanks: true);
    final target = AppDatabase.memory(archivesRemotePapers: false);
    _seed(source);
    try {
      final answer = _event('deferred-answer', 'q1', deviceId: 'windows');
      target.applySyncExchange(
        acceptedOutboxIds: const {},
        changes: [_change('answer_event', answer.toJson())],
        nextCursor: '1',
      );
      expect(target.deferredSyncCount, 1);
      expect(target.answerHistory('q1'), isEmpty);

      final catalogChanges = source
          .pendingOutbox(includeDeferred: true)
          .where(
            (item) =>
                item['entity_type'] == 'question_bank' ||
                item['entity_id'] == 'q1',
          )
          .map(
            (item) => <String, Object?>{
              'entity_type': item['entity_type'],
              'entity_id': item['entity_id'],
              'payload': jsonDecode(item['payload_json'] as String),
              'payload_hash': item['payload_hash'],
            },
          )
          .toList();
      target.applySyncExchange(
        acceptedOutboxIds: const {},
        changes: catalogChanges,
        nextCursor: '2',
      );
      expect(target.deferredSyncCount, 0);
      expect(target.progress('q1').seenCount, 1);
    } finally {
      source.dispose();
      target.dispose();
    }
  });

  test('超过 100 个题库实体会自动分批上传直到 outbox 清空', () async {
    final db = AppDatabase.memory(publishesQuestionBanks: true);
    final questions = List.generate(205, (index) => _question('bulk-$index'));
    db.importBank(
      ImportPreview(
        packagePath: 'bulk',
        bankId: 'bank',
        name: '批量题库',
        subject: '同步',
        contentVersion: 1,
        questions: questions,
        mediaFiles: const {},
        issues: const [],
      ),
      reportJson: '{}',
    );
    var calls = 0;
    final gateway = _FakeGateway((device, cursor, items) {
      calls++;
      return SyncExchangeResult(
        acceptedOutboxIds: items
            .map((item) => item['outbox_id']! as String)
            .toSet(),
        changes: const [],
        nextCursor: '$calls',
      );
    });
    try {
      final report = await SyncService(db).synchronize(gateway);
      expect(calls, 3);
      expect(report.uploaded, 206);
      expect(report.failed, 0);
      expect(db.pendingOutbox(includeDeferred: true), isEmpty);
    } finally {
      db.dispose();
    }
  });

  test('同 event_id 不同内容保留本地并写入冲突记录', () {
    final db = AppDatabase.memory();
    _seed(db);
    try {
      db.submitAnswer(_event('same', 'q1', deviceId: 'windows'));
      final conflicting = _event('same', 'q1', correct: false);
      db.applySyncExchange(
        acceptedOutboxIds: const {},
        changes: [_change('answer_event', conflicting.toJson())],
        nextCursor: 'after-conflict',
      );
      expect(db.progress('q1').correctCount, 1);
      expect(db.progress('q1').wrongCount, 0);
      expect(db.syncConflicts(), hasLength(1));
      expect(db.syncCursor, 'after-conflict');
    } finally {
      db.dispose();
    }
  });

  test('任一远端变化无法落库时整批回滚且游标不推进', () async {
    final db = AppDatabase.memory();
    _seed(db);
    try {
      db.submitAnswer(_event('pending', 'q1', deviceId: 'windows'));
      final gateway = _FakeGateway(
        (device, cursor, items) => SyncExchangeResult(
          acceptedOutboxIds: {'answer_event:pending'},
          changes: [
            {
              'entity_type': 'future_unknown_entity',
              'payload': {'id': 'x'},
            },
          ],
          nextCursor: 'must-not-commit',
        ),
      );
      final report = await SyncService(db).synchronize(gateway);
      expect(report.message, contains('同步失败'));
      expect(db.syncCursor, isEmpty);
      expect(db.pendingOutbox(includeDeferred: true), hasLength(1));
    } finally {
      db.dispose();
    }
  });

  test('本机推送的试卷被拉回时不归档，仍保留在历史试卷', () {
    final db = AppDatabase.memory();
    _seed(db);
    try {
      final paper = db.createPaper(
        bankId: 'bank',
        title: '本机试卷',
        questions: [_question('q1'), _question('q2')],
        suggestedDurationMs: 60000,
      );
      paper.questions.first.selected.add('A');
      paper.durationMs = 5000;
      db.submitPaper(paper);
      final item = db
          .pendingOutbox(includeDeferred: true)
          .firstWhere((row) => row['entity_type'] == 'paper_attempt');
      final payload = (jsonDecode(item['payload_json'] as String) as Map)
          .cast<String, Object?>();

      // 模拟下一次同步：游标推进后把自己刚推送的试卷又拉了回来。
      db.applySyncExchange(
        acceptedOutboxIds: const {},
        changes: [
          _change(
            'paper_attempt',
            payload,
            hash: item['payload_hash'] as String,
          ),
        ],
        nextCursor: 'self-cursor',
      );

      expect(
        db.history().map((row) => row.attemptId),
        contains(paper.attemptId),
      );
      expect(
        db
            .pendingOutbox(includeDeferred: true)
            .map((row) => row['entity_type']),
        isNot(contains('paper_archive_ack')),
      );
    } finally {
      db.dispose();
    }
  });

  test('Windows 写入远端完整试卷后生成归档确认', () {
    final source = AppDatabase.memory();
    final windows = AppDatabase.memory();
    _seed(source);
    _seed(windows);
    try {
      final paper = source.createPaper(
        bankId: 'bank',
        title: 'Android 试卷',
        questions: [_question('q1'), _question('q2')],
        suggestedDurationMs: 60000,
      );
      paper.questions.first.selected.add('A');
      paper.durationMs = 5000;
      source.submitPaper(paper);
      final item = source
          .pendingOutbox(includeDeferred: true)
          .firstWhere((row) => row['entity_type'] == 'paper_attempt');
      final payload = (jsonDecode(item['payload_json'] as String) as Map)
          .cast<String, Object?>();

      windows.applySyncExchange(
        acceptedOutboxIds: const {},
        changes: [
          _change(
            'paper_attempt',
            payload,
            hash: item['payload_hash'] as String,
          ),
        ],
        nextCursor: 'paper-cursor',
      );

      final loaded = windows.loadAttempt(paper.attemptId);
      expect(loaded, isNotNull);
      expect(loaded!.questions, hasLength(2));
      expect(loaded.compositionMode, PaperCompositionMode.realExam);
      expect(loaded.scoringPolicy.toJson(), const {
          'kind': 'uniform_exam_v2',
          'single_score': 1.0,
          'multiple_score': 2.0,
          'partial_credit': true,
          'partial_per_correct_option': 0.5,
          'wrong_option_makes_zero': true,
        });
      expect(loaded.percentage, 50);
      expect(loaded.questions.first.question.stem, '题干 q1');
      expect(
        windows
            .pendingOutbox(includeDeferred: true)
            .map((row) => row['entity_type']),
        contains('paper_archive_ack'),
      );
    } finally {
      source.dispose();
      windows.dispose();
    }
  });

  test('Android 拉取远端试卷不代替 Windows 发送归档确认', () {
    final source = AppDatabase.memory();
    final android = AppDatabase.memory(archivesRemotePapers: false);
    _seed(source);
    _seed(android);
    try {
      final paper = source.createPaper(
        bankId: 'bank',
        title: 'Windows 试卷',
        questions: [_question('q1')],
        suggestedDurationMs: 60000,
      );
      paper.questions.first.selected.add('A');
      source.submitPaper(paper);
      final item = source
          .pendingOutbox(includeDeferred: true)
          .firstWhere((row) => row['entity_type'] == 'paper_attempt');
      final payload = (jsonDecode(item['payload_json'] as String) as Map)
          .cast<String, Object?>();

      android.applySyncExchange(
        acceptedOutboxIds: const {},
        changes: [
          _change(
            'paper_attempt',
            payload,
            hash: item['payload_hash'] as String,
          ),
        ],
        nextCursor: 'android-paper-cursor',
      );

      expect(android.loadAttempt(paper.attemptId), isNotNull);
      expect(
        android
            .pendingOutbox(includeDeferred: true)
            .where((row) => row['entity_type'] == 'paper_archive_ack'),
        isEmpty,
      );
    } finally {
      source.dispose();
      android.dispose();
    }
  });

  test('双方编辑个人笔记时不静默覆盖并保留冲突', () {
    final db = AppDatabase.memory();
    _seed(db);
    try {
      db.updateQuestionMeta('q1', note: 'Windows 笔记');
      final remote = <String, Object?>{
        'question_id': 'q1',
        'is_favorite': true,
        'is_uncertain': false,
        'is_excluded': false,
        'personal_note_markdown': 'Android 笔记',
        'base_version': 0,
        'version': 1,
        'base_note_hash': 'different-base',
        'device_id': 'android',
        'updated_at_utc': DateTime.utc(2030, 1, 1).toIso8601String(),
      };
      db.applySyncExchange(
        acceptedOutboxIds: const {},
        changes: [_change('question_progress_control', remote)],
        nextCursor: 'notes',
      );
      expect(db.progress('q1').personalNote, 'Windows 笔记');
      expect(db.progress('q1').isFavorite, isTrue);
      expect(
        db.syncConflicts().single['entity_type'],
        'question_progress_control',
      );
    } finally {
      db.dispose();
    }
  });
}
