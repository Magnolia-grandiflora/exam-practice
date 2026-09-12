import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../config/app_info.dart';
import '../config/supabase_config.dart';
import '../domain/models.dart';
import '../domain/paper_policy.dart';
import '../domain/policies.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/sync_service.dart';
import 'app_theme.dart';
import 'error_messages.dart';
import 'export_labels.dart';
import 'paper_page.dart';
import 'practice_page.dart';
import 'question_widgets.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 720 || size.shortestSide < 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: mobile ? 58 : 72,
        title: Text(title),
        actions: [
          ...actions,
          SizedBox(width: mobile ? 4 : 20),
        ],
      ),
      body: Padding(
        padding: mobile
            ? const EdgeInsets.fromLTRB(12, 2, 12, 12)
            : const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.onNavigate,
  });
  final AppController controller;
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = controller.stats;
    final mobile = MediaQuery.sizeOf(context).shortestSide < 600;
    return PageFrame(
      title: l10n.dashboardTitle,
      actions: [_BankPicker(controller: controller)],
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1e463c).withValues(alpha: 0.08),
                  blurRadius: 34,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dashboardCurrentBank,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.currentBank?.name ?? l10n.dashboardNoBank,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.dashboardTagline,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Material(
                  color: s.pendingSync == 0
                      ? const Color(0xffe8f4ef)
                      : const Color(0xfffff5df),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    key: const ValueKey('home-pending-sync-pill'),
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _showPendingSyncDialog(context, controller),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.pendingSync == 0
                                ? l10n.dashboardAllSaved
                                : l10n.dashboardPendingSyncCount(s.pendingSync),
                            style: TextStyle(
                              color: s.pendingSync == 0
                                  ? ExamColors.success
                                  : ExamColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = mobile
                  ? (constraints.maxWidth - 12) / 2
                  : 170.0;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  StatTile(
                    label: l10n.statsTotalQuestions,
                    value: '${s.total}',
                    icon: Icons.library_books,
                    width: cardWidth,
                  ),
                  StatTile(
                    label: l10n.statsUnseen,
                    value: '${s.unseen}',
                    icon: Icons.visibility_outlined,
                    width: cardWidth,
                  ),
                  StatTile(
                    label: l10n.statsCurrentWrong,
                    value: '${s.wrong}',
                    icon: Icons.close,
                    color: Colors.red,
                    width: cardWidth,
                  ),
                  StatTile(
                    label: l10n.statsMastered,
                    value: '${s.mastered}',
                    icon: Icons.check,
                    color: Colors.green,
                    width: cardWidth,
                  ),
                  StatTile(
                    label: l10n.statsEverWrong,
                    value: '${s.everWrong}',
                    icon: Icons.history_toggle_off,
                    width: cardWidth,
                  ),
                  StatTile(
                    label: l10n.statsPendingSync,
                    value: '${s.pendingSync}',
                    icon: Icons.cloud_upload_outlined,
                    width: cardWidth,
                    onTap: () => _showPendingSyncDialog(context, controller),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            l10n.dashboardQuickStart,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                key: const ValueKey('home-primary-action'),
                width: mobile ? double.infinity : null,
                child: FilledButton.icon(
                  onPressed: () => onNavigate(1),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    s.unseen > 0
                        ? l10n.dashboardContinueUnseen
                        : s.wrong > 0
                        ? l10n.dashboardStartWrongReview
                        : l10n.modeRandom,
                  ),
                ),
              ),
              SizedBox(
                width: mobile ? double.infinity : null,
                child: OutlinedButton.icon(
                  onPressed: s.wrong > 0 ? () => onNavigate(4) : null,
                  icon: const Icon(Icons.error_outline),
                  label: Text(l10n.dashboardViewWrong),
                ),
              ),
              SizedBox(
                width: mobile ? double.infinity : null,
                child: OutlinedButton.icon(
                  onPressed: () => onNavigate(2),
                  icon: const Icon(Icons.article_outlined),
                  label: Text(l10n.dashboardCreatePaper),
                ),
              ),
              if (controller.draft != null)
                SizedBox(
                  width: mobile ? double.infinity : null,
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaperPage(
                          controller: controller,
                          attempt: controller.draft!,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.restore),
                    label: Text(l10n.dashboardResumeDraft),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.dashboardRecentPapers,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ...controller.recentHistory
              .take(5)
              .map(
                (item) => ListTile(
                  leading: Icon(
                    item.status == AttemptStatus.submitted
                        ? Icons.task_alt
                        : Icons.edit_note,
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    l10n.papersSubtitle(
                      item.questionCount,
                      _status(l10n, item.status),
                      formatDuration(item.durationMs),
                    ),
                  ),
                  trailing: item.score == null
                      ? null
                      : Text('${item.score}/${item.maxScore}'),
                  onTap: () {
                    final attempt = controller.database.loadAttempt(
                      item.attemptId,
                    );
                    if (attempt != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaperPage(
                            controller: controller,
                            attempt: attempt,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
          if (controller.recentHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.papersNoRecords),
            ),
        ],
      ),
    );
  }
}

class PracticeLauncherPage extends StatefulWidget {
  const PracticeLauncherPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<PracticeLauncherPage> createState() => _PracticeLauncherPageState();
}

class _PracticeLauncherPageState extends State<PracticeLauncherPage> {
  String? year;
  String? chapter;
  String? tag;
  QuestionType? type;
  AppController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auto = controller.automaticPracticeMode;
    final mobile = MediaQuery.sizeOf(context).shortestSide < 600;
    final questions = controller.currentBank == null
        ? const <Question>[]
        : controller.database.managedQuestions(controller.currentBank!.id);
    final years = _values(questions.map((q) => q.year));
    final chapters = _values(questions.map((q) => q.chapter));
    final tags = _values(questions.expand((q) => q.tags));
    return PageFrame(
      title: l10n.practiceTitle,
      actions: [_BankPicker(controller: controller)],
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final description = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.practiceDefaultPolicy(_mode(l10n, auto)),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(l10n.practiceDefaultPolicyDesc),
                    ],
                  );
                  final button = FilledButton(
                    onPressed: () => _open(context, auto),
                    child: Text(l10n.practiceStartDefault),
                  );
                  if (constraints.maxWidth < 600) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.route, size: 34),
                        const SizedBox(height: 10),
                        description,
                        const SizedBox(height: 14),
                        button,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      const Icon(Icons.route, size: 34),
                      const SizedBox(width: 14),
                      Expanded(child: description),
                      button,
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.practiceCustomScope),
                  _StringFilter(
                    label: l10n.filterAllYear,
                    value: years.contains(year) ? year : null,
                    values: years,
                    onChanged: (value) => setState(() => year = value),
                  ),
                  _StringFilter(
                    label: l10n.filterAllChapter,
                    value: chapters.contains(chapter) ? chapter : null,
                    values: chapters,
                    onChanged: (value) => setState(() => chapter = value),
                  ),
                  _StringFilter(
                    label: l10n.filterAllTag,
                    value: tags.contains(tag) ? tag : null,
                    values: tags,
                    onChanged: (value) => setState(() => tag = value),
                  ),
                  DropdownButton<QuestionType?>(
                    value: type,
                    hint: Text(l10n.filterAllTypes),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.filterAllTypes),
                      ),
                      DropdownMenuItem(
                        value: QuestionType.single,
                        child: Text(l10n.questionTypeSingle),
                      ),
                      DropdownMenuItem(
                        value: QuestionType.multiple,
                        child: Text(l10n.questionTypeMultiple),
                      ),
                    ],
                    onChanged: (value) => setState(() => type = value),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      year = null;
                      chapter = null;
                      tag = null;
                      type = null;
                    }),
                    child: Text(l10n.practiceClearFilters),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = mobile
                  ? (constraints.maxWidth - 14) / 2
                  : 230.0;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _ModeCard(
                    icon: Icons.visibility_outlined,
                    title: l10n.modeUnseen,
                    count: controller.stats.unseen,
                    width: cardWidth,
                    onTap: () => _open(context, PracticeMode.unseen),
                  ),
                  _ModeCard(
                    icon: Icons.error_outline,
                    title: l10n.modeWrongReview,
                    count: controller.stats.wrong,
                    width: cardWidth,
                    onTap: () => _open(context, PracticeMode.wrongReview),
                  ),
                  _ModeCard(
                    icon: Icons.shuffle,
                    title: l10n.modeRandom,
                    count: controller.stats.total - controller.stats.excluded,
                    width: cardWidth,
                    onTap: () => _open(context, PracticeMode.random),
                  ),
                  _ModeCard(
                    icon: Icons.star_outline,
                    title: l10n.modeFavorite,
                    count: controller.stats.favorite,
                    width: cardWidth,
                    onTap: () => _open(context, PracticeMode.favorite),
                  ),
                  _ModeCard(
                    icon: Icons.help_outline,
                    title: l10n.modeUncertain,
                    count: controller.stats.uncertain,
                    width: cardWidth,
                    onTap: () => _open(context, PracticeMode.uncertain),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text(l10n.practiceShortcutsHint),
        ],
      ),
    );
  }

  void _open(BuildContext context, PracticeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    final questions = controller.practiceQueue(
      mode,
      year: year,
      chapter: chapter,
      tag: tag,
      type: type,
    );
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.practiceQueueEmpty(_mode(l10n, mode)))),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          controller: controller,
          mode: mode,
          questions: questions,
        ),
      ),
    );
  }

  static List<String> _values(Iterable<String> source) =>
      (source.where((value) => value.trim().isNotEmpty).toSet().toList()
        ..sort());
}

