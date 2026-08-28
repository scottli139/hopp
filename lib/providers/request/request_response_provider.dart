import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../models/http_response.dart';
import '../../models/pre_request_step.dart';
import '../../services/assertion/assertion_engine.dart';
import '../../services/auth_resolver.dart';
import '../../services/http_service.dart';
import '../../services/pre_request/pre_request_chain_runner.dart';
import '../../services/variable_resolver.dart';
import '../../utils/app_logger.dart';
import '../collection/collection_provider.dart';
import '../core/providers.dart';
import '../environment/environment_provider.dart';
import 'request_tab_provider.dart';

class RequestResponseNotifier extends StateNotifier<Map<String, HttpResponse>> {
  final HttpService _httpService;
  final Ref _ref;

  RequestResponseNotifier(this._httpService, this._ref) : super({});

  Future<void> sendRequest(String tabId, HttpRequest request) async {
    AppLogger.info(
        '[RequestResponseNotifier] Sending request for tab $tabId: ${request.method.value} ${request.url}');

    final resolver = _ref.read(variableResolverProvider);
    final collectionsById = _ref.read(collectionsByIdProvider);

    // F4.1：清除上一轮的断言结果，避免重新 Send 前残留旧数据
    _ref.read(assertionResultsProvider.notifier).update((map) {
      return {...map}..remove(tabId);
    });

    // F8.2：先执行预请求链（请求级 > 集合级继承），产出写入本地作用域
    final (chain, retryOn401) =
        PreRequestChainRunner.resolveEffective(request, collectionsById);
    if (chain.isNotEmpty) {
      final result = await _runChain(
        request.id,
        chain,
        _ref.read(resolvedVariablesProvider),
        collectionsById,
        resolver,
      );
      if (!result.allSucceeded) {
        AppLogger.warning(
            '[RequestResponseNotifier] Pre-request chain failed: ${result.firstError}');
        // 链失败不发目标请求，错误呈现在响应区；断言按失败响应求值
        final errorResponse =
            HttpResponse.error('预请求链执行失败：${result.firstError}');
        _evaluateAssertions(tabId, request, errorResponse);
        state = {
          ...state,
          tabId: errorResponse,
        };
        return;
      }
    }

    // 发送前应用环境变量替换（{{variable}}；含链产出的本地变量）
    final variables = _ref.read(resolvedVariablesProvider);
    var resolvedRequest = resolver.resolveRequest(request, variables);

    final unresolved = resolver.findUnresolvedInRequest(request, variables);
    if (unresolved.isNotEmpty) {
      AppLogger.warning(
          '[RequestResponseNotifier] Unresolved variables: ${unresolved.join(', ')}');
    }

    // F8.1：应用生效的认证配置（请求级 > 就近集合级继承）
    final auth = AuthResolver.resolveEffective(request, collectionsById);
    if (auth != null) {
      resolvedRequest =
          AuthResolver.apply(resolvedRequest, auth, variables, resolver);
    }

    state = {
      ...state,
      tabId: HttpResponse.empty(),
    };

    var response = await _httpService.sendRequest(resolvedRequest);

    // F8.2：401 自动重跑前置链一次（刷新 token 后重发）
    if (response.statusCode == 401 && retryOn401 && chain.isNotEmpty) {
      AppLogger.info(
          '[RequestResponseNotifier] Got 401, re-running pre-request chain');
      final rerun = await _runChain(
        request.id,
        chain,
        _ref.read(resolvedVariablesProvider),
        collectionsById,
        resolver,
      );
      if (rerun.allSucceeded) {
        final retryVariables = _ref.read(resolvedVariablesProvider);
        var retryRequest = resolver.resolveRequest(request, retryVariables);
        if (auth != null) {
          retryRequest =
              AuthResolver.apply(retryRequest, auth, retryVariables, resolver);
        }
        response = await _httpService.sendRequest(retryRequest);
      }
    }

    if (response.error != null) {
      AppLogger.warning(
          '[RequestResponseNotifier] Request failed: ${response.error}');
    } else {
      AppLogger.info(
          '[RequestResponseNotifier] Request completed: ${response.statusCode} in ${response.durationMs}ms');
    }

    // F4.1：发送完成后对断言规则求值（error 响应同样求值，规则自然全部失败）
    _evaluateAssertions(tabId, request, response);

    state = {
      ...state,
      tabId: response,
    };
  }

