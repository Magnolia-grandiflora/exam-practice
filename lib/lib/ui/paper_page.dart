import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_theme.dart';
import 'export_labels.dart';
import 'question_widgets.dart';
import 'windows_omr_review_page.dart';

class PaperPage extends StatefulWidget {
  const PaperPage({
    super.key,
    required this.controller,
    required this.attempt,
    this.recognize,
    this.pickImage,
  });
  final AppController controller;
  final PaperAttempt attempt;

  /// 测试注入的识别回调；生产为 null（使用真实 sidecar 桥接）。
  final WindowsOmrRecognizer? recognize;

  /// 测试注入的取图回调；生产为 null（使用文件选择器）。
  final Future<File?> Function()? pickImage;
  @override
  State<PaperPage> createState() => _PaperPageState();
}

class _PaperPageState extends State<PaperPage> with WidgetsBindingObserver {
  final scrollController = ScrollController();
  late final PageController pageController;
  late final List<GlobalKey> questionKeys;
  Timer? timer;
  Timer? _qaSaveDebounce;
  late DateTime lastTick;
  /// 计时仅在页面打开且应用处于前台时累计；离页/最小化暂停。
  bool _counting = true;
  int saveTicks = 0;
  bool navigatorCollapsed = false;
  bool confirmingDesktopSubmit = false;
  bool isSubmitting = false;
  PaperAttempt get attempt => widget.attempt;
  bool get submitted => attempt.status == AttemptStatus.submitted;

