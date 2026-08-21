import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

/// 次级 Tab 条的单个标签定义（规格见原型 .tabs / .tab）。
class AppTabItem {
  const AppTabItem({
    required this.label,
    this.icon,
    this.count,
    this.dot = false,
  });

  final String label;
  final IconData? icon;

  /// 计数徽章（如 Params/Headers 条数）；null 不显示
  final int? count;

  /// 内容存在标记点（如 Body 有内容）
  final bool dot;
}

/// 应用统一次级 Tab 条（请求编辑区 / 响应区）。
///
/// 规格：条高 32、底边 1px border；Tab 高 32、横 padding 12、图标 12、
/// 文字 12 w500、间距 6；hover 文字 textPrimary；选中文字 brand +
/// 2px brand 下划线；计数徽章 10px w600 圆角 8（选中 brandSoft 底）；
/// dot 为 5px success 圆点。
class AppTabs extends StatelessWidget {
  const AppTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.backgroundColor,
  });

  final List<AppTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// 条底色；null 时用 surface
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Container(
      width: double.infinity,
      height: AppMetrics.height32,
      decoration: BoxDecoration(
        color: backgroundColor ?? t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              _AppTab(
                item: tabs[i],
                isActive: i == selectedIndex,
                onTap: () => onChanged(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppTab extends StatefulWidget {
  const _AppTab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AppTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_AppTab> createState() => _AppTabState();
}

class _AppTabState extends State<_AppTab> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final active = widget.isActive;

    final foreground =
        active ? t.brand : (_hovering ? t.textPrimary : t.textSecondary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: AppMetrics.height32,
          padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? t.brand : AppColors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 12, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                widget.item.label,
                style: AppTextStyles.caption12.copyWith(
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
              if (widget.item.count != null)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: active ? t.brandSoft : t.surfaceVariant,
                    borderRadius: AppMetrics.br8,
                  ),
                  child: Text(
                    '${widget.item.count}',
                    style: AppTextStyles.micro10.copyWith(
                      fontWeight: FontWeight.w600,
                      color: active ? t.brand : t.textSecondary,
                    ),
                  ),
                ),
              if (widget.item.dot)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
