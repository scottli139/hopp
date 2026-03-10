import 'package:flutter/material.dart';

/// 应用设计规范常量
class AppConstants {
  AppConstants._();

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

  // ========== HTTP 方法颜色 ==========
  static Color httpGet = const Color(0xFF3B82F6);
  static Color httpPost = const Color(0xFF10B981);
  static Color httpPut = const Color(0xFFF59E0B);
  static Color httpDelete = const Color(0xFFEF4444);
  static Color httpPatch = const Color(0xFF8B5CF6);
  static Color httpHead = const Color(0xFF6B7280);
  static Color httpOptions = const Color(0xFF6B7280);

  static Color getHttpMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return httpGet;
      case 'POST':
        return httpPost;
      case 'PUT':
        return httpPut;
      case 'DELETE':
        return httpDelete;
      case 'PATCH':
        return httpPatch;
      case 'HEAD':
        return httpHead;
      case 'OPTIONS':
        return httpOptions;
      default:
        return Colors.grey;
    }
  }

  // ========== 状态码颜色 ==========
  static Color getStatusCodeColor(int? statusCode) {
    if (statusCode == null) return Colors.grey;
    if (statusCode >= 200 && statusCode < 300) return success;
    if (statusCode >= 300 && statusCode < 400) return warning;
    if (statusCode >= 400 && statusCode < 500) return error;
    if (statusCode >= 500) return const Color(0xFFB91C1C);
    return Colors.grey;
  }

  // ========== 浅色模式中性色 ==========
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF9FAFB);
  static const Color lightSurfaceVariant = Color(0xFFF3F4F6);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);

  // ========== 深色模式中性色 ==========
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);
}

/// 应用字体规范
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';
  static const String monoFontFamily = 'JetBrains Mono';

  // ========== 显示样式 ==========
  static const TextStyle display = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.55,
  );

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

  static const TextStyle methodBadge = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // ========== 代码样式 ==========
  static const TextStyle code = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38,
    fontFamily: monoFontFamily,
  );
}

/// 组件样式预设
class AppComponentStyles {
  AppComponentStyles._();

  // ========== 按钮样式 ==========
  static ButtonStyle primaryButton(BuildContext context) {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceL,
        vertical: 10,
      ),
      minimumSize: const Size(0, AppConstants.buttonHeightM),
    );
  }

  static ButtonStyle secondaryButton(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceL,
        vertical: 10,
      ),
      minimumSize: const Size(0, AppConstants.buttonHeightM),
    );
  }

  static ButtonStyle ghostButton(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: AppColors.lightTextSecondary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: AppConstants.spaceS,
      ),
      minimumSize: const Size(0, AppConstants.buttonHeightS),
    );
  }

  // ========== 输入框样式 ==========
  static InputDecoration outlineInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.lightTextTertiary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceM,
        vertical: 10,
      ),
      isDense: true,
    );
  }

  // ========== 卡片样式 ==========
  static BoxDecoration card(BuildContext context) {
    return BoxDecoration(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      border: Border.all(color: AppColors.lightBorder),
    );
  }

  static BoxDecoration elevatedCard(BuildContext context) {
    return BoxDecoration(
      color: AppColors.lightBackground,
      borderRadius: BorderRadius.circular(AppConstants.radiusL),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // ========== HTTP 方法徽章 ==========
  static Widget httpMethodBadge(String method) {
    final color = AppColors.getHttpMethodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        method.toUpperCase(),
        style: AppTextStyles.methodBadge.copyWith(color: color),
      ),
    );
  }

  // ========== 状态码徽章 ==========
  static Widget statusCodeBadge(int? statusCode) {
    final color = AppColors.getStatusCodeColor(statusCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        '$statusCode',
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}

/// 阴影样式
class AppShadows {
  AppShadows._();

  static BoxShadow get small => BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 1),
      );

  static BoxShadow get medium => BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      );

  static BoxShadow get large => BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 16,
        offset: const Offset(0, 4),
      );
}
