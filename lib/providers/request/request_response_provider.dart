import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';
import '../../models/http_response.dart';
import '../../services/http_service.dart';
import '../../utils/app_logger.dart';
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

    // 发送前应用环境变量替换（{{variable}}）
    final variables = _ref.read(resolvedVariablesProvider);
    final resolver = _ref.read(variableResolverProvider);
    final resolvedRequest = resolver.resolveRequest(request, variables);

    final unresolved = resolver.findUnresolvedInRequest(request, variables);
    if (unresolved.isNotEmpty) {
      AppLogger.warning(
          '[RequestResponseNotifier] Unresolved variables: ${unresolved.join(', ')}');
    }

    state = {
      ...state,
      tabId: HttpResponse.empty(),
    };

    final response = await _httpService.sendRequest(resolvedRequest);

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
