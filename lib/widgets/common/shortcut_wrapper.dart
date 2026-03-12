import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../providers/request/request_tab_provider.dart';
import '../../models/http_request.dart';
import '../../utils/app_logger.dart';

/// 快捷键包装器
/// 
/// 为应用提供全局快捷键支持
class ShortcutWrapper extends ConsumerStatefulWidget {
  final Widget child;
  
  const ShortcutWrapper({
    super.key,
    required this.child,
  });
  
  @override
  ConsumerState<ShortcutWrapper> createState() => _ShortcutWrapperState();
}

class _ShortcutWrapperState extends ConsumerState<ShortcutWrapper> {
  final FocusNode _focusNode = FocusNode();
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    AppLogger.info('[ShortcutWrapper] Building with Shortcuts + Actions');
    
    return Shortcuts(
      shortcuts: {
        // Cmd+N: 新建请求
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): 
            const NewRequestIntent(),
        // Cmd+Enter: 发送请求
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): 
            const SendRequestIntent(),
        // Cmd+S: 保存请求
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): 
            const SaveRequestIntent(),
        // Cmd+Shift+S: 另存为
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true): 
            const SaveAsIntent(),
        // Cmd+W: 关闭标签
        const SingleActivator(LogicalKeyboardKey.keyW, meta: true): 
            const CloseTabIntent(),
        // Cmd+1-9: 切换标签
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true): 
            const SwitchTabIntent(0),
        const SingleActivator(LogicalKeyboardKey.digit2, meta: true): 
            const SwitchTabIntent(1),
        const SingleActivator(LogicalKeyboardKey.digit3, meta: true): 
            const SwitchTabIntent(2),
        const SingleActivator(LogicalKeyboardKey.digit4, meta: true): 
            const SwitchTabIntent(3),
        const SingleActivator(LogicalKeyboardKey.digit5, meta: true): 
            const SwitchTabIntent(4),
        const SingleActivator(LogicalKeyboardKey.digit6, meta: true): 
            const SwitchTabIntent(5),
        const SingleActivator(LogicalKeyboardKey.digit7, meta: true): 
            const SwitchTabIntent(6),
        const SingleActivator(LogicalKeyboardKey.digit8, meta: true): 
            const SwitchTabIntent(7),
        const SingleActivator(LogicalKeyboardKey.digit9, meta: true): 
            const SwitchTabIntent(8),
      },
      child: Actions(
        actions: {
          NewRequestIntent: CallbackAction<NewRequestIntent>(
            onInvoke: (intent) {
              AppLogger.info('[ShortcutWrapper] Cmd+N triggered via Actions');
              _handleNewRequest();
              return null;
            },
          ),
          SendRequestIntent: CallbackAction<SendRequestIntent>(
            onInvoke: (intent) {
              AppLogger.info('[ShortcutWrapper] Cmd+Enter triggered');
              _handleSendRequest();
              return null;
            },
          ),
          SaveRequestIntent: CallbackAction<SaveRequestIntent>(
            onInvoke: (intent) {
              AppLogger.info('[ShortcutWrapper] Cmd+S triggered');
              _handleSaveRequest();
              return null;
            },
          ),
          SaveAsIntent: CallbackAction<SaveAsIntent>(
            onInvoke: (intent) {
              AppLogger.info('[ShortcutWrapper] Cmd+Shift+S triggered');
              _handleSaveAs();
              return null;
            },
          ),
          CloseTabIntent: CallbackAction<CloseTabIntent>(
            onInvoke: (intent) {
              AppLogger.info('[ShortcutWrapper] Cmd+W triggered');
              _handleCloseTab();
              return null;
            },
          ),
          SwitchTabIntent: CallbackAction<SwitchTabIntent>(
            onInvoke: (intent) {
              AppLogger.info('[ShortcutWrapper] Cmd+${intent.index + 1} triggered');
              _handleSwitchTab(intent.index);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          canRequestFocus: true,
          focusNode: _focusNode,
          child: widget.child,
        ),
      ),
    );
  }
  
  /// 处理新建请求
  void _handleNewRequest() {
    AppLogger.info('[ShortcutWrapper] Handling new request');
    
    try {
      // 记录创建前的状态
      final tabsBefore = ref.read(requestTabProvider);
      AppLogger.info('[ShortcutWrapper] BEFORE: ${tabsBefore.length} tabs - '
          '[${tabsBefore.map((t) => t.request.name).join(", ")}]');
      
      final notifier = ref.read(requestTabProvider.notifier);
      final newRequest = HttpRequest.empty();
      AppLogger.debug('[ShortcutWrapper] Creating request: ${newRequest.id}');
      
      notifier.openTab(newRequest);
      ref.read(activeTabIdProvider.notifier).state = newRequest.id;
      
      // 记录创建后的状态
      final tabsAfter = ref.read(requestTabProvider);
      AppLogger.info('[ShortcutWrapper] AFTER: ${tabsAfter.length} tabs - '
          '[${tabsAfter.map((t) => t.request.name).join(", ")}]');
    } catch (e, stack) {
      AppLogger.error('[ShortcutWrapper] Failed to create new request', e, stack);
    }
  }
  
  /// 处理发送请求
  void _handleSendRequest() {
    AppLogger.info('[ShortcutWrapper] Handling send request');
    
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) {
      AppLogger.warning('[ShortcutWrapper] No active tab');
      return;
    }
    
    try {
      final notifier = ref.read(requestResponseProvider.notifier);
      notifier.sendRequest(activeTab.id, activeTab.request);
      AppLogger.info('[ShortcutWrapper] Request sent');
    } catch (e, stack) {
      AppLogger.error('[ShortcutWrapper] Failed to send request', e, stack);
    }
  }
  
  /// 处理保存请求
  void _handleSaveRequest() {
    AppLogger.info('[ShortcutWrapper] Handling save request');
    
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) {
      AppLogger.warning('[ShortcutWrapper] No active tab');
      return;
    }
    
    try {
      final collectionNotifier = ref.read(collectionProvider.notifier);
      collectionNotifier.updateRequestInCollection(activeTab.request);
      AppLogger.info('[ShortcutWrapper] Request saved');
    } catch (e, stack) {
      AppLogger.error('[ShortcutWrapper] Failed to save request', e, stack);
    }
  }
  
  /// 处理关闭标签
  void _handleCloseTab() {
    AppLogger.info('[ShortcutWrapper] Handling close tab');
    
    final activeTab = ref.read(activeTabProvider);
    if (activeTab == null) {
      AppLogger.warning('[ShortcutWrapper] No active tab');
      return;
    }
    
    try {
      final notifier = ref.read(requestTabProvider.notifier);
      notifier.closeTab(activeTab.id);
      AppLogger.info('[ShortcutWrapper] Tab closed');
    } catch (e, stack) {
      AppLogger.error('[ShortcutWrapper] Failed to close tab', e, stack);
    }
  }
  
  /// 处理另存为
  void _handleSaveAs() {
    AppLogger.info('[ShortcutWrapper] Handling save as');
    _handleSaveRequest();
  }
  
  /// 处理切换标签
  void _handleSwitchTab(int index) {
    AppLogger.info('[ShortcutWrapper] Handling switch tab to index: $index');
    
    final tabs = ref.read(requestTabProvider);
    if (index < 0 || index >= tabs.length) {
      AppLogger.warning('[ShortcutWrapper] Invalid tab index: $index');
      return;
    }
    
    try {
      ref.read(activeTabIdProvider.notifier).state = tabs[index].id;
      AppLogger.info('[ShortcutWrapper] Switched to tab: ${tabs[index].id}');
    } catch (e, stack) {
      AppLogger.error('[ShortcutWrapper] Failed to switch tab', e, stack);
    }
  }
}

/// Intents for shortcuts
class NewRequestIntent extends Intent {
  const NewRequestIntent();
}

class SendRequestIntent extends Intent {
  const SendRequestIntent();
}

class SaveRequestIntent extends Intent {
  const SaveRequestIntent();
}

class SaveAsIntent extends Intent {
  const SaveAsIntent();
}

class CloseTabIntent extends Intent {
  const CloseTabIntent();
}

class SwitchTabIntent extends Intent {
  final int index;
  const SwitchTabIntent(this.index);
}
