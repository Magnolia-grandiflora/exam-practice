import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/domain/models.dart';

void main() {
  testWidgets('试卷在后台连接中提交并回写结果', (tester) async {
    final root = Directory.systemTemp.createTempSync('paper-submit-');
    final controller = await AppController.createForTesting(
      root,
      submitPaperInBackground: true,
    );
    try {
      final paper = controller.createPaper(
        requestedCount: 3,
        suggestedMinutes: 30,
        random: false,
      );
      paper.questions.first.selected.add('A');

      await tester.runAsync(
        () =>
            controller.submitPaper(paper).timeout(const Duration(seconds: 10)),
      );

      expect(paper.status, AttemptStatus.submitted);
      expect(paper.submittedAtUtc, isNotNull);
      expect(paper.score, isNotNull);
      expect(controller.database.latestDraft(paper.bankId), isNull);
    } finally {
      controller.dispose();
      if (root.existsSync()) root.deleteSync(recursive: true);
    }
  });
}
