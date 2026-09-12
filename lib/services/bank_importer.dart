import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../data/app_database.dart';
import '../data/app_paths.dart';
import '../domain/models.dart';
import '../domain/bank_identity.dart';
import '../domain/policies.dart';

class BankImporter {
  const BankImporter(this.database, this.paths);

  final AppDatabase database;
  final AppPaths paths;

  ImportPreview previewFile(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    switch (p.extension(filePath).toLowerCase()) {
      case '.zip':
        return previewBytes(bytes, packagePath: filePath);
      case '.tsv':
        return previewDelimitedBytes(
          bytes,
          packagePath: filePath,
          delimiter: '\t',
        );
      case '.csv':
        return previewDelimitedBytes(
          bytes,
          packagePath: filePath,
          delimiter: ',',
        );
      default:
        return ImportPreview(
          packagePath: filePath,
          bankId: '',
          name: '',
          subject: '',
          contentVersion: 0,
          questions: const [],
          mediaFiles: const {},
          issues: const [
            ImportIssue(
              '仅支持 .zip、.tsv 或 .csv 题库文件',
              blocking: true,
              code: 'import.blocked.unsupportedFileType',
            ),
          ],
        );
    }
  }

  ImportPreview previewBytes(Uint8List bytes, {required String packagePath}) {
    final issues = <ImportIssue>[];
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (error) {
      return ImportPreview(
        packagePath: packagePath,
        bankId: '',
        name: '',
        subject: '',
        contentVersion: 0,
        questions: const [],
        mediaFiles: const {},
        issues: [
          ImportIssue(
            'ZIP 无法解析：$error',
            blocking: true,
            code: 'import.blocked.zipUnparsable',
            params: ['$error'],
          ),
        ],
      );
    }
    final files = <String, Uint8List>{};
    for (final file in archive.files.where((file) => file.isFile)) {
      files[file.name.replaceAll('\\', '/')] = file.content;
    }
    final manifestBytes = files['manifest.json'];
    final questionBytes = files['questions.jsonl'];
    if (manifestBytes == null) {
      issues.add(
        const ImportIssue(
          '缺少 manifest.json',
          blocking: true,
          code: 'import.blocked.missingManifest',
        ),
      );
    }
    if (questionBytes == null) {
      issues.add(
        const ImportIssue(
          '缺少 questions.jsonl',
          blocking: true,
          code: 'import.blocked.missingQuestions',
        ),
      );
    }
    if (manifestBytes == null || questionBytes == null) {
      return ImportPreview(
        packagePath: packagePath,
        bankId: '',
        name: '',
        subject: '',
        contentVersion: 0,
        questions: const [],
        mediaFiles: const {},
        issues: issues,
      );
    }
    Map<String, Object?> manifest;
    try {
      manifest = (jsonDecode(utf8.decode(manifestBytes)) as Map)
          .cast<String, Object?>();
    } catch (error) {
      issues.add(
        ImportIssue(
          'manifest.json 无法解析：$error',
          blocking: true,
          code: 'import.blocked.manifestUnparsable',
          params: ['$error'],
        ),
      );
      return ImportPreview(
        packagePath: packagePath,
        bankId: '',
        name: '',
        subject: '',
        contentVersion: 0,
        questions: const [],
        mediaFiles: const {},
        issues: issues,
      );
    }
    final schemaVersion = (manifest['schema_version'] as num?)?.toInt();
    if (schemaVersion != 1) {
      issues.add(
        ImportIssue(
          '不支持 schema_version=$schemaVersion',
          blocking: true,
          code: 'import.blocked.unsupportedSchemaVersion',
          params: ['$schemaVersion'],
        ),
      );
    }
    final bankId = manifest['bank_id']?.toString() ?? '';
    if (!isSafeBankId(bankId)) {
      issues.add(
        const ImportIssue(
          'bank_id 包含无效目录字符',
          blocking: true,
          code: 'import.blocked.invalidBankId',
        ),
      );
    }
    final name = manifest['name']?.toString() ?? '';
    final subject = manifest['subject']?.toString() ?? '';
    final contentVersion = (manifest['content_version'] as num?)?.toInt() ?? 0;
    if (bankId.isEmpty || name.isEmpty || contentVersion < 1) {
      issues.add(
        const ImportIssue(
          '题库 ID、名称或内容版本无效',
          blocking: true,
          code: 'import.blocked.invalidBankMetadata',
        ),
      );
    }
    final actualHash = sha256.convert(questionBytes).toString();
    if (manifest['questions_sha256']?.toString().toLowerCase() != actualHash) {
      issues.add(
        const ImportIssue(
          'questions.jsonl 的 SHA-256 与清单不一致',
          blocking: true,
          code: 'import.blocked.questionsHashMismatch',
        ),
      );
    }
    final questions = <Question>[];
    final ids = <String>{};
    final externalIds = <String>{};
    final stems = <String>{};
    final lines = const LineSplitter().convert(utf8.decode(questionBytes));
    for (var index = 0; index < lines.length; index++) {
      if (lines[index].trim().isEmpty) continue;
      try {
        final raw = (jsonDecode(lines[index]) as Map).cast<String, Object?>();
        final id = raw['question_id']?.toString() ?? '';
        final externalId = raw['external_id']?.toString();
        final stem = raw['stem']?.toString().trim() ?? '';
        final typeName = raw['type']?.toString() ?? '';
        final options = (raw['options'] as Map? ?? const {}).map(
          (key, value) =>
              MapEntry(key.toString().toUpperCase(), value.toString().trim()),
        )..removeWhere((key, value) => value.isEmpty);
        final answersRaw = (raw['answers'] as List? ?? const [])
            .map((e) => e.toString())
            .toList();
        final isQa = typeName == 'qa';
        final answers = isQa
            ? [
                if (answersRaw.join('\n').trim().isNotEmpty)
                  answersRaw.join('\n').trim(),
              ]
            : AnswerPolicy.normalize(answersRaw);
        if (id.isEmpty) {
          issues.add(
            ImportIssue(
              '第 ${index + 1} 行 question_id 为空',
              blocking: true,
              code: 'import.blocked.emptyQuestionId',
              params: [index + 1],
            ),
          );
        }
        if (!ids.add(id)) {
          issues.add(
            ImportIssue(
              '重复 question_id：$id',
              blocking: true,
              code: 'import.blocked.dupQuestionId',
              params: [id],
            ),
          );
        }
        if (typeName != 'single' && typeName != 'multiple' && typeName != 'qa') {
          issues.add(
            ImportIssue(
              '$id 的题型无效：$typeName',
              blocking: true,
              code: 'import.blocked.invalidQuestionType',
              params: [id, typeName],
            ),
          );
        }
        if (stem.isEmpty) {
          issues.add(
            ImportIssue(
              '$id 的题干为空',
              blocking: true,
              code: 'import.blocked.emptyStem',
              params: [id],
            ),
          );
        }
        if (isQa) {
          if (options.isNotEmpty) {
            issues.add(
              ImportIssue(
                '$id 是问答题但填写了选项',
                blocking: true,
                code: 'import.blocked.qaWithOptions',
                params: [id],
              ),
            );
          }
        } else {
          if (options.length < 2) {
            issues.add(
              ImportIssue(
                '$id 少于两个有效选项',
                blocking: true,
                code: 'import.blocked.tooFewOptions',
                params: [id],
              ),
            );
          }
          if (answers.any((answer) => !options.containsKey(answer)) ||
              answers.isEmpty) {
            issues.add(
              ImportIssue(
                '$id 的答案不在有效选项中',
                blocking: true,
                code: 'import.blocked.answerNotInOptions',
                params: [id],
              ),
            );
          }
          if (typeName == 'single' && answers.length != 1) {
            issues.add(
              ImportIssue(
                '$id 是单选题但答案数量不是 1',
                blocking: true,
                code: 'import.blocked.singleAnswerCount',
                params: [id],
              ),
            );
          }
        }
        if (externalId != null &&
            externalId.isNotEmpty &&
            !externalIds.add(externalId)) {
          issues.add(
            ImportIssue(
              '重复 external_id：$externalId',
              blocking: false,
              code: 'import.warning.dupExternalId',
              params: [externalId],
            ),
          );
        }
        final normalizedStem = stem
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();
        if (!stems.add(normalizedStem)) {
          issues.add(
            ImportIssue(
              '存在相同题干：$externalId',
              blocking: false,
              code: 'import.warning.dupStem',
              params: ['$externalId'],
            ),
          );
        }
        final media = (raw['media'] as List? ?? const [])
            .map((e) => e.toString())
            .toList();
        for (final mediaPath in media) {
          if (!files.containsKey(mediaPath.replaceAll('\\', '/'))) {
            issues.add(
              ImportIssue(
                '$id 声明的媒体不存在：$mediaPath',
                blocking: true,
                code: 'import.blocked.missingMedia',
                params: [id, mediaPath],
              ),
            );
          }
        }
        final scoring =
            (raw['scoring_rule'] as Map?)?.cast<String, Object?>() ?? const {};
        questions.add(
          Question(
            id: id,
            bankId: bankId,
            externalId: externalId,
            contentVersion:
                (raw['content_version'] as num?)?.toInt() ?? contentVersion,
            type: switch (typeName) {
              'multiple' => QuestionType.multiple,
              'qa' => QuestionType.qa,
              _ => QuestionType.single,
            },
            stem: stem,
            options: options,
            answers: answers,
            explanation: raw['explanation']?.toString() ?? '',
            knowledgePoint: raw['knowledge_point']?.toString() ?? '',
            source: raw['source']?.toString() ?? '',
            year: raw['year']?.toString() ?? '',
            chapter: raw['chapter']?.toString() ?? '',
            tags: (raw['tags'] as List? ?? const [])
                .map((e) => e.toString())
                .toList(),
            media: media,
            scoringRule: ScoringRule.fromJson(scoring),
            isActive: true,
          ),
        );
        if ((raw['explanation']?.toString() ?? '').trim().isEmpty) {
          issues.add(
            ImportIssue(
              '$id 的解析为空',
              blocking: false,
              code: 'import.warning.emptyExplanation',
              params: [id],
            ),
          );
        }
        if ((raw['year']?.toString() ?? '').isEmpty ||
            (raw['chapter']?.toString() ?? '').isEmpty ||
            (raw['source']?.toString() ?? '').isEmpty) {
          issues.add(
            ImportIssue(
              '$id 的年份、章节或来源不完整',
              blocking: false,
              code: 'import.warning.incompleteMetadata',
              params: [id],
            ),
          );
        }
      } catch (error) {
        issues.add(
          ImportIssue(
            'questions.jsonl 第 ${index + 1} 行无法解析：$error',
            blocking: true,
            code: 'import.blocked.questionLineUnparsable',
            params: [index + 1, '$error'],
          ),
        );
      }
    }
    if ((manifest['question_count'] as num?)?.toInt() != questions.length) {
      issues.add(
        ImportIssue(
          '清单题量 ${manifest['question_count']} 与实际 ${questions.length} 不一致',
          blocking: true,
          code: 'import.blocked.questionCountMismatch',
          params: ['${manifest['question_count']}', questions.length],
        ),
      );
    }
    final mediaFiles = <String, List<int>>{};
    for (final entry in files.entries.where(
      (entry) => entry.key.startsWith('media/'),
    )) {
      mediaFiles[entry.key] = entry.value;
    }
    for (final item in (manifest['media_manifest'] as List? ?? const [])) {
      final map = (item as Map).cast<String, Object?>();
      final path = map['path']?.toString() ?? '';
      final content = files[path];
      if (content == null) continue;
      if (map['sha256']?.toString().toLowerCase() !=
          sha256.convert(content).toString()) {
        issues.add(
          ImportIssue(
            '媒体哈希不匹配：$path',
            blocking: true,
            code: 'import.blocked.mediaHashMismatch',
            params: [path],
          ),
        );
      }
    }
    return ImportPreview(
      packagePath: packagePath,
      bankId: bankId,
      name: name,
      subject: subject,
      contentVersion: contentVersion,
      questions: questions,
      mediaFiles: mediaFiles,
      issues: issues,
    );
  }

