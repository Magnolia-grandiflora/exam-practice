import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:personal_exam_app/services/windows_omr_scanner.dart';
import 'package:personal_exam_app/ui/app_theme.dart';
import 'package:personal_exam_app/ui/paper_page.dart';
import 'package:personal_exam_app/ui/windows_omr_review_page.dart';

Map<String, List<List<double>>> _bubbleQuad() => {
  for (final option in const ['A', 'B', 'C', 'D', 'E'])
    option: const [
      [0.1, 0.1],
      [0.12, 0.1],
      [0.12, 0.12],
      [0.1, 0.12],
    ],
};

void main() {
  testWidgets('OMR 导入确认后：回到试卷页并显示判卷结果（后台交卷路径）', (tester) async {
    final root = Directory.systemTemp.createTempSync('exam-omr-return-');
    final image = File('${root.path}${Platform.pathSeparator}sheet.jpg')
      ..writeAsBytesSync([1]);
    // 生产 Windows 使用后台 isolate 交卷，这里用相同设置复现。
    final controller = await AppController.createForTesting(
      root,
      submitPaperInBackground: true,
    );
    addTearDown(() async {
      controller.dispose();
      // 后台 isolate 的数据库连接可能稍晚释放，重试删除。
      for (var i = 0; i < 20; i++) {
        try {
          if (!root.existsSync()) return;
          root.deleteSync(recursive: true);
          return;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    });

    final attempt = controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    await controller.refresh();
    expect(controller.draft?.attemptId, attempt.attemptId);

    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ExamTheme.light().copyWith(platform: TargetPlatform.windows),
        home: PaperPage(
          controller: controller,
          attempt: attempt,
          pickImage: () async => image,
          recognize: (_, _, expected) async => WindowsOmrResult(
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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaperPage), findsOneWidget);

    // 走真实的"读取答题卡"入口（试卷页把 recognize 注入复核页）。
    await tester.tap(find.byKey(const ValueKey('windows-omr-review-action')));
    await tester.pumpAndSettle();
    expect(find.byType(WindowsOmrReviewPage), findsOneWidget);

    // 识别 → 确认交卷。
    await tester.tap(find.byKey(const ValueKey('windows-omr-pick-image')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('windows-omr-confirm-submit')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('windows-omr-confirm-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认交卷'));

    // 等待后台 isolate 交卷完成（真实异步 I/O 需 runAsync）。
    await tester.runAsync(() async {
      for (var i = 0; i < 100; i++) {
        if (attempt.status == AttemptStatus.submitted) return;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pumpAndSettle();

    // 确认后不跳走：复核页原地转为判卷情况视图。
    expect(find.byType(WindowsOmrReviewPage), findsOneWidget);
    expect(attempt.status, AttemptStatus.submitted);
    expect(
      find.byKey(const ValueKey('windows-omr-grading-summary')),
      findsOneWidget,
    );
    expect(find.textContaining('得分'), findsWidgets);
    expect(
      find.byKey(const ValueKey('windows-omr-graded-1')),
      findsOneWidget,
    );

    // 用户主动返回后，试卷页继续显示判卷情况。
    await tester.tap(find.byKey(const ValueKey('windows-omr-back-to-paper')));
    await tester.pumpAndSettle();
    expect(find.byType(WindowsOmrReviewPage), findsNothing);
    expect(find.byType(PaperPage), findsOneWidget);
    expect(find.textContaining('得分'), findsWidgets);
    // 顶部不再有"读取答题卡"入口（已交卷）。
    expect(find.textContaining('答题卡'), findsNothing);
  });
}
