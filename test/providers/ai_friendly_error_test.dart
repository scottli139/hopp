import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';
import 'package:hopp/providers/ai/ai_provider.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/settings/settings_provider.dart';
import 'package:hopp/services/ai/llm_client.dart';
import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

class _ErrClient extends LlmClient {
  _ErrClient(this.error);

  final LlmException error;

  @override
  Future<String> chat({
    required String baseUrl,
    required String model,
    required String apiKey,
    required List<LlmMessage> messages,
  }) async =>
      throw error;
}

/// F9.9：云端 HTTP 错误的用户可读文案映射（401 / 429 / 其他 5xx）。
/// 单测不挂界面，L10nBridge 回退英文。
void main() {
  late MockStorageService mockStorageService;

  ProviderContainer buildContainer(LlmClient client) {
    mockStorageService = MockStorageService();
    when(mockStorageService.getSettings()).thenAnswer(
      (_) async => const AppSettings(
        aiEnabled: true,
        aiProviderPreset: 'openai',
        aiBaseUrl: 'https://api.openai.com/v1',
        aiModel: 'gpt-4o-mini',
        aiKeySavedPresets: ['openai'],
      ),
    );
    when(mockStorageService.readAiKey(any)).thenAnswer((_) async => 'sk-t');
    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorageService),
        llmClientProvider.overrideWithValue(client),
      ],
    );
    container.read(settingsProvider);
    return container;
  }

  Future<String?> explainAndGetError(ProviderContainer container) async {
    // 等 settings 加载完成（StateNotifierProvider 无 .future，显式 await 加载）
    await container.read(settingsProvider.notifier).loadSettings();
    await container
        .read(explainProvider.notifier)
        .explain(statusCode: 200, statusText: 'OK', body: '{}');
    return container.read(explainProvider).errorMessage;
  }

  test('401 → Key 无效或未配置', () async {
    final container =
        buildContainer(_ErrClient(LlmHttpException(401, 'invalid api key')));
    addTearDown(container.dispose);
    expect(
      await explainAndGetError(container),
      'Invalid or missing API Key (401); check AI Settings',
    );
  });

  test('429 → 配额不足或限流', () async {
    final container =
        buildContainer(_ErrClient(LlmHttpException(429, 'rate limit')));
    addTearDown(container.dispose);
    expect(
      await explainAndGetError(container),
      'Quota exceeded or rate limited (429); check your cloud provider account',
    );
  });

  test('500 → 通用 HTTP 错误文案', () async {
    final container = buildContainer(_ErrClient(LlmHttpException(500, 'boom')));
    addTearDown(container.dispose);
    expect(await explainAndGetError(container), 'Model service error: boom');
  });
}