  ImportPreview previewDelimitedBytes(
    Uint8List bytes, {
    required String packagePath,
    required String delimiter,
  }) {
    final issues = <ImportIssue>[];
    if (delimiter != '\t' && delimiter != ',') {
      throw ArgumentError.value(delimiter, 'delimiter', '只允许 Tab 或逗号');
    }
    String source;
    try {
      source = utf8.decode(bytes);
    } catch (error) {
      return _emptyPreview(
        packagePath,
        ImportIssue(
          '文件不是有效的 UTF-8：$error',
          blocking: true,
          code: 'import.blocked.invalidUtf8',
          params: ['$error'],
        ),
      );
    }

    final extracted = _extractMetadata(source);
    List<List<String>> rows;
    try {
      rows = _parseDelimited(extracted.body, delimiter);
    } catch (error) {
      return _emptyPreview(
        packagePath,
        ImportIssue(
          '分隔文件无法解析：$error',
          blocking: true,
          code: 'import.blocked.delimitedUnparsable',
          params: ['$error'],
        ),
      );
    }
    if (rows.isEmpty) {
      return _emptyPreview(
        packagePath,
        const ImportIssue(
          '文件缺少表头和题目',
          blocking: true,
          code: 'import.blocked.emptyFile',
        ),
      );
    }

    final metadata = extracted.metadata;
    final schemaVersion = int.tryParse(
      _metadata(metadata, const ['schema_version', '格式版本']) ?? '1',
    );
    if (schemaVersion != 1) {
      issues.add(
        ImportIssue(
          '不支持 schema_version=$schemaVersion',
          blocking: true,
          code: 'import.blocked.unsupportedSchemaVersion',
          params: ['$schemaVersion'],
        ),
      );
    }
    var name = _metadata(metadata, const ['name', '题库名称'])?.trim() ?? '';
    if (name.isEmpty) {
      name = p.basenameWithoutExtension(packagePath);
      issues.add(
        ImportIssue(
          '未提供题库名称，已使用文件名“$name”',
          blocking: false,
          code: 'import.warning.bankNameFallback',
          params: [name],
        ),
      );
    }
    final subject = _metadata(metadata, const ['subject', '科目'])?.trim() ?? '';
    final versionText =
        _metadata(metadata, const ['content_version', '内容版本']) ?? '1';
    final contentVersion = int.tryParse(versionText) ?? 0;
    if (contentVersion < 1) {
      issues.add(
        ImportIssue(
          '题库内容版本无效：$versionText',
          blocking: true,
          code: 'import.blocked.invalidContentVersion',
          params: [versionText],
        ),
      );
    }
    var bankId = _metadata(metadata, const ['bank_id', '题库id'])?.trim() ?? '';
    if (bankId.isEmpty) {
      bankId = _stableUuid('personal-exam-bank|$name|$subject');
      issues.add(
        const ImportIssue(
          '未提供 bank_id，已按题库名称和科目生成稳定 ID；以后更新时不要改变这两项',
          blocking: false,
          code: 'import.warning.generatedBankId',
        ),
      );
    }

    final rawHeaders = rows.first.map((value) => value.trim()).toList();
    if (!isSafeBankId(bankId)) {
      issues.add(
        const ImportIssue(
          'bank_id 包含无效目录字符',
          blocking: true,
          code: 'import.blocked.invalidBankId',
        ),
      );
    }
    final headers = <String, int>{};
    for (var index = 0; index < rawHeaders.length; index++) {
      final key = _normalizeHeader(rawHeaders[index]);
      if (key.isEmpty) continue;
      if (headers.containsKey(key)) {
        issues.add(
          ImportIssue(
            '存在重复表头：${rawHeaders[index]}',
            blocking: true,
            code: 'import.blocked.dupHeader',
            params: [rawHeaders[index]],
          ),
        );
      } else {
        headers[key] = index;
      }
    }
    const requiredHeaders = <String, String>{
      '编号': '编号',
      '题型': '题型',
      '题干': '题干',
      '选项a': '选项A',
      '选项b': '选项B',
      '答案': '答案',
    };
    for (final entry in requiredHeaders.entries) {
      if (!headers.containsKey(entry.key)) {
        issues.add(
          ImportIssue(
            '缺少必需列：${entry.value}',
            blocking: true,
            code: 'import.blocked.missingColumn',
            params: [entry.value],
          ),
        );
      }
    }
    if (issues.any((issue) => issue.blocking)) {
      return ImportPreview(
        packagePath: packagePath,
        bankId: bankId,
        name: name,
        subject: subject,
        contentVersion: contentVersion,
        questions: const [],
        mediaFiles: const {},
        issues: issues,
      );
    }

    String cell(List<String> row, String header) {
      final index = headers[_normalizeHeader(header)];
      return index == null || index >= row.length ? '' : row[index].trim();
    }

    final questions = <Question>[];
    final ids = <String>{};
    final externalIds = <String>{};
    final stems = <String>{};
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.every((value) => value.trim().isEmpty)) continue;
      final displayRow = rowIndex + 1;
      if (row.length != rawHeaders.length) {
        issues.add(
          ImportIssue(
            '第 $displayRow 行有 ${row.length} 列，表头有 ${rawHeaders.length} 列',
            blocking: true,
            code: 'import.blocked.rowColumnMismatch',
            params: [displayRow, row.length, rawHeaders.length],
          ),
        );
      }
      final externalId = cell(row, '编号');
      final explicitId = cell(row, '题目ID');
      final id = explicitId.isEmpty
          ? _stableUuid('personal-exam-question|$bankId|$externalId')
          : explicitId;
      final stem = cell(row, '题干');
      final typeText = cell(row, '题型').toLowerCase();
      final type = switch (typeText) {
        'single' || '单选' || '单选题' => QuestionType.single,
        'multiple' || '多选' || '多选题' => QuestionType.multiple,
        'qa' || '问答' || '问答题' || '简答' || '简答题' => QuestionType.qa,
        _ => null,
      };
      final options = <String, String>{};
      for (final letter in const ['A', 'B', 'C', 'D', 'E']) {
        final value = cell(row, '选项$letter');
        if (value.isNotEmpty) options[letter] = value;
      }
      // 问答题的答案列为参考答案原文，不做 A–E 归一化；允许为空。
      final answers = type == QuestionType.qa
          ? [if (cell(row, '答案').trim().isNotEmpty) cell(row, '答案').trim()]
          : AnswerPolicy.normalize([cell(row, '答案')]);
      final questionVersionText = cell(row, '题目版本');
      final questionVersion = questionVersionText.isEmpty
          ? contentVersion
          : int.tryParse(questionVersionText) ?? 0;

