import 'package:flutter/material.dart';

/// 原始调色板：品牌色、语义色、HTTP 方法色（与亮/暗主题无关的常量色）。
///
/// 数值与 docs/design/design_system_preview.html 的 CSS 变量一一对应。
/// 随主题变化的中性色 / soft 背景见 app_theme_data.dart（AppThemeData），
/// 语法高亮色见 app_syntax_colors.dart（AppSyntaxColors）。
class AppColors {
  AppColors._();

  // ========== 品牌色 ==========
  /// 品牌主色（亮色主题）
  static const Color brand = Color(0xFF6366F1);

  /// 暗色主题品牌色（提高亮度保证对比度）
  static const Color brandLight = Color(0xFF818CF8);

  /// 品牌色 hover / pressed
  static const Color brandDark = Color(0xFF4F46E5);

  // ========== 语义色（亮暗通用；soft 背景色在 AppThemeData） ==========
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  /// 5xx 状态码专用（error 加深一档）
  static const Color errorStrong = Color(0xFFB91C1C);

  // ========== HTTP 方法色（亮暗通用） ==========
  static const Color methodGet = info;
  static const Color methodPost = success;
  static const Color methodPut = warning;
  static const Color methodDelete = error;
  static const Color methodPatch = Color(0xFF8B5CF6);
  static const Color methodOther = Color(0xFF64748B);

  /// HTTP 方法色唯一入口
  static Color method(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return methodGet;
      case 'POST':
        return methodPost;
      case 'PUT':
        return methodPut;
      case 'DELETE':
        return methodDelete;
      case 'PATCH':
        return methodPatch;
      default:
        return methodOther;
    }
  }

  /// 状态码颜色唯一入口
  static Color statusCode(int? statusCode) {
    if (statusCode == null) {
      return methodOther;
    }
    if (statusCode >= 200 && statusCode < 300) {
      return success;
    }
    if (statusCode >= 300 && statusCode < 400) {
      return warning;
    }
    if (statusCode >= 400 && statusCode < 500) {
      return error;
    }
    if (statusCode >= 500) {
      return errorStrong;
    }
    return methodOther;
  }
}
