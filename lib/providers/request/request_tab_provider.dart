import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';
import '../../models/request_tab.dart';
import '../../utils/app_logger.dart';

class RequestTabNotifier extends StateNotifier<List<RequestTab>> {
  RequestTabNotifier() : super([]);

  void openTab(HttpRequest request) {
    final existingIndex = state.indexWhere((tab) => tab.id == request.id);

    if (existingIndex != -1) {
      // Update last accessed and move to end
      AppLogger.debug(
          '[RequestTabNotifier] Tab already open, updating: ${request.id}');
      final updatedTabs = [...state];
      updatedTabs[existingIndex] = updatedTabs[existingIndex].copyWith(
        lastAccessed: DateTime.now(),
      );
      state = updatedTabs;
    } else {
      // Add new tab
      AppLogger.info(
          '[RequestTabNotifier] Opening new tab: ${request.name} (${request.id})');
      state = [...state, RequestTab.fromRequest(request)];
      AppLogger.debug('[RequestTabNotifier] Total tabs: ${state.length}');
    }
  }

  void closeTab(String tabId) {
    AppLogger.debug('[RequestTabNotifier] Closing tab: $tabId');
    state = state.where((tab) => tab.id != tabId).toList();
    AppLogger.debug('[RequestTabNotifier] Total tabs: ${state.length}');
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

final requestTabProvider =
    StateNotifierProvider<RequestTabNotifier, List<RequestTab>>((ref) {
  return RequestTabNotifier();
});

final activeTabIdProvider = StateProvider<String?>((ref) => null);

/// 请求编辑器当前选中的子 Tab 索引（Params/Headers/Body/Auth/Settings）
///
/// 编辑器 State 可能因布局重建（如调整分栏）被销毁重建，
/// 将索引保存在 provider 中以便重建后恢复，避免被重置回 Params。
final requestEditorTabIndexProvider = StateProvider<int>((ref) => 0);

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