class _StringFilter extends StatelessWidget {
  const _StringFilter({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<String?>(
    value: value,
    hint: Text(label),
    items: [
      DropdownMenuItem(value: null, child: Text(label)),
      ...values.map((item) => DropdownMenuItem(value: item, child: Text(item))),
    ],
    onChanged: onChanged,
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.width,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final int count;
  final double width;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      key: ValueKey('practice-mode-card-$title'),
      width: width,
      height: 130,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: count > 0 ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(l10n.practiceModeCardCount(count)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaperLauncherPage extends StatefulWidget {
  const PaperLauncherPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<PaperLauncherPage> createState() => _PaperLauncherPageState();
}

class _PaperLauncherPageState extends State<PaperLauncherPage> {
  int count = 20;
  int singleCount = 14;
  int multipleCount = 3;
  int qaCount = 0;
  int suggestedMinutes = 30;
  bool random = true;
  String? year;
  String? chapter;
  String? tag;
  QuestionType? type;
  PaperCompositionMode compositionMode = PaperCompositionMode.realExam;

  /// 实际请求题量：仅 Windows 考试模式使用三题型之和，其余用单一题量。
  int effectiveCount(bool isWindows) =>
      isWindows && compositionMode == PaperCompositionMode.realExam
      ? singleCount + multipleCount + qaCount
      : count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    final questions = widget.controller.currentBank == null
        ? const <Question>[]
        : widget.controller.database.managedQuestions(
            widget.controller.currentBank!.id,
          );
    final years = _PracticeLauncherPageState._values(
      questions.map((q) => q.year),
    );
    final chapters = _PracticeLauncherPageState._values(
      questions.map((q) => q.chapter),
    );
    final tags = _PracticeLauncherPageState._values(
      questions.expand((q) => q.tags),
    );
    final poolSize = widget.controller.currentBank == null
        ? 0
        : widget.controller.database.listQuestions(
            bankId: widget.controller.currentBank!.id,
            year: year,
            chapter: chapter,
            tag: tag,
            type: isWindows ? null : type,
          ).length;
    return PageFrame(
      title: l10n.paperTitle,
      actions: [_BankPicker(controller: widget.controller)],
      child: ListView(
        children: [
          if (widget.controller.draft != null)
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.restore),
                title: Text(l10n.paperDraftAvailable),
                subtitle: Text(widget.controller.draft!.title),
                trailing: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaperPage(
                        controller: widget.controller,
                        attempt: widget.controller.draft!,
                      ),
                    ),
                  ),
                  child: Text(l10n.commonContinue),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            l10n.paperScopeTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StringFilter(
                label: l10n.filterAllYear,
                value: years.contains(year) ? year : null,
                values: years,
                onChanged: (value) => setState(() => year = value),
              ),
              _StringFilter(
                label: l10n.filterAllChapter,
                value: chapters.contains(chapter) ? chapter : null,
                values: chapters,
                onChanged: (value) => setState(() => chapter = value),
              ),
              _StringFilter(
                label: l10n.filterAllTag,
                value: tags.contains(tag) ? tag : null,
                values: tags,
                onChanged: (value) => setState(() => tag = value),
              ),
              if (!isWindows)
                DropdownButton<QuestionType?>(
                  value: type,
                  hint: Text(l10n.filterAllTypes),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.filterAllTypes),
                    ),
                    DropdownMenuItem(
                      value: QuestionType.single,
                      child: Text(l10n.questionTypeSingle),
                    ),
                    DropdownMenuItem(
                      value: QuestionType.multiple,
                      child: Text(l10n.questionTypeMultiple),
                    ),
                    DropdownMenuItem(
                      value: QuestionType.qa,
                      child: Text(l10n.questionTypeQa),
                    ),
                  ],
                  onChanged: (value) => setState(() => type = value),
                ),
            ],
          ),
          Text(
            style: Theme.of(context).textTheme.bodySmall,
            l10n.paperScopeSummary(
              poolSize,
              random ? l10n.paperPickerRandom : l10n.paperPickerInOrder,
              poolSize < effectiveCount(isWindows)
                  ? poolSize
                  : effectiveCount(isWindows),
            ),
          ),
          const SizedBox(height: 14),
          if (isWindows) ...[
            Text(
              l10n.paperCompositionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<PaperCompositionMode>(
              key: const ValueKey('paper-composition-mode'),
              segments: [
                ButtonSegment(
                  value: PaperCompositionMode.singleOnly,
                  icon: const Icon(Icons.radio_button_checked),
                  label: Text(l10n.paperCompositionSingleOnly),
                ),
                ButtonSegment(
                  value: PaperCompositionMode.multipleOnly,
                  icon: const Icon(Icons.checklist),
                  label: Text(l10n.paperCompositionMultipleOnly),
                ),
                ButtonSegment(
                  value: PaperCompositionMode.realExam,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(l10n.paperCompositionRealExam),
                ),
              ],
              selected: {compositionMode},
              onSelectionChanged: (value) =>
                  setState(() => compositionMode = value.single),
            ),
            const SizedBox(height: 14),
          ],
          if (isWindows && compositionMode == PaperCompositionMode.realExam) ...[
            Text(
              l10n.paperTypeCountsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 130,
                  child: TextFormField(
                    key: const ValueKey('paper-count-single'),
                    initialValue: '$singleCount',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.paperTypeCountsSingle,
                    ),
                    onChanged: (value) => singleCount = (int.tryParse(
                      value,
                    ) ?? singleCount).clamp(0, 100),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: TextFormField(
                    key: const ValueKey('paper-count-multiple'),
                    initialValue: '$multipleCount',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.paperTypeCountsMultiple,
                    ),
                    onChanged: (value) => multipleCount = (int.tryParse(
                      value,
                    ) ?? multipleCount).clamp(0, 100),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: TextFormField(
                    key: const ValueKey('paper-count-qa'),
                    initialValue: '$qaCount',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.paperTypeCountsQa),
                    onChanged: (value) =>
                        qaCount = (int.tryParse(value) ?? qaCount).clamp(0, 100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              style: Theme.of(context).textTheme.bodySmall,
              l10n.paperTypeCountsHint,
            ),
          ] else ...[
            Text(
              l10n.paperCountTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final value in [20, 30, 50, 85, 100])
                  ChoiceChip(
                    label: Text('$value'),
                    selected: count == value,
                    onSelected: (_) => setState(() => count = value),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(l10n.paperCustomCount),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    initialValue: '$count',
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        count = (int.tryParse(value) ?? count).clamp(1, 100),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(l10n.paperSuggestedMinutes),
              SizedBox(
                width: 110,
                child: TextFormField(
                  initialValue: '$suggestedMinutes',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => suggestedMinutes =
                      (int.tryParse(value) ?? suggestedMinutes).clamp(0, 600),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.paperRandomTitle),
            subtitle: Text(l10n.paperRandomDesc),
            value: random,
            onChanged: (value) => setState(() => random = value),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.paperGenerateStart),
            ),
          ),
          const SizedBox(height: 10),
          Text(l10n.paperNote),
        ],
      ),
    );
  }

  void _start() {
    final l10n = AppLocalizations.of(context)!;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    try {
      final realExamCounts = isWindows &&
              compositionMode == PaperCompositionMode.realExam
          ? PaperTypeCounts(
              single: singleCount,
              multiple: multipleCount,
              qa: qaCount,
            )
          : null;
      final paper = widget.controller.createPaper(
        requestedCount: effectiveCount(isWindows),
        suggestedMinutes: suggestedMinutes,
        random: random,
        compositionMode: isWindows ? compositionMode : null,
        typeCounts: realExamCounts,
        year: year,
        chapter: chapter,
        tag: tag,
        type: type,
      );
      if (paper.questions.length < effectiveCount(isWindows)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paperAdjustedCount(paper.questions.length)),
          ),
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PaperPage(controller: widget.controller, attempt: paper),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedErrorText(l10n, error))),
      );
    }
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PageFrame(
      title: l10n.historyTitle,
      child: controller.recentHistory.isEmpty
          ? Center(child: Text(l10n.papersNoRecords))
          : ListView.separated(
              itemCount: controller.recentHistory.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = controller.recentHistory[index];
                return ListTile(
                  leading: Icon(
                    item.status == AttemptStatus.submitted
                        ? Icons.task_alt
                        : Icons.edit_note,
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    l10n.papersSubtitle(
                      item.questionCount,
                      _status(l10n, item.status),
                      formatDuration(item.durationMs),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.score != null)
                        Text('${item.score}/${item.maxScore}'),
                      IconButton(
                        tooltip: l10n.historyDeleteTooltip,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteAttempt(context, item),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    final attempt = controller.database.loadAttempt(
                      item.attemptId,
                    );
                    if (attempt != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PaperPage(controller: controller, attempt: attempt),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  Future<void> _deleteAttempt(BuildContext context, AttemptSummary item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteBody(item.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.deleteHistoryAttempt(item.attemptId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.historyDeleteFailed('$error'))),
        );
      }
    }
  }
}

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  String filter = 'wrong';
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bank = widget.controller.currentBank;
    final all = bank == null
        ? <Question>[]
        : widget.controller.database.listQuestions(
            bankId: bank.id,
            includeExcluded: true,
          );
    final questions = all.where((q) {
      final p = widget.controller.database.progress(q.id);
      return switch (filter) {
        'wrong' => p.state == StudyState.wrong,
        'ever' => p.everWrong,
        'favorite' => p.isFavorite,
        'uncertain' => p.isUncertain,
        'excluded' => p.isExcluded,
        _ => false,
      };
    }).toList();
    return PageFrame(
      title: l10n.collectionTitle,
      actions: [
        OutlinedButton.icon(
          onPressed: questions.isNotEmpty
              ? () {
                  final title = switch (filter) {
                    'wrong' => l10n.statsCurrentWrong,
                    'ever' => l10n.collectionEverWrongTitle,
                    'favorite' => l10n.modeFavorite,
                    'uncertain' => l10n.modeUncertain,
                    'excluded' => l10n.collectionExcludedTitle,
                    _ => l10n.collectionGenericTitle,
                  };
                  final file = widget.controller.exportCollection(
                    title,
                    questions,
                    labels: localizedExportLabels(l10n),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.collectionExported(file.path))),
                  );
                }
              : null,
          icon: const Icon(Icons.download),
          label: Text(l10n.collectionExport),
        ),
      ],
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'wrong',
                  label: Text(l10n.statsCurrentWrong),
                ),
                ButtonSegment(value: 'ever', label: Text(l10n.statsEverWrong)),
                ButtonSegment(
                  value: 'favorite',
                  label: Text(l10n.collectionFavorite),
                ),
                ButtonSegment(
                  value: 'uncertain',
                  label: Text(l10n.collectionUncertain),
                ),
                ButtonSegment(
                  value: 'excluded',
                  label: Text(l10n.collectionExcluded),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (value) =>
                  setState(() => filter = value.first),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: questions.isEmpty
                ? Center(child: Text(l10n.collectionEmpty))
                : ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      final p = widget.controller.database.progress(q.id);
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${q.externalId ?? q.id}　${widget.controller.questionText(q.stem)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            l10n.collectionItemSubtitle(
                              q.type == QuestionType.single
                                  ? l10n.questionTypeSingleShort
                                  : l10n.questionTypeMultipleShort,
                              p.seenCount,
                              p.wrongCount,
                            ),
                          ),
                          leading: filter == 'favorite'
                              ? const Icon(Icons.star, color: Colors.amber)
                              : const Icon(Icons.quiz_outlined),
                          trailing: filter == 'excluded'
                              ? TextButton(
                                  onPressed: () {
                                    widget.controller.updateMeta(
                                      q,
                                      excluded: false,
                                    );
                                    setState(() {});
                                  },
                                  child: Text(l10n.commonRestore),
                                )
                              : IconButton(
                                  tooltip: l10n.collectionHistoryTooltip,
                                  icon: const Icon(Icons.history),
                                  onPressed: () => _showAnswerHistory(q),
                                ),
                          onTap: filter == 'excluded'
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PracticeSessionPage(
                                      controller: widget.controller,
                                      mode: PracticeMode.random,
                                      questions: [q],
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAnswerHistory(Question question) async {
    final l10n = AppLocalizations.of(context)!;
    final rows = widget.controller.database.answerHistory(question.id);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.collectionHistoryTitle(question.externalId ?? question.id),
        ),
        content: SizedBox(
          width: 720,
          height: 420,
          child: rows.isEmpty
              ? Center(child: Text(l10n.collectionNoEvents))
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final selected =
                        (jsonDecode(row['selected_json'] as String) as List)
                            .join('、');
                    return ListTile(
                      leading: Icon(
                        row['correct'] == 1 ? Icons.check_circle : Icons.cancel,
                        color: row['correct'] == 1 ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        l10n.collectionAnsweredAt(
                          '${row['answered_at_utc']}',
                          selected.isEmpty
                              ? l10n.collectionNotAnswered
                              : selected,
                        ),
                      ),
                      subtitle: Text(
                        l10n.collectionEventSubtitle(
                          '${row['mode']}',
                          '${row['score']}',
                          formatDuration(row['duration_ms'] as int),
                        ),
                      ),
                      trailing: SelectableText('${row['event_id']}'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }
}

class BankPage extends StatefulWidget {
  const BankPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  static const pageSize = 100;
  late final TextEditingController pathController;
  late final TextEditingController searchController;
  ImportPreview? preview;
  String? message;
  String? loadedBankId;
  int visibleQuestionCount = pageSize;
  @override
  void initState() {
    super.initState();
    pathController = TextEditingController();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    pathController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = Theme.of(context).platform == TargetPlatform.windows;
    final bank = widget.controller.currentBank;
    if (bank?.id != loadedBankId) {
      loadedBankId = bank?.id;
      visibleQuestionCount = pageSize;
    }
    final totalQuestions = bank == null
        ? 0
        : widget.controller.database.managedQuestionCount(bank.id);
    final query = searchController.text.trim().toLowerCase();
    final questions = bank == null
        ? <Question>[]
        : query.isEmpty
        ? widget.controller.database.managedQuestions(
            bank.id,
            limit: visibleQuestionCount,
          )
        : widget.controller.database
              .managedQuestions(bank.id)
              .where((question) => _matchesSearch(question, query))
              .toList();
    final hasMore = query.isEmpty && questions.length < totalQuestions;
    return PageFrame(
      title: l10n.banksTitle,
      actions: [
        if (canEdit && bank != null)
          TextButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add),
            label: Text(l10n.banksAddQuestion),
          ),
        _BankPicker(controller: widget.controller),
      ],
      child: Column(
        children: [
          if (!canEdit)
            Card(
              child: ListTile(
                leading: const Icon(Icons.phonelink_lock_outlined),
                title: Text(l10n.banksReadonlyTitle),
                subtitle: Text(
                  l10n.banksReadonlyBody(bank?.name ?? l10n.commonNone),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.banksImportTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pathController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: l10n.banksImportHint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _chooseImportFile,
                          icon: const Icon(Icons.folder_open_outlined),
                          label: Text(l10n.banksChooseFile),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _preview,
                          child: Text(l10n.banksPreview),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: preview?.canImport == true
                              ? _commit
                              : null,
                          child: Text(l10n.banksBackupAndImport),
                        ),
                      ],
                    ),
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SelectableText(message!),
                      ),
                    if (preview != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.banksPreviewSummary(
                            preview!.name,
                            preview!.questions.length,
                            preview!.singleCount,
                            preview!.multipleCount,
                            preview!.issues.where((e) => e.blocking).length,
                            preview!.issues.where((e) => !e.blocking).length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (bank != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restart_alt),
                title: Text(l10n.banksResetTitle),
                subtitle: Text(l10n.banksResetBody(bank.name, totalQuestions)),
                trailing: OutlinedButton.icon(
                  onPressed: _resetBank,
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.banksResetAction),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(l10n.banksDeleteTitle),
                subtitle: Text(l10n.banksDeleteBody(bank.name)),
                trailing: OutlinedButton.icon(
                  onPressed: _deleteBank,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.banksDeleteAction),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (bank != null) ...[
            TextField(
              key: const ValueKey('bank-question-search'),
              controller: searchController,
              onChanged: (_) => setState(() => visibleQuestionCount = pageSize),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.banksClearSearch,
                        onPressed: () {
                          searchController.clear();
                          setState(() => visibleQuestionCount = pageSize);
                        },
                        icon: const Icon(Icons.clear),
                      ),
                labelText: l10n.banksSearchLabel,
                hintText: l10n.banksSearchHint,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: questions.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == questions.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => visibleQuestionCount += pageSize),
                        icon: const Icon(Icons.expand_more),
                        label: Text(
                          l10n.banksLoadMore(questions.length, totalQuestions),
                        ),
                      ),
                    ),
                  );
                }
                final q = questions[index];
                return ListTile(
                  enabled: q.isActive,
                  leading: Icon(
                    q.isActive
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText('${q.externalId ?? q.id}　${widget.controller.questionText(q.stem)}'),
                      const SizedBox(height: 6),
                      for (final option in q.options.entries)
                        SelectableText('${option.key}. ${widget.controller.questionText(option.value)}'),
                    ],
                  ),
                  subtitle: Text(
                    '${q.type.name} · v${q.contentVersion} · ${q.year} · ${q.chapter}',
                  ),
                  trailing: !canEdit
                      ? null
                      : Wrap(
                          children: [
                            IconButton(
                              tooltip: l10n.commonEdit,
                              onPressed: () => _edit(q),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.controller.database.setQuestionActive(
                                  q.id,
                                  !q.isActive,
                                );
                                setState(() {});
                              },
                              child: Text(
                                q.isActive
                                    ? l10n.commonDisabled
                                    : l10n.commonRestore,
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(Question question, String query) {
    final searchable = [
      question.externalId ?? question.id,
      widget.controller.questionText(question.stem),
      ...question.options.values.map(widget.controller.questionText),
      question.answers.join(),
      widget.controller.questionText(question.explanation),
      question.knowledgePoint,
      question.source,
      question.year,
      question.chapter,
      ...question.tags,
    ].join('\n').toLowerCase();
    return searchable.contains(query);
  }

  Future<void> _chooseImportFile() async {
    try {
      final path = await widget.controller.chooseQuestionBankFile();
      if (path == null || path.isEmpty || !mounted) return;
      pathController.text = path;
      _preview();
    } catch (error) {
      if (mounted) {
        setState(() {
          message = AppLocalizations.of(
            context,
          )!.banksFilePickerFailed('$error');
        });
      }
    }
  }

  void _preview() {
    final l10n = AppLocalizations.of(context)!;
    try {
      final value = widget.controller.previewImport(pathController.text.trim());
      setState(() {
        preview = value;
        message = value.issues.isEmpty
            ? l10n.banksPreviewOk
            : value.issues
                  .map(
                    (e) => l10n.banksIssueLine(
                      e.blocking
                          ? l10n.banksIssueBlocking
                          : l10n.banksIssueWarning,
                      localizedErrorText(l10n, e),
                    ),
                  )
                  .join('\n');
      });
    } catch (error) {
      setState(() {
        preview = null;
        message = l10n.banksReadFailed('$error');
      });
    }
  }

  Future<void> _commit() async {
    await widget.controller.commitImport(preview!);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        message = l10n.banksImportDone;
        preview = null;
      });
    }
  }

  Future<void> _resetBank() async {
    final bank = widget.controller.currentBank;
    if (bank == null) return;
    final l10n = AppLocalizations.of(context)!;
    final typed = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.banksResetDialogTitle(bank.name)),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.banksResetDialogBody(l10n.commonConfirmResetPhrase)),
              const SizedBox(height: 12),
              TextField(
                controller: typed,
                autofocus: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.commonConfirmResetPhrase,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              typed.text.trim() == l10n.commonConfirmResetPhrase,
            ),
            child: Text(l10n.banksResetConfirmAction),
          ),
        ],
      ),
    );
    typed.dispose();
    if (confirmed != true) return;
    setState(() => message = l10n.banksResetting(bank.name));
    try {
      final backupPath = await widget.controller.resetCurrentBank();
      if (!mounted) return;
      setState(() => message = l10n.banksResetDone(bank.name, backupPath));
    } catch (error) {
      if (mounted) {
        setState(() => message = l10n.banksResetFailed(localizedErrorText(l10n, error)));
      }
    }
  }

  Future<void> _deleteBank() async {
    final bank = widget.controller.currentBank;
    if (bank == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.banksDeleteDialogTitle(bank.name)),
        content: SizedBox(width: 560, child: Text(l10n.banksDeleteDialogBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => message = l10n.banksDeleting(bank.name));
    try {
      await widget.controller.deleteCurrentBank();
      if (mounted) {
        setState(() {
          preview = null;
          message = l10n.banksDeleteDone(bank.name);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => message = l10n.banksDeleteFailed(localizedErrorText(l10n, error)));
      }
    }
  }

  Future<void> _addQuestion() async {
    final bank = widget.controller.currentBank;
    if (bank == null) return;
    final l10n = AppLocalizations.of(context)!;
    final externalId = TextEditingController();
    final stem = TextEditingController();
    final optionControllers = <String, TextEditingController>{
      for (final key in const ['A', 'B', 'C', 'D', 'E'])
        key: TextEditingController(),
    };
    final answer = TextEditingController();
    final explanation = TextEditingController();
    final point = TextEditingController();
    final source = TextEditingController();
    final year = TextEditingController();
    final chapter = TextEditingController();
    final tags = TextEditingController();
    var type = QuestionType.single;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.banksAddQuestionTitle(bank.name)),
          content: SizedBox(
            width: 760,
            height: (MediaQuery.sizeOf(context).height * 0.68)
                .clamp(360.0, 680.0)
                .toDouble(),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<QuestionType>(
                    initialValue: type,
                    decoration: InputDecoration(labelText: l10n.banksFieldType),
                    items: [
                      DropdownMenuItem(
                        value: QuestionType.single,
                        child: Text(l10n.questionTypeSingle),
                      ),
                      DropdownMenuItem(
                        value: QuestionType.multiple,
                        child: Text(l10n.questionTypeMultiple),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => type = value ?? type),
                  ),
                  TextField(
                    controller: externalId,
                    decoration: InputDecoration(
                      labelText: l10n.banksFieldExternalId,
                    ),
                  ),
                  TextField(
                    controller: stem,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: l10n.banksFieldStem),
                  ),
                  for (final entry in optionControllers.entries)
                    TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: l10n.banksFieldOption(
                          entry.key,
                          entry.key == 'A' || entry.key == 'B' ? ' *' : '',
                        ),
                      ),
                    ),
                  TextField(
                    controller: answer,
                    decoration: InputDecoration(
                      labelText: type == QuestionType.single
                          ? l10n.banksFieldAnswerSingle
                          : l10n.banksFieldAnswerMultiple,
                    ),
                  ),
                  TextField(
                    controller: explanation,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.banksFieldExplanation,
                    ),
                  ),
                  TextField(
                    controller: point,
                    decoration: InputDecoration(
                      labelText: l10n.banksFieldKnowledgePoint,
                    ),
                  ),
                  TextField(
                    controller: source,
                    decoration: InputDecoration(
                      labelText: l10n.banksFieldSource,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: year,
                          decoration: InputDecoration(
                            labelText: l10n.banksFieldYear,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: chapter,
                          decoration: InputDecoration(
                            labelText: l10n.banksFieldChapter,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: tags,
                    decoration: InputDecoration(
                      labelText: l10n.banksFieldTags,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.banksSaveQuestion),
            ),
          ],
        ),
      ),
    );
    if (save == true) {
      final options = <String, String>{
        for (final entry in optionControllers.entries)
          if (entry.value.text.trim().isNotEmpty)
            entry.key: entry.value.text.trim(),
      };
      final expectedKeys = const [
        'A',
        'B',
        'C',
        'D',
        'E',
      ].take(options.length).toList();
      final answers = AnswerPolicy.normalize([answer.text]);
      final invalid =
          stem.text.trim().isEmpty ||
          options.length < 2 ||
          options.keys.join() != expectedKeys.join() ||
          answers.isEmpty ||
          (type == QuestionType.single && answers.length != 1) ||
          answers.any((value) => !options.containsKey(value));
      if (invalid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.banksAddInvalid)),
          );
        }
      } else {
        try {
          await widget.controller.addQuestion(
            type: type,
            stem: stem.text,
            options: options,
            answers: answers,
            externalId: externalId.text,
            explanation: explanation.text,
            knowledgePoint: point.text,
            source: source.text,
            year: year.text,
            chapter: chapter.text,
            tags: tags.text
                .split(RegExp(r'[,，;；\s]+'))
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(),
          );
          if (mounted) {
            setState(() => message = l10n.banksQuestionAdded(bank.name));
          }
        } catch (error) {
          if (mounted) {
            setState(() => message = l10n.banksAddFailed(localizedErrorText(l10n, error)));
          }
        }
      }
    }
    externalId.dispose();
    stem.dispose();
    for (final controller in optionControllers.values) {
      controller.dispose();
    }
    answer.dispose();
    explanation.dispose();
    point.dispose();
    source.dispose();
    year.dispose();
    chapter.dispose();
    tags.dispose();
  }

  Future<void> _edit(Question q) async {
    final updated = await showQuestionEditDialog(context, q);
    if (updated == null || !mounted) return;
    widget.controller.database.editQuestion(updated);
    setState(() {});
  }
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bank = controller.currentBank;
    if (bank == null) {
      return PageFrame(
        title: l10n.statsTitle,
        child: Center(child: Text(l10n.statsNoBank)),
      );
    }
    final year = controller.database.groupedStats(bank.id, 'year');
    final chapter = controller.database.groupedStats(bank.id, 'chapter');
    final tag = controller.database.tagStats(bank.id);
    final type = controller.database.groupedStats(bank.id, 'question_type');
    final slow = controller.database.slowQuestions(bank.id);
    return PageFrame(
      title: l10n.statsTitle,
      child: ListView(
        children: [
          Wrap(
            spacing: 12,
            children: [
              StatTile(
                label: l10n.statsTotalQuestions,
                value: '${controller.stats.total}',
                icon: Icons.library_books,
              ),
              StatTile(
                label: l10n.statsUnseen,
                value: '${controller.stats.unseen}',
                icon: Icons.visibility_outlined,
              ),
              StatTile(
                label: l10n.statsCurrentWrong,
                value: '${controller.stats.wrong}',
                icon: Icons.close,
                color: Colors.red,
              ),
              StatTile(
                label: l10n.statsMastered,
                value: '${controller.stats.mastered}',
                icon: Icons.check,
                color: Colors.green,
              ),
            ],
          ),
          _StatsTable(title: l10n.statsByYear, rows: year),
          _StatsTable(title: l10n.statsByChapter, rows: chapter),
          _StatsTable(title: l10n.statsByTag, rows: tag),
          _StatsTable(title: l10n.statsByType, rows: type),
          Text(
            l10n.statsSlowTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ...slow.map(
            (row) => ListTile(
              title: Text(
                controller.questionText(row['stem_markdown'] as String),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                l10n.statsSeenCount((row['seen_count'] as int?) ?? 0),
              ),
              trailing: Text(
                l10n.statsSecondsPerQuestion(
                  ((row['average_ms'] as num) / 1000).toStringAsFixed(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsTable extends StatelessWidget {
  const _StatsTable({required this.title, required this.rows});
  final String title;
  final List<Map<String, Object?>> rows;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(l10n.statsColumnCategory)),
                DataColumn(label: Text(l10n.statsColumnCount)),
                DataColumn(label: Text(l10n.statsColumnAttempts)),
                DataColumn(label: Text(l10n.statsColumnAccuracy)),
                DataColumn(label: Text(l10n.statsColumnAvgTime)),
              ],
              rows: rows.map((row) {
                final attempts = (row['attempts'] as int?) ?? 0;
                final correct = (row['correct'] as int?) ?? 0;
                final avg = (row['average_ms'] as num?)?.toDouble();
                return DataRow(
                  cells: [
                    DataCell(Text('${row['label'] ?? l10n.statsUncategorized}')),
                    DataCell(Text('${row['total']}')),
                    DataCell(Text('$attempts')),
                    DataCell(
                      Text(
                        attempts == 0
                            ? '-'
                            : '${(correct / attempts * 100).toStringAsFixed(1)}%',
                      ),
                    ),
                    DataCell(
                      Text(
                        avg == null
                            ? '-'
                            : l10n.statsSeconds((avg / 1000).toStringAsFixed(1)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showPendingSyncDialog(
  BuildContext context,
  AppController controller,
) => showDialog<void>(
  context: context,
  builder: (context) => _PendingSyncDialog(controller: controller),
);

class _PendingSyncDialog extends StatefulWidget {
  const _PendingSyncDialog({required this.controller});

  final AppController controller;

  @override
  State<_PendingSyncDialog> createState() => _PendingSyncDialogState();
}

class _PendingSyncDialogState extends State<_PendingSyncDialog> {
  late List<Map<String, Object?>> items;
  final selected = <String>{};
  bool deleting = false;

  @override
  void initState() {
    super.initState();
    items = widget.controller.pendingSyncItems();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.pendingDialogTitle),
      content: SizedBox(
        width: 720,
        child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text(l10n.pendingDialogEmpty)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.pendingDialogNote),
                  Row(
                    children: [
                      Checkbox(
                        value: selected.length == items.length,
                        tristate:
                            selected.isNotEmpty && selected.length < items.length,
                        onChanged: deleting
                            ? null
                            : (value) => setState(() {
                                selected.clear();
                                if (value == true) {
                                  selected.addAll(
                                    items.map((e) => e['outbox_id']! as String),
                                  );
                                }
                              }),
                      ),
                      Text(l10n.pendingSelectAll(items.length)),
                    ],
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final id = item['outbox_id']! as String;
                        final error = item['last_error']?.toString();
                        return CheckboxListTile(
                          value: selected.contains(id),
                          onChanged: deleting
                              ? null
                              : (value) => setState(() {
                                  if (value == true) {
                                    selected.add(id);
                                  } else {
                                    selected.remove(id);
                                  }
                                }),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${_syncEntityLabel(l10n, item['entity_type'])} · '
                            '${_syncOperationLabel(l10n, item['operation'])}',
                          ),
                          subtitle: Text(
                            l10n.pendingItemSubtitle(
                              '${item['entity_id']}',
                              '${item['created_at_utc']}',
                            ) +
                                (error == null || error.isEmpty
                                    ? ''
                                    : l10n.pendingItemErrorLine(error)),
                          ),
                          isThreeLine: error != null && error.isNotEmpty,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: deleting ? null : () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: selected.isEmpty || deleting ? null : _deleteSelected,
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.pendingDeleteSelected(selected.length)),
        ),
      ],
    );
  }

  Future<void> _deleteSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pendingDeleteConfirmTitle),
        content: Text(l10n.pendingDeleteConfirmBody(selected.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.pendingDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => deleting = true);
    await widget.controller.deletePendingSyncItems(selected);
    if (!mounted) return;
    setState(() {
      items = widget.controller.pendingSyncItems();
      selected.clear();
      deleting = false;
    });
  }
}

String _syncEntityLabel(AppLocalizations l10n, Object? type) =>
    switch (type?.toString()) {
      'answer_event' => l10n.syncEntityAnswerEvent,
      'paper_attempt' => l10n.syncEntityPaperAttempt,
      'paper_archive_ack' => l10n.syncEntityArchiveAck,
      'question_progress_control' => l10n.syncEntityProgressControl,
      'question_bank' => l10n.syncEntityQuestionBank,
      'question' => l10n.syncEntityQuestion,
      'question_media_chunk' => l10n.syncEntityMediaChunk,
      'setting' => l10n.syncEntitySetting,
      _ => type?.toString() ?? l10n.syncEntityUnknown,
    };

String _syncOperationLabel(AppLocalizations l10n, Object? operation) =>
    switch (operation?.toString()) {
      'upsert' => l10n.syncOperationUpsert,
      'insert' => l10n.syncOperationInsert,
      'delete' => l10n.commonDelete,
      _ => operation?.toString() ?? l10n.syncOperationUnknown,
    };

class SyncBackupPage extends StatefulWidget {
  const SyncBackupPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<SyncBackupPage> createState() => _SyncBackupPageState();
}

class _SyncBackupPageState extends State<SyncBackupPage> {
  late final TextEditingController supabaseUrl;
  late final TextEditingController publishableKey;
  late final TextEditingController email;
  final password = TextEditingController();
  String? status;
  @override
  void initState() {
    super.initState();
    supabaseUrl = TextEditingController(
      text:
          widget.controller.database.getSetting<String>('supabase_url') ??
          SupabaseConfig.projectUrl,
    );
    publishableKey = TextEditingController(
      text:
          widget.controller.database.getSetting<String>(
            'supabase_publishable_key',
          ) ??
          SupabaseConfig.publishableKey,
    );
    email = TextEditingController(
      text: widget.controller.database.getSetting<String>('sync_email') ?? '',
    );
  }

  @override
  void dispose() {
    supabaseUrl.dispose();
    publishableKey.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasSavedSession = widget.controller.hasSavedSyncSession;
    final errors = widget.controller.database.syncErrors();
    final conflicts = widget.controller.database.syncConflicts();
    final backups = widget.controller.database.backupHistory();
    return PageFrame(
      title: l10n.syncTitle,
      child: ListView(
        children: [
          Text(
            l10n.syncCloudTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(l10n.syncCloudDesc),
          if (hasSavedSession)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(
                  widget.controller.savedSyncEmail.isEmpty
                      ? l10n.syncSessionSaved
                      : l10n.syncLoggedInAs(widget.controller.savedSyncEmail),
                ),
                subtitle: Text(l10n.syncSessionAutoRenew),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: supabaseUrl,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.syncFieldUrl,
              hintText: l10n.syncHintUrl,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: publishableKey,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Publishable Key',
              hintText: 'sb_publishable_…',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.syncFieldEmail,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: password,
            obscureText: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.syncFieldPassword,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _loginAndSync,
                icon: const Icon(Icons.login),
                label: Text(
                  hasSavedSession
                      ? l10n.syncRelogin
                      : l10n.syncLoginAndSync,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _sync,
                icon: const Icon(Icons.sync),
                label: Text(l10n.syncNow(widget.controller.stats.pendingSync)),
              ),
              OutlinedButton.icon(
                onPressed: _clearSession,
                icon: const Icon(Icons.logout),
                label: Text(l10n.syncClearSession),
              ),
            ],
          ),
          if (status != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SelectableText(status!),
            ),
          if (errors.isNotEmpty) ...[
            Text(
              l10n.syncErrorsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...errors.map(
              (e) => ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text('${e['entity_type']} · ${e['entity_id']}'),
                subtitle: Text('${e['last_error']}'),
              ),
            ),
          ],
          if (conflicts.isNotEmpty) ...[
            Text(
              l10n.syncConflictsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...conflicts.map(
              (e) => ListTile(
                leading: const Icon(Icons.compare_arrows, color: Colors.orange),
                title: Text('${e['entity_type']} · ${e['entity_id']}'),
                subtitle: Text(l10n.syncConflictDesc),
              ),
            ),
          ],
          const Divider(height: 36),
          Text(
            l10n.syncBackupTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (!Platform.isWindows)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Text(l10n.syncStorageAndroidNote),
            ),
          _storagePathTile(
            icon: Icons.storage_outlined,
            title: l10n.syncStorageDatabase,
            path: widget.controller.paths.database.path,
            isDefault: widget.controller.paths.usesDefaultDatabase,
            onChoose: () => _chooseStorageDirectory(_StorageTarget.database),
            onReset: () => _resetStorageDirectory(_StorageTarget.database),
          ),
          _storagePathTile(
            icon: Icons.backup_outlined,
            title: l10n.syncStorageBackups,
            path: widget.controller.paths.backups.path,
            isDefault: widget.controller.paths.usesDefaultBackups,
            onChoose: () => _chooseStorageDirectory(_StorageTarget.backups),
            onReset: () => _resetStorageDirectory(_StorageTarget.backups),
          ),
          _storagePathTile(
            icon: Icons.folder_outlined,
            title: l10n.syncStorageExports,
            path: widget.controller.paths.exports.path,
            isDefault: widget.controller.paths.usesDefaultExports,
            onChoose: () => _chooseStorageDirectory(_StorageTarget.exports),
            onReset: () => _resetStorageDirectory(_StorageTarget.exports),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _backup,
                icon: const Icon(Icons.backup),
                label: Text(l10n.syncBackupNow),
              ),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: Text(l10n.syncResetAfterBackup),
              ),
            ],
          ),
          ...backups
              .take(10)
              .map(
                (b) => ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: Text('${b['reason']} · ${b['created_at_utc']}'),
                  subtitle: SelectableText('${b['path']}'),
                  trailing: Text('${b['integrity_result']}'),
                ),
              ),
        ],
      ),
    );
  }

  Widget _storagePathTile({
    required IconData icon,
    required String title,
    required String path,
    required bool isDefault,
    required VoidCallback onChoose,
    required VoidCallback onReset,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text('$title${isDefault ? l10n.syncDefaultSuffix : ''}'),
        subtitle: SelectableText(path),
        trailing: Platform.isWindows
            ? Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: onChoose,
                    child: Text(l10n.commonChoose),
                  ),
                  TextButton(
                    onPressed: isDefault ? null : onReset,
                    child: Text(l10n.syncResetToDefault),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _chooseStorageDirectory(_StorageTarget target) async {
    final path = await widget.controller.chooseDirectory();
    if (path == null || !mounted) return;
    await _applyStorageDirectory(target, Directory(path));
  }

  Future<void> _resetStorageDirectory(_StorageTarget target) =>
      _applyStorageDirectory(target, null);

  Future<void> _applyStorageDirectory(
    _StorageTarget target,
    Directory? directory,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (target == _StorageTarget.database) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.syncMoveDbTitle),
            content: Text(l10n.syncMoveDbBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.syncMoveDbConfirm),
              ),
            ],
          ),
        );
        if (ok != true) return;
        setState(() => status = l10n.syncMovingDb);
        await widget.controller.moveDatabaseTo(directory);
        if (mounted) {
          setState(
            () => status = l10n.syncMoveDbDone(
              widget.controller.paths.database.path,
            ),
          );
        }
      } else if (target == _StorageTarget.backups) {
        widget.controller.updateBackupsDirectory(directory);
        setState(() => status = l10n.syncBackupsDirUpdated);
      } else {
        widget.controller.updateExportsDirectory(directory);
        setState(() => status = l10n.syncExportsDirUpdated);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => status = l10n.syncStorageChangeFailed(
            localizedErrorText(l10n, error),
          ),
        );
      }
    }
  }

  Future<void> _sync() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => status = l10n.syncInProgress);
    final report = await widget.controller.synchronizeSavedSession();
    _showSyncReport(report);
  }

  Future<void> _loginAndSync() async {
    // Release the native Windows text-input connection before the async login
    // rebuilds this page. The controller is intentionally not cleared while the
    // password field may still own a platform text-input client.
    FocusManager.instance.primaryFocus?.unfocus();
    final enteredPassword = password.text;
    final l10n = AppLocalizations.of(context)!;
    setState(() => status = l10n.syncLoginInProgress);
    try {
      final report = await widget.controller.signInAndSynchronize(
        supabaseUrl: supabaseUrl.text,
        publishableKey: publishableKey.text,
        email: email.text,
        password: enteredPassword,
      );
      _showSyncReport(report);
    } catch (error) {
      if (mounted) {
        setState(() => status = l10n.syncLoginFailed(localizedErrorText(l10n, error)));
      }
    } finally {
      password.clear();
    }
  }

  void _showSyncReport(SyncReport report) {
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      setState(
        () => status = l10n.syncReportDone(
          localizedErrorText(l10n, report),
          report.uploaded,
          report.downloaded,
          report.failed,
        ),
      );
    }
  }

  void _clearSession() {
    final l10n = AppLocalizations.of(context)!;
    FocusManager.instance.primaryFocus?.unfocus();
    widget.controller.clearLocalSyncSession();
    setState(() => status = l10n.syncSessionCleared);
  }

  void _backup() {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = widget.controller.createBackup();
      setState(() => status = l10n.syncBackupDone(path));
    } catch (error) {
      setState(() => status = l10n.syncBackupFailed('$error'));
    }
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context)!;
    final typed = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.syncResetDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.syncResetDialogBody(l10n.commonConfirmResetPhrase)),
            TextField(controller: typed, autofocus: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              typed.text == l10n.commonConfirmResetPhrase,
            ),
            child: Text(l10n.syncResetConfirmAction),
          ),
        ],
      ),
    );
    typed.dispose();
    if (ok == true) {
      final backupPath = await widget.controller.resetCurrentBank();
      if (mounted) {
        setState(() => status = l10n.syncResetDone(backupPath));
      }
    }
  }
}

