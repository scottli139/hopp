import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/settings/settings_provider.dart';
import 'package:hopp/widgets/ai/ai_privacy_gate.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/test_app.dart';
import '../../mocks/service_mocks.mocks.dart';

/// F9.9 首次外发隐私门：本地直通 / 云端未确认弹门（同意记录、取消中断）/
/// 已确认直通 / custom loopback 视为本地。
void main() {
  group('ensureAiCloudConsent', () {
    late MockStorageService mockStorageService;

    AppSettings settingsFor({
      String preset = 'openai',
      String baseUrl = 'https://api.openai.com/v1',
      Map<String, bool> consents = const {},
    }) =>
        AppSettings(
          aiEnabled: true,
          aiProviderPreset: preset,
          aiBaseUrl: baseUrl,
          aiModel: 'gpt-4o-mini',
          aiKeySavedPresets: const ['openai'],
          aiCloudConsents: consents,
        );

    void stubSettings(AppSettings settings) {
      when(mockStorageService.getSettings()).thenAnswer((_) async => settings);
      when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});
    }

    setUp(() {
      mockStorageService = MockStorageService();
    });

    /// 宿主：按钮触发 ensureAiCloudConsent 并捕获返回值
    Future<void> pumpHost(
      WidgetTester tester,
      ProviderContainer container,
      void Function(bool?) onResult,
    ) async {
      // 门内容偏高，放大 test surface 保证按钮可点
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: hoppTestApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () async {
                    final result = await ensureAiCloudConsent(
                      context,
                      ref,
                      capability: 'test capability',
                    );
                    onResult(result);
                  },
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      );
      // 等 settingsProvider 异步加载完成，再交由用例点击触发
      await tester.pumpAndSettle();
    }

    ProviderContainer buildContainer() {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService)
        ],
      );
      container.read(settingsProvider);
      return container;
    }

    testWidgets('本地预设直接放行，不弹门', (tester) async {
      stubSettings(settingsFor(
        preset: 'ollama',
        baseUrl: 'http://localhost:11434/v1',
      ));
      final container = buildContainer();
      addTearDown(container.dispose);

      bool? result;
      await pumpHost(tester, container, (r) => result = r);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byKey(const Key('ai_privacy_gate')), findsNothing);
    });

    testWidgets('custom 指向 loopback 视为本地，直接放行', (tester) async {
      stubSettings(settingsFor(
        preset: 'custom',
        baseUrl: 'http://127.0.0.1:9000/v1',
      ));
      final container = buildContainer();
      addTearDown(container.dispose);

      bool? result;
      await pumpHost(tester, container, (r) => result = r);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byKey(const Key('ai_privacy_gate')), findsNothing);
    });

    testWidgets('云端未确认弹门；同意后记录确认并放行', (tester) async {
      stubSettings(settingsFor());
      final container = buildContainer();
      addTearDown(container.dispose);

      bool? result;
      await pumpHost(tester, container, (r) => result = r);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      // 门出现，内容要点齐全
      expect(find.byKey(const Key('ai_privacy_gate')), findsOneWidget);
      expect(find.text('Confirm before sending to cloud'), findsOneWidget);
      expect(find.text('test capability'), findsOneWidget);
      expect(
        find.text('POST https://api.openai.com/v1/chat/completions'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('ai_gate_agree_button')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      final captured =
          verify(mockStorageService.saveSettings(captureAny)).captured;
      final saved = captured.last as AppSettings;
      expect(saved.aiCloudConsents['openai'], isTrue);
    });

    testWidgets('云端未确认弹门；取消则中断且不落确认', (tester) async {
      stubSettings(settingsFor());
      final container = buildContainer();
      addTearDown(container.dispose);

      bool? result;
      await pumpHost(tester, container, (r) => result = r);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai_privacy_gate')), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      verifyNever(mockStorageService.saveSettings(any));
      // toast 提示
      expect(
        find.text('Cancelled — nothing is sent to the cloud before consent'),
        findsOneWidget,
      );
    });

    testWidgets('云端已确认直接放行，不弹门', (tester) async {
      stubSettings(settingsFor(consents: const {'openai': true}));
      final container = buildContainer();
      addTearDown(container.dispose);

      bool? result;
      await pumpHost(tester, container, (r) => result = r);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byKey(const Key('ai_privacy_gate')), findsNothing);
    });
  });
}
