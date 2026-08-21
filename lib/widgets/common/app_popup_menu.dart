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

import '../../utils/constants.dart';

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
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
    return AppTextStyles.caption.copyWith(
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
/// - [boxed] = false：无边框紧凑触发器（表格单元格内，如变量类型）
/// - [boxed] = true：带边框触发器（对话框表单，菜单宽度与触发器一致）
class AppPopupSelect<T> extends StatelessWidget {
  const AppPopupSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onSelected,
    this.hint,
    this.boxed = false,
    this.fontSize = 12,
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

  /// 触发器文字字号
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          offset: Offset(0, boxed ? 34 : 22),
          constraints: BoxConstraints(
            minWidth: triggerWidth ?? 120,
            maxWidth: triggerWidth ?? 280,
          ),
          shape: AppPopupMenu.menuShape(theme),
          elevation: AppPopupMenu.menuElevation,
          color: AppPopupMenu.menuColor(theme),
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final entry in items)
              AppPopupMenu.textItem(
                theme: theme,
                value: entry.value,
                label: entry.label,
                selected: entry.value == value,
              ),
          ],
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: boxed ? 10 : 4,
              vertical: boxed ? 8 : 2,
            ),
            decoration: boxed
                ? BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  )
                : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel ?? hint ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: selectedLabel != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
