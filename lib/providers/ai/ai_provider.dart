import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../services/ai/ai_models.dart';
import '../../services/ai/ai_prompts.dart';
import '../../services/ai/ai_response_parser.dart';
import '../../services/ai/llm_client.dart';
import '../settings/settings_provider.dart';

/// AI 操作状态（F9.5：解释响应 / 生成断言 / 自然语言建请求共用）
///
/// 状态按「调用方实例」粒度：简单全局 notifier，不按键 tabId。
enum AiOpStatus { idle, loading, success, error }

class AiOpState<T> {
  const AiOpState._(this.status, this.result, this.errorMessage);

  const AiOpState.idle() : this._(AiOpStatus.idle, null, null);
  const AiOpState.loading() : this._(AiOpStatus.loading, null, null);
  const AiOpState.success(T result) : this._(AiOpStatus.success, result, null);
  const AiOpState.error(String message)
      : this._(AiOpStatus.error, null, message);

  final AiOpStatus status;
  final T? result;
  final String? errorMessage;

  bool get isIdle => status == AiOpStatus.idle;
  bool get isLoading => status == AiOpStatus.loading;
  bool get isSuccess => status == AiOpStatus.success;
  bool get isError => status == AiOpStatus.error;
}

/// UI 测试模式 AI mock 接缝（F9.5：test-mode 自动化验证用）
///
/// 非 null 时 [llmClientProvider] 返回 [CannedLlmClient]，
/// 任何 chat() 立即返回该字符串（不走网络）。由 test-mode 指令
/// set_ai_mock / clear_ai_mock 写入；常规运行恒为 null。
final uiTestAiMockProvider = StateProvider<String?>((ref) => null);

/// LLM 客户端（F9.3 单一 OpenAI 兼容客户端）
///
/// watch [uiTestAiMockProvider]：mock 值非 null 时返回 canned 实现，
/// 供 test-mode 指令在无本地模型（Ollama / LM Studio）环境下验证
/// AI 全链路（提示词 → 解析 → 状态机）。
final llmClientProvider = Provider<LlmClient>((ref) {
  final canned = ref.watch(uiTestAiMockProvider);
  if (canned != null) return CannedLlmClient(canned);
  return LlmClient();
});

/// canned 响应的 LlmClient：任何 chat() 立即返回固定字符串（测试用）
class CannedLlmClient extends LlmClient {
  CannedLlmClient(this._response);

  final String _response;

  @override
  Future<String> chat({
    required String baseUrl,
    required String model,
    required String apiKey,
    required List<LlmMessage> messages,
  }) async =>
      _response;
}

/// 解释响应 / 错误（入口：Response info bar ✨）
class ExplainNotifier extends StateNotifier<AiOpState<String>> {
  ExplainNotifier(this._ref) : super(const AiOpState.idle());

  final Ref _ref;

  /// 复位状态（重新生成 / 打开任务弹窗前调用，避免残留上一次结果）
  void reset() => state = const AiOpState.idle();

  Future<void> explain({
    required int statusCode,
    required String statusText,
    required String body,
  }) async {
    final settings = _requireSettings();
    if (settings == null) return;

    state = const AiOpState.loading();
    try {
      final client = _ref.read(llmClientProvider);
      final content = await client.chat(
        baseUrl: settings.aiBaseUrl,
        model: settings.aiModel,
        apiKey: settings.aiApiKey,
        messages: AiPrompts.buildExplainPrompt(
          statusCode: statusCode,
          statusText: statusText,
          body: body,
        ),
      );
      state = AiOpState.success(content);
    } catch (e) {
      state = AiOpState.error(_friendlyError(e));
    }
  }

  AppSettings? _requireSettings() {
    final settings = _ref.read(settingsProvider).value;
    if (settings == null) {
      state = AiOpState.error(L10nBridge.t.ai_configNotLoaded);
      return null;
    }
    if (settings.aiModel.isEmpty) {
      state = AiOpState.error(L10nBridge.t.ai_modelNotConfigured);
      return null;
    }
    return settings;
  }
}

final explainProvider =
    StateNotifierProvider<ExplainNotifier, AiOpState<String>>((ref) {
  return ExplainNotifier(ref);
});

