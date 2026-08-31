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

    setUp(() {
      mockStorageService = MockStorageService();
      when(mockStorageService.getSettings()).thenAnswer(
        (_) async => const AppSettings(
          aiEnabled: true,
          aiProviderPreset: 'ollama',
          aiBaseUrl: 'http://localhost:11434/v1',
          aiModel: 'qwen2.5:7b',
          aiApiKey: 'secret-key',
        ),
      );
      when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});
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
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
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

    testWidgets('renders all five fields with current settings',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await openDialog(tester, container);

      // 开关 + 预设 + 三个输入框标签
      expect(find.text('启用本地 AI'), findsOneWidget);
      expect(find.text('Provider 预设'), findsOneWidget);
      expect(find.text('Base URL'), findsOneWidget);
      expect(find.text('Model'), findsOneWidget);
      expect(find.text('API Key'), findsOneWidget);
      expect(find.text('Ollama'), findsOneWidget);
      expect(find.text('LM Studio'), findsOneWidget);
      expect(find.text('自定义'), findsOneWidget);
      expect(
        find.text('本地模型通常无需 Key，留空即可；仅 Tier 2 云端使用'),
        findsOneWidget,
      );
      expect(find.text('尚未检查连接'), findsOneWidget);
      expect(find.text('检查连接'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);

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
      final keyField =
          tester.widget<TextField>(find.byKey(const Key('ai_api_key_field')));
      expect(keyField.controller!.text, 'secret-key');
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

      // 自定义：不覆盖手填值
      await tester.tap(find.text('自定义'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ai_base_url_field')))
            .controller!
            .text,
        'http://localhost:1234/v1',
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
      expect(saved.aiApiKey, 'secret-key');

      expect(find.byKey(const Key('ai_settings_dialog')), findsNothing);
    });

    testWidgets('check connection success shows connected row', (tester) async {
      final container = buildContainer(llmClient: FakeLlmClient());
      addTearDown(container.dispose);
      await openDialog(tester, container);

      await tester.tap(find.text('检查连接'));
      await tester.pumpAndSettle();

      expect(find.text('已连接 · Ollama · qwen2.5:7b'), findsOneWidget);
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

      await tester.tap(find.text('检查连接'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '未检测到本地模型服务，请确认 Ollama / LM Studio 已启动（connection refused）',
        ),
        findsOneWidget,
      );
      // 失败后仍可再次检查
      expect(find.text('检查连接'), findsOneWidget);
    });
  });
}
