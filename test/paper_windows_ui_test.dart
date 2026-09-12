import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/domain/paper_policy.dart';
import 'package:personal_exam_app/ui/app_theme.dart';
import 'package:personal_exam_app/ui/pages.dart';
import 'package:personal_exam_app/ui/paper_page.dart';

void main() {
  testWidgets('Windows 试卷创建页提供三种组卷模式', (tester) async {
    final root = Directory.systemTemp.createTempSync('paper-windows-mode-');
    final controller = await AppController.createForTesting(root);
    addTearDown(() async {
      controller.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ExamTheme.light().copyWith(platform: TargetPlatform.windows),
        home: PaperLauncherPage(controller: controller),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('paper-composition-mode')),
      findsOneWidget,
    );
    expect(find.text('仅单选'), findsOneWidget);
    expect(find.text('仅多选'), findsOneWidget);
    expect(find.text('真实考试 14:3'), findsOneWidget);
    final mode = tester.widget<SegmentedButton<PaperCompositionMode>>(
      find.byKey(const ValueKey('paper-composition-mode')),
    );
    expect(mode.selected, {PaperCompositionMode.realExam});
  });

  testWidgets('桌面试卷强调当前题和已答状态', (tester) async {
    final root = Directory.systemTemp.createTempSync('paper-windows-ui-');
    final controller = await AppController.createForTesting(root);
    addTearDown(() async {
      controller.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final paper = controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ExamTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 800)),
          child: PaperPage(controller: controller, attempt: paper),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('本题未答'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();

    expect(find.text('本题已答'), findsOneWidget);
    final answeredNumber = find.byKey(const ValueKey('paper-number-1'));
    expect(answeredNumber, findsOneWidget);
    expect(
      find.descendant(
        of: answeredNumber,
        matching: find.byIcon(Icons.check_circle),
      ),
      findsNothing,
    );
    final numberMaterial = tester.widget<Material>(
      find
          .descendant(of: answeredNumber, matching: find.byType(Material))
          .first,
    );
    expect(numberMaterial.color, Colors.green.withValues(alpha: 0.18));
  });

  testWidgets('桌面题号导航直接精准定位题目且没有滚动动画', (tester) async {
    final root = Directory.systemTemp.createTempSync('paper-windows-jump-');
    final controller = await AppController.createForTesting(root);
    addTearDown(() async {
      controller.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final paper = controller.createPaper(
      requestedCount: 15,
      suggestedMinutes: 30,
      random: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ExamTheme.light().copyWith(platform: TargetPlatform.windows),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 800)),
          child: PaperPage(controller: controller, attempt: paper),
        ),
      ),
    );
    await tester.pump();

    for (final number in [8, 3, 11]) {
      await tester.tap(find.byKey(ValueKey('paper-number-$number')));
      await tester.pump();
      final scrollTop = tester
          .getTopLeft(find.byKey(const ValueKey('paper-question-scroll')))
          .dy;
      final questionTop = tester
          .getTopLeft(find.byKey(ValueKey('paper-question-$number')))
          .dy;
      expect((questionTop - scrollTop).abs(), lessThan(1));
      expect(paper.currentIndex, number - 1);
    }
  });

  testWidgets('桌面交卷使用页内确认且提交后显示结果', (tester) async {
    final root = Directory.systemTemp.createTempSync('paper-windows-submit-');
    final controller = await AppController.createForTesting(root);
    addTearDown(() async {
      controller.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final paper = controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ExamTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 800)),
          child: PaperPage(controller: controller, attempt: paper),
        ),
      ),
    );
    await tester.pump();
    final baselineBarrierCount = find.byType(ModalBarrier).evaluate().length;

    await tester.tap(find.widgetWithText(FilledButton, '交卷'));
    await tester.pump();
    expect(find.textContaining('确认交卷？'), findsOneWidget);
    expect(find.byType(ModalBarrier).evaluate().length, baselineBarrierCount);

    await tester.tap(find.widgetWithText(FilledButton, '确认交卷'));
    await tester.pumpAndSettle();

    expect(find.textContaining('得分'), findsOneWidget);
    expect(find.textContaining('百分制'), findsOneWidget);
    expect(find.byType(ModalBarrier).evaluate().length, baselineBarrierCount);
  });

  testWidgets('交卷后题号导航按答对答错着色', (tester) async {
    final root = Directory.systemTemp.createTempSync('paper-windows-verdict-');
    final controller = await AppController.createForTesting(root);
    addTearDown(() async {
      controller.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final paper = controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    paper.questions[0].selected.addAll(paper.questions[0].question.answers);
    final wrongOption = paper.questions[1].question.options.keys.firstWhere(
      (option) => !paper.questions[1].question.answers.contains(option),
    );
    paper.questions[1].selected.add(wrongOption);
    paper.durationMs = 5000;
    await controller.submitPaper(paper);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ExamTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 800)),
          child: PaperPage(controller: controller, attempt: paper),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('答对'), findsOneWidget);
    expect(find.text('答错'), findsOneWidget);
    final rightChip = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('paper-number-1')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(rightChip.color, ExamColors.success.withValues(alpha: 0.18));
    final wrongChip = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('paper-number-2')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(wrongChip.color, ExamColors.danger.withValues(alpha: 0.18));
    final untouchedChip = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('paper-number-3')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(untouchedChip.color, isNot(Colors.green.withValues(alpha: 0.18)));
  });

  testWidgets('试卷创建页说明随机抽题范围', (tester) async {
    final root = Directory.systemTemp.createTempSync('paper-windows-pool-');
    final controller = await AppController.createForTesting(root);
    addTearDown(() async {
      controller.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ExamTheme.light().copyWith(platform: TargetPlatform.windows),
        home: PaperLauncherPage(controller: controller),
      ),
    );
    await tester.pump();

    // 内置测试包共 15 题，默认题量 20 → 提示按实际池 15 题随机抽取。
    expect(find.text('随机抽题'), findsOneWidget);
    expect(find.text('随机题目顺序'), findsNothing);
    expect(find.textContaining('当前范围共 15 题'), findsOneWidget);
    expect(find.textContaining('将从中随机抽取 15 题'), findsOneWidget);
    expect(find.textContaining('将按题库顺序取前'), findsNothing);
  });
}
