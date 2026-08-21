import 'package:flutter/material.dart';

/// 语法高亮配色（JSON/XML 等代码视图共用）。
///
/// 由 code_editor.dart 与 optimized_response_viewer.dart 中两份逐字重复
/// 的定义合并而来（2026-08-21，P1）。亮/暗取值保持合并前原值，零视觉变化。
class AppSyntaxColors {
  AppSyntaxColors._();

  // Key - 深蓝色 (Blue 800)
  static const key = Color(0xFF1E40AF);

  // String - 深绿色 (Green 700)
  static const string = Color(0xFF15803D);

  // Number - 蓝色 (Blue 600)
  static const number = Color(0xFF2563EB);

  // Boolean/Null - 紫色 (Violet 600)
  static const keyword = Color(0xFF7C3AED);

  // Punctuation - 灰色 (Gray 500)
  static const punctuation = Color(0xFF6B7280);

  // ========== 深色模式适配 ==========
  static Color getKey(bool isDark) => isDark ? const Color(0xFF93C5FD) : key;
  static Color getString(bool isDark) =>
      isDark ? const Color(0xFF86EFAC) : string;
  static Color getNumber(bool isDark) =>
      isDark ? const Color(0xFF60A5FA) : number;
  static Color getKeyword(bool isDark) =>
      isDark ? const Color(0xFFC4B5FD) : keyword;
  static Color getPunctuation(bool isDark) =>
      isDark ? const Color(0xFF9CA3AF) : punctuation;
}
