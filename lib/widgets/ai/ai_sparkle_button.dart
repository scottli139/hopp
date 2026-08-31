import 'package:flutter/material.dart';

import '../../theme/app_metrics.dart';
import '../../theme/app_theme_data.dart';

/// AI 入口统一图标按钮（✨，规格见原型 .icon-btn.ai）。
///
/// brandSoft 底 + brand 图标 + br6 圆角，用于 URL 栏 / 响应 info bar 等
/// 空间受限处的 AI 任务入口；hover 底色加深一档。
class AiSparkleButton extends StatefulWidget {
  const AiSparkleButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.size = AppMetrics.height28,
    this.iconSize = 15,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  @override
  State<AiSparkleButton> createState() => _AiSparkleButtonState();
}

class _AiSparkleButtonState extends State<AiSparkleButton> {
  var _hovering = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    Widget child = MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: _enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: _enabled ? (_) => setState(() => _hovering = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppMetrics.animFast,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _hovering ? t.brand.withValues(alpha: 0.22) : t.brandSoft,
            borderRadius: AppMetrics.br6,
          ),
          child: Icon(
            Icons.auto_awesome,
            size: widget.iconSize,
            color: t.brand,
          ),
        ),
      ),
    );

    if (!_enabled) {
      child = Opacity(opacity: 0.45, child: child);
    }

    return Tooltip(message: widget.tooltip, child: child);
  }
}
