import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/ui/app_theme.dart';
import 'package:personal_exam_app/ui/practice_page.dart';

void main() {
  testWidgets('移动练习页清楚展示作答提示和两列题目标记操作', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final questions = fixture.controller.practiceQueue(
      PracticeMode.unseen,
      limit: 3,
    );

    await tester.pumpWidget(
      _testApp(
        child: PracticeSessionPage(
          controller: fixture.controller,
          mode: PracticeMode.unseen,
          questions: questions,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('practice-session-progress')), findsOne);
    expect(find.byKey(const ValueKey('answer-instruction')), findsNothing);
    expect(find.text('请选择 1 个答案'), findsNothing);
    expect(find.text('可选择多个答案，选好后提交'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '提交并查看答案'));
    await tester.pump();
    expect(find.text('尚未选择答案，请先作答'), findsOne);

    final favorite = tester.getRect(
      find.byKey(const ValueKey('practice-favorite-action')),
    );
    final uncertain = tester.getRect(
      find.byKey(const ValueKey('practice-uncertain-action')),
    );
    final note = tester.getRect(
      find.byKey(const ValueKey('practice-note-action')),
    );
    final exclude = tester.getRect(
      find.byKey(const ValueKey('practice-exclude-action')),
    );
    expect(favorite.top, closeTo(uncertain.top, 0.1));
    expect(favorite.width, closeTo(uncertain.width, 0.1));
    expect(note.top, closeTo(exclude.top, 0.1));
    expect(note.top, greaterThan(favorite.bottom));

    await tester.tap(find.byKey(const ValueKey('practice-uncertain-action')));
    await tester.pump();
    expect(find.text('已标疑问'), findsOne);
    expect(
      fixture.controller.database.progress(questions.first.id).isUncertain,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('practice-exclude-action')));
    await tester.pumpAndSettle();
    expect(find.text('排除此题？'), findsOne);
    expect(find.widgetWithText(FilledButton, '确认排除'), findsOne);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('练习提交后用完整反馈面板显示结果、答案和解析', (tester) async {
    _setViewSize(tester, const Size(390, 844));
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final questions = fixture.controller.practiceQueue(
      PracticeMode.unseen,
      limit: 3,
    );

    await tester.pumpWidget(
      _testApp(
        child: PracticeSessionPage(
          controller: fixture.controller,
          mode: PracticeMode.unseen,
          questions: questions,
        ),
      ),
    );
    await tester.pump();

    final firstOption = find.byType(CheckboxListTile).first;
    await tester.ensureVisible(firstOption);
    await tester.tap(firstOption);
    await tester.pump();
    expect(find.byKey(const ValueKey('answer-instruction')), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '提交并查看答案'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('answer-result-panel')), findsOne);
    expect(find.text('答案解析'), findsOne);
    expect(find.text('本题已提交'), findsOne);
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

Widget _testApp({required Widget child}) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ExamTheme.light(),
  home: MediaQuery(
    data: const MediaQueryData(size: Size(390, 844)),
    child: child,
  ),
);

class _Fixture {
  _Fixture(this.root, this.controller);

  final Directory root;
  final AppController controller;

  static Future<_Fixture> create() async {
    final root = Directory.systemTemp.createTempSync('practice-page-ui-');
    final controller = await AppController.createForTesting(root);
    return _Fixture(root, controller);
  }

  Future<void> dispose() async {
    controller.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}