  /// State 内统一取词入口：State 的 context 在所有 build 路径方法中都有效。
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pageController = PageController(initialPage: attempt.currentIndex);
    questionKeys = List.generate(attempt.questions.length, (_) => GlobalKey());
    lastTick = DateTime.now();
    if (!submitted) {
      _startTimer();
    }
  }

  void _startTimer() {
    timer?.cancel();
    lastTick = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final delta = now.difference(lastTick).inMilliseconds.clamp(0, 60000);
    lastTick = now;
    if (!submitted && !isSubmitting && _counting && attempt.questions.isNotEmpty) {
      // 整卷时间为打开页面期间的真实累计时长，而不是组卷时刻起的墙钟时间：
      // 关闭页面或最小化即暂停，重新打开后从已累计时长继续。
      attempt.durationMs += delta;
      attempt.questions[attempt.currentIndex].durationMs += delta;
      saveTicks++;
      if (saveTicks >= 5) {
        saveTicks = 0;
        widget.controller.savePaper(attempt);
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _setCounting(state == AppLifecycleState.resumed);
    if (!submitted && !isSubmitting && state != AppLifecycleState.resumed) {
      widget.controller.savePaper(attempt);
    }
    lastTick = DateTime.now();
  }

  void _setCounting(bool value) {
    if (_counting == value) return;
    _counting = value;
    lastTick = DateTime.now();
  }

  @override
  void dispose() {
    timer?.cancel();
    _qaSaveDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (!submitted && !isSubmitting) widget.controller.savePaper(attempt);
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void _toggle(int index, String option) {
    if (submitted || isSubmitting) return;
    setState(() {
      attempt.currentIndex = index;
      final state = attempt.questions[index];
      if (state.question.type == QuestionType.single) {
        state.selected
          ..clear()
          ..add(option);
      } else if (!state.selected.remove(option)) {
        state.selected.add(option);
      }
    });
    widget.controller.savePaper(attempt);
  }

  /// 问答题作答文本写入 selected（单元素集合，原样保存）。
  /// 输入是连续事件：内存即时更新，落库做 800ms 防抖（导航/交卷时已有落库点）。
  void _setQaAnswer(int index, String text) {
    if (submitted || isSubmitting) return;
    final state = attempt.questions[index];
    if (state.question.type != QuestionType.qa) return;
    state.selected
      ..clear()
      ..add(text);
    _qaSaveDebounce?.cancel();
    _qaSaveDebounce = Timer(const Duration(milliseconds: 800), () {
      widget.controller.savePaper(attempt);
    });
  }

  void _goTo(int index) {
    if (isSubmitting) return;
    setState(() => attempt.currentIndex = index);
    if (pageController.hasClients) {
      pageController.jumpToPage(index);
      widget.controller.savePaper(attempt);
      return;
    }
    if (!scrollController.hasClients) return;
    final target = questionKeys[index].currentContext?.findRenderObject();
    if (target != null) {
      scrollController.position.ensureVisible(
        target,
        alignment: 0,
        duration: Duration.zero,
      );
    }
    widget.controller.savePaper(attempt);
  }

  void _syncCurrentQuestionFromScroll(ScrollMetrics metrics) {
    if (!scrollController.hasClients || questionKeys.isEmpty) return;
    var visibleIndex = 0;
    if (metrics.pixels >= metrics.maxScrollExtent - 1) {
      visibleIndex = questionKeys.length - 1;
    } else {
      for (var index = 0; index < questionKeys.length; index++) {
        final renderObject = questionKeys[index].currentContext
            ?.findRenderObject();
        if (renderObject == null || !renderObject.attached) continue;
        final viewport = RenderAbstractViewport.of(renderObject);
        final itemOffset = viewport.getOffsetToReveal(renderObject, 0).offset;
        if (itemOffset <= metrics.pixels + 1) {
          visibleIndex = index;
        } else {
          break;
        }
      }
    }
    if (visibleIndex != attempt.currentIndex) {
      setState(() => attempt.currentIndex = visibleIndex);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (submitted || isSubmitting || event is! KeyDownEvent || _editingText()) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey.keyLabel.toUpperCase();
    final q = attempt.questions[attempt.currentIndex].question;
    if ('ABCDE'.contains(key) &&
        key.length == 1 &&
        q.options.containsKey(key)) {
      _toggle(attempt.currentIndex, key);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goTo((attempt.currentIndex - 1).clamp(0, attempt.questions.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goTo((attempt.currentIndex + 1).clamp(0, attempt.questions.length - 1));
      return KeyEventResult.handled;
    }
    if (key == 'M') {
      setState(
        () => attempt.questions[attempt.currentIndex].uncertain =
            !attempt.questions[attempt.currentIndex].uncertain,
      );
      widget.controller.savePaper(attempt);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _editingText() {
    final focus = FocusManager.instance.primaryFocus;
    return focus?.context?.widget is EditableText ||
        focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !isSubmitting,
    onPopInvokedWithResult: (didPop, result) {
      if (!submitted && !isSubmitting) widget.controller.savePaper(attempt);
    },
    child:
        (MediaQuery.sizeOf(context).width < 720 ||
            MediaQuery.sizeOf(context).shortestSide < 600)
        ? _mobileScaffold()
        : Scaffold(
            appBar: AppBar(
              title: Text(attempt.title),
              actions: [
                _HeaderStatus(
                  icon: Icons.check_box_outlined,
                  text: _l10n.paperHeaderAnswered(
                    attempt.answeredCount,
                    attempt.questions.length,
                  ),
                ),
                _HeaderStatus(
                  icon: Icons.timer_outlined,
                  text: formatDuration(attempt.durationMs),
                  color: attempt.overtimeMs > 0 ? Colors.orange : null,
                ),
                if (attempt.suggestedDurationMs > 0)
                  _HeaderStatus(
                    icon: Icons.flag_outlined,
                    text: _l10n.paperHeaderSuggested(
                      formatDuration(attempt.suggestedDurationMs),
                    ),
                  ),
                IconButton(
                  tooltip: submitted
                      ? _l10n.paperExportTooltipSubmitted
                      : _l10n.paperExportTooltipDraft,
                  icon: const Icon(Icons.download_outlined),
                  onPressed: _export,
                ),
                if (Theme.of(context).platform == TargetPlatform.windows &&
                    !submitted)
                  TextButton.icon(
                    key: const ValueKey('windows-omr-review-action'),
                    onPressed: _openWindowsOmrReview,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(_l10n.paperReadAnswerSheet),
                  ),
                if (Theme.of(context).platform == TargetPlatform.windows &&
                    submitted)
                  TextButton.icon(
                    key: const ValueKey('submitted-paper-edit-question-action'),
                    onPressed: _editSubmittedQuestion,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(_l10n.paperEditBankQuestion),
                  ),
                const SizedBox(width: 12),
              ],
            ),
            body: Focus(
              autofocus: true,
              onKeyEvent: _onKey,
              child: Row(
                children: [
                  if (!navigatorCollapsed)
                    SizedBox(width: 236, child: _numberNavigator()),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: navigatorCollapsed
                                    ? _l10n.paperNavigatorExpand
                                    : _l10n.paperNavigatorCollapse,
                                icon: Icon(
                                  navigatorCollapsed
                                      ? Icons.last_page
                                      : Icons.first_page,
                                ),
                                onPressed: () => setState(
                                  () =>
                                      navigatorCollapsed = !navigatorCollapsed,
                                ),
                              ),
                              _AnswerStateBadge(
                                answered: attempt
                                    .questions[attempt.currentIndex]
                                    .selected
                                    .isNotEmpty,
                                uncertain: attempt
                                    .questions[attempt.currentIndex]
                                    .uncertain,
                              ),
                              if (attempt.overtimeMs > 0)
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _l10n.paperOvertimeHint,
                                        style: const TextStyle(
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const Spacer(),
                              if (!submitted)
                                Text(
                                  _l10n.paperAutoSaved,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: widget.controller.contentWidth,
                              ),
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification
                                      is ScrollUpdateNotification) {
                                    _syncCurrentQuestionFromScroll(
                                      notification.metrics,
                                    );
                                  }
                                  return false;
                                },
                                child: SingleChildScrollView(
                                  key: const ValueKey('paper-question-scroll'),
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      for (
                                        var index = 0;
                                        index < attempt.questions.length;
                                        index++
                                      )
                                        GestureDetector(
                                          key: questionKeys[index],
                                          onTap: () => setState(
                                            () => attempt.currentIndex = index,
                                          ),
                                          child: KeyedSubtree(
                                            key: ValueKey(
                                              'paper-question-${index + 1}',
                                            ),
                                            child: QuestionCard(
                                              controller: widget.controller,
                                              question: attempt
                                                  .questions[index]
                                                  .question,
                                              number: index + 1,
                                              selected: attempt
                                                  .questions[index]
                                                  .selected,
                                              onToggle: (option) =>
                                                  _toggle(index, option),
                                              onQaTextChanged: (text) =>
                                                  _setQaAnswer(index, text),
                                              revealed: submitted,
                                              readOnly: submitted,
                                              uncertain: submitted
                                                  ? widget.controller.database
                                                        .progress(
                                                          attempt
                                                              .questions[index]
                                                              .question
                                                              .id,
                                                        )
                                                        .isUncertain
                                                  : attempt
                                                        .questions[index]
                                                        .uncertain,
                                              onUncertain: submitted
                                                  ? () => setState(() {
                                                      final question = attempt
                                                          .questions[index]
                                                          .question;
                                                      final current = widget
                                                          .controller
                                                          .database
                                                          .progress(question.id)
                                                          .isUncertain;
                                                      widget.controller
                                                          .updateMeta(
                                                            question,
                                                            uncertain: !current,
                                                          );
                                                    })
                                                  : () {
                                                      setState(() {
                                                        attempt.currentIndex =
                                                            index;
                                                        final state = attempt
                                                            .questions[index];
                                                        state.uncertain =
                                                            !state.uncertain;
                                                      });
                                                      widget.controller
                                                          .savePaper(attempt);
                                                    },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: submitted ? _resultBar() : _draftBar(),
          ),
  );

  Widget _mobileScaffold() {
    final state = attempt.questions[attempt.currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _l10n.paperMobileTitle(
            attempt.currentIndex + 1,
            attempt.questions.length,
          ),
        ),
        actions: [
          _HeaderStatus(
            icon: Icons.timer_outlined,
            text: formatDuration(attempt.durationMs),
            color: attempt.overtimeMs > 0 ? Colors.orange : null,
          ),
          IconButton(
            tooltip: _l10n.paperNumberPanelTooltip,
            onPressed: _showNumberPanel,
            icon: const Icon(Icons.grid_view_rounded),
          ),
          IconButton(
            tooltip: submitted
                ? _l10n.paperExportTooltipSubmitted
                : _l10n.paperExportTooltipDraft,
            onPressed: _export,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _AnswerStateBadge(
                      answered: state.selected.isNotEmpty,
                      uncertain: state.uncertain,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        attempt.overtimeMs > 0
                            ? _l10n.paperOvertimeHint
                            : _l10n.paperMobileAnsweredStatus(
                                attempt.answeredCount,
                                attempt.questions.length,
                              ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: attempt.questions.length,
                onPageChanged: (index) {
                  setState(() => attempt.currentIndex = index);
                  widget.controller.savePaper(attempt);
                },
                itemBuilder: (context, index) {
                  final item = attempt.questions[index];
                  return ListView(
                    key: PageStorageKey('paper-${attempt.attemptId}-$index'),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    children: [
                      QuestionCard(
                        controller: widget.controller,
                        question: item.question,
                        number: index + 1,
                        selected: item.selected,
                        onToggle: (option) => _toggle(index, option),
                        onQaTextChanged: (text) => _setQaAnswer(index, text),
                        revealed: submitted,
                        readOnly: submitted,
                        uncertain: submitted
                            ? widget.controller.database
                                  .progress(item.question.id)
                                  .isUncertain
                            : item.uncertain,
                        onUncertain: submitted
                            ? () => setState(() {
                                final current = widget.controller.database
                                    .progress(item.question.id)
                                    .isUncertain;
                                widget.controller.updateMeta(
                                  item.question,
                                  uncertain: !current,
                                );
                              })
                            : () {
                                setState(() {
                                  attempt.currentIndex = index;
                                  item.uncertain = !item.uncertain;
                                });
                                widget.controller.savePaper(attempt);
                              },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: submitted
          ? _mobileResultBar()
          : _mobileDraftBar(state),
    );
  }

  Widget _mobileDraftBar(PaperQuestionState state) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: attempt.currentIndex > 0
                      ? () => _goTo(attempt.currentIndex - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(_l10n.paperPrevQuestion),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: _l10n.paperNumberPanelTooltip,
                onPressed: _showNumberPanel,
                icon: const Icon(Icons.grid_view_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: attempt.currentIndex + 1 < attempt.questions.length
                      ? () => _goTo(attempt.currentIndex + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_l10n.paperNextQuestion),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => state.uncertain = !state.uncertain);
                    widget.controller.savePaper(attempt);
                  },
                  icon: Icon(
                    state.uncertain ? Icons.help : Icons.help_outline,
                    color: state.uncertain ? Colors.orange : null,
                  ),
                  label: Text(
                    state.uncertain
                        ? _l10n.paperUncertainMarked
                        : _l10n.paperUncertainMark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : _submit,
                  icon: isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.task_alt),
                  label: Text(
                    isSubmitting ? _l10n.paperSubmitting : _l10n.paperSubmit,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: _l10n.paperMoreActions,
                onSelected: (value) {
                  if (value == 'abandon') _abandon();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'abandon',
                    child: Text(_l10n.paperAbandonMenu),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _mobileResultBar() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _l10n.paperMobileResultSummary(
                _scoreSummary(),
                attempt.unansweredCount,
                formatDuration(attempt.durationMs),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.download),
            label: Text(_l10n.paperExportShort),
          ),
        ],
      ),
    ),
  );

  Future<void> _showNumberPanel() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.66,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                submitted
                    ? _submittedPanelTitle(_l10n)
                    : _l10n.paperNumberPanelDraftTitle(
                        attempt.answeredCount,
                        attempt.questions.length,
                      ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _legends(),
            ),
            const Divider(height: 22),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 58,
                  mainAxisSpacing: 7,
                  crossAxisSpacing: 7,
                ),
                itemCount: attempt.questions.length,
                itemBuilder: (context, index) => _NumberButton(
                  number: index + 1,
                  current: index == attempt.currentIndex,
                  answered: attempt.questions[index].selected.isNotEmpty,
                  uncertain: attempt.questions[index].uncertain,
                  correct: submitted
                      ? _verdict(attempt.questions[index])
                      : null,
                  onPressed: () => Navigator.pop(context, index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) _goTo(selected);
  }

  Widget _numberNavigator() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l10n.paperNumberNavigatorTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _legends(),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < attempt.questions.length; i++)
                  _NumberButton(
                    number: i + 1,
                    current: i == attempt.currentIndex,
                    answered: attempt.questions[i].selected.isNotEmpty,
                    uncertain: attempt.questions[i].uncertain,
                    correct: submitted ? _verdict(attempt.questions[i]) : null,
                    onPressed: () => _goTo(i),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  /// 已交卷时按判分策略重算每题对错；未答题返回 null（不参与对错着色）。
  bool? _verdict(PaperQuestionState state) {
    final result = attempt.scoringPolicy.score(state.question, state.selected);
    return result.isAnswered ? result.isCompletelyCorrect : null;
  }

  String _submittedPanelTitle(AppLocalizations l10n) {
    var correctCount = 0;
    var wrongCount = 0;
    var unansweredCount = 0;
    for (final state in attempt.questions) {
      final result = attempt.scoringPolicy.score(
        state.question,
        state.selected,
      );
      if (!result.isAnswered) {
        unansweredCount++;
      } else if (result.isCompletelyCorrect) {
        correctCount++;
      } else {
        wrongCount++;
      }
    }
    return l10n.paperNumberPanelSubmittedTitle(
      correctCount,
      wrongCount,
      unansweredCount,
    );
  }

  Widget _legends() {
    if (!submitted) {
      return Wrap(
        spacing: 8,
        children: [
          _Legend(
            icon: Icons.radio_button_unchecked,
            text: _l10n.paperUnanswered,
          ),
          _Legend(
            icon: Icons.circle,
            text: _l10n.paperAnswered,
            color: Colors.green,
          ),
          _Legend(
            icon: Icons.help,
            text: _l10n.paperUncertainLabel,
            color: Colors.orange,
          ),
        ],
      );
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      children: [
        _Legend(
          icon: Icons.radio_button_unchecked,
          text: _l10n.paperUnanswered,
        ),
        _Legend(
          icon: Icons.check_circle,
          text: _l10n.paperCorrect,
          color: dark ? const Color(0xff65d6a5) : ExamColors.success,
        ),
        _Legend(
          icon: Icons.cancel,
          text: _l10n.paperWrong,
          color: dark ? const Color(0xffff8f88) : ExamColors.danger,
        ),
      ],
    );
  }

  Widget _draftBar() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: isSubmitting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(_l10n.paperSubmittingDesktop),
              ],
            )
          : confirmingDesktopSubmit
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _l10n.paperSubmitConfirmInline(attempt.unansweredCount),
                  ),
                ),
                const SizedBox(width: 18),
                TextButton(
                  onPressed: () =>
                      setState(() => confirmingDesktopSubmit = false),
                  child: Text(_l10n.paperKeepReviewing),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _commitSubmission,
                  child: Text(_l10n.paperConfirmSubmit),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: attempt.currentIndex > 0
                      ? () => _goTo(attempt.currentIndex - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(_l10n.paperPrevQuestion),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(
                      () => attempt.questions[attempt.currentIndex].uncertain =
                          !attempt.questions[attempt.currentIndex].uncertain,
                    );
                    widget.controller.savePaper(attempt);
                  },
                  icon: const Icon(Icons.help_outline),
                  label: Text(_l10n.paperUncertainMarkKey),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: attempt.currentIndex + 1 < attempt.questions.length
                      ? () => _goTo(attempt.currentIndex + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_l10n.paperNextQuestion),
                ),
                const SizedBox(width: 18),
                FilledButton.icon(
                  onPressed: _requestDesktopSubmit,
                  icon: const Icon(Icons.task_alt),
                  label: Text(_l10n.paperSubmit),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: _abandon, child: Text(_l10n.paperAbandon)),
              ],
            ),
    ),
  );

  Widget _resultBar() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              _l10n.paperResultSummary(
                _scoreSummary(),
                attempt.unansweredCount,
                formatDuration(attempt.durationMs),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 24),
          FilledButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.download),
            label: Text(_l10n.paperExportPackButton),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    widget.controller.savePaper(attempt);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.paperSubmitConfirmTitle),
        content: Text(_l10n.paperSubmitConfirmBody(attempt.unansweredCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_l10n.paperKeepReviewing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_l10n.paperConfirmSubmit),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Let the confirmation route remove its modal barrier before beginning the
    // database handoff. This prevents the Windows window from appearing stuck
    // on the grey dialog overlay while a whole paper is committed.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await _commitSubmission();
  }

  Future<void> _openWindowsOmrReview() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => WindowsOmrReviewPage(
          controller: widget.controller,
          attempt: attempt,
          pickImage: widget.pickImage,
          recognize: widget.recognize,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editSubmittedQuestion() async {
    final snapshotQuestion = attempt.questions[attempt.currentIndex].question;
    final latestQuestion = widget.controller.database.questionById(
      snapshotQuestion.id,
    );
    if (latestQuestion == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_l10n.paperEditQuestionMissing)));
      return;
    }
    final updated = await showQuestionEditDialog(
      context,
      latestQuestion,
      title: _l10n.paperEditBankQuestionTitle(
        latestQuestion.externalId ?? latestQuestion.id,
      ),
    );
    if (updated == null || !mounted) return;
    widget.controller.database.editQuestion(updated);
    setState(() {
      // 历史试卷显示题库最新内容：直接替换当前题的内存对象以即时刷新；
      // 存储的交卷快照与答题事件保持不可变。
      final index = attempt.currentIndex;
      final state = attempt.questions[index];
      attempt.questions[index] = PaperQuestionState(
        question: updated,
        eventId: state.eventId,
        selected: state.selected,
        uncertain: state.uncertain,
        durationMs: state.durationMs,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.paperEditQuestionUpdated)),
    );
  }

  String _scoreSummary() {
    final percentage = attempt.percentage;
    final percentageText = Platform.isWindows && percentage != null
        ? _l10n.paperScorePercentage(percentage.toStringAsFixed(1))
        : '';
    final summary = _l10n.paperScoreSummary(
      '${attempt.score}',
      '${attempt.maxScore}',
    );
    return '$summary$percentageText';
  }

  void _requestDesktopSubmit() {
    widget.controller.savePaper(attempt);
    setState(() => confirmingDesktopSubmit = true);
  }

  Future<void> _commitSubmission() async {
    if (submitted || isSubmitting) return;
    timer?.cancel();
    setState(() {
      confirmingDesktopSubmit = false;
      isSubmitting = true;
    });
    try {
      await widget.controller.submitPaper(attempt);
      if (mounted) setState(() => isSubmitting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.paperSubmitFailed('$error'))),
      );
    }
  }

  Future<void> _abandon() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.paperAbandon),
        content: Text(_l10n.paperAbandonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_l10n.commonCancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: Text(_l10n.paperAbandonKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(_l10n.paperAbandonDiscard),
          ),
        ],
      ),
    );
    if (choice == null) return;
    await widget.controller.abandonPaper(attempt, keepDraft: choice == 'keep');
    if (mounted) Navigator.pop(context);
  }

  Future<void> _export() async {
    var blankPaper = true;
    var answerSheet = true;
    var answers = submitted;
    var review = submitted;
    var paperA3 = false;
    var mode = widget.controller.canPrintPdf
        ? _PaperExportMode.packAndPdf
        : _PaperExportMode.pack;
    final choice = await showDialog<_PaperExportSelection>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canPrintPdf = widget.controller.canPrintPdf;
          final showPdfOptions = canPrintPdf && mode != _PaperExportMode.pack;
          final hasSelection =
              blankPaper || answerSheet || answers || review;
          return AlertDialog(
            icon: const Icon(Icons.file_download_outlined),
            title: Text(_l10n.paperExportTitle),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.sizeOf(context).height * 0.62,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submitted
                          ? _l10n.paperExportHintSubmitted
                          : _l10n.paperExportHintDraft,
                    ),
                    const SizedBox(height: 8),
                    _ExportSectionLabel(_l10n.paperExportSectionContent),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: blankPaper,
                      onChanged: (value) => setDialogState(
                          () => blankPaper = value ?? false),
                      title: Text(_l10n.paperExportBlankPaper),
                      subtitle: Text(_l10n.paperExportBlankPaperDesc),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: answerSheet,
                      onChanged: (value) => setDialogState(
                          () => answerSheet = value ?? false),
                      title: Text(_l10n.paperExportAnswerSheet),
                      subtitle: Text(_l10n.paperExportAnswerSheetDesc),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: answers,
                      onChanged: submitted
                          ? (value) =>
                                setDialogState(() => answers = value ?? false)
                          : null,
                      title: Text(_l10n.paperExportAnswers),
                      subtitle: Text(
                        submitted
                            ? _l10n.paperExportAnswersDesc
                            : _l10n.paperExportAfterSubmit,
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: review,
                      onChanged: submitted
                          ? (value) =>
                                setDialogState(() => review = value ?? false)
                          : null,
                      title: Text(_l10n.paperExportReview),
                      subtitle: Text(
                        submitted
                            ? _l10n.paperExportReviewDesc
                            : _l10n.paperExportAfterSubmit,
                      ),
                    ),
                    const Divider(height: 24),
                    _ExportSectionLabel(_l10n.paperExportSectionOutput),
                    if (canPrintPdf)
                      SegmentedButton<_PaperExportMode>(
                        segments: [
                          ButtonSegment(
                            value: _PaperExportMode.pack,
                            label: Text(_l10n.paperExportModePack),
                          ),
                          ButtonSegment(
                            value: _PaperExportMode.packAndPdf,
                            label: Text(_l10n.paperExportModePackAndPdf),
                          ),
                          ButtonSegment(
                            value: _PaperExportMode.pdfOnly,
                            label: Text(_l10n.paperExportModePdfOnly),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (selection) =>
                            setDialogState(() => mode = selection.first),
                      )
                    else
                      Text(_l10n.paperExportPdfWindowsOnly),
                    const SizedBox(height: 6),
                    Text(
                      style: Theme.of(context).textTheme.bodySmall,
                      switch (mode) {
                        _PaperExportMode.pack => _l10n.paperExportModePackDesc,
                        _PaperExportMode.packAndPdf =>
                          _l10n.paperExportModePackAndPdfDesc,
                        _PaperExportMode.pdfOnly =>
                          _l10n.paperExportModePdfOnlyDesc,
                      },
                    ),
                    if (showPdfOptions) ...[
                      const SizedBox(height: 10),
                      _ExportSectionLabel(_l10n.paperExportLayoutTitle),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(_l10n.paperExportLayoutA4),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(_l10n.paperExportLayoutA3),
                          ),
                        ],
                        selected: {paperA3},
                        onSelectionChanged: (selection) =>
                            setDialogState(() => paperA3 = selection.first),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        style: Theme.of(context).textTheme.bodySmall,
                        _l10n.paperExportLayoutHint,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_l10n.commonCancel),
              ),
              FilledButton.icon(
                onPressed: hasSelection
                    ? () => Navigator.pop(
                        context,
                        _PaperExportSelection(
                          blankPaper: blankPaper,
                          answerSheet: answerSheet,
                          answers: answers,
                          review: review,
                          printPdf: mode != _PaperExportMode.pack,
                          paperA3: paperA3,
                        ),
                      )
                    : null,
                icon: const Icon(Icons.download),
                label: Text(switch (mode) {
                  _PaperExportMode.pack => _l10n.paperExportStart,
                  _PaperExportMode.packAndPdf => _l10n.paperExportAndPrint,
                  _PaperExportMode.pdfOnly => _l10n.paperExportPdfOnlyButton,
                }),
              ),
            ],
          );
        },
      ),
    );
    if (choice == null || !mounted) return;
    Directory? directory;
    try {
      directory = widget.controller.exportPaper(
        attempt,
        blankPaper: choice.blankPaper,
        answerSheet: choice.answerSheet,
        answers: choice.answers,
        review: choice.review,
        paperA3: choice.paperA3,
        labels: localizedExportLabels(_l10n),
      );
      final pdfs = choice.printPdf
          ? await widget.controller.printPaperPdfs(
              directory,
              paperA3: choice.paperA3,
              labels: localizedExportLabels(_l10n),
            )
          : const <File>[];
      if (pdfs.isNotEmpty && mode == _PaperExportMode.pdfOnly) {
        widget.controller.retainOnlyPdfs(directory, pdfs);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pdfs.isEmpty
                ? _l10n.paperExportedTo(directory.path)
                : _l10n.paperExportedPdf(
                    pdfs.map((file) => file.path).join('\n'),
                  ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = directory == null
          ? _l10n.paperExportFailed('$error')
          : _l10n.paperExportPdfFailedWithPack(directory.path, '$error');
      if (directory != null) {
        try {
          await File(
            '${directory.path}${Platform.pathSeparator}'
            '${_l10n.paperPdfErrorFileName}',
          ).writeAsString(message, flush: true);
        } on FileSystemException {
          // 错误对话框仍会显示完整内容。
        }
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.error_outline),
          title: Text(_l10n.paperExportPdfFailedTitle),
          content: SizedBox(width: 620, child: SelectableText(message)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_l10n.commonConfirm),
            ),
          ],
        ),
      );
    }
  }
}

