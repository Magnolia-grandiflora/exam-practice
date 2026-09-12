import '../l10n/generated/app_localizations.dart';

/// 把携带稳定码的对象映射为本地化文本。
///
/// 通过 duck-typing 读取 `code` / `params` 字段：服务层的
/// `Coded*Exception`（见 `lib/domain/coded_exceptions.dart`）、
/// `ImportIssue` 与 `SyncReport` 都走同一映射；无码或未知码回退
/// `error.toString()`（中文技术诊断）。
String localizedErrorText(AppLocalizations l10n, Object error) {
  String? code;
  List<Object> params = const [];
  try {
    final dynamic dynamicError = error;
    final Object? rawCode = dynamicError.code;
    if (rawCode is String) code = rawCode;
    final Object? rawParams = dynamicError.params;
    if (rawParams is List) params = List<Object>.from(rawParams);
  } on NoSuchMethodError {
    // 普通异常没有 code/params 字段，走 toString() 回退。
  }
  if (code == null) return error.toString();
  switch (code) {
    // ── 题库导入（blocking） ──
    case 'import.blocked.unsupportedFileType':
      return l10n.errImportBlockedUnsupportedFileType;
    case 'import.blocked.zipUnparsable':
      return l10n.errImportBlockedZipUnparsable(_s(params, 0));
    case 'import.blocked.missingManifest':
      return l10n.errImportBlockedMissingManifest;
    case 'import.blocked.missingQuestions':
      return l10n.errImportBlockedMissingQuestions;
    case 'import.blocked.manifestUnparsable':
      return l10n.errImportBlockedManifestUnparsable(_s(params, 0));
    case 'import.blocked.unsupportedSchemaVersion':
      return l10n.errImportBlockedUnsupportedSchemaVersion(_s(params, 0));
    case 'import.blocked.invalidBankId':
      return l10n.errImportBlockedInvalidBankId;
    case 'import.blocked.invalidBankMetadata':
      return l10n.errImportBlockedInvalidBankMetadata;
    case 'import.blocked.questionsHashMismatch':
      return l10n.errImportBlockedQuestionsHashMismatch;
    case 'import.blocked.emptyQuestionId':
      return l10n.errImportBlockedEmptyQuestionId(_i(params, 0));
    case 'import.blocked.dupQuestionId':
      return l10n.errImportBlockedDupQuestionId(_s(params, 0));
    case 'import.blocked.invalidQuestionType':
      return l10n.errImportBlockedInvalidQuestionType(_s(params, 0), _s(params, 1));
    case 'import.blocked.emptyStem':
      return l10n.errImportBlockedEmptyStem(_s(params, 0));
    case 'import.blocked.tooFewOptions':
      return l10n.errImportBlockedTooFewOptions(_s(params, 0));
    case 'import.blocked.answerNotInOptions':
      return l10n.errImportBlockedAnswerNotInOptions(_s(params, 0));
    case 'import.blocked.singleAnswerCount':
      return l10n.errImportBlockedSingleAnswerCount(_s(params, 0));
    case 'import.blocked.missingMedia':
      return l10n.errImportBlockedMissingMedia(_s(params, 0), _s(params, 1));
    case 'import.blocked.questionLineUnparsable':
      return l10n.errImportBlockedQuestionLineUnparsable(_i(params, 0), _s(params, 1));
    case 'import.blocked.questionCountMismatch':
      return l10n.errImportBlockedQuestionCountMismatch(_s(params, 0), _i(params, 1));
    case 'import.blocked.mediaHashMismatch':
      return l10n.errImportBlockedMediaHashMismatch(_s(params, 0));
    case 'import.blocked.invalidUtf8':
      return l10n.errImportBlockedInvalidUtf8(_s(params, 0));
    case 'import.blocked.delimitedUnparsable':
      return l10n.errImportBlockedDelimitedUnparsable(_s(params, 0));
    case 'import.blocked.emptyFile':
      return l10n.errImportBlockedEmptyFile;
    case 'import.blocked.invalidContentVersion':
      return l10n.errImportBlockedInvalidContentVersion(_s(params, 0));
    case 'import.blocked.dupHeader':
      return l10n.errImportBlockedDupHeader(_s(params, 0));
    case 'import.blocked.missingColumn':
      return l10n.errImportBlockedMissingColumn(_s(params, 0));
    case 'import.blocked.rowColumnMismatch':
      return l10n.errImportBlockedRowColumnMismatch(
        _i(params, 0),
        _i(params, 1),
        _i(params, 2),
      );
    case 'import.blocked.emptyExternalId':
      return l10n.errImportBlockedEmptyExternalId(_i(params, 0));
    case 'import.blocked.dupExplicitId':
      return l10n.errImportBlockedDupExplicitId(_s(params, 0));
    case 'import.blocked.dupExternalId':
      return l10n.errImportBlockedDupExternalId(_s(params, 0));
    case 'import.blocked.invalidQuestionVersion':
      return l10n.errImportBlockedInvalidQuestionVersion(_s(params, 0));
    case 'import.blocked.noValidQuestions':
      return l10n.errImportBlockedNoValidQuestions;
    // ── 题库导入（warning） ──
    case 'import.warning.dupExternalId':
      return l10n.errImportWarningDupExternalId(_s(params, 0));
    case 'import.warning.dupStem':
      return l10n.errImportWarningDupStem(_s(params, 0));
    case 'import.warning.emptyExplanation':
      return l10n.errImportWarningEmptyExplanation(_s(params, 0));
    case 'import.warning.incompleteMetadata':
      return l10n.errImportWarningIncompleteMetadata(_s(params, 0));
    case 'import.warning.bankNameFallback':
      return l10n.errImportWarningBankNameFallback(_s(params, 0));
    case 'import.warning.generatedBankId':
      return l10n.errImportWarningGeneratedBankId;
    // ── Windows 答题卡阅卷 ──
    case 'omr.platform.unsupported':
      return l10n.errOmrPlatformUnsupported;
    case 'omr.image.format.unsupported':
      return l10n.errOmrImageFormatUnsupported(_s(params, 0));
    case 'omr.executable.missing':
      return l10n.errOmrExecutableMissing(_s(params, 0));
    case 'omr.recognize.timeout':
      return l10n.errOmrRecognizeTimeout;
    case 'omr.bridge.exitCode':
      return l10n.errOmrBridgeExitCode(_i(params, 0), _s(params, 1));
    case 'omr.bridge.noResult':
      return l10n.errOmrBridgeNoResult(_s(params, 0));
    case 'omr.result.versionInvalid':
      return l10n.errOmrResultVersionInvalid;
    case 'omr.result.sourceSizeInvalid':
      return l10n.errOmrResultSourceSizeInvalid;
    case 'omr.result.quadInvalid':
      return l10n.errOmrResultQuadInvalid(_s(params, 0));
    case 'omr.result.quadOutOfRange':
      return l10n.errOmrResultQuadOutOfRange(_s(params, 0));
    case 'omr.result.questionCountMismatch':
      return l10n.errOmrResultQuestionCountMismatch;
    case 'omr.result.questionFormatInvalid':
      return l10n.errOmrResultQuestionFormatInvalid;
    case 'omr.result.labelInvalid':
      return l10n.errOmrResultLabelInvalid(_s(params, 0));
    case 'omr.result.optionsFormatInvalid':
      return l10n.errOmrResultOptionsFormatInvalid;
    case 'omr.result.optionsOutOfRange':
      return l10n.errOmrResultOptionsOutOfRange;
    case 'omr.result.confidenceInvalid':
      return l10n.errOmrResultConfidenceInvalid;
    case 'omr.result.bubblesInvalid':
      return l10n.errOmrResultBubblesInvalid;
    case 'omr.result.labelsIncomplete':
      return l10n.errOmrResultLabelsIncomplete;
    // ── 云同步 ──
    case 'sync.done':
      return l10n.errSyncDone(_i(params, 0), _i(params, 1));
    case 'sync.partial':
      return l10n.errSyncPartial(
        _i(params, 0),
        _i(params, 1),
        _i(params, 2),
        _i(params, 3),
      );
    case 'sync.timeout':
      return l10n.errSyncTimeout;
    case 'sync.failed':
      return l10n.errSyncFailed(_s(params, 0));
    case 'sync.notLoggedIn':
      return l10n.errSyncNotLoggedIn;
    case 'sync.sessionRefreshFailed':
      return l10n.errSyncSessionRefreshFailed(_s(params, 0));
    case 'sync.missingCloudConfig':
      return l10n.errSyncMissingCloudConfig;
    case 'sync.missingAccountConfig':
      return l10n.errSyncMissingAccountConfig;
    // ── 用户操作前置校验 ──
    case 'answer.notSelected':
      return l10n.errAnswerNotSelected;
    case 'practice.emptyScope':
      return l10n.errPracticeEmptyScope;
    case 'bank.notSelected':
      return l10n.errBankNotSelected;
    case 'storage.targetDirNotEmpty':
      return l10n.errStorageTargetDirNotEmpty;
    case 'storage.integrityCheckFailed':
      return l10n.errStorageIntegrityCheckFailed(_s(params, 0));
    // ── 问答题与导出 ──
    case 'import.blocked.qaWithOptions':
      return l10n.errImportBlockedQaWithOptions(_s(params, 0));
    case 'export.sheetNeedsChoice':
      return l10n.errExportSheetNeedsChoice;
  }
  return error.toString();
}

String _s(List<Object> params, int index) =>
    index < params.length ? '${params[index]}' : '';

int _i(List<Object> params, int index) =>
    index < params.length ? (params[index] as num).toInt() : 0;
