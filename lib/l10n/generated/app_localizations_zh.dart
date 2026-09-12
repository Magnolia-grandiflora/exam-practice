// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '题序';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonClose => '关闭';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '重试';

  @override
  String get commonBack => '返回';

  @override
  String get commonDone => '完成';

  @override
  String get commonContinue => '继续';

  @override
  String get commonYes => '是';

  @override
  String get commonNo => '否';

  @override
  String get commonLoading => '加载中…';

  @override
  String get commonEmpty => '暂无数据';

  @override
  String get commonCopy => '复制';

  @override
  String get commonCopied => '已复制';

  @override
  String get commonUnknown => '未知';

  @override
  String get commonAll => '全部';

  @override
  String get commonEnabled => '启用';

  @override
  String get commonDisabled => '停用';

  @override
  String get commonPending => '待处理';

  @override
  String get commonError => '出错了';

  @override
  String get commonDetails => '详情';

  @override
  String get exitQuitTitle => '退出题序';

  @override
  String exitPendingTitle(int count) {
    return '有 $count 项数据等待同步';
  }

  @override
  String get exitPendingBody => '全部作答和草稿已保存到本地 SQLite。可以先同步，也可以保留待同步队列直接退出。';

  @override
  String exitSavedBody(String lastSync) {
    return '本地数据已保存。最近同步时间：$lastSync';
  }

  @override
  String get exitNeverSynced => '尚未同步';

  @override
  String get exitStayWithoutSync => '暂不同步，直接退出';

  @override
  String get exitQuit => '退出';

  @override
  String get exitSyncAndQuit => '同步并退出';

  @override
  String get exitCancelQuit => '取消退出';

  @override
  String get exitQuitDirect => '直接退出';

  @override
  String get syncFailedTitle => '同步失败';

  @override
  String syncFailedBody(String message) {
    return '$message\n待同步队列仍保存在本地。';
  }

  @override
  String get startupErrorTitle => '启动失败';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageHelp =>
      '界面语言。导出文档（试卷、答题卡、解析等）的标签随界面语言生成，题目内容保持原文。';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get omrReviewTitle => 'Windows 答题卡阅卷';

  @override
  String get omrWindowsOnly => '答题卡阅卷仅在 Windows 端开放';

  @override
  String omrImportFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String omrRecognizeFailed(String error) {
    return '识别失败：$error';
  }

  @override
  String omrSubmitFailed(String error) {
    return '交卷失败：$error';
  }

  @override
  String get omrReviewIntro => '选择已导出的纸质答题卡照片；识别结果只显示在本页，须逐题审核并确认交卷后才会写入答题事件。';

  @override
  String get omrRecognizing => '正在识别…';

  @override
  String get omrPickImage => '选择答题卡图片';

  @override
  String get omrPasteClipboard => '从剪贴板粘贴（Ctrl+V）';

  @override
  String get omrPreviewUnavailable => '原图无法预览';

  @override
  String get omrOverlayHint => '照片保持固定；拖动、双指缩放或旋转只调整识别叠层。';

  @override
  String get omrOverlayAlignLabel => '叠层对齐：';

  @override
  String get omrOverlayReset => '一键复位';

  @override
  String get omrReviewEachQuestion => '逐题审核';

  @override
  String get omrReviewEditableHint => '可直接改选。未确认前不会更改当前试卷或写入答题记录。';

  @override
  String get omrConfirmWrite => '确认识别结果并交卷';

  @override
  String get omrConfirmWriteTitle => '确认识别结果并交卷？';

  @override
  String get omrConfirmWriteBody => '确认后才会写入答题事件并提交试卷，之后不能再修改。';

  @override
  String get omrKeepReviewing => '继续审核';

  @override
  String get omrConfirmSubmit => '确认交卷';

  @override
  String omrQuestionHeader(int number, String type) {
    return '第 $number 题 · $type';
  }

  @override
  String get omrQuestionTypeSingle => '单选';

  @override
  String get omrQuestionTypeMultiple => '多选';

  @override
  String get dashboardTitle => '首页';

  @override
  String get dashboardCurrentBank => '当前题库';

  @override
  String get dashboardNoBank => '尚无题库';

  @override
  String get dashboardTagline => '离线优先 · 作答即时保存 · 未见题优先';

  @override
  String get dashboardAllSaved => '本地已保存';

  @override
  String dashboardPendingSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项待同步',
    );
    return '$_temp0';
  }

  @override
  String get dashboardQuickStart => '快速开始';

  @override
  String get dashboardContinueUnseen => '继续未见题';

  @override
  String get dashboardStartWrongReview => '开始错题复习';

  @override
  String get dashboardViewWrong => '查看错题';

  @override
  String get dashboardCreatePaper => '生成试卷';

  @override
  String get dashboardResumeDraft => '继续未完成试卷';

  @override
  String get dashboardRecentPapers => '最近试卷';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonRestore => '恢复';

  @override
  String get commonChoose => '选择';

  @override
  String get commonNone => '无';

  @override
  String get commonConfirmResetPhrase => '确认重置';

  @override
  String get statsTotalQuestions => '总题数';

  @override
  String get statsUnseen => '未见';

  @override
  String get statsCurrentWrong => '当前错题';

  @override
  String get statsMastered => '已掌握';

  @override
  String get statsEverWrong => '曾错';

  @override
  String get statsPendingSync => '待同步';

  @override
  String get statsTitle => '统计';

  @override
  String get statsNoBank => '暂无题库';

  @override
  String get statsByYear => '按年份';

  @override
  String get statsByChapter => '按章节';

  @override
  String get statsByTag => '按标签';

  @override
  String get statsByType => '按题型';

  @override
  String get statsSlowTitle => '慢题排行（交互估计）';

  @override
  String statsSeenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次作答',
    );
    return '$_temp0';
  }

  @override
  String statsSecondsPerQuestion(String seconds) {
    return '$seconds 秒/题';
  }

  @override
  String statsSeconds(String seconds) {
    return '$seconds 秒';
  }

  @override
  String get statsColumnCategory => '分类';

  @override
  String get statsColumnCount => '题数';

  @override
  String get statsColumnAttempts => '作答次数';

  @override
  String get statsColumnAccuracy => '正确率';

  @override
  String get statsColumnAvgTime => '平均用时';

  @override
  String get statsUncategorized => '未分类';

  @override
  String get modeUnseen => '未见题优先';

  @override
  String get modeWrongReview => '错题复习';

  @override
  String get modeRandom => '随机练习';

  @override
  String get modeFavorite => '收藏题';

  @override
  String get modeUncertain => '不确定题';

  @override
  String get practiceTitle => '开始练习';

  @override
  String practiceDefaultPolicy(String mode) {
    return '默认策略：$mode';
  }

  @override
  String get practiceDefaultPolicyDesc =>
      '先覆盖全部未见题；首次答错不在未见阶段提前重复；未见清零后复习当前错题。';

  @override
  String get practiceStartDefault => '按默认策略开始';

  @override
  String get practiceCustomScope => '自定义范围：';

  @override
  String get practiceClearFilters => '清除筛选';

  @override
  String get practiceShortcutsHint =>
      '快捷键：A—E 选择；Enter 提交；← / → 切题。输入个人笔记时快捷键自动停用。';

  @override
  String practiceQueueEmpty(String mode) {
    return '$mode暂无题目';
  }

  @override
  String practiceModeCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 题',
    );
    return '$_temp0';
  }

  @override
  String get filterAllYear => '全部年份';

  @override
  String get filterAllChapter => '全部章节';

  @override
  String get filterAllTag => '全部标签';

  @override
  String get filterAllTypes => '全部题型';

  @override
  String get questionTypeSingle => '单选题';

  @override
  String get questionTypeMultiple => '多选题';

  @override
  String get questionTypeSingleShort => '单选';

  @override
  String get questionTypeMultipleShort => '多选';

  @override
  String get paperTitle => '试卷模式';

  @override
  String get papersNoRecords => '暂无试卷记录';

  @override
  String papersSubtitle(int count, String status, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 题',
    );
    return '$_temp0 · $status · $duration';
  }

  @override
  String get paperDraftAvailable => '有一份未完成试卷';

  @override
  String get paperScopeTitle => '选题范围';

  @override
  String paperScopeSummary(int pool, String picker, int count) {
    return '当前范围共 $pool 题，$picker $count 题。';
  }

  @override
  String get paperPickerRandom => '将从中随机抽取';

  @override
  String get paperPickerInOrder => '将按题库顺序取前';

  @override
  String get paperCompositionTitle => '组卷模式';

  @override
  String get paperCompositionSingleOnly => '仅单选';

  @override
  String get paperCompositionMultipleOnly => '仅多选';

  @override
  String get paperCompositionRealExam => '真实考试';

  @override
  String get paperCountTitle => '题量';

  @override
  String get paperCustomCount => '自定义 1—100：';

  @override
  String get paperSuggestedMinutes => '建议完成时长（分钟）：';

  @override
  String get paperRandomTitle => '随机抽题';

  @override
  String get paperRandomDesc => '开启时从当前筛选范围内随机抽取题目并打乱顺序；关闭时按题库顺序取题。';

  @override
  String get paperGenerateStart => '生成并开始试卷';

  @override
  String get paperNote => '题量不足时只使用当前范围内的实际题量，不引入范围外题目。交卷前不显示答案和解析。';

  @override
  String paperAdjustedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '当前范围只有 $count 题，已按实际数量组卷',
    );
    return '$_temp0';
  }

  @override
  String get attemptStatusDraft => '未完成';

  @override
  String get attemptStatusSubmitted => '已交卷';

  @override
  String get attemptStatusAbandoned => '已放弃';

  @override
  String get historyTitle => '历史试卷';

  @override
  String get historyDeleteTooltip => '删除这张历史试卷';

  @override
  String get historyDeleteTitle => '删除历史试卷？';

  @override
  String historyDeleteBody(String title) {
    return '“$title”将从历史试卷列表中移除。已产生的题目答题统计不会被删除。';
  }

  @override
  String historyDeleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String get collectionTitle => '错题/收藏';

  @override
  String get collectionEverWrongTitle => '历史曾错';

  @override
  String get collectionExcludedTitle => '已排除题';

  @override
  String get collectionGenericTitle => '题目集';

  @override
  String get collectionExport => '导出当前分类';

  @override
  String collectionExported(String path) {
    return '已导出：$path';
  }

  @override
  String get collectionFavorite => '收藏';

  @override
  String get collectionUncertain => '不确定';

  @override
  String get collectionExcluded => '已排除';

  @override
  String get collectionEmpty => '当前分类暂无题目';

  @override
  String collectionItemSubtitle(String type, int seen, int wrong) {
    return '$type · $seen 次作答 · $wrong 次错误';
  }

  @override
  String get collectionHistoryTooltip => '完整作答历史';

  @override
  String collectionHistoryTitle(String id) {
    return '$id · 完整作答历史';
  }

  @override
  String get collectionNoEvents => '尚无作答事件';

  @override
  String collectionAnsweredAt(String time, String selected) {
    return '$time · 选择 $selected';
  }

  @override
  String get collectionNotAnswered => '未答';

  @override
  String collectionEventSubtitle(String mode, String score, String duration) {
    return '$mode · 得分 $score · 用时 $duration';
  }

  @override
  String get banksTitle => '题库管理';

  @override
  String get banksAddQuestion => '手动录入题目';

  @override
  String get banksPickerHint => '选择题库';

  @override
  String get banksReadonlyTitle => 'Android 题库为只读模式';

  @override
  String banksReadonlyBody(String name) {
    return '当前题库：$name。批量导入、编辑、停用和发布请在 Windows 端完成；本机可浏览题目并通过同步合并学习记录。';
  }

  @override
  String get banksImportTitle => '导入题库（ZIP / TSV / CSV）';

  @override
  String get banksImportHint => 'D:\\题库\\法规题库.tsv';

  @override
  String get banksChooseFile => '选择文件';

  @override
  String get banksPreview => '预览校验';

  @override
  String get banksBackupAndImport => '备份并导入';

  @override
  String banksPreviewSummary(
    String name,
    int total,
    int single,
    int multiple,
    int blocking,
    int warnings,
  ) {
    return '$name：$total 题（单选 $single，多选 $multiple）；阻断 $blocking，警告 $warnings';
  }

  @override
  String get banksResetTitle => '重新开始学习';

  @override
  String banksResetBody(String name, int count) {
    return '将“$name”的 $count 道题重置为未见。题目、收藏、个人笔记和已提交试卷历史会保留。';
  }

  @override
  String get banksResetAction => '重置答题状态';

  @override
  String get banksDeleteTitle => '删除当前题库';

  @override
  String banksDeleteBody(String name) {
    return '将“$name”从题库列表移除。已提交试卷和答题统计保留。';
  }

  @override
  String get banksDeleteAction => '删除题库';

  @override
  String get banksClearSearch => '清空搜索';

  @override
  String get banksSearchLabel => '搜索题库';

  @override
  String get banksSearchHint => '题号、题干、选项、答案、解析、考点、来源、年份、章节或标签';

  @override
  String banksLoadMore(int shown, int total) {
    return '加载更多（已显示 $shown / $total）';
  }

  @override
  String banksFilePickerFailed(String error) {
    return '无法打开文件选择器：$error';
  }

  @override
  String get banksPreviewOk => '校验通过，无警告。';

  @override
  String get banksIssueBlocking => '阻断';

  @override
  String get banksIssueWarning => '警告';

  @override
  String banksIssueLine(String severity, String message) {
    return '$severity：$message';
  }

  @override
  String banksReadFailed(String error) {
    return '无法读取题库包：$error';
  }

  @override
  String get banksImportDone => '导入完成；导入前备份已通过完整性检查。';

  @override
  String banksResetDialogTitle(String name) {
    return '重置“$name”的答题状态？';
  }

  @override
  String banksResetDialogBody(String phrase) {
    return '程序会先创建并校验数据库备份，然后：\n• 所有题目恢复为“未见”\n• 清空答题事件、正确/错误次数和累计用时\n• 删除该题库未完成的试卷草稿\n\n题目内容、收藏、个人笔记和已提交试卷历史不会删除。\n请输入“$phrase”继续。';
  }

  @override
  String get banksResetConfirmAction => '备份并重置';

  @override
  String banksResetting(String name) {
    return '正在备份并重置“$name”……';
  }

  @override
  String banksResetDone(String name, String backupPath) {
    return '“$name”已恢复为全部未见。备份：$backupPath';
  }

  @override
  String banksResetFailed(String error) {
    return '重置失败：$error；原数据未继续修改。';
  }

  @override
  String banksDeleteDialogTitle(String name) {
    return '删除题库“$name”？';
  }

  @override
  String get banksDeleteDialogBody =>
      '程序会将该题库及其题目从可选列表中移除。\n\n已提交试卷、答题事件和统计保留；以后重新导入同一题库可恢复使用。';

  @override
  String banksDeleting(String name) {
    return '正在删除“$name”……';
  }

  @override
  String banksDeleteDone(String name) {
    return '题库“$name”已删除。';
  }

  @override
  String banksDeleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String banksAddQuestionTitle(String name) {
    return '向“$name”手动录入题目';
  }

  @override
  String get banksFieldType => '题型';

  @override
  String get banksFieldExternalId => '题号（可选）';

  @override
  String get banksFieldStem => '题干 *';

  @override
  String banksFieldOption(String key, String suffix) {
    return '选项 $key$suffix';
  }

  @override
  String get banksFieldAnswerSingle => '答案 *（例如 A）';

  @override
  String get banksFieldAnswerMultiple => '答案 *（例如 AC）';

  @override
  String get banksFieldExplanation => '解析';

  @override
  String get banksFieldKnowledgePoint => '考点';

  @override
  String get banksFieldSource => '来源';

  @override
  String get banksFieldYear => '年份';

  @override
  String get banksFieldChapter => '章节';

  @override
  String get banksFieldTags => '标签（逗号分隔）';

  @override
  String get banksSaveQuestion => '保存题目';

  @override
  String get banksAddInvalid => '请填写题干、至少连续的 A/B 两个选项，并确认答案属于已填选项';

  @override
  String banksQuestionAdded(String name) {
    return '题目已添加到“$name”。';
  }

  @override
  String banksAddFailed(String error) {
    return '添加题目失败：$error';
  }

  @override
  String get pendingDialogTitle => '待同步项目';

  @override
  String get pendingDialogEmpty => '当前没有待同步项目';

  @override
  String get pendingDialogNote => '删除只会移出同步队列，本地答题记录、试卷和题库不会被删除。';

  @override
  String pendingSelectAll(int count) {
    return '全选（$count）';
  }

  @override
  String pendingItemSubtitle(String entityId, String createdAt) {
    return '编号：$entityId\n加入时间：$createdAt';
  }

  @override
  String pendingItemErrorLine(String error) {
    return '\n错误：$error';
  }

  @override
  String pendingDeleteSelected(int count) {
    return '删除所选（$count）';
  }

  @override
  String get pendingDeleteConfirmTitle => '确认移出同步队列';

  @override
  String pendingDeleteConfirmBody(int count) {
    return '确定删除所选 $count 项吗？本地数据仍会保留，但这些项目不会再上传，除非后续操作重新产生同步任务。';
  }

  @override
  String get pendingDeleteConfirmAction => '确认删除';

  @override
  String get syncEntityAnswerEvent => '作答记录';

  @override
  String get syncEntityPaperAttempt => '试卷记录';

  @override
  String get syncEntityArchiveAck => '试卷归档确认';

  @override
  String get syncEntityProgressControl => '题目状态';

  @override
  String get syncEntityQuestionBank => '题库';

  @override
  String get syncEntityQuestion => '题目';

  @override
  String get syncEntityMediaChunk => '题目媒体';

  @override
  String get syncEntitySetting => '设置';

  @override
  String get syncEntityUnknown => '未知项目';

  @override
  String get syncOperationUpsert => '新增或更新';

  @override
  String get syncOperationInsert => '新增';

  @override
  String get syncOperationUnknown => '同步';

  @override
  String get syncTitle => '同步与备份';

  @override
  String get syncCloudTitle => 'Supabase 云同步';

  @override
  String get syncCloudDesc =>
      '使用预先创建的 Supabase 邮箱账号登录，不在软件内注册。密码不落盘；本机仅保存公开的 Publishable Key 和个人会话令牌，用于启动自动对账。';

  @override
  String get syncSessionSaved => '本机已保存登录会话';

  @override
  String syncLoggedInAs(String email) {
    return '已登录：$email';
  }

  @override
  String get syncSessionAutoRenew => '启动软件和会话到期时会自动续期，不需要再次输入密码。';

  @override
  String get syncFieldUrl => 'Supabase 项目 URL';

  @override
  String get syncHintUrl => 'https://项目ID.supabase.co';

  @override
  String get syncFieldEmail => '个人账号邮箱';

  @override
  String get syncFieldPassword => '密码（不保存）';

  @override
  String get syncLoginAndSync => '登录并同步';

  @override
  String get syncRelogin => '更换账号或重新登录';

  @override
  String syncNow(int pending) {
    return '立即同步（待上传 $pending）';
  }

  @override
  String get syncClearSession => '清除本机会话';

  @override
  String get syncErrorsTitle => '同步错误';

  @override
  String get syncConflictsTitle => '待人工处理的冲突';

  @override
  String get syncConflictDesc => '自动同步没有覆盖本地内容；两份内容均已保留在冲突记录中。';

  @override
  String get syncBackupTitle => '本地备份';

  @override
  String get syncStorageAndroidNote =>
      'Android 使用系统保护的应用目录；自定义存储位置目前仅在 Windows 开放。';

  @override
  String get syncStorageDatabase => '数据库';

  @override
  String get syncStorageBackups => '备份目录';

  @override
  String get syncStorageExports => '导出目录';

  @override
  String get syncDefaultSuffix => '（默认）';

  @override
  String get syncBackupNow => '立即备份并检查';

  @override
  String get syncResetAfterBackup => '备份后重置当前题库状态';

  @override
  String get syncResetToDefault => '恢复默认';

  @override
  String get syncMoveDbTitle => '迁移数据库';

  @override
  String get syncMoveDbBody => '软件会先在目标目录生成完整数据库副本并校验，然后立即切换使用。原数据库会保留，方便回退。';

  @override
  String get syncMoveDbConfirm => '开始迁移';

  @override
  String get syncMovingDb => '正在迁移并校验数据库……';

  @override
  String syncMoveDbDone(String path) {
    return '数据库已切换到：$path';
  }

  @override
  String get syncBackupsDirUpdated => '备份目录已更新。';

  @override
  String get syncExportsDirUpdated => '导出目录已更新。';

  @override
  String syncStorageChangeFailed(String error) {
    return '存储位置修改失败：$error';
  }

  @override
  String get syncInProgress => '正在同步……';

  @override
  String get syncLoginInProgress => '正在登录并同步……';

  @override
  String syncLoginFailed(String error) {
    return '$error；本地数据未受影响。';
  }

  @override
  String syncReportDone(
    String message,
    int uploaded,
    int downloaded,
    int failed,
  ) {
    return '$message；上传 $uploaded，拉取 $downloaded，待重试 $failed';
  }

  @override
  String get syncSessionCleared => '已清除本机保存的同步会话；离线数据未受影响。';

  @override
  String syncBackupDone(String path) {
    return '备份完成并通过 integrity_check：$path';
  }

  @override
  String syncBackupFailed(String error) {
    return '备份失败：$error';
  }

  @override
  String get syncResetDialogTitle => '重置学习状态';

  @override
  String syncResetDialogBody(String phrase) {
    return '将先创建并校验备份，然后清空当前题库的作答事件和聚合学习状态。请输入“$phrase”。';
  }

  @override
  String get syncResetConfirmAction => '执行';

  @override
  String syncResetDone(String path) {
    return '已完成备份并重置：$path';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsDarkMode => '深色模式';

  @override
  String settingsFontScale(String value) {
    return '字号缩放 $value';
  }

  @override
  String settingsLineHeight(String value) {
    return '行距 $value';
  }

  @override
  String settingsContentWidth(String value) {
    return '内容最大宽度 $value px';
  }

  @override
  String get settingsRandomWrongReturn => '随机练习答错后重新列为当前错题';

  @override
  String get settingsRandomWrongReturnDesc => '默认开启；不会清除“曾错”历史。';

  @override
  String get settingsVersion => '版本';

  @override
  String settingsDeviceId(String deviceId) {
    return '设备 ID：$deviceId';
  }

  @override
  String paperHeaderAnswered(int answered, int total) {
    return '已答 $answered/$total';
  }

  @override
  String paperHeaderSuggested(String duration) {
    return '建议 $duration';
  }

  @override
  String get paperExportTooltipSubmitted => '导出试卷或 PDF';

  @override
  String get paperExportTooltipDraft => '导出空白试卷、答题卡或 PDF';

  @override
  String get paperReadAnswerSheet => '读取答题卡';

  @override
  String get paperEditBankQuestion => '编辑题库题目';

  @override
  String get paperNavigatorExpand => '展开题号导航';

  @override
  String get paperNavigatorCollapse => '折叠题号导航';

  @override
  String get paperOvertimeHint => '已超过建议时长，仍可继续作答';

  @override
  String get paperAutoSaved => '已自动保存到本地 SQLite  ';

  @override
  String paperMobileTitle(int current, int total) {
    return '第 $current / $total 题';
  }

  @override
  String get paperNumberPanelTooltip => '题号面板';

  @override
  String paperMobileAnsweredStatus(int answered, int total) {
    return '整卷已答 $answered/$total · 选项自动保存';
  }

  @override
  String get paperUncertainMarked => '已标不确定';

  @override
  String get paperUncertainMark => '标记不确定';

  @override
  String get paperUncertainMarkKey => '标记不确定（M）';

  @override
  String get paperSubmitting => '正在交卷…';

  @override
  String get paperSubmit => '交卷';

  @override
  String get paperSubmittingDesktop => '正在交卷，本地数据处理中…';

  @override
  String get paperSubmitConfirmTitle => '确认交卷？';

  @override
  String paperSubmitConfirmInline(int unanswered) {
    return '确认交卷？共有 $unanswered 道未答题，未答题按 0 分统计，但保持“未见”状态。';
  }

  @override
  String paperSubmitConfirmBody(int unanswered) {
    return '共有 $unanswered 道未答题。未答题按 0 分统计，但保持“未见”状态。';
  }

  @override
  String get paperConfirmSubmit => '确认交卷';

  @override
  String get paperKeepReviewing => '继续检查';

  @override
  String get paperPrevQuestion => '上一题';

  @override
  String get paperNextQuestion => '下一题';

  @override
  String get paperMoreActions => '更多操作';

  @override
  String get paperAbandonMenu => '放弃试卷…';

  @override
  String get paperAbandon => '放弃试卷';

  @override
  String get paperAbandonBody => '请选择如何处理当前本地草稿。放弃不会生成答错记录。';

  @override
  String get paperAbandonKeep => '保留草稿并退出';

  @override
  String get paperAbandonDiscard => '删除作答草稿';

  @override
  String paperMobileResultSummary(
    String summary,
    int unanswered,
    String duration,
  ) {
    return '$summary · 未答 $unanswered · $duration';
  }

  @override
  String paperResultSummary(String summary, int unanswered, String duration) {
    return '$summary　未答 $unanswered　用时 $duration';
  }

  @override
  String get paperExportShort => '导出';

  @override
  String get paperExportPackButton => '导出试卷包';

  @override
  String paperNumberPanelDraftTitle(int answered, int total) {
    return '题号面板 · 已答 $answered/$total';
  }

  @override
  String paperNumberPanelSubmittedTitle(
    int correctCount,
    int wrongCount,
    int unansweredCount,
  ) {
    return '题号面板 · 答对 $correctCount · 答错 $wrongCount · 未答 $unansweredCount';
  }

  @override
  String get paperNumberNavigatorTitle => '题号导航';

  @override
  String get paperUnanswered => '未答';

  @override
  String get paperAnswered => '已答';

  @override
  String get paperUncertainLabel => '不确定';

  @override
  String get paperCorrect => '答对';

  @override
  String get paperWrong => '答错';

  @override
  String get paperStatusAnsweredUncertain => '已答，已标记不确定';

  @override
  String get paperStatusUnansweredUncertain => '未答，已标记不确定';

  @override
  String paperStatusLabel(int number, String status) {
    return '第 $number 题，$status';
  }

  @override
  String paperStatusCurrentLabel(int number, String status) {
    return '第 $number 题，$status，当前题';
  }

  @override
  String get paperBadgeAnswered => '本题已答';

  @override
  String get paperBadgeUnanswered => '本题未答';

  @override
  String get paperEditQuestionMissing => '题库中找不到该题，无法编辑。';

  @override
  String paperEditBankQuestionTitle(String id) {
    return '编辑题库题目 $id';
  }

  @override
  String get paperEditQuestionUpdated => '题库已更新，当前试卷已显示最新题目内容。';

  @override
  String paperScoreSummary(String score, String maxScore) {
    return '得分 $score/$maxScore';
  }

  @override
  String paperScorePercentage(String percentage) {
    return ' · 百分制 $percentage%';
  }

  @override
  String paperSubmitFailed(String error) {
    return '交卷失败：$error；本地草稿已保留。';
  }

  @override
  String get paperExportTitle => '导出试卷';

  @override
  String get paperExportHintSubmitted =>
      '先选导出内容，再选输出方式；题目资源、打印 CSS 和 manifest 会自动随包输出。';

  @override
  String get paperExportHintDraft => '交卷前只能导出空白试卷和纸质答题卡；交卷后可导出答案与作答回顾。';

  @override
  String get paperExportSectionContent => '导出内容';

  @override
  String get paperExportBlankPaper => '空白试卷';

  @override
  String get paperExportBlankPaperDesc => '完整题干、选项及题目图片，不包含答案';

  @override
  String get paperExportAnswerSheet => '纸质答题卡';

  @override
  String get paperExportAnswerSheetDesc => 'A4 涂卡区，含二维码、四角定位点和 ABCDE 表头';

  @override
  String get paperExportAnswers => '答案与解析';

  @override
  String get paperExportAnswersDesc => '正确答案、解析、考点和来源';

  @override
  String get paperExportReview => '作答回顾';

  @override
  String get paperExportReviewDesc => '用户选择、判定、得分和用时';

  @override
  String get paperExportAfterSubmit => '交卷后可选';

  @override
  String get paperExportSectionOutput => '输出方式';

  @override
  String get paperExportModePack => '试卷包';

  @override
  String get paperExportModePackAndPdf => '试卷包＋PDF';

  @override
  String get paperExportModePdfOnly => '仅 PDF';

  @override
  String get paperExportPdfWindowsOnly => 'PDF 打印目前仅支持 Windows 版';

  @override
  String get paperExportModePackDesc =>
      '生成 Markdown 试卷包：所选文件、题目资源、打印 CSS 和 manifest 一起输出。';

  @override
  String get paperExportModePackAndPdfDesc =>
      '在试卷包之外，额外把所选内容合并为一份 A4 PDF，保存在同一目录。';

  @override
  String get paperExportModePdfOnlyDesc =>
      '只保留一份 PDF（空白试卷＋纸质答题卡）；Markdown、资源与 manifest 在生成成功后删除。';

  @override
  String get paperExportStart => '开始导出';

  @override
  String get paperExportAndPrint => '导出并打印 PDF';

  @override
  String get paperExportPdfOnlyButton => '仅导出 PDF';

  @override
  String paperExportedTo(String path) {
    return '已导出到：$path';
  }

  @override
  String paperExportedPdf(String path) {
    return 'PDF 已生成：$path';
  }

  @override
  String paperExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String paperExportPdfFailedWithPack(String path, String error) {
    return 'PDF 生成失败；Markdown 试卷包已保存到：$path\n\n$error';
  }

  @override
  String get paperExportPdfFailedTitle => 'PDF 生成失败';

  @override
  String get paperPdfErrorFileName => 'PDF生成错误.txt';

  @override
  String get practiceModeUnseen => '未见题优先';

  @override
  String get practiceModeWrongReview => '错题复习';

  @override
  String get practiceModeRandom => '随机练习';

  @override
  String get practiceModeFavorite => '收藏题';

  @override
  String get practiceModeUncertain => '不确定题';

  @override
  String get practicePrevQuestion => '上一题';

  @override
  String get practiceNextQuestion => '下一题';

  @override
  String get practiceSubmitCurrentKey => '提交当前题（Enter）';

  @override
  String get practiceSubmittedCurrent => '本题已提交';

  @override
  String get practiceSubmitAndReveal => '提交并查看答案';

  @override
  String get practiceFavoriteMarked => '已收藏';

  @override
  String get practiceFavorite => '收藏题目';

  @override
  String get practiceMarkedUncertain => '已标疑问';

  @override
  String get practiceMarkUncertain => '标记疑问';

  @override
  String get practiceAddNote => '添加笔记';

  @override
  String get practiceEditNote => '编辑笔记';

  @override
  String get practiceExcludeQuestion => '排除此题';

  @override
  String get practiceExcludeTitle => '排除此题？';

  @override
  String get practiceExcludeBody => '排除后，本题不会再进入自动练习队列；已有作答记录仍会保留。';

  @override
  String get practiceExcludeConfirm => '确认排除';

  @override
  String get practiceNoteTitle => '个人笔记（Markdown 文字）';

  @override
  String practiceProgressPosition(int current, int total) {
    return '第 $current / $total 题';
  }

  @override
  String practiceProgressPercent(int percent) {
    return '进度 $percent%';
  }

  @override
  String questionEditDefaultTitle(String id) {
    return '编辑 $id';
  }

  @override
  String get questionEditStemLabel => '题干 *';

  @override
  String questionEditOptionLabel(String option) {
    return '选项 $option';
  }

  @override
  String questionEditAnswerLabel(String example) {
    return '答案 *（例如 $example）';
  }

  @override
  String get questionEditExplanationLabel => '解析';

  @override
  String get questionEditKnowledgePointLabel => '考点';

  @override
  String get questionEditSave => '保存修改';

  @override
  String get questionEditValidationError => '请填写题干、至少连续的 A/B 两个选项，并确认答案属于已填选项';

  @override
  String get questionUncertainTooltipRemove => '已标疑问，点击取消';

  @override
  String get questionMarkUncertain => '标记疑问';

  @override
  String get questionMarkedUncertain => '已标疑问';

  @override
  String questionMediaMissing(String media) {
    return '媒体缺失：$media';
  }

  @override
  String get questionImageSemantics => '题目图片，可双指缩放';

  @override
  String get questionSelectAnswerRequired => '尚未选择答案，请先作答';

  @override
  String get questionCorrectAnswerLabel => '正确答案';

  @override
  String get questionYourChoiceLabel => '你的选择';

  @override
  String get questionResultUnanswered => '本题未作答';

  @override
  String get questionResultCorrect => '回答正确';

  @override
  String get questionResultWrong => '回答错误';

  @override
  String get questionNotAnswered => '未答';

  @override
  String get questionAnswerSeparator => '、';

  @override
  String questionScoreBadge(double score, double maxScore) {
    return '$score/$maxScore 分';
  }

  @override
  String get questionYourAnswerLabel => '你的答案';

  @override
  String get questionExplanationTitle => '答案解析';

  @override
  String get questionNoExplanation => '暂无解析';

  @override
  String get questionKnowledgePointEmpty => '考点未填写';

  @override
  String get questionSourceEmpty => '来源未填写';

  @override
  String get shellNavHome => '首页';

  @override
  String get shellNavPractice => '开始练习';

  @override
  String get shellNavPaper => '试卷模式';

  @override
  String get shellNavHistory => '历史试卷';

  @override
  String get shellNavCollection => '错题/收藏';

  @override
  String get shellNavBank => '题库管理';

  @override
  String get shellNavStats => '统计';

  @override
  String get shellNavSync => '同步与备份';

  @override
  String get shellNavSettings => '设置';

  @override
  String get shellTabPractice => '练习';

  @override
  String get shellTabPaper => '试卷';

  @override
  String get shellTabHistory => '历史';

  @override
  String get shellTabMore => '更多';

  @override
  String get shellSheetCollection => '错题 / 收藏';

  @override
  String get shellSheetBank => '题库';

  @override
  String get errImportBlockedUnsupportedFileType => '仅支持 .zip、.tsv 或 .csv 题库文件';

  @override
  String errImportBlockedZipUnparsable(String error) {
    return 'ZIP 无法解析：$error';
  }

  @override
  String get errImportBlockedMissingManifest => '缺少 manifest.json';

  @override
  String get errImportBlockedMissingQuestions => '缺少 questions.jsonl';

  @override
  String errImportBlockedManifestUnparsable(String error) {
    return 'manifest.json 无法解析：$error';
  }

  @override
  String errImportBlockedUnsupportedSchemaVersion(String version) {
    return '不支持 schema_version=$version';
  }

  @override
  String get errImportBlockedInvalidBankId => 'bank_id 包含无效目录字符';

  @override
  String get errImportBlockedInvalidBankMetadata => '题库 ID、名称或内容版本无效';

  @override
  String get errImportBlockedQuestionsHashMismatch =>
      'questions.jsonl 的 SHA-256 与清单不一致';

  @override
  String errImportBlockedEmptyQuestionId(int line) {
    return '第 $line 行 question_id 为空';
  }

  @override
  String errImportBlockedDupQuestionId(String id) {
    return '重复 question_id：$id';
  }

  @override
  String errImportBlockedInvalidQuestionType(String id, String type) {
    return '$id 的题型无效：$type';
  }

  @override
  String errImportBlockedEmptyStem(String id) {
    return '$id 的题干为空';
  }

  @override
  String errImportBlockedTooFewOptions(String id) {
    return '$id 少于两个有效选项';
  }

  @override
  String errImportBlockedAnswerNotInOptions(String id) {
    return '$id 的答案不在有效选项中';
  }

  @override
  String errImportBlockedSingleAnswerCount(String id) {
    return '$id 是单选题但答案数量不是 1';
  }

  @override
  String errImportBlockedMissingMedia(String id, String path) {
    return '$id 声明的媒体不存在：$path';
  }

  @override
  String errImportBlockedQuestionLineUnparsable(int line, String error) {
    return 'questions.jsonl 第 $line 行无法解析：$error';
  }

  @override
  String errImportBlockedQuestionCountMismatch(String declared, int actual) {
    return '清单题量 $declared 与实际 $actual 不一致';
  }

  @override
  String errImportBlockedMediaHashMismatch(String path) {
    return '媒体哈希不匹配：$path';
  }

  @override
  String errImportBlockedInvalidUtf8(String error) {
    return '文件不是有效的 UTF-8：$error';
  }

  @override
  String errImportBlockedDelimitedUnparsable(String error) {
    return '分隔文件无法解析：$error';
  }

  @override
  String get errImportBlockedEmptyFile => '文件缺少表头和题目';

  @override
  String errImportBlockedInvalidContentVersion(String version) {
    return '题库内容版本无效：$version';
  }

  @override
  String errImportBlockedDupHeader(String header) {
    return '存在重复表头：$header';
  }

  @override
  String errImportBlockedMissingColumn(String column) {
    return '缺少必需列：$column';
  }

  @override
  String errImportBlockedRowColumnMismatch(int line, int actual, int expected) {
    return '第 $line 行有 $actual 列，表头有 $expected 列';
  }

  @override
  String errImportBlockedEmptyExternalId(int line) {
    return '第 $line 行编号为空';
  }

  @override
  String errImportBlockedDupExplicitId(String id) {
    return '重复题目 ID：$id';
  }

  @override
  String errImportBlockedDupExternalId(String externalId) {
    return '重复编号：$externalId';
  }

  @override
  String errImportBlockedInvalidQuestionVersion(String id) {
    return '$id 的题目版本无效';
  }

  @override
  String get errImportBlockedNoValidQuestions => '文件中没有有效题目行';

  @override
  String errImportWarningDupExternalId(String externalId) {
    return '重复 external_id：$externalId';
  }

  @override
  String errImportWarningDupStem(String externalId) {
    return '存在相同题干：$externalId';
  }

  @override
  String errImportWarningEmptyExplanation(String id) {
    return '$id 的解析为空';
  }

  @override
  String errImportWarningIncompleteMetadata(String id) {
    return '$id 的年份、章节或来源不完整';
  }

  @override
  String errImportWarningBankNameFallback(String name) {
    return '未提供题库名称，已使用文件名“$name”';
  }

  @override
  String get errImportWarningGeneratedBankId =>
      '未提供 bank_id，已按题库名称和科目生成稳定 ID；以后更新时不要改变这两项';

  @override
  String get errOmrPlatformUnsupported => '答题卡阅卷仅支持 Windows';

  @override
  String errOmrImageFormatUnsupported(String path) {
    return '仅支持 PNG/JPG/JPEG：$path';
  }

  @override
  String errOmrExecutableMissing(String path) {
    return '缺少随程序发布的阅卷组件：$path';
  }

  @override
  String get errOmrRecognizeTimeout => '答题卡识别超时';

  @override
  String errOmrBridgeExitCode(int exitCode, String stderr) {
    return '阅卷组件退出码 $exitCode：$stderr';
  }

  @override
  String errOmrBridgeNoResult(String stdout) {
    return '阅卷组件未生成结构化结果：$stdout';
  }

  @override
  String get errOmrResultVersionInvalid => '阅卷结果版本无效';

  @override
  String get errOmrResultSourceSizeInvalid => '阅卷结果原图尺寸无效';

  @override
  String errOmrResultQuadInvalid(String field) {
    return '阅卷结果 $field 无效';
  }

  @override
  String errOmrResultQuadOutOfRange(String field) {
    return '阅卷结果 $field 越界';
  }

  @override
  String get errOmrResultQuestionCountMismatch => '阅卷结果题目数量不匹配';

  @override
  String get errOmrResultQuestionFormatInvalid => '阅卷结果题目格式无效';

  @override
  String errOmrResultLabelInvalid(String label) {
    return '阅卷结果标签无效：$label';
  }

  @override
  String get errOmrResultOptionsFormatInvalid => '阅卷结果选项格式无效';

  @override
  String get errOmrResultOptionsOutOfRange => '阅卷结果选项越界';

  @override
  String get errOmrResultConfidenceInvalid => '阅卷结果置信度无效';

  @override
  String get errOmrResultBubblesInvalid => '阅卷结果气泡几何无效';

  @override
  String get errOmrResultLabelsIncomplete => '阅卷结果标签不完整';

  @override
  String errSyncDone(int uploaded, int downloaded) {
    return '同步完成：上传 $uploaded 项，拉取 $downloaded 项';
  }

  @override
  String errSyncPartial(
    int uploaded,
    int downloaded,
    int failed,
    int deferred,
  ) {
    return '已上传 $uploaded 项、拉取 $downloaded 项；$failed 项未获确认，$deferred 项等待题库依赖';
  }

  @override
  String get errSyncTimeout => '同步超时，本地数据和同步队列均已保留';

  @override
  String errSyncFailed(String error) {
    return '同步失败，本地数据安全：$error';
  }

  @override
  String get errSyncNotLoggedIn => '尚未登录 Supabase 个人账号';

  @override
  String errSyncSessionRefreshFailed(String error) {
    return '会话刷新失败，本地数据安全：$error';
  }

  @override
  String get errSyncMissingCloudConfig =>
      '请填写 Supabase 项目 URL、Publishable Key 并登录';

  @override
  String get errSyncMissingAccountConfig =>
      '请填写 Supabase 项目 URL、Publishable Key、邮箱和密码';

  @override
  String get errAnswerNotSelected => '请先选择答案';

  @override
  String get errPracticeEmptyScope => '当前筛选范围没有可用题目';

  @override
  String get errBankNotSelected => '请先选择题库';

  @override
  String get errStorageTargetDirNotEmpty =>
      '目标目录已有 personal_exam.sqlite，请选择空目录，避免覆盖原数据库';

  @override
  String errStorageIntegrityCheckFailed(String integrity) {
    return '新数据库完整性检查失败：$integrity';
  }

  @override
  String get exportPaperFileName => '试卷';

  @override
  String get exportAnswersFileName => '答案与解析';

  @override
  String get exportReviewFileName => '作答回顾';

  @override
  String get exportAnswerSheetFileName => '答题卡';

  @override
  String get exportResourcesFolderName => '资源';

  @override
  String get exportAnswersYamlSuffix => '（答案与解析）';

  @override
  String get exportAnswersHeadingSuffix => ' · 答案与解析';

  @override
  String get exportReviewYamlSuffix => '（作答回顾）';

  @override
  String get exportReviewHeadingSuffix => ' · 作答回顾';

  @override
  String exportPaperStatsLine(String count, String minutes) {
    return '题量：$count　建议用时：$minutes 分钟';
  }

  @override
  String get exportMultipleChoiceTag => '【多选】';

  @override
  String get exportSingleChoiceTag => '【单选】';

  @override
  String exportMissingMediaWarning(String path) {
    return '> [!warning] 题目图片缺失：$path';
  }

  @override
  String exportCorrectAnswersBoldLine(String answers) {
    return '**正确答案：$answers**';
  }

  @override
  String exportExplanationLine(String explanation) {
    return '解析：$explanation';
  }

  @override
  String exportKnowledgePointSourceLine(String knowledgePoint, String source) {
    return '考点：$knowledgePoint　来源：$source';
  }

  @override
  String exportReviewScoreLine(String score, String max) {
    return '得分：$score / $max';
  }

  @override
  String exportTotalDurationLine(String duration) {
    return '总用时：$duration';
  }

  @override
  String exportOvertimeLine(String duration) {
    return '超时：$duration';
  }

  @override
  String exportUnansweredCountLine(String count) {
    return '未答：$count 题';
  }

  @override
  String get exportUnansweredStatus => '未答';

  @override
  String get exportFullyCorrectStatus => '完全正确';

  @override
  String get exportWrongStatus => '错误';

  @override
  String exportVerdictLine(String status) {
    return '判定：$status';
  }

  @override
  String exportUserSelectionLine(String answers) {
    return '用户选择：$answers';
  }

  @override
  String exportCorrectAnswerLine(String answers) {
    return '正确答案：$answers';
  }

  @override
  String exportQuestionDurationLine(String duration) {
    return '本题交互估计用时：$duration';
  }

  @override
  String exportFavoriteUncertainLine(String favorite, String uncertain) {
    return '收藏：$favorite；不确定：$uncertain';
  }

  @override
  String get exportYesLabel => '是';

  @override
  String get exportNoLabel => '否';

  @override
  String exportPersonalNoteLine(String note) {
    return '个人笔记：$note';
  }

  @override
  String get exportEmptyNoteValue => '无';

  @override
  String exportKnowledgePointSourceReviewLine(
    String knowledgePoint,
    String source,
  ) {
    return '考点：$knowledgePoint；来源：$source';
  }

  @override
  String get exportAnswerSeparator => '、';

  @override
  String get exportAnswerSheetYamlSuffix => '（答题卡）';

  @override
  String get exportAnswerSheetHeadingSuffix => ' · 答题卡';

  @override
  String exportAnswerSheetStatsLine(
    String count,
    String single,
    String multiple,
  ) {
    return '个人练习专用　共 $count 题　单选 $single 题　多选 $multiple 题';
  }

  @override
  String get exportAnswerSheetQrAlt => '答题卡二维码';

  @override
  String get exportFillNoteHtml =>
      '<strong>填涂说明：</strong>将所选圆圈完整涂黑；多选题可涂多个选项。修改时请擦净，无法擦净时重新打印。';

  @override
  String get exportAnswerSectionTitle => '选择题答题区';

  @override
  String get exportAnswerSectionHint => '请按试卷题号顺序填涂';

  @override
  String get exportQuestionNumberHeader => '题号';

  @override
  String get exportWrongQuestionsTitle => '当前错题';

  @override
  String exportRecentSelectionLine(String answers) {
    return '最近选择：$answers';
  }

  @override
  String exportKnowledgePointLine(String knowledgePoint) {
    return '考点：$knowledgePoint';
  }

  @override
  String exportSourceLine(String source) {
    return '来源：$source';
  }

  @override
  String exportAttemptStatsLine(String seen, String wrong) {
    return '累计作答：$seen 次；答错：$wrong 次';
  }

  @override
  String get settingsDevVersion => '开发版';

  @override
  String get questionTypeQa => '问答题';

  @override
  String get questionTypeQaShort => '问答';

  @override
  String get questionEditQaAnswerLabel => '参考答案（可留空）';

  @override
  String get questionQaAnswerLabel => '作答区';

  @override
  String get questionQaReferenceLabel => '参考答案';

  @override
  String get questionQaReferenceEmpty => '未提供参考答案';

  @override
  String get paperExportLayoutTitle => '试卷排版';

  @override
  String get paperExportLayoutA4 => 'A4';

  @override
  String get paperExportLayoutA3 => 'A3';

  @override
  String get paperExportLayoutHint => '答题卡始终为 A4；选择 A3 时试卷文档与答题卡分别输出两个 PDF。';

  @override
  String get paperTypeCountsTitle => '各题型数量（考试模式）';

  @override
  String get paperTypeCountsSingle => '单选题';

  @override
  String get paperTypeCountsMultiple => '多选题';

  @override
  String get paperTypeCountsQa => '问答题';

  @override
  String get paperTypeCountsHint => '库存不足的题型按现有数量组卷；问答题不计分。';

  @override
  String get settingsScoringTitle => '试卷判分规则';

  @override
  String get settingsScoringHint => '仅对新试卷生效；已交试卷保持组卷时的规则。';

  @override
  String settingsScoringSingleScore(String score) {
    return '单选每题分值：$score';
  }

  @override
  String settingsScoringMultipleScore(String score) {
    return '多选每题分值：$score';
  }

  @override
  String get settingsScoringPartialCredit => '多选少选给部分分';

  @override
  String settingsScoringPerOption(String score) {
    return '每个正确项分值：$score';
  }

  @override
  String get settingsScoringWrongZero => '有错项整题零分';

  @override
  String get settingsScoringQaNote => '问答题不判分，不计入总分。';

  @override
  String get omrQuestionTypeQa => '问答';

  @override
  String get omrQaAnswerHint => '问答题无法机读，可在此手工录入作答文本（可留空）';

  @override
  String get omrQaSheetNote => '答题卡气泡仅覆盖选择题（行首为试卷题号）；问答题在气泡表下方作答。';

  @override
  String errImportBlockedQaWithOptions(String id) {
    return '$id 是问答题但填写了选项';
  }

  @override
  String get errExportSheetNeedsChoice => '答题卡需要至少一道单选或多选题';

  @override
  String get exportQaTag => '【问答】';

  @override
  String exportQaReferenceAnswerLine(String answer) {
    return '参考答案：$answer';
  }

  @override
  String get exportQaEmptyReferenceAnswer => '（未提供参考答案）';

  @override
  String exportQaUserAnswerLine(String answer) {
    return '用户作答：$answer';
  }

  @override
  String get exportQaUnansweredText => '未作答';

  @override
  String get exportAnswerSheetQaSectionTitle => '问答题答题区';

  @override
  String exportAnswerSheetQaItemLabel(String number) {
    return '第 $number 题';
  }

  @override
  String get exportAnswerSheetQaOverflowNote => '其余问答题答题区不足，请直接在试卷上作答';

  @override
  String exportAnswerSheetQaStatsSuffix(String qa) {
    return '　问答 $qa 题';
  }

  @override
  String get omrGradingDone => '判卷完成';

  @override
  String get omrGradingDoneBody => '答题卡成绩已写入试卷，可在下方逐题核对；问答题为人工录入结果。';

  @override
  String get omrBackToPaper => '返回试卷';

  @override
  String get settingsRenderMarkupTitle => '渲染题目排版标记';

  @override
  String get settingsRenderMarkupDesc =>
      '将题干、选项与解析中的 <p>、<br> 等标记转换为换行等排版；关闭时界面剥离标记、导出原样保留。';
}
