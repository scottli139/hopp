import 'package:flutter/material.dart';

import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

/// 应用统一输入框（outline 风格，规格见原型 .input）。
///
/// 规格：默认高 32（[compact] 高 28）、横 padding 10、字号 13（compact 12）、
/// 底 background、边 borderStrong、圆角 6、focus 边 brand 1.5px。
/// 占位文字 textTertiary。
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.compact = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.height,
    this.style,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  /// true 时高 28、字号 12（工具条内嵌输入）
  final bool compact;
  final bool obscureText;
  final int? maxLines;

  /// 固定高度；null 时按 compact 取 28/32。maxLines > 1 时忽略。
  final double? height;
  final TextStyle? style;

  /// 统一的输入框装饰（供需要裸 TextField 的场景复用）
  static InputDecoration decoration(
    BuildContext context, {
    String? hintText,
    bool compact = false,
  }) {
    final t = context.appTheme;
    OutlineInputBorder outline(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: AppMetrics.br6,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hintText,
      hintStyle: (compact ? AppTextStyles.caption12 : AppTextStyles.body13)
          .copyWith(color: t.textTertiary),
      filled: true,
      fillColor: t.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.space12 - 2,
      ),
      border: outline(t.borderStrong),
      enabledBorder: outline(t.borderStrong),
      focusedBorder: outline(t.brand, width: 1.5),
      errorBorder: outline(t.error),
      focusedErrorBorder: outline(t.error, width: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final effectiveHeight =
        maxLines == 1 ? (height ?? (compact ? 28.0 : 32.0)) : null;

    Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: maxLines,
      style: style ??
          (compact ? AppTextStyles.caption12 : AppTextStyles.body13)
              .copyWith(color: t.textPrimary),
      decoration: decoration(context, hintText: hintText, compact: compact),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );

    if (effectiveHeight != null) {
      field = SizedBox(height: effectiveHeight, child: field);
    }
    return field;
  }
}
