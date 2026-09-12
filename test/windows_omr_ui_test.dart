import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/services/windows_omr_scanner.dart';
import 'package:personal_exam_app/ui/app_theme.dart';
import 'package:personal_exam_app/ui/windows_omr_review_page.dart';

void main() {
  testWidgets('连续识别成功或失败均清理模板且不产生导出文件夹', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    final templates = <File>[];
    await tester.pumpWidget(
      _app(
        WindowsOmrReviewPage(
          controller: fixture.controller,
          attempt: paper,
          pickImage: () async => fixture.image,
          recognize: (_, template, expected) async {
            templates.add(template);
            expect(template.existsSync(), isTrue);
            expect(_exportEntries(fixture.controller), isEmpty);
            if (templates.length == 2) throw StateError('识别失败测试');
            return _result(expected);
          },
        ),
      ),
    );
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(const ValueKey('windows-omr-pick-image')));
      await tester.pumpAndSettle();
      expect(templates.length, index + 1);
      expect(templates.last.parent.existsSync(), isFalse);
      expect(_exportEntries(fixture.controller), isEmpty);
      expect(fixture.image.existsSync(), isTrue);
    }
  });

  testWidgets('取消或识别失败不会提交试卷', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    final historyBefore = fixture.controller.recentHistory.length;
    final outboxBefore = fixture.controller.pendingSyncItems().length;

    await tester.pumpWidget(
      _app(
        WindowsOmrReviewPage(
          controller: fixture.controller,
          attempt: paper,
          pickImage: () async => fixture.image,
          recognize: (_, _, expected) async => _result(expected),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('windows-omr-pick-image')));
    await tester.pumpAndSettle();
    expect(_exportEntries(fixture.controller), isEmpty);
    expect(paper.questions.every((state) => state.selected.isEmpty), isTrue);
    expect(fixture.controller.recentHistory.length, historyBefore);
    expect(fixture.controller.pendingSyncItems().length, outboxBefore);
    expect(find.byKey(const ValueKey('windows-omr-viewport')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('windows-omr-source-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('windows-omr-bubble-overlay')),
      findsOneWidget,
    );
    final transformBefore = tester
        .widget<Transform>(
          find.byKey(const ValueKey('windows-omr-overlay-transform')),
        )
        .transform;
    await tester.tap(find.byKey(const ValueKey('windows-omr-overlay-zoom-in')));
    await tester.pump();
    final transformAfterZoom = tester
        .widget<Transform>(
          find.byKey(const ValueKey('windows-omr-overlay-transform')),
        )
        .transform;
    expect(transformAfterZoom, isNot(transformBefore));
    await tester.tap(
      find.byKey(const ValueKey('windows-omr-overlay-move-right')),
    );
    await tester.pump();
    final transformAfterPan = tester
        .widget<Transform>(
          find.byKey(const ValueKey('windows-omr-overlay-transform')),
        )
        .transform;
    expect(transformAfterPan, isNot(transformAfterZoom));
    await tester.tap(
      find.byKey(const ValueKey('windows-omr-overlay-rotate-right')),
    );
    await tester.pump();
    final transformAfterRotate = tester
        .widget<Transform>(
          find.byKey(const ValueKey('windows-omr-overlay-transform')),
        )
        .transform;
    expect(transformAfterRotate, isNot(transformAfterPan));
    await tester.tap(find.byKey(const ValueKey('windows-omr-overlay-reset')));
    await tester.pump();
    final resetTransform = tester
        .widget<Transform>(
          find.byKey(const ValueKey('windows-omr-overlay-transform')),
        )
        .transform;
    expect(
      resetTransform.storage,
      orderedEquals(const [
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
      ]),
    );

    final confirmButton = find.byKey(
      const ValueKey('windows-omr-confirm-submit'),
    );
    await tester.scrollUntilVisible(confirmButton, 500);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '继续审核'));
    await tester.pumpAndSettle();
    expect(paper.status.name, 'draft');
    expect(paper.questions.every((state) => state.selected.isEmpty), isTrue);
    expect(fixture.controller.recentHistory.length, historyBefore);
    expect(fixture.controller.pendingSyncItems().length, outboxBefore);

    await tester.pumpWidget(
      _app(
        WindowsOmrReviewPage(
          key: const ValueKey('windows-omr-failure-page'),
          controller: fixture.controller,
          attempt: paper,
          pickImage: () async => fixture.image,
          recognize: (ignoredImage, ignoredTemplate, ignoredCount) =>
              Future<WindowsOmrResult>.error('bridge failed'),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('windows-omr-pick-image')));
    await tester.pumpAndSettle();
    expect(find.textContaining('识别失败'), findsOneWidget);
    expect(paper.status.name, 'draft');
    expect(paper.questions.every((state) => state.selected.isEmpty), isTrue);
    expect(fixture.controller.recentHistory.length, historyBefore);
    expect(fixture.controller.pendingSyncItems().length, outboxBefore);
    expect(_exportEntries(fixture.controller), isEmpty);
  });

  testWidgets('Ctrl+V 从剪贴板导入图片并开始识别', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    var pasteCount = 0;

    await tester.pumpWidget(
      _app(
        WindowsOmrReviewPage(
          controller: fixture.controller,
          attempt: paper,
          pasteImage: () async {
            pasteCount++;
            return fixture.image;
          },
          recognize: (_, _, expected) async => _result(expected),
        ),
      ),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(pasteCount, 1);
    expect(find.byKey(const ValueKey('windows-omr-viewport')), findsOneWidget);
    expect(_exportEntries(fixture.controller), isEmpty);
  });

  testWidgets('人工确认后通过既有事务提交试卷', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    final historyBefore = fixture.controller.recentHistory.length;
    final outboxBefore = fixture.controller.pendingSyncItems().length;

    await tester.pumpWidget(
      _app(
        WindowsOmrReviewPage(
          controller: fixture.controller,
          attempt: paper,
          pickImage: () async => fixture.image,
          recognize: (_, _, expected) async => _result(expected),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('windows-omr-pick-image')));
    await tester.pumpAndSettle();
    final firstQuestion = find.byKey(const ValueKey('windows-omr-question-1'));
    await tester.scrollUntilVisible(firstQuestion, 500);
    await tester.tap(
      find.descendant(
        of: firstQuestion,
        matching: find.widgetWithText(FilterChip, 'B'),
      ),
    );
    await tester.pump();
    expect(fixture.controller.recentHistory.length, historyBefore);
    expect(fixture.controller.pendingSyncItems().length, outboxBefore);
    expect(paper.questions.every((state) => state.selected.isEmpty), isTrue);
    final confirmButton = find.byKey(
      const ValueKey('windows-omr-confirm-submit'),
    );
    await tester.scrollUntilVisible(confirmButton, 500);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认交卷'));
    await tester.pumpAndSettle();

    expect(paper.status.name, 'submitted');
    expect(paper.percentage, isNotNull);
    expect(fixture.controller.recentHistory.length, historyBefore);
    expect(
      fixture.controller.recentHistory
          .singleWhere((summary) => summary.attemptId == paper.attemptId)
          .status
          .name,
      'submitted',
    );
    expect(
      fixture.controller.pendingSyncItems().length,
      greaterThan(outboxBefore),
    );
    expect(
      fixture.controller.database
          .answerHistory(paper.questions[0].question.id)
          .single['source'],
      'manual_correction',
    );
    for (var index = 1; index < paper.questions.length; index++) {
      expect(
        fixture.controller.database
            .answerHistory(paper.questions[index].question.id)
            .single['source'],
        'paper_omr_scan',
      );
    }
  });
}

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ExamTheme.light().copyWith(platform: TargetPlatform.windows),
  home: child,
);

