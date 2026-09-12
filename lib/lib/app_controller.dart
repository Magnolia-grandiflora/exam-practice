import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'config/supabase_config.dart';
import 'data/app_database.dart';
import 'data/app_paths.dart';
import 'domain/coded_exceptions.dart';
import 'domain/models.dart';
import 'domain/question_text.dart';
import 'domain/paper_policy.dart';
import 'domain/policies.dart';
import 'services/backup_service.dart';
import 'services/bank_importer.dart';
import 'services/markdown_exporter.dart';
import 'services/pdf_print_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/sync_service.dart';

class AppController extends ChangeNotifier {
  AppController._();
  static const _uuid = Uuid();

  late final AppPaths paths;
  late AppDatabase database;
  late BankImporter importer;
  late BackupService backupService;
  late MarkdownExporter exporter;
  late PdfPrintService pdfPrintService;
  late SyncService syncService;
  late final SupabaseAuthService authService;
  late bool _archivesRemotePapers;
  late bool _publishesQuestionBanks;

  bool initialized = false;
  bool busy = false;
  String? error;
  List<BankSummary> banks = const [];
  BankSummary? currentBank;
  DashboardStats stats = const DashboardStats();
  PaperAttempt? draft;
  List<AttemptSummary> recentHistory = const [];
  bool darkMode = false;
  double fontScale = 1;
  double lineHeight = 1.55;
  double contentWidth = 920;
  /// 界面语言偏好：'system' | 'zh' | 'en'，仅本地保存，不参与云同步。
  String localeTag = 'system';

  /// 新试卷使用的判分策略（设置页可自定义）；随卷快照持久化，不影响历史试卷。
  PaperScoringPolicy paperScoringPolicy = const PaperScoringPolicy();

  /// 是否把题目内容中的排版标记（<p>、<br> 等）渲染为换行等语义。
  bool renderQuestionMarkup = true;
  String _supabaseUrl = '';
  String _supabasePublishableKey = '';
  String _sessionAccessToken = '';
  Future<SyncReport>? _savedSessionSync;
  final String practiceSessionId = _uuid.v4();
  bool _submitPaperInBackground = true;

  static Future<AppController> create() async {
    final controller = AppController._();
    await controller._initialize();
    controller._startAutomaticSync();
    return controller;
  }

  @visibleForTesting
  static Future<AppController> createForTesting(
    Directory root, {
    bool submitPaperInBackground = false,
  }) async {
    final controller = AppController._();
    controller._submitPaperInBackground = submitPaperInBackground;
    await controller._initialize(
      resolvedPaths: AppPaths.at(root),
      archivesRemotePapers: false,
      publishesQuestionBanks: false,
    );
    return controller;
  }

  Future<void> _initialize({
    AppPaths? resolvedPaths,
    bool? archivesRemotePapers,
    bool? publishesQuestionBanks,
  }) async {
    try {
      paths = (resolvedPaths ?? await AppPaths.resolve())..ensureCreated();
      _archivesRemotePapers = archivesRemotePapers ?? Platform.isWindows;
      _publishesQuestionBanks = publishesQuestionBanks ?? Platform.isWindows;
      database = AppDatabase.open(
        paths.database.path,
        archivesRemotePapers: _archivesRemotePapers,
        publishesQuestionBanks: _publishesQuestionBanks,
      );
      importer = BankImporter(database, paths);
      backupService = BackupService(database, paths);
      exporter = MarkdownExporter(database, paths);
      pdfPrintService = const PdfPrintService();
      syncService = SyncService(database, mediaRoot: paths.media.path);
      authService = SupabaseAuthService();
      _supabaseUrl =
          database.getSetting<String>('supabase_url')?.trim() ??
          SupabaseConfig.projectUrl;
      _supabasePublishableKey =
          database.getSetting<String>('supabase_publishable_key')?.trim() ??
          SupabaseConfig.publishableKey;
      _sessionAccessToken =
          database.getSetting<String>('sync_access_token')?.trim() ?? '';
      darkMode = database.getSetting<bool>('dark_mode') ?? false;
      fontScale = ((database.getSetting<Object?>('font_scale') as num?) ?? 1)
          .toDouble();
      lineHeight =
          ((database.getSetting<Object?>('line_height') as num?) ?? 1.55)
              .toDouble();
      contentWidth =
          ((database.getSetting<Object?>('content_width') as num?) ?? 920)
              .toDouble();
      localeTag = switch (database.getSetting<String>('locale_tag')) {
        'zh' || 'en' => database.getSetting<String>('locale_tag')!,
        _ => 'system',
      };
      paperScoringPolicy = PaperScoringPolicy.fromJson(
        (database.getSetting<Object?>('paper_scoring_policy') as Map?)
                ?.cast<String, Object?>() ??
            const {},
      );
      renderQuestionMarkup =
          database.getSetting<bool>('render_question_markup') ?? true;
      banks = database.listBanks();
      if (banks.isEmpty) await _importEmbeddedBank();
      if (database.publishesQuestionBanks) {
        database.enqueueExistingCatalog(paths.media.path);
      }
      await refresh();
      initialized = true;
    } catch (exception, stack) {
      error = '$exception\n$stack';
      initialized = true;
    }
    notifyListeners();
  }

