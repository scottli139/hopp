import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_theme_data.dart';

/// 应用主题组装入口。
///
/// P1 说明：ColorScheme 由 fromSeed(seed 0xFF6366F1) 改为显式映射，各字段
/// 数值与 fromSeed 实际输出逐项对齐，保证本次重构零视觉变化；
/// appBarTheme / cardTheme / inputDecorationTheme / tabBarTheme 均为
/// main.dart 原样搬迁（Colors.grey.shade300/700、Colors.grey 已展开为
/// 字面色值）。textTheme / dividerTheme / popupMenuTheme 等显式映射在
/// 后续阶段（P3+）按 token 补齐。
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamilyFallback: kAppFontFamilyFallback,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF575992),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFE1E0FF),
        onPrimaryContainer: Color(0xFF13144B),
        primaryFixed: Color(0xFFE1E0FF),
        primaryFixedDim: Color(0xFFC0C1FF),
        onPrimaryFixed: Color(0xFF13144B),
        onPrimaryFixedVariant: Color(0xFF3F4178),
        secondary: Color(0xFF5D5C72),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE2E0F9),
        onSecondaryContainer: Color(0xFF191A2C),
        secondaryFixed: Color(0xFFE2E0F9),
        secondaryFixedDim: Color(0xFFC6C4DD),
        onSecondaryFixed: Color(0xFF191A2C),
        onSecondaryFixedVariant: Color(0xFF454559),
        tertiary: Color(0xFF795369),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFFFFD8EC),
        onTertiaryContainer: Color(0xFF2E1125),
        tertiaryFixed: Color(0xFFFFD8EC),
        tertiaryFixedDim: Color(0xFFE9B9D3),
        onTertiaryFixed: Color(0xFF2E1125),
        onTertiaryFixedVariant: Color(0xFF5F3C51),
        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: Color(0xFFFCF8FF),
        onSurface: Color(0xFF1B1B21),
        surfaceDim: Color(0xFFDCD9E0),
        surfaceBright: Color(0xFFFCF8FF),
        surfaceContainerLowest: Color(0xFFFFFFFF),
        surfaceContainerLow: Color(0xFFF6F2FA),
        surfaceContainer: Color(0xFFF0ECF4),
        surfaceContainerHigh: Color(0xFFEAE7EF),
        surfaceContainerHighest: Color(0xFFE4E1E9),
        onSurfaceVariant: Color(0xFF46464F),
        outline: Color(0xFF777680),
        outlineVariant: Color(0xFFC8C5D0),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF303036),
        onInverseSurface: Color(0xFFF3EFF7),
        inversePrimary: Color(0xFFC0C1FF),
        surfaceTint: Color(0xFF575992),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.brand,
        unselectedLabelColor: Color(0xFF9E9E9E),
        indicatorColor: AppColors.brand,
      ),
      extensions: const <ThemeExtension<dynamic>>[AppThemeData.light],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamilyFallback: kAppFontFamilyFallback,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFC0C1FF),
        onPrimary: Color(0xFF292A60),
        primaryContainer: Color(0xFF3F4178),
        onPrimaryContainer: Color(0xFFE1E0FF),
        primaryFixed: Color(0xFFE1E0FF),
        primaryFixedDim: Color(0xFFC0C1FF),
        onPrimaryFixed: Color(0xFF13144B),
        onPrimaryFixedVariant: Color(0xFF3F4178),
        secondary: Color(0xFFC6C4DD),
        onSecondary: Color(0xFF2E2F42),
        secondaryContainer: Color(0xFF454559),
        onSecondaryContainer: Color(0xFFE2E0F9),
        secondaryFixed: Color(0xFFE2E0F9),
        secondaryFixedDim: Color(0xFFC6C4DD),
        onSecondaryFixed: Color(0xFF191A2C),
        onSecondaryFixedVariant: Color(0xFF454559),
        tertiary: Color(0xFFE9B9D3),
        onTertiary: Color(0xFF46263A),
        tertiaryContainer: Color(0xFF5F3C51),
        onTertiaryContainer: Color(0xFFFFD8EC),
        tertiaryFixed: Color(0xFFFFD8EC),
        tertiaryFixedDim: Color(0xFFE9B9D3),
        onTertiaryFixed: Color(0xFF2E1125),
        onTertiaryFixedVariant: Color(0xFF5F3C51),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF131318),
        onSurface: Color(0xFFE4E1E9),
        surfaceDim: Color(0xFF131318),
        surfaceBright: Color(0xFF39383F),
        surfaceContainerLowest: Color(0xFF0E0E13),
        surfaceContainerLow: Color(0xFF1B1B21),
        surfaceContainer: Color(0xFF1F1F25),
        surfaceContainerHigh: Color(0xFF2A292F),
        surfaceContainerHighest: Color(0xFF35343A),
        onSurfaceVariant: Color(0xFFC8C5D0),
        outline: Color(0xFF918F9A),
        outlineVariant: Color(0xFF46464F),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFE4E1E9),
        onInverseSurface: Color(0xFF303036),
        inversePrimary: Color(0xFF575992),
        surfaceTint: Color(0xFFC0C1FF),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF616161)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF616161)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.brandLight, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.brandLight,
        unselectedLabelColor: Color(0xFF9E9E9E),
        indicatorColor: AppColors.brandLight,
      ),
      extensions: const <ThemeExtension<dynamic>>[AppThemeData.dark],
    );
  }
}
