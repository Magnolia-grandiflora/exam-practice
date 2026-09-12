import 'models.dart';

class AnswerPolicy {
  const AnswerPolicy._();

  static List<String> normalize(Iterable<String> values) {
    final normalized =
        values
            .expand((value) => value.toUpperCase().split(RegExp(r'[^A-E]+')))
            .expand((value) => value.split(''))
            .where((value) => RegExp(r'^[A-E]$').hasMatch(value))
            .toSet()
            .toList()
          ..sort();
    return normalized;
  }

  static bool validSelection(Question question, Iterable<String> selected) {
    if (question.type == QuestionType.qa) {
      // 问答题：作答文本不做 A–E 归一化，非空即有效。
      return selected.any((value) => value.trim().isNotEmpty);
    }
    final normalized = normalize(selected);
    if (question.type == QuestionType.single && normalized.length > 1) {
      return false;
    }
    return normalized.every(question.options.containsKey);
  }

  static ScoreResult score(Question question, Iterable<String> selected) {
    if (question.type == QuestionType.qa) {
      // 问答题不判分：得分恒为 0，不占用总分（maxScore 0）。
      return ScoreResult(
        isAnswered: selected.any((value) => value.trim().isNotEmpty),
        isCompletelyCorrect: false,
        score: 0,
        maxScore: 0,
      );
    }
    final chosen = normalize(selected);
    final correct = normalize(question.answers);
    final maxScore = question.scoringRule.maxScore(question.type);
    if (chosen.isEmpty) {
      return ScoreResult(
        isAnswered: false,
        isCompletelyCorrect: false,
        score: question.scoringRule.unansweredScore,
        maxScore: maxScore,
      );
    }
    if (!validSelection(question, chosen)) {
      throw const FormatException('当前选择不符合题型或选项范围');
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
        score: maxScore,
        maxScore: maxScore,
      );
    }
    if (question.type == QuestionType.multiple &&
        question.scoringRule.partialCredit) {
      final wrong = chosen.any((answer) => !correct.contains(answer));
      if (!wrong || !question.scoringRule.wrongOptionMakesZero) {
        final rightCount = chosen.where(correct.contains).length;
        return ScoreResult(
          isAnswered: true,
          isCompletelyCorrect: false,
          score: (rightCount * question.scoringRule.partialPerCorrectOption)
              .clamp(0, maxScore),
          maxScore: maxScore,
        );
      }
    }
    return ScoreResult(
      isAnswered: true,
      isCompletelyCorrect: false,
      score: 0,
      maxScore: maxScore,
    );
  }
}

class StudyPolicy {
  const StudyPolicy._();

  static StudyState afterAnswer({
    required StudyState before,
    required bool correct,
    required bool randomErrorsReturnToWrong,
    required bool isRandomPractice,
  }) {
    if (correct) return StudyState.mastered;
    if (isRandomPractice && !randomErrorsReturnToWrong) return before;
    return StudyState.wrong;
  }

  static PracticeMode automaticMode({required int unseen, required int wrong}) {
    if (unseen > 0) return PracticeMode.unseen;
    if (wrong > 0) return PracticeMode.wrongReview;
    return PracticeMode.random;
  }
}
