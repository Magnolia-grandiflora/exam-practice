import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/data/app_database.dart';
import 'package:personal_exam_app/data/app_paths.dart';
import 'package:personal_exam_app/services/bank_importer.dart';

void main() {
  test('外部 ZIP 的 bank_id 不得改变媒体写入目录', () {
    final temp = Directory.systemTemp.createTempSync('exam-bank-path-');
    final db = AppDatabase.memory();
    try {
      final importer = BankImporter(db, AppPaths.at(temp));
      for (final bankId in [
        '../escape',
        r'..\escape',
        'C:/escape',
        '.',
        'NUL',
      ]) {
        final archive = ZipDecoder().decodeBytes(
          File('assets/test-bank/test-bank.zip').readAsBytesSync(),
        );
        final manifestFile = archive.findFile('manifest.json')!;
        final manifest = jsonDecode(utf8.decode(manifestFile.content)) as Map;
        manifest['bank_id'] = bankId;
        final bytes = utf8.encode(jsonEncode(manifest));
        archive.addFile(ArchiveFile('manifest.json', bytes.length, bytes));
        final preview = importer.previewBytes(
          Uint8List.fromList(ZipEncoder().encode(archive)),
          packagePath: 'test.zip',
        );
        expect(preview.canImport, isFalse, reason: bankId);
        expect(() => importer.commit(preview), throwsStateError);
      }
      expect(db.listBanks(), isEmpty);
      expect(AppPaths.at(temp).media.existsSync(), isFalse);
    } finally {
      db.dispose();
      temp.deleteSync(recursive: true);
    }
  });

  test('内置 15 题包通过阻断校验并满足题型配比', () {
    final temp = Directory.systemTemp.createTempSync('exam-bank-zip-');
    final db = AppDatabase.memory();
    try {
      final preview = BankImporter(
        db,
        AppPaths.at(temp),
      ).previewFile('assets/test-bank/test-bank.zip');
      expect(
        preview.canImport,
        isTrue,
        reason: preview.issues.map((e) => e.message).join('\n'),
      );
      expect(preview.questions, hasLength(15));
      expect(preview.singleCount, 10);
      expect(preview.multipleCount, 5);
      expect(preview.mediaFiles.length, 2);
      expect(preview.questions.where((q) => q.media.isNotEmpty), hasLength(2));
    } finally {
      db.dispose();
      temp.deleteSync(recursive: true);
    }
  });

  test('损坏的 ZIP 被拒绝', () {
    final temp = Directory.systemTemp.createTempSync('exam-bank-bad-zip-');
    final db = AppDatabase.memory();
    try {
      final preview = BankImporter(db, AppPaths.at(temp)).previewBytes(
        File('pubspec.yaml').readAsBytesSync(),
        packagePath: 'bad.zip',
      );
      expect(preview.canImport, isFalse);
      expect(preview.issues.any((e) => e.blocking), isTrue);
    } finally {
      db.dispose();
      temp.deleteSync(recursive: true);
    }
  });

  test('UTF-8 TSV 中文表头可导入并自动生成稳定题目 ID', () {
    final temp = Directory.systemTemp.createTempSync('exam-bank-tsv-');
    final file = File('${temp.path}${Platform.pathSeparator}法规题库.tsv');
    file.writeAsStringSync(
      '''
# schema_version: 1
# bank_id: 6bb446a3-a893-4f12-88db-f0ac05f55301
# name: TSV 测试题库
# subject: 法规
# content_version: 2
编号\t年份\t题型\t题干\t选项A\t选项B\t选项C\t选项D\t选项E\t答案\t解析\t考点\t来源\tTags
TSV-001\t2025\tsingle\t正确的是（ ）。\t甲\t乙\t丙\t丁\t\tB\t乙正确。\t考点一\t来源一\t真题|法规
TSV-002\t2025\tmultiple\t符合要求的有（ ）。\t甲\t乙\t丙\t丁\t\tAC\t甲、丙正确。\t考点二\t来源二\t真题|多选
'''
          .trimLeft(),
    );
    final db = AppDatabase.memory();
    try {
      final importer = BankImporter(db, AppPaths.at(temp));
      final first = importer.previewFile(file.path);
      final second = importer.previewFile(file.path);
      expect(
        first.canImport,
        isTrue,
        reason: first.issues.map((issue) => issue.message).join('\n'),
      );
      expect(first.name, 'TSV 测试题库');
      expect(first.contentVersion, 2);
      expect(first.questions, hasLength(2));
      expect(first.singleCount, 1);
      expect(first.multipleCount, 1);
      expect(first.questions.last.answers, ['A', 'C']);
      expect(first.questions.first.tags, ['真题', '法规']);
      expect(first.questions.first.id, second.questions.first.id);
      expect(first.issues.any((issue) => issue.message.contains('章节')), isTrue);
      importer.commit(first);
      expect(db.listBanks(), hasLength(1));
      expect(db.listQuestions(bankId: first.bankId), hasLength(2));
    } finally {
      db.dispose();
      temp.deleteSync(recursive: true);
    }
  });

  test('CSV 支持逗号、双引号和带换行的引用字段', () {
    final temp = Directory.systemTemp.createTempSync('exam-bank-csv-');
    final file = File('${temp.path}${Platform.pathSeparator}quoted.csv');
    file.writeAsStringSync(
      '''
# schema_version: 1
# bank_id: 9ca4b996-330c-4129-a936-6a5f4b8e1801
# name: CSV 测试题库
# subject: 测试
# content_version: 1
编号,年份,题型,题干,选项A,选项B,选项C,选项D,选项E,答案,解析,考点,来源,章节,Tags
CSV-001,2025,single,"第一行,
第二行",选项甲,选项乙,,,,A,"解析含 ""引号"", 以及逗号",考点,来源,章节,标签1|标签2
'''
          .trimLeft(),
    );
    final db = AppDatabase.memory();
    try {
      final preview = BankImporter(
        db,
        AppPaths.at(temp),
      ).previewFile(file.path);
      expect(
        preview.canImport,
        isTrue,
        reason: preview.issues.map((issue) => issue.message).join('\n'),
      );
      expect(preview.questions, hasLength(1));
      expect(preview.questions.single.stem, '第一行,\n第二行');
      expect(preview.questions.single.explanation, '解析含 "引号", 以及逗号');
      expect(preview.questions.single.tags, ['标签1', '标签2']);
    } finally {
      db.dispose();
      temp.deleteSync(recursive: true);
    }
  });

  test('未知题库扩展名被明确拒绝', () {
    final temp = Directory.systemTemp.createTempSync('exam-bank-ext-');
    final file = File('${temp.path}${Platform.pathSeparator}bank.txt')
      ..writeAsStringSync('not a bank');
    final db = AppDatabase.memory();
    try {
      final preview = BankImporter(
        db,
        AppPaths.at(temp),
      ).previewFile(file.path);
      expect(preview.canImport, isFalse);
      expect(preview.issues.single.message, contains('.tsv'));
    } finally {
      db.dispose();
      temp.deleteSync(recursive: true);
    }
  });

  test('ZIP 题目未单列版本时继承题库版本', () {
    final temp = Directory.systemTemp.createTempSync('exam-bank-version-');
    final db = AppDatabase.memory();
    try {
      final importer = BankImporter(db, AppPaths.at(temp));
      final original = File('assets/test-bank/test-bank.zip').readAsBytesSync();
      final preview = importer.previewBytes(
        original,
        packagePath: 'test-bank.zip',
      );
      expect(preview.questions, isNotEmpty);
      expect(
        preview.questions.every(
          (question) => question.contentVersion == preview.contentVersion,
        ),
        isTrue,
      );
    } finally {
      db.dispose();
      temp.deleteSync(recursive: true);
    }
  });
}
