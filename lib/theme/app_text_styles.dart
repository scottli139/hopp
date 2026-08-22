import 'package:flutter/material.dart';

/// 应用文字样式：8 档收敛（20/16/13/12/11/10 + code 12/11）。
///
/// 业务代码禁止内联 fontSize 字面量（守卫规则 G3），统一从这里取，
/// 或在其基础上 copyWith（仅限字重 / 颜色等非字号属性）。
class AppTextStyles {
  AppTextStyles._();

  /// 20 w600 —— 页面级大标题（极少使用）
  static const display20 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// 16 w600 —— 对话框标题 / 区块标题
  static const title16 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// 13 w400 —— 正文基准（桌面密度）
  static const body13 = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// 12 w400 —— 辅助说明 / 次级信息
  static const caption12 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// 11 w500 —— 徽标文字 / 状态行
  static const tiny11 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// 10 w700 —— 方法徽章等小号强调
  static const micro10 = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.2,
  );

  /// 12 w400 Menlo —— 代码 / 等宽文本统一入口
  static const code12 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    fontFamily: 'Menlo',
  );

  /// 11 w400 Menlo —— 密集代码场景（KV 行 / 头信息等）
  static const code11 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamily: 'Menlo',
  );
}
