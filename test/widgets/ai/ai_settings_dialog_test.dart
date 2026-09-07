import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';
import 'package:hopp/providers/ai/ai_provider.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/settings/settings_provider.dart';
import 'package:hopp/services/ai/llm_client.dart';
import 'package:hopp/widgets/ai/ai_settings_dialog.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/test_app.dart';
import '../../mocks/service_mocks.mocks.dart';

class FakeLlmClient extends LlmClient {
  FakeLlmClient({this.error});

  final LlmException? error;

  @override
  Future<String> chat({
    required String baseUrl,
    required String model,
    required String apiKey,
    required List<LlmMessage> messages,
  }) async {
    if (error != null) throw error!;
    return 'pong';
  }
}

void main() {
  group('AiSettingsDialog', () {
    late MockStorageService mockStorageService;

    void stubSettings(AppSettings settings) {
      when(mockStorageService.getSettings()).thenAnswer((_) async => settings);
      when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});
      when(mockStorageService.readAiKey(any)).thenAnswer((_) async => '');
      when(mockStorageService.writeAiKey(any, any)).thenAnswer((_) async {});
      when(mockStorageService.deleteAiKey(any)).thenAnswer((_) async {});
    }

    setUp(() {
      mockStorageService = MockStorageService();
      stubSettings(const AppSettings(
        aiEnabled: true,
        aiProviderPreset: 'ollama',
        aiBaseUrl: 'http://localhost:11434/v1',
        aiModel: 'qwen2.5:7b',
      ));
    });

    ProviderContainer buildContainer({FakeLlmClient? llmClient}) {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
          if (llmClient != null) llmClientProvider.overrideWithValue(llmClient),
        ],
      );
      // 预触发 settings 加载，避免对话框 initState 读到 loading 态
      container.read(settingsProvider);
      return container;
    }

    Future<void> openDialog(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      // 内容变高（两组分段 + key 说明条），放大 test surface 保证底部按钮可点
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: hoppTestApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => openAiSettingsDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai_settings_dialog')), findsOneWidget);
    }

    testWidgets('renders tier groups and fields with current settings',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      // 开关 + 预设两组分段 + 三个输入框标签
      expect(find.text('Enable AI Assistant'), findsOneWidget);
      expect(find.text('Provider Preset'), findsOneWidget);
      expect(find.text('LOCAL'), findsOneWidget);
      expect(find.text('Data stays on device'), findsOneWidget);
      expect(find.text('CLOUD · BYOK'), findsOneWidget);
      expect(find.text('⚠ Data leaves device'), findsOneWidget);
      expect(find.text('Base URL'), findsOneWidget);
      expect(find.text('Model'), findsOneWidget);
      expect(find.text('API Key'), findsOneWidget);
      expect(find.text('Ollama'), findsOneWidget);
      expect(find.text('LM Studio'), findsOneWidget);
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('DeepSeek'), findsOneWidget);
      expect(find.text('Anthropic'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(
        find.text(
            'Keys are stored with app-level AES encryption (same scheme as secret variables) and are write-only'),
        findsOneWidget,
      );
      expect(find.text('Reset consent'), findsOneWidget);
      expect(find.text('Connection not checked yet'), findsOneWidget);
      expect(find.text('Check Connection'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // 初始值来自 settingsProvider
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ai_base_url_field')))
            .controller!
            .text,
        'http://localhost:11434/v1',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ai_model_field')))
            .controller!
            .text,
        'qwen2.5:7b',
      );
      // F9.9：Key 只写不读，controller 恒空开场
      final keyField =
          tester.widget<TextField>(find.byKey(const Key('ai_api_key_field')));
      expect(keyField.controller!.text, isEmpty);
      expect(keyField.obscureText, isTrue); // 默认脱敏
    });

    testWidgets('tapping preset fills base url', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.tap(find.text('LM Studio'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ai_base_url_field')))
            .controller!
            .text,
        'http://localhost:1234/v1',
      );

      // 云端预设自动填官方端点
      await tester.tap(find.text('OpenAI'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ai_base_url_field')))
            .controller!
            .text,
        'https://api.openai.com/v1',
      );

      // 自定义：不覆盖手填值
      await tester.tap(find.text('Custom'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ai_base_url_field')))
            .controller!
            .text,
        'https://api.openai.com/v1',
      );
    });

    testWidgets('custom url remembered per preset when switching (F9.9)',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      String currentUrl() => tester
          .widget<TextField>(find.byKey(const Key('ai_base_url_field')))
          .controller!
          .text;

      // 自定义填 moonshot
      await tester.tap(find.text('Custom'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('ai_base_url_field')),
        'https://api.moonshot.cn/v1',
      );

      // 切 DeepSeek → 官方端点；切回自定义 → 恢复 moonshot
      await tester.tap(find.text('DeepSeek'));
      await tester.pump();
      expect(currentUrl(), 'https://api.deepseek.com/v1');
      await tester.tap(find.text('Custom'));
      await tester.pump();
      expect(currentUrl(), 'https://api.moonshot.cn/v1');

      // 保存后按预设持久化（custom 非 loopback 视为云端，需先填 key）
      await tester.enterText(
        find.byKey(const Key('ai_api_key_field')),
        'sk-moonshot',
      );
      await tester.tap(find.byKey(const Key('ai_settings_save_button')));
      await tester.pumpAndSettle();

      verify(mockStorageService.writeAiKey('custom', 'sk-moonshot')).called(1);
      final captured =
          verify(mockStorageService.saveSettings(captureAny)).captured;
      final saved = captured.last as AppSettings;
      expect(saved.aiPresetBaseUrls['custom'], 'https://api.moonshot.cn/v1');
      expect(saved.aiPresetBaseUrls['ollama'], 'http://localhost:11434/v1');
    });

    testWidgets('persisted per-preset url restores on preset tap',
        (tester) async {
      stubSettings(const AppSettings(
        aiEnabled: true,
        aiProviderPreset: 'openai',
        aiBaseUrl: 'https://api.openai.com/v1',
        aiModel: 'gpt-4o-mini',
        aiKeySavedPresets: ['openai'],
        aiPresetBaseUrls: {'custom': 'https://my-gateway.example.com/v1'},
      ));
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.tap(find.text('Custom'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ai_base_url_field')))
            .controller!
            .text,
        'https://my-gateway.example.com/v1',
      );
    });

    testWidgets('save persists via updateAiSettings and closes dialog',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.enterText(
        find.byKey(const Key('ai_model_field')),
        'llama3.1:8b',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai_settings_save_button')));
      await tester.pumpAndSettle();

      final captured =
          verify(mockStorageService.saveSettings(captureAny)).captured;
      expect(captured, hasLength(1));
      final saved = captured.single as AppSettings;
      expect(saved.aiEnabled, isTrue);
      expect(saved.aiProviderPreset, 'ollama');
      expect(saved.aiBaseUrl, 'http://localhost:11434/v1');
      expect(saved.aiModel, 'llama3.1:8b');
      // 未输入 key：不写加密 box、标志位不变
      verifyNever(mockStorageService.writeAiKey(any, any));
      expect(saved.aiKeySavedPresets, isEmpty);

      expect(find.byKey(const Key('ai_settings_dialog')), findsNothing);
    });

    testWidgets('entering a key writes encrypted box and sets flag',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.enterText(
        find.byKey(const Key('ai_api_key_field')),
        'sk-new-key',
      );
      await tester.tap(find.byKey(const Key('ai_settings_save_button')));
      await tester.pumpAndSettle();

      verify(mockStorageService.writeAiKey('ollama', 'sk-new-key')).called(1);
      final captured =
          verify(mockStorageService.saveSettings(captureAny)).captured;
      final saved = captured.last as AppSettings;
      expect(saved.aiKeySavedPresets, contains('ollama'));
      // key 不落 AppSettings 明文字段
      expect(saved.aiApiKey, isEmpty);
    });

    testWidgets('cloud preset without key blocks save with error',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.tap(find.text('OpenAI'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('ai_settings_save_button')));
      await tester.pump();

      expect(find.text('Cloud providers require an API Key'), findsOneWidget);
      // 对话框未关闭，未落库
      expect(find.byKey(const Key('ai_settings_dialog')), findsOneWidget);
      verifyNever(mockStorageService.saveSettings(any));

      // 输入 key 后错误解除并可保存
      await tester.enterText(
        find.byKey(const Key('ai_api_key_field')),
        'sk-openai',
      );
      await tester.tap(find.byKey(const Key('ai_settings_save_button')));
      await tester.pumpAndSettle();
      verify(mockStorageService.writeAiKey('openai', 'sk-openai')).called(1);
      expect(find.byKey(const Key('ai_settings_dialog')), findsNothing);
    });

    testWidgets('saved key shows encrypted note; clear removes it',
        (tester) async {
      stubSettings(const AppSettings(
        aiEnabled: true,
        aiProviderPreset: 'openai',
        aiBaseUrl: 'https://api.openai.com/v1',
        aiModel: 'gpt-4o-mini',
        aiKeySavedPresets: ['openai'],
      ));
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      // 已存说明条可见
      expect(
        find.textContaining('Saved with app-level AES encryption'),
        findsOneWidget,
      );
      expect(find.text('Clear'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      verify(mockStorageService.deleteAiKey('openai')).called(1);
      final captured =
          verify(mockStorageService.saveSettings(captureAny)).captured;
      final saved = captured.last as AppSettings;
      expect(saved.aiKeySavedPresets, isNot(contains('openai')));
    });

    testWidgets('reset consent button clears cloud consents', (tester) async {
      stubSettings(const AppSettings(
        aiEnabled: true,
        aiProviderPreset: 'openai',
        aiBaseUrl: 'https://api.openai.com/v1',
        aiModel: 'gpt-4o-mini',
        aiKeySavedPresets: ['openai'],
        aiCloudConsents: {'openai': true},
      ));
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.tap(find.byKey(const Key('ai_reset_consent_button')));
      await tester.pumpAndSettle();

      final captured =
          verify(mockStorageService.saveSettings(captureAny)).captured;
      final saved = captured.last as AppSettings;
      expect(saved.aiCloudConsents, isEmpty);
    });

    testWidgets('check connection success shows connected row', (tester) async {
      final container = buildContainer(llmClient: FakeLlmClient());
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.tap(find.text('Check Connection'));
      await tester.pumpAndSettle();

      expect(find.text('Connected · Ollama · qwen2.5:7b'), findsOneWidget);
      // 本地预设不过隐私门
      expect(find.byKey(const Key('ai_privacy_gate')), findsNothing);
    });

    testWidgets('cloud check connection passes privacy gate first',
        (tester) async {
      stubSettings(const AppSettings(
        aiEnabled: true,
        aiProviderPreset: 'openai',
        aiBaseUrl: 'https://api.openai.com/v1',
        aiModel: 'gpt-4o-mini',
        aiKeySavedPresets: ['openai'],
      ));
      when(mockStorageService.readAiKey('openai'))
          .thenAnswer((_) async => 'sk-saved');
      final container = buildContainer(llmClient: FakeLlmClient());
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.tap(find.text('Check Connection'));
      await tester.pumpAndSettle();

      // 先弹隐私门；同意后继续检查连接
      expect(find.byKey(const Key('ai_privacy_gate')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ai_gate_agree_button')));
      await tester.pumpAndSettle();

      expect(find.text('Connected · OpenAI · gpt-4o-mini'), findsOneWidget);
    });

    testWidgets('check connection failure shows warning and keeps detail',
        (tester) async {
      final container = buildContainer(
        llmClient: FakeLlmClient(
          error: LlmConnectionException('connection refused'),
        ),
      );
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.tap(find.text('Check Connection'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Local model service not detected. Make sure Ollama / LM Studio is running (connection refused)',
        ),
        findsOneWidget,
      );
      // 失败后仍可再次检查
      expect(find.text('Check Connection'), findsOneWidget);
    });
  });
}
