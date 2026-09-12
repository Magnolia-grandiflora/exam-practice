import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/domain/policies.dart';

Question question({
  QuestionType type = QuestionType.multiple,
  ScoringRule rule = const ScoringRule(),
}) => Question(
  id: 'q',
  bankId: 'b',
  externalId: 'Q',
  contentVersion: 1,
  type: type,
  stem: '题干',
  options: const {'A': 'a', 'B': 'b', 'C': 'c', 'D': 'd', 'E': 'e'},
  answers: type == QuestionType.single ? const ['C'] : const ['B', 'D', 'E'],
  explanation: '',
  knowledgePoint: '',
  source: '',
  year: '',
  chapter: '',
  tags: const [],
  media: const [],
  scoringRule: rule,
  isActive: true,
);

void main() {
  test('多选答案去分隔符去重并按 A-E 排序', () {
    expect(AnswerPolicy.normalize(['E D,B', 'D']), ['B', 'D', 'E']);
  });

  test('单选多个选项无效', () {
    expect(
      AnswerPolicy.validSelection(question(type: QuestionType.single), [
        'A',
        'C',
      ]),
      isFalse,
    );
  });

  test('多选必须完全匹配', () {
    expect(
      AnswerPolicy.score(question(), ['E', 'B', 'D']).isCompletelyCorrect,
      isTrue,
    );
    expect(AnswerPolicy.score(question(), ['B', 'D']).score, 0);
    expect(AnswerPolicy.score(question(), ['B', 'D', 'A']).score, 0);
  });

  test('可配置部分分与错选归零', () {
    final q = question(
      rule: const ScoringRule(
        partialCredit: true,
        partialPerCorrectOption: 0.5,
      ),
    );
    expect(AnswerPolicy.score(q, ['B', 'D']).score, 1);
    expect(AnswerPolicy.score(q, ['A', 'B']).score, 0);
  });

  test('默认自动队列先未见后错题', () {
    expect(StudyPolicy.automaticMode(unseen: 2, wrong: 8), PracticeMode.unseen);
    expect(
      StudyPolicy.automaticMode(unseen: 0, wrong: 8),
      PracticeMode.wrongReview,
    );
    expect(StudyPolicy.automaticMode(unseen: 0, wrong: 0), PracticeMode.random);
  });
}
