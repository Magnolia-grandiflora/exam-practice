import 'package:flutter_test/flutter_test.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations_en.dart';
import 'package:personal_exam_app/l10n/generated/app_localizations_zh.dart';
import 'package:personal_exam_app/services/markdown_exporter.dart';
import 'package:personal_exam_app/ui/export_labels.dart';

void main() {
  test('zh 导出标签与默认值逐字一致（中文导出产物不变）', () {
    final zh = localizedExportLabels(AppLocalizationsZh());
    const defaults = ExportLabels();
    expect(zh.paperFileName, defaults.paperFileName);
    expect(zh.answerSheetFileName, defaults.answerSheetFileName);
    expect(zh.multipleChoiceTag, defaults.multipleChoiceTag);
    expect(zh.singleChoiceTag, defaults.singleChoiceTag);
    expect(zh.wrongStatus, defaults.wrongStatus);
    expect(zh.paperStatsLine, '题量：{count}　建议用时：{minutes} 分钟');
  });

  test('en 导出标签随界面语言本地化，且数值令牌完整保留', () {
    final en = localizedExportLabels(AppLocalizationsEn());
    // 关键行模板仍含令牌，供导出器回填实际数值。
    expect(en.paperStatsLine, 'Questions: {count} · Suggested time: {minutes} min');
    expect(en.correctAnswersBoldLine, contains('{answers}'));
    expect(en.reviewScoreLine, contains('{score}'));
    expect(en.unansweredCountLine, contains('{count}'));
    // 标签本体与中文默认不同（确属本地化产物）。
    expect(en.multipleChoiceTag, isNot('【多选】'));
    expect(en.paperFileName, isNot(const ExportLabels().paperFileName));
  });
}
