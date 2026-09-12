import 'dart:io';

import 'package:flutter/material.dart';
import '../app_controller.dart';
import '../domain/models.dart';
import '../domain/question_text.dart';
import '../domain/policies.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_theme.dart';

/// 历史显示行为：剥离标记（无换行语义）。新代码请用 controller.questionText。
String readableText(String value) => plainText(value);

/// 编辑题库中的一题，保存后覆盖题库原题记录（同一 question_id，内容版本 +1）；
/// 已提交试卷持有的交卷快照不受影响。
Future<Question?> showQuestionEditDialog(
  BuildContext context,
  Question question, {
  String? title,
}) => showDialog<Question>(
  context: context,
  builder: (context) => _QuestionEditDialog(question: question, title: title),
);

class _QuestionEditDialog extends StatefulWidget {
  const _QuestionEditDialog({required this.question, this.title});

  final Question question;
  final String? title;

  @override
  State<_QuestionEditDialog> createState() => _QuestionEditDialogState();
}

class _QuestionEditDialogState extends State<_QuestionEditDialog> {
  late final TextEditingController stem;
  late final TextEditingController answer;
  late final TextEditingController explanation;
  late final TextEditingController knowledgePoint;
  late final Map<String, TextEditingController> optionControllers;
  String? error;

  Question get question => widget.question;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    stem = TextEditingController(text: question.stem);
    answer = TextEditingController(text: question.answers.join());
    explanation = TextEditingController(text: question.explanation);
    knowledgePoint = TextEditingController(text: question.knowledgePoint);
    optionControllers = {
      for (final key in const ['A', 'B', 'C', 'D', 'E'])
        key: TextEditingController(text: question.options[key] ?? ''),
    };
  }

  @override
  void dispose() {
    stem.dispose();
    answer.dispose();
    explanation.dispose();
    knowledgePoint.dispose();
    for (final controller in optionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.title ??
          _l10n.questionEditDefaultTitle(question.externalId ?? question.id),
    ),
    content: SizedBox(
      width: 720,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              key: const ValueKey('question-edit-stem'),
              controller: stem,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _l10n.questionEditStemLabel,
              ),
            ),
            if (question.type != QuestionType.qa)
              for (final entry in optionControllers.entries)
                TextField(
                  key: ValueKey('question-edit-option-${entry.key}'),
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: _l10n.questionEditOptionLabel(entry.key),
                  ),
                ),
            TextField(
              key: const ValueKey('question-edit-answer'),
              controller: answer,
              maxLines: question.type == QuestionType.qa ? 5 : 1,
              decoration: InputDecoration(
                labelText: question.type == QuestionType.qa
                    ? _l10n.questionEditQaAnswerLabel
                    : _l10n.questionEditAnswerLabel(
                        question.type == QuestionType.single ? 'A' : 'AC',
                      ),
              ),
            ),
            TextField(
              key: const ValueKey('question-edit-explanation'),
              controller: explanation,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: _l10n.questionEditExplanationLabel,
              ),
            ),
            TextField(
              key: const ValueKey('question-edit-knowledge-point'),
              controller: knowledgePoint,
              decoration: InputDecoration(
                labelText: _l10n.questionEditKnowledgePointLabel,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                key: const ValueKey('question-edit-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
      FilledButton(
        key: const ValueKey('question-edit-save'),
        onPressed: _save,
        child: Text(_l10n.questionEditSave),
      ),
    ],
  );

  void _save() {
    if (question.type == QuestionType.qa) {
      // 问答题：无选项，答案列为参考答案原文（可选）。
      final reference = answer.text.trim();
      if (stem.text.trim().isEmpty) {
        setState(() => error = _l10n.questionEditValidationError);
        return;
      }
      Navigator.pop(
        context,
        Question(
          id: question.id,
          bankId: question.bankId,
          externalId: question.externalId,
          contentVersion: question.contentVersion,
          type: QuestionType.qa,
          stem: stem.text.trim(),
          options: const {},
          answers: [if (reference.isNotEmpty) reference],
          explanation: explanation.text.trim(),
          knowledgePoint: knowledgePoint.text.trim(),
          source: question.source,
          year: question.year,
          chapter: question.chapter,
          tags: question.tags,
          media: question.media,
          scoringRule: question.scoringRule,
          isActive: question.isActive,
        ),
      );
      return;
    }
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
        (question.type == QuestionType.single && answers.length != 1) ||
        answers.any((value) => !options.containsKey(value));
    if (invalid) {
      setState(() {
        error = _l10n.questionEditValidationError;
      });
      return;
    }
    Navigator.pop(
      context,
      Question(
        id: question.id,
        bankId: question.bankId,
        externalId: question.externalId,
        contentVersion: question.contentVersion,
        type: question.type,
        stem: stem.text.trim(),
        options: options,
        answers: answers,
        explanation: explanation.text.trim(),
        knowledgePoint: knowledgePoint.text.trim(),
        source: question.source,
        year: question.year,
        chapter: question.chapter,
        tags: question.tags,
        media: question.media,
        scoringRule: question.scoringRule,
        isActive: question.isActive,
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.controller,
    required this.question,
    required this.number,
    required this.selected,
    required this.onToggle,
    this.revealed = false,
    this.readOnly = false,
    this.uncertain = false,
    this.selectionRequired = false,
    this.onUncertain,
    this.onQaTextChanged,
  });
  final AppController controller;
  final Question question;
  final int number;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final bool revealed;
  final bool readOnly;
  final bool uncertain;
  final bool selectionRequired;
  final VoidCallback? onUncertain;

  /// 问答题作答回调；为 null 且非只读时不显示输入框。
  final ValueChanged<String>? onQaTextChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = revealed ? AnswerPolicy.score(question, selected) : null;
    final mobile = MediaQuery.sizeOf(context).shortestSide < 600;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final success = dark ? const Color(0xff65d6a5) : ExamColors.success;
    final danger = dark ? const Color(0xffff8f88) : ExamColors.danger;
    final warning = dark ? const Color(0xffffbd66) : ExamColors.warning;
    // 网页式拖选：SelectionArea 让题干、选项和解析可一次框选后 Ctrl+C 复制。
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$number · ${switch (question.type) {
                  QuestionType.single => l10n.questionTypeSingleShort,
                  QuestionType.multiple => l10n.questionTypeMultipleShort,
                  QuestionType.qa => l10n.questionTypeQaShort,
                }}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            if (onUncertain != null)
              readOnly
                  ? IconButton(
                      key: const ValueKey('question-uncertain-action'),
                      tooltip: uncertain
                          ? l10n.questionUncertainTooltipRemove
                          : l10n.questionMarkUncertain,
                      onPressed: onUncertain,
                      style: IconButton.styleFrom(
                        foregroundColor: uncertain ? warning : scheme.onSurface,
                        backgroundColor: uncertain
                            ? warning.withValues(alpha: 0.18)
                            : scheme.surfaceContainerLow,
                        side: BorderSide(
                          color: uncertain
                              ? warning.withValues(alpha: 0.6)
                              : scheme.outline,
                        ),
                      ),
                      icon: Icon(
                        uncertain ? Icons.help : Icons.help_outline,
                        size: 21,
                      ),
                    )
                  : TextButton.icon(
                      key: const ValueKey('question-uncertain-action'),
                      onPressed: onUncertain,
                      style: TextButton.styleFrom(
                        foregroundColor: uncertain ? warning : scheme.onSurface,
                        backgroundColor: uncertain
                            ? warning.withValues(alpha: 0.12)
                            : scheme.surfaceContainerLow,
                        side: BorderSide(
                          color: uncertain
                              ? warning.withValues(alpha: 0.55)
                              : scheme.outline,
                        ),
                      ),
                      icon: Icon(
                        uncertain ? Icons.flag : Icons.flag_outlined,
                        size: 19,
                      ),
                      label: Text(
                        uncertain
                            ? l10n.questionMarkedUncertain
                            : l10n.questionMarkUncertain,
                      ),
                    ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          controller.questionText(question.stem),
          style: TextStyle(
            fontSize: mobile ? 17 : 18,
            height: controller.lineHeight,
            fontWeight: FontWeight.w600,
          ),
        ),
        for (final media in question.media) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final path = controller.mediaPath(question, media);
              return path == null
                  ? Text(
                      l10n.questionMediaMissing(media),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : Semantics(
                      label: l10n.questionImageSemantics,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: mobile ? 320 : 240,
                        ),
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Image.file(File(path)),
                        ),
                      ),
                    );
            },
          ),
        ],
        if (selectionRequired) ...[
          const SizedBox(height: 16),
          Container(
            key: const ValueKey('answer-instruction'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: scheme.error.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: scheme.error, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    l10n.questionSelectAnswerRequired,
                    style: TextStyle(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 12),
        ...question.options.entries.map((entry) {
          final checked = selected.contains(entry.key);
          Color? tileColor;
          Color borderColor = scheme.outline;
          Widget? trailing;
          if (revealed) {
            final correct = question.answers.contains(entry.key);
            if (correct) {
              tileColor = success.withValues(alpha: 0.11);
              borderColor = success.withValues(alpha: 0.55);
              trailing = _OptionStatus(
                icon: Icons.check_circle,
                label: l10n.questionCorrectAnswerLabel,
                color: success,
              );
            } else if (checked) {
              tileColor = danger.withValues(alpha: 0.1);
              borderColor = danger.withValues(alpha: 0.55);
              trailing = _OptionStatus(
                icon: Icons.cancel,
                label: l10n.questionYourChoiceLabel,
                color: danger,
              );
            }
          } else if (checked) {
            tileColor = scheme.primary.withValues(alpha: 0.08);
            borderColor = scheme.primary;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Material(
              color: tileColor ?? scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: borderColor,
                  width:
                      checked ||
                          (revealed && question.answers.contains(entry.key))
                      ? 1.7
                      : 1,
                ),
              ),
              child: CheckboxListTile(
                value: checked,
                onChanged: readOnly ? null : (_) => onToggle(entry.key),
                checkboxShape: question.type == QuestionType.single
                    ? const CircleBorder()
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                title: GestureDetector(
                  onTap: readOnly ? null : () => onToggle(entry.key),
                  child: Text(
                    '${entry.key}. ${controller.questionText(entry.value)}',
                    style: TextStyle(
                      height: controller.lineHeight,
                      fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                secondary: trailing,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          );
        }),
        if (question.type == QuestionType.qa) ...[
          const SizedBox(height: 12),
          if (readOnly)
            _QaReadOnlyAnswer(
              question: question,
              selected: selected,
              revealed: revealed,
              l10n: l10n,
            )
          else if (onQaTextChanged != null)
            _QaAnswerField(
              key: const ValueKey('qa-answer-field'),
              initialText: selected.firstOrNull,
              onChanged: onQaTextChanged!,
            ),
        ],
        if (revealed && question.type != QuestionType.qa) ...[
          const SizedBox(height: 14),
          _AnswerResultPanel(
            controller: controller,
            question: question,
            selected: selected,
            result: result!,
          ),
        ],
      ],
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 20),
        child: SelectionArea(child: content),
      ),
    );
  }
}

