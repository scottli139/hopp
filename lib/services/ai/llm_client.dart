import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// LLM 调用异常基类（F9.5）
sealed class LlmException implements Exception {
  const LlmException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 连接失败 / 超时：未检测到本地模型服务
class LlmConnectionException extends LlmException {
  LlmConnectionException([String? detail])
      : super(
          detail == null || detail.isEmpty
              ? '未检测到本地模型服务，请确认 Ollama / LM Studio 已启动'
              : '未检测到本地模型服务，请确认 Ollama / LM Studio 已启动（$detail）',
        );

  /// 服务在线但生成超时（首次加载模型 / 机器负载高 / 超大 body）
  LlmConnectionException.timeout([String? detail])
      : super(
          detail == null || detail.isEmpty
              ? '本地模型响应超时：可能是首次加载模型或机器负载较高，请重试'
              : '本地模型响应超时：可能是首次加载模型或机器负载较高，请重试（$detail）',
        );
}

/// HTTP 非 2xx：携带 status 与服务端错误消息
class LlmHttpException extends LlmException {
  const LlmHttpException(this.statusCode, String message) : super(message);

  final int statusCode;

  @override
  String toString() => 'HTTP $statusCode: $message';
}

/// 响应 schema 不符 / choices 为空
class LlmResponseException extends LlmException {
  LlmResponseException([String detail = ''])
      : super(
          detail.isEmpty ? '模型服务返回异常，请稍后重试' : '模型服务返回异常：$detail',
        );
}

/// chat completions 消息（OpenAI 兼容格式）
class LlmMessage {
  const LlmMessage.system(String content) : this._('system', content);
  const LlmMessage.user(String content) : this._('user', content);
  const LlmMessage.assistant(String content) : this._('assistant', content);
  const LlmMessage._(this.role, this.content);

  final String role; // system | user | assistant
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// 单次调用的 token 用量（来自 usage 字段，可选）
class LlmUsage {
  const LlmUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
}

/// 单一 OpenAI 兼容 chat completions 客户端（F9.3）
///
/// `baseURL + model + key` 可配，Tier 1（Ollama / LM Studio）与 Tier 2
/// （BYOK 云端）共用一套代码。非流式、温度 0。
///
/// 日志只记元数据（端点 / 模型 / 耗时 / token 数），不落 messages 内容、
/// API key 与响应文本本体。
class LlmClient {
  LlmClient({Dio? dio, Logger? logger})
      : _dio = dio,
        _logger = logger ?? Logger();
  final Dio? _dio;
  final Logger _logger;

  /// 发送一轮对话，返回 assistant 文本内容
  Future<String> chat({
    required String baseUrl,
    required String model,
    required String apiKey,
    required List<LlmMessage> messages,
  }) async {
    // baseUrl 可能带或不带末尾斜杠，统一归一
    final endpoint = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}'
        '/chat/completions';

    final dio = _dio ?? _createDio();

    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final body = <String, dynamic>{
      'model': model,
      'messages': [for (final m in messages) m.toJson()],
      'temperature': 0,
      'stream': false,
    };

    final stopwatch = Stopwatch()..start();

    Response<Map<String, dynamic>> response;
    try {
      response = await dio.request<Map<String, dynamic>>(
        endpoint,
        data: body,
        options: Options(method: 'POST', headers: headers),
      );
    } on DioException catch (e) {
      // 服务端返回了响应（4xx/5xx，dio 默认 validateStatus 会抛）
      final errResponse = e.response;
      if (errResponse != null && errResponse.statusCode != null) {
        throw LlmHttpException(
          errResponse.statusCode!,
          _extractErrorMessage(errResponse.data) ?? e.message ?? '请求失败',
        );
      }
      // 发送/接收超时：服务在线但生成太慢，与「服务未启动」区分提示
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw LlmConnectionException.timeout(e.message);
      }
      // 连接失败 / 连接超时：服务未启动或端口不通
      throw LlmConnectionException(e.message);
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw LlmHttpException(
        statusCode,
        _extractErrorMessage(response.data) ?? 'HTTP $statusCode',
      );
    }

    // 解析 choices[0].message.content；usage 仅用于元数据日志
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw LlmResponseException('响应体不是 JSON 对象');
    }

    LlmUsage? usage;
    final usageRaw = data['usage'];
    if (usageRaw is Map) {
      usage = LlmUsage(
        promptTokens: usageRaw['prompt_tokens'] as int?,
        completionTokens: usageRaw['completion_tokens'] as int?,
        totalTokens: usageRaw['total_tokens'] as int?,
      );
    }

    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      throw LlmResponseException('choices 为空');
    }

    final first = choices.first;
    if (first is! Map || first['message'] is! Map) {
      throw LlmResponseException('choices[0].message 结构不符');
    }

    final content = (first['message'] as Map)['content'];
    if (content is! String || content.isEmpty) {
      throw LlmResponseException('choices[0].message.content 为空');
    }

    // 元数据-only 日志：端点 / 模型 / 耗时 / token 数
    _logger.i('[LlmClient] chat model=$model endpoint=$endpoint '
        'elapsed=${elapsedMs}ms tokens=${usage?.totalTokens ?? '-'}');

    return content;
  }

  /// 自建实例时的默认超时：连接 5s / 生成 60s（F9.5）
  Dio _createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  /// 从服务返回的 error 中提取 message（OpenAI 风格：
  /// `{error: {message: ...}}`，也兼容裸字符串）
  String? _extractErrorMessage(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (error is String) return error;
      final message = data['message'];
      if (message is String) return message;
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
