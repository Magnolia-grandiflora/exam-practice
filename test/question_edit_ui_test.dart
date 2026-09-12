import 'dart:io';

import 'package:flutter/material.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/ui/app_theme.dart';
import 'package:personal_exam_app/ui/pages.dart';
import 'package:personal_exam_app/ui/paper_page.dart';
import 'package:personal_exam_app/ui/question_widgets.dart';

void main() {
  testWidgets('Windows 题库搜索后可编辑，保存保留未编辑字段', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final original = fixture.controller.database
        .managedQuestions(fixture.controller.currentBank!.id)
        .first;
    for (var index = 0; index < 86; index++) {
      fixture.controller.database.addQuestion(
        Question(
          id: 'question-edit-page-$index',
          bankId: original.bankId,
          externalId: 'PAGE-${index.toString().padLeft(3, '0')}',
          contentVersion: 1,
          type: QuestionType.single,
          stem: '分页恢复测试题 $index',
          options: const {'A': '正确', 'B': '错误'},
          answers: const ['A'],
          explanation: '',
          knowledgePoint: '',
          source: '',
          year: '测试',
          chapter: '分页',
          tags: const ['分页'],
          media: const [],
          scoringRule: original.scoringRule,
          isActive: true,
        ),
      );
    }

    await tester.pumpWidget(
      _app(
        platform: TargetPlatform.windows,
        child: BankPage(controller: fixture.controller),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('bank-question-search')),
      original.stem,
    );
    await tester.pump();
    expect(find.textContaining(original.externalId!), findsOneWidget);
    expect(find.text('A. ${original.options['A']}'), findsOneWidget);

    await tester.tap(find.byTooltip('编辑'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('编辑'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('question-edit-stem')),
      '编辑后的题干',
    );
    await tester.enterText(
      find.byKey(const ValueKey('question-edit-option-A')),
      '编辑后的 A 选项',
    );
    await tester.enterText(
      find.byKey(const ValueKey('question-edit-explanation')),
      '编辑后的解析',
    );
    await tester.enterText(
      find.byKey(const ValueKey('question-edit-knowledge-point')),
      '编辑后的考点',
    );
    await tester.tap(find.byKey(const ValueKey('question-edit-save')));
    await tester.pumpAndSettle();

    final saved = fixture.controller.database.questionById(original.id)!;
    expect(saved.stem, '编辑后的题干');
    expect(saved.options['A'], '编辑后的 A 选项');
    expect(saved.explanation, '编辑后的解析');
    expect(saved.knowledgePoint, '编辑后的考点');
    expect(saved.bankId, original.bankId);
    expect(saved.id, original.id);
    expect(saved.media, original.media);
    expect(saved.scoringRule.toJson(), original.scoringRule.toJson());
    expect(saved.isActive, original.isActive);

    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pumpAndSettle();
    final searchField = tester.widget<TextField>(
      find.byKey(const ValueKey('bank-question-search')),
    );
    expect(searchField.controller!.text, isEmpty);
    final questionList = tester.widget<ListView>(find.byType(ListView));
    expect(questionList.childrenDelegate.estimatedChildCount, 101);
  });

  testWidgets('题目文字可选择且保留选项点击作答', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final question = fixture.controller.database
        .managedQuestions(fixture.controller.currentBank!.id)
        .first;
    final selected = <String>{};
    var toggleCount = 0;

    await tester.pumpWidget(
      _app(
        platform: TargetPlatform.windows,
        child: QuestionCard(
          controller: fixture.controller,
          question: question,
          number: 1,
          selected: selected,
          onToggle: (value) {
            toggleCount += 1;
            selected.add(value);
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsNothing);
    expect(find.text('复制'), findsNothing);
    final firstOption = question.options.entries.first;
    await tester.tap(find.text('${firstOption.key}. ${firstOption.value}'));
    await tester.pump();
    expect(selected, contains(firstOption.key));
    expect(toggleCount, 1);
  });

  testWidgets('Android 仅可搜索浏览题库，不显示编辑入口', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      _app(
        platform: TargetPlatform.android,
        child: BankPage(controller: fixture.controller),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('bank-question-search')), findsOneWidget);
    expect(find.byTooltip('编辑'), findsNothing);
    expect(find.text('手动录入题目'), findsNothing);
  });

  testWidgets('Windows 未交卷时不显示编辑题库入口', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );

    await tester.pumpWidget(
      _app(
        platform: TargetPlatform.windows,
        child: PaperPage(controller: fixture.controller, attempt: paper),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('submitted-paper-edit-question-action')),
      findsNothing,
    );
  });

  testWidgets('Windows 交卷后编辑题库，试卷即时显示最新内容', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    await fixture.controller.submitPaper(paper);

    await tester.pumpWidget(
      _app(
        platform: TargetPlatform.windows,
        size: const Size(1280, 800),
        child: PaperPage(controller: fixture.controller, attempt: paper),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('submitted-paper-edit-question-action')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('submitted-paper-edit-question-action')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('question-edit-stem')),
      '题库的新题干',
    );
    await tester.tap(find.byKey(const ValueKey('question-edit-save')));
    await tester.pumpAndSettle();

    expect(
      fixture.controller.database
          .questionById(paper.questions.first.question.id)!
          .stem,
      '题库的新题干',
    );
    expect(find.text('题库的新题干'), findsOneWidget);
    expect(find.text('题库已更新，当前试卷已显示最新题目内容。'), findsOneWidget);
  });

  testWidgets('Windows 交卷后可用右上角“？”标记题目疑问并可取消', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    final questionId = paper.questions.first.question.id;
    await fixture.controller.submitPaper(paper);

    await tester.pumpWidget(
      _app(
        platform: TargetPlatform.windows,
        size: const Size(1280, 800),
        child: PaperPage(controller: fixture.controller, attempt: paper),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.help_outline), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('question-uncertain-action')).first,
    );
    await tester.pumpAndSettle();
    expect(
      fixture.controller.database.progress(questionId).isUncertain,
      isTrue,
    );
    expect(find.byIcon(Icons.help), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('question-uncertain-action')).first,
    );
    await tester.pumpAndSettle();
    expect(
      fixture.controller.database.progress(questionId).isUncertain,
      isFalse,
    );
  });

  testWidgets('Android 交卷后不显示编辑题库入口', (tester) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final paper = fixture.controller.createPaper(
      requestedCount: 3,
      suggestedMinutes: 30,
      random: false,
    );
    await fixture.controller.submitPaper(paper);

    await tester.pumpWidget(
      _app(
        platform: TargetPlatform.android,
        size: const Size(1280, 800),
        child: PaperPage(controller: fixture.controller, attempt: paper),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('submitted-paper-edit-question-action')),
      findsNothing,
    );
  });
}

Widget _app({
  required TargetPlatform platform,
  required Widget child,
  Size size = const Size(1280, 800),
}) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ExamTheme.light().copyWith(platform: platform),
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
    final root = Directory.systemTemp.createTempSync('question-edit-ui-');
    return _Fixture(root, await AppController.createForTesting(root));
  }

  Future<void> dispose() async {
    controller.dispose();
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}