/// AI 生成断言（F4.2，入口：Assertions 页「AI 生成」）
class GenerateAssertionsNotifier
    extends StateNotifier<AiOpState<AiAssertionParseResult>> {
  GenerateAssertionsNotifier(this._ref) : super(const AiOpState.idle());

  final Ref _ref;

  /// 复位状态（重新生成 / 打开任务弹窗前调用，避免残留上一次结果）
  void reset() => state = const AiOpState.idle();

  Future<void> generate({
    required String method,
    required String url,
    required String? responseBody,
  }) async {
    // 无响应样本：业务错误，不发请求
    if (responseBody == null || responseBody.isEmpty) {
      state = AiOpState.error(L10nBridge.t.ai_noResponseSample);
      return;
    }

    final settings = _requireSettings();
    if (settings == null) return;

    state = const AiOpState.loading();
    try {
      final client = _ref.read(llmClientProvider);
      final content = await client.chat(
        baseUrl: settings.aiBaseUrl,
        model: settings.aiModel,
        apiKey: settings.aiApiKey,
        messages: AiPrompts.buildAssertionPrompt(
          method: method,
          url: url,
          responseBody: responseBody,
        ),
      );
      final decoded = AiResponseParser.decodeAiJson(content);
      final result = AiResponseParser.parseAssertionDrafts(decoded);
      state = AiOpState.success(result);
    } catch (e) {
      state = AiOpState.error(_friendlyError(e));
    }
  }

  AppSettings? _requireSettings() {
    final settings = _ref.read(settingsProvider).value;
    if (settings == null) {
      state = AiOpState.error(L10nBridge.t.ai_configNotLoaded);
      return null;
    }
    if (settings.aiModel.isEmpty) {
      state = AiOpState.error(L10nBridge.t.ai_modelNotConfigured);
      return null;
    }
    return settings;
  }
}

final generateAssertionsProvider = StateNotifierProvider<
    GenerateAssertionsNotifier, AiOpState<AiAssertionParseResult>>((ref) {
  return GenerateAssertionsNotifier(ref);
});

/// 自然语言建请求（入口：URL 栏 ✨）
class BuildRequestNotifier extends StateNotifier<AiOpState<AiRequestDraft>> {
  BuildRequestNotifier(this._ref) : super(const AiOpState.idle());

  final Ref _ref;

  /// 复位状态（重新生成 / 打开任务弹窗前调用，避免残留上一次结果）
  void reset() => state = const AiOpState.idle();

  Future<void> build({required String description}) async {
    final settings = _requireSettings();
    if (settings == null) return;

    state = const AiOpState.loading();
    try {
      final client = _ref.read(llmClientProvider);
      final content = await client.chat(
        baseUrl: settings.aiBaseUrl,
        model: settings.aiModel,
        apiKey: settings.aiApiKey,
        messages: AiPrompts.buildRequestPrompt(description: description),
      );
      final decoded = AiResponseParser.decodeAiJson(content);
      final draft = AiResponseParser.parseRequestDraft(decoded);
      state = AiOpState.success(draft);
    } catch (e) {
      state = AiOpState.error(_friendlyError(e));
    }
  }

  AppSettings? _requireSettings() {
    final settings = _ref.read(settingsProvider).value;
    if (settings == null) {
      state = AiOpState.error(L10nBridge.t.ai_configNotLoaded);
      return null;
    }
    if (settings.aiModel.isEmpty) {
      state = AiOpState.error(L10nBridge.t.ai_modelNotConfigured);
      return null;
    }
    return settings;
  }
}

final buildRequestProvider =
    StateNotifierProvider<BuildRequestNotifier, AiOpState<AiRequestDraft>>(
        (ref) {
  return BuildRequestNotifier(ref);
});

/// 异常 → 用户可读的友好文案（区分连接失败 / 格式异常 / 其他）
String _friendlyError(Object e) {
  return switch (e) {
    LlmConnectionException() => e.message,
    LlmHttpException() => L10nBridge.t.ai_httpError(e.message),
    LlmResponseException() => e.message,
    AiParseException() => e.message,
    _ => L10nBridge.t.ai_callFailed('$e'),
  };
}
