import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/settings/settings_provider.dart';
import 'package:hopp/widgets/settings/app_settings_dialog.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/test_app.dart';
import '../../mocks/service_mocks.mocks.dart';

void main() {
  group('AppSettingsDialog (F5.9)', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenAnswer((_) async => AppSettings.defaults());
      when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});
    });

    ProviderContainer buildContainer() {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );
      container.read(settingsProvider);
      return container;
    }

    Future<void> openDialog(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: hoppTestApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => openAppSettingsDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders theme / language / ui scale rows', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('UI Scale'), findsOneWidget);
      // 语言当前值（默认 system）
      expect(find.text('System'), findsWidgets);
    });

    testWidgets('switching language persists via storage', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      // 打开语言下拉（触发器显示当前值 System）
      await tester.tap(find.text('System').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文').last);
      await tester.pumpAndSettle();

      final saved = verify(mockStorageService.saveSettings(captureAny))
          .captured
          .last as AppSettings;
      expect(saved.language, 'zh');
      expect(container.read(settingsProvider).valueOrNull?.language, 'zh');
      // localeProvider 跟随更新
      expect(container.read(localeProvider), const Locale('zh'));
    });

    testWidgets('switching ui scale persists via storage', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.tap(find.text('100%'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('150%').last);
      await tester.pumpAndSettle();

      final saved = verify(mockStorageService.saveSettings(captureAny))
          .captured
          .last as AppSettings;
      expect(saved.uiScale, 1.5);
    });

    testWidgets('zh locale renders Chinese labels', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: hoppTestApp(
            locale: const Locale('zh'),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => openAppSettingsDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('语言'), findsOneWidget);
      expect(find.text('界面缩放'), findsOneWidget);
    });
  });
}
