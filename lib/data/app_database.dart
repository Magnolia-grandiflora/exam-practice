import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../domain/bank_identity.dart';
import '../domain/paper_policy.dart';
import '../domain/policies.dart';

class EventConflictException implements Exception {
  const EventConflictException(this.eventId);
  final String eventId;
  @override
  String toString() => '事件 $eventId 与已有内容冲突，已停止覆盖';
}

class AppDatabase {
  AppDatabase._(
    this._db, {
    required this.archivesRemotePapers,
    required this.publishesQuestionBanks,
  });

  final Database _db;
  final bool archivesRemotePapers;
  final bool publishesQuestionBanks;
  static const _uuid = Uuid();
  static const mediaChunkSize = 512 * 1024;

  factory AppDatabase.open(
    String path, {
    bool archivesRemotePapers = true,
    bool publishesQuestionBanks = false,
  }) {
    final db = sqlite3.open(path);
    final wrapper = AppDatabase._(
      db,
      archivesRemotePapers: archivesRemotePapers,
      publishesQuestionBanks: publishesQuestionBanks,
    );
    wrapper._initialize();
    return wrapper;
  }

  factory AppDatabase.memory({
    bool archivesRemotePapers = true,
    bool publishesQuestionBanks = false,
  }) {
    final wrapper = AppDatabase._(
      sqlite3.openInMemory(),
      archivesRemotePapers: archivesRemotePapers,
      publishesQuestionBanks: publishesQuestionBanks,
    );
    wrapper._initialize();
    return wrapper;
  }

