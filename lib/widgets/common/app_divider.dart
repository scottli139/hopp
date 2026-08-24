import 'package:flutter/material.dart';

import '../../theme/app_theme_data.dart';

/// 统一分隔线：实色 `border` 或 `border × 50%`（subtle）两档。
///
/// 替代散落的 Divider / VerticalDivider / 手写边线写法。
/// 用法：`AppDivider()` / `AppDivider(subtle: true)` / `AppDivider.vertical()`。
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.subtle = false, this.height = 1})
      : width = 1,
        _vertical = false;

  const AppDivider.vertical({super.key, this.subtle = false, this.width = 1})
      : height = 1,
        _vertical = true;

  /// subtle 使用 border × 50%，否则实色 border
  final bool subtle;

  /// 水平模式占用高度（线贴底，与 Divider 语义一致），默认 1
  final double height;

  /// 垂直模式占用宽度（线贴左，与 VerticalDivider 语义一致），默认 1
  final double width;

  final bool _vertical;

  @override
  Widget build(BuildContext context) {
    final base = context.appTheme.border;
    final color = subtle ? base.withValues(alpha: 0.5) : base;
    if (_vertical) {
      return SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color)),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      // 水平分隔线必须撑满可用宽度：无子节点的 DecoratedBox 在宽松
      // 约束下宽度为 0（非 stretch 的 Column 里整条线不渲染）
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: color)),
        ),
      ),
    );
  }
}
