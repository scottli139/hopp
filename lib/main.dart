import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';
import 'screens/main_screen.dart';
import 'services/menu_channel.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_logger.dart';
import 'utils/testing/test_helpers.dart';
import 'utils/testing/ui_test_mode.dart';
import 'widgets/common/shortcut_wrapper.dart';

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
  await storage.initialize();

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
  @override
  void initState() {
    super.initState();
    // 初始化 UI 测试模式
    _initTestMode();
  }

  Future<void> _initTestMode() async {
    await UITestModeManager().initialize(appArgs, ref);
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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh', 'CN'),
      ],
      builder: (context, child) => RepaintBoundary(
        key: appRepaintBoundaryKey,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const ShortcutWrapper(
        child: MainScreen(),
      ),
    );
  }
}
