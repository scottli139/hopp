import 'package:flutter/material.dart';

/// 布局度量 token：间距 / 圆角 / 控件高度 / 动画时长。
///
/// 业务代码禁止 BorderRadius.circular(数字) 字面量（守卫规则 G5），
/// 统一使用这里的命名值。
class AppMetrics {
  AppMetrics._();

  // ========== 间距（4 的倍数网格） ==========
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // ========== 圆角 ==========
  /// 微型徽章 / 标签
  static const double radius2 = 2;
  static const double radius4 = 4;
  static const double radius6 = 6;
  static const double radius8 = 8;
  static const double radius10 = 10;

  static const BorderRadius br2 = BorderRadius.all(Radius.circular(2));
  static const BorderRadius br4 = BorderRadius.all(Radius.circular(4));
  static const BorderRadius br6 = BorderRadius.all(Radius.circular(6));
  static const BorderRadius br8 = BorderRadius.all(Radius.circular(8));
  static const BorderRadius br10 = BorderRadius.all(Radius.circular(10));

  // ========== 控件高度 ==========
  /// 紧凑行 / 小控件
  static const double height24 = 24;

  /// 小按钮 / 图标按钮 / 状态栏
  static const double height28 = 28;

  /// 标准控件（URL 栏 / 主按钮 / 输入框 / Tab 条）
  static const double height32 = 32;

  /// 宽松控件（响应信息栏等）
  static const double height36 = 36;

  /// 响应信息栏（设计规范统一值）
  static const double height38 = 38;

  /// 页面头部条（侧栏 header 等）
  static const double height48 = 48;

  // ========== 动画时长 ==========
  static const Duration animFast = Duration(milliseconds: 100);
  static const Duration animNormal = Duration(milliseconds: 200);
  static const Duration animSlow = Duration(milliseconds: 300);
}
