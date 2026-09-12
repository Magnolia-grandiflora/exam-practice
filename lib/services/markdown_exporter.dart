import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:qr/qr.dart';

import '../domain/coded_exceptions.dart';
import '../data/app_database.dart';
import '../data/app_paths.dart';
import '../domain/models.dart';
import '../domain/policies.dart';
import '../domain/question_text.dart';
import 'omr_identity.dart';

/// 导出文档（试卷 / 答题卡 / 解析 / 回顾 / 错题集）中的用户可见文案。
///
/// 默认值与既有中文导出文案逐字一致（含全角标点与全角空格）——中文环境下
/// 导出产物必须逐字节不变。带占位符的行用 `{token}` 书写（如 `{count}`），
/// 导出器写入前做一次线性替换，用户内容中的 `{` 不会被二次展开。
/// 本地化工厂见 `lib/ui/export_labels.dart`。
class ExportLabels {
  const ExportLabels({
    this.paperFileName = '试卷',
    this.answersFileName = '答案与解析',
    this.reviewFileName = '作答回顾',
    this.answerSheetFileName = '答题卡',
    this.resourcesFolderName = '资源',
    this.answersYamlSuffix = '（答案与解析）',
    this.answersHeadingSuffix = ' · 答案与解析',
    this.reviewYamlSuffix = '（作答回顾）',
    this.reviewHeadingSuffix = ' · 作答回顾',
    this.paperStatsLine = '题量：{count}　建议用时：{minutes} 分钟',
    this.multipleChoiceTag = '【多选】',
    this.singleChoiceTag = '【单选】',
    this.missingMediaWarning = '> [!warning] 题目图片缺失：{path}',
    this.correctAnswersBoldLine = '**正确答案：{answers}**',
    this.explanationLine = '解析：{explanation}',
    this.knowledgePointSourceLine = '考点：{knowledgePoint}　来源：{source}',
    this.reviewScoreLine = '得分：{score} / {max}',
    this.totalDurationLine = '总用时：{duration}',
    this.overtimeLine = '超时：{duration}',
    this.unansweredCountLine = '未答：{count} 题',
    this.unansweredStatus = '未答',
    this.fullyCorrectStatus = '完全正确',
    this.wrongStatus = '错误',
    this.verdictLine = '判定：{status}',
    this.userSelectionLine = '用户选择：{answers}',
    this.correctAnswerLine = '正确答案：{answers}',
    this.questionDurationLine = '本题交互估计用时：{duration}',
    this.favoriteUncertainLine = '收藏：{favorite}；不确定：{uncertain}',
    this.yesLabel = '是',
    this.noLabel = '否',
    this.personalNoteLine = '个人笔记：{note}',
    this.emptyNoteValue = '无',
    this.knowledgePointSourceReviewLine =
        '考点：{knowledgePoint}；来源：{source}',
    this.answerSeparator = '、',
    this.answerSheetYamlSuffix = '（答题卡）',
    this.answerSheetHeadingSuffix = ' · 答题卡',
    this.answerSheetStatsLine =
        '个人练习专用　共 {count} 题　单选 {single} 题　多选 {multiple} 题',
    this.answerSheetQrAlt = '答题卡二维码',
    this.fillNoteHtml =
        '<strong>填涂说明：</strong>将所选圆圈完整涂黑；多选题可涂多个选项。'
        '修改时请擦净，无法擦净时重新打印。',
    this.answerSectionTitle = '选择题答题区',
    this.answerSectionHint = '请按试卷题号顺序填涂',
    this.questionNumberHeader = '题号',
    this.wrongQuestionsTitle = '当前错题',
    this.recentSelectionLine = '最近选择：{answers}',
    this.knowledgePointLine = '考点：{knowledgePoint}',
    this.sourceLine = '来源：{source}',
    this.attemptStatsLine = '累计作答：{seen} 次；答错：{wrong} 次',
    this.qaTag = '【问答】',
    this.qaReferenceAnswerLine = '参考答案：{answer}',
    this.qaEmptyReferenceAnswer = '（未提供参考答案）',
    this.qaUserAnswerLine = '用户作答：{answer}',
    this.qaUnansweredText = '未作答',
    this.answerSheetQaSectionTitle = '问答题答题区',
    this.answerSheetQaItemLabel = '第 {number} 题',
    this.answerSheetQaOverflowNote = '其余问答题答题区不足，请直接在试卷上作答',
    this.answerSheetQaStatsSuffix = '　问答 {qa} 题',
  });

  final String paperFileName;
  final String answersFileName;
  final String reviewFileName;
  final String answerSheetFileName;
  final String resourcesFolderName;
  final String answersYamlSuffix;
  final String answersHeadingSuffix;
  final String reviewYamlSuffix;
  final String reviewHeadingSuffix;
  final String paperStatsLine;
  final String multipleChoiceTag;
  final String singleChoiceTag;
  final String missingMediaWarning;
  final String correctAnswersBoldLine;
  final String explanationLine;
  final String knowledgePointSourceLine;
  final String reviewScoreLine;
  final String totalDurationLine;
  final String overtimeLine;
  final String unansweredCountLine;
  final String unansweredStatus;
  final String fullyCorrectStatus;
  final String wrongStatus;
  final String verdictLine;
  final String userSelectionLine;
  final String correctAnswerLine;
  final String questionDurationLine;
  final String favoriteUncertainLine;
  final String yesLabel;
  final String noLabel;
  final String personalNoteLine;
  final String emptyNoteValue;
  final String knowledgePointSourceReviewLine;
  final String answerSeparator;
  final String answerSheetYamlSuffix;
  final String answerSheetHeadingSuffix;
  final String answerSheetStatsLine;
  final String answerSheetQrAlt;
  final String fillNoteHtml;
  final String answerSectionTitle;
  final String answerSectionHint;
  final String questionNumberHeader;
  final String wrongQuestionsTitle;
  final String recentSelectionLine;
  final String knowledgePointLine;
  final String sourceLine;
  final String attemptStatsLine;
  final String qaTag;
  final String qaReferenceAnswerLine;
  final String qaEmptyReferenceAnswer;
  final String qaUserAnswerLine;
  final String qaUnansweredText;
  final String answerSheetQaSectionTitle;
  final String answerSheetQaItemLabel;
  final String answerSheetQaOverflowNote;
  final String answerSheetQaStatsSuffix;
}

