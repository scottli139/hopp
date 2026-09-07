import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/services/ai/ai_presets.dart';

void main() {
  group('ai_presets 常量完整性（F9.9）', () {
    test('六个预设都有展示名', () {
      for (final preset in [...kAiLocalPresets, ...kAiCloudPresets]) {
        expect(kAiPresetLabels, contains(preset));
      }
      expect(kAiPresetLabels, hasLength(6));
    });

    test('除 custom 外都有默认 Base URL', () {
      for (final preset in [...kAiLocalPresets, ...kAiCloudPresets]) {
        if (preset == 'custom') continue;
        expect(kAiPresetBaseUrls, contains(preset));
      }
      expect(kAiPresetBaseUrls['openai'], 'https://api.openai.com/v1');
      expect(kAiPresetBaseUrls['deepseek'], 'https://api.deepseek.com/v1');
      expect(kAiPresetBaseUrls['anthropic'], 'https://api.anthropic.com/v1');
    });
  });

  group('isCloudPreset 云端判定（F9.9）', () {
    test('本地预设恒本地', () {
      expect(isCloudPreset('ollama', 'http://localhost:11434/v1'), isFalse);
      expect(isCloudPreset('lmstudio', 'http://localhost:1234/v1'), isFalse);
      // 即使 baseUrl 被改成远端，本地预设仍按本地处理
      expect(isCloudPreset('ollama', 'https://example.com/v1'), isFalse);
    });

    test('云端三预设恒云端', () {
      expect(isCloudPreset('openai', 'https://api.openai.com/v1'), isTrue);
      expect(isCloudPreset('deepseek', 'https://api.deepseek.com/v1'), isTrue);
      expect(
          isCloudPreset('anthropic', 'https://api.anthropic.com/v1'), isTrue);
    });

    test('custom 指向 loopback 视为本地', () {
      expect(isCloudPreset('custom', 'http://localhost:11434/v1'), isFalse);
      expect(isCloudPreset('custom', 'http://127.0.0.1:8080/v1'), isFalse);
      expect(isCloudPreset('custom', 'http://[::1]:8080/v1'), isFalse);
    });

    test('custom 指向远端视为云端', () {
      expect(
          isCloudPreset('custom', 'https://my-gateway.example.com/v1'), isTrue);
      expect(isCloudPreset('custom', 'https://192.168.1.10:8080/v1'), isTrue);
    });

    test('custom 空/非法 baseUrl 保守按云端处理', () {
      expect(isCloudPreset('custom', ''), isTrue);
      expect(isCloudPreset('custom', 'not-a-url'), isTrue);
    });
  });
}
