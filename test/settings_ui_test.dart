import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/ui/pages.dart';

void main() {
  testWidgets('设置页显示注入的版本号，不再展示开发约定文案', (tester) async {
    final root = Directory.systemTemp.createTempSync('personal-exam-settings-');
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
home: SettingsPage(controller: controller)),
    );
    await tester.pump();

    // 判分规则区块加入后"版本"卡片位于列表底部，需滚动到可见（ListView 懒加载）。
    await tester.dragUntilVisible(
      find.text('版本'),
      find.byType(ListView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(find.text('版本'), findsOneWidget);
    // 测试环境未注入 APP_VERSION，应显示"开发版"而不是写死的旧版本号。
    expect(find.textContaining('开发版'), findsOneWidget);
    expect(find.textContaining('0.7.0'), findsNothing);
    expect(find.textContaining('设备 ID：'), findsOneWidget);
    expect(find.text('数据原则'), findsNothing);
    expect(find.textContaining('不内置 AI'), findsNothing);
    expect(find.textContaining('SQLite 完整性'), findsNothing);
  });
}
