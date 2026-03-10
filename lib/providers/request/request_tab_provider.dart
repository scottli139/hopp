import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';
import '../../models/request_tab.dart';

class RequestTabNotifier extends StateNotifier<List<RequestTab>> {
  RequestTabNotifier() : super([]);

  void openTab(HttpRequest request) {
    final existingIndex = state.indexWhere((tab) => tab.id == request.id);
    
    if (existingIndex != -1) {
      // Update last accessed and move to end
      final updatedTabs = [...state];
      updatedTabs[existingIndex] = updatedTabs[existingIndex].copyWith(
        lastAccessed: DateTime.now(),
      );
      state = updatedTabs;
    } else {
      // Add new tab
      state = [...state, RequestTab.fromRequest(request)];
    }
  }

  void closeTab(String tabId) {
    state = state.where((tab) => tab.id != tabId).toList();
  }

  void closeAllTabs() {
    state = [];
  }

  void closeOtherTabs(String keepTabId) {
    state = state.where((tab) => tab.id == keepTabId).toList();
  }

  void updateRequest(String tabId, HttpRequest request) {
    state = state.map((tab) {
      if (tab.id == tabId) {
        return tab.copyWith(
          request: request,
          isDirty: true,
        );
      }
      return tab;
    }).toList();
  }

  void markAsSaved(String tabId) {
    state = state.map((tab) {
      if (tab.id == tabId) {
        return tab.copyWith(isDirty: false);
      }
      return tab;
    }).toList();
  }

  RequestTab? getTab(String tabId) {
    try {
      return state.firstWhere((tab) => tab.id == tabId);
    } catch (e) {
      return null;
    }
  }

  int get tabCount => state.length;
}

final requestTabProvider = StateNotifierProvider<RequestTabNotifier, List<RequestTab>>((ref) {
  return RequestTabNotifier();
});

final activeTabIdProvider = StateProvider<String?>((ref) => null);

final activeTabProvider = Provider<RequestTab?>((ref) {
  final tabs = ref.watch(requestTabProvider);
  final activeId = ref.watch(activeTabIdProvider);
  
  if (activeId == null) return null;
  
  try {
    return tabs.firstWhere((tab) => tab.id == activeId);
  } catch (e) {
    return null;
  }
});