      if (externalId.isEmpty) {
        issues.add(
          ImportIssue(
            '第 $displayRow 行编号为空',
            blocking: true,
            code: 'import.blocked.emptyExternalId',
            params: [displayRow],
          ),
        );
      }
      if (!ids.add(id)) {
        issues.add(
          ImportIssue(
            '重复题目 ID：$id',
            blocking: true,
            code: 'import.blocked.dupExplicitId',
            params: [id],
          ),
        );
      }
      if (!externalIds.add(externalId)) {
        issues.add(
          ImportIssue(
            '重复编号：$externalId',
            blocking: true,
            code: 'import.blocked.dupExternalId',
            params: [externalId],
          ),
        );
      }
      if (type == null) {
        issues.add(
          ImportIssue(
            '$externalId 的题型无效：$typeText',
            blocking: true,
            code: 'import.blocked.invalidQuestionType',
            params: [externalId, typeText],
          ),
        );
      }
      if (stem.isEmpty) {
        issues.add(
          ImportIssue(
            '$externalId 的题干为空',
            blocking: true,
            code: 'import.blocked.emptyStem',
            params: [externalId],
          ),
        );
      }
      if (type == QuestionType.qa) {
        if (options.isNotEmpty) {
          issues.add(
            ImportIssue(
              '$externalId 是问答题但填写了选项',
              blocking: true,
              code: 'import.blocked.qaWithOptions',
              params: [externalId],
            ),
          );
        }
      } else {
        if (options.length < 2) {
          issues.add(
            ImportIssue(
              '$externalId 少于两个有效选项',
              blocking: true,
              code: 'import.blocked.tooFewOptions',
              params: [externalId],
            ),
          );
        }
        if (answers.isEmpty ||
            answers.any((answer) => !options.containsKey(answer))) {
          issues.add(
            ImportIssue(
              '$externalId 的答案不在有效选项中',
              blocking: true,
              code: 'import.blocked.answerNotInOptions',
              params: [externalId],
            ),
          );
        }
        if (type == QuestionType.single && answers.length != 1) {
          issues.add(
            ImportIssue(
              '$externalId 是单选题但答案数量不是 1',
              blocking: true,
              code: 'import.blocked.singleAnswerCount',
              params: [externalId],
            ),
          );
        }
      }
      if (questionVersion < 1) {
        issues.add(
          ImportIssue(
            '$externalId 的题目版本无效',
            blocking: true,
            code: 'import.blocked.invalidQuestionVersion',
            params: [externalId],
          ),
        );
      }
      final normalizedStem = stem.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      if (!stems.add(normalizedStem)) {
        issues.add(
          ImportIssue(
            '存在相同题干：$externalId',
            blocking: false,
            code: 'import.warning.dupStem',
            params: [externalId],
          ),
        );
      }
      final explanation = cell(row, '解析');
      final year = cell(row, '年份');
      final chapter = cell(row, '章节');
      final sourceName = cell(row, '来源');
      if (explanation.isEmpty) {
        issues.add(
          ImportIssue(
            '$externalId 的解析为空',
            blocking: false,
            code: 'import.warning.emptyExplanation',
            params: [externalId],
          ),
        );
      }
      if (year.isEmpty || chapter.isEmpty || sourceName.isEmpty) {
        issues.add(
          ImportIssue(
            '$externalId 的年份、章节或来源不完整',
            blocking: false,
            code: 'import.warning.incompleteMetadata',
            params: [externalId],
          ),
        );
      }
      questions.add(
        Question(
          id: id,
          bankId: bankId,
          externalId: externalId,
          contentVersion: questionVersion < 1 ? 1 : questionVersion,
          type: type ?? QuestionType.single,
          stem: stem,
          options: options,
          answers: answers,
          explanation: explanation,
          knowledgePoint: cell(row, '考点'),
          source: sourceName,
          year: year,
          chapter: chapter,
          tags: _splitList(cell(row, 'Tags')),
          media: const [],
          scoringRule: const ScoringRule(),
          isActive: true,
        ),
      );
    }
    if (questions.isEmpty) {
      issues.add(
        const ImportIssue(
          '文件中没有有效题目行',
          blocking: true,
          code: 'import.blocked.noValidQuestions',
        ),
      );
    }
    return ImportPreview(
      packagePath: packagePath,
      bankId: bankId,
      name: name,
      subject: subject,
      contentVersion: contentVersion,
      questions: questions,
      mediaFiles: const {},
      issues: issues,
    );
  }

  void commit(ImportPreview preview) {
    if (!preview.canImport) throw StateError('导入预览仍包含阻断性错误');
    if (!isSafeBankId(preview.bankId)) {
      throw const FormatException('bank_id 包含无效目录字符');
    }
    final target = Directory(
      p.join(paths.media.path, preview.bankId, 'v${preview.contentVersion}'),
    )..createSync(recursive: true);
    for (final entry in preview.mediaFiles.entries) {
      File(
        p.join(target.path, p.basename(entry.key)),
      ).writeAsBytesSync(entry.value, flush: true);
    }
    final report = jsonEncode(<String, Object?>{
      'questions': preview.questions.length,
      'single': preview.singleCount,
      'multiple': preview.multipleCount,
      'qa': preview.qaCount,
      'issues': preview.issues
          .map((e) => {'blocking': e.blocking, 'message': e.message})
          .toList(),
    });
    database.importBank(preview, reportJson: report);
    database.enqueueMediaFiles(
      bankId: preview.bankId,
      contentVersion: preview.contentVersion,
      mediaFiles: preview.mediaFiles,
    );
  }
}

