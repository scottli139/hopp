import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/providers/ai/ai_provider.dart';
import 'package:hopp/services/ai/llm_client.dart';

void main() {
  group('llmClientProvider mock 接缝', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('uiTestAiMockProvider 为 null 时返回真实 LlmClient', () {
      final client = container.read(llmClientProvider);

      expect(client.runtimeType, equals(LlmClient));
    });

    test('设置 canned 响应后 chat() 立即返回该字符串（不走网络）', () async {
      container.read(uiTestAiMockProvider.notifier).state =
          '{"assertions":[{"target":"status","operator":"equals","expected":"200"}]}';

      final client = container.read(llmClientProvider);
      expect(client, isA<CannedLlmClient>());

      final reply = await client.chat(
        baseUrl: 'http://localhost:1',
        model: 'test-model',
        apiKey: '',
        messages: const [LlmMessage.user('hello')],
      );
      expect(
        reply,
        equals(
          '{"assertions":[{"target":"status","operator":"equals","expected":"200"}]}',
        ),
      );
    });

    test('清除 mock 后回到真实 LlmClient', () {
      container.read(uiTestAiMockProvider.notifier).state = 'x';
      expect(container.read(llmClientProvider), isA<CannedLlmClient>());

      container.read(uiTestAiMockProvider.notifier).state = null;
      expect(
        container.read(llmClientProvider).runtimeType,
        equals(LlmClient),
      );
    });
  });
}
