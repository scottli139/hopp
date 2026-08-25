import 'package:flutter/material.dart';

import '../../services/variable_resolver.dart';
import '../../theme/app_theme_data.dart';

/// 变量高亮输入控制器（F8.3）
///
/// 把 `{{variable}}` 片段渲染为分段 chip 效果（纯 TextSpan 着色）：
/// - 基础变量名（`{{name` 与 `}}`）：brand 色 + brandSoft 底色
/// - 转换管道段（`| sha1` 等）：warning 色 + warningSoft 底色，一眼区分
///   「谁在起作用」（设计原型 docs/design/f8_prerequest_chain_preview.html）
///
/// 复用自原 `_UrlEditingController`（request_editor.dart），支持
/// 转换管道语法；用于 URL 栏与 KV 单元格。[appTheme] 在
/// State.didChangeDependencies 中刷新，主题切换后下一次重建生效。
class VariableHighlightController extends TextEditingController {
  AppThemeData appTheme = AppThemeData.light;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final value = text;
    if (!value.contains('{{')) {
      return TextSpan(style: style, text: value);
    }

    final baseStyle = style?.copyWith(
      color: appTheme.brand,
      backgroundColor: appTheme.brandSoft,
    );
    final pipeStyle = style?.copyWith(
      color: appTheme.warning,
      backgroundColor: appTheme.warningSoft,
    );

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in VariableResolver.scanExpressions(value)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, match.start)));
      }
      spans.addAll(
          _buildExpressionSpans(match.expression, baseStyle, pipeStyle));
      cursor = match.end;
    }
    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor)));
    }
    return TextSpan(style: style, children: spans);
  }

  /// 把一条表达式（不含大括号）按顶层 `|` 切成基础段 + 管道段
  List<TextSpan> _buildExpressionSpans(
    String expression,
    TextStyle? baseStyle,
    TextStyle? pipeStyle,
  ) {
    // 在原文上按顶层 | 定位（保留原始空白），第一段为基础变量
    final pipeOffsets = <int>[];
    var depth = 0;
    for (var i = 0; i < expression.length; i++) {
      final ch = expression[i];
      if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        if (depth > 0) depth--;
      } else if (ch == '|' && depth == 0) {
        pipeOffsets.add(i);
      }
    }

    if (pipeOffsets.isEmpty) {
      return [TextSpan(text: '{{$expression}}', style: baseStyle)];
    }

    final spans = <TextSpan>[
      TextSpan(
        text: '{{${expression.substring(0, pipeOffsets.first)}}',
        style: baseStyle,
      ),
    ];
    for (var k = 0; k < pipeOffsets.length; k++) {
      final end =
          k + 1 < pipeOffsets.length ? pipeOffsets[k + 1] : expression.length;
      spans.add(TextSpan(
        text: expression.substring(pipeOffsets[k], end),
        style: pipeStyle,
      ));
    }
    spans.add(TextSpan(text: '}}', style: baseStyle));
    return spans;
  }
}
