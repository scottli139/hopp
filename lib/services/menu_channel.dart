import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/request/request_tab_provider.dart';
import '../models/http_request.dart';
import '../utils/app_logger.dart';

/// macOS 菜单通道服务
/// 
/// 处理从 macOS 系统菜单发送的命令
class MenuChannelService {
  static const MethodChannel _channel = MethodChannel('com.example.hopp/menu');
  static ProviderContainer? _container;
  
  /// 初始化菜单通道
  static void initialize(ProviderContainer container) {
    _container = container;
    
    _channel.setMethodCallHandler((call) async {
      AppLogger.info('[MenuChannel] Received: ${call.method}');
      
      switch (call.method) {
        case 'new_request':
          _handleNewRequest();
          break;
        case 'new_collection':
          _handleNewCollection();
          break;
        case 'save_request':
          _handleSaveRequest();
          break;
        case 'save_as':
          _handleSaveAs();
          break;
        case 'close_tab':
          _handleCloseTab();
          break;
        case 'send_request':
          _handleSendRequest();
          break;
        default:
          AppLogger.warning('[MenuChannel] Unknown method: ${call.method}');
      }
      
      return null;
    });
    
    AppLogger.info('[MenuChannel] Initialized');
  }
  
  /// 处理新建请求
  static void _handleNewRequest() {
    AppLogger.info('[MenuChannel] Creating new request');
    
    try {
      final container = _container;
      if (container == null) {
        AppLogger.error('[MenuChannel] ProviderContainer not initialized');
        return;
      }
      
      final tabsBefore = container.read(requestTabProvider);
      AppLogger.info('[MenuChannel] BEFORE: ${tabsBefore.length} tabs');
      
      final notifier = container.read(requestTabProvider.notifier);
      final newRequest = HttpRequest.empty();
      
      notifier.openTab(newRequest);
      container.read(activeTabIdProvider.notifier).state = newRequest.id;
      
      final tabsAfter = container.read(requestTabProvider);
      AppLogger.info('[MenuChannel] AFTER: ${tabsAfter.length} tabs - [${tabsAfter.map((t) => t.request.name).join(", ")}]');
    } catch (e, stack) {
      AppLogger.error('[MenuChannel] Failed to create new request', e, stack);
    }
  }
  
  /// 处理新建集合
  static void _handleNewCollection() {
    AppLogger.info('[MenuChannel] Creating new collection');
    // TODO: 实现新建集合
  }
  
  /// 处理保存请求
  static void _handleSaveRequest() {
    AppLogger.info('[MenuChannel] Saving request');
    
    try {
      final container = _container;
      if (container == null) return;
      
      final activeTab = container.read(activeTabProvider);
      if (activeTab == null) {
        AppLogger.warning('[MenuChannel] No active tab');
        return;
      }
      
      final collectionNotifier = container.read(collectionProvider.notifier);
      collectionNotifier.updateRequestInCollection(activeTab.request);
      AppLogger.info('[MenuChannel] Request saved');
    } catch (e, stack) {
      AppLogger.error('[MenuChannel] Failed to save request', e, stack);
    }
  }
  
  /// 处理另存为
  static void _handleSaveAs() {
    AppLogger.info('[MenuChannel] Save As');
    _handleSaveRequest();
  }
  
  /// 处理关闭标签
  static void _handleCloseTab() {
    AppLogger.info('[MenuChannel] Closing tab');
    
    try {
      final container = _container;
      if (container == null) return;
      
      final activeTab = container.read(activeTabProvider);
      if (activeTab == null) {
        AppLogger.warning('[MenuChannel] No active tab');
        return;
      }
      
      final notifier = container.read(requestTabProvider.notifier);
      notifier.closeTab(activeTab.id);
      AppLogger.info('[MenuChannel] Tab closed');
    } catch (e, stack) {
      AppLogger.error('[MenuChannel] Failed to close tab', e, stack);
    }
  }
  
  /// 处理发送请求
  static void _handleSendRequest() {
    AppLogger.info('[MenuChannel] Sending request');
    
    try {
      final container = _container;
      if (container == null) return;
      
      final activeTab = container.read(activeTabProvider);
      if (activeTab == null) {
        AppLogger.warning('[MenuChannel] No active tab');
        return;
      }
      
      final notifier = container.read(requestResponseProvider.notifier);
      notifier.sendRequest(activeTab.id, activeTab.request);
      AppLogger.info('[MenuChannel] Request sent');
    } catch (e, stack) {
      AppLogger.error('[MenuChannel] Failed to send request', e, stack);
    }
  }
}
