import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../domain/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/windows_omr_scanner.dart';
import '../services/windows_omr_file_picker.dart';
import 'error_messages.dart';
import 'app_theme.dart';
import 'question_widgets.dart' show formatDuration;

typedef WindowsOmrRecognizer =
    Future<WindowsOmrResult> Function(
      File image,
      File template,
      int expectedQuestions,
    );

/// Windows-only review step. Recognition remains in memory until the explicit
/// confirmation below invokes the existing paper-submission transaction.
class WindowsOmrReviewPage extends StatefulWidget {
  const WindowsOmrReviewPage({
    super.key,
    required this.controller,
    required this.attempt,
    this.pickImage,
    this.pasteImage,
    this.recognize,
  });

  final AppController controller;
  final PaperAttempt attempt;
  final Future<File?> Function()? pickImage;
  final Future<File?> Function()? pasteImage;
  final WindowsOmrRecognizer? recognize;

  @override
  State<WindowsOmrReviewPage> createState() => _WindowsOmrReviewPageState();
}

class _WindowsOmrReviewPageState extends State<WindowsOmrReviewPage> {
  List<Set<String>> selections = const [];
  WindowsOmrResult? result;
  File? sourceImage;
  File? _temporaryClipboardImage;
  Matrix4 overlayTransform = Matrix4.identity();
  Offset _overlayOffset = Offset.zero;
  double _overlayScale = 1;
  double _overlayRotation = 0;
  Offset _gestureStartFocal = Offset.zero;
  Offset _gestureStartOffset = Offset.zero;
  double _gestureStartScale = 1;
  double _gestureStartRotation = 0;
  final manuallyChanged = <int>{};
  bool busy = false;
  bool completed = false;
  String? error;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  bool get hasResult => selections.length == widget.attempt.questions.length;

  Future<void> _pickAndRecognize() => _obtainAndRecognize(
    widget.pickImage ?? WindowsOmrFilePicker.pickImage,
  );

  Future<void> _pasteAndRecognize() => _obtainAndRecognize(
    widget.pasteImage ?? WindowsOmrFilePicker.pasteImage,
    clipboard: true,
  );

