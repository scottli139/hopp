import '../../models/assertion_rule.dart';
import '../assertion/assertion_engine.dart';
import 'llm_client.dart';

/// AI 提示词构建（F9.5，纯函数，可单测）
///
/// 三个能力共用同一套防脑补硬约束：模型只能基于给出的输入生成内容，
/// 缺失即缺失，禁止臆测。
class AiPrompts {
  AiPrompts._();

  /// 响应体进入提示词的最大长度（F9.5：截断 ≤8KB）
  static const int maxBodyChars = 8192;

  static const String _truncationMarker = '\n\n…（内容过长，已截断）';

  /// 解释响应 / 错误（入口：Response info bar ✨）
  static List<LlmMessage> buildExplainPrompt({
    required int statusCode,
    required String statusText,
    required String body,
  }) {
    final trimmedBody = body.length > maxBodyChars
        ? '${body.substring(0, maxBodyChars)}$_truncationMarker'
        : body;

    return [
      const LlmMessage.system(
        '你是 API 调试助手，用简洁中文解释 HTTP 响应。'
        '只能基于给出的响应内容解释：状态码含义、可能的错误原因、排查建议。'
        '不要臆测响应中没有的信息（如服务端实现细节），不确定就直说不确定。',
      ),
      LlmMessage.user(
        '请解释以下 HTTP 响应：\n\n'
        'HTTP $statusCode $statusText\n\n'
        '$trimmedBody',
      ),
    ];
  }

  /// 生成断言（入口：Assertions 页「AI 生成」）
  ///
  /// 枚举值直接取自 [AssertionTarget] / [AssertionOperator] 与
  /// [AssertionEngine.operatorsByTarget] 矩阵，与断言模型保持一致。
  static List<LlmMessage> buildAssertionPrompt({
    required String method,
    required String url,
    required String responseBody,
  }) {
    final targets = AssertionTarget.values.map((t) => t.name).join('|');
    final operators = AssertionOperator.values.map((o) => o.name).join('|');
    final matrix = AssertionEngine.operatorsByTarget.entries
        .map((e) => '${e.key.name}: ${e.value.map((o) => o.name).join('/')}')
        .join('; ');
    // 响应样本同样截断：超大 body（如分页列表）会撑爆本地模型的
    // context window 并导致生成超时（8GB 机器实测 240KB body 60s 不返回）
    final trimmedBody = responseBody.length > maxBodyChars
        ? '${responseBody.substring(0, maxBodyChars)}$_truncationMarker'
        : responseBody;

    return [
      LlmMessage.system(
        '你是 API 测试专家，根据请求信息与响应样本生成断言规则。'
        '只输出严格 JSON 数组，不要输出 markdown 代码围栏或任何其他文字。'
        '数组元素格式：'
        '{"target": "$targets", "targetArg": "string(可空)", '
        '"operator": "$operators", "expected": "string|number"}。'
        'target 与 operator 的合法组合：$matrix。'
        'targetArg：header 目标填 Header 名，jsonPath 目标填路径表达式，其余目标留空。'
        '生成 3-6 条最有价值的断言，只覆盖响应样本能支撑的内容。'
        '硬约束：expected 的取值只能来自响应样本（状态码、Header 值、Body 内容），'
        '缺失即缺失，禁止脑补响应中没有的值。',
      ),
      LlmMessage.user(
        '请求：$method $url\n\n'
        '响应样本：\n$trimmedBody\n\n'
        '请生成断言规则 JSON 数组。',
      ),
    ];
  }

  /// 自然语言建请求（入口：URL 栏 ✨）
  static List<LlmMessage> buildRequestPrompt({
    required String description,
  }) {
    return [
      const LlmMessage.system(
        '你是 API 客户端助手，把用户的自然语言描述转成 HTTP 请求。'
        '只输出严格 JSON 对象，不要输出 markdown 代码围栏或任何其他文字。'
        '格式：{"name": "string", "method": "GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS", '
        '"url": "string", "params": [{"key": "string", "value": "string", "enabled": true}], '
        '"headers": [{"key": "string", "value": "string", "enabled": true}], '
        '"bodyType": "none|form-urlencoded|multipart|raw", '
        '"rawContentType": "json|xml|text(仅 bodyType 为 raw 时)", "body": "string"}。'
        '硬约束：所有值只能来自用户描述，缺失的字段直接省略，禁止脑补；'
        'url 可以使用 {{var}} 变量占位。',
      ),
      LlmMessage.user('请根据描述生成请求：$description'),
    ];
  }
}
