import 'dart:convert';

import 'paper_policy.dart';

/// 题型。`qa` 为问答题：无选项、不参与判分与练习统计，
/// 作答文本保存在试卷快照的 `selected` 中（单元素集合，见 PaperQuestionState）。
enum QuestionType { single, multiple, qa }

enum StudyState { unseen, wrong, mastered }

enum PracticeMode { unseen, wrongReview, random, favorite, uncertain }

enum AttemptStatus { draft, submitted, abandoned }

class Question {
  const Question({
    required this.id,
    required this.bankId,
    required this.externalId,
    required this.contentVersion,
    required this.type,
    required this.stem,
    required this.options,
    required this.answers,
    required this.explanation,
    required this.knowledgePoint,
    required this.source,
    required this.year,
    required this.chapter,
    required this.tags,
    required this.media,
    required this.scoringRule,
    required this.isActive,
  });

  final String id;
  final String bankId;
  final String? externalId;
  final int contentVersion;
  final QuestionType type;
  final String stem;
  final Map<String, String> options;
  final List<String> answers;
  final String explanation;
  final String knowledgePoint;
  final String source;
  final String year;
  final String chapter;
  final List<String> tags;
  final List<String> media;
  final ScoringRule scoringRule;
  final bool isActive;

  Map<String, Object?> toSnapshot() => <String, Object?>{
    'question_id': id,
    'bank_id': bankId,
    'external_id': externalId,
    'content_version': contentVersion,
    'type': type.name,
    'stem': stem,
    'options': options,
    'answers': answers,
    'explanation': explanation,
    'knowledge_point': knowledgePoint,
    'source': source,
    'year': year,
    'chapter': chapter,
    'tags': tags,
    'media': media,
    'scoring_rule': scoringRule.toJson(),
    'is_active': isActive,
  };