enum _PaperExportMode { pack, packAndPdf, pdfOnly }

class _ExportSectionLabel extends StatelessWidget {
  const _ExportSectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _PaperExportSelection {
  const _PaperExportSelection({
    required this.blankPaper,
    required this.answerSheet,
    required this.answers,
    required this.review,
    required this.printPdf,
    required this.paperA3,
  });

  final bool blankPaper;
  final bool answerSheet;
  final bool answers;
  final bool review;
  final bool printPdf;

  /// 试卷排版：true = A3（答题卡始终 A4，A3 时试卷与答题卡分别输出 PDF）。
  final bool paperA3;
}

class _HeaderStatus extends StatelessWidget {
  const _HeaderStatus({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: color)),
      ],
    ),
  );
}

class _AnswerStateBadge extends StatelessWidget {
  const _AnswerStateBadge({required this.answered, required this.uncertain});
  final bool answered;
  final bool uncertain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final color = answered ? Colors.green.shade700 : scheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            answered ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            answered ? l10n.paperBadgeAnswered : l10n.paperBadgeUnanswered,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          if (uncertain) ...[
            const SizedBox(width: 6),
            const Icon(Icons.help, size: 16, color: Colors.orange),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      Text(text, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    required this.number,
    required this.current,
    required this.answered,
    required this.uncertain,
    required this.onPressed,
    this.correct,
  });
  final int number;
  final bool current;
  final bool answered;
  final bool uncertain;