enum _StorageTarget { database, backups, exports }

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PageFrame(
      title: l10n.settingsTitle,
      child: ListView(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsDarkMode),
            value: controller.darkMode,
            onChanged: (value) => controller.updateAppearance(dark: value),
          ),
          Text(l10n.settingsFontScale(controller.fontScale.toStringAsFixed(2))),
          Slider(
            value: controller.fontScale,
            min: 0.85,
            max: 1.5,
            divisions: 13,
            onChanged: (value) => controller.updateAppearance(font: value),
          ),
          Text(l10n.settingsLineHeight(controller.lineHeight.toStringAsFixed(2))),
          Slider(
            value: controller.lineHeight,
            min: 1.2,
            max: 2,
            divisions: 16,
            onChanged: (value) => controller.updateAppearance(line: value),
          ),
          if (!Platform.isAndroid) ...[
            Text(
              l10n.settingsContentWidth(
                controller.contentWidth.toInt().toString(),
              ),
            ),
            Slider(
              value: controller.contentWidth,
              min: 680,
              max: 1400,
              divisions: 18,
              onChanged: (value) => controller.updateAppearance(width: value),
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(l10n.settingsLanguageHelp),
            trailing: DropdownButton<String>(
              value: controller.localeTag,
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.languageSystem),
                ),
                DropdownMenuItem(
                  value: 'zh',
                  child: Text(l10n.languageChinese),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.languageEnglish),
                ),
              ],
              onChanged: (value) {
                if (value != null) controller.setLocaleTag(value);
              },
            ),
          ),
          const Divider(),
          Text(
            l10n.settingsScoringTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.settingsScoringHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              l10n.settingsScoringSingleScore(
                controller.paperScoringPolicy.singleScore.toStringAsFixed(1),
              ),
            ),
            Slider(
              key: const ValueKey('settings-scoring-single'),
              value: controller.paperScoringPolicy.singleScore.clamp(0, 5),
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (value) => controller.updatePaperScoringPolicy(
                controller.paperScoringPolicy.copyWith(singleScore: value),
              ),
            ),
            Text(
              l10n.settingsScoringMultipleScore(
                controller.paperScoringPolicy.multipleScore.toStringAsFixed(1),
              ),
            ),
            Slider(
              key: const ValueKey('settings-scoring-multiple'),
              value: controller.paperScoringPolicy.multipleScore.clamp(0, 10),
              min: 0,
              max: 10,
              divisions: 20,
              onChanged: (value) => controller.updatePaperScoringPolicy(
                controller.paperScoringPolicy.copyWith(multipleScore: value),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              key: const ValueKey('settings-scoring-partial'),
              title: Text(l10n.settingsScoringPartialCredit),
              value: controller.paperScoringPolicy.partialCredit,
              onChanged: (value) => controller.updatePaperScoringPolicy(
                controller.paperScoringPolicy.copyWith(partialCredit: value),
              ),
            ),
            Text(
              l10n.settingsScoringPerOption(
                controller.paperScoringPolicy.partialPerCorrectOption
                    .toStringAsFixed(1),
              ),
            ),
            Slider(
              key: const ValueKey('settings-scoring-per-option'),
              value: controller.paperScoringPolicy.partialPerCorrectOption
                  .clamp(0, 2),
              min: 0,
              max: 2,
              divisions: 20,
              onChanged: controller.paperScoringPolicy.partialCredit
                  ? (value) => controller.updatePaperScoringPolicy(
                      controller.paperScoringPolicy.copyWith(
                        partialPerCorrectOption: value,
                      ),
                    )
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              key: const ValueKey('settings-scoring-wrong-zero'),
              title: Text(l10n.settingsScoringWrongZero),
              value: controller.paperScoringPolicy.wrongOptionMakesZero,
              onChanged: (value) => controller.updatePaperScoringPolicy(
                controller.paperScoringPolicy.copyWith(
                  wrongOptionMakesZero: value,
                ),
              ),
            ),
            Text(
              l10n.settingsScoringQaNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              key: const ValueKey('settings-render-markup'),
              title: Text(l10n.settingsRenderMarkupTitle),
              subtitle: Text(l10n.settingsRenderMarkupDesc),
              value: controller.renderQuestionMarkup,
              onChanged: controller.setRenderQuestionMarkup,
            ),
            const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsRandomWrongReturn),
            subtitle: Text(l10n.settingsRandomWrongReturnDesc),
            value:
                controller.database.getSetting<bool>(
                  'random_errors_return_wrong',
                ) ??
                true,
            onChanged: controller.setRandomErrorsReturnToWrong,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsVersion),
            subtitle: Text(
              '${l10n.appTitle} ${Platform.isAndroid ? 'Android' : 'Windows'} '
              '${kAppVersion == '开发版' ? l10n.settingsDevVersion : kAppVersion}\n'
              '${l10n.settingsDeviceId(controller.database.deviceId)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _BankPicker extends StatelessWidget {
  const _BankPicker({required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 720 || size.shortestSide < 600;
    return Padding(
      padding: EdgeInsets.only(right: mobile ? 6 : 16),
      child: SizedBox(
        width: mobile ? 142 : null,
        child: DropdownButton<String>(
          isExpanded: mobile,
          value: controller.currentBank?.id,
          hint: Text(l10n.banksPickerHint),
          items: controller.banks
              .map(
                (bank) => DropdownMenuItem(
                  value: bank.id,
                  child: Text(
                    '${bank.name} (${bank.questionCount})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) controller.selectBank(value);
          },
        ),
      ),
    );
  }
}

String _status(AppLocalizations l10n, AttemptStatus status) => switch (status) {
  AttemptStatus.draft => l10n.attemptStatusDraft,
  AttemptStatus.submitted => l10n.attemptStatusSubmitted,
  AttemptStatus.abandoned => l10n.attemptStatusAbandoned,
};
String _mode(AppLocalizations l10n, PracticeMode mode) => switch (mode) {
  PracticeMode.unseen => l10n.modeUnseen,
  PracticeMode.wrongReview => l10n.modeWrongReview,
  PracticeMode.random => l10n.modeRandom,
  PracticeMode.favorite => l10n.modeFavorite,
  PracticeMode.uncertain => l10n.modeUncertain,
};
