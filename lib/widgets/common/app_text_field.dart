import 'package:flutter/material.dart';

import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

/// 应用统一输入框（outline 风格，规格见原型 .input）。
///
/// 规格：默认高 32（[compact] 高 28）、横 padding 10、字号 13（compact 12）、
/// 底 background、边 borderStrong、圆角 6、focus 边 brand 1.5px。
/// 占位文字 textTertiary。
///
/// 实现说明：**不能**依赖 `InputDecorator` 描边控高——`isDense` 下边框只
/// 包住「文字行高 + contentPadding」，外层 SizedBox 只影响布局空间，不会
/// 影响描边高度（`InputDecoration.constraints` 也无效，Flutter 3.27 实测）；
/// 多行 expands 场景甚至会出现文字溢出描边框。因此统一用显式 Container
/// 盒子 + `InputDecoration.collapsed`（且所有 border 状态显式置空，否则会
/// 从主题 inputDecorationTheme 继承出第二道描边），保证渲染盒 == 绘制盒。
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.fieldKey,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.compact = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.expands = false,
    this.height,
    this.style,
    this.suffix,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// 挂在内部 TextField 上的 key（测试按 key 定位/输入的场景使用）
  final Key? fieldKey;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;

  /// true 时高 28、字号 12（工具条/表格行内嵌输入）
  final bool compact;
  final bool obscureText;

  /// 多行时 > 1（如 3），盒子高度包裹内容；单行固定高时忽略
  final int? maxLines;

  /// 撑满父级紧约束高度（需父级提供有限高度，如 Expanded），文本顶对齐
  final bool expands;

  /// 固定高度；null 时按 compact 取 28/32。仅单行生效。
  final double? height;
  final TextStyle? style;

  /// 盒子右端内嵌控件（如 secret 显隐切换按钮），仅单行生效
  final Widget? suffix;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownedNode;
  FocusNode? _listenedNode;
  bool _focused = false;

  FocusNode get _effectiveNode =>
      widget.focusNode ?? (_ownedNode ??= FocusNode());

  void _attachListener() {
    final node = _effectiveNode;
    if (_listenedNode == node) return;
    _listenedNode?.removeListener(_onFocusChange);
    node.addListener(_onFocusChange);
    _listenedNode = node;
    _focused = node.hasFocus;
  }

  @override
  void initState() {
    super.initState();
    _attachListener();
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (widget.focusNode != null && _ownedNode != null) {
        _ownedNode!.dispose();
        _ownedNode = null;
      }
      _attachListener();
    }
  }

  void _onFocusChange() {
    if (_focused != _listenedNode!.hasFocus) {
      setState(() => _focused = _listenedNode!.hasFocus);
    }
  }

  @override
  void dispose() {
    _listenedNode?.removeListener(_onFocusChange);
    _ownedNode?.dispose();
    super.dispose();
  }

  InputDecoration _collapsedDecoration(TextStyle textStyle, AppThemeData t) {
    return InputDecoration.collapsed(
      hintText: widget.hintText,
      hintStyle: textStyle.copyWith(color: t.textTertiary),
    ).copyWith(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final textStyle = (widget.style ??
            (widget.compact ? AppTextStyles.caption12 : AppTextStyles.body13))
        .copyWith(color: widget.enabled ? t.textPrimary : t.textTertiary);
    final singleLine = widget.maxLines == 1 && !widget.expands;

    final field = TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      focusNode: _effectiveNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      maxLines: widget.expands ? null : widget.maxLines,
      expands: widget.expands,
      textAlignVertical: widget.expands ? TextAlignVertical.top : null,
      style: textStyle,
      decoration: _collapsedDecoration(textStyle, t),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );

    return Container(
      height: singleLine
          ? (widget.height ??
              (widget.compact ? AppMetrics.height28 : AppMetrics.height32))
          : null,
      decoration: BoxDecoration(
        color: t.background,
        border: Border.all(
          color: _focused ? t.brand : t.borderStrong,
          width: _focused ? 1.5 : 1,
        ),
        borderRadius: AppMetrics.br6,
      ),
      padding: singleLine
          ? const EdgeInsets.symmetric(horizontal: AppMetrics.space12 - 2)
          : const EdgeInsets.symmetric(
              horizontal: AppMetrics.space12 - 2,
              vertical: AppMetrics.space8,
            ),
      child: singleLine
          ? Row(
              children: [
                Expanded(child: Center(child: field)),
                if (widget.suffix != null) widget.suffix!,
              ],
            )
          : field,
    );
  }
}