  /// 非 null 表示已交卷的判定结果（仅已答的题有值），此时按对错着色。
  final bool? correct;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final judged = correct != null && answered;
    final Color verdictColor;
    if (judged) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      verdictColor = correct!
          ? (dark ? const Color(0xff65d6a5) : ExamColors.success)
          : (dark ? const Color(0xffff8f88) : ExamColors.danger);
    } else {
      verdictColor = Colors.green;
    }
    final background = judged
        ? verdictColor.withValues(alpha: 0.18)
        : uncertain
        ? Colors.orange.withValues(alpha: 0.18)
        : answered
        ? Colors.green.withValues(alpha: 0.18)
        : scheme.surface;
    final foreground = judged
        ? verdictColor
        : answered
        ? Colors.green.shade800
        : scheme.onSurface;
    final borderColor = current
        ? scheme.primary
        : judged
        ? verdictColor
        : answered
        ? Colors.green.shade600
        : scheme.outlineVariant;
    final status = judged
        ? correct!
              ? l10n.paperCorrect
              : l10n.paperWrong
        : uncertain && answered
        ? l10n.paperStatusAnsweredUncertain
        : uncertain
        ? l10n.paperStatusUnansweredUncertain
        : answered
        ? l10n.paperAnswered
        : l10n.paperUnanswered;
    final semanticLabel = current
        ? l10n.paperStatusCurrentLabel(number, status)
        : l10n.paperStatusLabel(number, status);
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: SizedBox.square(
          key: ValueKey('paper-number-$number'),
          dimension: 44,
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(width: current ? 3 : 1.5, color: borderColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onPressed,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      color: foreground,
                      fontWeight: answered ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (uncertain)
                    const Positioned(
                      right: 2,
                      top: 2,
                      child: Icon(Icons.help, size: 14, color: Colors.orange),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
