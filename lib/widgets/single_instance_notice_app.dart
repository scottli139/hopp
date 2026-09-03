import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/l10n.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_data.dart';
import 'common/app_button.dart';

/// TD-7 单实例保护：第二实例的提示壳。
///
/// 检测到另一实例持有数据目录锁时，main() 启动本壳替代主界面——此时 Hive
/// 尚未初始化（拿不到用户设置，语言跟随系统 locale），仅展示说明 + 退出按钮。
class SingleInstanceNoticeApp extends StatelessWidget {
  const SingleInstanceNoticeApp({super.key, this.onQuit});

  /// 退出动作（默认 `exit(0)`）；测试注入以避免杀掉 test runner
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _NoticeScreen(onQuit: onQuit ?? () => exit(0)),
    );
  }
}

class _NoticeScreen extends StatelessWidget {
  const _NoticeScreen({required this.onQuit});

  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: t.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppMetrics.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 40, color: t.warning),
                const SizedBox(height: AppMetrics.space16),
                Text(
                  l10n.singleInstance_title,
                  style: AppTextStyles.title16.copyWith(color: t.textPrimary),
                ),
                const SizedBox(height: AppMetrics.space12),
                Text(
                  l10n.singleInstance_message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body13.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: AppMetrics.space24),
                AppButton.primary(label: l10n.common_quit, onPressed: onQuit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