  factory Question.fromSnapshot(Map<String, Object?> json) => Question(
    id: json['question_id']! as String,
    bankId: json['bank_id']! as String,
    externalId: json['external_id'] as String?,
    contentVersion: (json['content_version'] as num?)?.toInt() ?? 1,
    type: QuestionType.values.byName(json['type']! as String),
    stem: json['stem']! as String,
    options: (json['options']! as Map).map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    ),
    answers: (json['answers']! as List).map((e) => e.toString()).toList(),
    explanation: json['explanation']?.toString() ?? '',
    knowledgePoint: json['knowledge_point']?.toString() ?? '',
    source: json['source']?.toString() ?? '',
    year: json['year']?.toString() ?? '',
    chapter: json['chapter']?.toString() ?? '',
    tags: (json['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
    media: (json['media'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
    scoringRule: ScoringRule.fromJson(
      (json['scoring_rule'] as Map?)?.cast<String, Object?>() ?? const {},
    ),
    isActive: json['is_active'] != false,
  );
}

class ScoringRule {
  const ScoringRule({
    this.singleScore = 1,
    this.multipleScore = 2,
    this.partialCredit = false,
    this.partialPerCorrectOption = 0.5,
    this.wrongOptionMakesZero = true,
    this.unansweredScore = 0,
  });

  final double singleScore;
  final double multipleScore;
  final bool partialCredit;
  final double partialPerCorrectOption;
  final bool wrongOptionMakesZero;
  final double unansweredScore;

  double maxScore(QuestionType type) => switch (type) {
    QuestionType.single => singleScore,
    QuestionType.multiple => multipleScore,
    QuestionType.qa => 0,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'single_score': singleScore,
    'multiple_score': multipleScore,
    'partial_credit': partialCredit,
    'partial_per_correct_option': partialPerCorrectOption,
    'wrong_option_makes_zero': wrongOptionMakesZero,
    'unanswered_score': unansweredScore,
  };

  factory ScoringRule.fromJson(Map<String, Object?> json) => ScoringRule(
    singleScore: (json['single_score'] as num?)?.toDouble() ?? 1,
    multipleScore: (json['multiple_score'] as num?)?.toDouble() ?? 2,
    partialCredit: json['partial_credit'] as bool? ?? false,
    partialPerCorrectOption:
        (json['partial_per_correct_option'] as num?)?.toDouble() ?? 0.5,
    wrongOptionMakesZero: json['wrong_option_makes_zero'] as bool? ?? true,
    unansweredScore: (json['unanswered_score'] as num?)?.toDouble() ?? 0,
  );
}

class ScoreResult {
  const ScoreResult({
    required this.isAnswered,
    required this.isCompletelyCorrect,
    required this.score,
    required this.maxScore,
  });

  final bool isAnswered;
  final bool isCompletelyCorrect;
  final double score;
  final double maxScore;
}

class QuestionProgress {
  const QuestionProgress({
    required this.questionId,
    this.state = StudyState.unseen,
    this.seenCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.everWrong = false,
    this.totalDurationMs = 0,
    this.isFavorite = false,
    this.isUncertain = false,
    this.isExcluded = false,
    this.personalNote = '',
  });

  final String questionId;
  final StudyState state;
  final int seenCount;
  final int correctCount;
  final int wrongCount;
  final bool everWrong;
  final int totalDurationMs;
  final bool isFavorite;
  final bool isUncertain;
  final bool isExcluded;
  final String personalNote;
}

class AnswerEvent {
  const AnswerEvent({
    required this.eventId,
    required this.deviceId,
    required this.questionId,
    required this.questionVersion,
    required this.sessionId,
    required this.attemptId,
    required this.mode,
    required this.selected,
    required this.correct,
    required this.score,
    required this.durationMs,
    required this.answeredAtUtc,
    required this.source,
    this.schemaVersion = 1,
  });

  final String eventId;
  final String deviceId;
  final String questionId;
  final int questionVersion;
  final String sessionId;
  final String? attemptId;
  final String mode;
  final List<String> selected;
  final bool correct;
  final double score;
  final int durationMs;
  final DateTime answeredAtUtc;
  final String source;
  final int schemaVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'event_id': eventId,
    'device_id': deviceId,
    'question_id': questionId,
    'question_version': questionVersion,
    'session_id': sessionId,
    'attempt_id': attemptId,
    'mode': mode,
    'selected': selected,
    'correct': correct,
    'score': score,
    'duration_ms': durationMs,
    'answered_at_utc': answeredAtUtc.toUtc().toIso8601String(),
    'source': source,
    'schema_version': schemaVersion,
  };

  factory AnswerEvent.fromJson(Map<String, Object?> json) => AnswerEvent(
    eventId: json['event_id']! as String,
    deviceId: json['device_id']! as String,
    questionId: json['question_id']! as String,
    questionVersion: (json['question_version'] as num).toInt(),
    sessionId: json['session_id']! as String,
    attemptId: json['attempt_id'] as String?,
    mode: json['mode']! as String,
    selected: (json['selected'] as List? ?? const [])
        .map((value) => value.toString())
        .toList(growable: false),
    correct: json['correct']! as bool,
    score: (json['score'] as num).toDouble(),
    durationMs: (json['duration_ms'] as num).toInt(),
    answeredAtUtc: DateTime.parse(json['answered_at_utc']! as String).toUtc(),
    source: json['source']! as String,
    schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
  );

  String canonicalJson() => jsonEncode(toJson());
}

class BankSummary {
  const BankSummary({
    required this.id,
    required this.name,
    required this.subject,
    required this.contentVersion,
    required this.questionCount,
  });

  final String id;
  final String name;
  final String subject;
  final int contentVersion;
  final int questionCount;
}

class DashboardStats {
  const DashboardStats({
    this.total = 0,
    this.unseen = 0,
    this.wrong = 0,
    this.mastered = 0,
    this.everWrong = 0,
    this.favorite = 0,
    this.uncertain = 0,
    this.excluded = 0,
    this.pendingSync = 0,
  });

  final int total;
  final int unseen;
  final int wrong;
  final int mastered;
  final int everWrong;
  final int favorite;
  final int uncertain;
  final int excluded;
  final int pendingSync;
}

class PaperQuestionState {
  PaperQuestionState({
    required this.question,
    required this.eventId,
    Set<String>? selected,
    this.uncertain = false,
    this.durationMs = 0,
  }) : selected = selected ?? <String>{};

  final Question question;
  final String eventId;

  /// 选择题：已选选项字母集合；问答题：单元素集合，唯一元素即作答文本
  /// （原样保存，不做 A–E 归一化）。空集合 = 未答。
  final Set<String> selected;
  bool uncertain;
  int durationMs;

  /// 问答题作答文本；非问答题返回 null。
  String? get textAnswer =>
      question.type == QuestionType.qa ? selected.firstOrNull : null;
}

class PaperAttempt {
  PaperAttempt({
    required this.attemptId,
    required this.paperId,
    required this.title,
    required this.bankId,
    required this.status,
    required this.questions,
    required this.startedAtUtc,
    required this.suggestedDurationMs,
    this.compositionMode = PaperCompositionMode.realExam,
    this.scoringPolicy = const PaperScoringPolicy(),
    this.submittedAtUtc,
    this.durationMs = 0,
    this.score,
    this.maxScore,
    this.currentIndex = 0,
  });

  final String attemptId;
  final String paperId;
  final String title;
  final String bankId;
  AttemptStatus status;
  final List<PaperQuestionState> questions;
  final DateTime startedAtUtc;
  final int suggestedDurationMs;
  final PaperCompositionMode compositionMode;
  final PaperScoringPolicy scoringPolicy;
  DateTime? submittedAtUtc;
  int durationMs;
  double? score;
  double? maxScore;
  int currentIndex;

  int get answeredCount => questions.where((q) => q.selected.isNotEmpty).length;
  int get unansweredCount => questions.length - answeredCount;
  int get overtimeMs => suggestedDurationMs <= 0
      ? 0
      : (durationMs - suggestedDurationMs).clamp(0, 1 << 62);

  double? get percentage => score == null || maxScore == null
      ? null
      : scoringPolicy.percentage(score: score!, maxScore: maxScore!);
}

class AttemptSummary {
  const AttemptSummary({
    required this.attemptId,
    required this.title,
    required this.status,
    required this.questionCount,
    required this.startedAtUtc,
    required this.durationMs,
    required this.score,
    required this.maxScore,
  });

  final String attemptId;
  final String title;
  final AttemptStatus status;
  final int questionCount;
  final DateTime startedAtUtc;
  final int durationMs;
  final double? score;
  final double? maxScore;
}

class ImportIssue {
  const ImportIssue(
    this.message, {
    required this.blocking,
    this.code,
    this.params = const [],
  });

  /// 中文技术诊断，保持与迁移前逐字一致；测试与导入报告依赖它。
  final String message;
  final bool blocking;

  /// 用户可见消息的稳定码（如 `import.blocked.dupExternalId`）；
  /// UI 层据此映射本地化文案（见 `lib/ui/error_messages.dart`），无码时回退原文。
  final String? code;

  /// 按位置对应本地化消息占位符的参数；无占位符时为空。
  final List<Object> params;
}

class ImportPreview {
  const ImportPreview({
    required this.packagePath,
    required this.bankId,
    required this.name,
    required this.subject,
    required this.contentVersion,
    required this.questions,
    required this.mediaFiles,
    required this.issues,
  });

  final String packagePath;
  final String bankId;
  final String name;
  final String subject;
  final int contentVersion;
  final List<Question> questions;
  final Map<String, List<int>> mediaFiles;
  final List<ImportIssue> issues;

  bool get canImport => !issues.any((issue) => issue.blocking);
  int get singleCount =>
      questions.where((q) => q.type == QuestionType.single).length;
  int get multipleCount =>
      questions.where((q) => q.type == QuestionType.multiple).length;
  int get qaCount => questions.where((q) => q.type == QuestionType.qa).length;
}

/// 考试模式组卷的题型数量（绝对题数，非比例）。
class PaperTypeCounts {
  const PaperTypeCounts({
    this.single = 14,
    this.multiple = 3,
    this.qa = 0,
  });

  final int single;
  final int multiple;
  final int qa;

  int get total => single + multiple + qa;

  Map<String, Object?> toJson() => <String, Object?>{
    'single': single,
    'multiple': multiple,
    'qa': qa,
  };

  factory PaperTypeCounts.fromJson(Map<String, Object?> json) =>
      PaperTypeCounts(
        single: (json['single'] as num?)?.toInt() ?? 14,
        multiple: (json['multiple'] as num?)?.toInt() ?? 3,
        qa: (json['qa'] as num?)?.toInt() ?? 0,
      );
}
