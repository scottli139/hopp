import 'package:flutter/material.dart';

/// 语义颜色 ThemeExtension：随亮/暗主题变化的颜色唯一来源。
///
/// 通过 `context.appTheme` 访问（见文件末尾扩展）。数值与
/// docs/design/design_system_preview.html 的 :root / [data-theme="dark"]
/// CSS 变量一一对应；HTTP 方法色与状态码色见 app_colors.dart（AppColors）。
@immutable
class AppThemeData extends ThemeExtension<AppThemeData> {
  const AppThemeData({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.brandHover,
    required this.brandSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.info,
    required this.infoSoft,
  });

  /// 页面背景
  final Color background;

  /// 一级表面（卡片 / 侧栏 / 分组容器）
  final Color surface;

  /// 二级表面（hover / 填充 / 选中底色）
  final Color surfaceVariant;

  /// 常规分隔线 / 边框
  final Color border;

  /// 强边框（输入框边、强调分隔）
  final Color borderStrong;

  /// 主要文字
  final Color textPrimary;

  /// 次级文字
  final Color textSecondary;

  /// 占位 / 禁用文字
  final Color textTertiary;

  /// 品牌色（当前主题取值）
  final Color brand;

  /// 品牌色 hover / pressed
  final Color brandHover;

  /// 品牌色浅底（选中态 / 强调背景）
  final Color brandSoft;

  /// 成功（2xx / POST）
  final Color success;

  /// 成功浅底
  final Color successSoft;

  /// 警告（3xx / PUT）
  final Color warning;

  /// 警告浅底
  final Color warningSoft;

  /// 错误（4xx / DELETE）
  final Color error;

  /// 错误浅底
  final Color errorSoft;

  /// 信息（GET）
  final Color info;

  /// 信息浅底
  final Color infoSoft;

  static const light = AppThemeData(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC),
    surfaceVariant: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF94A3B8),
    brand: Color(0xFF6366F1),
    brandHover: Color(0xFF4F46E5),
    brandSoft: Color(0xFFEEF2FF),
    success: Color(0xFF10B981),
    successSoft: Color(0xFFECFDF5),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0xFFFFFBEB),
    error: Color(0xFFEF4444),
    errorSoft: Color(0xFFFEF2F2),
    info: Color(0xFF3B82F6),
    infoSoft: Color(0xFFEFF6FF),
  );

  static const dark = AppThemeData(
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceVariant: Color(0xFF334155),
    border: Color(0xFF2B3A55),
    borderStrong: Color(0xFF475569),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF64748B),
    brand: Color(0xFF818CF8),
    brandHover: Color(0xFF6366F1),
    brandSoft: Color(0x24818CF8),
    success: Color(0xFF10B981),
    successSoft: Color(0x2410B981),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0x24F59E0B),
    error: Color(0xFFEF4444),
    errorSoft: Color(0x24EF4444),
    info: Color(0xFF3B82F6),
    infoSoft: Color(0x243B82F6),
  );

  @override
  AppThemeData copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? brand,
    Color? brandHover,
    Color? brandSoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? error,
    Color? errorSoft,
    Color? info,
    Color? infoSoft,
  }) {
    return AppThemeData(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      brand: brand ?? this.brand,
      brandHover: brandHover ?? this.brandHover,
      brandSoft: brandSoft ?? this.brandSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
    );
  }

  @override
  AppThemeData lerp(ThemeExtension<AppThemeData>? other, double t) {
    if (other is! AppThemeData) {
      return this;
    }
    return AppThemeData(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandHover: Color.lerp(brandHover, other.brandHover, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
    );
  }
}

/// 语义颜色快捷访问：`context.appTheme.border`
extension AppThemeContext on BuildContext {
  AppThemeData get appTheme =>
      Theme.of(this).extension<AppThemeData>() ?? AppThemeData.light;
}
