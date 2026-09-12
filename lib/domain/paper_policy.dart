import 'dart:math';

import 'models.dart';
import 'policies.dart';

/// The composition profile for a paper attempt. Practice sessions deliberately
/// do not use this profile and continue to use each question's scoring rule.
enum PaperCompositionMode { singleOnly, multipleOnly, realExam }

/// 试卷判分策略（随卷快照持久化）。v2 起参数可自定义：
/// 单选/多选分值、少选部分分开关与每正确项分值、错项是否整题零分。
/// 问答题一律不判分（maxScore 0，不产生作答事件）。
/// 旧版本快照（uniform_exam_v1 或缺字段）反序列化后与本类默认值完全一致，
/// 历史试卷显示与得分不受影响。
class PaperScoringPolicy {
  const PaperScoringPolicy({
    this.singleScore = 1,
    this.multipleScore = 2,
    this.partialCredit = true,
    this.partialPerCorrectOption = 0.5,
    this.wrongOptionMakesZero = true,
  });

  static const String kind = 'uniform_exam_v2';

  final double singleScore;
  final double multipleScore;

  /// 多选题少选且无错选时是否给部分分。
  final bool partialCredit;
  final double partialPerCorrectOption;

  /// 多选题出现错项时是否整题零分（关闭时错项也按部分分计）。
  final bool wrongOptionMakesZero;

  PaperScoringPolicy copyWith({
    double? singleScore,
    double? multipleScore,
    bool? partialCredit,
    double? partialPerCorrectOption,
    bool? wrongOptionMakesZero,
  }) => PaperScoringPolicy(
    singleScore: singleScore ?? this.singleScore,
    multipleScore: multipleScore ?? this.multipleScore,
    partialCredit: partialCredit ?? this.partialCredit,
    partialPerCorrectOption:
        partialPerCorrectOption ?? this.partialPerCorrectOption,
    wrongOptionMakesZero: wrongOptionMakesZero ?? this.wrongOptionMakesZero,
  );

  double maxScore(QuestionType type) => switch (type) {
    QuestionType.single => singleScore,
    QuestionType.multiple => multipleScore,
    QuestionType.qa => 0,
  };

  ScoreResult score(Question question, Iterable<String> selected) {
    final questionMax = maxScore(question.type);
    if (question.type == QuestionType.qa) {
      // 问答题不判分：作答文本原样保存在 selected 中，得分恒为 0。
      return ScoreResult(
        isAnswered: selected.isNotEmpty,
        isCompletelyCorrect: false,
        score: 0,
        maxScore: 0,
      );
    }
    final chosen = AnswerPolicy.normalize(selected);
    final correct = AnswerPolicy.normalize(question.answers);
    if (chosen.isEmpty) {
      return ScoreResult(
        isAnswered: false,
        isCompletelyCorrect: false,
        score: 0,
        maxScore: questionMax,
      );
    }
    if (!AnswerPolicy.validSelection(question, chosen)) {
      throw const FormatException('试卷作答不符合题型或选项范围');
    }
    final exact =
        chosen.length == correct.length &&
        chosen.asMap().entries.every(
          (entry) => correct[entry.key] == entry.value,
        );
    if (exact) {
      return ScoreResult(
        isAnswered: true,
        isCompletelyCorrect: true,
        score: questionMax,
        maxScore: questionMax,
      );
    }
    if (question.type == QuestionType.multiple &&
        partialCredit &&
        (!chosen.any((option) => !correct.contains(option)) ||
            !wrongOptionMakesZero)) {
      return ScoreResult(
        isAnswered: true,
        isCompletelyCorrect: false,
        score: chosen.where(correct.contains).length * partialPerCorrectOption,
        maxScore: questionMax,
      );
    }
    return ScoreResult(
      isAnswered: true,
      isCompletelyCorrect: false,
      score: 0,
      maxScore: questionMax,
    );
  }

