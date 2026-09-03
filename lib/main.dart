import 'dart:io' show Directory, Platform;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'providers/providers.dart';
import 'screens/main_screen.dart';
import 'services/menu_channel.dart';
import 'services/single_instance_lock.dart';
import 'services/storage_service.dart';
import 'services/title_bar_sync.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/l10n.dart';
import 'theme/app_theme.dart';
import 'utils/app_logger.dart';
import 'utils/testing/test_helpers.dart';
import 'utils/testing/ui_test_mode.dart';
import 'widgets/common/shortcut_wrapper.dart';
import 'widgets/single_instance_notice_app.dart';

// 存储启动参数，供测试模式使用
List<String> appArgs = [];

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 保存启动参数
  appArgs = args;

  // Initialize logging first
  await AppLogger.initialize();

  // Initialize storage
  final storage = StorageService();
  // test-mode 隔离必须由 main() 显式传入：Flutter Linux release 下
  // Platform.executableArguments 拿不到 argv（2026-09-02 事故根因）
  final testMode = args.contains('--test-mode') || args.contains('--ui-test');

  // TD-7 单实例保护：对数据目录加 OS 级文件锁（Hive 非跨进程安全，双开会
  // 清空 box——2026-08-28 / 2026-09-02 两次事故）。锁随进程退出自动释放；
  // test-mode 数据目录独立，与用户实例互不干扰。
  final appDir = await getApplicationDocumentsDirectory();
  final instanceLock = SingleInstanceLock();
  final acquired = await instanceLock.tryAcquire(
    Directory(
        '${appDir.path}/${StorageService.dataDirNameFor(testMode: testMode)}'),
  );
  if (!acquired) {
    AppLogger.warning('[main] Another instance is already running');
    runApp(const SingleInstanceNoticeApp());
    return;
  }

  await storage.initialize(testMode: testMode);

  // Create ProviderContainer for menu channel
  final container = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
    ],
  );

  // Initialize menu channel (for macOS system menu)
  MenuChannelService.initialize(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HoppApp(),
    ),
  );
}

class HoppApp extends ConsumerStatefulWidget {
  const HoppApp({super.key});

  @override
  ConsumerState<HoppApp> createState() => _HoppAppState();
}

class _HoppAppState extends ConsumerState<HoppApp> {
  /// 上次已同步到原生标题栏的暗色态（避免重复下调通道）
  bool? _lastTitleBarDark;

  @override
  void initState() {
    super.initState();
    // 初始化 UI 测试模式
    _initTestMode();
  }

  Future<void> _initTestMode() async {
    await UITestModeManager().initialize(appArgs, ref);
  }

  /// F5.8：把当前主题态同步给 Linux 原生标题栏（GTK headerbar 不跟随
  /// Flutter 主题，需显式下发 prefer-dark + token 颜色）。
  void _syncTitleBarTheme(ThemeMode mode, Brightness platformBrightness) {
    if (!Platform.isLinux) {
      return;
    }
    final dark = TitleBarSync.resolveDark(mode, platformBrightness);
    if (dark == _lastTitleBarDark) {
      return;
    }
    _lastTitleBarDark = dark;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => TitleBarSync.sync(dark: dark));
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Hopp',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // F5.9：null 表示跟随系统（'system' 档），由 localeResolutionCallback 解析
      locale: ref.watch(localeProvider),
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return const Locale('en');
        for (final s in supported) {
          if (s.languageCode == locale.languageCode) return s;
        }
        return const Locale('en');
      },
      builder: (context, child) {
        // F5.7 界面缩放：全局文字缩放（Linux HiDPI 等系统缩放不生效场景）
        final uiScale = ref.watch(uiScaleProvider);
        // F5.9：无 context 场景（services/providers）取词桥随 locale 刷新
        L10nBridge.update(context.l10n);
        // F5.8：Linux 原生标题栏主题同步（此处 MediaQuery 必定在作用域内，
        // 根级 platformBrightnessOf 无 MediaQuery 时会静默回退 light）
        _syncTitleBarTheme(themeMode, MediaQuery.platformBrightnessOf(context));
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(uiScale)),
          child: RepaintBoundary(
            key: appRepaintBoundaryKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const ShortcutWrapper(
        child: MainScreen(),
      ),
    );
  }
}
