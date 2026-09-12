/// 题目内容（题干/选项/解析）中排版标记的两种处理方式。
///
/// 题库文本可能包含 `<p>`、`<br>` 等排版标记：
/// - [renderMarkupText]：把块级标记转换为换行（渲染语义），其余标记剥离；
/// - [plainText]：与历史行为一致，检测到标记时整段剥离（换行语义丢失）。
/// 设置项 `render_question_markup` 决定 UI 与导出采用哪一种（默认渲染）。
library;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// 块级元素：其开始/结束边界视为换行。
const _blockTags = {
  'p', 'div', 'li', 'ul', 'ol', 'tr', 'table', 'h1', 'h2', 'h3', 'h4', 'h5',
  'h6', 'blockquote', 'pre', 'section', 'article', 'hr',
};

/// 把排版标记渲染为换行等纯文本语义。
String renderMarkupText(String value) {
  if (!RegExp(r'<[a-zA-Z/][^>]*>').hasMatch(value)) return value;
  final buffer = StringBuffer();
  void walk(dom.Node node) {
    if (node is dom.Text) {
      buffer.write(node.text);
      return;
    }
    if (node is! dom.Element) return;
    final tag = (node.localName ?? '').toLowerCase();
    if (tag == 'br') {
      buffer.write('\n');
      return;
    }
    final isBlock = _blockTags.contains(tag);
    if (isBlock) buffer.write('\n');
    for (final child in node.nodes) {
      walk(child);
    }
    if (isBlock) buffer.write('\n');
  }

  for (final node in html_parser.parseFragment(value).nodes) {
    walk(node);
  }
  return _normalize(buffer.toString());
}

/// 历史行为：检测到标记时整段剥离文本（无换行语义）。
String plainText(String value) {
  if (!RegExp(r'<[a-zA-Z][^>]*>').hasMatch(value)) return value;
  return html_parser.parseFragment(value).text ?? value;
}

/// 收敛空白：不换行空格转普通空格、行尾空格去除、
/// 3 个以上连续换行折叠为 2 个（段落间隔）、整体去首尾。
String _normalize(String text) {
  final lines = text
      .replaceAll('\u00a0', ' ')
      .split('\n')
      .map((line) => line.trim())
      .join('\n');
  var result = lines.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  result = result.replaceFirst(RegExp(r'^\n+'), '');
  result = result.replaceFirst(RegExp(r'\n+$'), '');
  return result;
}
