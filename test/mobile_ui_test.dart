import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/ui/app_shell.dart';
import 'package:personal_exam_app/ui/app_theme.dart';
import 'package:personal_exam_app/ui/paper_page.dart';
import 'package:personal_exam_app/ui/pages.dart';

void main() {
  testWidgets('安卓历史入口可打开同步的已交卷试卷', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    final source = await _Fixture.create();
    final target = await _Fixture.create();
    addTearDown(source.dispose);
    addTearDown(target.dispose);
    final paper = source.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    paper.questions.first.selected.add('A');
    source.controller.database.submitPaper(paper);
    final item = source.controller.database
        .pendingOutbox(includeDeferred: true)
        .firstWhere((row) => row['entity_type'] == 'paper_attempt');
    target.controller.database.applySyncExchange(
      acceptedOutboxIds: const {},
      changes: [
        {
          'entity_type': 'paper_attempt',
          'entity_id': paper.attemptId,
          'payload': jsonDecode(item['payload_json'] as String),
          'payload_hash': item['payload_hash'],
        },
      ],
      nextCursor: '1',
    );
    await target.controller.refresh();
    await tester.pumpWidget(
      _testApp(
        size: const Size(390, 844),
        child: AppShell(controller: target.controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('历史').last);
    await tester.pumpAndSettle();
    expect(find.text(paper.title), findsOneWidget);
    await tester.tap(find.text(paper.title));
    await tester.pumpAndSettle();
    expect(find.byType(PaperPage), findsOneWidget);
    expect(find.textContaining('得分'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏使用底部导航并保留五个核心入口', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      _testApp(
        size: const Size(390, 844),
        child: AppShell(controller: fixture.controller),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final label in ['首页', '练习', '试卷', '历史', '更多']) {
      expect(find.text(label), findsAtLeastNWidgets(1));
    }

    final totalRect = tester.getRect(
      find.byKey(const ValueKey('stat-tile-总题数')),
    );
    final unseenRect = tester.getRect(
      find.byKey(const ValueKey('stat-tile-未见')),
    );
    expect(totalRect.width, greaterThan(150));
    expect(totalRect.width, lessThan(180));
    expect(unseenRect.width, closeTo(totalRect.width, 0.1));
    expect(unseenRect.top, closeTo(totalRect.top, 0.1));

    await tester.tap(find.text('练习').last);
    await tester.pumpAndSettle();
    final unseenModeRect = tester.getRect(
      find.byKey(const ValueKey('practice-mode-card-未见题优先')),
    );
    final wrongModeRect = tester.getRect(
      find.byKey(const ValueKey('practice-mode-card-错题复习')),
    );
    expect(unseenModeRect.width, greaterThan(150));
    expect(unseenModeRect.width, lessThan(180));
    expect(wrongModeRect.width, closeTo(unseenModeRect.width, 0.1));
    expect(wrongModeRect.top, closeTo(unseenModeRect.top, 0.1));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('practice-mode-card-随机练习')),
      250,
    );
    await tester.pump();
    final randomModeWidth = tester
        .getSize(find.byKey(const ValueKey('practice-mode-card-随机练习')))
        .width;
    expect(randomModeWidth, greaterThan(150));
    expect(randomModeWidth, lessThan(180));
  });

  testWidgets('Android 试卷创建页不显示 Windows OMR 组卷控件', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      _testApp(
        size: const Size(390, 844),
        child: PaperLauncherPage(controller: fixture.controller),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('paper-composition-mode')), findsNothing);
    expect(find.text('仅单选'), findsNothing);
    expect(find.text('仅多选'), findsNothing);
  });

  testWidgets('移动试卷分页作答在横竖屏切换后不丢选择', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );

    final page = PaperPage(
      key: ValueKey(paper.attemptId),
      controller: fixture.controller,
      attempt: paper,
    );
    await tester.pumpWidget(_testApp(size: const Size(390, 844), child: page));
    await tester.pump();

    expect(find.text('第 1 / 3 题'), findsOneWidget);
    expect(find.text('本题未答'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    expect(paper.questions.first.selected, isNotEmpty);
    expect(find.text('本题已答'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '下一题'));
    await tester.pumpAndSettle();
    expect(paper.currentIndex, 1);
    expect(find.text('第 2 / 3 题'), findsOneWidget);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpWidget(_testApp(size: const Size(844, 390), child: page));
    await tester.pump();
    expect(find.text('第 2 / 3 题'), findsOneWidget);
    expect(paper.questions.first.selected, isNotEmpty);
  });

  testWidgets('移动试卷交卷前可选择导出空白试卷和纸质答题卡', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );

    await tester.pumpWidget(
      _testApp(
        size: const Size(390, 844),
        child: PaperPage(controller: fixture.controller, attempt: paper),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('导出空白试卷、答题卡或 PDF'));
    await tester.pumpAndSettle();
    expect(find.text('导出试卷'), findsOneWidget);
    expect(find.text('导出内容'), findsOneWidget);
    expect(find.text('输出方式'), findsOneWidget);
    expect(find.text('空白试卷'), findsOneWidget);
    expect(find.text('纸质答题卡'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, '答案与解析'),
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, '作答回顾'),
          )
          .onChanged,
      isNull,
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('移动试卷交卷后显示结果而非停留在遮罩层', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );

    await tester.pumpWidget(
      _testApp(
        size: const Size(390, 844),
        child: PaperPage(controller: fixture.controller, attempt: paper),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '交卷'));
    await tester.pumpAndSettle();
    expect(find.text('确认交卷？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '确认交卷'));
    for (
      var i = 0;
      i < 10 &&
          paper.status != AttemptStatus.submitted &&
          find.text('正在交卷…').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (paper.status != AttemptStatus.submitted) {
        if (DateTime.now().isAfter(deadline)) {
          throw StateError('后台交卷在 10 秒内未完成');
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();

    expect(paper.status, AttemptStatus.submitted);
    expect(find.text('确认交卷？'), findsNothing);
    expect(find.textContaining('得分'), findsOneWidget);
  });
}

void _setViewSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _testApp({required Size size, required Widget child}) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ExamTheme.light().copyWith(platform: TargetPlatform.android),
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: child,
  ),
);

class _Fixture {
  _Fixture(this.root, this.controller);

  final Directory root;
  final AppController controller;

  static Future<_Fixture> create() async {
    final root = Directory.systemTemp.createTempSync('personal-exam-mobile-');
    final controller = await AppController.createForTesting(root);
    return _Fixture(root, controller);
  }

  Future<void> dispose() async {
    controller.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}
