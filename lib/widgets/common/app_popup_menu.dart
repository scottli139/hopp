/// 应用统一的弹出菜单样式
///
/// 所有命令菜单（PopupMenuButton / showMenu / MenuAnchor）共享：
/// - 容器：圆角 radiusM + 细边框 + elevation 4 + surface 底色
/// - 菜单项：高 32、水平内边距 12、图标 14px、文字 caption（12px w500）
///
/// 值选择场景（替代 DropdownButton）使用本文件的 [AppPopupSelect]，
/// 弹出菜单复用同一容器与菜单项样式。
library;

import 'package:flutter/material.dart';

import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

class AppPopupMenu {
  AppPopupMenu._();

  /// 菜单项高度
  static const double itemHeight = 32;

  /// 菜单项水平内边距
  static const double itemHorizontalPadding = 12;

  /// 菜单项图标尺寸
  static const double itemIconSize = 14;

  /// 菜单容器 elevation
  static const double menuElevation = 4;

  /// 菜单容器形状（圆角 + 细边框）
  static RoundedRectangleBorder menuShape(ThemeData theme) {
    return RoundedRectangleBorder(
      borderRadius: AppMetrics.br6,
      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
    );
  }

  /// 菜单容器底色
  static Color menuColor(ThemeData theme) => theme.colorScheme.surface;

  /// MenuAnchor 场景的容器样式（与 PopupMenu 容器一致）
  static MenuStyle menuStyle(ThemeData theme) {
    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll(menuColor(theme)),
      elevation: const WidgetStatePropertyAll(menuElevation),
      shape: WidgetStatePropertyAll(menuShape(theme)),
    );
  }

  /// 菜单项文字样式
  static TextStyle itemTextStyle(
    ThemeData theme, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    return AppTextStyles.caption12.copyWith(
      color: color ?? theme.colorScheme.onSurface,
      fontWeight: fontWeight ?? FontWeight.w500,
    );
  }

  /// 图标 + 文字菜单项（命令菜单）
  static PopupMenuItem<T> iconItem<T>({
    required ThemeData theme,
    required T value,
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? labelColor,
  }) {
    return PopupMenuItem<T>(
      value: value,
      height: itemHeight,
      padding: const EdgeInsets.symmetric(horizontal: itemHorizontalPadding),
      child: Row(
        children: [
          Icon(
            icon,
            size: itemIconSize,
            color: iconColor ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(label, style: itemTextStyle(theme, color: labelColor)),
        ],
      ),
    );
  }

  /// 纯文字菜单项（选择器类弹出菜单）
  static PopupMenuItem<T> textItem<T>({
    required ThemeData theme,
    required T value,
    required String label,
    bool selected = false,
    Color? color,
  }) {
    return PopupMenuItem<T>(
      value: value,
      height: itemHeight,
      padding: const EdgeInsets.symmetric(horizontal: itemHorizontalPadding),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: itemTextStyle(
          theme,
          color: color ?? (selected ? theme.colorScheme.primary : null),
          fontWeight: selected ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}

/// 选择项
class AppPopupSelectEntry<T> {
  final T value;
  final String label;

  const AppPopupSelectEntry({required this.value, required this.label});
}

/// 值选择弹出菜单（DropdownButton 的统一替代）
///
/// 触发器为「文字 + 下拉箭头」，弹出菜单复用 [AppPopupMenu] 统一容器与
/// 菜单项样式，当前值在菜单中以选中态（primary + w600）高亮。
///
/// - [boxed] = false：无边框紧凑触发器（工具栏等极简场景）
/// - [boxed] = true：带边框触发器（表单 / 表格单元格，菜单宽度与触发器一致）
class AppPopupSelect<T> extends StatelessWidget {
  const AppPopupSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onSelected,
    this.hint,
    this.boxed = false,
    this.compact = false,
    this.textStyle,
  });

  /// 当前值；为 null 或不匹配任何项时显示 [hint]
  final T? value;

  /// 可选项
  final List<AppPopupSelectEntry<T>> items;

  /// 选择回调
  final ValueChanged<T> onSelected;

  /// 未选择时的占位文字
  final String? hint;

  /// 是否使用带边框的表单触发器
  final bool boxed;

  /// 紧凑模式（仅 [boxed] 时生效）：触发器高 28 而非 32，与
  /// AppTextField compact 对齐（表格行内场景）
  final bool compact;

  /// 触发器文字样式（默认 [AppTextStyles.caption12]）
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    String? selectedLabel;
    for (final entry in items) {
      if (entry.value == value) {
        selectedLabel = entry.label;
        break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // boxed 触发器场景下菜单宽度与触发器一致
        final triggerWidth = boxed ? constraints.maxWidth : null;

        return PopupMenuButton<T>(
          tooltip: '',
          offset: Offset(0, boxed ? (compact ? 30 : 34) : 22),
          constraints: BoxConstraints(
            minWidth: triggerWidth ?? 120,
            maxWidth: triggerWidth ?? 280,
          ),
          shape: AppPopupMenu.menuShape(Theme.of(context)),
          elevation: AppPopupMenu.menuElevation,
          color: AppPopupMenu.menuColor(Theme.of(context)),
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final entry in items)
              AppPopupMenu.textItem(
                theme: Theme.of(context),
                value: entry.value,
                label: entry.label,
                selected: entry.value == value,
              ),
          ],
          // boxed 触发器规格与 AppTextField 对齐：高 32（compact 28）、
          // 底 background、边 borderStrong、圆角 6
          child: Container(
            height: boxed ? (compact ? 28.0 : 32.0) : null,
            padding: EdgeInsets.symmetric(
              horizontal: boxed ? 10 : 4,
              vertical: boxed ? 0 : 2,
            ),
            decoration: boxed
                ? BoxDecoration(
                    color: t.background,
                    border: Border.all(color: t.borderStrong),
                    borderRadius: AppMetrics.br6,
                  )
                : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel ?? hint ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (textStyle ?? AppTextStyles.caption12).copyWith(
                      color: selectedLabel != null
                          ? t.textPrimary
                          : t.textTertiary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: t.textTertiary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
