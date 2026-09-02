import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/services/title_bar_sync.dart';

void main() {
  group('TitleBarSync.resolveDark', () {
    test('dark 模式始终为暗色', () {
      expect(
        TitleBarSync.resolveDark(ThemeMode.dark, Brightness.light),
        isTrue,
      );
      expect(
        TitleBarSync.resolveDark(ThemeMode.dark, Brightness.dark),
        isTrue,
      );
    });

    test('light 模式始终为亮色', () {
      expect(
        TitleBarSync.resolveDark(ThemeMode.light, Brightness.dark),
        isFalse,
      );
      expect(
        TitleBarSync.resolveDark(ThemeMode.light, Brightness.light),
        isFalse,
      );
    });

    test('system 模式跟随平台亮度', () {
      expect(
        TitleBarSync.resolveDark(ThemeMode.system, Brightness.dark),
        isTrue,
      );
      expect(
        TitleBarSync.resolveDark(ThemeMode.system, Brightness.light),
        isFalse,
      );
    });
  });

  group('TitleBarSync.buildArgs', () {
    test('暗色输出 dark token 颜色', () {
      final args = TitleBarSync.buildArgs(dark: true);
      expect(args['dark'], isTrue);
      expect(args['background'], '#1E293B'); // AppThemeData.dark.surface
      expect(args['foreground'], '#F1F5F9'); // AppThemeData.dark.textPrimary
      expect(args['separator'], '#2B3A55'); // AppThemeData.dark.border
    });

    test('亮色输出 light token 颜色', () {
      final args = TitleBarSync.buildArgs(dark: false);
      expect(args['dark'], isFalse);
      expect(args['background'], '#F8FAFC'); // AppThemeData.light.surface
      expect(args['foreground'], '#0F172A'); // AppThemeData.light.textPrimary
      expect(args['separator'], '#E2E8F0'); // AppThemeData.light.border
    });
  });
}
