import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:personal_exam_app/main.dart';
import 'package:personal_exam_app/ui/app_shell.dart';

void main() {
  late Directory root;
  final controllers = <AppController>[];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('personal_exam_i18n_test');
  });

  tearDown(() async {
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<AppController> newController() async {
    final controller = await AppController.createForTesting(root);
    controllers.add(controller);
    return controller;
  }

  void useDesktopSurface(WidgetTester tester) {
    // AppShell 的 NavigationRail/首页仪表盘按桌面窗口尺寸设计。
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('跟随系统解析：测试宿主默认 en_US，解析到受支持的 en', (tester) async {
    useDesktopSurface(tester);
    final controller = await newController();
    await tester.pumpWidget(PersonalExamApp(controller: controller));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppShell).first);
    final l10n = AppLocalizations.of(context)!;
    expect(l10n.localeName, 'en');
    expect(l10n.shellNavPractice, 'Practice');
    expect(find.text('练习'), findsNothing);
  });

  testWidgets('localeTag=zh 时界面渲染中文文案', (tester) async {
    useDesktopSurface(tester);
    final controller = await newController();
    controller.setLocaleTag('zh');
    await tester.pumpWidget(PersonalExamApp(controller: controller));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppShell).first);
    final l10n = AppLocalizations.of(context)!;
    expect(l10n.localeName, 'zh');
    expect(l10n.shellNavPractice, '开始练习');
    expect(find.text('开始练习'), findsWidgets);
    expect(find.text('Practice'), findsNothing);
  });

  testWidgets('localeTag=en 覆盖系统语言，界面渲染英文文案', (tester) async {
    useDesktopSurface(tester);
    final controller = await newController();
    controller.setLocaleTag('en');
    await tester.pumpWidget(PersonalExamApp(controller: controller));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AppShell).first);
    final l10n = AppLocalizations.of(context)!;
    expect(l10n.localeName, 'en');
    expect(find.text('Practice'), findsWidgets);
  });

  test('语言偏好写入 app_settings，重建控制器后保持（重启持久化）', () async {
    var controller = await newController();
    expect(controller.localeTag, 'system');
    controller.setLocaleTag('en');
    expect(controller.localeTag, 'en');
    // 非法值被拒绝并保持不变。
    controller.setLocaleTag('fr');
    expect(controller.localeTag, 'en');

    // 模拟重启：同一数据目录重新初始化控制器。
    controller = await newController();
    expect(controller.localeTag, 'en');
  });

  test('语言偏好仅本地保存，不进入同步 outbox', () async {
    final controller = await newController();
    final pendingBefore = controller.stats.pendingSync;
    controller.setLocaleTag('zh');
    expect(controller.stats.pendingSync, pendingBefore);
  });
}
