/// `hopp run` 执行引擎（F4.4 CLI）
///
/// 镜像 GUI 发送流程（request_response_provider.sendRequest）：
/// 预请求链（resolveEffective → 跑链，产物并入本地作用域）→ 变量解析
/// URL/params/headers/body → AuthResolver 应用认证 → HttpService 发送 →
/// 断言引擎求值。被请求失败（网络错/无响应）记 failed 并继续；
/// 链失败中断后续步骤，该请求记 failed。
///
/// 纯 Dart 实现，复用 lib/services 纯 Dart 闭包，不依赖 Flutter。
library;

import 'dart:convert';
import 'dart:io';

import 'package:hopp/models/collection.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/services/assertion/assertion_engine.dart';
import 'package:hopp/services/auth_resolver.dart';
import 'package:hopp/services/http_service.dart';
import 'package:hopp/services/pre_request/pre_request_chain_runner.dart';
import 'package:hopp/services/variable_resolver.dart';
import 'package:logger/logger.dart';

import 'cli_args.dart';
import 'export_document.dart';
import 'report.dart';

/// 环境解析结果
class EnvironmentResolution {
  const EnvironmentResolution({
    required this.envName,
    required this.variables,
  });

  /// 环境展示名（无环境时为 "(none)"）
  final String envName;

  /// 合并后的变量表（全局 → 环境 → 进程环境回填空值 → --env-var）
  final Map<String, String> variables;
}

/// 解析生效环境并按优先级合并变量表。
///
/// [processEnvironment] 可注入（测试用），默认 [Platform.environment]。
///
/// 优先级（对齐 app 的 本地 > 环境 > 全局；CLI 无 local）：
/// `--env-var` > 进程环境变量（仅回填导出为空值的 key）> 环境 > 全局。
/// 导出时被置空的 secret 变量由此在 CI 中重获值。
EnvironmentResolution resolveEnvironment({
  required HoppExportDocument doc,
  required RunOptions options,
  Map<String, String>? processEnvironment,
}) {
  final procEnv = processEnvironment ?? Platform.environment;

  Environment? env;
  if (options.env != null) {
    final envArg = options.env!;
    if (File(envArg).existsSync()) {
      // 外部原生 env json：单环境对象
      try {
        final content = File(envArg).readAsStringSync();
        final decoded = jsonDecode(content);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('expected a JSON object');
        }
        env = Environment.fromJson(decoded);
      } on FormatException catch (e) {
        throw FormatException('Invalid env file "$envArg": ${e.message}');
      }
    } else {
      // 按名称匹配导出文件内 environments
      for (final candidate in doc.environments) {
        if (candidate.name == envArg) {
          env = candidate;
          break;
        }
      }
      if (env == null) {
        throw FormatException(
          'Environment "$envArg" not found in export file '
          '(available: ${doc.environments.map((e) => e.name).join(', ')})',
        );
      }
    }
  } else {
    // 未指定：优先文件里标记的激活环境，否则第一个，否则空环境
    if (doc.activeEnvironmentId != null) {
      for (final candidate in doc.environments) {
        if (candidate.id == doc.activeEnvironmentId) {
          env = candidate;
          break;
        }
      }
    }
    env ??= doc.environments.isEmpty ? null : doc.environments.first;
  }

  // 全局 → 环境（环境覆盖全局，与 app 的 buildScope 一致）；
  // 进程环境回填：导出为空值的 key（secret 置空）从进程环境补值；
  // --env-var 最高优先级
  final variables = VariableResolver.buildScope(
    globals: doc.globals,
    activeEnvironment: env,
  )
    ..updateAll((key, value) {
      if (value.isEmpty && procEnv.containsKey(key)) {
        return procEnv[key]!;
      }
      return value;
    })
    ..addAll(options.envVars);

  return EnvironmentResolution(
    envName: env?.name ?? '(none)',
    variables: variables,
  );
}

/// 集合运行器
class CliRunner {
  CliRunner({HttpService? httpService, Logger? logger})
      : _httpService =
            httpService ?? HttpService(logger: Logger(level: Level.off)),
        _resolver = VariableResolver(),
        _logger = logger ?? Logger(level: Level.off);

  final HttpService _httpService;
  final VariableResolver _resolver;
  final Logger _logger;

