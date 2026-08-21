import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

/// 按钮变体（规格见 docs/design/design_system_preview.html .btn-*）
enum AppButtonVariant { primary, secondary, ghost, danger }

/// 按钮尺寸：small 高 28 / medium 高 32
enum AppButtonSize { small, medium }

/// 应用统一按钮。
///
/// 规格：圆角 6、w500、无阴影；small 高 28 横 padding 12 字号 12，
/// medium 高 32 横 padding 14 字号 13；禁用态 opacity .45。
/// hover：primary → brandHover；secondary/ghost → surfaceVariant 底；
/// danger → 黑色 8% 叠加。
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  var _hovering = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    final Color background;
    final Color hoverBackground;
    final Color foreground;
    final Color hoverForeground;
    final Border? border;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        background = t.brand;
        hoverBackground = t.brandHover;
        foreground = AppColors.onBrand;
        hoverForeground = AppColors.onBrand;
        border = null;
      case AppButtonVariant.secondary:
        background = AppColors.transparent;
        hoverBackground = t.surfaceVariant;
        foreground = t.textPrimary;
        hoverForeground = t.textPrimary;
        border = Border.all(color: t.borderStrong);
      case AppButtonVariant.ghost:
        background = AppColors.transparent;
        hoverBackground = t.surfaceVariant;
        foreground = t.textSecondary;
        hoverForeground = t.textPrimary;
        border = null;
      case AppButtonVariant.danger:
        background = t.error;
        hoverBackground = t.error;
        foreground = AppColors.onBrand;
        hoverForeground = AppColors.onBrand;
        border = null;
    }

    final isSmall = widget.size == AppButtonSize.small;
    final textStyle =
        (isSmall ? AppTextStyles.caption12 : AppTextStyles.body13).copyWith(
      fontWeight: FontWeight.w500,
      color: _hovering ? hoverForeground : foreground,
    );
    final iconColor = _hovering ? hoverForeground : foreground;

    Widget child = AnimatedContainer(
      duration: AppMetrics.animFast,
      height: isSmall ? AppMetrics.height28 : AppMetrics.height32,
      padding:
          EdgeInsets.symmetric(horizontal: isSmall ? AppMetrics.space12 : 14),
      decoration: BoxDecoration(
        color: _hovering ? hoverBackground : background,
        borderRadius: AppMetrics.br6,
        border: border,
      ),
      // danger hover 叠加黑色 8%
      foregroundDecoration:
          _hovering && widget.variant == AppButtonVariant.danger
              ? BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.08),
                  borderRadius: AppMetrics.br6,
                )
              : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: isSmall ? 14 : 16, color: iconColor),
            const SizedBox(width: 6),
          ],
          Text(widget.label, style: textStyle),
        ],
      ),
    );

    if (!_enabled) {
      child = Opacity(opacity: 0.45, child: child);
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: _enabled ? (_) => setState(() => _hovering = true) : null,
        onExit: _enabled ? (_) => setState(() => _hovering = false) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: child,
        ),
      ),
    );
  }
}

/// 应用统一图标按钮（28×28，圆角 6）。
///
/// 默认：图标 textSecondary，hover 底 surfaceVariant + 图标 textPrimary。
/// [bordered] 为 true 时带 borderStrong 边框与 background 底（输入区工具按钮）。
/// [color] 可覆盖图标色（如 dirty 态用 brand）。
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.bordered = false,
    this.size = AppMetrics.height28,
    this.iconSize = 16,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final bool bordered;
  final double size;
  final double iconSize;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  var _hovering = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final baseColor = widget.color ?? t.textSecondary;
    final iconColor = _hovering ? (widget.color ?? t.textPrimary) : baseColor;

    Widget child = AnimatedContainer(
      duration: AppMetrics.animFast,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _hovering
            ? t.surfaceVariant
            : (widget.bordered ? t.background : AppColors.transparent),
        borderRadius: AppMetrics.br6,
        border: widget.bordered ? Border.all(color: t.borderStrong) : null,
      ),
      child: Center(
        child: Icon(widget.icon, size: widget.iconSize, color: iconColor),
      ),
    );

    if (!_enabled) {
      child = Opacity(opacity: 0.45, child: child);
    }

    child = MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: _enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: _enabled ? (_) => setState(() => _hovering = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: child,
      ),
    );

    final tooltip = widget.tooltip;
    if (tooltip != null) {
      child = Tooltip(message: tooltip, child: child);
    }
    return child;
  }
}
