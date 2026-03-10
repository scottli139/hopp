import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';
import '../../models/http_response.dart';
import '../../services/http_service.dart';
import '../../utils/app_logger.dart';
import '../core/providers.dart';
import 'request_tab_provider.dart';

class RequestResponseNotifier extends StateNotifier<Map<String, HttpResponse>> {
  final HttpService _httpService;

  RequestResponseNotifier(this._httpService) : super({});

  Future<void> sendRequest(String tabId, HttpRequest request) async {
    AppLogger.info('[RequestResponseNotifier] Sending request for tab $tabId: ${request.method.value} ${request.url}');
    state = {
      ...state,
      tabId: HttpResponse.empty(),
    };

    final response = await _httpService.sendRequest(request);
    
    if (response.error != null) {
      AppLogger.warning('[RequestResponseNotifier] Request failed: ${response.error}');
    } else {
      AppLogger.info('[RequestResponseNotifier] Request completed: ${response.statusCode} in ${response.durationMs}ms');
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
}

final requestResponseProvider =
    StateNotifierProvider<RequestResponseNotifier, Map<String, HttpResponse>>(
        (ref) {
  final httpService = ref.watch(httpServiceProvider);
  return RequestResponseNotifier(httpService);
});

final currentResponseProvider = Provider<HttpResponse?>((ref) {
  final responses = ref.watch(requestResponseProvider);
  final activeTabId = ref.watch(activeTabIdProvider);

  if (activeTabId == null) return null;
  return responses[activeTabId];
});