/// 问答题作答输入框：自带 TextEditingController，重建时保留光标与文本。
class _QaAnswerField extends StatefulWidget {
  const _QaAnswerField({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  final String? initialText;
  final ValueChanged<String> onChanged;

  @override
  State<_QaAnswerField> createState() => _QaAnswerFieldState();
}

class _QaAnswerFieldState extends State<_QaAnswerField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      key: const ValueKey('qa-answer-text-field'),
      controller: _controller,
      maxLines: 5,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: l10n.questionQaAnswerLabel,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// 只读（交卷后回顾）的问答题作答展示：用户原文 + 参考答案。
class _QaReadOnlyAnswer extends StatelessWidget {
  const _QaReadOnlyAnswer({
    required this.question,
    required this.selected,
    required this.revealed,
    required this.l10n,
  });

  final Question question;
  final Set<String> selected;
  final bool revealed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final answer = selected.firstOrNull?.trim() ?? '';
    final reference = question.answers.join('\n').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.questionQaAnswerLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: dark ? ExamColors.darkMuted : ExamColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            answer.isEmpty ? l10n.questionNotAnswered : answer,
            style: TextStyle(
              height: 1.5,
              fontStyle: answer.isEmpty ? FontStyle.italic : FontStyle.normal,
              color: answer.isEmpty
                  ? (dark ? ExamColors.darkMuted : ExamColors.muted)
                  : null,
            ),
          ),
          if (revealed) ...[
            const SizedBox(height: 10),
            Text(
              l10n.questionQaReferenceLabel,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: dark ? const Color(0xff65d6a5) : ExamColors.success,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              reference.isEmpty ? l10n.questionQaReferenceEmpty : reference,
              style: TextStyle(
                height: 1.5,
                fontStyle: reference.isEmpty ? FontStyle.italic : FontStyle.normal,
                color: reference.isEmpty
                    ? (dark ? ExamColors.darkMuted : ExamColors.muted)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionStatus extends StatelessWidget {
  const _OptionStatus({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 19),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _AnswerResultPanel extends StatelessWidget {
  const _AnswerResultPanel({
    required this.controller,
    required this.question,
    required this.selected,
    required this.result,
  });

  final AppController controller;
  final Question question;
  final Set<String> selected;
  final ScoreResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final correct = result.isAnswered && result.isCompletelyCorrect;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = correct
        ? dark
              ? const Color(0xff65d6a5)
              : ExamColors.success
        : dark
        ? const Color(0xffff8f88)
        : ExamColors.danger;
    final title = !result.isAnswered
        ? l10n.questionResultUnanswered
        : correct
        ? l10n.questionResultCorrect
        : l10n.questionResultWrong;
    final yourAnswer = selected.isEmpty
        ? l10n.questionNotAnswered
        : AnswerPolicy.normalize(selected).join(l10n.questionAnswerSeparator);
    final explanation = controller.questionText(question.explanation).trim();
    return Container(
      key: const ValueKey('answer-result-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 26,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.questionScoreBadge(result.score, result.maxScore),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AnswerBadge(
                label: l10n.questionYourAnswerLabel,
                value: yourAnswer,
              ),
              _AnswerBadge(
                label: l10n.questionCorrectAnswerLabel,
                value: question.answers.join(l10n.questionAnswerSeparator),
                emphasized: true,
              ),
            ],
          ),
          const Divider(height: 27),
          Text(
            l10n.questionExplanationTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            explanation.isEmpty ? l10n.questionNoExplanation : explanation,
            style: TextStyle(height: controller.lineHeight),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.lightbulb_outline,
                text: question.knowledgePoint.isEmpty
                    ? l10n.questionKnowledgePointEmpty
                    : question.knowledgePoint,
              ),
              _MetaChip(
                icon: Icons.source_outlined,
                text: question.source.isEmpty
                    ? l10n.questionSourceEmpty
                    : question.source,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerBadge extends StatelessWidget {
  const _AnswerBadge({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final success = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff65d6a5)
        : ExamColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? success.withValues(alpha: 0.1)
            : scheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: emphasized ? success.withValues(alpha: 0.35) : scheme.outline,
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label  ', style: const TextStyle(fontSize: 12)),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.width = 170,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final double width;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('stat-tile-$label'),
      width: width,
      height: 112,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (color ?? Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    size: 23,
                    color: color ?? Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? ExamColors.darkMuted
                              : ExamColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatDuration(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(duration.inHours)}:${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
}
