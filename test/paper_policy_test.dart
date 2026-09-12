import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/domain/models.dart';
import 'package:personal_exam_app/domain/paper_policy.dart';
import 'package:personal_exam_app/domain/policies.dart';

Question question(
  String id,
  QuestionType type, {
  List<String>? answers,
  ScoringRule scoringRule = const ScoringRule(),
}) => Question(
  id: id,
  bankId: 'bank',
  externalId: id,
  contentVersion: 1,
  type: type,
  stem: id,
  options: const {'A': 'A', 'B': 'B', 'C': 'C', 'D': 'D', 'E': 'E'},
  answers:
      answers ??
      (type == QuestionType.single ? const ['A'] : const ['A', 'B', 'C']),
  explanation: '',
  knowledgePoint: '',
  source: '',
  year: '',
  chapter: '',
  tags: const [],
  media: const [],
  scoringRule: scoringRule,
  isActive: true,
);

void main() {
  const policy = PaperScoringPolicy();

  test('试卷统一评分真值表忽略题库自定义规则，练习仍保留题库规则', () {
    final single = question(
      'single',
      QuestionType.single,
      scoringRule: const ScoringRule(singleScore: 5, unansweredScore: 3),
    );
    final multiple = question(
      'multiple',
      QuestionType.multiple,
      scoringRule: const ScoringRule(multipleScore: 10, partialCredit: false),
    );

    expect(policy.score(single, const ['A']).score, 1);
    expect(policy.score(single, const ['B']).score, 0);
    expect(policy.score(single, const []).score, 0);
    expect(policy.score(multiple, const ['A', 'B', 'C']).score, 2);
    expect(policy.score(multiple, const ['A', 'B']).score, 1);
    expect(policy.score(multiple, const ['A']).score, 0.5);
    expect(policy.score(multiple, const ['A', 'D']).score, 0);
    expect(policy.score(multiple, const []).score, 0);
    expect(AnswerPolicy.score(single, const ['A']).score, 5);
    expect(AnswerPolicy.score(multiple, const ['A', 'B']).score, 0);
  });

  test('百分制与原始分和满分一致，并安全处理零满分', () {
    expect(policy.percentage(score: 10.5, maxScore: 14), 75);
    expect(policy.percentage(score: 0, maxScore: 0), 0);
  });

  test('仅单选和仅多选模式只抽取指定题型', () {
    final available = <Question>[
      ...List.generate(4, (i) => question('s$i', QuestionType.single)),
      ...List.generate(3, (i) => question('m$i', QuestionType.multiple)),
    ];
    final singles = PaperCompositionPolicy.compose(
      available,
      mode: PaperCompositionMode.singleOnly,
      total: 3,
      random: false,
    );
    final multiples = PaperCompositionPolicy.compose(
      available,
      mode: PaperCompositionMode.multipleOnly,
      total: 2,
      random: false,
    );

    expect(singles.map((q) => q.id), ['s0', 's1', 's2']);
    expect(singles.every((q) => q.type == QuestionType.single), isTrue);
    expect(multiples.map((q) => q.id), ['m0', 'm1']);
    expect(multiples.every((q) => q.type == QuestionType.multiple), isTrue);
  });

  test('真实组卷配额使用 round(total*3/17)，单选块在前', () {
    final available = <Question>[
      ...List.generate(100, (i) => question('s$i', QuestionType.single)),
      ...List.generate(100, (i) => question('m$i', QuestionType.multiple)),
    ];
    final expected = <int, List<int>>{
      20: [16, 4],
      30: [25, 5],
      50: [41, 9],
      85: [70, 15],
      100: [82, 18],
    };
    for (final entry in expected.entries) {
      final paper = PaperCompositionPolicy.composeRealExam(
        available,
        total: entry.key,
        random: false,
      );
      expect(
        paper.where((q) => q.type == QuestionType.single),
        hasLength(entry.value[0]),
      );
      expect(
        paper.where((q) => q.type == QuestionType.multiple),
        hasLength(entry.value[1]),
      );
      expect(
        paper.take(entry.value[0]).every((q) => q.type == QuestionType.single),
        isTrue,
      );
      expect(
        paper
            .skip(entry.value[0])
            .every((q) => q.type == QuestionType.multiple),
        isTrue,
      );
    }
  });

  test('库存不足不跨类型补齐，随机只发生在各自块内', () {
    final constrained = <Question>[
      ...List.generate(30, (i) => question('s$i', QuestionType.single)),
      ...List.generate(2, (i) => question('m$i', QuestionType.multiple)),
    ];
    final shortage = PaperCompositionPolicy.composeRealExam(
      constrained,
      total: 20,
      random: false,
    );
    expect(shortage, hasLength(18));
    expect(shortage.take(16).map((q) => q.id), List.generate(16, (i) => 's$i'));
    expect(shortage.skip(16).map((q) => q.id), ['m0', 'm1']);

    final randomized = PaperCompositionPolicy.composeRealExam(
      constrained,
      total: 20,
      random: true,
      randomSource: Random(7),
    );
    expect(
      randomized.take(16).every((q) => q.type == QuestionType.single),
      isTrue,
    );
    expect(
      randomized.skip(16).every((q) => q.type == QuestionType.multiple),
      isTrue,
    );
    expect(randomized, hasLength(18));
    expect(randomized.map((q) => q.id).toSet(), hasLength(18));
    expect(randomized.take(16).every((q) => constrained.contains(q)), isTrue);
    expect(randomized.skip(16).map((q) => q.id).toSet(), {'m0', 'm1'});
    expect(
      randomized.take(16).map((q) => q.id).toList(),
      isNot(equals(shortage.take(16).map((q) => q.id).toList())),
    );
  });
}
