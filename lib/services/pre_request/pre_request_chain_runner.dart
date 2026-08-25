import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../models/pre_request_step.dart';
import '../../utils/app_logger.dart';
import '../auth_resolver.dart';
import '../http_service.dart';
import '../storage_service.dart';
import '../variable_resolver.dart';
import 'response_extractor.dart';

/// 单步执行结果
class ChainStepResult {
  const ChainStepResult({
    required this.step,
    this.request,
    this.statusCode,
    this.error,
    this.extracted = const {},
    this.missing = const [],
  });

  final PreRequestStep step;

  /// 引用的请求（未找到时为 null，步骤失败）
  final HttpRequest? request;
  final int? statusCode;
  final String? error;

  /// 提取成功：变量名 → 值
  final Map<String, String> extracted;

  /// 提取失败的规则（路径存在但取不到值）
  final List<ExtractionRule> missing;

  bool get succeeded => error == null;
}

/// 链执行结果
class ChainRunResult {
  const ChainRunResult({required this.steps, required this.produced});

  final List<ChainStepResult> steps;

  /// 本链产出的全部变量（本地作用域）
  final Map<String, String> produced;

  /// 是否所有启用步骤都成功（停用的步骤不参与判定）
  bool get allSucceeded =>
      steps.where((s) => s.step.enabled).every((s) => s.succeeded);

  /// 第一个失败步骤的错误信息（无失败返回 null）
  String? get firstError {
    for (final step in steps) {
      if (step.step.enabled && !step.succeeded) return step.error;
    }
    return null;
  }
}

/// 预请求链执行器（F8.2）
///
/// 发送目标请求前依次执行启用步骤：加载引用的已保存请求 → 变量解析
/// （含 F8.3 转换管道）→ 应用其 Auth 配置 → 发送 → 按规则提取变量。
/// 产出的变量并入作用域供后续步骤与目标请求使用（本地作用域，不污染环境）。
///
/// 被引用请求自身的预请求链不会递归执行（深度固定为 1，防循环）。
class PreRequestChainRunner {
  PreRequestChainRunner({
    required HttpService httpService,
    required StorageService storageService,
    required VariableResolver resolver,
  })  : _httpService = httpService,
        _storage = storageService,
        _resolver = resolver;

  final HttpService _httpService;
  final StorageService _storage;
  final VariableResolver _resolver;

  /// 解析生效的链与 401 重跑策略（请求级非空时优先，否则沿集合链向上）。
  ///
  /// 返回 (链, retryOn401)；链与开关作为整体按层继承——链来自哪层，
  /// 401 策略就随哪层。
  static (List<PreRequestStep>, bool) resolveEffective(
    HttpRequest request,
    Map<String, Collection> collectionsById,
  ) {
    if (request.preRequestChain.isNotEmpty) {
      return (request.preRequestChain, request.preRequestRetryOn401);
    }
    var cursor = request.parentId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final collection = collectionsById[cursor];
      if (collection == null) return (const [], false);
      if (collection.preRequestChain.isNotEmpty) {
        return (collection.preRequestChain, collection.preRequestRetryOn401);
      }
      cursor = collection.parentId;
    }
    return (const [], false);
  }

  /// 执行整条链。
  ///
  /// [variables] 为当前作用域（本地 > 环境 > 全局 合并前的底表）；
  /// 步骤产出的变量会并入后续步骤的解析作用域。
  /// 某步失败（请求未找到 / 网络错误）即中断，后续步骤不再执行。
  ///
  /// [label] 区分触发来源（`send` / `dry-run`），仅用于日志。
  ///
  /// 日志只记录变量名与状态码，不落任何变量值 / 响应体（含密码、token）。
  Future<ChainRunResult> run({
    required List<PreRequestStep> chain,
    required Map<String, String> variables,
    required Map<String, Collection> collectionsById,
    String label = 'send',
  }) async {
    final stepResults = <ChainStepResult>[];
    final produced = <String, String>{};

    AppLogger.info('[PreRequestChain] Start ($label): ${chain.length} step(s), '
        '${chain.where((s) => s.enabled).length} enabled');

    for (var i = 0; i < chain.length; i++) {
      final step = chain[i];
      final stepTag = 'Step ${i + 1}';
      if (!step.enabled) {
        AppLogger.debug('[PreRequestChain] $stepTag skipped (disabled)');
        stepResults.add(ChainStepResult(step: step));
        continue;
      }

      final request = await _storage.getRequest(step.requestId);
      if (request == null) {
        AppLogger.warning('[PreRequestChain] $stepTag failed: 引用的请求不存在 '
            '(${step.requestId})，可能已被删除');
        stepResults.add(ChainStepResult(
          step: step,
          error: '引用的请求不存在（${step.requestId}），可能已被删除',
        ));
        break;
      }

      // 变量解析（链产出并入作用域）+ 应用被引用请求自身的 Auth
      final scope = {...variables, ...produced};
      final unresolved = _resolver.findUnresolvedInRequest(request, scope);
      if (unresolved.isNotEmpty) {
        // 未解析的占位符会原样发出（如密码变量缺失），这里给出定位线索
        AppLogger.warning('[PreRequestChain] $stepTag (${request.name}): '
            'unresolved variables: ${unresolved.join(', ')}');
      }
      var resolved = _resolver.resolveRequest(request, scope);
      final auth = AuthResolver.resolveEffective(request, collectionsById);
      if (auth != null) {
        resolved = AuthResolver.apply(resolved, auth, scope, _resolver);
      }

      AppLogger.info('[PreRequestChain] $stepTag (${request.name}): '
          '${resolved.method.value} ${resolved.url}');
      final response = await _httpService.sendRequest(resolved);
      if (response.error != null) {
        AppLogger.warning(
            '[PreRequestChain] $stepTag (${request.name}) failed: '
            '${response.error}');
        stepResults.add(ChainStepResult(
          step: step,
          request: request,
          statusCode: response.statusCode,
          error: response.error,
        ));
        break;
      }

      // 提取变量
      final extracted = <String, String>{};
      final missing = <ExtractionRule>[];
      for (final rule in step.extractions) {
        if (!rule.enabled || rule.targetVariable.trim().isEmpty) continue;
        final value = ResponseExtractor.extract(response, rule);
        if (value == null) {
          missing.add(rule);
        } else {
          extracted[rule.targetVariable.trim()] = value;
        }
      }
      produced.addAll(extracted);

      AppLogger.info('[PreRequestChain] $stepTag (${request.name}) '
          'status ${response.statusCode}, '
          'extracted: ${extracted.isEmpty ? '(none)' : extracted.keys.join(', ')}');
      for (final rule in missing) {
        AppLogger.warning('[PreRequestChain] $stepTag (${request.name}): '
            'extraction missed — ${rule.source.name} "${rule.path}" '
            '→ ${rule.targetVariable}');
      }

      stepResults.add(ChainStepResult(
        step: step,
        request: request,
        statusCode: response.statusCode,
        extracted: extracted,
        missing: missing,
      ));
    }

    AppLogger.info('[PreRequestChain] Done ($label): '
        '${produced.isEmpty ? 'no variables produced' : 'produced ${produced.keys.join(', ')}'}');
    return ChainRunResult(steps: stepResults, produced: produced);
  }
}
