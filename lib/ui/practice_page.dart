import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_theme.dart';
import 'error_messages.dart';
import 'question_widgets.dart';

class PracticeSessionPage extends StatefulWidget {
  const PracticeSessionPage({
    super.key,
    required this.controller,
    required this.mode,
    required this.questions,
  });
  final AppController controller;
  final PracticeMode mode;
  final List<Question> questions;
  @override
  State<PracticeSessionPage> createState() => _PracticeSessionPageState();
}

class _PracticeSessionPageState extends State<PracticeSessionPage> {
  int index = 0;
  final selected = <String>{};
  bool revealed = false;
  bool selectionRequired = false;
  late DateTime questionStarted;
  Timer? timer;
  int elapsedMs = 0;
  Question get question => widget.questions[index];

  /// State 内统一取词入口：State 的 context 在所有 build 路径方法中都有效。
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    questionStarted = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(
          () => elapsedMs = DateTime.now()
              .difference(questionStarted)
              .inMilliseconds,
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void toggle(String option) {
    if (revealed) return;
    setState(() {
      selectionRequired = false;
      if (question.type == QuestionType.single) {
        selected
          ..clear()
          ..add(option);
      } else if (!selected.remove(option)) {
        selected.add(option);
      }
    });
  }

  void submit() {
    if (selected.isEmpty) {
      setState(() => selectionRequired = true);
      return;
    }
    try {
      widget.controller.submitPractice(
        question: question,
        selected: selected,
        durationMs: elapsedMs,
        mode: widget.mode,
      );
      setState(() => revealed = true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedErrorText(_l10n, error))),
      );
    }
  }

  void move(int delta) {
    final target = index + delta;
    if (target < 0 || target >= widget.questions.length) return;
    setState(() {
      index = target;
      selected.clear();
      revealed = false;
      selectionRequired = false;
      elapsedMs = 0;
      questionStarted = DateTime.now();
    });
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _editingText()) return KeyEventResult.ignored;
    final key = event.logicalKey.keyLabel.toUpperCase();
    if ('ABCDE'.contains(key) &&
        key.length == 1 &&
        question.options.containsKey(key)) {
      toggle(key);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      move(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter && !revealed) {
      submit();
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
  Widget build(BuildContext context) {
    final progress = widget.controller.database.progress(question.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(_modeName(widget.mode, _l10n)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 19),
                const SizedBox(width: 6),
                Text(
                  formatDuration(elapsedMs),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: onKey,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.controller.contentWidth,
            ),
            child: ListView(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).shortestSide < 600 ? 12 : 24,
              ),
              children: [
                _SessionProgress(
                  current: index + 1,
                  total: widget.questions.length,
                ),
                const SizedBox(height: 12),
                _questionActions(progress),
                const SizedBox(height: 12),
                QuestionCard(
                  controller: widget.controller,
                  question: question,
                  number: index + 1,
                  selected: selected,
                  onToggle: toggle,
                  revealed: revealed,
                  selectionRequired: selectionRequired,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).shortestSide < 600
          ? _mobileBottomBar()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: index > 0 ? () => move(-1) : null,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(_l10n.practicePrevQuestion),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: revealed ? null : submit,
                      icon: const Icon(Icons.check),
                      label: Text(_l10n.practiceSubmitCurrentKey),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: index + 1 < widget.questions.length
                          ? () => move(1)
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(_l10n.practiceNextQuestion),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _questionActions(QuestionProgress progress) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 8.0;
      final columns = constraints.maxWidth >= 760 ? 4 : 2;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _QuestionActionButton(
            key: const ValueKey('practice-favorite-action'),
            width: width,
            icon: progress.isFavorite ? Icons.star : Icons.star_border,
            label: progress.isFavorite
                ? _l10n.practiceFavoriteMarked
                : _l10n.practiceFavorite,
            selected: progress.isFavorite,
            selectedColor: const Color(0xffa66b00),
            onPressed: () => setState(
              () => widget.controller.updateMeta(
                question,
                favorite: !progress.isFavorite,
              ),
            ),
          ),
          _QuestionActionButton(
            key: const ValueKey('practice-uncertain-action'),
            width: width,
            icon: progress.isUncertain ? Icons.flag : Icons.flag_outlined,
            label: progress.isUncertain
                ? _l10n.practiceMarkedUncertain
                : _l10n.practiceMarkUncertain,
            selected: progress.isUncertain,
            selectedColor: ExamColors.warning,
            onPressed: () => setState(
              () => widget.controller.updateMeta(
                question,
                uncertain: !progress.isUncertain,
              ),
            ),
          ),
          _QuestionActionButton(
            key: const ValueKey('practice-note-action'),
            width: width,
            icon: progress.personalNote.isEmpty
                ? Icons.note_add_outlined
                : Icons.note_alt,
            label: progress.personalNote.isEmpty
                ? _l10n.practiceAddNote
                : _l10n.practiceEditNote,
            selected: progress.personalNote.isNotEmpty,
            onPressed: () => _editNote(progress.personalNote),
          ),
          _QuestionActionButton(
            key: const ValueKey('practice-exclude-action'),
            width: width,
            icon: Icons.do_not_disturb_alt_outlined,
            label: _l10n.practiceExcludeQuestion,
            danger: true,
            onPressed: _exclude,
          ),
        ],
      );
    },
  );

  Widget _mobileBottomBar() => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: Border(
      top: BorderSide(color: Theme.of(context).colorScheme.outline),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: revealed ? null : submit,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  revealed
                      ? _l10n.practiceSubmittedCurrent
                      : _l10n.practiceSubmitAndReveal,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: index > 0 ? () => move(-1) : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(_l10n.practicePrevQuestion),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: index + 1 < widget.questions.length
                        ? () => move(1)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_l10n.practiceNextQuestion),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _exclude() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.do_not_disturb_alt_outlined),
        title: Text(_l10n.practiceExcludeTitle),
        content: Text(_l10n.practiceExcludeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(_l10n.practiceExcludeConfirm),
          ),
        ],
      ),
    );
    if (confirm == true) {
      widget.controller.updateMeta(question, excluded: true);
      if (mounted && index + 1 < widget.questions.length) move(1);
    }
  }

  Future<void> _editNote(String initial) async {
    final text = TextEditingController(text: initial);
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.practiceNoteTitle),
        content: SizedBox(
          width: 540,
          child: TextField(controller: text, maxLines: 8, autofocus: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text),
            child: Text(_l10n.commonSave),
          ),
        ],
      ),
    );
    if (saved != null) {
      setState(() => widget.controller.updateMeta(question, note: saved));
    }
    text.dispose();
  }

  static String _modeName(PracticeMode mode, AppLocalizations l10n) =>
      switch (mode) {
        PracticeMode.unseen => l10n.practiceModeUnseen,
        PracticeMode.wrongReview => l10n.practiceModeWrongReview,
        PracticeMode.random => l10n.practiceModeRandom,
        PracticeMode.favorite => l10n.practiceModeFavorite,
        PracticeMode.uncertain => l10n.practiceModeUncertain,
      };
}

class _SessionProgress extends StatelessWidget {
  const _SessionProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final value = total == 0 ? 0.0 : current / total;
    return Container(
      key: const ValueKey('practice-session-progress'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l10n.practiceProgressPosition(current, total),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                l10n.practiceProgressPercent((value * 100).round()),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: value, minHeight: 7),
          ),
        ],
      ),
    );
  }
}

class _QuestionActionButton extends StatelessWidget {
  const _QuestionActionButton({
    super.key,
    required this.width,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.danger = false,
    this.selectedColor,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final bool danger;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = danger ? scheme.error : selectedColor ?? scheme.primary;
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: selected || danger ? activeColor : scheme.onSurface,
          backgroundColor: selected
              ? activeColor.withValues(alpha: 0.1)
              : scheme.surface,
          side: BorderSide(
            color: selected || danger
                ? activeColor.withValues(alpha: selected ? 0.55 : 0.38)
                : scheme.outline,
          ),
        ),
        icon: Icon(icon, size: 19),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