class MarkdownExporter {
  const MarkdownExporter(this.database, this.paths);
  final AppDatabase database;
  final AppPaths paths;
  static const _omrLayout = OmrIdentity.layout;
  static const _answerSheetGroupSize = 20;

  /// 题目内容排版标记处理：跟随设置 `render_question_markup`（默认渲染为换行等
  /// 语义）；关闭时导出保持历史行为（原样输出标记）。
  bool get _renderMarkup =>
      database.getSetting<bool>('render_question_markup') ?? true;
  String _text(String value) =>
      _renderMarkup ? renderMarkupText(value) : value;

  /// Writes only the OMR geometry contract used during recognition.
  /// Unlike [exportPaper], this does not create a user-visible export bundle.
  File writeOmrTemplate(
    PaperAttempt attempt,
    Directory directory, {
    ExportLabels labels = const ExportLabels(),
  }) {
    final file = File(p.join(directory.path, 'omr-template.json'));
    _write(
      file,
      const JsonEncoder.withIndent(' ').convert(_omrTemplate(attempt)),
    );
    return file;
  }

  Directory exportPaper(
    PaperAttempt attempt, {
    bool blankPaper = true,
    bool answerSheet = true,
    bool? answers,
    bool? review,
    bool paperA3 = false,
    ExportLabels labels = const ExportLabels(),
  }) {
    final submitted = attempt.status == AttemptStatus.submitted;
    final includeAnswers = answers ?? submitted;
    final includeReview = review ?? submitted;
    if (!blankPaper && !answerSheet && !includeAnswers && !includeReview) {
      throw const FormatException('请至少选择一种 Markdown 文件');
    }
    if (!submitted && (includeAnswers || includeReview)) {
      throw StateError('试卷交卷前不能导出答案、解析或作答回顾');
    }
    final choiceStates = attempt.questions
        .where((state) => state.question.type != QuestionType.qa)
        .toList(growable: false);
    if (answerSheet && choiceStates.isEmpty) {
      throw const CodedFormatException(
        'export.sheetNeedsChoice',
        '答题卡需要至少一道单选或多选题',
      );
    }
    if (answerSheet &&
        (attempt.questions.isEmpty || attempt.questions.length > 100)) {
      throw const FormatException('纸质答题卡仅支持 1—100 题');
    }
    final stamp = DateTime.now().toLocal().toIso8601String().substring(0, 10);
    final safeTitle = _safe(attempt.title);
    final directory = _createUniqueDirectory(
      p.join(
        paths.exports.path,
        '${stamp}_${safeTitle}_${attempt.paperId.substring(0, 8)}',
      ),
    );
    final resources = Directory(
      p.join(directory.path, labels.resourcesFolderName),
    )..createSync(recursive: true);
    final mediaLinks = blankPaper || includeAnswers || includeReview
        ? _copyQuestionMedia(resources, attempt, labels)
        : <String, List<String?>>{};
    final markdownFiles = <String>[];
    String? answerSheetFile;
    if (blankPaper) {
      _write(
        File(p.join(directory.path, '${labels.paperFileName}.md')),
        _paperMarkdown(
          attempt,
          showAnswers: false,
          mediaLinks: mediaLinks,
          labels: labels,
          paperA3: paperA3,
        ),
      );
      markdownFiles.add('${labels.paperFileName}.md');
    }
    if (includeAnswers) {
      _write(
        File(p.join(directory.path, '${labels.answersFileName}.md')),
        _paperMarkdown(
          attempt,
          showAnswers: true,
          mediaLinks: mediaLinks,
          labels: labels,
          paperA3: paperA3,
        ),
      );
      markdownFiles.add('${labels.answersFileName}.md');
    }
    if (includeReview) {
      _write(
        File(p.join(directory.path, '${labels.reviewFileName}.md')),
        _reviewMarkdown(attempt, mediaLinks: mediaLinks, labels: labels),
      );
      markdownFiles.add('${labels.reviewFileName}.md');
    }
    Map<String, Object?>? omrPayload;
    if (answerSheet) {
      omrPayload = _omrPayload(attempt, labels);
      final qrDataUri = _omrQrDataUri(attempt);
      _write(
        File(p.join(resources.path, 'omr-template.json')),
        const JsonEncoder.withIndent('  ').convert(_omrTemplate(attempt)),
      );
      answerSheetFile = '${labels.answerSheetFileName}.md';
      _write(
        File(p.join(directory.path, answerSheetFile)),
        _answerSheetMarkdown(attempt, omrPayload, qrDataUri, labels),
      );
      markdownFiles.add(answerSheetFile);
    }
    final resourceFiles =
        resources
            .listSync()
            .whereType<File>()
            .map((file) => '${labels.resourcesFolderName}/${p.basename(file.path)}')
            .toList()
          ..sort();
    _write(
      File(p.join(directory.path, 'manifest.json')),
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 1,
        'paper_id': attempt.paperId,
        'attempt_id': attempt.attemptId,
        'title': attempt.title,
        'question_count': attempt.questions.length,
        'question_order': attempt.questions.map((q) => q.question.id).toList(),
        'question_layout': [
          for (var i = 0; i < attempt.questions.length; i++)
            {
              'number': i + 1,
              'question_id': attempt.questions[i].question.id,
              'valid_options': AnswerPolicy.normalize(
                attempt.questions[i].question.options.keys,
              ),
            },
        ],
        'markdown_files': markdownFiles,
        'answer_sheet_file': ?answerSheetFile,
        'paper_layout': paperA3 ? 'a3' : 'a4',
        'resources': resourceFiles,
        if (omrPayload != null)
          'omr': {
            ...omrPayload,
            'paper_id': attempt.paperId,
            'attempt_id': attempt.attemptId,
          },
        'created_at_utc': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    _write(File(p.join(directory.path, 'exam-print.css')), _css);
    return directory;
  }

  File exportWrongQuestions(
    String bankId, {
    ExportLabels labels = const ExportLabels(),
  }) {
    final questions = database.listQuestions(
      bankId: bankId,
      mode: PracticeMode.wrongReview,
    );
    return exportQuestionCollection(
      labels.wrongQuestionsTitle,
      questions,
      labels: labels,
    );
  }

  File exportQuestionCollection(
    String title,
    List<Question> questions, {
    ExportLabels labels = const ExportLabels(),
  }) {
    final stamp = DateTime.now().toLocal().toIso8601String().substring(0, 10);
    final file = File(
      p.join(paths.exports.path, '${stamp}_${_safe(title)}.md'),
    );
    final out = StringBuffer()
      ..writeln('---')
      ..writeln('title: $title')
      ..writeln('created_at: ${DateTime.now().toLocal().toIso8601String()}')
      ..writeln('question_count: ${questions.length}')
      ..writeln('---\n')
      ..writeln('# $title\n');
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final progress = database.progress(q.id);
      final history = database.answerHistory(q.id);
      out.writeln(_questionBlock(q, i + 1, labels: labels));
      if (history.isNotEmpty) {
        out.writeln(
          '- ${_format(labels.recentSelectionLine, {
            '{answers}': _answers(
              jsonDecode(history.first['selected_json'] as String) as List,
              labels,
            ),
          })}',
        );
      }
      out
        ..writeln(
          '- ${_format(labels.correctAnswerLine, {
            '{answers}': _answers(q.answers, labels),
          })}',
        )
        ..writeln(
          '- ${_format(labels.explanationLine, {'{explanation}': _text(q.explanation)})}',
        )
        ..writeln(
          '- ${_format(labels.knowledgePointLine, {
            '{knowledgePoint}': q.knowledgePoint,
          })}',
        )
        ..writeln('- ${_format(labels.sourceLine, {'{source}': q.source})}')
        ..writeln(
          '- ${_format(labels.attemptStatsLine, {
            '{seen}': '${progress.seenCount}',
            '{wrong}': '${progress.wrongCount}',
          })}',
        )
        ..writeln(
          '- ${_format(labels.personalNoteLine, {
            '{note}': progress.personalNote.isEmpty
                ? labels.emptyNoteValue
                : progress.personalNote,
          })}\n',
        );
    }
    _write(file, out.toString());
    return file;
  }

  String _paperMarkdown(
    PaperAttempt attempt, {
    required bool showAnswers,
    required Map<String, List<String?>> mediaLinks,
    required ExportLabels labels,
    bool paperA3 = false,
  }) {
    final cssClasses = [
      'exam-print',
      'exam-paper',
      if (paperA3) 'exam-paper-a3',
    ].join(', ');
    final out = StringBuffer()
      ..writeln('---')
      ..writeln(
        'title: ${_yaml('${attempt.title}${showAnswers ? labels.answersYamlSuffix : ''}')}',
      )
      ..writeln('paper_id: ${attempt.paperId}')
      ..writeln('paper_version: 1')
      ..writeln('created_at: ${DateTime.now().toLocal().toIso8601String()}')
      ..writeln('question_count: ${attempt.questions.length}')
      ..writeln('suggested_minutes: ${attempt.suggestedDurationMs ~/ 60000}')
      ..writeln('cssclasses: [$cssClasses]')
      ..writeln('---\n')
      ..writeln(
        '# ${attempt.title}${showAnswers ? labels.answersHeadingSuffix : ''}\n',
      )
      ..writeln(
        '> ${_format(labels.paperStatsLine, {
          '{count}': '${attempt.questions.length}',
          '{minutes}': '${attempt.suggestedDurationMs ~/ 60000}',
        })}\n',
      );
    for (var i = 0; i < attempt.questions.length; i++) {
      final q = attempt.questions[i].question;
      out.writeln(
        _questionBlock(
          q,
          i + 1,
          mediaLinks: mediaLinks[q.id],
          labels: labels,
          // 空白卷为问答题留手写作答区；答案卷给出参考答案。
          qaAnswerSpace: !showAnswers,
          qaReferenceAnswer: showAnswers,
        ),
      );
      if (showAnswers && q.type != QuestionType.qa) {
        out
          ..writeln(
            _format(labels.correctAnswersBoldLine, {
              '{answers}': _answers(q.answers, labels),
            }),
          )
          ..writeln('')
          ..writeln(
            _format(labels.explanationLine, {'{explanation}': _text(q.explanation)}),
          )
          ..writeln('')
          ..writeln(
            _format(labels.knowledgePointSourceLine, {
              '{knowledgePoint}': q.knowledgePoint,
              '{source}': q.source,
            }),
          )
          ..writeln('');
      }
    }
    return out.toString();
  }

  String _reviewMarkdown(
    PaperAttempt attempt, {
    required Map<String, List<String?>> mediaLinks,
    required ExportLabels labels,
  }) {
    final out = StringBuffer()
      ..writeln('---')
      ..writeln('title: ${_yaml('${attempt.title}${labels.reviewYamlSuffix}')}')
      ..writeln('paper_id: ${attempt.paperId}')
      ..writeln('attempt_id: ${attempt.attemptId}')
      ..writeln('created_at: ${DateTime.now().toLocal().toIso8601String()}')
      ..writeln('---\n')
      ..writeln('# ${attempt.title}${labels.reviewHeadingSuffix}\n')
      ..writeln(
        '- ${_format(labels.reviewScoreLine, {
          '{score}': _number(attempt.score ?? 0),
          '{max}': _number(attempt.maxScore ?? 0),
        })}',
      )
      ..writeln(
        '- ${_format(labels.totalDurationLine, {
          '{duration}': _duration(attempt.durationMs),
        })}',
      )
      ..writeln(
        '- ${_format(labels.overtimeLine, {
          '{duration}': _duration(attempt.overtimeMs),
        })}',
      )
      ..writeln(
        '- ${_format(labels.unansweredCountLine, {
          '{count}': '${attempt.unansweredCount}',
        })}\n',
      );
    for (var i = 0; i < attempt.questions.length; i++) {
      final state = attempt.questions[i];
      final question = state.question;
      final progress = database.progress(question.id);
      if (question.type == QuestionType.qa) {
        // 问答题不判分：回顾只展示作答原文与参考答案。
        final userText = state.textAnswer?.trim() ?? '';
        final reference = question.answers.join('\n').trim();
        out
          ..writeln(
            _questionBlock(question, i + 1, mediaLinks: mediaLinks[question.id], labels: labels),
          )
          ..writeln(
            '- ${_format(labels.qaUserAnswerLine, {
              '{answer}': userText.isEmpty ? labels.qaUnansweredText : userText,
            })}',
          )
          ..writeln(
            '- ${_format(labels.qaReferenceAnswerLine, {
              '{answer}': reference.isEmpty
                  ? labels.qaEmptyReferenceAnswer
                  : reference,
            })}',
          )
          ..writeln(
            '- ${_format(labels.questionDurationLine, {
              '{duration}': _duration(state.durationMs),
            })}',
          )
          ..writeln(
            '- ${_format(labels.favoriteUncertainLine, {
              '{favorite}': progress.isFavorite ? labels.yesLabel : labels.noLabel,
              '{uncertain}': state.uncertain ? labels.yesLabel : labels.noLabel,
            })}',
          )
          ..writeln(
            '- ${_format(labels.personalNoteLine, {
              '{note}': progress.personalNote.isEmpty
                  ? labels.emptyNoteValue
                  : progress.personalNote,
            })}\n',
          );
        continue;
      }
      final result = AnswerPolicy.score(state.question, state.selected);
      final status = !result.isAnswered
          ? labels.unansweredStatus
          : result.isCompletelyCorrect
          ? labels.fullyCorrectStatus
          : labels.wrongStatus;
      out
        ..writeln(
          _questionBlock(
            state.question,
            i + 1,
            mediaLinks: mediaLinks[state.question.id],
            labels: labels,
          ),
        )
        ..writeln('- ${_format(labels.verdictLine, {'{status}': status})}')
        ..writeln(
          '- ${_format(labels.userSelectionLine, {
            '{answers}': _answers(state.selected, labels),
          })}',
        )
        ..writeln(
          '- ${_format(labels.correctAnswerLine, {
            '{answers}': _answers(state.question.answers, labels),
          })}',
        )
        ..writeln(
          '- ${_format(labels.reviewScoreLine, {
            '{score}': _number(result.score),
            '{max}': _number(result.maxScore),
          })}',
        )
        ..writeln(
          '- ${_format(labels.questionDurationLine, {
            '{duration}': _duration(state.durationMs),
          })}',
        )
        ..writeln(
          '- ${_format(labels.favoriteUncertainLine, {
            '{favorite}': progress.isFavorite ? labels.yesLabel : labels.noLabel,
            '{uncertain}': state.uncertain ? labels.yesLabel : labels.noLabel,
          })}',
        )
        ..writeln(
          '- ${_format(labels.personalNoteLine, {
            '{note}': progress.personalNote.isEmpty
                ? labels.emptyNoteValue
                : progress.personalNote,
          })}',
        )
        ..writeln(
          '- ${_format(labels.explanationLine, {
            '{explanation}': _text(state.question.explanation),
          })}',
        )
        ..writeln(
          '- ${_format(labels.knowledgePointSourceReviewLine, {
            '{knowledgePoint}': state.question.knowledgePoint,
            '{source}': state.question.source,
          })}\n',
        );
    }
    return out.toString();
  }

  String _answerSheetMarkdown(
    PaperAttempt attempt,
    Map<String, Object?> omrPayload,
    String qrDataUri,
    ExportLabels labels,
  ) {
    // 答题卡只给选择题（单选/多选）提供气泡；问答题在下方留手写作答区。
    // 气泡行按选择题顺序压缩编号（q1..qM），行首显示试卷题号，
    // 识别结果由 Dart 侧按压缩顺序映射回试卷题位。
    final choiceStates = attempt.questions
        .where((state) => state.question.type != QuestionType.qa)
        .toList(growable: false);
    final qaStates = attempt.questions
        .where((state) => state.question.type == QuestionType.qa)
        .toList(growable: false);
    final choiceCount = choiceStates.length;
    final groups =
        (choiceCount + _answerSheetGroupSize - 1) ~/ _answerSheetGroupSize;
    final qaCount = qaStates.length;
    final statsBase = _format(labels.answerSheetStatsLine, {
      '{count}': '${attempt.questions.length}',
      '{single}': '${attempt.questions.where((s) => s.question.type == QuestionType.single).length}',
      '{multiple}': '${attempt.questions.where((s) => s.question.type == QuestionType.multiple).length}',
    });
    final statsLine = qaCount > 0
        ? statsBase + _format(labels.answerSheetQaStatsSuffix, {'{qa}': '$qaCount'})
        : statsBase;
    final out = StringBuffer()
      ..writeln('---')
      ..writeln(
        'title: ${_yaml('${attempt.title}${labels.answerSheetYamlSuffix}')}',
      )
      ..writeln('paper_id: ${attempt.paperId}')
      ..writeln('paper_version: 1')
      ..writeln('layout: $_omrLayout')
      ..writeln('question_count: ${attempt.questions.length}')
      ..writeln(
        'cssclasses: [exam-print, exam-answer-sheet, omr-groups-$groups]',
      )
      ..writeln('---\n')
      ..writeln(
        '<div class="omr-marker omr-marker-tl"></div>\n'
        '<div class="omr-marker omr-marker-tr"></div>\n'
        '<div class="omr-marker omr-marker-bl"></div>\n'
        '<div class="omr-marker omr-marker-br"></div>\n',
      )
      ..writeln(
        '<div class="omr-heading"><div class="omr-heading-copy"><h1>${htmlEscape.convert(attempt.title)}${labels.answerSheetHeadingSuffix}</h1>'
        '<p>$statsLine</p></div>'
        '<img class="omr-qr" alt="${labels.answerSheetQrAlt}" src="$qrDataUri"></div>\n',
      )
      ..writeln('<div class="omr-fill-note">${labels.fillNoteHtml}</div>\n')
      ..writeln(
        '<div class="omr-section-title">${labels.answerSectionTitle}　'
        '<span>${labels.answerSectionHint}</span></div>\n',
      );
    out.writeln('<div class="omr-grid">');
    for (var group = 0; group < groups; group++) {
      out.writeln('<div class="omr-group">');
      out.writeln(
        '<div class="omr-head"><span>${labels.questionNumberHeader}</span><span>A</span><span>B</span><span>C</span><span>D</span><span>E</span></div>',
      );
      for (var row = 0; row < _answerSheetGroupSize; row++) {
        final choiceIndex = group * _answerSheetGroupSize + row;
        if (choiceIndex >= choiceCount) break;
        // 行首显示试卷题号（attempt 中的位置），几何标签按压缩顺序编号。
        final paperNumber =
            attempt.questions.indexOf(choiceStates[choiceIndex]) + 1;
        out.writeln(
          '<div class="omr-row" data-omr-label="q${choiceIndex + 1}"><span class="omr-number">$paperNumber</span><span class="omr-bubble">A</span><span class="omr-bubble">B</span><span class="omr-bubble">C</span><span class="omr-bubble">D</span><span class="omr-bubble">E</span></div>',
        );
      }
      out.writeln('</div>');
    }
    out.writeln('</div>');
    if (qaStates.isNotEmpty) {
      final gridHeightMm =
          (choiceCount < _answerSheetGroupSize
              ? choiceCount
              : _answerSheetGroupSize) *
          OmrIdentity.rowHeightMm;
      final qaTopMm = OmrIdentity.tableTopMm + gridHeightMm + 10.0;
      final boxHeightMm = 24.0;
      final availableMm = 270.0 - qaTopMm - 4.0;
      final renderCount = qaCount == 0
          ? 0
          : (availableMm ~/ boxHeightMm).clamp(0, qaCount);
      out.writeln(
        '<div class="omr-qa-section" style="top:${qaTopMm}mm;">'
        '<div class="omr-qa-title">${labels.answerSheetQaSectionTitle}</div>',
      );
      for (var i = 0; i < renderCount; i++) {
        final paperNumber = attempt.questions.indexOf(qaStates[i]) + 1;
        out.writeln(
          '<div class="omr-qa-item"><div class="omr-qa-item-label">'
          '${_format(labels.answerSheetQaItemLabel, {'{number}': '$paperNumber'})}'
          '</div><div class="omr-qa-lines"></div></div>',
        );
      }
      if (renderCount < qaCount) {
        out.writeln(
          '<div class="omr-qa-overflow">${labels.answerSheetQaOverflowNote}</div>',
        );
      }
      out.writeln('</div>');
    }
    return out.toString();
  }

  String _questionBlock(
    Question q,
    int number, {
    required ExportLabels labels,
    List<String?>? mediaLinks,
    bool qaAnswerSpace = false,
    bool qaReferenceAnswer = false,
  }) {
    final tag = switch (q.type) {
      QuestionType.multiple => labels.multipleChoiceTag,
      QuestionType.single => labels.singleChoiceTag,
      QuestionType.qa => labels.qaTag,
    };
    final out = StringBuffer()
      ..writeln('## $number. $tag ${_text(q.stem)}\n');
    if (q.type != QuestionType.qa) {
      for (final key in AnswerPolicy.normalize(q.options.keys)) {
        out.writeln('$key. ${_text(q.options[key] ?? '')}');
      }
    }
    for (var i = 0; i < q.media.length; i++) {
      final link = mediaLinks != null && i < mediaLinks.length
          ? mediaLinks[i]
          : null;
      if (link == null) {
        out.writeln(
          '\n${_format(labels.missingMediaWarning, {'{path}': q.media[i]})}',
        );
      } else {
        out.writeln('\n![[${link.replaceAll('\\', '/')}]]');
      }
    }
    if (q.type == QuestionType.qa) {
      if (qaAnswerSpace) {
        // 空白卷：问答题下方留手写作答区（打印 CSS 渲染为多条横线）。
        out.writeln('\n<div class="exam-qa-space"></div>');
      }
      if (qaReferenceAnswer) {
        final reference = q.answers.join('\n').trim();
        out
          ..writeln('')
          ..writeln(
            _format(labels.qaReferenceAnswerLine, {
              '{answer}': reference.isEmpty
                  ? labels.qaEmptyReferenceAnswer
                  : reference,
            }),
          );
      }
    }
    out.writeln('');
    return out.toString();
  }

  Map<String, List<String?>> _copyQuestionMedia(
    Directory resources,
    PaperAttempt attempt,
    ExportLabels labels,
  ) {
    final result = <String, List<String?>>{};
    for (
      var questionIndex = 0;
      questionIndex < attempt.questions.length;
      questionIndex++
    ) {
      final question = attempt.questions[questionIndex].question;
      final links = <String?>[];
      for (
        var mediaIndex = 0;
        mediaIndex < question.media.length;
        mediaIndex++
      ) {
        final original = question.media[mediaIndex];
        final source = File(
          p.join(
            paths.media.path,
            question.bankId,
            'v${question.contentVersion}',
            p.basename(original.replaceAll('\\', '/')),
          ),
        );
        if (!source.existsSync()) {
          links.add(null);
          continue;
        }
        final extension = p.extension(source.path).toLowerCase();
        final targetName =
            'question-media-${(questionIndex + 1).toString().padLeft(3, '0')}'
            '-${(mediaIndex + 1).toString().padLeft(2, '0')}'
            '${extension.isEmpty ? '.bin' : extension}';
        source.copySync(p.join(resources.path, targetName));
        links.add('${labels.resourcesFolderName}/$targetName');
      }
      result[question.id] = links;
    }
    return result;
  }

  Map<String, Object?> _omrPayload(
    PaperAttempt attempt,
    ExportLabels labels,
  ) {
    // 气泡只覆盖选择题，标签按压缩顺序 q1..qM；映射回试卷题位由 Dart 侧完成。
    final choiceCount = attempt.questions
        .where((state) => state.question.type != QuestionType.qa)
        .length;
    return <String, Object?>{
      'engine': 'paper-omr',
      'layout': _omrLayout,
      'template': '${labels.resourcesFolderName}/omr-template.json',
      'question_count': attempt.questions.length,
      'choice_count': choiceCount,
      'labels': List<String>.generate(choiceCount, (index) => 'q${index + 1}'),
    };
  }

  /// 答题卡二维码用于校验题库版本与题目顺序（a4-omr-v4）。
  String _omrQrDataUri(PaperAttempt attempt) {
    final bank = database.bankSummary(attempt.bankId);
    if (bank == null) {
      throw StateError('答题卡二维码生成失败：题库 ${attempt.bankId} 不存在');
    }
    final payload = OmrIdentity.forAttempt(
      attempt,
      catalogVersion: bank.contentVersion,
      questionPositions: database.omrQuestionPositions(
        attempt.bankId,
        attempt.questions.map((state) => state.question.id),
      ),
    );
    final qr = QrImage(
      QrCode(
        payload: QrPayload.fromString(jsonEncode(payload.toJson())),
        errorCorrectLevel: QrErrorCorrectLevel.medium,
      ),
    );
    const module = 6;
    const quiet = 4;
    final size = (qr.moduleCount + quiet * 2) * module;
    final image = img.Image(width: size, height: size)
      ..clear(img.ColorRgb8(255, 255, 255));
    for (var row = 0; row < qr.moduleCount; row++) {
      for (var column = 0; column < qr.moduleCount; column++) {
        if (!qr.isDark(row, column)) continue;
        img.fillRect(
          image,
          x1: (column + quiet) * module,
          y1: (row + quiet) * module,
          x2: (column + quiet + 1) * module - 1,
          y2: (row + quiet + 1) * module - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
    return 'data:image/png;base64,${base64Encode(img.encodePng(image))}';
  }

  Map<String, Object?> _omrTemplate(PaperAttempt attempt) {
    // 气泡行只覆盖选择题并压缩编号：q1..qM（M = 选择题数）。
    final choiceCount = attempt.questions
        .where((state) => state.question.type != QuestionType.qa)
        .length;
    final groups =
        (choiceCount + _answerSheetGroupSize - 1) ~/ _answerSheetGroupSize;
    final gridWidthMm = OmrIdentity.tableWidthMm(groups);
    final groupWidthMm = OmrIdentity.groupWidthMm(groups);
    final numberColumnWidthMm = OmrIdentity.numberColumnWidthMm;
    final bubbleStep = ((groupWidthMm - numberColumnWidthMm) / 5.0 * 10)
        .round();
    // 表头行（题号 + A–E）占第一行，首个数据行气泡中心在 tableTop + 1.5*rowHeight。
    final firstBubbleY =
        ((9.0 + OmrIdentity.tableTopMm + OmrIdentity.rowHeightMm * 1.5) * 10)
            .round();
    final gridLeftMm = 9.0 + (192.0 - gridWidthMm) / 2;
    final fieldBlocks = <String, Object?>{};
    for (var group = 0; group < groups; group++) {
      final first = group * _answerSheetGroupSize + 1;
      final last = (first + _answerSheetGroupSize - 1).clamp(
        1,
        choiceCount,
      );
      final firstBubbleX =
          ((gridLeftMm +
                      group * groupWidthMm +
                      numberColumnWidthMm +
                      ((groupWidthMm - numberColumnWidthMm) / 5.0 - 4.0) / 2) *
                  10)
              .round();
      fieldBlocks['answers_${group + 1}'] = <String, Object?>{
        'fieldType': 'QTYPE_MCQ5',
        'fieldLabels': ['q$first..$last'],
        'bubblesGap': bubbleStep,
        'labelsGap': 64,
        'origin': [firstBubbleX, firstBubbleY],
      };
    }
    return <String, Object?>{
      'pageDimensions': [OmrIdentity.pageWidth, OmrIdentity.pageHeight],
      'bubbleDimensions': [40, 40],
      'outputColumns': ['q1..$choiceCount'],
      'fieldBlocks': fieldBlocks,
      'preProcessors': [
        {
          'name': 'CropPage',
          'options': {
            'morphKernel': [10, 10],
          },
        },
      ],
      // 这是 Windows bridge 的版本化输入契约；模板只保留 bridge 需要的字段。
      'personal_exam_geometry': {
        'schema_version': 1,
        'layout': OmrIdentity.layout,
        'marker_centers': OmrIdentity.markerCenters,
      },
    };
  }

  static void _write(File file, String content) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content, encoding: utf8, flush: true);
  }

  static String _answers(Iterable values, ExportLabels labels) {
    final list = values.map((e) => e.toString()).toList();
    return list.isEmpty
        ? labels.unansweredStatus
        : AnswerPolicy.normalize(list).join(labels.answerSeparator);
  }

  /// 单次线性替换 `{token}` 占位符；值中的 `{` 不会被再次展开。
  static String _format(String template, Map<String, String> values) {
    if (!template.contains('{')) return template;
    final out = StringBuffer();
    for (var i = 0; i < template.length; i++) {
      if (template.codeUnitAt(i) == 0x7B /* { */) {
        final close = template.indexOf('}', i);
        if (close > i) {
          final value = values[template.substring(i, close + 1)];
          if (value != null) {
            out.write(value);
            i = close;
            continue;
          }
        }
      }
      out.write(template[i]);
    }
    return out.toString();
  }

  static String _duration(int ms) =>
      Duration(milliseconds: ms).toString().split('.').first.padLeft(8, '0');
  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  static Directory _createUniqueDirectory(String basePath) {
    var candidate = Directory(basePath);
    var sequence = 2;
    while (candidate.existsSync()) {
      candidate = Directory(
        '${basePath}_${sequence.toString().padLeft(2, '0')}',
      );
      sequence++;
    }
    return candidate..createSync(recursive: true);
  }

  static String _yaml(String value) => jsonEncode(value);
  static String _safe(String value) =>
      value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

  static const _css = '''
@media print {
  @page { size: A4 portrait; margin: 9mm; }
  @page a3paper { size: A3 landscape; margin: 12mm; }
  .exam-paper-a3 { page: a3paper; column-count: 2; column-gap: 10mm; }
  .exam-paper-a3 h1 { column-span: all; }
  .exam-print { font-size: 10.5pt; line-height: 1.45; }
  .exam-paper h2 { break-after: avoid; }
  .exam-paper h2 + p { break-before: avoid; }
  .exam-answer-sheet { font-size: 8.5pt; line-height: 1.15; }
  .exam-answer-sheet {
    position: relative;
    box-sizing: border-box;
    height: 270mm;
    overflow: hidden;
  }
  .exam-answer-sheet h1 { margin: 0 0 1.5mm; font-size: 15pt; }
  .exam-answer-sheet .omr-grid {
    position: absolute;
    top: 56mm;
    left: 50%;
    transform: translateX(-50%);
  }
}
/* 问答题手写作答区：空白卷每题下方若干横线。 */
.exam-qa-space {
  height: 24mm;
  margin: 1mm 0 0 7mm;
  background: repeating-linear-gradient(
    to bottom,
    transparent 0,
    transparent calc(8mm - 0.25mm),
    #bbb calc(8mm - 0.25mm),
    #bbb 8mm
  );
}
/* 答题卡问答题区：定位由行内 style 给出（气泡表高度随题量变化）。 */
.exam-answer-sheet .omr-qa-section {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  width: 180mm;
}
.exam-answer-sheet .omr-qa-title {
  box-sizing: border-box;
  height: 7mm;
  padding: 1.5mm 2mm;
  border: 0.35mm solid #333;
  font-weight: 700;
  font-size: 8.5pt;
}
.exam-answer-sheet .omr-qa-item {
  box-sizing: border-box;
  height: 24mm;
  border: 0.35mm solid #333;
  border-top: 0;
}
.exam-answer-sheet .omr-qa-item-label {
  height: 6mm;
  padding: 1mm 2mm;
  font: 700 8pt/1 Arial, sans-serif;
  border-bottom: 0.25mm solid #999;
}
.exam-answer-sheet .omr-qa-lines {
  height: 18mm;
  margin: 0 2mm;
  background: repeating-linear-gradient(
    to bottom,
    transparent 0,
    transparent calc(6mm - 0.25mm),
    #bbb calc(6mm - 0.25mm),
    #bbb 6mm
  );
}
.exam-answer-sheet .omr-qa-overflow {
  padding: 1.5mm 2mm;
  font-size: 7.5pt;
  color: #333;
}
/* 四角定位点：规格与 omr_identity（a4-omr-v4 版式）一致——外框 9.92mm、
   白色内框 2.24mm、黑色中心 2.56mm，中心位于内容框
   (6, 6.5) / (186, 6.5) / (6, 263.5) / (186, 263.5) mm。 */
.exam-answer-sheet .omr-marker {
  position: absolute;
  width: 9.92mm;
  height: 9.92mm;
  background: #000;
}
.exam-answer-sheet .omr-marker::before {
  content: '';
  position: absolute;
  inset: 2.24mm;
  background: #fff;
}
.exam-answer-sheet .omr-marker::after {
  content: '';
  position: absolute;
  left: calc(50% - 1.28mm);
  top: calc(50% - 1.28mm);
  width: 2.56mm;
  height: 2.56mm;
  background: #000;
}
.exam-answer-sheet .omr-marker-tl { left: 1.04mm; top: 1.54mm; }
.exam-answer-sheet .omr-marker-tr { left: 181.04mm; top: 1.54mm; }
.exam-answer-sheet .omr-marker-bl { left: 1.04mm; top: 258.54mm; }
.exam-answer-sheet .omr-marker-br { left: 181.04mm; top: 258.54mm; }
.exam-answer-sheet .omr-heading {
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  box-sizing: border-box;
  height: 21mm;
  border-bottom: 0.35mm solid #333;
}
.exam-answer-sheet .omr-heading-copy { text-align: center; }
.exam-answer-sheet .omr-heading-copy p { margin: 0; font-size: 8pt; }
.exam-answer-sheet .omr-qr {
  position: absolute;
  top: 1.5mm;
  right: 12mm;
  width: 18mm;
  height: 18mm;
  image-rendering: pixelated;
}
.exam-answer-sheet .omr-fill-note {
  box-sizing: border-box;
  height: 8mm;
  padding: 1.4mm 2mm;
  border: 0.25mm solid #555;
  border-top: 0;
  font-size: 7.5pt;
}
.exam-answer-sheet .omr-section-title {
  box-sizing: border-box;
  height: 7mm;
  padding: 1.5mm 2mm;
  border: 0.35mm solid #333;
  border-top: 0;
  font-weight: 700;
}
.exam-answer-sheet .omr-section-title span {
  margin-left: 3mm;
  font-size: 7.5pt;
  font-weight: 400;
}
.exam-answer-sheet .omr-bubble {
  display: inline-block;
  box-sizing: border-box;
  width: 4mm;
  height: 4mm;
  border: 0.3mm solid #111;
  border-radius: 50%;
  vertical-align: middle;
}
.exam-answer-sheet .omr-grid {
  display: grid;
  grid-template-columns: repeat(var(--omr-groups, 1), 1fr);
  gap: 0;
  margin: 0 auto;
  border: 0.35mm solid #333;
}
.exam-answer-sheet.omr-groups-1 .omr-grid { width: 50mm; --omr-groups: 1; }
.exam-answer-sheet.omr-groups-2 .omr-grid { width: 100mm; --omr-groups: 2; }
.exam-answer-sheet.omr-groups-3 .omr-grid { width: 150mm; --omr-groups: 3; }
.exam-answer-sheet.omr-groups-4 .omr-grid { width: 180mm; --omr-groups: 4; }
.exam-answer-sheet.omr-groups-5 .omr-grid { width: 180mm; --omr-groups: 5; }
.exam-answer-sheet .omr-group { min-width: 0; }
.exam-answer-sheet .omr-head {
  display: grid;
  grid-template-columns: 8mm repeat(5, 1fr);
  align-items: center;
  height: 6.4mm;
  border-bottom: 0.2mm solid #222;
  border-right: 0.2mm solid #222;
  box-sizing: border-box;
  background: #f0f0f0;
  font: 700 7.5pt/1 Arial, sans-serif;
  text-align: center;
}
.exam-answer-sheet .omr-row {
  display: grid;
  grid-template-columns: 8mm repeat(5, 1fr);
  align-items: center;
  height: 6.4mm;
  border-bottom: 0.2mm solid #222;
  border-right: 0.2mm solid #222;
  box-sizing: border-box;
  font: 7.5pt/1 Arial, sans-serif;
  text-align: center;
}
.exam-answer-sheet .omr-number { font-weight: 700; }
.exam-answer-sheet .omr-row .omr-bubble {
  justify-self: center;
  color: transparent;
  font-size: 0;
}
''';
}