ImportPreview _emptyPreview(String packagePath, ImportIssue issue) =>
    ImportPreview(
      packagePath: packagePath,
      bankId: '',
      name: '',
      subject: '',
      contentVersion: 0,
      questions: const [],
      mediaFiles: const {},
      issues: [issue],
    );

class _MetadataBody {
  const _MetadataBody(this.metadata, this.body);
  final Map<String, String> metadata;
  final String body;
}

_MetadataBody _extractMetadata(String source) {
  if (source.startsWith('\ufeff')) source = source.substring(1);
  final metadata = <String, String>{};
  var offset = 0;
  while (offset < source.length) {
    final newline = source.indexOf('\n', offset);
    final end = newline < 0 ? source.length : newline;
    final rawLine = source
        .substring(offset, end)
        .replaceFirst(RegExp(r'\r$'), '');
    final line = rawLine.trim();
    if (line.isEmpty) {
      offset = newline < 0 ? source.length : newline + 1;
      continue;
    }
    if (!line.startsWith('#')) break;
    final content = line.substring(1).trim();
    final colon = content.indexOf(RegExp(r'[:=：]'));
    if (colon > 0) {
      metadata[_normalizeHeader(content.substring(0, colon))] = content
          .substring(colon + 1)
          .trim();
    }
    offset = newline < 0 ? source.length : newline + 1;
  }
  return _MetadataBody(metadata, source.substring(offset));
}

