import 'package:flutter/material.dart';

/// 阴影 token：仅浮层（菜单 / 对话框 / 悬浮卡片 / 开关滑块）使用。
///
/// 数值与 docs/design/design_system_preview.html 的 --shadow-sm / --shadow-md
/// 一一对应（亮暗两套），按钮一律无阴影。
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> _smLight = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> _mdLight = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> _smDark = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> _mdDark = [
    BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// 一级阴影（开关滑块 / 小浮层）
  static List<BoxShadow> sm(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _smDark : _smLight;

  /// 二级阴影（菜单 / 对话框 / 悬浮卡片）
  static List<BoxShadow> md(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _mdDark : _mdLight;
}
