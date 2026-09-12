import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/ui/pages.dart';

void main() {
  testWidgets('首页待同步框可查看、选择并移出同步队列', (tester) async {
    final root = Directory.systemTemp.createTempSync('personal-exam-pending-');
    final controller = await AppController.createForTesting(root);
    addTearDown(() {
      controller.dispose();
      root.deleteSync(recursive: true);
    });
    final mode = controller.automaticPracticeMode;
    final question = controller.practiceQueue(mode).first;
    controller.submitPractice(
      question: question,
      selected: question.answers,
      durationMs: 1000,
      mode: mode,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomePage(controller: controller, onNavigate: (_) {}),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('home-pending-sync-pill')));
    await tester.pumpAndSettle();
    expect(find.text('待同步项目'), findsOneWidget);
    expect(find.textContaining('作答记录'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    await tester.tap(find.textContaining('删除所选'));
    await tester.pumpAndSettle();
    expect(find.text('确认移出同步队列'), findsOneWidget);
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(find.text('当前没有待同步项目'), findsOneWidget);
    expect(controller.database.answerHistory(question.id), hasLength(1));
  });
}