  Future<void> _obtainAndRecognize(
    Future<File?> Function() obtain, {
    bool clipboard = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (!Platform.isWindows &&
        widget.pickImage == null &&
        widget.pasteImage == null) {
      setState(() => error = l10n.omrWindowsOnly);
      return;
    }
    try {
      final image = await obtain();
      if (image == null || !mounted) return;
      _deleteTemporaryClipboardImage();
      if (clipboard && WindowsOmrFilePicker.isTemporaryClipboardImage(image)) {
        _temporaryClipboardImage = image;
      }
      await _recognizeImage(image);
    } catch (exception) {
      if (mounted) {
        setState(
          () => error = l10n.omrImportFailed(localizedErrorText(l10n, exception)),
        );
      }
    }
  }

  Future<void> _recognizeImage(File image) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      busy = true;
      error = null;
      selections = const [];
      result = null;
      sourceImage = image;
      overlayTransform = Matrix4.identity();
      _overlayOffset = Offset.zero;
      _overlayScale = 1;
      _overlayRotation = 0;
      manuallyChanged.clear();
    });
    Directory? templateDirectory;
    try {
      templateDirectory = Directory.systemTemp.createTempSync(
        'personal-exam-omr-template-',
      );
      // 答题卡气泡按选择题压缩编号（q1..qM）：识别结果按压缩顺序
      // 映射回 attempt 中的选择题位；问答题不参与机读。
      final choicePositions = <int>[
        for (var index = 0; index < widget.attempt.questions.length; index++)
          if (widget.attempt.questions[index].question.type !=
              QuestionType.qa)
            index,
      ];
      final template = widget.controller.writeTemporaryOmrTemplate(
        widget.attempt,
        templateDirectory,
      );
      final recognized =
          await (widget.recognize?.call(
                image,
                template,
                choicePositions.length,
              ) ??
              WindowsOmrScanner().check(
                image: image,
                template: template,
                expectedQuestions: choicePositions.length,
              ));
      if (!mounted) return;
      final values = List<Set<String>>.generate(
        widget.attempt.questions.length,
        (index) => <String>{},
        growable: false,
      );
      for (var i = 0; i < recognized.questions.length && i < choicePositions.length; i++) {
        values[choicePositions[i]] = Set<String>.from(
          recognized.questions[i].selected,
        );
      }
      // 重扫时保留问答题已录入的人工文本（识别结果不含问答题）。
      if (selections.isNotEmpty) {
        for (var index = 0; index < values.length; index++) {
          if (widget.attempt.questions[index].question.type ==
                  QuestionType.qa &&
              selections[index].isNotEmpty) {
            values[index] = selections[index];
          }
        }
      }
      setState(() {
        selections = values;
        result = recognized;
      });
    } catch (exception) {
      if (_temporaryClipboardImage?.path == image.path) {
        _deleteTemporaryClipboardImage();
        sourceImage = null;
      }
      if (mounted) {
        setState(
          () => error = l10n.omrRecognizeFailed(
            localizedErrorText(l10n, exception),
          ),
        );
      }
    } finally {
      if (templateDirectory?.existsSync() ?? false) {
        templateDirectory!.deleteSync(recursive: true);
      }
      if (mounted) setState(() => busy = false);
    }
  }

  void _deleteTemporaryClipboardImage() {
    final file = _temporaryClipboardImage;
    _temporaryClipboardImage = null;
    if (file != null && file.existsSync()) {
      try {
        file.deleteSync();
      } on FileSystemException {
        // Windows may still be releasing the preview handle; the OS temp
        // cleaner remains the final fallback in this exceptional case.
      }
    }
  }

  @override
  void dispose() {
    _deleteTemporaryClipboardImage();
    super.dispose();
  }

  void _toggle(int index, String option) {
    final question = widget.attempt.questions[index].question;
    setState(() {
      final selected = selections[index];
      if (question.type == QuestionType.single) {
        selected
          ..clear()
          ..add(option);
      } else if (!selected.remove(option)) {
        selected.add(option);
      }
      manuallyChanged.add(index);
    });
  }

  /// 问答题无法机读：作答文本由人工录入，原样保存（单元素集合）。
  void _setQaText(int index, String text) {
    setState(() {
      selections[index]
        ..clear()
        ..add(text);
      manuallyChanged.add(index);
    });
  }

  void _resetOverlay() => setState(() {
    _overlayOffset = Offset.zero;
    _overlayScale = 1;
    _overlayRotation = 0;
    overlayTransform = Matrix4.identity();
  });

  void _beginOverlayGesture(ScaleStartDetails details) {
    _gestureStartFocal = details.focalPoint;
    _gestureStartOffset = _overlayOffset;
    _gestureStartScale = _overlayScale;
    _gestureStartRotation = _overlayRotation;
  }

  void _updateOverlayGesture(ScaleUpdateDetails details) {
    setState(() {
      _overlayOffset =
          _gestureStartOffset + details.focalPoint - _gestureStartFocal;
      _overlayScale = (_gestureStartScale * details.scale).clamp(0.35, 4.0);
      _overlayRotation = _gestureStartRotation + details.rotation;
      overlayTransform = Matrix4.identity()
        ..translateByDouble(_overlayOffset.dx, _overlayOffset.dy, 0, 1)
        ..rotateZ(_overlayRotation)
        ..scaleByDouble(_overlayScale, _overlayScale, 1, 1);
    });
  }

  void _nudgeOverlay({
    double dx = 0,
    double dy = 0,
    double scale = 1,
    double rotation = 0,
  }) {
    setState(() {
      _overlayOffset += Offset(dx, dy);
      _overlayScale = (_overlayScale * scale).clamp(0.35, 4.0);
      _overlayRotation += rotation;
      overlayTransform = Matrix4.identity()
        ..translateByDouble(_overlayOffset.dx, _overlayOffset.dy, 0, 1)
        ..rotateZ(_overlayRotation)
        ..scaleByDouble(_overlayScale, _overlayScale, 1, 1);
    });
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.omrConfirmWriteTitle),
        content: Text(l10n.omrConfirmWriteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.omrKeepReviewing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.omrConfirmSubmit),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    setState(() => busy = true);
    try {
      final sources = <int, String>{};
      for (var index = 0; index < widget.attempt.questions.length; index++) {
        final state = widget.attempt.questions[index];
        if (state.question.type == QuestionType.qa) {
          // 问答题：作答文本原样写入快照，不产生作答事件，无需来源标记。
          state.selected
            ..clear()
            ..addAll(selections[index]);
          continue;
        }
        final valid = state.question.options.keys.toSet();
        state.selected
          ..clear()
          ..addAll(selections[index].where(valid.contains));
        sources[index] = manuallyChanged.contains(index)
            ? 'manual_correction'
            : 'paper_omr_scan';
      }
      widget.controller.savePaper(widget.attempt);
      await widget.controller.submitPaper(
        widget.attempt,
        sourceByPosition: sources,
      );
      // 确认后不立即退出：留在本页显示判卷情况，由用户主动返回试卷。
      if (mounted) setState(() => completed = true);
    } catch (exception) {
      if (mounted) {
        setState(
          () => error = l10n.omrSubmitFailed(localizedErrorText(l10n, exception)),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (completed) return _completedBuild(context);
    return _reviewBuild(context);
  }

  /// 确认写入后的判卷情况视图：留在本页，由用户主动返回试卷。
  Widget _completedBuild(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attempt = widget.attempt;
    final percentage = attempt.percentage;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.omrReviewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 46,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.omrGradingDone,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.omrGradingDoneBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Card(
            key: const ValueKey('windows-omr-grading-summary'),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.paperResultSummary(
                      l10n.paperScoreSummary(
                        '${attempt.score}',
                        '${attempt.maxScore}',
                      ) +
                      (percentage == null
                          ? ''
                          : l10n.paperScorePercentage(
                              percentage.toStringAsFixed(1),
                            )),
                      attempt.unansweredCount,
                      formatDuration(attempt.durationMs),
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < attempt.questions.length; index++)
            _GradedQuestionCard(
              index: index,
              state: attempt.questions[index],
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('windows-omr-back-to-paper'),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.assignment_return_outlined),
            label: Text(l10n.omrBackToPaper),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _reviewBuild(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyV, control: true):
          _pasteAndRecognize,
    },
    child: Focus(
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(title: Text(_l10n.omrReviewTitle)),
        body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(_l10n.omrReviewIntro),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              key: const ValueKey('windows-omr-pick-image'),
              onPressed: busy ? null : _pickAndRecognize,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(busy ? _l10n.omrRecognizing : _l10n.omrPickImage),
            ),
            OutlinedButton.icon(
              key: const ValueKey('windows-omr-paste-image'),
              onPressed: busy ? null : _pasteAndRecognize,
              icon: const Icon(Icons.content_paste_outlined),
              label: Text(_l10n.omrPasteClipboard),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (hasResult) ...[
          const SizedBox(height: 24),
          if (result != null && sourceImage != null) ...[
            _OmrOverlayToolbar(
              onReset: _resetOverlay,
              onMoveLeft: () => _nudgeOverlay(dx: -4),
              onMoveRight: () => _nudgeOverlay(dx: 4),
              onMoveUp: () => _nudgeOverlay(dy: -4),
              onMoveDown: () => _nudgeOverlay(dy: 4),
              onZoomIn: () => _nudgeOverlay(scale: 1.08),
              onZoomOut: () => _nudgeOverlay(scale: 0.92),
              onRotateLeft: () => _nudgeOverlay(rotation: -0.03),
              onRotateRight: () => _nudgeOverlay(rotation: 0.03),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final source = result!;
                final aspect = source.sourceWidth / source.sourceHeight;
                final width = constraints.maxWidth;
                final height = width / aspect;
                return Center(
                  child: SizedBox(
                    key: const ValueKey('windows-omr-viewport'),
                    width: width,
                    height: height,
                    child: ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            sourceImage!,
                            key: const ValueKey('windows-omr-source-image'),
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stack) => ColoredBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Text(_l10n.omrPreviewUnavailable),
                              ),
                            ),
                          ),
                          GestureDetector(
                            key: const ValueKey('windows-omr-overlay-gesture'),
                            behavior: HitTestBehavior.translucent,
                            onScaleStart: _beginOverlayGesture,
                            onScaleUpdate: _updateOverlayGesture,
                            child: Transform(
                              key: const ValueKey(
                                'windows-omr-overlay-transform',
                              ),
                              alignment: Alignment.center,
                              transform: overlayTransform,
                              child: CustomPaint(
                                key: const ValueKey(
                                  'windows-omr-bubble-overlay',
                                ),
                                painter: _OmrBubbleOverlayPainter(
                                  source,
                                  colorScheme: Theme.of(context).colorScheme,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(_l10n.omrOverlayHint),
            const SizedBox(height: 16),
          ],
          Text(_l10n.omrReviewEachQuestion,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(_l10n.omrReviewEditableHint),
          if (widget.attempt.questions.any(
            (state) => state.question.type == QuestionType.qa,
          )) ...[
            const SizedBox(height: 6),
            Text(
              _l10n.omrQaSheetNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          for (var index = 0; index < widget.attempt.questions.length; index++)
            _QuestionReviewCard(
              index: index,
              question: widget.attempt.questions[index].question,
              selected: selections[index],
              onToggle: (option) => _toggle(index, option),
              onQaText: (text) => _setQaText(index, text),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('windows-omr-confirm-submit'),
            onPressed: busy ? null : _confirm,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(_l10n.omrConfirmWrite),
          ),
        ],
          ],
        ),
      ),
    ),
  );
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.onToggle,
    this.onQaText,
  });

  final int index;
  final Question question;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// 问答题人工录入回调（问答题无气泡，不传 onToggle）。
  final ValueChanged<String>? onQaText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = switch (question.type) {
      QuestionType.single => l10n.omrQuestionTypeSingle,
      QuestionType.multiple => l10n.omrQuestionTypeMultiple,
      QuestionType.qa => l10n.omrQuestionTypeQa,
    };
    return Card(
      key: ValueKey('windows-omr-question-${index + 1}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.omrQuestionHeader(index + 1, typeLabel)),
            const SizedBox(height: 8),
            if (question.type == QuestionType.qa)
              _QaReviewField(
                key: ValueKey('windows-omr-qa-text-${index + 1}'),
                initialText: selected.firstOrNull,
                onChanged: onQaText!,
              )
            else
              Wrap(
                spacing: 8,
                children: [
                  for (final option in question.options.keys)
                    FilterChip(
                      label: Text(option),
                      selected: selected.contains(option),
                      onSelected: (_) => onToggle(option),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 问答题人工录入框：控制器只初始化一次，重建不丢光标。
class _QaReviewField extends StatefulWidget {
  const _QaReviewField({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  final String? initialText;
  final ValueChanged<String> onChanged;

  @override
  State<_QaReviewField> createState() => _QaReviewFieldState();
}

class _QaReviewFieldState extends State<_QaReviewField> {
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
      controller: _controller,
      minLines: 2,
      maxLines: 5,
      onChanged: widget.onChanged,
      decoration: InputDecoration(hintText: l10n.omrQaAnswerHint),
    );
  }
}

class _OmrOverlayToolbar extends StatelessWidget {
  const _OmrOverlayToolbar({
    required this.onReset,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRotateLeft,
    required this.onRotateRight,
  });

  final VoidCallback onReset;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(AppLocalizations.of(context)!.omrOverlayAlignLabel),
      IconButton(
        key: const ValueKey('windows-omr-overlay-move-left'),
        onPressed: onMoveLeft,
        icon: const Icon(Icons.arrow_left),
      ),
      IconButton(
        key: const ValueKey('windows-omr-overlay-move-right'),
        onPressed: onMoveRight,
        icon: const Icon(Icons.arrow_right),
      ),
      IconButton(
        key: const ValueKey('windows-omr-overlay-move-up'),
        onPressed: onMoveUp,
        icon: const Icon(Icons.arrow_drop_up),
      ),
      IconButton(
        key: const ValueKey('windows-omr-overlay-move-down'),
        onPressed: onMoveDown,
        icon: const Icon(Icons.arrow_drop_down),
      ),
      IconButton(
        key: const ValueKey('windows-omr-overlay-zoom-out'),
        onPressed: onZoomOut,
        icon: const Icon(Icons.remove),
      ),
      IconButton(
        key: const ValueKey('windows-omr-overlay-zoom-in'),
        onPressed: onZoomIn,
        icon: const Icon(Icons.add),
      ),
      IconButton(
        key: const ValueKey('windows-omr-overlay-rotate-left'),
        onPressed: onRotateLeft,
        icon: const Icon(Icons.rotate_left),
      ),
      IconButton(
        key: const ValueKey('windows-omr-overlay-rotate-right'),
        onPressed: onRotateRight,
        icon: const Icon(Icons.rotate_right),
      ),
      OutlinedButton(
        key: const ValueKey('windows-omr-overlay-reset'),
        onPressed: onReset,
        child: Text(AppLocalizations.of(context)!.omrOverlayReset),
      ),
    ],
  );
}

class _OmrBubbleOverlayPainter extends CustomPainter {
  _OmrBubbleOverlayPainter(this.result, {required this.colorScheme});

  final WindowsOmrResult result;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final pagePaint = Paint()
      ..color = colorScheme.tertiary.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _drawQuad(canvas, size, result.pageQuad, pagePaint);
    for (final question in result.questions) {
      for (final option in const ['A', 'B', 'C', 'D', 'E']) {
        final selected = question.selected.contains(option);
        final paint = Paint()
          ..color = selected
              ? colorScheme.error.withValues(alpha: 0.9)
              : colorScheme.primary.withValues(alpha: 0.48)
          ..style = selected ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = selected ? 3.5 : 2;
        _drawQuad(canvas, size, question.bubbleQuad[option]!, paint);
      }
    }
  }

  static void _drawQuad(
    Canvas canvas,
    Size size,
    List<List<double>> quad,
    Paint paint,
  ) {
    final path = Path();
    for (var index = 0; index < quad.length; index++) {
      final point = Offset(
        quad[index][0] * size.width,
        quad[index][1] * size.height,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OmrBubbleOverlayPainter oldDelegate) =>
      oldDelegate.result != result || oldDelegate.colorScheme != colorScheme;
}


/// 判卷结果视图中单题的核对卡片（只读）。
class _GradedQuestionCard extends StatelessWidget {
  const _GradedQuestionCard({required this.index, required this.state});

  final int index;
  final PaperQuestionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final question = state.question;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final success = dark ? const Color(0xff65d6a5) : ExamColors.success;
    final danger = dark ? const Color(0xffff8f88) : ExamColors.danger;
    final muted = dark ? ExamColors.darkMuted : ExamColors.muted;
    final typeLabel = switch (question.type) {
      QuestionType.single => l10n.omrQuestionTypeSingle,
      QuestionType.multiple => l10n.omrQuestionTypeMultiple,
      QuestionType.qa => l10n.omrQuestionTypeQa,
    };
    final correct = question.answers.toSet();
    final selected = state.selected;
    final verdict = switch (question.type) {
      QuestionType.qa => null,
      _ when selected.isEmpty => null,
      _ => selected.length == correct.length &&
          selected.every(correct.contains),
    };
    final verdictColor = verdict == null
        ? muted
        : verdict == true
        ? success
        : danger;
    final yourAnswer = switch (question.type) {
      QuestionType.qa => selected.firstOrNull ?? l10n.questionNotAnswered,
      _ when selected.isEmpty => l10n.questionNotAnswered,
      _ => (selected.toList()..sort()).join(l10n.questionAnswerSeparator),
    };
    return Card(
      key: ValueKey('windows-omr-graded-${index + 1}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.omrQuestionHeader(index + 1, typeLabel),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(
                  switch (verdict) {
                    null => Icons.remove_circle_outline,
                    true => Icons.check_circle,
                    false => Icons.cancel,
                  },
                  size: 20,
                  color: verdictColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.questionYourChoiceLabel}：$yourAnswer',
              style: TextStyle(color: muted),
            ),
            if (question.type == QuestionType.qa)
              Builder(
                builder: (context) {
                  final reference = question.answers.join('\n').trim();
                  return Text(
                    '${l10n.questionQaReferenceLabel}：'
                    '${reference.isEmpty ? l10n.questionQaReferenceEmpty : reference}',
                    style: TextStyle(color: muted),
                  );
                },
              )
            else
              Text(
                '${l10n.questionCorrectAnswerLabel}：'
                '${(question.answers.toList()..sort()).join(l10n.questionAnswerSeparator)}',
                style: TextStyle(color: muted),
              ),
          ],
        ),
      ),
    );
  }
}
