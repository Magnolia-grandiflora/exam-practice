import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'题序'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonBack;

  /// No description provided for @commonDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get commonDone;

  /// No description provided for @commonContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get commonContinue;

  /// No description provided for @commonYes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get commonNo;

  /// No description provided for @commonLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get commonLoading;

  /// No description provided for @commonEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get commonEmpty;

  /// No description provided for @commonCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get commonCopied;

  /// No description provided for @commonUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get commonUnknown;

  /// No description provided for @commonAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get commonAll;

  /// No description provided for @commonEnabled.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get commonEnabled;

  /// No description provided for @commonDisabled.
  ///
  /// In zh, this message translates to:
  /// **'停用'**
  String get commonDisabled;

  /// No description provided for @commonPending.
  ///
  /// In zh, this message translates to:
  /// **'待处理'**
  String get commonPending;

  /// No description provided for @commonError.
  ///
  /// In zh, this message translates to:
  /// **'出错了'**
  String get commonError;

  /// No description provided for @commonDetails.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get commonDetails;

  /// No description provided for @exitQuitTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出题序'**
  String get exitQuitTitle;

  /// No description provided for @exitPendingTitle.
  ///
  /// In zh, this message translates to:
  /// **'有 {count} 项数据等待同步'**
  String exitPendingTitle(int count);

  /// No description provided for @exitPendingBody.
  ///
  /// In zh, this message translates to:
  /// **'全部作答和草稿已保存到本地 SQLite。可以先同步，也可以保留待同步队列直接退出。'**
  String get exitPendingBody;

  /// No description provided for @exitSavedBody.
  ///
  /// In zh, this message translates to:
  /// **'本地数据已保存。最近同步时间：{lastSync}'**
  String exitSavedBody(String lastSync);

  /// No description provided for @exitNeverSynced.
  ///
  /// In zh, this message translates to:
  /// **'尚未同步'**
  String get exitNeverSynced;

  /// No description provided for @exitStayWithoutSync.
  ///
  /// In zh, this message translates to:
  /// **'暂不同步，直接退出'**
  String get exitStayWithoutSync;

  /// No description provided for @exitQuit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get exitQuit;

  /// No description provided for @exitSyncAndQuit.
  ///
  /// In zh, this message translates to:
  /// **'同步并退出'**
  String get exitSyncAndQuit;

  /// No description provided for @exitCancelQuit.
  ///
  /// In zh, this message translates to:
  /// **'取消退出'**
  String get exitCancelQuit;

  /// No description provided for @exitQuitDirect.
  ///
  /// In zh, this message translates to:
  /// **'直接退出'**
  String get exitQuitDirect;

  /// No description provided for @syncFailedTitle.
  ///
  /// In zh, this message translates to:
  /// **'同步失败'**
  String get syncFailedTitle;

  /// No description provided for @syncFailedBody.
  ///
  /// In zh, this message translates to:
  /// **'{message}\n待同步队列仍保存在本地。'**
  String syncFailedBody(String message);

  /// No description provided for @startupErrorTitle.
  ///
  /// In zh, this message translates to:
  /// **'启动失败'**
  String get startupErrorTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageHelp.
  ///
  /// In zh, this message translates to:
  /// **'界面语言。导出文档（试卷、答题卡、解析等）的标签随界面语言生成，题目内容保持原文。'**
  String get settingsLanguageHelp;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @omrReviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'Windows 答题卡阅卷'**
  String get omrReviewTitle;

  /// No description provided for @omrWindowsOnly.
  ///
  /// In zh, this message translates to:
  /// **'答题卡阅卷仅在 Windows 端开放'**
  String get omrWindowsOnly;

  /// No description provided for @omrImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败：{error}'**
  String omrImportFailed(String error);

  /// No description provided for @omrRecognizeFailed.
  ///
  /// In zh, this message translates to:
  /// **'识别失败：{error}'**
  String omrRecognizeFailed(String error);

  /// No description provided for @omrSubmitFailed.
  ///
  /// In zh, this message translates to:
  /// **'交卷失败：{error}'**
  String omrSubmitFailed(String error);

  /// No description provided for @omrReviewIntro.
  ///
  /// In zh, this message translates to:
  /// **'选择已导出的纸质答题卡照片；识别结果只显示在本页，须逐题审核并确认交卷后才会写入答题事件。'**
  String get omrReviewIntro;

  /// No description provided for @omrRecognizing.
  ///
  /// In zh, this message translates to:
  /// **'正在识别…'**
  String get omrRecognizing;

  /// No description provided for @omrPickImage.
  ///
  /// In zh, this message translates to:
  /// **'选择答题卡图片'**
  String get omrPickImage;

  /// No description provided for @omrPasteClipboard.
  ///
  /// In zh, this message translates to:
  /// **'从剪贴板粘贴（Ctrl+V）'**
  String get omrPasteClipboard;

  /// No description provided for @omrPreviewUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'原图无法预览'**
  String get omrPreviewUnavailable;

  /// No description provided for @omrOverlayHint.
  ///
  /// In zh, this message translates to:
  /// **'照片保持固定；拖动、双指缩放或旋转只调整识别叠层。'**
  String get omrOverlayHint;

  /// No description provided for @omrOverlayAlignLabel.
  ///
  /// In zh, this message translates to:
  /// **'叠层对齐：'**
  String get omrOverlayAlignLabel;

  /// No description provided for @omrOverlayReset.
  ///
  /// In zh, this message translates to:
  /// **'一键复位'**
  String get omrOverlayReset;

  /// No description provided for @omrReviewEachQuestion.
  ///
  /// In zh, this message translates to:
  /// **'逐题审核'**
  String get omrReviewEachQuestion;

  /// No description provided for @omrReviewEditableHint.
  ///
  /// In zh, this message translates to:
  /// **'可直接改选。未确认前不会更改当前试卷或写入答题记录。'**
  String get omrReviewEditableHint;

  /// No description provided for @omrConfirmWrite.
  ///
  /// In zh, this message translates to:
  /// **'确认识别结果并交卷'**
  String get omrConfirmWrite;

  /// No description provided for @omrConfirmWriteTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认识别结果并交卷？'**
  String get omrConfirmWriteTitle;

  /// No description provided for @omrConfirmWriteBody.
  ///
  /// In zh, this message translates to:
  /// **'确认后才会写入答题事件并提交试卷，之后不能再修改。'**
  String get omrConfirmWriteBody;

  /// No description provided for @omrKeepReviewing.
  ///
  /// In zh, this message translates to:
  /// **'继续审核'**
  String get omrKeepReviewing;

  /// No description provided for @omrConfirmSubmit.
  ///
  /// In zh, this message translates to:
  /// **'确认交卷'**
  String get omrConfirmSubmit;

  /// No description provided for @omrQuestionHeader.
  ///
  /// In zh, this message translates to:
  /// **'第 {number} 题 · {type}'**
  String omrQuestionHeader(int number, String type);

  /// No description provided for @omrQuestionTypeSingle.
  ///
  /// In zh, this message translates to:
  /// **'单选'**
  String get omrQuestionTypeSingle;

  /// No description provided for @omrQuestionTypeMultiple.
  ///
  /// In zh, this message translates to:
  /// **'多选'**
  String get omrQuestionTypeMultiple;

  /// No description provided for @dashboardTitle.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get dashboardTitle;

  /// No description provided for @dashboardCurrentBank.
  ///
  /// In zh, this message translates to:
  /// **'当前题库'**
  String get dashboardCurrentBank;

  /// No description provided for @dashboardNoBank.
  ///
  /// In zh, this message translates to:
  /// **'尚无题库'**
  String get dashboardNoBank;

  /// No description provided for @dashboardTagline.
  ///
  /// In zh, this message translates to:
  /// **'离线优先 · 作答即时保存 · 未见题优先'**
  String get dashboardTagline;

  /// No description provided for @dashboardAllSaved.
  ///
  /// In zh, this message translates to:
  /// **'本地已保存'**
  String get dashboardAllSaved;

  /// No description provided for @dashboardPendingSyncCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 项待同步}}'**
  String dashboardPendingSyncCount(int count);

  /// No description provided for @dashboardQuickStart.
  ///
  /// In zh, this message translates to:
  /// **'快速开始'**
  String get dashboardQuickStart;

  /// No description provided for @dashboardContinueUnseen.
  ///
  /// In zh, this message translates to:
  /// **'继续未见题'**
  String get dashboardContinueUnseen;

  /// No description provided for @dashboardStartWrongReview.
  ///
  /// In zh, this message translates to:
  /// **'开始错题复习'**
  String get dashboardStartWrongReview;

  /// No description provided for @dashboardViewWrong.
  ///
  /// In zh, this message translates to:
  /// **'查看错题'**
  String get dashboardViewWrong;

  /// No description provided for @dashboardCreatePaper.
  ///
  /// In zh, this message translates to:
  /// **'生成试卷'**
  String get dashboardCreatePaper;

  /// No description provided for @dashboardResumeDraft.
  ///
  /// In zh, this message translates to:
  /// **'继续未完成试卷'**
  String get dashboardResumeDraft;

  /// No description provided for @dashboardRecentPapers.
  ///
  /// In zh, this message translates to:
  /// **'最近试卷'**
  String get dashboardRecentPapers;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get commonRestore;

  /// No description provided for @commonChoose.
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get commonChoose;

  /// No description provided for @commonNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get commonNone;

  /// No description provided for @commonConfirmResetPhrase.
  ///
  /// In zh, this message translates to:
  /// **'确认重置'**
  String get commonConfirmResetPhrase;

  /// No description provided for @statsTotalQuestions.
  ///
  /// In zh, this message translates to:
  /// **'总题数'**
  String get statsTotalQuestions;

  /// No description provided for @statsUnseen.
  ///
  /// In zh, this message translates to:
  /// **'未见'**
  String get statsUnseen;

  /// No description provided for @statsCurrentWrong.
  ///
  /// In zh, this message translates to:
  /// **'当前错题'**
  String get statsCurrentWrong;

  /// No description provided for @statsMastered.
  ///
  /// In zh, this message translates to:
  /// **'已掌握'**
  String get statsMastered;

  /// No description provided for @statsEverWrong.
  ///
  /// In zh, this message translates to:
  /// **'曾错'**
  String get statsEverWrong;

  /// No description provided for @statsPendingSync.
  ///
  /// In zh, this message translates to:
  /// **'待同步'**
  String get statsPendingSync;

  /// No description provided for @statsTitle.
  ///
  /// In zh, this message translates to:
  /// **'统计'**
  String get statsTitle;

  /// No description provided for @statsNoBank.
  ///
  /// In zh, this message translates to:
  /// **'暂无题库'**
  String get statsNoBank;

  /// No description provided for @statsByYear.
  ///
  /// In zh, this message translates to:
  /// **'按年份'**
  String get statsByYear;

  /// No description provided for @statsByChapter.
  ///
  /// In zh, this message translates to:
  /// **'按章节'**
  String get statsByChapter;

  /// No description provided for @statsByTag.
  ///
  /// In zh, this message translates to:
  /// **'按标签'**
  String get statsByTag;

  /// No description provided for @statsByType.
  ///
  /// In zh, this message translates to:
  /// **'按题型'**
  String get statsByType;

  /// No description provided for @statsSlowTitle.
  ///
  /// In zh, this message translates to:
  /// **'慢题排行（交互估计）'**
  String get statsSlowTitle;

  /// No description provided for @statsSeenCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 次作答}}'**
  String statsSeenCount(int count);

  /// No description provided for @statsSecondsPerQuestion.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒/题'**
  String statsSecondsPerQuestion(String seconds);

  /// No description provided for @statsSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String statsSeconds(String seconds);

  /// No description provided for @statsColumnCategory.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get statsColumnCategory;

  /// No description provided for @statsColumnCount.
  ///
  /// In zh, this message translates to:
  /// **'题数'**
  String get statsColumnCount;

  /// No description provided for @statsColumnAttempts.
  ///
  /// In zh, this message translates to:
  /// **'作答次数'**
  String get statsColumnAttempts;

  /// No description provided for @statsColumnAccuracy.
  ///
  /// In zh, this message translates to:
  /// **'正确率'**
  String get statsColumnAccuracy;

  /// No description provided for @statsColumnAvgTime.
  ///
  /// In zh, this message translates to:
  /// **'平均用时'**
  String get statsColumnAvgTime;

  /// No description provided for @statsUncategorized.
  ///
  /// In zh, this message translates to:
  /// **'未分类'**
  String get statsUncategorized;

  /// No description provided for @modeUnseen.
  ///
  /// In zh, this message translates to:
  /// **'未见题优先'**
  String get modeUnseen;

  /// No description provided for @modeWrongReview.
  ///
  /// In zh, this message translates to:
  /// **'错题复习'**
  String get modeWrongReview;

  /// No description provided for @modeRandom.
  ///
  /// In zh, this message translates to:
  /// **'随机练习'**
  String get modeRandom;

  /// No description provided for @modeFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏题'**
  String get modeFavorite;

  /// No description provided for @modeUncertain.
  ///
  /// In zh, this message translates to:
  /// **'不确定题'**
  String get modeUncertain;

  /// No description provided for @practiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'开始练习'**
  String get practiceTitle;

  /// No description provided for @practiceDefaultPolicy.
  ///
  /// In zh, this message translates to:
  /// **'默认策略：{mode}'**
  String practiceDefaultPolicy(String mode);

  /// No description provided for @practiceDefaultPolicyDesc.
  ///
  /// In zh, this message translates to:
  /// **'先覆盖全部未见题；首次答错不在未见阶段提前重复；未见清零后复习当前错题。'**
  String get practiceDefaultPolicyDesc;

  /// No description provided for @practiceStartDefault.
  ///
  /// In zh, this message translates to:
  /// **'按默认策略开始'**
  String get practiceStartDefault;

  /// No description provided for @practiceCustomScope.
  ///
  /// In zh, this message translates to:
  /// **'自定义范围：'**
  String get practiceCustomScope;

  /// No description provided for @practiceClearFilters.
  ///
  /// In zh, this message translates to:
  /// **'清除筛选'**
  String get practiceClearFilters;

  /// No description provided for @practiceShortcutsHint.
  ///
  /// In zh, this message translates to:
  /// **'快捷键：A—E 选择；Enter 提交；← / → 切题。输入个人笔记时快捷键自动停用。'**
  String get practiceShortcutsHint;

  /// No description provided for @practiceQueueEmpty.
  ///
  /// In zh, this message translates to:
  /// **'{mode}暂无题目'**
  String practiceQueueEmpty(String mode);

  /// No description provided for @practiceModeCardCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 题}}'**
  String practiceModeCardCount(int count);

  /// No description provided for @filterAllYear.
  ///
  /// In zh, this message translates to:
  /// **'全部年份'**
  String get filterAllYear;

  /// No description provided for @filterAllChapter.
  ///
  /// In zh, this message translates to:
  /// **'全部章节'**
  String get filterAllChapter;

  /// No description provided for @filterAllTag.
  ///
  /// In zh, this message translates to:
  /// **'全部标签'**
  String get filterAllTag;

  /// No description provided for @filterAllTypes.
  ///
  /// In zh, this message translates to:
  /// **'全部题型'**
  String get filterAllTypes;

  /// No description provided for @questionTypeSingle.
  ///
  /// In zh, this message translates to:
  /// **'单选题'**
  String get questionTypeSingle;

  /// No description provided for @questionTypeMultiple.
  ///
  /// In zh, this message translates to:
  /// **'多选题'**
  String get questionTypeMultiple;

  /// No description provided for @questionTypeSingleShort.
  ///
  /// In zh, this message translates to:
  /// **'单选'**
  String get questionTypeSingleShort;

  /// No description provided for @questionTypeMultipleShort.
  ///
  /// In zh, this message translates to:
  /// **'多选'**
  String get questionTypeMultipleShort;

  /// No description provided for @paperTitle.
  ///
  /// In zh, this message translates to:
  /// **'试卷模式'**
  String get paperTitle;

  /// No description provided for @papersNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无试卷记录'**
  String get papersNoRecords;

  /// No description provided for @papersSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 题}} · {status} · {duration}'**
  String papersSubtitle(int count, String status, String duration);

  /// No description provided for @paperDraftAvailable.
  ///
  /// In zh, this message translates to:
  /// **'有一份未完成试卷'**
  String get paperDraftAvailable;

  /// No description provided for @paperScopeTitle.
  ///
  /// In zh, this message translates to:
  /// **'选题范围'**
  String get paperScopeTitle;

  /// No description provided for @paperScopeSummary.
  ///
  /// In zh, this message translates to:
  /// **'当前范围共 {pool} 题，{picker} {count} 题。'**
  String paperScopeSummary(int pool, String picker, int count);

  /// No description provided for @paperPickerRandom.
  ///
  /// In zh, this message translates to:
  /// **'将从中随机抽取'**
  String get paperPickerRandom;

  /// No description provided for @paperPickerInOrder.
  ///
  /// In zh, this message translates to:
  /// **'将按题库顺序取前'**
  String get paperPickerInOrder;

  /// No description provided for @paperCompositionTitle.
  ///
  /// In zh, this message translates to:
  /// **'组卷模式'**
  String get paperCompositionTitle;

  /// No description provided for @paperCompositionSingleOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅单选'**
  String get paperCompositionSingleOnly;

  /// No description provided for @paperCompositionMultipleOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅多选'**
  String get paperCompositionMultipleOnly;

  /// No description provided for @paperCompositionRealExam.
  ///
  /// In zh, this message translates to:
  /// **'真实考试 14:3'**
  String get paperCompositionRealExam;

  /// No description provided for @paperCountTitle.
  ///
  /// In zh, this message translates to:
  /// **'题量'**
  String get paperCountTitle;

  /// No description provided for @paperCustomCount.
  ///
  /// In zh, this message translates to:
  /// **'自定义 1—100：'**
  String get paperCustomCount;

  /// No description provided for @paperSuggestedMinutes.
  ///
  /// In zh, this message translates to:
  /// **'建议完成时长（分钟）：'**
  String get paperSuggestedMinutes;

  /// No description provided for @paperRandomTitle.
  ///
  /// In zh, this message translates to:
  /// **'随机抽题'**
  String get paperRandomTitle;

  /// No description provided for @paperRandomDesc.
  ///
  /// In zh, this message translates to:
  /// **'开启时从当前筛选范围内随机抽取题目并打乱顺序；关闭时按题库顺序取题。'**
  String get paperRandomDesc;

  /// No description provided for @paperGenerateStart.
  ///
  /// In zh, this message translates to:
  /// **'生成并开始试卷'**
  String get paperGenerateStart;

  /// No description provided for @paperNote.
  ///
  /// In zh, this message translates to:
  /// **'题量不足时只使用当前范围内的实际题量，不引入范围外题目。交卷前不显示答案和解析。'**
  String get paperNote;

  /// No description provided for @paperAdjustedCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{当前范围只有 {count} 题，已按实际数量组卷}}'**
  String paperAdjustedCount(int count);

  /// No description provided for @attemptStatusDraft.
  ///
  /// In zh, this message translates to:
  /// **'未完成'**
  String get attemptStatusDraft;

  /// No description provided for @attemptStatusSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'已交卷'**
  String get attemptStatusSubmitted;

  /// No description provided for @attemptStatusAbandoned.
  ///
  /// In zh, this message translates to:
  /// **'已放弃'**
  String get attemptStatusAbandoned;

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'历史试卷'**
  String get historyTitle;

  /// No description provided for @historyDeleteTooltip.
  ///
  /// In zh, this message translates to:
  /// **'删除这张历史试卷'**
  String get historyDeleteTooltip;

  /// No description provided for @historyDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除历史试卷？'**
  String get historyDeleteTitle;

  /// No description provided for @historyDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'“{title}”将从历史试卷列表中移除。已产生的题目答题统计不会被删除。'**
  String historyDeleteBody(String title);

  /// No description provided for @historyDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败：{error}'**
  String historyDeleteFailed(String error);

  /// No description provided for @collectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'错题/收藏'**
  String get collectionTitle;

  /// No description provided for @collectionEverWrongTitle.
  ///
  /// In zh, this message translates to:
  /// **'历史曾错'**
  String get collectionEverWrongTitle;

  /// No description provided for @collectionExcludedTitle.
  ///
  /// In zh, this message translates to:
  /// **'已排除题'**
  String get collectionExcludedTitle;

  /// No description provided for @collectionGenericTitle.
  ///
  /// In zh, this message translates to:
  /// **'题目集'**
  String get collectionGenericTitle;

  /// No description provided for @collectionExport.
  ///
  /// In zh, this message translates to:
  /// **'导出当前分类'**
  String get collectionExport;

  /// No description provided for @collectionExported.
  ///
  /// In zh, this message translates to:
  /// **'已导出：{path}'**
  String collectionExported(String path);

  /// No description provided for @collectionFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get collectionFavorite;

  /// No description provided for @collectionUncertain.
  ///
  /// In zh, this message translates to:
  /// **'不确定'**
  String get collectionUncertain;

  /// No description provided for @collectionExcluded.
  ///
  /// In zh, this message translates to:
  /// **'已排除'**
  String get collectionExcluded;

  /// No description provided for @collectionEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前分类暂无题目'**
  String get collectionEmpty;

  /// No description provided for @collectionItemSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{type} · {seen} 次作答 · {wrong} 次错误'**
  String collectionItemSubtitle(String type, int seen, int wrong);

  /// No description provided for @collectionHistoryTooltip.
  ///
  /// In zh, this message translates to:
  /// **'完整作答历史'**
  String get collectionHistoryTooltip;

  /// No description provided for @collectionHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'{id} · 完整作答历史'**
  String collectionHistoryTitle(String id);

  /// No description provided for @collectionNoEvents.
  ///
  /// In zh, this message translates to:
  /// **'尚无作答事件'**
  String get collectionNoEvents;

  /// No description provided for @collectionAnsweredAt.
  ///
  /// In zh, this message translates to:
  /// **'{time} · 选择 {selected}'**
  String collectionAnsweredAt(String time, String selected);

  /// No description provided for @collectionNotAnswered.
  ///
  /// In zh, this message translates to:
  /// **'未答'**
  String get collectionNotAnswered;

  /// No description provided for @collectionEventSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{mode} · 得分 {score} · 用时 {duration}'**
  String collectionEventSubtitle(String mode, String score, String duration);

  /// No description provided for @banksTitle.
  ///
  /// In zh, this message translates to:
  /// **'题库管理'**
  String get banksTitle;

  /// No description provided for @banksAddQuestion.
  ///
  /// In zh, this message translates to:
  /// **'手动录入题目'**
  String get banksAddQuestion;

  /// No description provided for @banksPickerHint.
  ///
  /// In zh, this message translates to:
  /// **'选择题库'**
  String get banksPickerHint;

  /// No description provided for @banksReadonlyTitle.
  ///
  /// In zh, this message translates to:
  /// **'Android 题库为只读模式'**
  String get banksReadonlyTitle;

  /// No description provided for @banksReadonlyBody.
  ///
  /// In zh, this message translates to:
  /// **'当前题库：{name}。批量导入、编辑、停用和发布请在 Windows 端完成；本机可浏览题目并通过同步合并学习记录。'**
  String banksReadonlyBody(String name);

  /// No description provided for @banksImportTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入题库（ZIP / TSV / CSV）'**
  String get banksImportTitle;

  /// No description provided for @banksImportHint.
  ///
  /// In zh, this message translates to:
  /// **'D:\\题库\\法规题库.tsv'**
  String get banksImportHint;

  /// No description provided for @banksChooseFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get banksChooseFile;

  /// No description provided for @banksPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览校验'**
  String get banksPreview;

  /// No description provided for @banksBackupAndImport.
  ///
  /// In zh, this message translates to:
  /// **'备份并导入'**
  String get banksBackupAndImport;

  /// No description provided for @banksPreviewSummary.
  ///
  /// In zh, this message translates to:
  /// **'{name}：{total} 题（单选 {single}，多选 {multiple}）；阻断 {blocking}，警告 {warnings}'**
  String banksPreviewSummary(
    String name,
    int total,
    int single,
    int multiple,
    int blocking,
    int warnings,
  );

  /// No description provided for @banksResetTitle.
  ///
  /// In zh, this message translates to:
  /// **'重新开始学习'**
  String get banksResetTitle;

  /// No description provided for @banksResetBody.
  ///
  /// In zh, this message translates to:
  /// **'将“{name}”的 {count} 道题重置为未见。题目、收藏、个人笔记和已提交试卷历史会保留。'**
  String banksResetBody(String name, int count);

  /// No description provided for @banksResetAction.
  ///
  /// In zh, this message translates to:
  /// **'重置答题状态'**
  String get banksResetAction;

  /// No description provided for @banksDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除当前题库'**
  String get banksDeleteTitle;

  /// No description provided for @banksDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'将“{name}”从题库列表移除。已提交试卷和答题统计保留。'**
  String banksDeleteBody(String name);

  /// No description provided for @banksDeleteAction.
  ///
  /// In zh, this message translates to:
  /// **'删除题库'**
  String get banksDeleteAction;

  /// No description provided for @banksClearSearch.
  ///
  /// In zh, this message translates to:
  /// **'清空搜索'**
  String get banksClearSearch;

  /// No description provided for @banksSearchLabel.
  ///
  /// In zh, this message translates to:
  /// **'搜索题库'**
  String get banksSearchLabel;

  /// No description provided for @banksSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'题号、题干、选项、答案、解析、考点、来源、年份、章节或标签'**
  String get banksSearchHint;

  /// No description provided for @banksLoadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更多（已显示 {shown} / {total}）'**
  String banksLoadMore(int shown, int total);

  /// No description provided for @banksFilePickerFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开文件选择器：{error}'**
  String banksFilePickerFailed(String error);

  /// No description provided for @banksPreviewOk.
  ///
  /// In zh, this message translates to:
  /// **'校验通过，无警告。'**
  String get banksPreviewOk;

  /// No description provided for @banksIssueBlocking.
  ///
  /// In zh, this message translates to:
  /// **'阻断'**
  String get banksIssueBlocking;

  /// No description provided for @banksIssueWarning.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get banksIssueWarning;

  /// No description provided for @banksIssueLine.
  ///
  /// In zh, this message translates to:
  /// **'{severity}：{message}'**
  String banksIssueLine(String severity, String message);

  /// No description provided for @banksReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取题库包：{error}'**
  String banksReadFailed(String error);

  /// No description provided for @banksImportDone.
  ///
  /// In zh, this message translates to:
  /// **'导入完成；导入前备份已通过完整性检查。'**
  String get banksImportDone;

  /// No description provided for @banksResetDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置“{name}”的答题状态？'**
  String banksResetDialogTitle(String name);

  /// No description provided for @banksResetDialogBody.
  ///
  /// In zh, this message translates to:
  /// **'程序会先创建并校验数据库备份，然后：\n• 所有题目恢复为“未见”\n• 清空答题事件、正确/错误次数和累计用时\n• 删除该题库未完成的试卷草稿\n\n题目内容、收藏、个人笔记和已提交试卷历史不会删除。\n请输入“{phrase}”继续。'**
  String banksResetDialogBody(String phrase);

  /// No description provided for @banksResetConfirmAction.
  ///
  /// In zh, this message translates to:
  /// **'备份并重置'**
  String get banksResetConfirmAction;

  /// No description provided for @banksResetting.
  ///
  /// In zh, this message translates to:
  /// **'正在备份并重置“{name}”……'**
  String banksResetting(String name);

  /// No description provided for @banksResetDone.
  ///
  /// In zh, this message translates to:
  /// **'“{name}”已恢复为全部未见。备份：{backupPath}'**
  String banksResetDone(String name, String backupPath);

  /// No description provided for @banksResetFailed.
  ///
  /// In zh, this message translates to:
  /// **'重置失败：{error}；原数据未继续修改。'**
  String banksResetFailed(String error);

  /// No description provided for @banksDeleteDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除题库“{name}”？'**
  String banksDeleteDialogTitle(String name);

  /// No description provided for @banksDeleteDialogBody.
  ///
  /// In zh, this message translates to:
  /// **'程序会将该题库及其题目从可选列表中移除。\n\n已提交试卷、答题事件和统计保留；以后重新导入同一题库可恢复使用。'**
  String get banksDeleteDialogBody;

  /// No description provided for @banksDeleting.
  ///
  /// In zh, this message translates to:
  /// **'正在删除“{name}”……'**
  String banksDeleting(String name);

  /// No description provided for @banksDeleteDone.
  ///
  /// In zh, this message translates to:
  /// **'题库“{name}”已删除。'**
  String banksDeleteDone(String name);

  /// No description provided for @banksDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败：{error}'**
  String banksDeleteFailed(String error);

  /// No description provided for @banksAddQuestionTitle.
  ///
  /// In zh, this message translates to:
  /// **'向“{name}”手动录入题目'**
  String banksAddQuestionTitle(String name);

  /// No description provided for @banksFieldType.
  ///
  /// In zh, this message translates to:
  /// **'题型'**
  String get banksFieldType;

  /// No description provided for @banksFieldExternalId.
  ///
  /// In zh, this message translates to:
  /// **'题号（可选）'**
  String get banksFieldExternalId;

  /// No description provided for @banksFieldStem.
  ///
  /// In zh, this message translates to:
  /// **'题干 *'**
  String get banksFieldStem;

  /// No description provided for @banksFieldOption.
  ///
  /// In zh, this message translates to:
  /// **'选项 {key}{suffix}'**
  String banksFieldOption(String key, String suffix);

  /// No description provided for @banksFieldAnswerSingle.
  ///
  /// In zh, this message translates to:
  /// **'答案 *（例如 A）'**
  String get banksFieldAnswerSingle;

  /// No description provided for @banksFieldAnswerMultiple.
  ///
  /// In zh, this message translates to:
  /// **'答案 *（例如 AC）'**
  String get banksFieldAnswerMultiple;

  /// No description provided for @banksFieldExplanation.
  ///
  /// In zh, this message translates to:
  /// **'解析'**
  String get banksFieldExplanation;

  /// No description provided for @banksFieldKnowledgePoint.
  ///
  /// In zh, this message translates to:
  /// **'考点'**
  String get banksFieldKnowledgePoint;

  /// No description provided for @banksFieldSource.
  ///
  /// In zh, this message translates to:
  /// **'来源'**
  String get banksFieldSource;

  /// No description provided for @banksFieldYear.
  ///
  /// In zh, this message translates to:
  /// **'年份'**
  String get banksFieldYear;

  /// No description provided for @banksFieldChapter.
  ///
  /// In zh, this message translates to:
  /// **'章节'**
  String get banksFieldChapter;

  /// No description provided for @banksFieldTags.
  ///
  /// In zh, this message translates to:
  /// **'标签（逗号分隔）'**
  String get banksFieldTags;

  /// No description provided for @banksSaveQuestion.
  ///
  /// In zh, this message translates to:
  /// **'保存题目'**
  String get banksSaveQuestion;

  /// No description provided for @banksAddInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请填写题干、至少连续的 A/B 两个选项，并确认答案属于已填选项'**
  String get banksAddInvalid;

  /// No description provided for @banksQuestionAdded.
  ///
  /// In zh, this message translates to:
  /// **'题目已添加到“{name}”。'**
  String banksQuestionAdded(String name);

  /// No description provided for @banksAddFailed.
  ///
  /// In zh, this message translates to:
  /// **'添加题目失败：{error}'**
  String banksAddFailed(String error);

  /// No description provided for @pendingDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'待同步项目'**
  String get pendingDialogTitle;

  /// No description provided for @pendingDialogEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前没有待同步项目'**
  String get pendingDialogEmpty;

  /// No description provided for @pendingDialogNote.
  ///
  /// In zh, this message translates to:
  /// **'删除只会移出同步队列，本地答题记录、试卷和题库不会被删除。'**
  String get pendingDialogNote;

  /// No description provided for @pendingSelectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选（{count}）'**
  String pendingSelectAll(int count);

  /// No description provided for @pendingItemSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'编号：{entityId}\n加入时间：{createdAt}'**
  String pendingItemSubtitle(String entityId, String createdAt);

  /// No description provided for @pendingItemErrorLine.
  ///
  /// In zh, this message translates to:
  /// **'\n错误：{error}'**
  String pendingItemErrorLine(String error);

  /// No description provided for @pendingDeleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'删除所选（{count}）'**
  String pendingDeleteSelected(int count);

  /// No description provided for @pendingDeleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认移出同步队列'**
  String get pendingDeleteConfirmTitle;

  /// No description provided for @pendingDeleteConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'确定删除所选 {count} 项吗？本地数据仍会保留，但这些项目不会再上传，除非后续操作重新产生同步任务。'**
  String pendingDeleteConfirmBody(int count);

  /// No description provided for @pendingDeleteConfirmAction.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get pendingDeleteConfirmAction;

  /// No description provided for @syncEntityAnswerEvent.
  ///
  /// In zh, this message translates to:
  /// **'作答记录'**
  String get syncEntityAnswerEvent;

  /// No description provided for @syncEntityPaperAttempt.
  ///
  /// In zh, this message translates to:
  /// **'试卷记录'**
  String get syncEntityPaperAttempt;

  /// No description provided for @syncEntityArchiveAck.
  ///
  /// In zh, this message translates to:
  /// **'试卷归档确认'**
  String get syncEntityArchiveAck;

  /// No description provided for @syncEntityProgressControl.
  ///
  /// In zh, this message translates to:
  /// **'题目状态'**
  String get syncEntityProgressControl;

  /// No description provided for @syncEntityQuestionBank.
  ///
  /// In zh, this message translates to:
  /// **'题库'**
  String get syncEntityQuestionBank;

  /// No description provided for @syncEntityQuestion.
  ///
  /// In zh, this message translates to:
  /// **'题目'**
  String get syncEntityQuestion;

  /// No description provided for @syncEntityMediaChunk.
  ///
  /// In zh, this message translates to:
  /// **'题目媒体'**
  String get syncEntityMediaChunk;

  /// No description provided for @syncEntitySetting.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get syncEntitySetting;

  /// No description provided for @syncEntityUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知项目'**
  String get syncEntityUnknown;

  /// No description provided for @syncOperationUpsert.
  ///
  /// In zh, this message translates to:
  /// **'新增或更新'**
  String get syncOperationUpsert;

  /// No description provided for @syncOperationInsert.
  ///
  /// In zh, this message translates to:
  /// **'新增'**
  String get syncOperationInsert;

  /// No description provided for @syncOperationUnknown.
  ///
  /// In zh, this message translates to:
  /// **'同步'**
  String get syncOperationUnknown;

  /// No description provided for @syncTitle.
  ///
  /// In zh, this message translates to:
  /// **'同步与备份'**
  String get syncTitle;

  /// No description provided for @syncCloudTitle.
  ///
  /// In zh, this message translates to:
  /// **'Supabase 云同步'**
  String get syncCloudTitle;

  /// No description provided for @syncCloudDesc.
  ///
  /// In zh, this message translates to:
  /// **'使用预先创建的 Supabase 邮箱账号登录，不在软件内注册。密码不落盘；本机仅保存公开的 Publishable Key 和个人会话令牌，用于启动自动对账。'**
  String get syncCloudDesc;

  /// No description provided for @syncSessionSaved.
  ///
  /// In zh, this message translates to:
  /// **'本机已保存登录会话'**
  String get syncSessionSaved;

  /// No description provided for @syncLoggedInAs.
  ///
  /// In zh, this message translates to:
  /// **'已登录：{email}'**
  String syncLoggedInAs(String email);

  /// No description provided for @syncSessionAutoRenew.
  ///
  /// In zh, this message translates to:
  /// **'启动软件和会话到期时会自动续期，不需要再次输入密码。'**
  String get syncSessionAutoRenew;

  /// No description provided for @syncFieldUrl.
  ///
  /// In zh, this message translates to:
  /// **'Supabase 项目 URL'**
  String get syncFieldUrl;

  /// No description provided for @syncHintUrl.
  ///
  /// In zh, this message translates to:
  /// **'https://项目ID.supabase.co'**
  String get syncHintUrl;

  /// No description provided for @syncFieldEmail.
  ///
  /// In zh, this message translates to:
  /// **'个人账号邮箱'**
  String get syncFieldEmail;

  /// No description provided for @syncFieldPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码（不保存）'**
  String get syncFieldPassword;

  /// No description provided for @syncLoginAndSync.
  ///
  /// In zh, this message translates to:
  /// **'登录并同步'**
  String get syncLoginAndSync;

  /// No description provided for @syncRelogin.
  ///
  /// In zh, this message translates to:
  /// **'更换账号或重新登录'**
  String get syncRelogin;

  /// No description provided for @syncNow.
  ///
  /// In zh, this message translates to:
  /// **'立即同步（待上传 {pending}）'**
  String syncNow(int pending);

  /// No description provided for @syncClearSession.
  ///
  /// In zh, this message translates to:
  /// **'清除本机会话'**
  String get syncClearSession;

  /// No description provided for @syncErrorsTitle.
  ///
  /// In zh, this message translates to:
  /// **'同步错误'**
  String get syncErrorsTitle;

  /// No description provided for @syncConflictsTitle.
  ///
  /// In zh, this message translates to:
  /// **'待人工处理的冲突'**
  String get syncConflictsTitle;

  /// No description provided for @syncConflictDesc.
  ///
  /// In zh, this message translates to:
  /// **'自动同步没有覆盖本地内容；两份内容均已保留在冲突记录中。'**
  String get syncConflictDesc;

  /// No description provided for @syncBackupTitle.
  ///
  /// In zh, this message translates to:
  /// **'本地备份'**
  String get syncBackupTitle;

  /// No description provided for @syncStorageAndroidNote.
  ///
  /// In zh, this message translates to:
  /// **'Android 使用系统保护的应用目录；自定义存储位置目前仅在 Windows 开放。'**
  String get syncStorageAndroidNote;

  /// No description provided for @syncStorageDatabase.
  ///
  /// In zh, this message translates to:
  /// **'数据库'**
  String get syncStorageDatabase;

  /// No description provided for @syncStorageBackups.
  ///
  /// In zh, this message translates to:
  /// **'备份目录'**
  String get syncStorageBackups;

  /// No description provided for @syncStorageExports.
  ///
  /// In zh, this message translates to:
  /// **'导出目录'**
  String get syncStorageExports;

  /// No description provided for @syncDefaultSuffix.
  ///
  /// In zh, this message translates to:
  /// **'（默认）'**
  String get syncDefaultSuffix;

  /// No description provided for @syncBackupNow.
  ///
  /// In zh, this message translates to:
  /// **'立即备份并检查'**
  String get syncBackupNow;

  /// No description provided for @syncResetAfterBackup.
  ///
  /// In zh, this message translates to:
  /// **'备份后重置当前题库状态'**
  String get syncResetAfterBackup;

  /// No description provided for @syncResetToDefault.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get syncResetToDefault;

  /// No description provided for @syncMoveDbTitle.
  ///
  /// In zh, this message translates to:
  /// **'迁移数据库'**
  String get syncMoveDbTitle;

  /// No description provided for @syncMoveDbBody.
  ///
  /// In zh, this message translates to:
  /// **'软件会先在目标目录生成完整数据库副本并校验，然后立即切换使用。原数据库会保留，方便回退。'**
  String get syncMoveDbBody;

  /// No description provided for @syncMoveDbConfirm.
  ///
  /// In zh, this message translates to:
  /// **'开始迁移'**
  String get syncMoveDbConfirm;

  /// No description provided for @syncMovingDb.
  ///
  /// In zh, this message translates to:
  /// **'正在迁移并校验数据库……'**
  String get syncMovingDb;

  /// No description provided for @syncMoveDbDone.
  ///
  /// In zh, this message translates to:
  /// **'数据库已切换到：{path}'**
  String syncMoveDbDone(String path);

  /// No description provided for @syncBackupsDirUpdated.
  ///
  /// In zh, this message translates to:
  /// **'备份目录已更新。'**
  String get syncBackupsDirUpdated;

  /// No description provided for @syncExportsDirUpdated.
  ///
  /// In zh, this message translates to:
  /// **'导出目录已更新。'**
  String get syncExportsDirUpdated;

  /// No description provided for @syncStorageChangeFailed.
  ///
  /// In zh, this message translates to:
  /// **'存储位置修改失败：{error}'**
  String syncStorageChangeFailed(String error);

  /// No description provided for @syncInProgress.
  ///
  /// In zh, this message translates to:
  /// **'正在同步……'**
  String get syncInProgress;

  /// No description provided for @syncLoginInProgress.
  ///
  /// In zh, this message translates to:
  /// **'正在登录并同步……'**
  String get syncLoginInProgress;

  /// No description provided for @syncLoginFailed.
  ///
  /// In zh, this message translates to:
  /// **'{error}；本地数据未受影响。'**
  String syncLoginFailed(String error);

  /// No description provided for @syncReportDone.
  ///
  /// In zh, this message translates to:
  /// **'{message}；上传 {uploaded}，拉取 {downloaded}，待重试 {failed}'**
  String syncReportDone(
    String message,
    int uploaded,
    int downloaded,
    int failed,
  );

  /// No description provided for @syncSessionCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清除本机保存的同步会话；离线数据未受影响。'**
  String get syncSessionCleared;

  /// No description provided for @syncBackupDone.
  ///
  /// In zh, this message translates to:
  /// **'备份完成并通过 integrity_check：{path}'**
  String syncBackupDone(String path);

  /// No description provided for @syncBackupFailed.
  ///
  /// In zh, this message translates to:
  /// **'备份失败：{error}'**
  String syncBackupFailed(String error);

  /// No description provided for @syncResetDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置学习状态'**
  String get syncResetDialogTitle;

  /// No description provided for @syncResetDialogBody.
  ///
  /// In zh, this message translates to:
  /// **'将先创建并校验备份，然后清空当前题库的作答事件和聚合学习状态。请输入“{phrase}”。'**
  String syncResetDialogBody(String phrase);

  /// No description provided for @syncResetConfirmAction.
  ///
  /// In zh, this message translates to:
  /// **'执行'**
  String get syncResetConfirmAction;

  /// No description provided for @syncResetDone.
  ///
  /// In zh, this message translates to:
  /// **'已完成备份并重置：{path}'**
  String syncResetDone(String path);

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsDarkMode.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get settingsDarkMode;

  /// No description provided for @settingsFontScale.
  ///
  /// In zh, this message translates to:
  /// **'字号缩放 {value}'**
  String settingsFontScale(String value);

  /// No description provided for @settingsLineHeight.
  ///
  /// In zh, this message translates to:
  /// **'行距 {value}'**
  String settingsLineHeight(String value);

  /// No description provided for @settingsContentWidth.
  ///
  /// In zh, this message translates to:
  /// **'内容最大宽度 {value} px'**
  String settingsContentWidth(String value);

  /// No description provided for @settingsRandomWrongReturn.
  ///
  /// In zh, this message translates to:
  /// **'随机练习答错后重新列为当前错题'**
  String get settingsRandomWrongReturn;

  /// No description provided for @settingsRandomWrongReturnDesc.
  ///
  /// In zh, this message translates to:
  /// **'默认开启；不会清除“曾错”历史。'**
  String get settingsRandomWrongReturnDesc;

  /// No description provided for @settingsVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get settingsVersion;

  /// No description provided for @settingsDeviceId.
  ///
  /// In zh, this message translates to:
  /// **'设备 ID：{deviceId}'**
  String settingsDeviceId(String deviceId);

  /// No description provided for @paperHeaderAnswered.
  ///
  /// In zh, this message translates to:
  /// **'已答 {answered}/{total}'**
  String paperHeaderAnswered(int answered, int total);

  /// No description provided for @paperHeaderSuggested.
  ///
  /// In zh, this message translates to:
  /// **'建议 {duration}'**
  String paperHeaderSuggested(String duration);

  /// No description provided for @paperExportTooltipSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'导出试卷或 PDF'**
  String get paperExportTooltipSubmitted;

  /// No description provided for @paperExportTooltipDraft.
  ///
  /// In zh, this message translates to:
  /// **'导出空白试卷、答题卡或 PDF'**
  String get paperExportTooltipDraft;

  /// No description provided for @paperReadAnswerSheet.
  ///
  /// In zh, this message translates to:
  /// **'读取答题卡'**
  String get paperReadAnswerSheet;

  /// No description provided for @paperEditBankQuestion.
  ///
  /// In zh, this message translates to:
  /// **'编辑题库题目'**
  String get paperEditBankQuestion;

  /// No description provided for @paperNavigatorExpand.
  ///
  /// In zh, this message translates to:
  /// **'展开题号导航'**
  String get paperNavigatorExpand;

  /// No description provided for @paperNavigatorCollapse.
  ///
  /// In zh, this message translates to:
  /// **'折叠题号导航'**
  String get paperNavigatorCollapse;

  /// No description provided for @paperOvertimeHint.
  ///
  /// In zh, this message translates to:
  /// **'已超过建议时长，仍可继续作答'**
  String get paperOvertimeHint;

  /// No description provided for @paperAutoSaved.
  ///
  /// In zh, this message translates to:
  /// **'已自动保存到本地 SQLite  '**
  String get paperAutoSaved;

  /// No description provided for @paperMobileTitle.
  ///
  /// In zh, this message translates to:
  /// **'第 {current} / {total} 题'**
  String paperMobileTitle(int current, int total);

  /// No description provided for @paperNumberPanelTooltip.
  ///
  /// In zh, this message translates to:
  /// **'题号面板'**
  String get paperNumberPanelTooltip;

  /// No description provided for @paperMobileAnsweredStatus.
  ///
  /// In zh, this message translates to:
  /// **'整卷已答 {answered}/{total} · 选项自动保存'**
  String paperMobileAnsweredStatus(int answered, int total);

  /// No description provided for @paperUncertainMarked.
  ///
  /// In zh, this message translates to:
  /// **'已标不确定'**
  String get paperUncertainMarked;

  /// No description provided for @paperUncertainMark.
  ///
  /// In zh, this message translates to:
  /// **'标记不确定'**
  String get paperUncertainMark;

  /// No description provided for @paperUncertainMarkKey.
  ///
  /// In zh, this message translates to:
  /// **'标记不确定（M）'**
  String get paperUncertainMarkKey;

  /// No description provided for @paperSubmitting.
  ///
  /// In zh, this message translates to:
  /// **'正在交卷…'**
  String get paperSubmitting;

  /// No description provided for @paperSubmit.
  ///
  /// In zh, this message translates to:
  /// **'交卷'**
  String get paperSubmit;

  /// No description provided for @paperSubmittingDesktop.
  ///
  /// In zh, this message translates to:
  /// **'正在交卷，本地数据处理中…'**
  String get paperSubmittingDesktop;

  /// No description provided for @paperSubmitConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认交卷？'**
  String get paperSubmitConfirmTitle;

  /// No description provided for @paperSubmitConfirmInline.
  ///
  /// In zh, this message translates to:
  /// **'确认交卷？共有 {unanswered} 道未答题，未答题按 0 分统计，但保持“未见”状态。'**
  String paperSubmitConfirmInline(int unanswered);

  /// No description provided for @paperSubmitConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'共有 {unanswered} 道未答题。未答题按 0 分统计，但保持“未见”状态。'**
  String paperSubmitConfirmBody(int unanswered);

  /// No description provided for @paperConfirmSubmit.
  ///
  /// In zh, this message translates to:
  /// **'确认交卷'**
  String get paperConfirmSubmit;

  /// No description provided for @paperKeepReviewing.
  ///
  /// In zh, this message translates to:
  /// **'继续检查'**
  String get paperKeepReviewing;

  /// No description provided for @paperPrevQuestion.
  ///
  /// In zh, this message translates to:
  /// **'上一题'**
  String get paperPrevQuestion;

  /// No description provided for @paperNextQuestion.
  ///
  /// In zh, this message translates to:
  /// **'下一题'**
  String get paperNextQuestion;

  /// No description provided for @paperMoreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get paperMoreActions;

  /// No description provided for @paperAbandonMenu.
  ///
  /// In zh, this message translates to:
  /// **'放弃试卷…'**
  String get paperAbandonMenu;

  /// No description provided for @paperAbandon.
  ///
  /// In zh, this message translates to:
  /// **'放弃试卷'**
  String get paperAbandon;

  /// No description provided for @paperAbandonBody.
  ///
  /// In zh, this message translates to:
  /// **'请选择如何处理当前本地草稿。放弃不会生成答错记录。'**
  String get paperAbandonBody;

  /// No description provided for @paperAbandonKeep.
  ///
  /// In zh, this message translates to:
  /// **'保留草稿并退出'**
  String get paperAbandonKeep;

  /// No description provided for @paperAbandonDiscard.
  ///
  /// In zh, this message translates to:
  /// **'删除作答草稿'**
  String get paperAbandonDiscard;

  /// No description provided for @paperMobileResultSummary.
  ///
  /// In zh, this message translates to:
  /// **'{summary} · 未答 {unanswered} · {duration}'**
  String paperMobileResultSummary(
    String summary,
    int unanswered,
    String duration,
  );

  /// No description provided for @paperResultSummary.
  ///
  /// In zh, this message translates to:
  /// **'{summary}　未答 {unanswered}　用时 {duration}'**
  String paperResultSummary(String summary, int unanswered, String duration);

  /// No description provided for @paperExportShort.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get paperExportShort;

  /// No description provided for @paperExportPackButton.
  ///
  /// In zh, this message translates to:
  /// **'导出试卷包'**
  String get paperExportPackButton;

  /// No description provided for @paperNumberPanelDraftTitle.
  ///
  /// In zh, this message translates to:
  /// **'题号面板 · 已答 {answered}/{total}'**
  String paperNumberPanelDraftTitle(int answered, int total);

  /// No description provided for @paperNumberPanelSubmittedTitle.
  ///
  /// In zh, this message translates to:
  /// **'题号面板 · 答对 {correctCount} · 答错 {wrongCount} · 未答 {unansweredCount}'**
  String paperNumberPanelSubmittedTitle(
    int correctCount,
    int wrongCount,
    int unansweredCount,
  );

  /// No description provided for @paperNumberNavigatorTitle.
  ///
  /// In zh, this message translates to:
  /// **'题号导航'**
  String get paperNumberNavigatorTitle;

  /// No description provided for @paperUnanswered.
  ///
  /// In zh, this message translates to:
  /// **'未答'**
  String get paperUnanswered;

  /// No description provided for @paperAnswered.
  ///
  /// In zh, this message translates to:
  /// **'已答'**
  String get paperAnswered;

  /// No description provided for @paperUncertainLabel.
  ///
  /// In zh, this message translates to:
  /// **'不确定'**
  String get paperUncertainLabel;

  /// No description provided for @paperCorrect.
  ///
  /// In zh, this message translates to:
  /// **'答对'**
  String get paperCorrect;

  /// No description provided for @paperWrong.
  ///
  /// In zh, this message translates to:
  /// **'答错'**
  String get paperWrong;

  /// No description provided for @paperStatusAnsweredUncertain.
  ///
  /// In zh, this message translates to:
  /// **'已答，已标记不确定'**
  String get paperStatusAnsweredUncertain;

  /// No description provided for @paperStatusUnansweredUncertain.
  ///
  /// In zh, this message translates to:
  /// **'未答，已标记不确定'**
  String get paperStatusUnansweredUncertain;

  /// No description provided for @paperStatusLabel.
  ///
  /// In zh, this message translates to:
  /// **'第 {number} 题，{status}'**
  String paperStatusLabel(int number, String status);

  /// No description provided for @paperStatusCurrentLabel.
  ///
  /// In zh, this message translates to:
  /// **'第 {number} 题，{status}，当前题'**
  String paperStatusCurrentLabel(int number, String status);

  /// No description provided for @paperBadgeAnswered.
  ///
  /// In zh, this message translates to:
  /// **'本题已答'**
  String get paperBadgeAnswered;

  /// No description provided for @paperBadgeUnanswered.
  ///
  /// In zh, this message translates to:
  /// **'本题未答'**
  String get paperBadgeUnanswered;

  /// No description provided for @paperEditQuestionMissing.
  ///
  /// In zh, this message translates to:
  /// **'题库中找不到该题，无法编辑。'**
  String get paperEditQuestionMissing;

  /// No description provided for @paperEditBankQuestionTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑题库题目 {id}'**
  String paperEditBankQuestionTitle(String id);

  /// No description provided for @paperEditQuestionUpdated.
  ///
  /// In zh, this message translates to:
  /// **'题库已更新，当前试卷已显示最新题目内容。'**
  String get paperEditQuestionUpdated;

  /// No description provided for @paperScoreSummary.
  ///
  /// In zh, this message translates to:
  /// **'得分 {score}/{maxScore}'**
  String paperScoreSummary(String score, String maxScore);

  /// No description provided for @paperScorePercentage.
  ///
  /// In zh, this message translates to:
  /// **' · 百分制 {percentage}%'**
  String paperScorePercentage(String percentage);

  /// No description provided for @paperSubmitFailed.
  ///
  /// In zh, this message translates to:
  /// **'交卷失败：{error}；本地草稿已保留。'**
  String paperSubmitFailed(String error);

  /// No description provided for @paperExportTitle.
  ///
  /// In zh, this message translates to:
  /// **'导出试卷'**
  String get paperExportTitle;

  /// No description provided for @paperExportHintSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'先选导出内容，再选输出方式；题目资源、打印 CSS 和 manifest 会自动随包输出。'**
  String get paperExportHintSubmitted;

  /// No description provided for @paperExportHintDraft.
  ///
  /// In zh, this message translates to:
  /// **'交卷前只能导出空白试卷和纸质答题卡；交卷后可导出答案与作答回顾。'**
  String get paperExportHintDraft;

  /// No description provided for @paperExportSectionContent.
  ///
  /// In zh, this message translates to:
  /// **'导出内容'**
  String get paperExportSectionContent;

  /// No description provided for @paperExportBlankPaper.
  ///
  /// In zh, this message translates to:
  /// **'空白试卷'**
  String get paperExportBlankPaper;

  /// No description provided for @paperExportBlankPaperDesc.
  ///
  /// In zh, this message translates to:
  /// **'完整题干、选项及题目图片，不包含答案'**
  String get paperExportBlankPaperDesc;

  /// No description provided for @paperExportAnswerSheet.
  ///
  /// In zh, this message translates to:
  /// **'纸质答题卡'**
  String get paperExportAnswerSheet;

  /// No description provided for @paperExportAnswerSheetDesc.
  ///
  /// In zh, this message translates to:
  /// **'A4 涂卡区，含二维码、四角定位点和 ABCDE 表头'**
  String get paperExportAnswerSheetDesc;

  /// No description provided for @paperExportAnswers.
  ///
  /// In zh, this message translates to:
  /// **'答案与解析'**
  String get paperExportAnswers;

  /// No description provided for @paperExportAnswersDesc.
  ///
  /// In zh, this message translates to:
  /// **'正确答案、解析、考点和来源'**
  String get paperExportAnswersDesc;

  /// No description provided for @paperExportReview.
  ///
  /// In zh, this message translates to:
  /// **'作答回顾'**
  String get paperExportReview;

  /// No description provided for @paperExportReviewDesc.
  ///
  /// In zh, this message translates to:
  /// **'用户选择、判定、得分和用时'**
  String get paperExportReviewDesc;

  /// No description provided for @paperExportAfterSubmit.
  ///
  /// In zh, this message translates to:
  /// **'交卷后可选'**
  String get paperExportAfterSubmit;

  /// No description provided for @paperExportSectionOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出方式'**
  String get paperExportSectionOutput;

  /// No description provided for @paperExportModePack.
  ///
  /// In zh, this message translates to:
  /// **'试卷包'**
  String get paperExportModePack;

  /// No description provided for @paperExportModePackAndPdf.
  ///
  /// In zh, this message translates to:
  /// **'试卷包＋PDF'**
  String get paperExportModePackAndPdf;

  /// No description provided for @paperExportModePdfOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅 PDF'**
  String get paperExportModePdfOnly;

  /// No description provided for @paperExportPdfWindowsOnly.
  ///
  /// In zh, this message translates to:
  /// **'PDF 打印目前仅支持 Windows 版'**
  String get paperExportPdfWindowsOnly;

  /// No description provided for @paperExportModePackDesc.
  ///
  /// In zh, this message translates to:
  /// **'生成 Markdown 试卷包：所选文件、题目资源、打印 CSS 和 manifest 一起输出。'**
  String get paperExportModePackDesc;

  /// No description provided for @paperExportModePackAndPdfDesc.
  ///
  /// In zh, this message translates to:
  /// **'在试卷包之外，额外把所选内容合并为一份 A4 PDF，保存在同一目录。'**
  String get paperExportModePackAndPdfDesc;

  /// No description provided for @paperExportModePdfOnlyDesc.
  ///
  /// In zh, this message translates to:
  /// **'只保留一份 PDF（空白试卷＋纸质答题卡）；Markdown、资源与 manifest 在生成成功后删除。'**
  String get paperExportModePdfOnlyDesc;

  /// No description provided for @paperExportStart.
  ///
  /// In zh, this message translates to:
  /// **'开始导出'**
  String get paperExportStart;

  /// No description provided for @paperExportAndPrint.
  ///
  /// In zh, this message translates to:
  /// **'导出并打印 PDF'**
  String get paperExportAndPrint;

  /// No description provided for @paperExportPdfOnlyButton.
  ///
  /// In zh, this message translates to:
  /// **'仅导出 PDF'**
  String get paperExportPdfOnlyButton;

  /// No description provided for @paperExportedTo.
  ///
  /// In zh, this message translates to:
  /// **'已导出到：{path}'**
  String paperExportedTo(String path);

  /// No description provided for @paperExportedPdf.
  ///
  /// In zh, this message translates to:
  /// **'PDF 已生成：{path}'**
  String paperExportedPdf(String path);

  /// No description provided for @paperExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{error}'**
  String paperExportFailed(String error);

  /// No description provided for @paperExportPdfFailedWithPack.
  ///
  /// In zh, this message translates to:
  /// **'PDF 生成失败；Markdown 试卷包已保存到：{path}\n\n{error}'**
  String paperExportPdfFailedWithPack(String path, String error);

  /// No description provided for @paperExportPdfFailedTitle.
  ///
  /// In zh, this message translates to:
  /// **'PDF 生成失败'**
  String get paperExportPdfFailedTitle;

  /// No description provided for @paperPdfErrorFileName.
  ///
  /// In zh, this message translates to:
  /// **'PDF生成错误.txt'**
  String get paperPdfErrorFileName;

  /// No description provided for @practiceModeUnseen.
  ///
  /// In zh, this message translates to:
  /// **'未见题优先'**
  String get practiceModeUnseen;

  /// No description provided for @practiceModeWrongReview.
  ///
  /// In zh, this message translates to:
  /// **'错题复习'**
  String get practiceModeWrongReview;

  /// No description provided for @practiceModeRandom.
  ///
  /// In zh, this message translates to:
  /// **'随机练习'**
  String get practiceModeRandom;

  /// No description provided for @practiceModeFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏题'**
  String get practiceModeFavorite;

  /// No description provided for @practiceModeUncertain.
  ///
  /// In zh, this message translates to:
  /// **'不确定题'**
  String get practiceModeUncertain;

  /// No description provided for @practicePrevQuestion.
  ///
  /// In zh, this message translates to:
  /// **'上一题'**
  String get practicePrevQuestion;

  /// No description provided for @practiceNextQuestion.
  ///
  /// In zh, this message translates to:
  /// **'下一题'**
  String get practiceNextQuestion;

  /// No description provided for @practiceSubmitCurrentKey.
  ///
  /// In zh, this message translates to:
  /// **'提交当前题（Enter）'**
  String get practiceSubmitCurrentKey;

  /// No description provided for @practiceSubmittedCurrent.
  ///
  /// In zh, this message translates to:
  /// **'本题已提交'**
  String get practiceSubmittedCurrent;

  /// No description provided for @practiceSubmitAndReveal.
  ///
  /// In zh, this message translates to:
  /// **'提交并查看答案'**
  String get practiceSubmitAndReveal;

  /// No description provided for @practiceFavoriteMarked.
  ///
  /// In zh, this message translates to:
  /// **'已收藏'**
  String get practiceFavoriteMarked;

  /// No description provided for @practiceFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏题目'**
  String get practiceFavorite;

  /// No description provided for @practiceMarkedUncertain.
  ///
  /// In zh, this message translates to:
  /// **'已标疑问'**
  String get practiceMarkedUncertain;

  /// No description provided for @practiceMarkUncertain.
  ///
  /// In zh, this message translates to:
  /// **'标记疑问'**
  String get practiceMarkUncertain;

  /// No description provided for @practiceAddNote.
  ///
  /// In zh, this message translates to:
  /// **'添加笔记'**
  String get practiceAddNote;

  /// No description provided for @practiceEditNote.
  ///
  /// In zh, this message translates to:
  /// **'编辑笔记'**
  String get practiceEditNote;

  /// No description provided for @practiceExcludeQuestion.
  ///
  /// In zh, this message translates to:
  /// **'排除此题'**
  String get practiceExcludeQuestion;

  /// No description provided for @practiceExcludeTitle.
  ///
  /// In zh, this message translates to:
  /// **'排除此题？'**
  String get practiceExcludeTitle;

  /// No description provided for @practiceExcludeBody.
  ///
  /// In zh, this message translates to:
  /// **'排除后，本题不会再进入自动练习队列；已有作答记录仍会保留。'**
  String get practiceExcludeBody;

  /// No description provided for @practiceExcludeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认排除'**
  String get practiceExcludeConfirm;

  /// No description provided for @practiceNoteTitle.
  ///
  /// In zh, this message translates to:
  /// **'个人笔记（Markdown 文字）'**
  String get practiceNoteTitle;

  /// No description provided for @practiceProgressPosition.
  ///
  /// In zh, this message translates to:
  /// **'第 {current} / {total} 题'**
  String practiceProgressPosition(int current, int total);

  /// No description provided for @practiceProgressPercent.
  ///
  /// In zh, this message translates to:
  /// **'进度 {percent}%'**
  String practiceProgressPercent(int percent);

  /// No description provided for @questionEditDefaultTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑 {id}'**
  String questionEditDefaultTitle(String id);

  /// No description provided for @questionEditStemLabel.
  ///
  /// In zh, this message translates to:
  /// **'题干 *'**
  String get questionEditStemLabel;

  /// No description provided for @questionEditOptionLabel.
  ///
  /// In zh, this message translates to:
  /// **'选项 {option}'**
  String questionEditOptionLabel(String option);

  /// No description provided for @questionEditAnswerLabel.
  ///
  /// In zh, this message translates to:
  /// **'答案 *（例如 {example}）'**
  String questionEditAnswerLabel(String example);

  /// No description provided for @questionEditExplanationLabel.
  ///
  /// In zh, this message translates to:
  /// **'解析'**
  String get questionEditExplanationLabel;

  /// No description provided for @questionEditKnowledgePointLabel.
  ///
  /// In zh, this message translates to:
  /// **'考点'**
  String get questionEditKnowledgePointLabel;

  /// No description provided for @questionEditSave.
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get questionEditSave;

  /// No description provided for @questionEditValidationError.
  ///
  /// In zh, this message translates to:
  /// **'请填写题干、至少连续的 A/B 两个选项，并确认答案属于已填选项'**
  String get questionEditValidationError;

  /// No description provided for @questionUncertainTooltipRemove.
  ///
  /// In zh, this message translates to:
  /// **'已标疑问，点击取消'**
  String get questionUncertainTooltipRemove;

  /// No description provided for @questionMarkUncertain.
  ///
  /// In zh, this message translates to:
  /// **'标记疑问'**
  String get questionMarkUncertain;

  /// No description provided for @questionMarkedUncertain.
  ///
  /// In zh, this message translates to:
  /// **'已标疑问'**
  String get questionMarkedUncertain;

  /// No description provided for @questionMediaMissing.
  ///
  /// In zh, this message translates to:
  /// **'媒体缺失：{media}'**
  String questionMediaMissing(String media);

  /// No description provided for @questionImageSemantics.
  ///
  /// In zh, this message translates to:
  /// **'题目图片，可双指缩放'**
  String get questionImageSemantics;

  /// No description provided for @questionSelectAnswerRequired.
  ///
  /// In zh, this message translates to:
  /// **'尚未选择答案，请先作答'**
  String get questionSelectAnswerRequired;

  /// No description provided for @questionCorrectAnswerLabel.
  ///
  /// In zh, this message translates to:
  /// **'正确答案'**
  String get questionCorrectAnswerLabel;

  /// No description provided for @questionYourChoiceLabel.
  ///
  /// In zh, this message translates to:
  /// **'你的选择'**
  String get questionYourChoiceLabel;

  /// No description provided for @questionResultUnanswered.
  ///
  /// In zh, this message translates to:
  /// **'本题未作答'**
  String get questionResultUnanswered;

  /// No description provided for @questionResultCorrect.
  ///
  /// In zh, this message translates to:
  /// **'回答正确'**
  String get questionResultCorrect;

  /// No description provided for @questionResultWrong.
  ///
  /// In zh, this message translates to:
  /// **'回答错误'**
  String get questionResultWrong;

  /// No description provided for @questionNotAnswered.
  ///
  /// In zh, this message translates to:
  /// **'未答'**
  String get questionNotAnswered;

  /// No description provided for @questionAnswerSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get questionAnswerSeparator;

  /// No description provided for @questionScoreBadge.
  ///
  /// In zh, this message translates to:
  /// **'{score}/{maxScore} 分'**
  String questionScoreBadge(double score, double maxScore);

  /// No description provided for @questionYourAnswerLabel.
  ///
  /// In zh, this message translates to:
  /// **'你的答案'**
  String get questionYourAnswerLabel;

  /// No description provided for @questionExplanationTitle.
  ///
  /// In zh, this message translates to:
  /// **'答案解析'**
  String get questionExplanationTitle;

  /// No description provided for @questionNoExplanation.
  ///
  /// In zh, this message translates to:
  /// **'暂无解析'**
  String get questionNoExplanation;

  /// No description provided for @questionKnowledgePointEmpty.
  ///
  /// In zh, this message translates to:
  /// **'考点未填写'**
  String get questionKnowledgePointEmpty;

  /// No description provided for @questionSourceEmpty.
  ///
  /// In zh, this message translates to:
  /// **'来源未填写'**
  String get questionSourceEmpty;

  /// No description provided for @shellNavHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get shellNavHome;

  /// No description provided for @shellNavPractice.
  ///
  /// In zh, this message translates to:
  /// **'开始练习'**
  String get shellNavPractice;

  /// No description provided for @shellNavPaper.
  ///
  /// In zh, this message translates to:
  /// **'试卷模式'**
  String get shellNavPaper;

  /// No description provided for @shellNavHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史试卷'**
  String get shellNavHistory;

  /// No description provided for @shellNavCollection.
  ///
  /// In zh, this message translates to:
  /// **'错题/收藏'**
  String get shellNavCollection;

  /// No description provided for @shellNavBank.
  ///
  /// In zh, this message translates to:
  /// **'题库管理'**
  String get shellNavBank;

  /// No description provided for @shellNavStats.
  ///
  /// In zh, this message translates to:
  /// **'统计'**
  String get shellNavStats;

  /// No description provided for @shellNavSync.
  ///
  /// In zh, this message translates to:
  /// **'同步与备份'**
  String get shellNavSync;

  /// No description provided for @shellNavSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get shellNavSettings;

  /// No description provided for @shellTabPractice.
  ///
  /// In zh, this message translates to:
  /// **'练习'**
  String get shellTabPractice;

  /// No description provided for @shellTabPaper.
  ///
  /// In zh, this message translates to:
  /// **'试卷'**
  String get shellTabPaper;

  /// No description provided for @shellTabHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史'**
  String get shellTabHistory;

  /// No description provided for @shellTabMore.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get shellTabMore;

  /// No description provided for @shellSheetCollection.
  ///
  /// In zh, this message translates to:
  /// **'错题 / 收藏'**
  String get shellSheetCollection;

  /// No description provided for @shellSheetBank.
  ///
  /// In zh, this message translates to:
  /// **'题库'**
  String get shellSheetBank;

  /// No description provided for @errImportBlockedUnsupportedFileType.
  ///
  /// In zh, this message translates to:
  /// **'仅支持 .zip、.tsv 或 .csv 题库文件'**
  String get errImportBlockedUnsupportedFileType;

  /// No description provided for @errImportBlockedZipUnparsable.
  ///
  /// In zh, this message translates to:
  /// **'ZIP 无法解析：{error}'**
  String errImportBlockedZipUnparsable(String error);

  /// No description provided for @errImportBlockedMissingManifest.
  ///
  /// In zh, this message translates to:
  /// **'缺少 manifest.json'**
  String get errImportBlockedMissingManifest;

  /// No description provided for @errImportBlockedMissingQuestions.
  ///
  /// In zh, this message translates to:
  /// **'缺少 questions.jsonl'**
  String get errImportBlockedMissingQuestions;

  /// No description provided for @errImportBlockedManifestUnparsable.
  ///
  /// In zh, this message translates to:
  /// **'manifest.json 无法解析：{error}'**
  String errImportBlockedManifestUnparsable(String error);

  /// No description provided for @errImportBlockedUnsupportedSchemaVersion.
  ///
  /// In zh, this message translates to:
  /// **'不支持 schema_version={version}'**
  String errImportBlockedUnsupportedSchemaVersion(String version);

  /// No description provided for @errImportBlockedInvalidBankId.
  ///
  /// In zh, this message translates to:
  /// **'bank_id 包含无效目录字符'**
  String get errImportBlockedInvalidBankId;

  /// No description provided for @errImportBlockedInvalidBankMetadata.
  ///
  /// In zh, this message translates to:
  /// **'题库 ID、名称或内容版本无效'**
  String get errImportBlockedInvalidBankMetadata;

  /// No description provided for @errImportBlockedQuestionsHashMismatch.
  ///
  /// In zh, this message translates to:
  /// **'questions.jsonl 的 SHA-256 与清单不一致'**
  String get errImportBlockedQuestionsHashMismatch;

  /// No description provided for @errImportBlockedEmptyQuestionId.
  ///
  /// In zh, this message translates to:
  /// **'第 {line} 行 question_id 为空'**
  String errImportBlockedEmptyQuestionId(int line);

  /// No description provided for @errImportBlockedDupQuestionId.
  ///
  /// In zh, this message translates to:
  /// **'重复 question_id：{id}'**
  String errImportBlockedDupQuestionId(String id);

  /// No description provided for @errImportBlockedInvalidQuestionType.
  ///
  /// In zh, this message translates to:
  /// **'{id} 的题型无效：{type}'**
  String errImportBlockedInvalidQuestionType(String id, String type);

  /// No description provided for @errImportBlockedEmptyStem.
  ///
  /// In zh, this message translates to:
  /// **'{id} 的题干为空'**
  String errImportBlockedEmptyStem(String id);

  /// No description provided for @errImportBlockedTooFewOptions.
  ///
  /// In zh, this message translates to:
  /// **'{id} 少于两个有效选项'**
  String errImportBlockedTooFewOptions(String id);

  /// No description provided for @errImportBlockedAnswerNotInOptions.
  ///
  /// In zh, this message translates to:
  /// **'{id} 的答案不在有效选项中'**
  String errImportBlockedAnswerNotInOptions(String id);

  /// No description provided for @errImportBlockedSingleAnswerCount.
  ///
  /// In zh, this message translates to:
  /// **'{id} 是单选题但答案数量不是 1'**
  String errImportBlockedSingleAnswerCount(String id);

  /// No description provided for @errImportBlockedMissingMedia.
  ///
  /// In zh, this message translates to:
  /// **'{id} 声明的媒体不存在：{path}'**
  String errImportBlockedMissingMedia(String id, String path);

  /// No description provided for @errImportBlockedQuestionLineUnparsable.
  ///
  /// In zh, this message translates to:
  /// **'questions.jsonl 第 {line} 行无法解析：{error}'**
  String errImportBlockedQuestionLineUnparsable(int line, String error);

  /// No description provided for @errImportBlockedQuestionCountMismatch.
  ///
  /// In zh, this message translates to:
  /// **'清单题量 {declared} 与实际 {actual} 不一致'**
  String errImportBlockedQuestionCountMismatch(String declared, int actual);

  /// No description provided for @errImportBlockedMediaHashMismatch.
  ///
  /// In zh, this message translates to:
  /// **'媒体哈希不匹配：{path}'**
  String errImportBlockedMediaHashMismatch(String path);

  /// No description provided for @errImportBlockedInvalidUtf8.
  ///
  /// In zh, this message translates to:
  /// **'文件不是有效的 UTF-8：{error}'**
  String errImportBlockedInvalidUtf8(String error);

  /// No description provided for @errImportBlockedDelimitedUnparsable.
  ///
  /// In zh, this message translates to:
  /// **'分隔文件无法解析：{error}'**
  String errImportBlockedDelimitedUnparsable(String error);

  /// No description provided for @errImportBlockedEmptyFile.
  ///
  /// In zh, this message translates to:
  /// **'文件缺少表头和题目'**
  String get errImportBlockedEmptyFile;

  /// No description provided for @errImportBlockedInvalidContentVersion.
  ///
  /// In zh, this message translates to:
  /// **'题库内容版本无效：{version}'**
  String errImportBlockedInvalidContentVersion(String version);

  /// No description provided for @errImportBlockedDupHeader.
  ///
  /// In zh, this message translates to:
  /// **'存在重复表头：{header}'**
  String errImportBlockedDupHeader(String header);

  /// No description provided for @errImportBlockedMissingColumn.
  ///
  /// In zh, this message translates to:
  /// **'缺少必需列：{column}'**
  String errImportBlockedMissingColumn(String column);

  /// No description provided for @errImportBlockedRowColumnMismatch.
  ///
  /// In zh, this message translates to:
  /// **'第 {line} 行有 {actual} 列，表头有 {expected} 列'**
  String errImportBlockedRowColumnMismatch(int line, int actual, int expected);

  /// No description provided for @errImportBlockedEmptyExternalId.
  ///
  /// In zh, this message translates to:
  /// **'第 {line} 行编号为空'**
  String errImportBlockedEmptyExternalId(int line);

  /// No description provided for @errImportBlockedDupExplicitId.
  ///
  /// In zh, this message translates to:
  /// **'重复题目 ID：{id}'**
  String errImportBlockedDupExplicitId(String id);

  /// No description provided for @errImportBlockedDupExternalId.
  ///
  /// In zh, this message translates to:
  /// **'重复编号：{externalId}'**
  String errImportBlockedDupExternalId(String externalId);

  /// No description provided for @errImportBlockedInvalidQuestionVersion.
  ///
  /// In zh, this message translates to:
  /// **'{id} 的题目版本无效'**
  String errImportBlockedInvalidQuestionVersion(String id);

  /// No description provided for @errImportBlockedNoValidQuestions.
  ///
  /// In zh, this message translates to:
  /// **'文件中没有有效题目行'**
  String get errImportBlockedNoValidQuestions;

  /// No description provided for @errImportWarningDupExternalId.
  ///
  /// In zh, this message translates to:
  /// **'重复 external_id：{externalId}'**
  String errImportWarningDupExternalId(String externalId);

  /// No description provided for @errImportWarningDupStem.
  ///
  /// In zh, this message translates to:
  /// **'存在相同题干：{externalId}'**
  String errImportWarningDupStem(String externalId);

  /// No description provided for @errImportWarningEmptyExplanation.
  ///
  /// In zh, this message translates to:
  /// **'{id} 的解析为空'**
  String errImportWarningEmptyExplanation(String id);

  /// No description provided for @errImportWarningIncompleteMetadata.
  ///
  /// In zh, this message translates to:
  /// **'{id} 的年份、章节或来源不完整'**
  String errImportWarningIncompleteMetadata(String id);

  /// No description provided for @errImportWarningBankNameFallback.
  ///
  /// In zh, this message translates to:
  /// **'未提供题库名称，已使用文件名“{name}”'**
  String errImportWarningBankNameFallback(String name);

  /// No description provided for @errImportWarningGeneratedBankId.
  ///
  /// In zh, this message translates to:
  /// **'未提供 bank_id，已按题库名称和科目生成稳定 ID；以后更新时不要改变这两项'**
  String get errImportWarningGeneratedBankId;

  /// No description provided for @errOmrPlatformUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'答题卡阅卷仅支持 Windows'**
  String get errOmrPlatformUnsupported;

  /// No description provided for @errOmrImageFormatUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'仅支持 PNG/JPG/JPEG：{path}'**
  String errOmrImageFormatUnsupported(String path);

  /// No description provided for @errOmrExecutableMissing.
  ///
  /// In zh, this message translates to:
  /// **'缺少随程序发布的阅卷组件：{path}'**
  String errOmrExecutableMissing(String path);

  /// No description provided for @errOmrRecognizeTimeout.
  ///
  /// In zh, this message translates to:
  /// **'答题卡识别超时'**
  String get errOmrRecognizeTimeout;

  /// No description provided for @errOmrBridgeExitCode.
  ///
  /// In zh, this message translates to:
  /// **'阅卷组件退出码 {exitCode}：{stderr}'**
  String errOmrBridgeExitCode(int exitCode, String stderr);

  /// No description provided for @errOmrBridgeNoResult.
  ///
  /// In zh, this message translates to:
  /// **'阅卷组件未生成结构化结果：{stdout}'**
  String errOmrBridgeNoResult(String stdout);

  /// No description provided for @errOmrResultVersionInvalid.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果版本无效'**
  String get errOmrResultVersionInvalid;

  /// No description provided for @errOmrResultSourceSizeInvalid.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果原图尺寸无效'**
  String get errOmrResultSourceSizeInvalid;

  /// No description provided for @errOmrResultQuadInvalid.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果 {field} 无效'**
  String errOmrResultQuadInvalid(String field);

  /// No description provided for @errOmrResultQuadOutOfRange.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果 {field} 越界'**
  String errOmrResultQuadOutOfRange(String field);

  /// No description provided for @errOmrResultQuestionCountMismatch.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果题目数量不匹配'**
  String get errOmrResultQuestionCountMismatch;

  /// No description provided for @errOmrResultQuestionFormatInvalid.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果题目格式无效'**
  String get errOmrResultQuestionFormatInvalid;

  /// No description provided for @errOmrResultLabelInvalid.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果标签无效：{label}'**
  String errOmrResultLabelInvalid(String label);

  /// No description provided for @errOmrResultOptionsFormatInvalid.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果选项格式无效'**
  String get errOmrResultOptionsFormatInvalid;

  /// No description provided for @errOmrResultOptionsOutOfRange.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果选项越界'**
  String get errOmrResultOptionsOutOfRange;

  /// No description provided for @errOmrResultConfidenceInvalid.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果置信度无效'**
  String get errOmrResultConfidenceInvalid;

  /// No description provided for @errOmrResultBubblesInvalid.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果气泡几何无效'**
  String get errOmrResultBubblesInvalid;

  /// No description provided for @errOmrResultLabelsIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'阅卷结果标签不完整'**
  String get errOmrResultLabelsIncomplete;

  /// No description provided for @errSyncDone.
  ///
  /// In zh, this message translates to:
  /// **'同步完成：上传 {uploaded} 项，拉取 {downloaded} 项'**
  String errSyncDone(int uploaded, int downloaded);

  /// No description provided for @errSyncPartial.
  ///
  /// In zh, this message translates to:
  /// **'已上传 {uploaded} 项、拉取 {downloaded} 项；{failed} 项未获确认，{deferred} 项等待题库依赖'**
  String errSyncPartial(int uploaded, int downloaded, int failed, int deferred);

  /// No description provided for @errSyncTimeout.
  ///
  /// In zh, this message translates to:
  /// **'同步超时，本地数据和同步队列均已保留'**
  String get errSyncTimeout;

  /// No description provided for @errSyncFailed.
  ///
  /// In zh, this message translates to:
  /// **'同步失败，本地数据安全：{error}'**
  String errSyncFailed(String error);

  /// No description provided for @errSyncNotLoggedIn.
  ///
  /// In zh, this message translates to:
  /// **'尚未登录 Supabase 个人账号'**
  String get errSyncNotLoggedIn;

  /// No description provided for @errSyncSessionRefreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'会话刷新失败，本地数据安全：{error}'**
  String errSyncSessionRefreshFailed(String error);

  /// No description provided for @errSyncMissingCloudConfig.
  ///
  /// In zh, this message translates to:
  /// **'请填写 Supabase 项目 URL、Publishable Key 并登录'**
  String get errSyncMissingCloudConfig;

  /// No description provided for @errSyncMissingAccountConfig.
  ///
  /// In zh, this message translates to:
  /// **'请填写 Supabase 项目 URL、Publishable Key、邮箱和密码'**
  String get errSyncMissingAccountConfig;

  /// No description provided for @errAnswerNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'请先选择答案'**
  String get errAnswerNotSelected;

  /// No description provided for @errPracticeEmptyScope.
  ///
  /// In zh, this message translates to:
  /// **'当前筛选范围没有可用题目'**
  String get errPracticeEmptyScope;

  /// No description provided for @errBankNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'请先选择题库'**
  String get errBankNotSelected;

  /// No description provided for @errStorageTargetDirNotEmpty.
  ///
  /// In zh, this message translates to:
  /// **'目标目录已有 personal_exam.sqlite，请选择空目录，避免覆盖原数据库'**
  String get errStorageTargetDirNotEmpty;

  /// No description provided for @errStorageIntegrityCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'新数据库完整性检查失败：{integrity}'**
  String errStorageIntegrityCheckFailed(String integrity);

  /// No description provided for @exportPaperFileName.
  ///
  /// In zh, this message translates to:
  /// **'试卷'**
  String get exportPaperFileName;

  /// No description provided for @exportAnswersFileName.
  ///
  /// In zh, this message translates to:
  /// **'答案与解析'**
  String get exportAnswersFileName;

  /// No description provided for @exportReviewFileName.
  ///
  /// In zh, this message translates to:
  /// **'作答回顾'**
  String get exportReviewFileName;

  /// No description provided for @exportAnswerSheetFileName.
  ///
  /// In zh, this message translates to:
  /// **'答题卡'**
  String get exportAnswerSheetFileName;

  /// No description provided for @exportResourcesFolderName.
  ///
  /// In zh, this message translates to:
  /// **'资源'**
  String get exportResourcesFolderName;

  /// No description provided for @exportAnswersYamlSuffix.
  ///
  /// In zh, this message translates to:
  /// **'（答案与解析）'**
  String get exportAnswersYamlSuffix;

  /// No description provided for @exportAnswersHeadingSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 答案与解析'**
  String get exportAnswersHeadingSuffix;

  /// No description provided for @exportReviewYamlSuffix.
  ///
  /// In zh, this message translates to:
  /// **'（作答回顾）'**
  String get exportReviewYamlSuffix;

  /// No description provided for @exportReviewHeadingSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 作答回顾'**
  String get exportReviewHeadingSuffix;

  /// No description provided for @exportPaperStatsLine.
  ///
  /// In zh, this message translates to:
  /// **'题量：{count}　建议用时：{minutes} 分钟'**
  String exportPaperStatsLine(String count, String minutes);

  /// No description provided for @exportMultipleChoiceTag.
  ///
  /// In zh, this message translates to:
  /// **'【多选】'**
  String get exportMultipleChoiceTag;

  /// No description provided for @exportSingleChoiceTag.
  ///
  /// In zh, this message translates to:
  /// **'【单选】'**
  String get exportSingleChoiceTag;

  /// No description provided for @exportMissingMediaWarning.
  ///
  /// In zh, this message translates to:
  /// **'> [!warning] 题目图片缺失：{path}'**
  String exportMissingMediaWarning(String path);

  /// No description provided for @exportCorrectAnswersBoldLine.
  ///
  /// In zh, this message translates to:
  /// **'**正确答案：{answers}**'**
  String exportCorrectAnswersBoldLine(String answers);

  /// No description provided for @exportExplanationLine.
  ///
  /// In zh, this message translates to:
  /// **'解析：{explanation}'**
  String exportExplanationLine(String explanation);

  /// No description provided for @exportKnowledgePointSourceLine.
  ///
  /// In zh, this message translates to:
  /// **'考点：{knowledgePoint}　来源：{source}'**
  String exportKnowledgePointSourceLine(String knowledgePoint, String source);

  /// No description provided for @exportReviewScoreLine.
  ///
  /// In zh, this message translates to:
  /// **'得分：{score} / {max}'**
  String exportReviewScoreLine(String score, String max);

  /// No description provided for @exportTotalDurationLine.
  ///
  /// In zh, this message translates to:
  /// **'总用时：{duration}'**
  String exportTotalDurationLine(String duration);

  /// No description provided for @exportOvertimeLine.
  ///
  /// In zh, this message translates to:
  /// **'超时：{duration}'**
  String exportOvertimeLine(String duration);

  /// No description provided for @exportUnansweredCountLine.
  ///
  /// In zh, this message translates to:
  /// **'未答：{count} 题'**
  String exportUnansweredCountLine(String count);

  /// No description provided for @exportUnansweredStatus.
  ///
  /// In zh, this message translates to:
  /// **'未答'**
  String get exportUnansweredStatus;

  /// No description provided for @exportFullyCorrectStatus.
  ///
  /// In zh, this message translates to:
  /// **'完全正确'**
  String get exportFullyCorrectStatus;

  /// No description provided for @exportWrongStatus.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get exportWrongStatus;

  /// No description provided for @exportVerdictLine.
  ///
  /// In zh, this message translates to:
  /// **'判定：{status}'**
  String exportVerdictLine(String status);

  /// No description provided for @exportUserSelectionLine.
  ///
  /// In zh, this message translates to:
  /// **'用户选择：{answers}'**
  String exportUserSelectionLine(String answers);

  /// No description provided for @exportCorrectAnswerLine.
  ///
  /// In zh, this message translates to:
  /// **'正确答案：{answers}'**
  String exportCorrectAnswerLine(String answers);

  /// No description provided for @exportQuestionDurationLine.
  ///
  /// In zh, this message translates to:
  /// **'本题交互估计用时：{duration}'**
  String exportQuestionDurationLine(String duration);

  /// No description provided for @exportFavoriteUncertainLine.
  ///
  /// In zh, this message translates to:
  /// **'收藏：{favorite}；不确定：{uncertain}'**
  String exportFavoriteUncertainLine(String favorite, String uncertain);

  /// No description provided for @exportYesLabel.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get exportYesLabel;

  /// No description provided for @exportNoLabel.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get exportNoLabel;

  /// No description provided for @exportPersonalNoteLine.
  ///
  /// In zh, this message translates to:
  /// **'个人笔记：{note}'**
  String exportPersonalNoteLine(String note);

  /// No description provided for @exportEmptyNoteValue.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get exportEmptyNoteValue;

  /// No description provided for @exportKnowledgePointSourceReviewLine.
  ///
  /// In zh, this message translates to:
  /// **'考点：{knowledgePoint}；来源：{source}'**
  String exportKnowledgePointSourceReviewLine(
    String knowledgePoint,
    String source,
  );

  /// No description provided for @exportAnswerSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get exportAnswerSeparator;

  /// No description provided for @exportAnswerSheetYamlSuffix.
  ///
  /// In zh, this message translates to:
  /// **'（答题卡）'**
  String get exportAnswerSheetYamlSuffix;

  /// No description provided for @exportAnswerSheetHeadingSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 答题卡'**
  String get exportAnswerSheetHeadingSuffix;

  /// No description provided for @exportAnswerSheetStatsLine.
  ///
  /// In zh, this message translates to:
  /// **'个人练习专用　共 {count} 题　单选 {single} 题　多选 {multiple} 题'**
  String exportAnswerSheetStatsLine(
    String count,
    String single,
    String multiple,
  );

  /// No description provided for @exportAnswerSheetQrAlt.
  ///
  /// In zh, this message translates to:
  /// **'答题卡二维码'**
  String get exportAnswerSheetQrAlt;

  /// No description provided for @exportFillNoteHtml.
  ///
  /// In zh, this message translates to:
  /// **'<strong>填涂说明：</strong>将所选圆圈完整涂黑；多选题可涂多个选项。修改时请擦净，无法擦净时重新打印。'**
  String get exportFillNoteHtml;

  /// No description provided for @exportAnswerSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择题答题区'**
  String get exportAnswerSectionTitle;

  /// No description provided for @exportAnswerSectionHint.
  ///
  /// In zh, this message translates to:
  /// **'请按试卷题号顺序填涂'**
  String get exportAnswerSectionHint;

  /// No description provided for @exportQuestionNumberHeader.
  ///
  /// In zh, this message translates to:
  /// **'题号'**
  String get exportQuestionNumberHeader;

  /// No description provided for @exportWrongQuestionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'当前错题'**
  String get exportWrongQuestionsTitle;

  /// No description provided for @exportRecentSelectionLine.
  ///
  /// In zh, this message translates to:
  /// **'最近选择：{answers}'**
  String exportRecentSelectionLine(String answers);

  /// No description provided for @exportKnowledgePointLine.
  ///
  /// In zh, this message translates to:
  /// **'考点：{knowledgePoint}'**
  String exportKnowledgePointLine(String knowledgePoint);

  /// No description provided for @exportSourceLine.
  ///
  /// In zh, this message translates to:
  /// **'来源：{source}'**
  String exportSourceLine(String source);

  /// No description provided for @exportAttemptStatsLine.
  ///
  /// In zh, this message translates to:
  /// **'累计作答：{seen} 次；答错：{wrong} 次'**
  String exportAttemptStatsLine(String seen, String wrong);

  /// No description provided for @settingsDevVersion.
  ///
  /// In zh, this message translates to:
  /// **'开发版'**
  String get settingsDevVersion;

  /// No description provided for @questionTypeQa.
  ///
  /// In zh, this message translates to:
  /// **'问答题'**
  String get questionTypeQa;

  /// No description provided for @questionTypeQaShort.
  ///
  /// In zh, this message translates to:
  /// **'问答'**
  String get questionTypeQaShort;

  /// No description provided for @questionEditQaAnswerLabel.
  ///
  /// In zh, this message translates to:
  /// **'参考答案（可留空）'**
  String get questionEditQaAnswerLabel;

  /// No description provided for @questionQaAnswerLabel.
  ///
  /// In zh, this message translates to:
  /// **'作答区'**
  String get questionQaAnswerLabel;

  /// No description provided for @questionQaReferenceLabel.
  ///
  /// In zh, this message translates to:
  /// **'参考答案'**
  String get questionQaReferenceLabel;

  /// No description provided for @questionQaReferenceEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未提供参考答案'**
  String get questionQaReferenceEmpty;

  /// No description provided for @paperExportLayoutTitle.
  ///
  /// In zh, this message translates to:
  /// **'试卷排版'**
  String get paperExportLayoutTitle;

  /// No description provided for @paperExportLayoutA4.
  ///
  /// In zh, this message translates to:
  /// **'A4'**
  String get paperExportLayoutA4;

  /// No description provided for @paperExportLayoutA3.
  ///
  /// In zh, this message translates to:
  /// **'A3'**
  String get paperExportLayoutA3;

  /// No description provided for @paperExportLayoutHint.
  ///
  /// In zh, this message translates to:
  /// **'答题卡始终为 A4；选择 A3 时试卷文档与答题卡分别输出两个 PDF。'**
  String get paperExportLayoutHint;

  /// No description provided for @paperTypeCountsTitle.
  ///
  /// In zh, this message translates to:
  /// **'各题型数量（考试模式）'**
  String get paperTypeCountsTitle;

  /// No description provided for @paperTypeCountsSingle.
  ///
  /// In zh, this message translates to:
  /// **'单选题'**
  String get paperTypeCountsSingle;

  /// No description provided for @paperTypeCountsMultiple.
  ///
  /// In zh, this message translates to:
  /// **'多选题'**
  String get paperTypeCountsMultiple;

  /// No description provided for @paperTypeCountsQa.
  ///
  /// In zh, this message translates to:
  /// **'问答题'**
  String get paperTypeCountsQa;

  /// No description provided for @paperTypeCountsHint.
  ///
  /// In zh, this message translates to:
  /// **'库存不足的题型按现有数量组卷；问答题不计分。'**
  String get paperTypeCountsHint;

  /// No description provided for @settingsScoringTitle.
  ///
  /// In zh, this message translates to:
  /// **'试卷判分规则'**
  String get settingsScoringTitle;

  /// No description provided for @settingsScoringHint.
  ///
  /// In zh, this message translates to:
  /// **'仅对新试卷生效；已交试卷保持组卷时的规则。'**
  String get settingsScoringHint;

  /// No description provided for @settingsScoringSingleScore.
  ///
  /// In zh, this message translates to:
  /// **'单选每题分值：{score}'**
  String settingsScoringSingleScore(String score);

  /// No description provided for @settingsScoringMultipleScore.
  ///
  /// In zh, this message translates to:
  /// **'多选每题分值：{score}'**
  String settingsScoringMultipleScore(String score);

  /// No description provided for @settingsScoringPartialCredit.
  ///
  /// In zh, this message translates to:
  /// **'多选少选给部分分'**
  String get settingsScoringPartialCredit;

  /// No description provided for @settingsScoringPerOption.
  ///
  /// In zh, this message translates to:
  /// **'每个正确项分值：{score}'**
  String settingsScoringPerOption(String score);

  /// No description provided for @settingsScoringWrongZero.
  ///
  /// In zh, this message translates to:
  /// **'有错项整题零分'**
  String get settingsScoringWrongZero;

  /// No description provided for @settingsScoringQaNote.
  ///
  /// In zh, this message translates to:
  /// **'问答题不判分，不计入总分。'**
  String get settingsScoringQaNote;

  /// No description provided for @omrQuestionTypeQa.
  ///
  /// In zh, this message translates to:
  /// **'问答'**
  String get omrQuestionTypeQa;

  /// No description provided for @omrQaAnswerHint.
  ///
  /// In zh, this message translates to:
  /// **'问答题无法机读，可在此手工录入作答文本（可留空）'**
  String get omrQaAnswerHint;

  /// No description provided for @omrQaSheetNote.
  ///
  /// In zh, this message translates to:
  /// **'答题卡气泡仅覆盖选择题（行首为试卷题号）；问答题在气泡表下方作答。'**
  String get omrQaSheetNote;

  /// No description provided for @errImportBlockedQaWithOptions.
  ///
  /// In zh, this message translates to:
  /// **'{id} 是问答题但填写了选项'**
  String errImportBlockedQaWithOptions(String id);

  /// No description provided for @errExportSheetNeedsChoice.
  ///
  /// In zh, this message translates to:
  /// **'答题卡需要至少一道单选或多选题'**
  String get errExportSheetNeedsChoice;

  /// No description provided for @exportQaTag.
  ///
  /// In zh, this message translates to:
  /// **'【问答】'**
  String get exportQaTag;

  /// No description provided for @exportQaReferenceAnswerLine.
  ///
  /// In zh, this message translates to:
  /// **'参考答案：{answer}'**
  String exportQaReferenceAnswerLine(String answer);

  /// No description provided for @exportQaEmptyReferenceAnswer.
  ///
  /// In zh, this message translates to:
  /// **'（未提供参考答案）'**
  String get exportQaEmptyReferenceAnswer;

  /// No description provided for @exportQaUserAnswerLine.
  ///
  /// In zh, this message translates to:
  /// **'用户作答：{answer}'**
  String exportQaUserAnswerLine(String answer);

  /// No description provided for @exportQaUnansweredText.
  ///
  /// In zh, this message translates to:
  /// **'未作答'**
  String get exportQaUnansweredText;

  /// No description provided for @exportAnswerSheetQaSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'问答题答题区'**
  String get exportAnswerSheetQaSectionTitle;

  /// No description provided for @exportAnswerSheetQaItemLabel.
  ///
  /// In zh, this message translates to:
  /// **'第 {number} 题'**
  String exportAnswerSheetQaItemLabel(String number);

  /// No description provided for @exportAnswerSheetQaOverflowNote.
  ///
  /// In zh, this message translates to:
  /// **'其余问答题答题区不足，请直接在试卷上作答'**
  String get exportAnswerSheetQaOverflowNote;

  /// No description provided for @exportAnswerSheetQaStatsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'　问答 {qa} 题'**
  String exportAnswerSheetQaStatsSuffix(String qa);

  /// No description provided for @omrGradingDone.
  ///
  /// In zh, this message translates to:
  /// **'判卷完成'**
  String get omrGradingDone;

  /// No description provided for @omrGradingDoneBody.
  ///
  /// In zh, this message translates to:
  /// **'答题卡成绩已写入试卷，可在下方逐题核对；问答题为人工录入结果。'**
  String get omrGradingDoneBody;

  /// No description provided for @omrBackToPaper.
  ///
  /// In zh, this message translates to:
  /// **'返回试卷'**
  String get omrBackToPaper;

  /// No description provided for @settingsRenderMarkupTitle.
  ///
  /// In zh, this message translates to:
  /// **'渲染题目排版标记'**
  String get settingsRenderMarkupTitle;

  /// No description provided for @settingsRenderMarkupDesc.
  ///
  /// In zh, this message translates to:
  /// **'将题干、选项与解析中的 <p>、<br> 等标记转换为换行等排版；关闭时界面剥离标记、导出原样保留。'**
  String get settingsRenderMarkupDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