  /// F4.1：求值请求断言并存入按 Tab 索引的结果表（Tests 页签数据源）
  void _evaluateAssertions(
    String tabId,
    HttpRequest request,
    HttpResponse response,
  ) {
    final resultsMap = {..._ref.read(assertionResultsProvider)};
    if (request.assertions.isEmpty) {
      resultsMap.remove(tabId);
      _ref.read(assertionResultsProvider.notifier).state = resultsMap;
      return;
    }

    // 与发送时同源的合并变量表（环境 + 全局 + 本地作用域）
    final variables = _ref.read(resolvedVariablesProvider);
    final resolver = _ref.read(variableResolverProvider);
    final results = AssertionEngine.evaluate(
      rules: request.assertions,
      response: response,
      resolver: resolver,
      variables: variables,
    );
    resultsMap[tabId] = results;
    _ref.read(assertionResultsProvider.notifier).state = resultsMap;
  }

  /// 执行预请求链：产出写入本地作用域，结果记录到试运行面板 provider
  Future<ChainRunResult> _runChain(
    String requestId,
    List<PreRequestStep> chain,
    Map<String, String> baseVariables,
    Map<String, Collection> collectionsById,
    VariableResolver resolver, {
    bool dryRun = false,
  }) async {
    final runner = PreRequestChainRunner(
      httpService: _httpService,
      requestLookup: (id) => _ref.read(storageServiceProvider).getRequest(id),
      resolver: resolver,
    );
    final result = await runner.run(
      chain: chain,
      variables: baseVariables,
      collectionsById: collectionsById,
      label: dryRun ? 'dry-run' : 'send',
    );

    // 链产出并入本地作用域（不污染环境）
    if (result.produced.isNotEmpty) {
      _ref.read(localVariablesProvider.notifier).update((map) {
        return {...map, ...result.produced};
      });
    }
    // 试运行面板数据（Pre-request tab 展示）
    _ref.read(preRequestRunResultsProvider.notifier).update((map) {
      return {...map, requestId: result};
    });
    return result;
  }

  /// F8.2：试运行预请求链（不发目标请求），结果写入试运行面板 provider
  Future<void> testRunPreRequestChain(
    String ownerId,
    List<PreRequestStep> chain,
  ) async {
    await _runChain(
      ownerId,
      chain,
      _ref.read(resolvedVariablesProvider),
      _ref.read(collectionsByIdProvider),
      _ref.read(variableResolverProvider),
      dryRun: true,
    );
  }

  HttpResponse? getResponse(String tabId) => state[tabId];

  void clearResponse(String tabId) {
    final newState = {...state};
    newState.remove(tabId);
    state = newState;
    _ref.read(assertionResultsProvider.notifier).update((map) {
      return {...map}..remove(tabId);
    });
  }

  void clearAll() {
    state = {};
    _ref.read(assertionResultsProvider.notifier).state = {};
  }

  /// 设置模拟响应（用于测试）
  void setMockResponse(String tabId, HttpResponse response) {
    AppLogger.info(
      '[RequestResponseNotifier] Setting mock response for tab $tabId: '
      '${response.statusCode}, size: ${response.sizeBytes} bytes',
    );
    // 模拟响应不做断言求值，同步清掉旧结果避免残留
    _ref.read(assertionResultsProvider.notifier).update((map) {
      return {...map}..remove(tabId);
    });
    state = {
      ...state,
      tabId: response,
    };
  }
}

final requestResponseProvider =
    StateNotifierProvider<RequestResponseNotifier, Map<String, HttpResponse>>(
        (ref) {
  final httpService = ref.watch(httpServiceProvider);
  return RequestResponseNotifier(httpService, ref);
});

final currentResponseProvider = Provider<HttpResponse?>((ref) {
  final responses = ref.watch(requestResponseProvider);
  final activeTabId = ref.watch(activeTabIdProvider);

  if (activeTabId == null) return null;
  return responses[activeTabId];
});

/// 预请求链最近一次执行结果（按主请求 ID 索引，F8.2 试运行面板数据源）
final preRequestRunResultsProvider =
    StateProvider<Map<String, ChainRunResult>>((ref) => {});

/// 断言最近一次求值结果（按请求 Tab ID 索引，F4.1 Tests 页签数据源）
final assertionResultsProvider =
    StateProvider<Map<String, List<AssertionResult>>>((ref) => {});

/// 当前活动 Tab 的断言求值结果；未求值过（或已清除）时为 null
final currentAssertionResultsProvider = Provider<List<AssertionResult>?>((ref) {
  final results = ref.watch(assertionResultsProvider);
  final activeTabId = ref.watch(activeTabIdProvider);

  if (activeTabId == null) {
    return null;
  }
  return results[activeTabId];
});