  /// 顺序执行导出文档中的全部请求（集合树 DFS），返回运行报告。
  ///
  /// 链产出的变量并入会话级本地作用域（对齐 app 的 localVariables），
  /// 供后续请求使用。
  Future<RunReport> run({
    required HoppExportDocument doc,
    required EnvironmentResolution environment,
    int? timeoutMs,
  }) async {
    _httpService.configure(
      timeoutMs: timeoutMs ?? 30000,
      followRedirects: true,
      maxRedirects: 10,
      validateCertificates: true,
    );

    final stopwatch = Stopwatch()..start();
    final collectionsById = doc.collectionsById;
    final requestsById = {for (final r in doc.requests) r.id: r};
    final ordered = doc.dfsRequests;
    final localScope = <String, String>{};
    final reports = <RequestReport>[];

    for (final request in ordered) {
      reports.add(
        await _runSingle(
          request,
          environment.variables,
          localScope,
          collectionsById,
          requestsById,
        ),
      );
    }

    stopwatch.stop();
    return RunReport(
      collectionName: doc.collection.name,
      envName: environment.envName,
      requests: reports,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  Future<RequestReport> _runSingle(
    HttpRequest request,
    Map<String, String> baseVariables,
    Map<String, String> localScope,
    Map<String, Collection> collectionsById,
    Map<String, HttpRequest> requestsById,
  ) async {
    // 当前作用域：底表 + 会话级链产出（对齐 app：本地 > 环境 > 全局）
    var scope = {...baseVariables, ...localScope};

    // 1. 预请求链（请求级 > 集合级继承）
    final (chain, _) =
        PreRequestChainRunner.resolveEffective(request, collectionsById);
    final chainSteps = <ChainStepEntry>[];
    if (chain.isNotEmpty) {
      final runner = PreRequestChainRunner(
        httpService: _httpService,
        requestLookup: (id) async => requestsById[id],
        resolver: _resolver,
        logger: _logger,
      );
      final result = await runner.run(
        chain: chain,
        variables: scope,
        collectionsById: collectionsById,
        label: 'cli',
      );
      chainSteps.addAll([
        for (final step in result.steps)
          ChainStepEntry(
            name: step.request?.name ?? step.step.requestId,
            statusCode: step.statusCode,
            error: step.error,
            extractedKeys: step.extracted.keys.toList(),
          ),
      ]);
      if (!result.allSucceeded) {
        // 链失败：中断后续步骤，该请求记 failed
        return RequestReport(
          name: request.name,
          method: request.method.value,
          displayPath: _displayPath(_resolver.resolve(request.url, scope)),
          error: 'pre-request chain failed: ${result.firstError}',
          chainSteps: chainSteps,
        );
      }
      // 链产物并入会话级本地作用域
      localScope.addAll(result.produced);
      scope = {...baseVariables, ...localScope};
    }

    // 2. 变量解析（URL / params / headers / body）
    var resolved = _resolver.resolveRequest(request, scope);

    // 3. 应用生效的认证配置（请求级 > 就近集合级继承）
    final auth = AuthResolver.resolveEffective(request, collectionsById);
    if (auth != null) {
      resolved = AuthResolver.apply(resolved, auth, scope, _resolver);
    }

    // 4. 发送
    final response = await _httpService.sendRequest(resolved);

    // 5. 网络错误：记 failed 并继续下一个
    if (response.error != null) {
      return RequestReport(
        name: request.name,
        method: request.method.value,
        displayPath: _displayPath(resolved.url),
        error: response.error,
        chainSteps: chainSteps,
      );
    }

    // 6. 断言求值（期望值/目标参数支持 {{var}} 插值）
    final assertionEntries = <AssertionEntry>[
      for (final r in AssertionEngine.evaluate(
        rules: request.assertions,
        response: response,
        resolver: _resolver,
        variables: scope,
      ))
        AssertionEntry(
          description: describeAssertion(r.rule),
          outcome: r.outcome,
          actual: r.actual,
          message: r.message,
          expected: r.rule.expected,
        ),
    ];

    final anyFailed = assertionEntries.any((a) => a.failed);
    return RequestReport(
      name: request.name,
      method: request.method.value,
      displayPath: _displayPath(resolved.url),
      statusCode: response.statusCode,
      statusText: response.statusText,
      durationMs: response.durationMs,
      chainSteps: chainSteps,
      assertions: assertionEntries,
      passed: !anyFailed,
    );
  }

  /// 展示用路径：解析后 URL 的 path（含 query），无法解析时原样返回
  String _displayPath(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.path.isEmpty) {
        return url;
      }
      return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    } on FormatException {
      return url;
    }
  }
}
