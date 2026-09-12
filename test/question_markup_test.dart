import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/data/app_database.dart';
import 'package:personal_exam_app/data/app_paths.dart';
import 'package:personal_exam_app/domain/question_text.dart';
import 'package:personal_exam_app/services/bank_importer.dart';
import 'package:personal_exam_app/services/markdown_exporter.dart';

void main() {
  group('renderMarkupText（渲染语义）', () {
    test('块级标记转换为换行，段落间保留空行', () {
      expect(renderMarkupText('<p>甲</p><p>乙</p>'), '甲\n\n乙');
    });

    test('br 转换为单个换行', () {
      expect(renderMarkupText('第一行<br>第二行<br/>第三行'), '第一行\n第二行\n第三行');
    });

    test('无标记文本原样返回，数学不等号不被误当标记', () {
      expect(renderMarkupText('普通题干，无任何标记。'), '普通题干，无任何标记。');
      expect(renderMarkupText('当 a < b 且 b > c 时成立。'), '当 a < b 且 b > c 时成立。');
    });

    test('实体与嵌套标记被正确剥离', () {
      expect(renderMarkupText('<p>&nbsp;含&nbsp;空格</p>'), '含 空格');
      expect(
        renderMarkupText('<div><span>嵌套</span><b>加粗</b></div>'),
        '嵌套加粗',
      );
    });
  });

  group('plainText（历史行为）', () {
    test('检测到标记时整段剥离且不产生换行', () {
      expect(plainText('<p>甲</p><p>乙</p>'), '甲乙');
    });
    test('无标记原样返回', () {
      expect(plainText('普通题干'), '普通题干');
    });
  });

  group('设置项 render_question_markup', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('exam-markup-');
    });

    tearDown(() async {
      // 控制器持有的数据库句柄可能稍晚释放，重试删除。
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

    test('默认开启；关闭后重建控制器保持（持久化）', () async {
      var controller = await AppController.createForTesting(root);
      addTearDown(controller.dispose);
      expect(controller.renderQuestionMarkup, isTrue);
      controller.setRenderQuestionMarkup(false);
      expect(controller.renderQuestionMarkup, isFalse);

      final reloaded = await AppController.createForTesting(root);
      expect(reloaded.renderQuestionMarkup, isFalse);
    });

    test('questionText 按开关选择渲染或剥离', () async {
      final controller = await AppController.createForTesting(root);
      addTearDown(controller.dispose);
      expect(controller.questionText('<p>甲</p><p>乙</p>'), '甲\n\n乙');
      controller.setRenderQuestionMarkup(false);
      expect(controller.questionText('<p>甲</p><p>乙</p>'), '甲乙');
    });
  });

  group('导出跟随设置', () {
    late Directory temp;
    late AppDatabase db;
    late String bankId;
    late File tsv;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('exam-markup-export-');
      tsv = File('${temp.path}${Platform.pathSeparator}markup.tsv')
        ..writeAsStringSync('''
# schema_version: 1
# bank_id: 6bb446a3-a893-4f12-88db-f0ac05f55305
# name: 排版标记题库
# subject: 法规
# content_version: 1
编号\t年份\t题型\t题干\t选项A\t选项B\t选项C\t选项D\t选项E\t答案\t解析\t考点\t来源\tTags
M-001\t2025\tsingle\t<p>下列说法中，</p><p>正确的是（ ）。</p>\t甲\t乙\t丙\t丁\t\tB\t<p>乙正确。</p>\t考点\t来源\t真题
'''
            .trimLeft());
      db = AppDatabase.memory();
      final importer = BankImporter(db, AppPaths.at(temp));
      final preview = importer.previewFile(tsv.path);
      importer.commit(preview);
      bankId = preview.bankId;
    });

    tearDown(() {
      db.dispose();
      temp.deleteSync(recursive: true);
    });

    test('默认渲染：导出试卷的题干转换为换行且不含标记', () {
      final questions = db.listQuestions(bankId: bankId);
      final exporter = MarkdownExporter(db, AppPaths.at(temp));
      final paper = db.createPaper(
        bankId: bankId,
        title: '渲染试卷',
        questions: questions,
        suggestedDurationMs: 60000,
      );
      final directory = exporter.exportPaper(paper);
      final markdown = File(
        '${directory.path}${Platform.pathSeparator}试卷.md',
      ).readAsStringSync();
      expect(markdown.contains('<p>'), isFalse);
      expect(markdown.contains('下列说法中，\n\n正确的是（ ）。'), isTrue);
    });

    test('关闭渲染：导出原样保留标记（历史行为）', () {
      db.setSetting('render_question_markup', false);
      final questions = db.listQuestions(bankId: bankId);
      final exporter = MarkdownExporter(db, AppPaths.at(temp));
      final paper = db.createPaper(
        bankId: bankId,
        title: '原始试卷',
        questions: questions,
        suggestedDurationMs: 60000,
      );
      final directory = exporter.exportPaper(paper);
      final markdown = File(
        '${directory.path}${Platform.pathSeparator}试卷.md',
      ).readAsStringSync();
      expect(markdown.contains('<p>下列说法中，</p><p>正确的是（ ）。</p>'), isTrue);
    });
  });
}