List<FileSystemEntity> _exportEntries(AppController controller) {
  final directory = controller.paths.exports;
  return directory.existsSync() ? directory.listSync() : const [];
}

Map<String, List<List<double>>> _bubbleQuad() => {
  for (final option in const ['A', 'B', 'C', 'D', 'E'])
    option: const [
      [0.1, 0.1],
      [0.12, 0.1],
      [0.12, 0.12],
      [0.1, 0.12],
    ],
};

WindowsOmrResult _result(int expected) => WindowsOmrResult(
  sourceWidth: 1000,
  sourceHeight: 1400,
  pageQuad: const [
    [0.02, 0.02],
    [0.98, 0.02],
    [0.98, 0.98],
    [0.02, 0.98],
  ],
  questions: List.generate(
    expected,
    (index) => WindowsOmrQuestion(
      number: index + 1,
      selected: const {'A'},
      confidence: 0.9,
      bubbleQuad: _bubbleQuad(),
    ),
  ),
);

class _Fixture {
  _Fixture(this.root, this.controller, this.image);

  final Directory root;
  final AppController controller;
  final File image;

  static Future<_Fixture> create() async {
    final root = Directory.systemTemp.createTempSync('windows-omr-ui-');
    final image = File('${root.path}${Platform.pathSeparator}sheet.jpg')
      ..writeAsBytesSync([1]);
    final controller = await AppController.createForTesting(root);
    return _Fixture(root, controller, image);
  }

  Future<void> dispose() async {
    controller.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}