String? _metadata(Map<String, String> metadata, List<String> keys) {
  for (final key in keys) {
    final value = metadata[_normalizeHeader(key)];
    if (value != null) return value;
  }
  return null;
}

String _normalizeHeader(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

List<String> _splitList(String value) => value
    .split(RegExp(r'[,，;；|]+'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toSet()
    .toList();

String _stableUuid(String value) {
  final bytes = sha256.convert(utf8.encode(value)).bytes.sublist(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

List<List<String>> _parseDelimited(String source, String delimiter) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var index = 0; index < source.length; index++) {
    final char = source[index];
    if (quoted) {
      if (char == '"') {
        if (index + 1 < source.length && source[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }
    if (char == '"' && field.isEmpty) {
      quoted = true;
    } else if (char == delimiter) {
      row.add(field.toString());
      field = StringBuffer();
    } else if (char == '\r' || char == '\n') {
      if (char == '\r' &&
          index + 1 < source.length &&
          source[index + 1] == '\n') {
        index++;
      }
      row.add(field.toString());
      if (row.any((value) => value.isNotEmpty)) rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else {
      field.write(char);
    }
  }
  if (quoted) throw const FormatException('存在未闭合的双引号');
  row.add(field.toString());
  if (row.any((value) => value.isNotEmpty)) rows.add(row);
  return rows;
}