  void _startAutomaticSync() {
    if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) return;
    unawaited(synchronizeSavedSession());
  }

  Future<SyncReport> _refreshAndSynchronize() async {
    try {
      final expiresText = database.getSetting<String>(
        'sync_access_expires_at_utc',
      );
      final expiresAt = expiresText == null
          ? null
          : DateTime.tryParse(expiresText)?.toUtc();
      final refreshToken =
          database.getSetting<String>('sync_refresh_token')?.trim() ?? '';
      final needsRefresh =
          _sessionAccessToken.isEmpty ||
          expiresAt == null ||
          expiresAt.isBefore(
            DateTime.now().toUtc().add(const Duration(minutes: 5)),
          );
      if (needsRefresh &&
          refreshToken.isNotEmpty &&
          _supabaseUrl.isNotEmpty &&
          _supabasePublishableKey.isNotEmpty) {
        final session = await authService.refresh(
          projectUrl: Uri.parse(_supabaseUrl),
          publishableKey: _supabasePublishableKey,
          refreshToken: refreshToken,
        );
        _saveSupabaseSession(session);
      }
      if (canSyncBeforeExit) {
        return await synchronize(
          supabaseUrl: _supabaseUrl,
          publishableKey: _supabasePublishableKey,
          accessToken: _sessionAccessToken,
        );
      }
      return SyncReport(
        uploaded: 0,
        downloaded: 0,
        failed: 0,
        message: '尚未登录 Supabase 个人账号',
        code: 'sync.notLoggedIn',
      );
    } catch (exception) {
      database.setSetting('last_sync_error', exception.toString());
      notifyListeners();
      return SyncReport(
        uploaded: 0,
        downloaded: 0,
        failed: stats.pendingSync,
        message: '会话刷新失败，本地数据安全：$exception',
        code: 'sync.sessionRefreshFailed',
        params: ['$exception'],
      );
    }
  }

  Future<SyncReport> synchronizeSavedSession() {
    final active = _savedSessionSync;
    if (active != null) return active;
    final future = _refreshAndSynchronize();
    _savedSessionSync = future;
    future.whenComplete(() {
      if (identical(_savedSessionSync, future)) _savedSessionSync = null;
    });
    return future;
  }

  void handleAppBackground() {
    prepareForExit();
    if (hasSavedSyncSession) unawaited(synchronizeSavedSession());
  }

  void handleAppForeground() {
    if (hasSavedSyncSession) unawaited(synchronizeSavedSession());
  }

  Future<void> _importEmbeddedBank() async {
    backupService.create(reason: '首次导入前');
    final data = await rootBundle.load('assets/test-bank/test-bank.zip');
    final preview = importer.previewBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      packagePath: 'asset:assets/test-bank/test-bank.zip',
    );
    if (!preview.canImport) {
      throw StateError(preview.issues.map((e) => e.message).join('\n'));
    }
    importer.commit(preview);
  }

  Future<void> refresh() async {
    banks = database.listBanks();
    final remembered = database.getSetting<String>('current_bank_id');
    currentBank =
        banks.where((b) => b.id == remembered).firstOrNull ?? banks.firstOrNull;
    if (currentBank != null) {
      database.setSetting('current_bank_id', currentBank!.id);
      stats = database.dashboard(currentBank!.id);
      draft = database.latestDraft(currentBank!.id);
    } else {
      stats = const DashboardStats();
      draft = null;
    }
    recentHistory = database.history(limit: 100);
    notifyListeners();
  }

  Future<void> selectBank(String bankId) async {
    currentBank = banks.where((bank) => bank.id == bankId).first;
    database.setSetting('current_bank_id', bankId);
    await refresh();
  }

  PracticeMode get automaticPracticeMode =>
      StudyPolicy.automaticMode(unseen: stats.unseen, wrong: stats.wrong);

  List<Question> practiceQueue(
    PracticeMode mode, {
    int limit = 100,
    String? year,
    String? chapter,
    String? tag,
    QuestionType? type,
  }) {
    final bank = currentBank;
    if (bank == null) return const [];
    return database.listQuestions(
      bankId: bank.id,
      mode: mode,
      year: year,
      chapter: chapter,
      tag: tag,
      type: type,
      limit: limit,
      random: mode == PracticeMode.random,
    );
  }

  ScoreResult submitPractice({
    required Question question,
    required Iterable<String> selected,
    required int durationMs,
    required PracticeMode mode,
    String? eventId,
  }) {
    final result = AnswerPolicy.score(question, selected);
    if (!result.isAnswered) {
      throw const CodedFormatException('answer.notSelected', '请先选择答案');
    }
    final event = AnswerEvent(
      eventId: eventId ?? _uuid.v4(),
      deviceId: database.deviceId,
      questionId: question.id,
      questionVersion: question.contentVersion,
      sessionId: practiceSessionId,
      attemptId: null,
      mode: mode == PracticeMode.random ? 'practice_random' : 'practice',
      selected: AnswerPolicy.normalize(selected),
      correct: result.isCompletelyCorrect,
      score: result.score,
      durationMs: durationMs,
      answeredAtUtc: DateTime.now().toUtc(),
      source: 'screen',
    );
    database.submitAnswer(
      event,
      randomErrorsReturnToWrong:
          database.getSetting<bool>('random_errors_return_wrong') ?? true,
    );
    refresh();
    return result;
  }

  void updateMeta(
    Question question, {
    bool? favorite,
    bool? uncertain,
    bool? excluded,
    String? note,
  }) {
    database.updateQuestionMeta(
      question.id,
      favorite: favorite,
      uncertain: uncertain,
      excluded: excluded,
      note: note,
    );
    refresh();
  }

  PaperAttempt createPaper({
    required int requestedCount,
    required int suggestedMinutes,
    required bool random,
    PaperCompositionMode? compositionMode,
    PaperTypeCounts? typeCounts,
    String? year,
    String? chapter,
    String? tag,
    QuestionType? type,
  }) {
    final bank = currentBank!;
    final questions = compositionMode == null
        ? database.listQuestions(
            bankId: bank.id,
            year: year,
            chapter: chapter,
            tag: tag,
            type: type,
            limit: requestedCount,
            random: random,
          )
        : PaperCompositionPolicy.compose(
            database.listQuestions(
              bankId: bank.id,
              year: year,
              chapter: chapter,
              tag: tag,
              type: type,
              // Composition needs the complete filtered pool: selecting the
              // first N rows could hide one type despite sufficient inventory.
              limit: null,
              random: false,
            ),
            mode: compositionMode,
            total: requestedCount,
            random: random,
            counts: typeCounts,
          );
    if (questions.isEmpty) {
      throw CodedStateError('practice.emptyScope', '当前筛选范围没有可用题目');
    }
    final stamp = DateTime.now()
        .toLocal()
        .toIso8601String()
        .substring(0, 16)
        .replaceFirst('T', ' ');
    final paper = database.createPaper(
      bankId: bank.id,
      title: '${bank.name} $stamp',
      questions: questions,
      suggestedDurationMs: suggestedMinutes * 60000,
      compositionMode: compositionMode ?? PaperCompositionMode.realExam,
      scoringPolicy: paperScoringPolicy,
    );
    refresh();
    return paper;
  }

  void savePaper(PaperAttempt attempt) {
    database.savePaperDraft(attempt);
    draft = attempt;
    notifyListeners();
  }

  Future<void> submitPaper(
    PaperAttempt attempt, {
    Map<int, String> sourceByPosition = const {},
  }) async {
    if (!_submitPaperInBackground) {
      database.submitPaper(attempt, sourceByPosition: sourceByPosition);
      await refresh();
      return;
    }
    final databasePath = paths.database.path;
    final result = await Isolate.run<Map<String, Object?>>(() {
      final workerDatabase = AppDatabase.open(
        databasePath,
        archivesRemotePapers: Platform.isWindows,
      );
      try {
        workerDatabase.submitPaper(attempt, sourceByPosition: sourceByPosition);
        return <String, Object?>{
          'status': attempt.status.name,
          'submitted_at_utc': attempt.submittedAtUtc?.toIso8601String(),
          'score': attempt.score,
          'max_score': attempt.maxScore,
        };
      } finally {
        workerDatabase.dispose();
      }
    });
    attempt.status = AttemptStatus.values.byName(result['status']! as String);
    final submittedAt = result['submitted_at_utc'] as String?;
    attempt.submittedAtUtc = submittedAt == null
        ? null
        : DateTime.parse(submittedAt);
    attempt.score = (result['score'] as num?)?.toDouble();
    attempt.maxScore = (result['max_score'] as num?)?.toDouble();
    await refresh();
  }

  Future<void> abandonPaper(
    PaperAttempt attempt, {
    required bool keepDraft,
  }) async {
    database.abandonPaper(attempt, keepDraft: keepDraft);
    await refresh();
  }

  ImportPreview previewImport(String path) => importer.previewFile(path);

  Future<void> commitImport(ImportPreview preview) async {
    backupService.create(reason: '题库导入前');
    final rootPath = paths.root.path;
    final databasePath = paths.database.path;
    await Isolate.run(() {
      final workerPaths = AppPaths.at(Directory(rootPath))..ensureCreated();
      final workerDatabase = AppDatabase.open(
        databasePath,
        publishesQuestionBanks: true,
      );
      try {
        BankImporter(workerDatabase, workerPaths).commit(preview);
      } finally {
        workerDatabase.dispose();
      }
    });
    await refresh();
  }

  Future<String?> chooseQuestionBankFile() => paths.chooseQuestionBankFile();

  Future<void> addQuestion({
    required QuestionType type,
    required String stem,
    required Map<String, String> options,
    required List<String> answers,
    String? externalId,
    String explanation = '',
    String knowledgePoint = '',
    String source = '',
    String year = '',
    String chapter = '',
    List<String> tags = const [],
  }) async {
    final bank = currentBank;
    if (bank == null) throw CodedStateError('bank.notSelected', '请先选择题库');
    database.addQuestion(
      Question(
        id: _uuid.v4(),
        bankId: bank.id,
        externalId: externalId?.trim().isEmpty == true
            ? null
            : externalId?.trim(),
        contentVersion: 1,
        type: type,
        stem: stem.trim(),
        options: options,
        answers: answers,
        explanation: explanation.trim(),
        knowledgePoint: knowledgePoint.trim(),
        source: source.trim().isEmpty ? '用户手动输入' : source.trim(),
        year: year.trim(),
        chapter: chapter.trim(),
        tags: tags,
        media: const [],
        scoringRule: const ScoringRule(),
        isActive: true,
      ),
    );
    await refresh();
  }

  Future<void> deleteCurrentBank() async {
    final bank = currentBank;
    if (bank == null) throw CodedStateError('bank.notSelected', '请先选择题库');
    database.archiveBank(bank.id);
    await refresh();
  }

  Future<void> deleteHistoryAttempt(String attemptId) async {
    database.archiveAttempt(attemptId);
    await refresh();
  }

  String createBackup({String reason = '手动备份'}) {
    final path = backupService.create(reason: reason);
    notifyListeners();
    return path;
  }

  Future<String> resetCurrentBank() async {
    final bank = currentBank;
    if (bank == null) throw CodedStateError('bank.notSelected', '请先选择题库');
    final backupPath = backupService.create(reason: '重置学习状态前');
    database.resetProgress(bank.id);
    await refresh();
    return backupPath;
  }

  Directory exportPaper(
    PaperAttempt attempt, {
    bool blankPaper = true,
    bool answerSheet = true,
    bool? answers,
    bool? review,
    bool paperA3 = false,
    ExportLabels? labels,
  }) => exporter.exportPaper(
    attempt,
    blankPaper: blankPaper,
    answerSheet: answerSheet,
    answers: answers,
    review: review,
    paperA3: paperA3,
    labels: labels ?? const ExportLabels(),
  );
  File writeTemporaryOmrTemplate(
    PaperAttempt attempt,
    Directory directory, {
    ExportLabels? labels,
  }) => exporter.writeOmrTemplate(attempt, directory, labels: labels ?? const ExportLabels());
  File exportWrong({ExportLabels? labels}) =>
      exporter.exportWrongQuestions(currentBank!.id, labels: labels ?? const ExportLabels());
  File exportCollection(
    String title,
    List<Question> questions, {
    ExportLabels? labels,
  }) => exporter.exportQuestionCollection(title, questions, labels: labels ?? const ExportLabels());
  bool get canPrintPdf => pdfPrintService.isSupported;
  Future<File> printPaperPack(Directory directory, {ExportLabels? labels}) =>
      pdfPrintService.printPack(directory, labels: labels ?? const ExportLabels());

  /// 生成试卷 PDF。A4 排版（默认）输出单个 PDF；A3 排版时试卷文档与
  /// 答题卡（恒为 A4）分别输出独立 PDF，避免混排页尺寸。
  Future<List<File>> printPaperPdfs(
    Directory directory, {
    required bool paperA3,
    ExportLabels? labels,
  }) async {
    final effectiveLabels = labels ?? const ExportLabels();
    final manifest = _readPackManifest(directory);
    final files = (manifest['markdown_files'] as List? ?? const [])
        .whereType<String>()
        .toList();
    if (!paperA3) {
      return [
        await pdfPrintService.printPack(directory, labels: effectiveLabels),
      ];
    }
    final sheetFile = manifest['answer_sheet_file']?.toString();
    final paperFiles = files
        .where((file) => file != sheetFile)
        .toList(growable: false);
    final outputs = <File>[];
    if (paperFiles.isNotEmpty) {
      outputs.add(
        await pdfPrintService.printPack(
          directory,
          labels: effectiveLabels,
          onlyFiles: paperFiles,
          outputName: effectiveLabels.paperFileName,
        ),
      );
    }
    if (sheetFile != null) {
      outputs.add(
        await pdfPrintService.printPack(
          directory,
          labels: effectiveLabels,
          onlyFiles: [sheetFile],
          outputName: effectiveLabels.answerSheetFileName,
        ),
      );
    }
    if (outputs.isEmpty) {
      throw const FormatException('试卷包中没有可打印的文件');
    }
    return outputs;
  }

  Map<String, dynamic> _readPackManifest(Directory directory) {
    final file = File(p.join(directory.path, 'manifest.json'));
    if (!file.existsSync()) {
      throw const FormatException('试卷包缺少 manifest.json');
    }
    final decoded = jsonDecode(file.readAsStringSync(encoding: utf8));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('manifest.json 格式无效');
    }
    return decoded;
  }

  void retainOnlyPdfs(Directory directory, List<File> pdfs) =>
      pdfPrintService.retainOnlyPdfs(directory, pdfs);

  Future<SyncReport> synchronize({
    required String supabaseUrl,
    required String publishableKey,
    required String accessToken,
  }) async {
    if (supabaseUrl.trim().isEmpty ||
        publishableKey.trim().isEmpty ||
        accessToken.trim().isEmpty) {
      return const SyncReport(
        uploaded: 0,
        downloaded: 0,
        failed: 0,
        message: '请填写 Supabase 项目 URL、Publishable Key 并登录',
        code: 'sync.missingCloudConfig',
      );
    }
    database.setSetting('supabase_url', supabaseUrl.trim(), syncScope: 'local');
    database.setSetting(
      'supabase_publishable_key',
      publishableKey.trim(),
      syncScope: 'local',
    );
    database.setSetting(
      'sync_access_token',
      accessToken.trim(),
      syncScope: 'local',
    );
    _supabaseUrl = supabaseUrl.trim();
    _supabasePublishableKey = publishableKey.trim();
    _sessionAccessToken = accessToken.trim();
    final report = await syncService.synchronize(
      SupabaseSyncGateway(
        projectUrl: Uri.parse(supabaseUrl.trim()),
        publishableKey: publishableKey.trim(),
        accessToken: accessToken.trim(),
      ),
    );
    if (report.failed == 0) {
      database.setSetting(
        'last_sync_at_utc',
        DateTime.now().toUtc().toIso8601String(),
      );
    }
    await refresh();
    return report;
  }

  Future<SyncReport> signInAndSynchronize({
    required String supabaseUrl,
    required String publishableKey,
    required String email,
    required String password,
  }) async {
    if (supabaseUrl.trim().isEmpty ||
        publishableKey.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty) {
      return const SyncReport(
        uploaded: 0,
        downloaded: 0,
        failed: 0,
        message: '请填写 Supabase 项目 URL、Publishable Key、邮箱和密码',
        code: 'sync.missingAccountConfig',
      );
    }
    final session = await authService.signIn(
      projectUrl: Uri.parse(supabaseUrl.trim()),
      publishableKey: publishableKey.trim(),
      email: email.trim(),
      password: password,
    );
    _supabaseUrl = supabaseUrl.trim();
    _supabasePublishableKey = publishableKey.trim();
    database.setSetting('supabase_url', _supabaseUrl, syncScope: 'local');
    database.setSetting(
      'supabase_publishable_key',
      _supabasePublishableKey,
      syncScope: 'local',
    );
    database.setSetting('sync_email', email.trim(), syncScope: 'local');
    _saveSupabaseSession(session);
    return synchronize(
      supabaseUrl: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
      accessToken: session.accessToken,
    );
  }

  void _saveSupabaseSession(SupabaseSession session) {
    _sessionAccessToken = session.accessToken;
    database.setSetting(
      'sync_access_token',
      session.accessToken,
      syncScope: 'local',
    );
    database.setSetting(
      'sync_refresh_token',
      session.refreshToken,
      syncScope: 'local',
    );
    database.setSetting(
      'sync_access_expires_at_utc',
      session.expiresAtUtc.toUtc().toIso8601String(),
      syncScope: 'local',
    );
    database.setSetting('sync_user_id', session.userId, syncScope: 'local');
  }

  void clearLocalSyncSession() {
    database.setSetting('sync_access_token', '', syncScope: 'local');
    database.setSetting('sync_refresh_token', '', syncScope: 'local');
    database.setSetting('sync_access_expires_at_utc', '', syncScope: 'local');
    database.setSetting('sync_user_id', '', syncScope: 'local');
    _sessionAccessToken = '';
    notifyListeners();
  }

  bool get hasSavedSyncSession =>
      _sessionAccessToken.isNotEmpty ||
      (database.getSetting<String>('sync_refresh_token')?.trim().isNotEmpty ??
          false);
  String get savedSyncEmail =>
      database.getSetting<String>('sync_email')?.trim() ?? '';
  bool get canSyncBeforeExit =>
      _supabaseUrl.isNotEmpty &&
      _supabasePublishableKey.isNotEmpty &&
      hasSavedSyncSession;
  String? get lastSyncAtUtc => database.getSetting<String>('last_sync_at_utc');

  Future<SyncReport> syncBeforeExit() => synchronizeSavedSession();

  List<Map<String, Object?>> pendingSyncItems() =>
      database.pendingOutboxSummary();

  Future<int> deletePendingSyncItems(Iterable<String> outboxIds) async {
    final deleted = database.deletePendingOutbox(outboxIds);
    await refresh();
    return deleted;
  }

  void updateBackupsDirectory(Directory? directory) {
    paths.setBackupsDirectory(directory);
    notifyListeners();
  }

  void updateExportsDirectory(Directory? directory) {
    paths.setExportsDirectory(directory);
    notifyListeners();
  }

  Future<String?> chooseDirectory() => paths.chooseDirectory();

  Future<void> moveDatabaseTo(Directory? directory) async {
    final oldFile = paths.database;
    final targetDirectory = directory ?? paths.defaultData;
    final targetFile = File(
      p.join(targetDirectory.path, 'personal_exam.sqlite'),
    );
    if (p.equals(p.absolute(oldFile.path), p.absolute(targetFile.path))) return;
    targetDirectory.createSync(recursive: true);
    if (targetFile.existsSync()) {
      throw CodedFileSystemException(
        'storage.targetDirNotEmpty',
        '目标目录已有 personal_exam.sqlite，请选择空目录，避免覆盖原数据库',
        targetFile.path,
      );
    }

    database.checkpoint();
    database.vacuumInto(targetFile.path);
    AppDatabase? replacement;
    try {
      replacement = AppDatabase.open(
        targetFile.path,
        archivesRemotePapers: _archivesRemotePapers,
        publishesQuestionBanks: _publishesQuestionBanks,
      );
      final integrity = replacement.integrityCheck();
      if (integrity != 'ok') {
        throw CodedStateError(
          'storage.integrityCheckFailed',
          '新数据库完整性检查失败：$integrity',
          [integrity],
        );
      }
      paths.setDatabaseDirectory(directory);
    } catch (_) {
      replacement?.dispose();
      if (targetFile.existsSync()) targetFile.deleteSync();
      rethrow;
    }

    database.dispose();
    database = replacement;
    importer = BankImporter(database, paths);
    backupService = BackupService(database, paths);
    exporter = MarkdownExporter(database, paths);
    syncService = SyncService(database, mediaRoot: paths.media.path);
    await refresh();
  }

  void prepareForExit() {
    database.checkpoint();
    if (currentBank != null) stats = database.dashboard(currentBank!.id);
    notifyListeners();
  }

  String? mediaPath(Question question, String media) {
    final file = File(
      '${paths.media.path}${Platform.pathSeparator}${question.bankId}'
      '${Platform.pathSeparator}v${currentBank?.contentVersion ?? question.contentVersion}'
      '${Platform.pathSeparator}${media.replaceAll('\\', '/').split('/').last}',
    );
    return file.existsSync() ? file.path : null;
  }

  void updateAppearance({
    bool? dark,
    double? font,
    double? line,
    double? width,
  }) {
    darkMode = dark ?? darkMode;
    fontScale = font ?? fontScale;
    lineHeight = line ?? lineHeight;
    contentWidth = width ?? contentWidth;
    database.setSetting('dark_mode', darkMode);
    database.setSetting('font_scale', fontScale);
    database.setSetting('line_height', lineHeight);
    database.setSetting('content_width', contentWidth);
    notifyListeners();
  }

  void setLocaleTag(String tag) {
    if (tag != 'system' && tag != 'zh' && tag != 'en') return;
    localeTag = tag;
    database.setSetting('locale_tag', localeTag);
    notifyListeners();
  }

  void updatePaperScoringPolicy(PaperScoringPolicy policy) {
    paperScoringPolicy = policy;
    database.setSetting('paper_scoring_policy', policy.toJson());
    notifyListeners();
  }

  void setRenderQuestionMarkup(bool value) {
    renderQuestionMarkup = value;
    database.setSetting('render_question_markup', value);
    notifyListeners();
  }

  /// 题目内容（题干/选项/解析）的统一显示转换：
  /// 开启渲染时把 <p>/<br> 等标记转换为换行等语义，关闭时保持历史剥离行为。
  String questionText(String value) => renderQuestionMarkup
      ? renderMarkupText(value)
      : plainText(value);

  void setRandomErrorsReturnToWrong(bool value) {
    database.setSetting('random_errors_return_wrong', value);
    notifyListeners();
  }

  @override
  void dispose() {
    authService.dispose();
    database.dispose();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
