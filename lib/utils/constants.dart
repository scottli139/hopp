import 'package:flutter/material.dart';

/// 应用设计规范常量
class AppConstants {
  AppConstants._();

  /// 应用版本号兜底值（与 pubspec.yaml `version` 保持一致，
  /// 由 test/app_version_test.dart 守护同步）。
  ///
  /// 正常运行时版本号由 package_info_plus 从应用包信息读取
  /// （见 appVersionProvider），此常量仅在该读取失败（如单元测试
  /// 环境）时使用。
  static const String appVersion = '0.7.0';

  // ========== 间距系统 ==========
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;
  static const double spaceXXXL = 48.0;

  // ========== 圆角系统 ==========
  static const double radiusS = 4.0;
  static const double radiusM = 6.0;
  static const double radiusL = 8.0;
  static const double radiusXL = 12.0;

  // ========== 组件高度 ==========
  static const double buttonHeightS = 28.0;
  static const double buttonHeightM = 36.0;
  static const double buttonHeightL = 44.0;

  static const double inputHeightS = 28.0;
  static const double inputHeightM = 36.0;
  static const double inputHeightL = 44.0;

  static const double sidebarItemHeight = 32.0;
  static const double tabHeight = 36.0;
  static const double statusBarHeight = 28.0;
  static const double appBarHeight = 48.0;

  // ========== 布局尺寸 ==========
  static const double sidebarMinWidth = 200.0;
  static const double sidebarDefaultFlex = 0.22;
  static const double sidebarMinFlex = 0.15;
  static const double sidebarMaxFlex = 0.40;

  // ========== 动画时长 ==========
  static const Duration animFast = Duration(milliseconds: 100);
  static const Duration animNormal = Duration(milliseconds: 200);
  static const Duration animSlow = Duration(milliseconds: 300);

  // ========== 缓动曲线 ==========
  static const Curve animCurve = Curves.easeInOut;
  static const Curve animSpring = Curves.easeOutBack;
}

/// 应用颜色系统
///
/// 注意：HTTP 方法色 / 状态码色已迁至 lib/theme/app_colors.dart
/// （`AppColors.method()` / `AppColors.statusCode()` 唯一入口）；
/// 随主题变化的中性色见 lib/theme/app_theme_data.dart（AppThemeData）。
/// 本类的存量成员将在 P3–P5 逐步收敛删除。
class AppColors {
  AppColors._();

  // ========== 主色调 ==========
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF8B5CF6);

  // ========== 功能色 ==========
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ========== 浅色模式中性色 ==========
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF9FAFB);
  static const Color lightSurfaceVariant = Color(0xFFF3F4F6);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
}

/// 应用字体规范
class AppTextStyles {
  AppTextStyles._();

  // ========== 显示样式 ==========
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // ========== 正文样式 ==========
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38,
  );

  // ========== 辅助样式 ==========
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );

  static const TextStyle tiny = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.27,
  );
}