  double percentage({required double score, required double maxScore}) =>
      maxScore <= 0 ? 0 : score / maxScore * 100;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': PaperScoringPolicy.kind,
    'single_score': singleScore,
    'multiple_score': multipleScore,
    'partial_credit': partialCredit,
    'partial_per_correct_option': partialPerCorrectOption,
    'wrong_option_makes_zero': wrongOptionMakesZero,
  };

  factory PaperScoringPolicy.fromJson(Map<String, Object?> json) =>
      PaperScoringPolicy(
        singleScore: (json['single_score'] as num?)?.toDouble() ?? 1,
        multipleScore: (json['multiple_score'] as num?)?.toDouble() ?? 2,
        partialCredit: json['partial_credit'] as bool? ?? true,
        partialPerCorrectOption:
            (json['partial_per_correct_option'] as num?)?.toDouble() ?? 0.5,
        wrongOptionMakesZero: json['wrong_option_makes_zero'] as bool? ?? true,
      );
}

class PaperCompositionPolicy {
  const PaperCompositionPolicy._();

  static List<Question> compose(
    Iterable<Question> available, {
    required PaperCompositionMode mode,
    required int total,
    required bool random,
    Random? randomSource,
    PaperTypeCounts? counts,
  }) {
    if (total < 0) throw ArgumentError.value(total, 'total', '不能为负数');
    switch (mode) {
      case PaperCompositionMode.singleOnly:
        return _takeType(
          available,
          type: QuestionType.single,
          total: total,
          random: random,
          randomSource: randomSource,
        );
      case PaperCompositionMode.multipleOnly:
        return _takeType(
          available,
          type: QuestionType.multiple,
          total: total,
          random: random,
          randomSource: randomSource,
        );
      case PaperCompositionMode.realExam:
        return composeRealExam(
          available,
          total: total,
          random: random,
          randomSource: randomSource,
          counts: counts,
        );
    }
  }

  static List<Question> _takeType(
    Iterable<Question> available, {
    required QuestionType type,
    required int total,
    required bool random,
    Random? randomSource,
  }) {
    final matching = available
        .where((question) => question.type == type)
        .toList();
    if (random) matching.shuffle(randomSource);
    return matching.take(total).toList(growable: false);
  }

  static int multipleQuota(int total) {
    if (total < 0) throw ArgumentError.value(total, 'total', '不能为负数');
    return (total * 3 / 17).round();
  }

  /// 考试模式组卷。未提供 [counts] 时沿用历史固定比例 14:3（不含问答题）；
  /// 提供 [counts] 时按各题型绝对题数取题，不足则取现有全部。
  /// 题目顺序固定为：单选在前、多选随后、问答题最后。
  static List<Question> composeRealExam(
    Iterable<Question> available, {
    required int total,
    required bool random,
    Random? randomSource,
    PaperTypeCounts? counts,
  }) {
    if (total < 0) throw ArgumentError.value(total, 'total', '不能为负数');
    final single = <Question>[];
    final multiple = <Question>[];
    final qa = <Question>[];
    for (final question in available) {
      switch (question.type) {
        case QuestionType.single:
          single.add(question);
        case QuestionType.multiple:
          multiple.add(question);
        case QuestionType.qa:
          qa.add(question);
      }
    }
    if (random) {
      single.shuffle(randomSource);
      multiple.shuffle(randomSource);
      qa.shuffle(randomSource);
    }
    final int multipleTarget;
    final int singleTarget;
    final int qaTarget;
    if (counts == null) {
      multipleTarget = multipleQuota(total);
      singleTarget = total - multipleTarget;
      qaTarget = 0;
    } else {
      if (counts.single < 0 || counts.multiple < 0 || counts.qa < 0) {
        throw ArgumentError.value(counts, 'counts', '题型数量不能为负数');
      }
      singleTarget = counts.single;
      multipleTarget = counts.multiple;
      qaTarget = counts.qa;
    }
    return <Question>[
      ...single.take(singleTarget),
      ...multiple.take(multipleTarget),
      ...qa.take(qaTarget),
    ];
  }
}
