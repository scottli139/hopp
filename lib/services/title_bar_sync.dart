import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme_data.dart';
import '../utils/app_logger.dart';

/// Linux 原生标题栏主题同步。
///
/// Linux runner 使用自定义 GtkBox 标题栏（Deepin GTK3 补丁锁定了
/// GtkHeaderBar 的绘制，详见 my_application.cc 注释）。这里把主题态换算成
/// prefer-dark + token 颜色，通过 com.example.hopp/window 通道的
/// updateTitleBar 方法下发给 Linux runner。
class TitleBarSync {
  static const MethodChannel _channel =
      MethodChannel('com.example.hopp/window');

  /// 由 ThemeMode + 平台亮度解析当前是否暗色（纯函数，便于单测）
  static bool resolveDark(ThemeMode mode, Brightness platformBrightness) {
    return mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);
  }

  /// 构造 updateTitleBar 通道参数（纯函数，便于单测）
  static Map<String, Object> buildArgs({required bool dark}) {
    final theme = dark ? AppThemeData.dark : AppThemeData.light;
    return {
      'dark': dark,
      'background': _hex(theme.surface),
      'foreground': _hex(theme.textPrimary),
      'separator': _hex(theme.border),
    };
  }

  /// 下发到原生侧；未实现的平台 / 单元测试环境静默降级
  static Future<void> sync({required bool dark}) async {
    try {
      await _channel.invokeMethod('updateTitleBar', buildArgs(dark: dark));
    } on Exception catch (e) {
      AppLogger.warning('[TitleBarSync] updateTitleBar failed: $e');
    }
  }

  static String _hex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
