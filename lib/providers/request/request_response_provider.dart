import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';
import '../../models/http_response.dart';
import '../../services/http_service.dart';
import '../core/providers.dart';
import 'request_tab_provider.dart';

class RequestResponseNotifier extends StateNotifier<Map<String, HttpResponse>> {
  final HttpService _httpService;

  RequestResponseNotifier(this._httpService) : super({});

  Future<void> sendRequest(String tabId, HttpRequest request) async {
    state = {
      ...state,
      tabId: HttpResponse.empty(),
    };

    final response = await _httpService.sendRequest(request);

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