  void _initialize() {
    _db.execute('PRAGMA foreign_keys = ON');
    _db.execute('PRAGMA busy_timeout = 5000');
    _db.execute('PRAGMA journal_mode = WAL');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        applied_at_utc TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS question_banks (
        bank_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        subject TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        schema_version INTEGER NOT NULL,
        content_version INTEGER NOT NULL,
        source_name TEXT NOT NULL DEFAULT '',
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      );
      CREATE TABLE IF NOT EXISTS questions (
        question_id TEXT PRIMARY KEY,
        bank_id TEXT NOT NULL REFERENCES question_banks(bank_id),
        external_id TEXT,
        content_version INTEGER NOT NULL,
        question_type TEXT NOT NULL CHECK(question_type IN ('single','multiple','qa')),
        stem_markdown TEXT NOT NULL,
        options_json TEXT NOT NULL,
        correct_answers_json TEXT NOT NULL,
        explanation_markdown TEXT NOT NULL DEFAULT '',
        knowledge_point TEXT NOT NULL DEFAULT '',
        source TEXT NOT NULL DEFAULT '',
        year TEXT NOT NULL DEFAULT '',
        chapter TEXT NOT NULL DEFAULT '',
        tags_json TEXT NOT NULL DEFAULT '[]',
        media_json TEXT NOT NULL DEFAULT '[]',
        scoring_rule_json TEXT NOT NULL DEFAULT '{}',
        content_hash TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_questions_bank ON questions(bank_id, is_active);
      CREATE INDEX IF NOT EXISTS idx_questions_filters ON questions(bank_id, year, chapter, question_type);
      CREATE TABLE IF NOT EXISTS question_progress (
        question_id TEXT PRIMARY KEY REFERENCES questions(question_id),
        state TEXT NOT NULL DEFAULT 'unseen' CHECK(state IN ('unseen','wrong','mastered')),
        seen_count INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0,
        wrong_count INTEGER NOT NULL DEFAULT 0,
        ever_wrong INTEGER NOT NULL DEFAULT 0,
        last_selected_json TEXT NOT NULL DEFAULT '[]',
        last_result TEXT,
        last_answered_at_utc TEXT,
        total_duration_ms INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_uncertain INTEGER NOT NULL DEFAULT 0,
        is_excluded INTEGER NOT NULL DEFAULT 0,
        personal_note_markdown TEXT NOT NULL DEFAULT '',
        updated_at_utc TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1
      );
      CREATE INDEX IF NOT EXISTS idx_progress_state ON question_progress(state, is_excluded);
      CREATE TABLE IF NOT EXISTS answer_events (
        event_id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        question_id TEXT NOT NULL REFERENCES questions(question_id),
        question_version INTEGER NOT NULL,
        session_id TEXT NOT NULL,
        attempt_id TEXT,
        mode TEXT NOT NULL,
        selected_json TEXT NOT NULL,
        correct INTEGER NOT NULL,
        score REAL NOT NULL,
        duration_ms INTEGER NOT NULL,
        answered_at_utc TEXT NOT NULL,
        source TEXT NOT NULL,
        schema_version INTEGER NOT NULL,
        sync_state TEXT NOT NULL DEFAULT 'pending',
        created_locally_at_utc TEXT NOT NULL,
        payload_hash TEXT NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_events_question ON answer_events(question_id, answered_at_utc);
      CREATE TABLE IF NOT EXISTS paper_attempts (
        attempt_id TEXT PRIMARY KEY,
        paper_id TEXT NOT NULL,
        title TEXT NOT NULL,
        bank_id TEXT NOT NULL,
        mode TEXT NOT NULL DEFAULT 'paper',
        status TEXT NOT NULL CHECK(status IN ('draft','submitted','abandoned')),
        scoring_rule_json TEXT NOT NULL,
        timer_state_json TEXT NOT NULL DEFAULT '{}',
        started_at_utc TEXT NOT NULL,
        submitted_at_utc TEXT,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        suggested_duration_ms INTEGER NOT NULL DEFAULT 0,
        overtime_ms INTEGER NOT NULL DEFAULT 0,
        score REAL,
        max_score REAL,
        source_device_id TEXT NOT NULL,
        current_index INTEGER NOT NULL DEFAULT 0,
        archived_locally INTEGER NOT NULL DEFAULT 0,
        cloud_archive_ack INTEGER NOT NULL DEFAULT 0,
        created_at_utc TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS paper_attempt_questions (
        attempt_id TEXT NOT NULL REFERENCES paper_attempts(attempt_id) ON DELETE CASCADE,
        position INTEGER NOT NULL,
        question_id TEXT NOT NULL,
        question_version INTEGER NOT NULL,
        event_id TEXT NOT NULL,
        snapshot_json TEXT NOT NULL,
        selected_json TEXT NOT NULL DEFAULT '[]',
        uncertain INTEGER NOT NULL DEFAULT 0,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(attempt_id, position),
        UNIQUE(event_id)
      );
      CREATE TABLE IF NOT EXISTS sync_outbox (
        outbox_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        payload_hash TEXT NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at_utc TEXT,
        last_error TEXT,
        created_at_utc TEXT NOT NULL,
        completed_at_utc TEXT
      );
      CREATE INDEX IF NOT EXISTS idx_outbox_pending ON sync_outbox(completed_at_utc, next_retry_at_utc);
      CREATE TABLE IF NOT EXISTS dismissed_sync_outbox (
        outbox_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload_fingerprint TEXT NOT NULL,
        dismissed_at_utc TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS sync_conflicts (
        conflict_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        local_payload TEXT NOT NULL,
        incoming_payload TEXT NOT NULL,
        source_device TEXT,
        created_at_utc TEXT NOT NULL,
        resolved_at_utc TEXT
      );
      CREATE TABLE IF NOT EXISTS app_settings (
        setting_key TEXT PRIMARY KEY,
        value_json TEXT NOT NULL,
        sync_scope TEXT NOT NULL DEFAULT 'local',
        updated_at_utc TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS question_bank_imports (
        import_id TEXT PRIMARY KEY,
        bank_id TEXT NOT NULL,
        source_file TEXT NOT NULL,
        content_version INTEGER NOT NULL,
        report_json TEXT NOT NULL,
        imported_at_utc TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS local_backups (
        backup_id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        reason TEXT NOT NULL,
        integrity_result TEXT NOT NULL,
        created_at_utc TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS question_control_versions (
        question_id TEXT PRIMARY KEY REFERENCES questions(question_id),
        version INTEGER NOT NULL DEFAULT 0,
        updated_at_utc TEXT NOT NULL,
        source_device_id TEXT NOT NULL DEFAULT ''
      );
      CREATE TABLE IF NOT EXISTS synced_entity_hashes (
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload_hash TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL,
        PRIMARY KEY(entity_type, entity_id)
      );
      CREATE TABLE IF NOT EXISTS deferred_sync_changes (
        deferred_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        change_json TEXT NOT NULL,
        payload_hash TEXT NOT NULL,
        source_device_id TEXT,
        created_at_utc TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS synced_media_chunks (
        chunk_id TEXT PRIMARY KEY,
        bank_id TEXT NOT NULL,
        catalog_version INTEGER NOT NULL,
        relative_path TEXT NOT NULL,
        file_sha256 TEXT NOT NULL,
        total_size INTEGER NOT NULL,
        chunk_index INTEGER NOT NULL,
        chunk_count INTEGER NOT NULL,
        content BLOB NOT NULL,
        materialized_at_utc TEXT
      );
      CREATE INDEX IF NOT EXISTS idx_synced_media_ready
        ON synced_media_chunks(bank_id,catalog_version,relative_path,file_sha256,chunk_index);
    ''');
    _db.execute(
      'INSERT OR IGNORE INTO schema_migrations(version, applied_at_utc) VALUES(1, ?)',
      [_now()],
    );
    _db.execute(
      'INSERT OR IGNORE INTO schema_migrations(version, applied_at_utc) VALUES(2, ?)',
      [_now()],
    );
    _db.execute(
      'INSERT OR IGNORE INTO schema_migrations(version, applied_at_utc) VALUES(3, ?)',
      [_now()],
    );
    _migrateV4QuestionTypeQa();
  }

  /// v4：问答题题型。旧库的 questions 表 CHECK 约束只允许 single/multiple，
  /// 需按 SQLite 官方流程重建表放宽约束；新库建表已含 qa，仅需登记版本。
  void _migrateV4QuestionTypeQa() {
    final applied = _db
        .select('SELECT version FROM schema_migrations')
        .map((row) => row['version'] as int)
        .toSet();
    if (applied.contains(4)) return;
    final tableSql = _db
        .select(
          "SELECT sql FROM sqlite_master WHERE type='table' AND name='questions'",
        )
        .first['sql'] as String;
    if (!tableSql.contains("'qa'")) {
      _db.execute('PRAGMA foreign_keys=OFF');
      _db.execute('BEGIN');
      try {
        _db.execute('''
          CREATE TABLE questions_new (
            question_id TEXT PRIMARY KEY,
            bank_id TEXT NOT NULL REFERENCES question_banks(bank_id),
            external_id TEXT,
            content_version INTEGER NOT NULL,
            question_type TEXT NOT NULL CHECK(question_type IN ('single','multiple','qa')),
            stem_markdown TEXT NOT NULL,
            options_json TEXT NOT NULL,
            correct_answers_json TEXT NOT NULL,
            explanation_markdown TEXT NOT NULL DEFAULT '',
            knowledge_point TEXT NOT NULL DEFAULT '',
            source TEXT NOT NULL DEFAULT '',
            year TEXT NOT NULL DEFAULT '',
            chapter TEXT NOT NULL DEFAULT '',
            tags_json TEXT NOT NULL DEFAULT '[]',
            media_json TEXT NOT NULL DEFAULT '[]',
            scoring_rule_json TEXT NOT NULL DEFAULT '{}',
            content_hash TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at_utc TEXT NOT NULL,
            updated_at_utc TEXT NOT NULL
          )
        ''');
        _db.execute('''
          INSERT INTO questions_new(
            question_id,bank_id,external_id,content_version,question_type,
            stem_markdown,options_json,correct_answers_json,explanation_markdown,
            knowledge_point,source,year,chapter,tags_json,media_json,
            scoring_rule_json,content_hash,is_active,created_at_utc,updated_at_utc)
          SELECT
            question_id,bank_id,external_id,content_version,question_type,
            stem_markdown,options_json,correct_answers_json,explanation_markdown,
            knowledge_point,source,year,chapter,tags_json,media_json,
            scoring_rule_json,content_hash,is_active,created_at_utc,updated_at_utc
          FROM questions
        ''');
        _db.execute('DROP TABLE questions');
        _db.execute('ALTER TABLE questions_new RENAME TO questions');
        _db.execute(
          'CREATE INDEX IF NOT EXISTS idx_questions_bank ON questions(bank_id, is_active)',
        );
        _db.execute(
          'CREATE INDEX IF NOT EXISTS idx_questions_filters ON questions(bank_id, year, chapter, question_type)',
        );
        _db.execute('COMMIT');
      } on Object {
        _db.execute('ROLLBACK');
        rethrow;
      } finally {
        _db.execute('PRAGMA foreign_keys=ON');
      }
    }
    _db.execute(
      'INSERT INTO schema_migrations(version, applied_at_utc) VALUES(4, ?)',
      [_now()],
    );
  }

  String get deviceId {
    final result = _db.select(
      "SELECT value_json FROM app_settings WHERE setting_key='device_id'",
    );
    if (result.isNotEmpty) {
      return jsonDecode(result.first['value_json'] as String) as String;
    }
    final id = _uuid.v4();
    setSetting('device_id', id, syncScope: 'local');
    return id;
  }

  void setSetting(String key, Object? value, {String syncScope = 'local'}) {
    _db.execute(
      '''
      INSERT INTO app_settings(setting_key, value_json, sync_scope, updated_at_utc)
      VALUES(?,?,?,?)
      ON CONFLICT(setting_key) DO UPDATE SET
        value_json=excluded.value_json,
        sync_scope=excluded.sync_scope,
        updated_at_utc=excluded.updated_at_utc
    ''',
      [key, jsonEncode(value), syncScope, _now()],
    );
  }

  T? getSetting<T>(String key) {
    final rows = _db.select(
      'SELECT value_json FROM app_settings WHERE setting_key=?',
      [key],
    );
    return rows.isEmpty
        ? null
        : jsonDecode(rows.first['value_json'] as String) as T?;
  }

  List<BankSummary> listBanks() => _db
      .select('''
    SELECT b.bank_id,b.name,b.subject,b.content_version,COUNT(q.question_id) question_count
    FROM question_banks b LEFT JOIN questions q ON q.bank_id=b.bank_id AND q.is_active=1
    WHERE b.is_active=1 GROUP BY b.bank_id ORDER BY b.updated_at_utc DESC
  ''')
      .map(
        (row) => BankSummary(
          id: row['bank_id'] as String,
          name: row['name'] as String,
          subject: row['subject'] as String,
          contentVersion: row['content_version'] as int,
          questionCount: row['question_count'] as int,
        ),
      )
      .toList();

  BankSummary? bankSummary(String bankId) =>
      listBanks().where((bank) => bank.id == bankId).firstOrNull;

  List<int> omrQuestionPositions(String bankId, Iterable<String> questionIds) {
    final rows = _db.select(
      'SELECT question_id FROM questions WHERE bank_id=? AND is_active=1 ORDER BY question_id',
      [bankId],
    );
    final positions = <String, int>{
      for (var index = 0; index < rows.length; index++)
        rows[index]['question_id'] as String: index,
    };
    return questionIds
        .map((id) {
          final position = positions[id];
          if (position == null) throw FormatException('答题卡题目 $id 不在当前题库版本中');
          return position;
        })
        .toList(growable: false);
  }

  void importBank(ImportPreview preview, {required String reportJson}) {
    if (!preview.canImport) throw StateError('存在阻断性导入错误');
    final now = _now();
    final importedQuestionIds = preview.questions.map((q) => q.id).toSet();
    _transaction(() {
      _db.execute(
        '''
        INSERT INTO question_banks(bank_id,name,subject,description,schema_version,
          content_version,source_name,created_at_utc,updated_at_utc,is_active)
        VALUES(?,?,?,?,?,?,?,?,?,1)
        ON CONFLICT(bank_id) DO UPDATE SET name=excluded.name,subject=excluded.subject,
          content_version=excluded.content_version,source_name=excluded.source_name,
          updated_at_utc=excluded.updated_at_utc,is_active=1
      ''',
        [
          preview.bankId,
          preview.name,
          preview.subject,
          '',
          1,
          preview.contentVersion,
          preview.packagePath,
          now,
          now,
        ],
      );
      for (final q in preview.questions) {
        final content = jsonEncode(q.toSnapshot());
        _db.execute(
          '''
          INSERT INTO questions(question_id,bank_id,external_id,content_version,question_type,
            stem_markdown,options_json,correct_answers_json,explanation_markdown,
            knowledge_point,source,year,chapter,tags_json,media_json,scoring_rule_json,
            content_hash,is_active,created_at_utc,updated_at_utc)
          VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,1,?,?)
          ON CONFLICT(question_id) DO UPDATE SET bank_id=excluded.bank_id,
            external_id=excluded.external_id,content_version=excluded.content_version,
            question_type=excluded.question_type,stem_markdown=excluded.stem_markdown,
            options_json=excluded.options_json,correct_answers_json=excluded.correct_answers_json,
            explanation_markdown=excluded.explanation_markdown,
            knowledge_point=excluded.knowledge_point,source=excluded.source,year=excluded.year,
            chapter=excluded.chapter,tags_json=excluded.tags_json,media_json=excluded.media_json,
            scoring_rule_json=excluded.scoring_rule_json,content_hash=excluded.content_hash,
            is_active=1,updated_at_utc=excluded.updated_at_utc
        ''',
          [
            q.id,
            q.bankId,
            q.externalId,
            q.contentVersion,
            q.type.name,
            q.stem,
            jsonEncode(q.options),
            jsonEncode(q.answers),
            q.explanation,
            q.knowledgePoint,
            q.source,
            q.year,
            q.chapter,
            jsonEncode(q.tags),
            jsonEncode(q.media),
            jsonEncode(q.scoringRule.toJson()),
            sha256.convert(utf8.encode(content)).toString(),
            now,
            now,
          ],
        );
        _db.execute(
          '''
          INSERT OR IGNORE INTO question_progress(question_id,updated_at_utc)
          VALUES(?,?)
        ''',
          [q.id, now],
        );
      }
      final removedRows = _db.select(
        'SELECT question_id FROM questions WHERE bank_id=? AND is_active=1',
        [preview.bankId],
      );
      for (final row in removedRows) {
        final questionId = row['question_id'] as String;
        if (importedQuestionIds.contains(questionId)) continue;
        _db.execute(
          '''
          UPDATE questions SET is_active=0,content_version=content_version+1,
            updated_at_utc=? WHERE question_id=?
        ''',
          [now, questionId],
        );
      }
      _db.execute(
        '''
        INSERT INTO question_bank_imports(import_id,bank_id,source_file,content_version,
          report_json,imported_at_utc) VALUES(?,?,?,?,?,?)
      ''',
        [
          _uuid.v4(),
          preview.bankId,
          preview.packagePath,
          preview.contentVersion,
          reportJson,
          now,
        ],
      );
      if (publishesQuestionBanks) {
        _enqueueBankById(preview.bankId);
        for (final row in _db.select(
          'SELECT * FROM questions WHERE bank_id=? ORDER BY question_id',
          [preview.bankId],
        )) {
          _enqueueQuestionRow(row);
        }
      }
    });
  }

  Question? questionById(String id) {
    final rows = _db.select('SELECT * FROM questions WHERE question_id=?', [
      id,
    ]);
    return rows.isEmpty ? null : _question(rows.first);
  }

  List<Question> listQuestions({
    required String bankId,
    PracticeMode? mode,
    String? year,
    String? chapter,
    String? tag,
    QuestionType? type,
    int? limit,
    Set<String> excludeIds = const {},
    bool random = false,
    bool includeExcluded = false,
  }) {
    final where = <String>['q.bank_id=?', 'q.is_active=1'];
    final args = <Object?>[bankId];
    if (year != null && year.isNotEmpty) {
      where.add('q.year=?');
      args.add(year);
    }
    if (chapter != null && chapter.isNotEmpty) {
      where.add('q.chapter=?');
      args.add(chapter);
    }
    if (tag != null && tag.isNotEmpty) {
      where.add('EXISTS (SELECT 1 FROM json_each(q.tags_json) WHERE value=?)');
      args.add(tag);
    }
    if (type != null) {
      where.add('q.question_type=?');
      args.add(type.name);
    }
    switch (mode) {
      case PracticeMode.unseen:
        where.add("p.state='unseen'");
        break;
      case PracticeMode.wrongReview:
        where.add("p.state='wrong'");
        break;
      case PracticeMode.favorite:
        where.add('p.is_favorite=1');
        break;
      case PracticeMode.uncertain:
        where.add('p.is_uncertain=1');
        break;
      case PracticeMode.random:
      case null:
    }
    if (mode != null) {
      // 练习池不含问答题：问答题无判分语义，只出现在题库浏览与试卷组卷中。
      where.add("q.question_type != 'qa'");
    }
    if (!includeExcluded) where.add('p.is_excluded=0');
    if (excludeIds.isNotEmpty) {
      where.add(
        'q.question_id NOT IN (${List.filled(excludeIds.length, '?').join(',')})',
      );
      args.addAll(excludeIds);
    }
    final order = random ? 'RANDOM()' : 'q.year,q.external_id,q.question_id';
    final limitSql = limit == null ? '' : ' LIMIT ?';
    if (limit != null) args.add(limit);
    return _db
        .select('''
      SELECT q.* FROM questions q JOIN question_progress p ON p.question_id=q.question_id
      WHERE ${where.join(' AND ')} ORDER BY $order$limitSql
    ''', args)
        .map(_question)
        .toList();
  }

  int managedQuestionCount(String bankId) =>
      _db.select('SELECT COUNT(*) AS total FROM questions WHERE bank_id=?', [
            bankId,
          ]).first['total']
          as int;

  List<Question> managedQuestions(String bankId, {int? limit, int offset = 0}) {
    final limitSql = limit == null ? '' : ' LIMIT ? OFFSET ?';
    final arguments = <Object?>[bankId];
    if (limit != null) arguments.addAll([limit, offset]);
    return _db
        .select(
          'SELECT * FROM questions WHERE bank_id=? '
          'ORDER BY external_id,question_id$limitSql',
          arguments,
        )
        .map(_question)
        .toList();
  }

  QuestionProgress progress(String questionId) {
    final rows = _db.select(
      'SELECT * FROM question_progress WHERE question_id=?',
      [questionId],
    );
    if (rows.isEmpty) return QuestionProgress(questionId: questionId);
    final row = rows.first;
    return QuestionProgress(
      questionId: questionId,
      state: StudyState.values.byName(row['state'] as String),
      seenCount: row['seen_count'] as int,
      correctCount: row['correct_count'] as int,
      wrongCount: row['wrong_count'] as int,
      everWrong: (row['ever_wrong'] as int) == 1,
      totalDurationMs: row['total_duration_ms'] as int,
      isFavorite: (row['is_favorite'] as int) == 1,
      isUncertain: (row['is_uncertain'] as int) == 1,
      isExcluded: (row['is_excluded'] as int) == 1,
      personalNote: row['personal_note_markdown'] as String,
    );
  }

  DashboardStats dashboard(String bankId) {
    final row = _db
        .select(
          '''
      SELECT COUNT(*) total,
        SUM(CASE WHEN p.state='unseen' THEN 1 ELSE 0 END) unseen,
        SUM(CASE WHEN p.state='wrong' THEN 1 ELSE 0 END) wrong,
        SUM(CASE WHEN p.state='mastered' THEN 1 ELSE 0 END) mastered,
        SUM(p.ever_wrong) ever_wrong,SUM(p.is_favorite) favorite,
        SUM(p.is_uncertain) uncertain,SUM(p.is_excluded) excluded
      FROM questions q JOIN question_progress p ON p.question_id=q.question_id
      WHERE q.bank_id=? AND q.is_active=1
    ''',
          [bankId],
        )
        .first;
    final pending =
        (_db
                .select(
                  'SELECT COUNT(*) count FROM sync_outbox WHERE completed_at_utc IS NULL',
                )
                .first['count']
            as int) +
        (_db
                .select('SELECT COUNT(*) count FROM deferred_sync_changes')
                .first['count']
            as int);
    int n(Object? value) => (value as int?) ?? 0;
    return DashboardStats(
      total: n(row['total']),
      unseen: n(row['unseen']),
      wrong: n(row['wrong']),
      mastered: n(row['mastered']),
      everWrong: n(row['ever_wrong']),
      favorite: n(row['favorite']),
      uncertain: n(row['uncertain']),
      excluded: n(row['excluded']),
      pendingSync: pending,
    );
  }

  bool submitAnswer(
    AnswerEvent event, {
    bool randomErrorsReturnToWrong = true,
  }) {
    final hash = _eventHash(event);
    final existing = _db.select(
      'SELECT payload_hash FROM answer_events WHERE event_id=?',
      [event.eventId],
    );
    if (existing.isNotEmpty) {
      if (existing.first['payload_hash'] == hash) return false;
      _recordConflict(
        event.eventId,
        existing.first['payload_hash'] as String,
        event.canonicalJson(),
      );
      throw EventConflictException(event.eventId);
    }
    _transaction(
      () => _insertEvent(
        event,
        hash,
        randomErrorsReturnToWrong: randomErrorsReturnToWrong,
      ),
    );
    return true;
  }

  void _insertEvent(
    AnswerEvent event,
    String hash, {
    required bool randomErrorsReturnToWrong,
    String syncState = 'pending',
    bool enqueue = true,
    bool updateProgress = true,
  }) {
    _db.execute(
      '''
      INSERT INTO answer_events(event_id,device_id,question_id,question_version,session_id,
        attempt_id,mode,selected_json,correct,score,duration_ms,answered_at_utc,source,
        schema_version,sync_state,created_locally_at_utc,payload_hash)
      VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    ''',
      [
        event.eventId,
        event.deviceId,
        event.questionId,
        event.questionVersion,
        event.sessionId,
        event.attemptId,
        event.mode,
        jsonEncode(event.selected),
        event.correct ? 1 : 0,
        event.score,
        event.durationMs,
        event.answeredAtUtc.toUtc().toIso8601String(),
        event.source,
        event.schemaVersion,
        syncState,
        _now(),
        hash,
      ],
    );
    if (!updateProgress) return;
    final before = progress(event.questionId);
    final newState = StudyPolicy.afterAnswer(
      before: before.state,
      correct: event.correct,
      randomErrorsReturnToWrong: randomErrorsReturnToWrong,
      isRandomPractice: event.mode == 'practice_random',
    );
    _db.execute(
      '''
      UPDATE question_progress SET state=?,seen_count=seen_count+1,
        correct_count=correct_count+?,wrong_count=wrong_count+?,ever_wrong=MAX(ever_wrong,?),
        last_selected_json=?,last_result=?,last_answered_at_utc=?,
        total_duration_ms=total_duration_ms+?,updated_at_utc=?,version=version+1
      WHERE question_id=?
    ''',
      [
        newState.name,
        event.correct ? 1 : 0,
        event.correct ? 0 : 1,
        event.correct ? 0 : 1,
        jsonEncode(event.selected),
        event.correct ? 'correct' : 'wrong',
        event.answeredAtUtc.toUtc().toIso8601String(),
        event.durationMs,
        _now(),
        event.questionId,
      ],
    );
    if (enqueue) {
      _enqueue(
        'answer_event',
        event.eventId,
        'upsert',
        event.canonicalJson(),
        hash,
      );
    }
  }

  void updateQuestionMeta(
    String questionId, {
    bool? favorite,
    bool? uncertain,
    bool? excluded,
    String? note,
  }) {
    final current = progress(questionId);
    final now = _now();
    final controlRows = _db.select(
      'SELECT version FROM question_control_versions WHERE question_id=?',
      [questionId],
    );
    final baseVersion = controlRows.isEmpty
        ? 0
        : controlRows.first['version'] as int;
    final nextVersion = baseVersion + 1;
    _transaction(() {
      _db.execute(
        '''
        UPDATE question_progress SET is_favorite=?,is_uncertain=?,is_excluded=?,
          personal_note_markdown=?,updated_at_utc=?,version=version+1 WHERE question_id=?
      ''',
        [
          favorite ?? current.isFavorite ? 1 : 0,
          uncertain ?? current.isUncertain ? 1 : 0,
          excluded ?? current.isExcluded ? 1 : 0,
          note ?? current.personalNote,
          now,
          questionId,
        ],
      );
      _db.execute(
        '''
        INSERT INTO question_control_versions(question_id,version,updated_at_utc,source_device_id)
        VALUES(?,?,?,?) ON CONFLICT(question_id) DO UPDATE SET
          version=excluded.version,updated_at_utc=excluded.updated_at_utc,
          source_device_id=excluded.source_device_id
      ''',
        [questionId, nextVersion, now, deviceId],
      );
      final payload = jsonEncode(<String, Object?>{
        'question_id': questionId,
        'is_favorite': favorite ?? current.isFavorite,
        'is_uncertain': uncertain ?? current.isUncertain,
        'is_excluded': excluded ?? current.isExcluded,
        'personal_note_markdown': note ?? current.personalNote,
        'base_version': baseVersion,
        'version': nextVersion,
        'base_note_hash': sha256
            .convert(utf8.encode(current.personalNote))
            .toString(),
        'device_id': deviceId,
        'updated_at_utc': now,
      });
      _enqueue(
        'question_progress_control',
        questionId,
        'upsert',
        payload,
        sha256.convert(utf8.encode(payload)).toString(),
      );
    });
  }

  PaperAttempt createPaper({
    required String bankId,
    required String title,
    required List<Question> questions,
    required int suggestedDurationMs,
    String? paperId,
    PaperCompositionMode compositionMode = PaperCompositionMode.realExam,
    PaperScoringPolicy scoringPolicy = const PaperScoringPolicy(),
  }) {
    final attemptId = _uuid.v4();
    final resolvedPaperId = paperId ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final states = questions
        .map((q) => PaperQuestionState(question: q, eventId: _uuid.v4()))
        .toList();
    _transaction(() {
      _db.execute(
        '''
        INSERT INTO paper_attempts(attempt_id,paper_id,title,bank_id,status,scoring_rule_json,
          started_at_utc,suggested_duration_ms,source_device_id,created_at_utc,updated_at_utc)
        VALUES(?,?,?,?, 'draft',?,?,?,?,?,?)
      ''',
        [
          attemptId,
          resolvedPaperId,
          title,
          bankId,
          jsonEncode(<String, Object?>{
            'composition_mode': compositionMode.name,
            'scoring_policy': scoringPolicy.toJson(),
          }),
          now.toIso8601String(),
          suggestedDurationMs,
          deviceId,
          now.toIso8601String(),
          now.toIso8601String(),
        ],
      );
      for (var i = 0; i < states.length; i++) {
        final state = states[i];
        _db.execute(
          '''
          INSERT INTO paper_attempt_questions(attempt_id,position,question_id,question_version,
            event_id,snapshot_json) VALUES(?,?,?,?,?,?)
        ''',
          [
            attemptId,
            i,
            state.question.id,
            state.question.contentVersion,
            state.eventId,
            jsonEncode(state.question.toSnapshot()),
          ],
        );
      }
    });
    return PaperAttempt(
      attemptId: attemptId,
      paperId: resolvedPaperId,
      title: title,
      bankId: bankId,
      status: AttemptStatus.draft,
      questions: states,
      startedAtUtc: now,
      suggestedDurationMs: suggestedDurationMs,
      compositionMode: compositionMode,
      scoringPolicy: scoringPolicy,
    );
  }

  void savePaperDraft(PaperAttempt attempt) {
    if (attempt.status != AttemptStatus.draft) return;
    final now = _now();
    _transaction(() {
      _db.execute(
        '''
        UPDATE paper_attempts SET duration_ms=?,overtime_ms=?,current_index=?,updated_at_utc=?
        WHERE attempt_id=? AND status='draft'
      ''',
        [
          attempt.durationMs,
          attempt.overtimeMs,
          attempt.currentIndex,
          now,
          attempt.attemptId,
        ],
      );
      for (var i = 0; i < attempt.questions.length; i++) {
        final state = attempt.questions[i];
        // 问答题的 selected 保存作答原文，不做 A–E 归一化。
        final selectedJson = state.question.type == QuestionType.qa
            ? jsonEncode(state.selected.toList())
            : jsonEncode(AnswerPolicy.normalize(state.selected));
        _db.execute(
          '''
          UPDATE paper_attempt_questions SET selected_json=?,uncertain=?,duration_ms=?
          WHERE attempt_id=? AND position=?
        ''',
          [
            selectedJson,
            state.uncertain ? 1 : 0,
            state.durationMs,
            attempt.attemptId,
            i,
          ],
        );
      }
    });
  }

  void submitPaper(
    PaperAttempt attempt, {
    Map<int, String> sourceByPosition = const {},
  }) {
    if (attempt.status == AttemptStatus.submitted) return;
    final events = <AnswerEvent>[];
    var score = 0.0;
    var maxScore = 0.0;
    final answeredAt = DateTime.now().toUtc();
    for (var position = 0; position < attempt.questions.length; position++) {
      final state = attempt.questions[position];
      final result = attempt.scoringPolicy.score(
        state.question,
        state.selected,
      );
      maxScore += result.maxScore;
      score += result.score;
      // 问答题不判分（maxScore 0）、不生成作答事件：作答文本仅随试卷快照保存。
      if (!result.isAnswered || state.question.type == QuestionType.qa) continue;
      events.add(
        AnswerEvent(
          eventId: state.eventId,
          deviceId: deviceId,
          questionId: state.question.id,
          questionVersion: state.question.contentVersion,
          sessionId: attempt.attemptId,
          attemptId: attempt.attemptId,
          mode: 'paper',
          selected: AnswerPolicy.normalize(state.selected),
          correct: result.isCompletelyCorrect,
          score: result.score,
          durationMs: state.durationMs,
          answeredAtUtc: answeredAt,
          source: sourceByPosition[position] ?? 'screen',
        ),
      );
    }
    for (final event in events) {
      final existing = _db.select(
        'SELECT payload_hash FROM answer_events WHERE event_id=?',
        [event.eventId],
      );
      if (existing.isNotEmpty &&
          existing.first['payload_hash'] != _eventHash(event)) {
        _recordConflict(
          event.eventId,
          existing.first['payload_hash'] as String,
          event.canonicalJson(),
        );
        throw EventConflictException(event.eventId);
      }
    }
    _transaction(() {
      for (final event in events) {
        final exists = _db.select(
          'SELECT 1 FROM answer_events WHERE event_id=?',
          [event.eventId],
        );
        if (exists.isEmpty) {
          _insertEvent(
            event,
            _eventHash(event),
            randomErrorsReturnToWrong: true,
          );
        }
      }
      _db.execute(
        '''
        UPDATE paper_attempts SET status='submitted',submitted_at_utc=?,duration_ms=?,
          overtime_ms=?,score=?,max_score=?,updated_at_utc=? WHERE attempt_id=?
      ''',
        [
          answeredAt.toIso8601String(),
          attempt.durationMs,
          attempt.overtimeMs,
          score,
          maxScore,
          _now(),
          attempt.attemptId,
        ],
      );
      final payload = jsonEncode(<String, Object?>{
        'attempt_id': attempt.attemptId,
        'paper_id': attempt.paperId,
        'title': attempt.title,
        'bank_id': attempt.bankId,
        'status': AttemptStatus.submitted.name,
        'composition_mode': attempt.compositionMode.name,
        'scoring_policy': attempt.scoringPolicy.toJson(),
        'started_at_utc': attempt.startedAtUtc.toUtc().toIso8601String(),
        'submitted_at_utc': answeredAt.toIso8601String(),
        'duration_ms': attempt.durationMs,
        'suggested_duration_ms': attempt.suggestedDurationMs,
        'overtime_ms': attempt.overtimeMs,
        'score': score,
        'max_score': maxScore,
        'source_device_id': deviceId,
        'questions': attempt.questions
            .map(
              (s) => <String, Object?>{
                'event_id': s.eventId,
                'question': s.question.toSnapshot(),
                // 问答题保存作答原文，其余题型保存归一化选项。
                'selected': s.question.type == QuestionType.qa
                    ? s.selected.toList()
                    : AnswerPolicy.normalize(s.selected),
                'uncertain': s.uncertain,
                'duration_ms': s.durationMs,
              },
            )
            .toList(),
      });
      _enqueue(
        'paper_attempt',
        attempt.attemptId,
        'upsert',
        payload,
        sha256.convert(utf8.encode(payload)).toString(),
      );
    });
    attempt.status = AttemptStatus.submitted;
    attempt.submittedAtUtc = answeredAt;
    attempt.score = score;
    attempt.maxScore = maxScore;
  }

  void abandonPaper(PaperAttempt attempt, {required bool keepDraft}) {
    if (keepDraft) return;
    _db.execute(
      "UPDATE paper_attempts SET status='abandoned',updated_at_utc=? WHERE attempt_id=?",
      [_now(), attempt.attemptId],
    );
    attempt.status = AttemptStatus.abandoned;
  }

  PaperAttempt? loadAttempt(String attemptId) {
    final rows = _db.select('SELECT * FROM paper_attempts WHERE attempt_id=?', [
      attemptId,
    ]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final status = AttemptStatus.values.byName(row['status'] as String);
    final qRows = _db.select(
      'SELECT * FROM paper_attempt_questions WHERE attempt_id=? ORDER BY position',
      [attemptId],
    );
    final questions = qRows.map((qRow) {
      final snapshot = Question.fromSnapshot(
        (jsonDecode(qRow['snapshot_json'] as String) as Map)
            .cast<String, Object?>(),
      );
      // 已交卷的历史试卷按题库当前内容显示（编辑后即时可见）；
      // 草稿保持组卷快照，避免作答中途换题。存储快照本身永不改写。
      final question = status == AttemptStatus.submitted
          ? questionById(snapshot.id) ?? snapshot
          : snapshot;
      return PaperQuestionState(
        question: question,
        eventId: qRow['event_id'] as String,
        selected: (jsonDecode(qRow['selected_json'] as String) as List)
            .map((e) => e.toString())
            .toSet(),
        uncertain: (qRow['uncertain'] as int) == 1,
        durationMs: qRow['duration_ms'] as int,
      );
    }).toList();
    return PaperAttempt(
      attemptId: attemptId,
      paperId: row['paper_id'] as String,
      title: row['title'] as String,
      bankId: row['bank_id'] as String,
      status: status,
      questions: questions,
      startedAtUtc: DateTime.parse(row['started_at_utc'] as String),
      suggestedDurationMs: row['suggested_duration_ms'] as int,
      compositionMode: _storedCompositionMode(
        row['scoring_rule_json'] as String,
      ),
      scoringPolicy: _storedScoringPolicy(row['scoring_rule_json'] as String),
      submittedAtUtc: row['submitted_at_utc'] == null
          ? null
          : DateTime.parse(row['submitted_at_utc'] as String),
      durationMs: row['duration_ms'] as int,
      score: (row['score'] as num?)?.toDouble(),
      maxScore: (row['max_score'] as num?)?.toDouble(),
      currentIndex: row['current_index'] as int,
    );
  }

  PaperAttempt? latestDraft(String bankId) {
    final rows = _db.select(
      '''
      SELECT attempt_id FROM paper_attempts WHERE bank_id=? AND status='draft'
      ORDER BY updated_at_utc DESC LIMIT 1
    ''',
      [bankId],
    );
    return rows.isEmpty
        ? null
        : loadAttempt(rows.first['attempt_id'] as String);
  }

  List<String> attemptIds({int limit = 1000}) => _db
      .select(
        'SELECT attempt_id FROM paper_attempts ORDER BY updated_at_utc DESC LIMIT ?',
        [limit],
      )
      .map((row) => row['attempt_id'] as String)
      .toList(growable: false);

  List<AttemptSummary> history({int limit = 100}) => _db
      .select(
        '''
    SELECT a.*,COUNT(q.position) question_count FROM paper_attempts a
    LEFT JOIN paper_attempt_questions q ON q.attempt_id=a.attempt_id
    WHERE a.archived_locally=0
    GROUP BY a.attempt_id ORDER BY a.started_at_utc DESC LIMIT ?
  ''',
        [limit],
      )
      .map(
        (row) => AttemptSummary(
          attemptId: row['attempt_id'] as String,
          title: row['title'] as String,
          status: AttemptStatus.values.byName(row['status'] as String),
          questionCount: row['question_count'] as int,
          startedAtUtc: DateTime.parse(row['started_at_utc'] as String),
          durationMs: row['duration_ms'] as int,
          score: (row['score'] as num?)?.toDouble(),
          maxScore: (row['max_score'] as num?)?.toDouble(),
        ),
      )
      .toList();

  void archiveAttempt(String attemptId) {
    _db.execute(
      'UPDATE paper_attempts SET archived_locally=1,updated_at_utc=? WHERE attempt_id=?',
      [_now(), attemptId],
    );
    if (_db.updatedRows == 0) throw StateError('历史试卷不存在或已删除');
  }

  List<Map<String, Object?>> answerHistory(String questionId) => _db
      .select(
        '''
    SELECT event_id,selected_json,correct,score,duration_ms,answered_at_utc,mode,source
    FROM answer_events WHERE question_id=? ORDER BY answered_at_utc DESC
  ''',
        [questionId],
      )
      .map((row) => Map<String, Object?>.from(row))
      .toList();

  List<Map<String, Object?>> groupedStats(String bankId, String dimension) {
    const allowed = {'year', 'chapter', 'question_type'};
    if (!allowed.contains(dimension)) {
      throw ArgumentError.value(dimension, 'dimension');
    }
    return _db
        .select(
          '''
      SELECT q.$dimension label,COUNT(*) total,
        SUM(p.seen_count) attempts,SUM(p.correct_count) correct,
        SUM(p.wrong_count) wrong,AVG(CASE WHEN p.seen_count>0
          THEN CAST(p.total_duration_ms AS REAL)/p.seen_count END) average_ms
      FROM questions q JOIN question_progress p ON p.question_id=q.question_id
      WHERE q.bank_id=? AND q.is_active=1 GROUP BY q.$dimension ORDER BY q.$dimension
    ''',
          [bankId],
        )
        .map((row) => Map<String, Object?>.from(row))
        .toList();
  }

  List<Map<String, Object?>> tagStats(String bankId) => _db
      .select(
        '''
        SELECT j.value label,COUNT(*) total,SUM(p.seen_count) attempts,
          SUM(p.correct_count) correct,SUM(p.wrong_count) wrong,
          AVG(CASE WHEN p.seen_count>0
            THEN CAST(p.total_duration_ms AS REAL)/p.seen_count END) average_ms
        FROM questions q JOIN question_progress p ON p.question_id=q.question_id,
          json_each(q.tags_json) j
        WHERE q.bank_id=? AND q.is_active=1
        GROUP BY j.value ORDER BY j.value
      ''',
        [bankId],
      )
      .map((row) => Map<String, Object?>.from(row))
      .toList();

  List<Map<String, Object?>> slowQuestions(String bankId, {int limit = 20}) =>
      _db
          .select(
            '''
    SELECT q.question_id,q.external_id,q.stem_markdown,p.seen_count,p.total_duration_ms,
      CAST(p.total_duration_ms AS REAL)/p.seen_count average_ms
    FROM questions q JOIN question_progress p ON p.question_id=q.question_id
    WHERE q.bank_id=? AND p.seen_count>0 ORDER BY average_ms DESC LIMIT ?
  ''',
            [bankId, limit],
          )
          .map((row) => Map<String, Object?>.from(row))
          .toList();

  void setQuestionActive(String questionId, bool active) {
    _transaction(() {
      _db.execute(
        '''
        UPDATE questions SET is_active=?,content_version=content_version+1,
          updated_at_utc=? WHERE question_id=?
      ''',
        [active ? 1 : 0, _now(), questionId],
      );
      _refreshQuestionHashAndQueue(questionId);
    });
  }

  void editQuestion(Question question) {
    _transaction(() {
      _db.execute(
        '''
        UPDATE questions SET content_version=content_version+1,question_type=?,stem_markdown=?,
          options_json=?,correct_answers_json=?,explanation_markdown=?,knowledge_point=?,source=?,
          year=?,chapter=?,tags_json=?,scoring_rule_json=?,updated_at_utc=?
        WHERE question_id=?
      ''',
        [
          question.type.name,
          question.stem,
          jsonEncode(question.options),
          jsonEncode(question.answers),
          question.explanation,
          question.knowledgePoint,
          question.source,
          question.year,
          question.chapter,
          jsonEncode(question.tags),
          jsonEncode(question.scoringRule.toJson()),
          _now(),
          question.id,
        ],
      );
      _refreshQuestionHashAndQueue(question.id);
    });
  }

  void addQuestion(Question question) {
    final now = _now();
    final snapshot = jsonEncode(question.toSnapshot());
    _transaction(() {
      final bank = _db.select(
        'SELECT 1 FROM question_banks WHERE bank_id=? AND is_active=1',
        [question.bankId],
      );
      if (bank.isEmpty) throw StateError('目标题库不存在或已删除');
      _db.execute(
        '''
        INSERT INTO questions(question_id,bank_id,external_id,content_version,question_type,
          stem_markdown,options_json,correct_answers_json,explanation_markdown,
          knowledge_point,source,year,chapter,tags_json,media_json,scoring_rule_json,
          content_hash,is_active,created_at_utc,updated_at_utc)
        VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,1,?,?)
      ''',
        [
          question.id,
          question.bankId,
          question.externalId,
          question.contentVersion,
          question.type.name,
          question.stem,
          jsonEncode(question.options),
          jsonEncode(question.answers),
          question.explanation,
          question.knowledgePoint,
          question.source,
          question.year,
          question.chapter,
          jsonEncode(question.tags),
          jsonEncode(question.media),
          jsonEncode(question.scoringRule.toJson()),
          sha256.convert(utf8.encode(snapshot)).toString(),
          now,
          now,
        ],
      );
      _db.execute(
        'INSERT INTO question_progress(question_id,updated_at_utc) VALUES(?,?)',
        [question.id, now],
      );
      if (publishesQuestionBanks) {
        final row = _db.select('SELECT * FROM questions WHERE question_id=?', [
          question.id,
        ]).first;
        _enqueueQuestionRow(row);
      }
    });
  }

  void archiveBank(String bankId) {
    _transaction(() {
      final now = _now();
      _db.execute(
        '''
        UPDATE question_banks SET is_active=0,content_version=content_version+1,
          updated_at_utc=? WHERE bank_id=? AND is_active=1
      ''',
        [now, bankId],
      );
      if (_db.updatedRows == 0) throw StateError('题库不存在或已删除');
      _db.execute(
        '''
        UPDATE questions SET is_active=0,content_version=content_version+1,
          updated_at_utc=? WHERE bank_id=? AND is_active=1
      ''',
        [now, bankId],
      );
      if (publishesQuestionBanks) {
        _enqueueBankById(bankId);
        for (final row in _db.select(
          'SELECT * FROM questions WHERE bank_id=? ORDER BY question_id',
          [bankId],
        )) {
          _enqueueQuestionRow(row);
        }
      }
    });
  }

  void enqueueExistingCatalog(String mediaRoot) {
    if (!publishesQuestionBanks) return;
    final banks = _db.select('SELECT * FROM question_banks ORDER BY bank_id');
    _transaction(() {
      for (final bank in banks) {
        _enqueueBankRow(bank);
        for (final question in _db.select(
          'SELECT * FROM questions WHERE bank_id=? ORDER BY question_id',
          [bank['bank_id']],
        )) {
          _enqueueQuestionRow(question);
        }
      }
    });
    for (final bank in banks) {
      final bankId = bank['bank_id'] as String;
      final contentVersion = bank['content_version'] as int;
      final files = <String, List<int>>{};
      for (final row in _db.select(
        'SELECT media_json FROM questions WHERE bank_id=? AND is_active=1',
        [bankId],
      )) {
        for (final media in (jsonDecode(row['media_json'] as String) as List)) {
          final name = p.basename(media.toString().replaceAll('\\', '/'));
          final file = File(
            p.join(mediaRoot, bankId, 'v$contentVersion', name),
          );
          if (file.existsSync()) files['media/$name'] = file.readAsBytesSync();
        }
      }
      enqueueMediaFiles(
        bankId: bankId,
        contentVersion: contentVersion,
        mediaFiles: files,
      );
    }
  }

  void enqueueMediaFiles({
    required String bankId,
    required int contentVersion,
    required Map<String, List<int>> mediaFiles,
  }) {
    if (!publishesQuestionBanks || mediaFiles.isEmpty) return;
    final bank = _db.select(
      'SELECT updated_at_utc FROM question_banks WHERE bank_id=?',
      [bankId],
    );
    final updatedAt = bank.isEmpty
        ? _now()
        : bank.first['updated_at_utc'] as String;
    _transaction(() {
      for (final entry in mediaFiles.entries) {
        final normalizedPath =
            'media/${p.basename(entry.key.replaceAll('\\', '/'))}';
        final bytes = Uint8List.fromList(entry.value);
        final fileHash = sha256.convert(bytes).toString();
        final chunkCount = bytes.isEmpty
            ? 1
            : (bytes.length + mediaChunkSize - 1) ~/ mediaChunkSize;
        for (var index = 0; index < chunkCount; index++) {
          final start = index * mediaChunkSize;
          final end = bytes.isEmpty
              ? 0
              : (start + mediaChunkSize).clamp(0, bytes.length);
          final chunk = Uint8List.fromList(bytes.sublist(start, end));
          final chunkId = sha256
              .convert(
                utf8.encode(
                  '$bankId|$contentVersion|$normalizedPath|$fileHash|$index',
                ),
              )
              .toString();
          final payload = <String, Object?>{
            'chunk_id': chunkId,
            'bank_id': bankId,
            'catalog_version': contentVersion,
            'relative_path': normalizedPath,
            'file_sha256': fileHash,
            'total_size': bytes.length,
            'chunk_index': index,
            'chunk_count': chunkCount,
            'chunk_sha256': sha256.convert(chunk).toString(),
            'bytes_base64': base64Encode(chunk),
            'updated_at_utc': updatedAt,
            'device_id': deviceId,
          };
          _enqueueCatalogPayload('question_media_chunk', chunkId, payload);
        }
      }
    });
  }

  void _refreshQuestionHashAndQueue(String questionId) {
    final rows = _db.select('SELECT * FROM questions WHERE question_id=?', [
      questionId,
    ]);
    if (rows.isEmpty) return;
    final row = rows.first;
    final snapshot = jsonEncode(_question(row).toSnapshot());
    _db.execute('UPDATE questions SET content_hash=? WHERE question_id=?', [
      sha256.convert(utf8.encode(snapshot)).toString(),
      questionId,
    ]);
    if (publishesQuestionBanks) _enqueueQuestionRow(row);
  }

  void _enqueueBankById(String bankId) {
    final rows = _db.select('SELECT * FROM question_banks WHERE bank_id=?', [
      bankId,
    ]);
    if (rows.isNotEmpty) _enqueueBankRow(rows.first);
  }

  void _enqueueBankRow(Row row) {
    final payload = <String, Object?>{
      'bank_id': row['bank_id'] as String,
      'name': row['name'] as String,
      'subject': row['subject'] as String,
      'description': row['description'] as String,
      'schema_version': row['schema_version'] as int,
      'content_version': row['content_version'] as int,
      'is_active': (row['is_active'] as int) == 1,
      'updated_at_utc': row['updated_at_utc'] as String,
      'device_id': deviceId,
    };
    _enqueueCatalogPayload('question_bank', row['bank_id'] as String, payload);
  }

  void _enqueueQuestionRow(Row row) {
    final bank = _db.select(
      'SELECT content_version FROM question_banks WHERE bank_id=?',
      [row['bank_id']],
    );
    if (bank.isEmpty) return;
    final payload = <String, Object?>{
      ..._question(row).toSnapshot(),
      'catalog_version': bank.first['content_version'] as int,
      'updated_at_utc': row['updated_at_utc'] as String,
      'device_id': deviceId,
    };
    _enqueueCatalogPayload('question', row['question_id'] as String, payload);
  }

  void _enqueueCatalogPayload(
    String type,
    String id,
    Map<String, Object?> payload,
  ) {
    final encoded = jsonEncode(payload);
    final hash = sha256.convert(utf8.encode(encoded)).toString();
    final outboxId = '$type:$id';
    final existing = _db.select(
      'SELECT payload_hash FROM sync_outbox WHERE outbox_id=?',
      [outboxId],
    );
    if (existing.isNotEmpty && existing.first['payload_hash'] == hash) return;
    final synced = _db.select(
      '''
      SELECT payload_hash FROM synced_entity_hashes
      WHERE entity_type=? AND entity_id=?
    ''',
      [type, id],
    );
    if (synced.isNotEmpty && synced.first['payload_hash'] == hash) return;
    _enqueue(type, id, 'upsert', encoded, hash);
  }

  String get syncCursor => getSetting<String>('sync_cursor') ?? '';

  void applySyncExchange({
    required Set<String> acceptedOutboxIds,
    required List<Map<String, Object?>> changes,
    required String nextCursor,
    String? mediaRoot,
  }) {
    final orderedChanges = [...changes]
      ..sort(
        (left, right) => _syncPriority(
          left['entity_type']?.toString() ?? '',
        ).compareTo(_syncPriority(right['entity_type']?.toString() ?? '')),
      );
    _transaction(() {
      for (final outboxId in acceptedOutboxIds) {
        _markOutboxComplete(outboxId);
      }
      final affectedQuestions = <String>{};
      for (final change in orderedChanges) {
        if (!_applyRemoteChange(change, affectedQuestions)) {
          _deferRemoteChange(change);
        }
      }
      _replayDeferredChanges(affectedQuestions);
      for (final questionId in affectedQuestions) {
        _rebuildProgress(questionId);
      }
      setSetting('sync_cursor', nextCursor, syncScope: 'local');
    });
    if (mediaRoot != null && mediaRoot.isNotEmpty) {
      materializeSyncedMedia(mediaRoot);
    }
  }

  int _syncPriority(String entityType) => switch (entityType) {
    'question_bank' => 0,
    'question' => 1,
    'question_media_chunk' => 2,
    'answer_event' || 'question_progress_control' => 3,
    'paper_attempt' || 'paper_archive_ack' => 4,
    _ => 5,
  };

  bool _applyRemoteChange(
    Map<String, Object?> change,
    Set<String> affectedQuestions,
  ) {
    final entityType = change['entity_type']?.toString();
    if (entityType == null || entityType.isEmpty) {
      throw const FormatException('同步变化缺少 entity_type');
    }
    final payload = _syncPayload(change);
    final applied = switch (entityType) {
      'question_bank' => _mergeRemoteQuestionBank(payload),
      'question' => _mergeRemoteQuestion(payload),
      'question_media_chunk' => _mergeRemoteMediaChunk(payload),
      'answer_event' => _mergeRemoteAnswerEvent(payload, affectedQuestions),
      'question_progress_control' => _mergeRemoteQuestionControl(payload),
      'paper_attempt' => _mergeRemotePaperAndReturn(payload, change),
      'paper_archive_ack' => true,
      _ => throw FormatException('不支持的同步实体：$entityType'),
    };
    if (applied) _rememberSyncedEntity(change, entityType);
    return applied;
  }

  bool _mergeRemotePaperAndReturn(
    Map<String, Object?> payload,
    Map<String, Object?> change,
  ) {
    _mergeRemotePaper(payload, change);
    return true;
  }

  void _rememberSyncedEntity(Map<String, Object?> change, String entityType) {
    final entityId = change['entity_id']?.toString();
    if (entityId == null || entityId.isEmpty) return;
    final payloadHash =
        change['payload_hash']?.toString() ??
        sha256
            .convert(utf8.encode(jsonEncode(_syncPayload(change))))
            .toString();
    _db.execute(
      '''
      INSERT INTO synced_entity_hashes(entity_type,entity_id,payload_hash,updated_at_utc)
      VALUES(?,?,?,?) ON CONFLICT(entity_type,entity_id) DO UPDATE SET
        payload_hash=excluded.payload_hash,updated_at_utc=excluded.updated_at_utc
    ''',
      [entityType, entityId, payloadHash, _now()],
    );
  }

  void _deferRemoteChange(Map<String, Object?> change) {
    final entityType = change['entity_type']?.toString() ?? '';
    final entityId = change['entity_id']?.toString() ?? '';
    final encoded = jsonEncode(change);
    final payloadHash =
        change['payload_hash']?.toString() ??
        sha256.convert(utf8.encode(encoded)).toString();
    final deferredId = sha256.convert(utf8.encode(encoded)).toString();
    _db.execute(
      '''
      INSERT OR IGNORE INTO deferred_sync_changes(
        deferred_id,entity_type,entity_id,change_json,payload_hash,
        source_device_id,created_at_utc
      ) VALUES(?,?,?,?,?,?,?)
    ''',
      [
        deferredId,
        entityType,
        entityId,
        encoded,
        payloadHash,
        change['source_device_id']?.toString(),
        _now(),
      ],
    );
  }

  void _replayDeferredChanges(Set<String> affectedQuestions) {
    for (var pass = 0; pass < 3; pass++) {
      var progressed = false;
      final rows = _db.select(
        'SELECT deferred_id,change_json FROM deferred_sync_changes ORDER BY created_at_utc',
      );
      for (final row in rows) {
        final change = (jsonDecode(row['change_json'] as String) as Map)
            .cast<String, Object?>();
        if (!_applyRemoteChange(change, affectedQuestions)) continue;
        _db.execute('DELETE FROM deferred_sync_changes WHERE deferred_id=?', [
          row['deferred_id'],
        ]);
        progressed = true;
      }
      if (!progressed) break;
    }
  }

  Map<String, Object?> _syncPayload(Map<String, Object?> change) {
    final raw = change['payload'] ?? change['payload_json'];
    if (raw is String) {
      return (jsonDecode(raw) as Map).cast<String, Object?>();
    }
    if (raw is Map) return raw.cast<String, Object?>();
    throw const FormatException('同步变化缺少有效 payload');
  }

  bool _mergeRemoteQuestionBank(Map<String, Object?> payload) {
    final bankId = payload['bank_id']?.toString() ?? '';
    final contentVersion = (payload['content_version'] as num?)?.toInt() ?? 0;
    if (bankId.isEmpty || contentVersion < 1) {
      throw const FormatException('题库同步载荷缺少有效 bank_id/content_version');
    }
    final existing = _db.select(
      'SELECT content_version FROM question_banks WHERE bank_id=?',
      [bankId],
    );
    if (existing.isNotEmpty &&
        (existing.first['content_version'] as int) > contentVersion) {
      return true;
    }
    final updatedAt =
        payload['updated_at_utc']?.toString() ??
        DateTime.now().toUtc().toIso8601String();
    _db.execute(
      '''
      INSERT INTO question_banks(
        bank_id,name,subject,description,schema_version,content_version,
        source_name,created_at_utc,updated_at_utc,is_active
      ) VALUES(?,?,?,?,?,?,?, ?,?,?)
      ON CONFLICT(bank_id) DO UPDATE SET
        name=excluded.name,subject=excluded.subject,description=excluded.description,
        schema_version=excluded.schema_version,content_version=excluded.content_version,
        updated_at_utc=excluded.updated_at_utc,is_active=excluded.is_active
    ''',
      [
        bankId,
        payload['name']?.toString() ?? '同步题库',
        payload['subject']?.toString() ?? '',
        payload['description']?.toString() ?? '',
        (payload['schema_version'] as num?)?.toInt() ?? 1,
        contentVersion,
        'cloud-sync',
        updatedAt,
        updatedAt,
        payload['is_active'] == false ? 0 : 1,
      ],
    );
    return true;
  }

  bool _mergeRemoteQuestion(Map<String, Object?> payload) {
    final bankId = payload['bank_id']?.toString() ?? '';
    final questionId = payload['question_id']?.toString() ?? '';
    if (bankId.isEmpty || questionId.isEmpty) {
      throw const FormatException('题目同步载荷缺少 bank_id/question_id');
    }
    final bank = _db.select(
      'SELECT content_version FROM question_banks WHERE bank_id=?',
      [bankId],
    );
    if (bank.isEmpty) return false;
    final catalogVersion = (payload['catalog_version'] as num?)?.toInt() ?? 0;
    if ((bank.first['content_version'] as int) > catalogVersion) return true;
    final question = Question.fromSnapshot(payload);
    final snapshot = jsonEncode(question.toSnapshot());
    final updatedAt =
        payload['updated_at_utc']?.toString() ??
        DateTime.now().toUtc().toIso8601String();
    _db.execute(
      '''
      INSERT INTO questions(
        question_id,bank_id,external_id,content_version,question_type,
        stem_markdown,options_json,correct_answers_json,explanation_markdown,
        knowledge_point,source,year,chapter,tags_json,media_json,scoring_rule_json,
        content_hash,is_active,created_at_utc,updated_at_utc
      ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
      ON CONFLICT(question_id) DO UPDATE SET
        bank_id=excluded.bank_id,external_id=excluded.external_id,
        content_version=excluded.content_version,question_type=excluded.question_type,
        stem_markdown=excluded.stem_markdown,options_json=excluded.options_json,
        correct_answers_json=excluded.correct_answers_json,
        explanation_markdown=excluded.explanation_markdown,
        knowledge_point=excluded.knowledge_point,source=excluded.source,
        year=excluded.year,chapter=excluded.chapter,tags_json=excluded.tags_json,
        media_json=excluded.media_json,scoring_rule_json=excluded.scoring_rule_json,
        content_hash=excluded.content_hash,is_active=excluded.is_active,
        updated_at_utc=excluded.updated_at_utc
    ''',
      [
        question.id,
        question.bankId,
        question.externalId,
        question.contentVersion,
        question.type.name,
        question.stem,
        jsonEncode(question.options),
        jsonEncode(question.answers),
        question.explanation,
        question.knowledgePoint,
        question.source,
        question.year,
        question.chapter,
        jsonEncode(question.tags),
        jsonEncode(question.media),
        jsonEncode(question.scoringRule.toJson()),
        sha256.convert(utf8.encode(snapshot)).toString(),
        question.isActive ? 1 : 0,
        updatedAt,
        updatedAt,
      ],
    );
    _db.execute(
      'INSERT OR IGNORE INTO question_progress(question_id,updated_at_utc) VALUES(?,?)',
      [question.id, updatedAt],
    );
    return true;
  }

  bool _mergeRemoteMediaChunk(Map<String, Object?> payload) {
    final chunkId = payload['chunk_id']?.toString() ?? '';
    final bankId = payload['bank_id']?.toString() ?? '';
    final relativePath = payload['relative_path']?.toString() ?? '';
    final normalizedRelativePath = relativePath.replaceAll('\\', '/');
    final fileHash = payload['file_sha256']?.toString() ?? '';
    final chunkHash = payload['chunk_sha256']?.toString() ?? '';
    final catalogVersion = (payload['catalog_version'] as num?)?.toInt() ?? 0;
    final totalSize = (payload['total_size'] as num?)?.toInt() ?? -1;
    final chunkIndex = (payload['chunk_index'] as num?)?.toInt() ?? -1;
    final chunkCount = (payload['chunk_count'] as num?)?.toInt() ?? 0;
    if (chunkId.isEmpty ||
        !isSafeBankId(bankId) ||
        catalogVersion < 1 ||
        !normalizedRelativePath.startsWith('media/') ||
        normalizedRelativePath.contains('/../') ||
        normalizedRelativePath.endsWith('/..') ||
        p.basename(normalizedRelativePath).isEmpty ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(fileHash) ||
        totalSize < 0 ||
        totalSize > 50 * 1024 * 1024 ||
        chunkIndex < 0 ||
        chunkIndex >= chunkCount) {
      throw const FormatException('题库媒体分块元数据无效');
    }
    final bank = _db.select('SELECT 1 FROM question_banks WHERE bank_id=?', [
      bankId,
    ]);
    if (bank.isEmpty) return false;
    Uint8List bytes;
    try {
      bytes = base64Decode(payload['bytes_base64']?.toString() ?? '');
    } on FormatException {
      throw const FormatException('题库媒体分块 Base64 无效');
    }
    if (bytes.length > mediaChunkSize ||
        sha256.convert(bytes).toString() != chunkHash) {
      throw const FormatException('题库媒体分块哈希或大小无效');
    }
    final existing = _db.select(
      'SELECT content FROM synced_media_chunks WHERE chunk_id=?',
      [chunkId],
    );
    if (existing.isNotEmpty) {
      final existingBytes = existing.first['content'] as Uint8List;
      if (sha256.convert(existingBytes).toString() != chunkHash) {
        throw FormatException('题库媒体分块 $chunkId 与本地内容冲突');
      }
      return true;
    }
    _db.execute(
      '''
      INSERT INTO synced_media_chunks(
        chunk_id,bank_id,catalog_version,relative_path,file_sha256,total_size,
        chunk_index,chunk_count,content
      ) VALUES(?,?,?,?,?,?,?,?,?)
    ''',
      [
        chunkId,
        bankId,
        catalogVersion,
        normalizedRelativePath,
        fileHash,
        totalSize,
        chunkIndex,
        chunkCount,
        bytes,
      ],
    );
    return true;
  }

  void materializeSyncedMedia(String mediaRoot) {
    final groups = _db.select('''
      SELECT bank_id,catalog_version,relative_path,file_sha256,total_size,
        chunk_count,COUNT(*) received
      FROM synced_media_chunks
      WHERE materialized_at_utc IS NULL
      GROUP BY bank_id,catalog_version,relative_path,file_sha256,total_size,chunk_count
      HAVING COUNT(*)=chunk_count
    ''');
    for (final group in groups) {
      final bankId = group['bank_id'] as String;
      final catalogVersion = group['catalog_version'] as int;
      final relativePath = group['relative_path'] as String;
      final expectedHash = group['file_sha256'] as String;
      final expectedSize = group['total_size'] as int;
      final chunks = _db.select(
        '''
        SELECT content FROM synced_media_chunks
        WHERE bank_id=? AND catalog_version=? AND relative_path=? AND file_sha256=?
        ORDER BY chunk_index
      ''',
        [bankId, catalogVersion, relativePath, expectedHash],
      );
      final builder = BytesBuilder(copy: false);
      for (final chunk in chunks) {
        builder.add(chunk['content'] as Uint8List);
      }
      final bytes = builder.takeBytes();
      if (bytes.length != expectedSize ||
          sha256.convert(bytes).toString() != expectedHash) {
        throw FormatException('题库媒体 ${p.basename(relativePath)} 完整性校验失败');
      }
      if (!isSafeBankId(bankId)) {
        throw const FormatException('bank_id 包含无效目录字符');
      }
      final directory = Directory(p.join(mediaRoot, bankId, 'v$catalogVersion'))
        ..createSync(recursive: true);
      final target = File(p.join(directory.path, p.basename(relativePath)));
      final temporary = File('${target.path}.sync-part');
      temporary.writeAsBytesSync(bytes, flush: true);
      if (target.existsSync()) target.deleteSync();
      temporary.renameSync(target.path);
      _db.execute(
        '''
        UPDATE synced_media_chunks SET materialized_at_utc=?
        WHERE bank_id=? AND catalog_version=? AND relative_path=? AND file_sha256=?
      ''',
        [_now(), bankId, catalogVersion, relativePath, expectedHash],
      );
    }
  }

  bool _mergeRemoteAnswerEvent(
    Map<String, Object?> payload,
    Set<String> affectedQuestions,
  ) {
    final event = AnswerEvent.fromJson(payload);
    if (questionById(event.questionId) == null) {
      return false;
    }
    final hash = _eventHash(event);
    final existing = _db.select(
      'SELECT payload_hash FROM answer_events WHERE event_id=?',
      [event.eventId],
    );
    if (existing.isNotEmpty) {
      if (existing.first['payload_hash'] != hash) {
        _recordConflict(
          event.eventId,
          existing.first['payload_hash'] as String,
          event.canonicalJson(),
          sourceDevice: event.deviceId,
        );
        _db.execute(
          "UPDATE answer_events SET sync_state='conflict' WHERE event_id=?",
          [event.eventId],
        );
      }
      return true;
    }
    _insertEvent(
      event,
      hash,
      randomErrorsReturnToWrong: true,
      syncState: 'uploaded',
      enqueue: false,
      updateProgress: false,
    );
    affectedQuestions.add(event.questionId);
    return true;
  }

  bool _mergeRemoteQuestionControl(Map<String, Object?> payload) {
    final questionId = payload['question_id']! as String;
    if (questionById(questionId) == null) {
      return false;
    }
    final incomingVersion = (payload['version'] as num?)?.toInt() ?? 0;
    final baseVersion = (payload['base_version'] as num?)?.toInt() ?? 0;
    final incomingUpdated = DateTime.parse(
      payload['updated_at_utc']! as String,
    ).toUtc();
    final incomingDevice = payload['device_id']?.toString() ?? '';
    final rows = _db.select(
      'SELECT version,updated_at_utc,source_device_id FROM question_control_versions WHERE question_id=?',
      [questionId],
    );
    final localVersion = rows.isEmpty ? 0 : rows.first['version'] as int;
    final localUpdated = rows.isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        : DateTime.parse(rows.first['updated_at_utc'] as String).toUtc();
    final localDevice = rows.isEmpty
        ? ''
        : rows.first['source_device_id'] as String;
    if (incomingVersion < localVersion) return true;
    final incomingWins =
        incomingVersion > localVersion ||
        incomingUpdated.isAfter(localUpdated) ||
        (incomingUpdated == localUpdated &&
            incomingDevice.compareTo(localDevice) > 0);
    if (!incomingWins) return true;

    final current = progress(questionId);
    final incomingNote = payload['personal_note_markdown']?.toString() ?? '';
    final baseNoteHash = payload['base_note_hash']?.toString();
    final localNoteHash = sha256
        .convert(utf8.encode(current.personalNote))
        .toString();
    final noteConflict =
        incomingNote != current.personalNote &&
        ((baseNoteHash != null && baseNoteHash != localNoteHash) ||
            (baseNoteHash == null && baseVersion < localVersion));
    if (noteConflict) {
      _recordConflict(
        questionId,
        jsonEncode({'personal_note_markdown': current.personalNote}),
        jsonEncode({'personal_note_markdown': incomingNote}),
        entityType: 'question_progress_control',
        sourceDevice: incomingDevice,
      );
    }
    _db.execute(
      '''
      UPDATE question_progress SET is_favorite=?,is_uncertain=?,is_excluded=?,
        personal_note_markdown=?,updated_at_utc=?,version=version+1 WHERE question_id=?
    ''',
      [
        payload['is_favorite'] == true ? 1 : 0,
        payload['is_uncertain'] == true ? 1 : 0,
        payload['is_excluded'] == true ? 1 : 0,
        noteConflict ? current.personalNote : incomingNote,
        incomingUpdated.toIso8601String(),
        questionId,
      ],
    );
    _db.execute(
      '''
      INSERT INTO question_control_versions(question_id,version,updated_at_utc,source_device_id)
      VALUES(?,?,?,?) ON CONFLICT(question_id) DO UPDATE SET
        version=excluded.version,updated_at_utc=excluded.updated_at_utc,
        source_device_id=excluded.source_device_id
    ''',
      [
        questionId,
        incomingVersion,
        incomingUpdated.toIso8601String(),
        incomingDevice,
      ],
    );
    return true;
  }

  void _mergeRemotePaper(
    Map<String, Object?> payload,
    Map<String, Object?> change,
  ) {
    final attemptId = payload['attempt_id']! as String;
    // 本机推送的试卷会被同一游标拉回：以本地为准，不归档、不与本地记录冲突。
    final ownDevice = payload['source_device_id']?.toString() == deviceId;
    final incomingJson = jsonEncode(payload);
    final incomingHash =
        change['payload_hash']?.toString() ??
        sha256.convert(utf8.encode(incomingJson)).toString();
    final existing = _db.select(
      'SELECT 1 FROM paper_attempts WHERE attempt_id=?',
      [attemptId],
    );
    if (existing.isNotEmpty) {
      if (ownDevice) return;
      final known = _db.select(
        '''
        SELECT payload_hash FROM synced_entity_hashes
        WHERE entity_type='paper_attempt' AND entity_id=?
        UNION ALL
        SELECT payload_hash FROM sync_outbox
        WHERE entity_type='paper_attempt' AND entity_id=? LIMIT 1
      ''',
        [attemptId, attemptId],
      );
      if (known.isNotEmpty && known.first['payload_hash'] != incomingHash) {
        _recordConflict(
          attemptId,
          known.first['payload_hash'] as String,
          incomingJson,
          entityType: 'paper_attempt',
          sourceDevice: payload['source_device_id']?.toString(),
        );
        return;
      }
    } else {
      final now = _now();
      _db.execute(
        '''
        INSERT INTO paper_attempts(attempt_id,paper_id,title,bank_id,status,
          scoring_rule_json,started_at_utc,submitted_at_utc,duration_ms,
          suggested_duration_ms,overtime_ms,score,max_score,source_device_id,
          archived_locally,created_at_utc,updated_at_utc)
        VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,1,?,?)
      ''',
        [
          attemptId,
          payload['paper_id']! as String,
          payload['title']?.toString() ?? '同步试卷',
          payload['bank_id']! as String,
          payload['status']?.toString() ?? AttemptStatus.submitted.name,
          jsonEncode(<String, Object?>{
            'composition_mode':
                payload['composition_mode']?.toString() ??
                PaperCompositionMode.realExam.name,
            'scoring_policy':
                (payload['scoring_policy'] as Map?)?.cast<String, Object?>() ??
                const <String, Object?>{},
          }),
          payload['started_at_utc']! as String,
          payload['submitted_at_utc'] as String?,
          (payload['duration_ms'] as num?)?.toInt() ?? 0,
          (payload['suggested_duration_ms'] as num?)?.toInt() ?? 0,
          (payload['overtime_ms'] as num?)?.toInt() ?? 0,
          (payload['score'] as num?)?.toDouble(),
          (payload['max_score'] as num?)?.toDouble(),
          payload['source_device_id']?.toString() ?? '',
          now,
          now,
        ],
      );
      final questions = payload['questions'] as List? ?? const [];
      for (var position = 0; position < questions.length; position++) {
        final raw = (questions[position] as Map).cast<String, Object?>();
        final snapshot = (raw['question'] as Map).cast<String, Object?>();
        final question = Question.fromSnapshot(snapshot);
        _db.execute(
          '''
          INSERT INTO paper_attempt_questions(attempt_id,position,question_id,
            question_version,event_id,snapshot_json,selected_json,uncertain,duration_ms)
          VALUES(?,?,?,?,?,?,?,?,?)
        ''',
          [
            attemptId,
            position,
            question.id,
            question.contentVersion,
            raw['event_id']?.toString() ?? '$attemptId:$position',
            jsonEncode(snapshot),
            jsonEncode(
              (raw['selected'] as List? ?? const [])
                  .map((value) => value.toString())
                  .toList(),
            ),
            raw['uncertain'] == true ? 1 : 0,
            (raw['duration_ms'] as num?)?.toInt() ?? 0,
          ],
        );
      }
    }
    _db.execute(
      '''
      INSERT INTO synced_entity_hashes(entity_type,entity_id,payload_hash,updated_at_utc)
      VALUES('paper_attempt',?,?,?) ON CONFLICT(entity_type,entity_id) DO UPDATE SET
        payload_hash=excluded.payload_hash,updated_at_utc=excluded.updated_at_utc
    ''',
      [attemptId, incomingHash, _now()],
    );
    if (archivesRemotePapers && !ownDevice) {
      _db.execute(
        'UPDATE paper_attempts SET archived_locally=1 WHERE attempt_id=?',
        [attemptId],
      );
      final ackPayload = jsonEncode(<String, Object?>{
        'attempt_id': attemptId,
        'archived_by_windows_at': _now(),
        'device_id': deviceId,
      });
      _enqueue(
        'paper_archive_ack',
        attemptId,
        'upsert',
        ackPayload,
        sha256.convert(utf8.encode(ackPayload)).toString(),
      );
    }
  }

  void _rebuildProgress(String questionId) {
    final events = _db.select(
      '''
      SELECT selected_json,correct,duration_ms,answered_at_utc,mode
      FROM answer_events WHERE question_id=?
      ORDER BY answered_at_utc,event_id
    ''',
      [questionId],
    );
    var state = StudyState.unseen;
    var correctCount = 0;
    var wrongCount = 0;
    var totalDuration = 0;
    var lastSelected = '[]';
    String? lastResult;
    String? lastAnswered;
    final randomErrorsReturnToWrong =
        getSetting<bool>('random_errors_return_wrong') ?? true;
    for (final event in events) {
      final correct = (event['correct'] as int) == 1;
      if (correct) {
        correctCount++;
      } else {
        wrongCount++;
      }
      state = StudyPolicy.afterAnswer(
        before: state,
        correct: correct,
        randomErrorsReturnToWrong: randomErrorsReturnToWrong,
        isRandomPractice: event['mode'] == 'practice_random',
      );
      totalDuration += event['duration_ms'] as int;
      lastSelected = event['selected_json'] as String;
      lastResult = correct ? 'correct' : 'wrong';
      lastAnswered = event['answered_at_utc'] as String;
    }
    _db.execute(
      '''
      UPDATE question_progress SET state=?,seen_count=?,correct_count=?,wrong_count=?,
        ever_wrong=?,last_selected_json=?,last_result=?,last_answered_at_utc=?,
        total_duration_ms=?,updated_at_utc=?,version=version+1 WHERE question_id=?
    ''',
      [
        state.name,
        events.length,
        correctCount,
        wrongCount,
        wrongCount > 0 ? 1 : 0,
        lastSelected,
        lastResult,
        lastAnswered,
        totalDuration,
        _now(),
        questionId,
      ],
    );
  }

  List<Map<String, Object?>> syncErrors() => _db
      .select('''
    SELECT outbox_id,entity_type,entity_id,attempt_count,next_retry_at_utc,last_error
    FROM sync_outbox WHERE completed_at_utc IS NULL AND last_error IS NOT NULL
    ORDER BY created_at_utc DESC LIMIT 50
  ''')
      .map((row) => Map<String, Object?>.from(row))
      .toList();

  List<Map<String, Object?>> pendingOutbox({
    int limit = 100,
    bool includeDeferred = false,
  }) => _db
      .select(
        '''
    SELECT * FROM sync_outbox WHERE completed_at_utc IS NULL
      AND (?=1 OR next_retry_at_utc IS NULL OR next_retry_at_utc<=?)
    ORDER BY created_at_utc LIMIT ?
  ''',
        [includeDeferred ? 1 : 0, _now(), limit],
      )
      .map((row) => Map<String, Object?>.from(row))
      .toList();

  List<Map<String, Object?>> pendingOutboxSummary({int limit = 500}) => _db
      .select(
        '''
    SELECT outbox_id,entity_type,entity_id,operation,attempt_count,
      next_retry_at_utc,last_error,created_at_utc
    FROM sync_outbox WHERE completed_at_utc IS NULL
    ORDER BY created_at_utc DESC LIMIT ?
  ''',
        [limit],
      )
      .map((row) => Map<String, Object?>.from(row))
      .toList();

  int deletePendingOutbox(Iterable<String> outboxIds) {
    final ids = outboxIds.toSet().toList();
    if (ids.isEmpty) return 0;
    var deleted = 0;
    _transaction(() {
      final rows = _db.select('''
        SELECT outbox_id,entity_type,entity_id,payload_json
        FROM sync_outbox
        WHERE completed_at_utc IS NULL
          AND outbox_id IN (${List.filled(ids.length, '?').join(',')})
        ''', ids);
      final dismiss = _db.prepare('''
        INSERT INTO dismissed_sync_outbox(
          outbox_id,entity_type,entity_id,payload_fingerprint,dismissed_at_utc
        ) VALUES(?,?,?,?,?)
        ON CONFLICT(outbox_id) DO UPDATE SET
          entity_type=excluded.entity_type,
          entity_id=excluded.entity_id,
          payload_fingerprint=excluded.payload_fingerprint,
          dismissed_at_utc=excluded.dismissed_at_utc
        ''');
      final remove = _db.prepare(
        'DELETE FROM sync_outbox WHERE outbox_id=? AND completed_at_utc IS NULL',
      );
      try {
        for (final row in rows) {
          final outboxId = row['outbox_id'] as String;
          final entityType = row['entity_type'] as String;
          dismiss.execute([
            outboxId,
            entityType,
            row['entity_id'] as String,
            _payloadFingerprint(entityType, row['payload_json'] as String),
            _now(),
          ]);
          remove.execute([outboxId]);
          deleted += _db.updatedRows;
        }
      } finally {
        dismiss.close();
        remove.close();
      }
    });
    return deleted;
  }

  void markOutboxComplete(String outboxId) => _markOutboxComplete(outboxId);

  void _markOutboxComplete(String outboxId) {
    final rows = _db.select(
      'SELECT entity_type,entity_id,payload_hash FROM sync_outbox WHERE outbox_id=?',
      [outboxId],
    );
    _db.execute(
      'UPDATE sync_outbox SET completed_at_utc=?,last_error=NULL,next_retry_at_utc=NULL WHERE outbox_id=?',
      [_now(), outboxId],
    );
    if (rows.isEmpty) return;
    final type = rows.first['entity_type'] as String;
    final id = rows.first['entity_id'] as String;
    if (type != 'paper_archive_ack') {
      _db.execute(
        '''
        INSERT INTO synced_entity_hashes(entity_type,entity_id,payload_hash,updated_at_utc)
        VALUES(?,?,?,?) ON CONFLICT(entity_type,entity_id) DO UPDATE SET
          payload_hash=excluded.payload_hash,updated_at_utc=excluded.updated_at_utc
      ''',
        [type, id, rows.first['payload_hash'] as String, _now()],
      );
    }
    if (type == 'answer_event') {
      _db.execute(
        "UPDATE answer_events SET sync_state='uploaded' WHERE event_id=?",
        [id],
      );
    } else if (type == 'paper_archive_ack') {
      _db.execute(
        'UPDATE paper_attempts SET cloud_archive_ack=1 WHERE attempt_id=?',
        [id],
      );
    }
  }

  void markOutboxFailed(String outboxId, String error) => _db.execute(
    '''
    UPDATE sync_outbox SET attempt_count=attempt_count+1,last_error=?,
      next_retry_at_utc=? WHERE outbox_id=?
  ''',
    [
      error,
      DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String(),
      outboxId,
    ],
  );

  List<Map<String, Object?>> syncConflicts() => _db
      .select('''
        SELECT * FROM sync_conflicts WHERE resolved_at_utc IS NULL
        ORDER BY created_at_utc DESC
      ''')
      .map((row) => Map<String, Object?>.from(row))
      .toList();

  int get deferredSyncCount =>
      _db
              .select('SELECT COUNT(*) count FROM deferred_sync_changes')
              .first['count']
          as int;

  void resetProgress(String bankId) {
    _transaction(() {
      _db.execute(
        '''
        DELETE FROM sync_outbox
        WHERE entity_type='answer_event' AND entity_id IN (
          SELECT e.event_id FROM answer_events e
          JOIN questions q ON q.question_id=e.question_id
          WHERE q.bank_id=?
        )
      ''',
        [bankId],
      );
      _db.execute(
        'DELETE FROM answer_events WHERE question_id IN (SELECT question_id FROM questions WHERE bank_id=?)',
        [bankId],
      );
      _db.execute(
        "DELETE FROM paper_attempts WHERE bank_id=? AND status='draft'",
        [bankId],
      );
      _db.execute(
        '''
        UPDATE question_progress SET state='unseen',seen_count=0,correct_count=0,wrong_count=0,
          ever_wrong=0,last_selected_json='[]',last_result=NULL,last_answered_at_utc=NULL,
          total_duration_ms=0,updated_at_utc=?,version=version+1
        WHERE question_id IN (SELECT question_id FROM questions WHERE bank_id=?)
      ''',
        [_now(), bankId],
      );
    });
  }

  String integrityCheck() =>
      _db.select('PRAGMA integrity_check').first.values.first.toString();

  void vacuumInto(String path) {
    _db.execute("VACUUM INTO '${path.replaceAll("'", "''")}'");
  }

  void recordBackup(String path, String reason, String result) => _db.execute(
    '''
    INSERT INTO local_backups(backup_id,path,reason,integrity_result,created_at_utc)
    VALUES(?,?,?,?,?)
  ''',
    [_uuid.v4(), path, reason, result, _now()],
  );

  List<Map<String, Object?>> backupHistory() => _db
      .select(
        'SELECT * FROM local_backups ORDER BY created_at_utc DESC LIMIT 50',
      )
      .map((row) => Map<String, Object?>.from(row))
      .toList();

  void checkpoint() => _db.execute('PRAGMA wal_checkpoint(FULL)');
  void dispose() => _db.close();

  Question _question(Row row) => Question(
    id: row['question_id'] as String,
    bankId: row['bank_id'] as String,
    externalId: row['external_id'] as String?,
    contentVersion: row['content_version'] as int,
    type: QuestionType.values.byName(row['question_type'] as String),
    stem: row['stem_markdown'] as String,
    options: (jsonDecode(row['options_json'] as String) as Map).map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    ),
    answers: (jsonDecode(row['correct_answers_json'] as String) as List)
        .map((e) => e.toString())
        .toList(),
    explanation: row['explanation_markdown'] as String,
    knowledgePoint: row['knowledge_point'] as String,
    source: row['source'] as String,
    year: row['year'] as String,
    chapter: row['chapter'] as String,
    tags: (jsonDecode(row['tags_json'] as String) as List)
        .map((e) => e.toString())
        .toList(),
    media: (jsonDecode(row['media_json'] as String) as List)
        .map((e) => e.toString())
        .toList(),
    scoringRule: ScoringRule.fromJson(
      (jsonDecode(row['scoring_rule_json'] as String) as Map)
          .cast<String, Object?>(),
    ),
    isActive: (row['is_active'] as int) == 1,
  );

  void _enqueue(
    String type,
    String id,
    String operation,
    String payload,
    String hash,
  ) {
    final outboxId = '$type:$id';
    final fingerprint = _payloadFingerprint(type, payload);
    final dismissed = _db.select(
      '''
      SELECT payload_fingerprint FROM dismissed_sync_outbox
      WHERE outbox_id=?
      ''',
      [outboxId],
    );
    if (dismissed.isNotEmpty) {
      if (dismissed.first['payload_fingerprint'] == fingerprint) return;
      _db.execute('DELETE FROM dismissed_sync_outbox WHERE outbox_id=?', [
        outboxId,
      ]);
    }
    _db.execute(
      '''
      INSERT INTO sync_outbox(outbox_id,entity_type,entity_id,operation,
        payload_json,payload_hash,created_at_utc) VALUES(?,?,?,?,?,?,?)
      ON CONFLICT(outbox_id) DO UPDATE SET
        operation=excluded.operation,
        payload_json=excluded.payload_json,
        payload_hash=excluded.payload_hash,
        attempt_count=0,
        next_retry_at_utc=NULL,
        last_error=NULL,
        created_at_utc=excluded.created_at_utc,
        completed_at_utc=NULL
    ''',
      [outboxId, type, id, operation, payload, hash, _now()],
    );
  }

  String _payloadFingerprint(String type, String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        final stable = Map<String, Object?>.from(
          decoded.cast<String, Object?>(),
        )..remove('updated_at_utc');
        return sha256.convert(utf8.encode(jsonEncode(stable))).toString();
      }
    } catch (_) {
      // Locally generated payloads are valid JSON. Keep deletion persistence
      // deterministic even if a legacy row is malformed.
    }
    return sha256.convert(utf8.encode('$type|$payload')).toString();
  }

  void _recordConflict(
    String id,
    String local,
    String incoming, {
    String entityType = 'answer_event',
    String? sourceDevice,
  }) {
    _db.execute(
      '''
      INSERT INTO sync_conflicts(conflict_id,entity_type,entity_id,local_payload,
        incoming_payload,source_device,created_at_utc) VALUES(?,?,?,?,?,?,?)
    ''',
      [_uuid.v4(), entityType, id, local, incoming, sourceDevice, _now()],
    );
  }

  String _eventHash(AnswerEvent event) =>
      sha256.convert(utf8.encode(event.canonicalJson())).toString();

  PaperCompositionMode _storedCompositionMode(String storedJson) {
    final decoded = jsonDecode(storedJson);
    if (decoded is! Map) return PaperCompositionMode.realExam;
    final value = decoded['composition_mode']?.toString();
    return PaperCompositionMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => PaperCompositionMode.realExam,
    );
  }

  PaperScoringPolicy _storedScoringPolicy(String storedJson) {
    final decoded = jsonDecode(storedJson);
    if (decoded is! Map || decoded['scoring_policy'] is! Map) {
      return const PaperScoringPolicy();
    }
    return PaperScoringPolicy.fromJson(
      (decoded['scoring_policy'] as Map).cast<String, Object?>(),
    );
  }

  void _transaction(void Function() body) {
    _db.execute('BEGIN IMMEDIATE');
    try {
      body();
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();
}
