import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../models/http_response.dart';
import '../../models/pre_request_step.dart';
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
        // 链失败不发目标请求，错误呈现在响应区
        state = {
          ...state,
          tabId: HttpResponse.error('预请求链执行失败：${result.firstError}'),
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

    state = {
      ...state,
      tabId: response,
    };
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
      storageService: _ref.read(storageServiceProvider),
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
  }

  void clearAll() {
    state = {};
  }

  /// 设置模拟响应（用于测试）
  void setMockResponse(String tabId, HttpResponse response) {
    AppLogger.info(
      '[RequestResponseNotifier] Setting mock response for tab $tabId: '
      '${response.statusCode}, size: ${response.sizeBytes} bytes',
    );
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
