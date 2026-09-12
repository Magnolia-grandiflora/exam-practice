// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Exam Practice';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDone => 'Done';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonEmpty => 'No data yet';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonAll => 'All';

  @override
  String get commonEnabled => 'Enabled';

  @override
  String get commonDisabled => 'Disabled';

  @override
  String get commonPending => 'Pending';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonDetails => 'Details';

  @override
  String get exitQuitTitle => 'Quit Exam Practice';

  @override
  String exitPendingTitle(int count) {
    return '$count item(s) waiting to sync';
  }

  @override
  String get exitPendingBody =>
      'All answers and drafts are saved to the local SQLite database. You can sync first, or quit now and keep the pending sync queue.';

  @override
  String exitSavedBody(String lastSync) {
    return 'Local data is saved. Last sync: $lastSync';
  }

  @override
  String get exitNeverSynced => 'never synced';

  @override
  String get exitStayWithoutSync => 'Quit without syncing';

  @override
  String get exitQuit => 'Quit';

  @override
  String get exitSyncAndQuit => 'Sync and quit';

  @override
  String get exitCancelQuit => 'Cancel quit';

  @override
  String get exitQuitDirect => 'Quit now';

  @override
  String get syncFailedTitle => 'Sync failed';

  @override
  String syncFailedBody(String message) {
    return '$message\nThe pending sync queue is kept locally.';
  }

  @override
  String get startupErrorTitle => 'Startup failed';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageHelp =>
      'UI language. Exported documents (papers, answer sheets, explanations) use labels in the UI language; question content stays as-is.';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get omrReviewTitle => 'Windows Answer Sheet OMR Grading';

  @override
  String get omrWindowsOnly =>
      'Answer sheet OMR grading is available on Windows only';

  @override
  String omrImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String omrRecognizeFailed(String error) {
    return 'Recognition failed: $error';
  }

  @override
  String omrSubmitFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String get omrReviewIntro =>
      'Choose a photo of the exported paper answer sheet. Recognition results are shown on this page only; answer events are written only after you review every question and confirm the submission.';

  @override
  String get omrRecognizing => 'Recognizing…';

  @override
  String get omrPickImage => 'Choose Answer Sheet Image';

  @override
  String get omrPasteClipboard => 'Paste from Clipboard (Ctrl+V)';

  @override
  String get omrPreviewUnavailable => 'Preview unavailable';

  @override
  String get omrOverlayHint =>
      'The photo stays fixed; dragging, pinch zoom and rotation only adjust the recognition overlay.';

  @override
  String get omrOverlayAlignLabel => 'Overlay alignment:';

  @override
  String get omrOverlayReset => 'Reset Overlay';

  @override
  String get omrReviewEachQuestion => 'Review Each Question';

  @override
  String get omrReviewEditableHint =>
      'You can change selections directly. Nothing is changed in the current paper or written to the answer history until you confirm.';

  @override
  String get omrConfirmWrite => 'Confirm Recognition & Submit Paper';

  @override
  String get omrConfirmWriteTitle =>
      'Confirm recognition results and submit the paper?';

  @override
  String get omrConfirmWriteBody =>
      'Answer events are only written and the paper only submitted after your confirmation, and can no longer be changed afterwards.';

  @override
  String get omrKeepReviewing => 'Keep Reviewing';

  @override
  String get omrConfirmSubmit => 'Submit Paper';

  @override
  String omrQuestionHeader(int number, String type) {
    return 'Question $number · $type';
  }

  @override
  String get omrQuestionTypeSingle => 'Single choice';

  @override
  String get omrQuestionTypeMultiple => 'Multiple choice';

  @override
  String get dashboardTitle => 'Home';

  @override
  String get dashboardCurrentBank => 'Current question bank';

  @override
  String get dashboardNoBank => 'No question bank yet';

  @override
  String get dashboardTagline =>
      'Offline-first · Answers saved instantly · Unseen questions first';

  @override
  String get dashboardAllSaved => 'Saved locally';

  @override
  String dashboardPendingSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items pending sync',
      one: '1 item pending sync',
    );
    return '$_temp0';
  }

  @override
  String get dashboardQuickStart => 'Quick start';

  @override
  String get dashboardContinueUnseen => 'Continue unseen questions';

  @override
  String get dashboardStartWrongReview => 'Review wrong answers';

  @override
  String get dashboardViewWrong => 'View wrong answers';

  @override
  String get dashboardCreatePaper => 'Create paper';

  @override
  String get dashboardResumeDraft => 'Resume unfinished paper';

  @override
  String get dashboardRecentPapers => 'Recent papers';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonChoose => 'Choose';

  @override
  String get commonNone => 'None';

  @override
  String get commonConfirmResetPhrase => 'RESET';

  @override
  String get statsTotalQuestions => 'Total questions';

  @override
  String get statsUnseen => 'Unseen';

  @override
  String get statsCurrentWrong => 'Current wrong answers';

  @override
  String get statsMastered => 'Mastered';

  @override
  String get statsEverWrong => 'Ever wrong';

  @override
  String get statsPendingSync => 'Pending sync';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsNoBank => 'No question bank';

  @override
  String get statsByYear => 'By year';

  @override
  String get statsByChapter => 'By chapter';

  @override
  String get statsByTag => 'By tag';

  @override
  String get statsByType => 'By question type';

  @override
  String get statsSlowTitle => 'Slowest questions (interaction estimate)';

  @override
  String statsSeenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count answers',
      one: '1 answer',
    );
    return '$_temp0';
  }

  @override
  String statsSecondsPerQuestion(String seconds) {
    return '$seconds s/question';
  }

  @override
  String statsSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get statsColumnCategory => 'Category';

  @override
  String get statsColumnCount => 'Questions';

  @override
  String get statsColumnAttempts => 'Answers';

  @override
  String get statsColumnAccuracy => 'Accuracy';

  @override
  String get statsColumnAvgTime => 'Avg. time';

  @override
  String get statsUncategorized => 'Uncategorized';

  @override
  String get modeUnseen => 'Unseen first';

  @override
  String get modeWrongReview => 'Wrong-answer review';

  @override
  String get modeRandom => 'Random practice';

  @override
  String get modeFavorite => 'Favorites';

  @override
  String get modeUncertain => 'Uncertain';

  @override
  String get practiceTitle => 'Practice';

  @override
  String practiceDefaultPolicy(String mode) {
    return 'Default strategy: $mode';
  }

  @override
  String get practiceDefaultPolicyDesc =>
      'Cover all unseen questions first; a question missed for the first time is not repeated early in the unseen phase; once unseen is cleared, review current wrong answers.';

  @override
  String get practiceStartDefault => 'Start with default strategy';

  @override
  String get practiceCustomScope => 'Custom scope:';

  @override
  String get practiceClearFilters => 'Clear filters';

  @override
  String get practiceShortcutsHint =>
      'Shortcuts: A—E to select, Enter to submit, ← / → to switch questions. Shortcuts pause while you type a personal note.';

  @override
  String practiceQueueEmpty(String mode) {
    return 'No questions in $mode';
  }

  @override
  String practiceModeCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get filterAllYear => 'All years';

  @override
  String get filterAllChapter => 'All chapters';

  @override
  String get filterAllTag => 'All tags';

  @override
  String get filterAllTypes => 'All question types';

  @override
  String get questionTypeSingle => 'Single-choice';

  @override
  String get questionTypeMultiple => 'Multiple-choice';

  @override
  String get questionTypeSingleShort => 'Single';

  @override
  String get questionTypeMultipleShort => 'Multiple';

  @override
  String get paperTitle => 'Papers';

  @override
  String get papersNoRecords => 'No paper records yet';

  @override
  String papersSubtitle(int count, String status, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0 · $status · $duration';
  }

  @override
  String get paperDraftAvailable => 'An unfinished paper exists';

  @override
  String get paperScopeTitle => 'Question scope';

  @override
  String paperScopeSummary(int pool, String picker, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      pool,
      locale: localeName,
      other: '$pool questions',
      one: '1 question',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return 'Current scope: $_temp0; $picker $_temp1.';
  }

  @override
  String get paperPickerRandom => 'will randomly pick';

  @override
  String get paperPickerInOrder => 'will take the first';

  @override
  String get paperCompositionTitle => 'Composition mode';

  @override
  String get paperCompositionSingleOnly => 'Single only';

  @override
  String get paperCompositionMultipleOnly => 'Multiple only';

  @override
  String get paperCompositionRealExam => 'Real exam';

  @override
  String get paperCountTitle => 'Question count';

  @override
  String get paperCustomCount => 'Custom 1—100:';

  @override
  String get paperSuggestedMinutes => 'Suggested time (minutes):';

  @override
  String get paperRandomTitle => 'Random selection';

  @override
  String get paperRandomDesc =>
      'When on, questions are drawn at random from the current filter and shuffled; when off, questions follow the bank order.';

  @override
  String get paperGenerateStart => 'Generate and start paper';

  @override
  String get paperNote =>
      'If the scope has fewer questions, only the actual count is used; no out-of-scope questions are added. Answers and explanations stay hidden before submission.';

  @override
  String paperAdjustedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Only $count questions are in the current scope; the paper was created with the actual count.',
      one: 'Only 1 question is in the current scope; the paper was created with the actual count.',
    );
    return '$_temp0';
  }

  @override
  String get attemptStatusDraft => 'In progress';

  @override
  String get attemptStatusSubmitted => 'Submitted';

  @override
  String get attemptStatusAbandoned => 'Abandoned';

  @override
  String get historyTitle => 'Paper history';

  @override
  String get historyDeleteTooltip => 'Delete this paper record';

  @override
  String get historyDeleteTitle => 'Delete paper record?';

  @override
  String historyDeleteBody(String title) {
    return '“$title” will be removed from the paper history list. Question answer statistics already produced will not be deleted.';
  }

  @override
  String historyDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get collectionTitle => 'Wrong answers / favorites';

  @override
  String get collectionEverWrongTitle => 'Past wrong answers';

  @override
  String get collectionExcludedTitle => 'Excluded questions';

  @override
  String get collectionGenericTitle => 'Question set';

  @override
  String get collectionExport => 'Export current category';

  @override
  String collectionExported(String path) {
    return 'Exported: $path';
  }

  @override
  String get collectionFavorite => 'Favorites';

  @override
  String get collectionUncertain => 'Uncertain';

  @override
  String get collectionExcluded => 'Excluded';

  @override
  String get collectionEmpty => 'No questions in this category';

  @override
  String collectionItemSubtitle(String type, int seen, int wrong) {
    String _temp0 = intl.Intl.pluralLogic(
      seen,
      locale: localeName,
      other: '$seen answers',
      one: '1 answer',
    );
    String _temp1 = intl.Intl.pluralLogic(
      wrong,
      locale: localeName,
      other: '$wrong wrong',
      one: '1 wrong',
    );
    return '$type · $_temp0 · $_temp1';
  }

  @override
  String get collectionHistoryTooltip => 'Full answer history';

  @override
  String collectionHistoryTitle(String id) {
    return '$id · Full answer history';
  }

  @override
  String get collectionNoEvents => 'No answer events yet';

  @override
  String collectionAnsweredAt(String time, String selected) {
    return '$time · Selected: $selected';
  }

  @override
  String get collectionNotAnswered => 'Not answered';

  @override
  String collectionEventSubtitle(String mode, String score, String duration) {
    return '$mode · Score $score · Time $duration';
  }

  @override
  String get banksTitle => 'Question banks';

  @override
  String get banksAddQuestion => 'Add question manually';

  @override
  String get banksPickerHint => 'Select bank';

  @override
  String get banksReadonlyTitle => 'Android banks are read-only';

  @override
  String banksReadonlyBody(String name) {
    return 'Current bank: $name. Bulk import, editing, disabling and publishing are done on Windows; this device can browse questions and merge study records through sync.';
  }

  @override
  String get banksImportTitle => 'Import question bank (ZIP / TSV / CSV)';

  @override
  String get banksImportHint => 'D:\\Banks\\example.tsv';

  @override
  String get banksChooseFile => 'Choose file';

  @override
  String get banksPreview => 'Preview & validate';

  @override
  String get banksBackupAndImport => 'Back up & import';

  @override
  String banksPreviewSummary(
    String name,
    int total,
    int single,
    int multiple,
    int blocking,
    int warnings,
  ) {
    return '$name: $total questions ($single single-choice, $multiple multiple-choice); $blocking blocking, $warnings warnings';
  }

  @override
  String get banksResetTitle => 'Start over';

  @override
  String banksResetBody(String name, int count) {
    return 'Resets all $count questions in “$name” to unseen. Question content, favorites, personal notes and submitted paper history are kept.';
  }

  @override
  String get banksResetAction => 'Reset answer state';

  @override
  String get banksDeleteTitle => 'Delete current bank';

  @override
  String banksDeleteBody(String name) {
    return 'Removes “$name” from the bank list. Submitted papers and answer statistics are kept.';
  }

  @override
  String get banksDeleteAction => 'Delete bank';

  @override
  String get banksClearSearch => 'Clear search';

  @override
  String get banksSearchLabel => 'Search bank';

  @override
  String get banksSearchHint =>
      'ID, stem, options, answer, explanation, knowledge point, source, year, chapter, or tags';

  @override
  String banksLoadMore(int shown, int total) {
    return 'Load more (showing $shown of $total)';
  }

  @override
  String banksFilePickerFailed(String error) {
    return 'Could not open the file picker: $error';
  }

  @override
  String get banksPreviewOk => 'Validation passed with no warnings.';

  @override
  String get banksIssueBlocking => 'Blocking';

  @override
  String get banksIssueWarning => 'Warning';

  @override
  String banksIssueLine(String severity, String message) {
    return '$severity: $message';
  }

  @override
  String banksReadFailed(String error) {
    return 'Could not read the bank package: $error';
  }

  @override
  String get banksImportDone =>
      'Import finished; the pre-import backup passed the integrity check.';

  @override
  String banksResetDialogTitle(String name) {
    return 'Reset answer state of “$name”?';
  }

  @override
  String banksResetDialogBody(String phrase) {
    return 'The app will first create and verify a database backup, then:\n• All questions go back to “unseen”\n• Answer events, correct/wrong counts and total time are cleared\n• Unfinished paper drafts of this bank are deleted\n\nQuestion content, favorites, personal notes and submitted paper history are not deleted.\nType $phrase to continue.';
  }

  @override
  String get banksResetConfirmAction => 'Back up & reset';

  @override
  String banksResetting(String name) {
    return 'Backing up and resetting “$name”…';
  }

  @override
  String banksResetDone(String name, String backupPath) {
    return '“$name” is back to all-unseen. Backup: $backupPath';
  }

  @override
  String banksResetFailed(String error) {
    return 'Reset failed: $error; original data was left unchanged.';
  }

  @override
  String banksDeleteDialogTitle(String name) {
    return 'Delete bank “$name”?';
  }

  @override
  String get banksDeleteDialogBody =>
      'The bank and its questions are removed from the selectable list.\n\nSubmitted papers, answer events and statistics are kept; re-importing the same bank later restores it.';

  @override
  String banksDeleting(String name) {
    return 'Deleting “$name”…';
  }

  @override
  String banksDeleteDone(String name) {
    return 'Bank “$name” deleted.';
  }

  @override
  String banksDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String banksAddQuestionTitle(String name) {
    return 'Add a question to “$name” manually';
  }

  @override
  String get banksFieldType => 'Type';

  @override
  String get banksFieldExternalId => 'Question ID (optional)';

  @override
  String get banksFieldStem => 'Stem *';

  @override
  String banksFieldOption(String key, String suffix) {
    return 'Option $key$suffix';
  }

  @override
  String get banksFieldAnswerSingle => 'Answer * (e.g. A)';

  @override
  String get banksFieldAnswerMultiple => 'Answer * (e.g. AC)';

  @override
  String get banksFieldExplanation => 'Explanation';

  @override
  String get banksFieldKnowledgePoint => 'Knowledge point';

  @override
  String get banksFieldSource => 'Source';

  @override
  String get banksFieldYear => 'Year';

  @override
  String get banksFieldChapter => 'Chapter';

  @override
  String get banksFieldTags => 'Tags (comma-separated)';

  @override
  String get banksSaveQuestion => 'Save question';

  @override
  String get banksAddInvalid =>
      'Fill in the stem, at least two consecutive options A/B, and make sure the answer refers to a filled option';

  @override
  String banksQuestionAdded(String name) {
    return 'Question added to “$name”.';
  }

  @override
  String banksAddFailed(String error) {
    return 'Failed to add question: $error';
  }

  @override
  String get pendingDialogTitle => 'Pending sync items';

  @override
  String get pendingDialogEmpty => 'Nothing is waiting to sync right now';

  @override
  String get pendingDialogNote =>
      'Removing only takes items out of the sync queue; local answer records, papers and question banks are not deleted.';

  @override
  String pendingSelectAll(int count) {
    return 'Select all ($count)';
  }

  @override
  String pendingItemSubtitle(String entityId, String createdAt) {
    return 'ID: $entityId\nQueued at: $createdAt';
  }

  @override
  String pendingItemErrorLine(String error) {
    return '\nError: $error';
  }

  @override
  String pendingDeleteSelected(int count) {
    return 'Delete selected ($count)';
  }

  @override
  String get pendingDeleteConfirmTitle => 'Remove from sync queue';

  @override
  String pendingDeleteConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'the $count selected items',
      one: 'the selected item',
    );
    return 'Delete $_temp0? Local data is kept, but these items will not be uploaded again unless later actions create new sync tasks.';
  }

  @override
  String get pendingDeleteConfirmAction => 'Delete';

  @override
  String get syncEntityAnswerEvent => 'Answer record';

  @override
  String get syncEntityPaperAttempt => 'Paper record';

  @override
  String get syncEntityArchiveAck => 'Paper archive confirmation';

  @override
  String get syncEntityProgressControl => 'Question state';

  @override
  String get syncEntityQuestionBank => 'Question bank';

  @override
  String get syncEntityQuestion => 'Question';

  @override
  String get syncEntityMediaChunk => 'Question media';

  @override
  String get syncEntitySetting => 'Setting';

  @override
  String get syncEntityUnknown => 'Unknown item';

  @override
  String get syncOperationUpsert => 'Upsert';

  @override
  String get syncOperationInsert => 'Insert';

  @override
  String get syncOperationUnknown => 'Sync';

  @override
  String get syncTitle => 'Sync & backup';

  @override
  String get syncCloudTitle => 'Supabase cloud sync';

  @override
  String get syncCloudDesc =>
      'Sign in with a pre-created Supabase email account; there is no in-app sign-up. The password is never stored on disk; this device only keeps the public Publishable Key and your personal session token for automatic reconciliation at startup.';

  @override
  String get syncSessionSaved => 'A login session is saved on this device';

  @override
  String syncLoggedInAs(String email) {
    return 'Signed in: $email';
  }

  @override
  String get syncSessionAutoRenew =>
      'The session renews automatically at startup and when it expires; no need to enter the password again.';

  @override
  String get syncFieldUrl => 'Supabase project URL';

  @override
  String get syncHintUrl => 'https://your-project.supabase.co';

  @override
  String get syncFieldEmail => 'Account email';

  @override
  String get syncFieldPassword => 'Password (not saved)';

  @override
  String get syncLoginAndSync => 'Sign in & sync';

  @override
  String get syncRelogin => 'Switch account or sign in again';

  @override
  String syncNow(int pending) {
    return 'Sync now ($pending to upload)';
  }

  @override
  String get syncClearSession => 'Clear local session';

  @override
  String get syncErrorsTitle => 'Sync errors';

  @override
  String get syncConflictsTitle => 'Conflicts needing manual review';

  @override
  String get syncConflictDesc =>
      'Auto-sync did not overwrite local content; both versions are kept in the conflict records.';

  @override
  String get syncBackupTitle => 'Local backups';

  @override
  String get syncStorageAndroidNote =>
      'Android uses the system-protected app directory; custom storage locations are currently available on Windows only.';

  @override
  String get syncStorageDatabase => 'Database';

  @override
  String get syncStorageBackups => 'Backups directory';

  @override
  String get syncStorageExports => 'Exports directory';

  @override
  String get syncDefaultSuffix => ' (default)';

  @override
  String get syncBackupNow => 'Back up & verify now';

  @override
  String get syncResetAfterBackup => 'Back up, then reset current bank state';

  @override
  String get syncResetToDefault => 'Reset to default';

  @override
  String get syncMoveDbTitle => 'Move database';

  @override
  String get syncMoveDbBody =>
      'The app first creates and verifies a full database copy in the target directory, then switches to it immediately. The original database is kept so you can roll back.';

  @override
  String get syncMoveDbConfirm => 'Start move';

  @override
  String get syncMovingDb => 'Moving and verifying database…';

  @override
  String syncMoveDbDone(String path) {
    return 'Database switched to: $path';
  }

  @override
  String get syncBackupsDirUpdated => 'Backups directory updated.';

  @override
  String get syncExportsDirUpdated => 'Exports directory updated.';

  @override
  String syncStorageChangeFailed(String error) {
    return 'Failed to change the storage location: $error';
  }

  @override
  String get syncInProgress => 'Syncing…';

  @override
  String get syncLoginInProgress => 'Signing in and syncing…';

  @override
  String syncLoginFailed(String error) {
    return '$error; local data was not affected.';
  }

  @override
  String syncReportDone(
    String message,
    int uploaded,
    int downloaded,
    int failed,
  ) {
    return '$message; uploaded $uploaded, pulled $downloaded, $failed pending retry';
  }

  @override
  String get syncSessionCleared =>
      'Cleared the sync session saved on this device; offline data was not affected.';

  @override
  String syncBackupDone(String path) {
    return 'Backup finished and passed integrity_check: $path';
  }

  @override
  String syncBackupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get syncResetDialogTitle => 'Reset study state';

  @override
  String syncResetDialogBody(String phrase) {
    return 'A backup will be created and verified first, then the answer events and aggregated study state of the current bank are cleared. Type $phrase to continue.';
  }

  @override
  String get syncResetConfirmAction => 'Run';

  @override
  String syncResetDone(String path) {
    return 'Backup finished and state reset: $path';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String settingsFontScale(String value) {
    return 'Font scale $value';
  }

  @override
  String settingsLineHeight(String value) {
    return 'Line height $value';
  }

  @override
  String settingsContentWidth(String value) {
    return 'Max content width $value px';
  }

  @override
  String get settingsRandomWrongReturn =>
      'Re-list wrong answers from random practice as current wrong answers';

  @override
  String get settingsRandomWrongReturnDesc =>
      'On by default; does not clear the ever-wrong history.';

  @override
  String get settingsVersion => 'Version';

  @override
  String settingsDeviceId(String deviceId) {
    return 'Device ID: $deviceId';
  }

  @override
  String paperHeaderAnswered(int answered, int total) {
    return 'Answered $answered/$total';
  }

  @override
  String paperHeaderSuggested(String duration) {
    return 'Suggested $duration';
  }

  @override
  String get paperExportTooltipSubmitted => 'Export paper or PDF';

  @override
  String get paperExportTooltipDraft =>
      'Export blank paper, answer sheet, or PDF';

  @override
  String get paperReadAnswerSheet => 'Scan answer sheet';

  @override
  String get paperEditBankQuestion => 'Edit bank question';

  @override
  String get paperNavigatorExpand => 'Show question navigator';

  @override
  String get paperNavigatorCollapse => 'Hide question navigator';

  @override
  String get paperOvertimeHint =>
      'Past the suggested duration; you can keep answering';

  @override
  String get paperAutoSaved => 'Auto-saved to local SQLite  ';

  @override
  String paperMobileTitle(int current, int total) {
    return 'Question $current / $total';
  }

  @override
  String get paperNumberPanelTooltip => 'Question numbers';

  @override
  String paperMobileAnsweredStatus(int answered, int total) {
    return 'Answered $answered/$total in total · choices save automatically';
  }

  @override
  String get paperUncertainMarked => 'Marked unsure';

  @override
  String get paperUncertainMark => 'Mark unsure';

  @override
  String get paperUncertainMarkKey => 'Mark unsure (M)';

  @override
  String get paperSubmitting => 'Submitting…';

  @override
  String get paperSubmit => 'Submit';

  @override
  String get paperSubmittingDesktop => 'Submitting; processing local data…';

  @override
  String get paperSubmitConfirmTitle => 'Submit paper?';

  @override
  String paperSubmitConfirmInline(int unanswered) {
    return 'Submit? $unanswered question(s) are unanswered. Unanswered questions score 0 but stay marked as not seen.';
  }

  @override
  String paperSubmitConfirmBody(int unanswered) {
    return '$unanswered question(s) are unanswered. Unanswered questions score 0 but stay marked as not seen.';
  }

  @override
  String get paperConfirmSubmit => 'Submit paper';

  @override
  String get paperKeepReviewing => 'Keep reviewing';

  @override
  String get paperPrevQuestion => 'Previous';

  @override
  String get paperNextQuestion => 'Next';

  @override
  String get paperMoreActions => 'More actions';

  @override
  String get paperAbandonMenu => 'Discard paper…';

  @override
  String get paperAbandon => 'Discard paper';

  @override
  String get paperAbandonBody =>
      'Choose how to handle the current local draft. Discarding does not create wrong-answer records.';

  @override
  String get paperAbandonKeep => 'Keep draft and exit';

  @override
  String get paperAbandonDiscard => 'Delete answer draft';

  @override
  String paperMobileResultSummary(
    String summary,
    int unanswered,
    String duration,
  ) {
    return '$summary · Unanswered $unanswered · $duration';
  }

  @override
  String paperResultSummary(String summary, int unanswered, String duration) {
    return '$summary　Unanswered $unanswered　Time $duration';
  }

  @override
  String get paperExportShort => 'Export';

  @override
  String get paperExportPackButton => 'Export paper pack';

  @override
  String paperNumberPanelDraftTitle(int answered, int total) {
    return 'Question numbers · Answered $answered/$total';
  }

  @override
  String paperNumberPanelSubmittedTitle(
    int correctCount,
    int wrongCount,
    int unansweredCount,
  ) {
    return 'Question numbers · Correct $correctCount · Wrong $wrongCount · Unanswered $unansweredCount';
  }

  @override
  String get paperNumberNavigatorTitle => 'Question navigator';

  @override
  String get paperUnanswered => 'Unanswered';

  @override
  String get paperAnswered => 'Answered';

  @override
  String get paperUncertainLabel => 'Unsure';

  @override
  String get paperCorrect => 'Correct';

  @override
  String get paperWrong => 'Wrong';

  @override
  String get paperStatusAnsweredUncertain => 'Answered, marked unsure';

  @override
  String get paperStatusUnansweredUncertain => 'Unanswered, marked unsure';

  @override
  String paperStatusLabel(int number, String status) {
    return 'Question $number, $status';
  }

  @override
  String paperStatusCurrentLabel(int number, String status) {
    return 'Question $number, $status, current question';
  }

  @override
  String get paperBadgeAnswered => 'Answered';

  @override
  String get paperBadgeUnanswered => 'Unanswered';

  @override
  String get paperEditQuestionMissing =>
      'This question was not found in the question bank and cannot be edited.';

  @override
  String paperEditBankQuestionTitle(String id) {
    return 'Edit bank question $id';
  }

  @override
  String get paperEditQuestionUpdated =>
      'Question bank updated; this paper now shows the latest question content.';

  @override
  String paperScoreSummary(String score, String maxScore) {
    return 'Score $score/$maxScore';
  }

  @override
  String paperScorePercentage(String percentage) {
    return ' · $percentage/100%';
  }

  @override
  String paperSubmitFailed(String error) {
    return 'Submit failed: $error; the local draft was kept.';
  }

  @override
  String get paperExportTitle => 'Export paper';

  @override
  String get paperExportHintSubmitted =>
      'Pick the content to export first, then the output format; question media, print CSS, and the manifest are included in the pack automatically.';

  @override
  String get paperExportHintDraft =>
      'Before submitting, only the blank paper and the paper answer sheet can be exported; answers and the answer review become available after submitting.';

  @override
  String get paperExportSectionContent => 'Content to export';

  @override
  String get paperExportBlankPaper => 'Blank paper';

  @override
  String get paperExportBlankPaperDesc =>
      'Full stems, options, and question images, without answers';

  @override
  String get paperExportAnswerSheet => 'Paper answer sheet';

  @override
  String get paperExportAnswerSheetDesc =>
      'A4 bubble area with QR code, corner marks, and ABCDE header';

  @override
  String get paperExportAnswers => 'Answers and explanations';

  @override
  String get paperExportAnswersDesc =>
      'Correct answers, explanations, knowledge points, and sources';

  @override
  String get paperExportReview => 'Answer review';

  @override
  String get paperExportReviewDesc =>
      'Your choices, verdicts, scores, and time';

  @override
  String get paperExportAfterSubmit => 'Available after submitting';

  @override
  String get paperExportSectionOutput => 'Output format';

  @override
  String get paperExportModePack => 'Paper pack';

  @override
  String get paperExportModePackAndPdf => 'Pack + PDF';

  @override
  String get paperExportModePdfOnly => 'PDF only';

  @override
  String get paperExportPdfWindowsOnly =>
      'PDF printing is currently Windows-only';

  @override
  String get paperExportModePackDesc =>
      'Generates a Markdown paper pack: the selected files, question media, print CSS, and the manifest are written together.';

  @override
  String get paperExportModePackAndPdfDesc =>
      'Besides the pack, merges the selected content into one A4 PDF saved in the same folder.';

  @override
  String get paperExportModePdfOnlyDesc =>
      'Keeps only one PDF (blank paper + paper answer sheet); the Markdown, media, and manifest are deleted once it is generated.';

  @override
  String get paperExportStart => 'Export';

  @override
  String get paperExportAndPrint => 'Export and print PDF';

  @override
  String get paperExportPdfOnlyButton => 'Export PDF only';

  @override
  String paperExportedTo(String path) {
    return 'Exported to: $path';
  }

  @override
  String paperExportedPdf(String path) {
    return 'PDF generated: $path';
  }

  @override
  String paperExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String paperExportPdfFailedWithPack(String path, String error) {
    return 'PDF generation failed; the Markdown paper pack was saved to: $path\n\n$error';
  }

  @override
  String get paperExportPdfFailedTitle => 'PDF generation failed';

  @override
  String get paperPdfErrorFileName => 'PDF generation error.txt';

  @override
  String get practiceModeUnseen => 'Unseen first';

  @override
  String get practiceModeWrongReview => 'Wrong answer review';

  @override
  String get practiceModeRandom => 'Random practice';

  @override
  String get practiceModeFavorite => 'Favorites';

  @override
  String get practiceModeUncertain => 'Marked unsure';

  @override
  String get practicePrevQuestion => 'Previous';

  @override
  String get practiceNextQuestion => 'Next';

  @override
  String get practiceSubmitCurrentKey => 'Submit question (Enter)';

  @override
  String get practiceSubmittedCurrent => 'Submitted';

  @override
  String get practiceSubmitAndReveal => 'Submit and reveal answer';

  @override
  String get practiceFavoriteMarked => 'Favorited';

  @override
  String get practiceFavorite => 'Favorite';

  @override
  String get practiceMarkedUncertain => 'Marked unsure';

  @override
  String get practiceMarkUncertain => 'Mark unsure';

  @override
  String get practiceAddNote => 'Add note';

  @override
  String get practiceEditNote => 'Edit note';

  @override
  String get practiceExcludeQuestion => 'Exclude question';

  @override
  String get practiceExcludeTitle => 'Exclude this question?';

  @override
  String get practiceExcludeBody =>
      'Once excluded, this question will no longer enter the automatic practice queue; existing answer records are kept.';

  @override
  String get practiceExcludeConfirm => 'Exclude';

  @override
  String get practiceNoteTitle => 'Personal note (Markdown text)';

  @override
  String practiceProgressPosition(int current, int total) {
    return 'Question $current / $total';
  }

  @override
  String practiceProgressPercent(int percent) {
    return 'Progress $percent%';
  }

  @override
  String questionEditDefaultTitle(String id) {
    return 'Edit $id';
  }

  @override
  String get questionEditStemLabel => 'Stem *';

  @override
  String questionEditOptionLabel(String option) {
    return 'Option $option';
  }

  @override
  String questionEditAnswerLabel(String example) {
    return 'Answer * (e.g. $example)';
  }

  @override
  String get questionEditExplanationLabel => 'Explanation';

  @override
  String get questionEditKnowledgePointLabel => 'Knowledge point';

  @override
  String get questionEditSave => 'Save changes';

  @override
  String get questionEditValidationError =>
      'Enter the stem, at least two consecutive options starting at A and B, and make sure the answer refers to filled options.';

  @override
  String get questionUncertainTooltipRemove => 'Marked unsure; tap to remove';

  @override
  String get questionMarkUncertain => 'Mark unsure';

  @override
  String get questionMarkedUncertain => 'Marked unsure';

  @override
  String questionMediaMissing(String media) {
    return 'Missing media: $media';
  }

  @override
  String get questionImageSemantics => 'Question image, pinch to zoom';

  @override
  String get questionSelectAnswerRequired =>
      'No answer selected yet; please answer first';

  @override
  String get questionCorrectAnswerLabel => 'Correct answer';

  @override
  String get questionYourChoiceLabel => 'Your choice';

  @override
  String get questionResultUnanswered => 'Not answered';

  @override
  String get questionResultCorrect => 'Correct';

  @override
  String get questionResultWrong => 'Incorrect';

  @override
  String get questionNotAnswered => 'Not answered';

  @override
  String get questionAnswerSeparator => ', ';

  @override
  String questionScoreBadge(double score, double maxScore) {
    return '$score/$maxScore pts';
  }

  @override
  String get questionYourAnswerLabel => 'Your answer';

  @override
  String get questionExplanationTitle => 'Explanation';

  @override
  String get questionNoExplanation => 'No explanation';

  @override
  String get questionKnowledgePointEmpty => 'No knowledge point';

  @override
  String get questionSourceEmpty => 'No source';

  @override
  String get shellNavHome => 'Home';

  @override
  String get shellNavPractice => 'Practice';

  @override
  String get shellNavPaper => 'Papers';

  @override
  String get shellNavHistory => 'Past Papers';

  @override
  String get shellNavCollection => 'Wrong & Starred';

  @override
  String get shellNavBank => 'Question Banks';

  @override
  String get shellNavStats => 'Stats';

  @override
  String get shellNavSync => 'Sync & Backup';

  @override
  String get shellNavSettings => 'Settings';

  @override
  String get shellTabPractice => 'Practice';

  @override
  String get shellTabPaper => 'Papers';

  @override
  String get shellTabHistory => 'History';

  @override
  String get shellTabMore => 'More';

  @override
  String get shellSheetCollection => 'Wrong & Starred';

  @override
  String get shellSheetBank => 'Question Banks';

  @override
  String get errImportBlockedUnsupportedFileType =>
      'Only .zip, .tsv or .csv question bank files are supported';

  @override
  String errImportBlockedZipUnparsable(String error) {
    return 'ZIP file cannot be parsed: $error';
  }

  @override
  String get errImportBlockedMissingManifest => 'manifest.json is missing';

  @override
  String get errImportBlockedMissingQuestions => 'questions.jsonl is missing';

  @override
  String errImportBlockedManifestUnparsable(String error) {
    return 'manifest.json cannot be parsed: $error';
  }

  @override
  String errImportBlockedUnsupportedSchemaVersion(String version) {
    return 'Unsupported schema_version=$version';
  }

  @override
  String get errImportBlockedInvalidBankId =>
      'bank_id contains invalid directory characters';

  @override
  String get errImportBlockedInvalidBankMetadata =>
      'Question bank ID, name or content version is invalid';

  @override
  String get errImportBlockedQuestionsHashMismatch =>
      'The SHA-256 of questions.jsonl does not match the manifest';

  @override
  String errImportBlockedEmptyQuestionId(int line) {
    return 'Line $line: question_id is empty';
  }

  @override
  String errImportBlockedDupQuestionId(String id) {
    return 'Duplicate question_id: $id';
  }

  @override
  String errImportBlockedInvalidQuestionType(String id, String type) {
    return 'Invalid question type for $id: $type';
  }

  @override
  String errImportBlockedEmptyStem(String id) {
    return 'The stem of $id is empty';
  }

  @override
  String errImportBlockedTooFewOptions(String id) {
    return '$id has fewer than two valid options';
  }

  @override
  String errImportBlockedAnswerNotInOptions(String id) {
    return 'The answer of $id is not among the valid options';
  }

  @override
  String errImportBlockedSingleAnswerCount(String id) {
    return '$id is a single-choice question but the answer count is not 1';
  }

  @override
  String errImportBlockedMissingMedia(String id, String path) {
    return 'Media declared by $id does not exist: $path';
  }

  @override
  String errImportBlockedQuestionLineUnparsable(int line, String error) {
    return 'questions.jsonl line $line cannot be parsed: $error';
  }

  @override
  String errImportBlockedQuestionCountMismatch(String declared, int actual) {
    return 'Manifest question count $declared does not match the actual $actual';
  }

  @override
  String errImportBlockedMediaHashMismatch(String path) {
    return 'Media hash mismatch: $path';
  }

  @override
  String errImportBlockedInvalidUtf8(String error) {
    return 'The file is not valid UTF-8: $error';
  }

  @override
  String errImportBlockedDelimitedUnparsable(String error) {
    return 'The delimited file cannot be parsed: $error';
  }

  @override
  String get errImportBlockedEmptyFile =>
      'The file has no header row and no questions';

  @override
  String errImportBlockedInvalidContentVersion(String version) {
    return 'Invalid question bank content version: $version';
  }

  @override
  String errImportBlockedDupHeader(String header) {
    return 'Duplicate column header: $header';
  }

  @override
  String errImportBlockedMissingColumn(String column) {
    return 'Missing required column: $column';
  }

  @override
  String errImportBlockedRowColumnMismatch(int line, int actual, int expected) {
    return 'Line $line has $actual columns but the header has $expected';
  }

  @override
  String errImportBlockedEmptyExternalId(int line) {
    return 'Line $line: the question number is empty';
  }

  @override
  String errImportBlockedDupExplicitId(String id) {
    return 'Duplicate question ID: $id';
  }

  @override
  String errImportBlockedDupExternalId(String externalId) {
    return 'Duplicate question number: $externalId';
  }

  @override
  String errImportBlockedInvalidQuestionVersion(String id) {
    return 'Invalid question version for $id';
  }

  @override
  String get errImportBlockedNoValidQuestions =>
      'The file contains no valid question rows';

  @override
  String errImportWarningDupExternalId(String externalId) {
    return 'Duplicate external_id: $externalId';
  }

  @override
  String errImportWarningDupStem(String externalId) {
    return 'Duplicate stem: $externalId';
  }

  @override
  String errImportWarningEmptyExplanation(String id) {
    return 'The explanation of $id is empty';
  }

  @override
  String errImportWarningIncompleteMetadata(String id) {
    return 'The year, chapter or source of $id is incomplete';
  }

  @override
  String errImportWarningBankNameFallback(String name) {
    return 'No question bank name provided; the file name “$name” is used';
  }

  @override
  String get errImportWarningGeneratedBankId =>
      'No bank_id provided; a stable ID was generated from the question bank name and subject. Do not change these two when updating later';

  @override
  String get errOmrPlatformUnsupported =>
      'Answer sheet grading is only supported on Windows';

  @override
  String errOmrImageFormatUnsupported(String path) {
    return 'Only PNG/JPG/JPEG is supported: $path';
  }

  @override
  String errOmrExecutableMissing(String path) {
    return 'The grading component shipped with the app is missing: $path';
  }

  @override
  String get errOmrRecognizeTimeout => 'Answer sheet recognition timed out';

  @override
  String errOmrBridgeExitCode(int exitCode, String stderr) {
    return 'Grading component exited with code $exitCode: $stderr';
  }

  @override
  String errOmrBridgeNoResult(String stdout) {
    return 'The grading component produced no structured result: $stdout';
  }

  @override
  String get errOmrResultVersionInvalid => 'Invalid grading result version';

  @override
  String get errOmrResultSourceSizeInvalid =>
      'Invalid source image size in the grading result';

  @override
  String errOmrResultQuadInvalid(String field) {
    return 'Invalid grading result for $field';
  }

  @override
  String errOmrResultQuadOutOfRange(String field) {
    return 'Grading result for $field is out of range';
  }

  @override
  String get errOmrResultQuestionCountMismatch =>
      'Question count in the grading result does not match';

  @override
  String get errOmrResultQuestionFormatInvalid =>
      'Invalid question format in the grading result';

  @override
  String errOmrResultLabelInvalid(String label) {
    return 'Invalid label in the grading result: $label';
  }

  @override
  String get errOmrResultOptionsFormatInvalid =>
      'Invalid option format in the grading result';

  @override
  String get errOmrResultOptionsOutOfRange =>
      'Options in the grading result are out of range';

  @override
  String get errOmrResultConfidenceInvalid =>
      'Invalid confidence value in the grading result';

  @override
  String get errOmrResultBubblesInvalid =>
      'Invalid bubble geometry in the grading result';

  @override
  String get errOmrResultLabelsIncomplete =>
      'Labels in the grading result are incomplete';

  @override
  String errSyncDone(int uploaded, int downloaded) {
    return 'Sync complete: $uploaded items uploaded, $downloaded items pulled';
  }

  @override
  String errSyncPartial(
    int uploaded,
    int downloaded,
    int failed,
    int deferred,
  ) {
    return '$uploaded items uploaded, $downloaded items pulled; $failed items not confirmed, $deferred items waiting for question bank dependencies';
  }

  @override
  String get errSyncTimeout =>
      'Sync timed out; local data and the sync queue are both preserved';

  @override
  String errSyncFailed(String error) {
    return 'Sync failed, local data is safe: $error';
  }

  @override
  String get errSyncNotLoggedIn =>
      'Not signed in to a personal Supabase account';

  @override
  String errSyncSessionRefreshFailed(String error) {
    return 'Session refresh failed, local data is safe: $error';
  }

  @override
  String get errSyncMissingCloudConfig =>
      'Fill in the Supabase project URL and Publishable Key, then sign in';

  @override
  String get errSyncMissingAccountConfig =>
      'Fill in the Supabase project URL, Publishable Key, email and password';

  @override
  String get errAnswerNotSelected => 'Select an answer first';

  @override
  String get errPracticeEmptyScope =>
      'No questions available in the current filter scope';

  @override
  String get errBankNotSelected => 'Select a question bank first';

  @override
  String get errStorageTargetDirNotEmpty =>
      'The target directory already contains personal_exam.sqlite; choose an empty directory to avoid overwriting the original database';

  @override
  String errStorageIntegrityCheckFailed(String integrity) {
    return 'Integrity check of the new database failed: $integrity';
  }

  @override
  String get exportPaperFileName => 'Paper';

  @override
  String get exportAnswersFileName => 'Answers & Explanations';

  @override
  String get exportReviewFileName => 'Answer Review';

  @override
  String get exportAnswerSheetFileName => 'Answer Sheet';

  @override
  String get exportResourcesFolderName => 'Resources';

  @override
  String get exportAnswersYamlSuffix => ' (Answers & Explanations)';

  @override
  String get exportAnswersHeadingSuffix => ' · Answers & Explanations';

  @override
  String get exportReviewYamlSuffix => ' (Answer Review)';

  @override
  String get exportReviewHeadingSuffix => ' · Answer Review';

  @override
  String exportPaperStatsLine(String count, String minutes) {
    return 'Questions: $count · Suggested time: $minutes min';
  }

  @override
  String get exportMultipleChoiceTag => '[Multiple choice]';

  @override
  String get exportSingleChoiceTag => '[Single choice]';

  @override
  String exportMissingMediaWarning(String path) {
    return '> [!warning] Missing question image: $path';
  }

  @override
  String exportCorrectAnswersBoldLine(String answers) {
    return '**Correct answer: $answers**';
  }

  @override
  String exportExplanationLine(String explanation) {
    return 'Explanation: $explanation';
  }

  @override
  String exportKnowledgePointSourceLine(String knowledgePoint, String source) {
    return 'Knowledge point: $knowledgePoint · Source: $source';
  }

  @override
  String exportReviewScoreLine(String score, String max) {
    return 'Score: $score / $max';
  }

  @override
  String exportTotalDurationLine(String duration) {
    return 'Total time: $duration';
  }

  @override
  String exportOvertimeLine(String duration) {
    return 'Overtime: $duration';
  }

  @override
  String exportUnansweredCountLine(String count) {
    return 'Unanswered: $count questions';
  }

  @override
  String get exportUnansweredStatus => 'Unanswered';

  @override
  String get exportFullyCorrectStatus => 'Fully correct';

  @override
  String get exportWrongStatus => 'Wrong';

  @override
  String exportVerdictLine(String status) {
    return 'Verdict: $status';
  }

  @override
  String exportUserSelectionLine(String answers) {
    return 'Your selection: $answers';
  }

  @override
  String exportCorrectAnswerLine(String answers) {
    return 'Correct answer: $answers';
  }

  @override
  String exportQuestionDurationLine(String duration) {
    return 'Estimated time on this question: $duration';
  }

  @override
  String exportFavoriteUncertainLine(String favorite, String uncertain) {
    return 'Favorite: $favorite; Uncertain: $uncertain';
  }

  @override
  String get exportYesLabel => 'Yes';

  @override
  String get exportNoLabel => 'No';

  @override
  String exportPersonalNoteLine(String note) {
    return 'Personal note: $note';
  }

  @override
  String get exportEmptyNoteValue => 'None';

  @override
  String exportKnowledgePointSourceReviewLine(
    String knowledgePoint,
    String source,
  ) {
    return 'Knowledge point: $knowledgePoint; Source: $source';
  }

  @override
  String get exportAnswerSeparator => ', ';

  @override
  String get exportAnswerSheetYamlSuffix => ' (Answer Sheet)';

  @override
  String get exportAnswerSheetHeadingSuffix => ' · Answer Sheet';

  @override
  String exportAnswerSheetStatsLine(
    String count,
    String single,
    String multiple,
  ) {
    return 'Personal practice · $count questions in total · $single single-choice · $multiple multiple-choice';
  }

  @override
  String get exportAnswerSheetQrAlt => 'Answer sheet QR code';

  @override
  String get exportFillNoteHtml =>
      '<strong>How to fill:</strong> Fill in the chosen circles completely; you may fill several options for multiple-choice questions. Erase thoroughly when changing an answer, or reprint the sheet if it cannot be erased.';

  @override
  String get exportAnswerSectionTitle => 'Multiple-choice answer area';

  @override
  String get exportAnswerSectionHint => 'Fill in the bubbles in question order';

  @override
  String get exportQuestionNumberHeader => 'No.';

  @override
  String get exportWrongQuestionsTitle => 'Current wrong answers';

  @override
  String exportRecentSelectionLine(String answers) {
    return 'Latest selection: $answers';
  }

  @override
  String exportKnowledgePointLine(String knowledgePoint) {
    return 'Knowledge point: $knowledgePoint';
  }

  @override
  String exportSourceLine(String source) {
    return 'Source: $source';
  }

  @override
  String exportAttemptStatsLine(String seen, String wrong) {
    return 'Answered $seen times; wrong $wrong times';
  }

  @override
  String get settingsDevVersion => 'dev build';

  @override
  String get questionTypeQa => 'Q&A question';

  @override
  String get questionTypeQaShort => 'Q&A';

  @override
  String get questionEditQaAnswerLabel => 'Reference answer (optional)';

  @override
  String get questionQaAnswerLabel => 'Your answer';

  @override
  String get questionQaReferenceLabel => 'Reference answer';

  @override
  String get questionQaReferenceEmpty => 'No reference answer provided';

  @override
  String get paperExportLayoutTitle => 'Paper layout';

  @override
  String get paperExportLayoutA4 => 'A4';

  @override
  String get paperExportLayoutA3 => 'A3';

  @override
  String get paperExportLayoutHint =>
      'The answer sheet is always A4. With A3, paper documents and the answer sheet are exported as separate PDFs.';

  @override
  String get paperTypeCountsTitle => 'Questions per type (exam mode)';

  @override
  String get paperTypeCountsSingle => 'Single-choice';

  @override
  String get paperTypeCountsMultiple => 'Multiple-choice';

  @override
  String get paperTypeCountsQa => 'Q&A';

  @override
  String get paperTypeCountsHint =>
      'Types with insufficient stock are filled with what is available; Q&A questions are not scored.';

  @override
  String get settingsScoringTitle => 'Paper scoring rules';

  @override
  String get settingsScoringHint =>
      'Applies to new papers only; submitted papers keep their original rules.';

  @override
  String settingsScoringSingleScore(String score) {
    return 'Single-choice score: $score';
  }

  @override
  String settingsScoringMultipleScore(String score) {
    return 'Multiple-choice score: $score';
  }

  @override
  String get settingsScoringPartialCredit =>
      'Partial credit for incomplete multiple choice';

  @override
  String settingsScoringPerOption(String score) {
    return 'Score per correct option: $score';
  }

  @override
  String get settingsScoringWrongZero => 'Any wrong option zeroes the question';

  @override
  String get settingsScoringQaNote =>
      'Q&A questions are not scored and excluded from totals.';

  @override
  String get omrQuestionTypeQa => 'Q&A';

  @override
  String get omrQaAnswerHint =>
      'Q&A cannot be machine-read; type the answer here (optional)';

  @override
  String get omrQaSheetNote =>
      'Bubbles cover choice questions only (row numbers are paper numbers); answer Q&A questions below the bubble grid.';

  @override
  String errImportBlockedQaWithOptions(String id) {
    return '$id is a Q&A question but has options';
  }

  @override
  String get errExportSheetNeedsChoice =>
      'The answer sheet needs at least one single- or multiple-choice question';

  @override
  String get exportQaTag => '[Q&A]';

  @override
  String exportQaReferenceAnswerLine(String answer) {
    return 'Reference answer: $answer';
  }

  @override
  String get exportQaEmptyReferenceAnswer => '(no reference answer)';

  @override
  String exportQaUserAnswerLine(String answer) {
    return 'Your answer: $answer';
  }

  @override
  String get exportQaUnansweredText => 'not answered';

  @override
  String get exportAnswerSheetQaSectionTitle => 'Q&A answer area';

  @override
  String exportAnswerSheetQaItemLabel(String number) {
    return 'No. $number';
  }

  @override
  String get exportAnswerSheetQaOverflowNote =>
      'Not enough space for the remaining Q&A questions; answer them on the paper.';

  @override
  String exportAnswerSheetQaStatsSuffix(String qa) {
    return ' · Q&A $qa';
  }

  @override
  String get omrGradingDone => 'Grading imported';

  @override
  String get omrGradingDoneBody =>
      'Answer-sheet results are written to the paper. Review each question below; Q&A answers were entered manually.';

  @override
  String get omrBackToPaper => 'Back to paper';

  @override
  String get settingsRenderMarkupTitle => 'Render question markup';

  @override
  String get settingsRenderMarkupDesc =>
      'Convert markup such as <p> and <br> in stems, options and explanations into line breaks. When off, the UI strips tags and exports keep them as-is.';
}
