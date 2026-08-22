import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_theme_data.dart';

/// 分段项定义（见 [AppSegmentedControl]）。
class AppSegmentedItem<T> {
  const AppSegmentedItem({
    required this.value,
    required this.icon,
    required this.tooltip,
  });

  final T value;
  final IconData icon;
  final String tooltip;
}

/// 应用统一分段选择器：2~4 个互斥选项的紧凑切换（如主题模式）。
///
/// 规格：容器高 24、surfaceVariant 底、br6 圆角、内 padding 2；
/// 段宽 28、图标 13；选中段 surface 底 + shadowSm + br4 圆角、图标
/// brand；未选中图标 textTertiary，hover textPrimary。
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final List<AppSegmentedItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Container(
      height: AppMetrics.height24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: AppMetrics.br6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            _AppSegment<T>(
              item: item,
              selected: item.value == value,
              onTap: () => onChanged(item.value),
            ),
        ],
      ),
    );
  }
}

class _AppSegment<T> extends StatefulWidget {
  const _AppSegment({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppSegmentedItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AppSegment<T>> createState() => _AppSegmentState<T>();
}

class _AppSegmentState<T> extends State<_AppSegment<T>> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final selected = widget.selected;

    final iconColor =
        selected ? t.brand : (_hovering ? t.textPrimary : t.textTertiary);

    return Tooltip(
      message: widget.item.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMetrics.animFast,
            width: 28,
            height: 20,
            decoration: BoxDecoration(
              color: selected ? t.surface : AppColors.transparent,
              borderRadius: AppMetrics.br4,
              boxShadow: selected ? AppShadows.sm(context) : null,
            ),
            child: Icon(widget.item.icon, size: 13, color: iconColor),
          ),
        ),
      ),
    );
  }
}
