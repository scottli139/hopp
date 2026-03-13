/// UI 测试模式
///
/// 当应用以 --test-mode 启动时，启动指令服务器，
/// 接收测试指令并执行相应的 UI 操作。
///
/// 使用方法:
///   flutter run -- --test-mode
///   或
///   ./hopp.app/Contents/MacOS/hopp --test-mode

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../models/http_method.dart';
import '../../models/key_value_pair.dart';
import '../../models/http_response.dart';

/// UI 测试模式管理器
class UITestModeManager {
  static final UITestModeManager _instance = UITestModeManager._internal();
  factory UITestModeManager() => _instance;
  UITestModeManager._internal();

  bool _isTestMode = false;
  io.HttpServer? _server;
  int _port = 0;
  WidgetRef? _ref;

  // 指令处理完成后的回调
  final _completers = <String, Completer<dynamic>>{};

  /// 是否处于测试模式
  bool get isTestMode => _isTestMode;

  /// 服务器端口
  int get port => _port;

  /// 初始化测试模式
  Future<void> initialize(List<String> args, WidgetRef ref) async {
    _ref = ref;

    // 检查启动参数
    if (args.contains('--test-mode') || args.contains('--ui-test')) {
      _isTestMode = true;
      await _startTestServer();
    }
  }

  /// 启动测试指令服务器
  Future<void> _startTestServer() async {
    try {
      // 绑定到本地随机端口
      // 使用 anyIPv4 而不是 loopbackIPv4 以避免 macOS 权限问题
      _server = await io.HttpServer.bind(io.InternetAddress.anyIPv4, 0);
      _port = _server!.port;

      print('[UI_TEST] =======================================');
      print('[UI_TEST] 测试服务器启动在端口: $_port');
      print('[UI_TEST] 等待指令...');
      print('[UI_TEST] =======================================');

      // 监听请求
      await for (final request in _server!) {
        await _handleRequest(request);
      }
    } catch (e) {
      print('[UI_TEST] 启动测试服务器失败: $e');
    }
  }

  /// 处理测试指令
  Future<void> _handleRequest(io.HttpRequest request) async {
    final response = request.response;
    response.headers.contentType = io.ContentType.json;

    try {
      // 读取请求体
      final body = await utf8.decoder.bind(request).join();
      final command = jsonDecode(body) as Map<String, dynamic>;

      final action = command['action'] as String;
      final params = command['params'] as Map<String, dynamic>? ?? {};

      print('[UI_TEST] 收到指令: $action, 参数: $params');

      // 执行指令
      final result = await _executeCommand(action, params);

      response.statusCode = io.HttpStatus.ok;
      response.write(jsonEncode({
        'success': true,
        'result': result,
      }));
    } catch (e, stack) {
      print('[UI_TEST] 执行指令失败: $e');
      print(stack);

      response.statusCode = io.HttpStatus.internalServerError;
      response.write(jsonEncode({
        'success': false,
        'error': e.toString(),
      }));
    }

    await response.close();
  }

  /// 执行具体指令
  Future<dynamic> _executeCommand(
      String action, Map<String, dynamic> params) async {
    if (_ref == null) {
      throw Exception('WidgetRef 未初始化');
    }

    switch (action) {
      case 'ping':
        return {'status': 'ok', 'test_mode': true};

      case 'create_request':
        return await _createNewRequest();

      case 'set_url':
        final url = params['url'] as String;
        return await _setUrl(url);

      case 'send_request':
        return await _sendRequest();

      case 'switch_response_tab':
        final tab = params['tab'] as String;
        return await _switchResponseTab(tab);

      case 'set_method':
        final method = params['method'] as String;
        return await _setMethod(method);

      case 'add_header':
        final key = params['key'] as String;
        final value = params['value'] as String;
        return await _addHeader(key, value);

      case 'set_body':
        final body = params['body'] as String;
        final type = params['type'] as String? ?? 'json';
        return await _setBody(body, type);

      case 'get_response_info':
        return await _getResponseInfo();

      case 'wait':
        final milliseconds = params['ms'] as int? ?? 1000;
        await Future.delayed(Duration(milliseconds: milliseconds));
        return {'waited': milliseconds};

      case 'close_tab':
        return await _closeTab();

      case 'save_request':
        return await _saveRequest();

      case 'rename_request':
        final requestId = params['request_id'] as String?;
        final newName = params['new_name'] as String;
        return await _renameRequest(requestId, newName);

      case 'start_edit_request_name':
        final requestId = params['request_id'] as String?;
        return await _startEditRequestName(requestId);

      case 'set_request_name':
        final name = params['name'] as String;
        return await _setRequestName(name);

      case 'confirm_edit_request_name':
        return await _confirmEditRequestName();

      case 'cancel_edit_request_name':
        return await _cancelEditRequestName();

      case 'get_request_info':
        final requestId = params['request_id'] as String?;
        return await _getRequestInfo(requestId);

      case 'get_response_body_info':
        return await _getResponseBodyInfo();

      case 'set_response_display_mode':
        final mode = params['mode'] as String;
        return await _setResponseDisplayMode(mode);

      case 'simulate_large_response':
        final size = params['size'] as int? ?? 100000;
        return await _simulateLargeResponse(size);

      default:
        throw Exception('未知指令: $action');
    }
  }

  /// 创建新请求
  Future<Map<String, dynamic>> _createNewRequest() async {
    final newRequest = HttpRequest.empty();
    _ref!.read(requestTabProvider.notifier).openTab(newRequest);
    _ref!.read(activeTabIdProvider.notifier).state = newRequest.id;

    return {
      'request_id': newRequest.id,
      'name': newRequest.name,
    };
  }

  /// 设置 URL
  Future<Map<String, dynamic>> _setUrl(String url) async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final updatedRequest = activeTab.request.copyWith(url: url);
    _ref!.read(requestTabProvider.notifier).updateRequest(
          activeTab.id,
          updatedRequest,
        );

    return {'url': url};
  }

  /// 设置 HTTP 方法
  Future<Map<String, dynamic>> _setMethod(String method) async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    HttpMethod httpMethod;
    switch (method.toUpperCase()) {
      case 'GET':
        httpMethod = HttpMethod.get;
        break;
      case 'POST':
        httpMethod = HttpMethod.post;
        break;
      case 'PUT':
        httpMethod = HttpMethod.put;
        break;
      case 'DELETE':
        httpMethod = HttpMethod.delete;
        break;
      case 'PATCH':
        httpMethod = HttpMethod.patch;
        break;
      default:
        throw Exception('不支持的 HTTP 方法: $method');
    }

    final updatedRequest = activeTab.request.copyWith(method: httpMethod);
    _ref!.read(requestTabProvider.notifier).updateRequest(
          activeTab.id,
          updatedRequest,
        );

    return {'method': method};
  }

  /// 发送请求
  Future<Map<String, dynamic>> _sendRequest() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    _ref!.read(requestResponseProvider.notifier).sendRequest(
          activeTab.id,
          activeTab.request,
        );

    return {'sent': true, 'request_id': activeTab.id};
  }

  /// 切换响应 Tab
  Future<Map<String, dynamic>> _switchResponseTab(String tab) async {
    // 发送消息通知 UI 切换 Tab
    // 使用 MethodChannel 或直接操作状态
    final validTabs = ['body', 'headers', 'cookies', 'certificate'];
    final tabLower = tab.toLowerCase();

    if (!validTabs.contains(tabLower)) {
      throw Exception('无效的 Tab 名称: $tab, 可选: $validTabs');
    }

    // 存储目标 Tab，UI 组件可以监听这个状态
    _ref!.read(uiTestTargetTabProvider.notifier).state = tabLower;

    return {'tab': tabLower};
  }

  /// 添加 Header
  Future<Map<String, dynamic>> _addHeader(String key, String value) async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final headers = [...activeTab.request.headers];
    headers.add(
        KeyValuePair.empty().copyWith(key: key, value: value, enabled: true));

    final updatedRequest = activeTab.request.copyWith(headers: headers);
    _ref!.read(requestTabProvider.notifier).updateRequest(
          activeTab.id,
          updatedRequest,
        );

    return {'header': '$key: $value'};
  }

  /// 设置 Body
  Future<Map<String, dynamic>> _setBody(String body, String type) async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final updatedRequest = activeTab.request.copyWith(
      body: body,
      bodyType: type,
    );
    _ref!.read(requestTabProvider.notifier).updateRequest(
          activeTab.id,
          updatedRequest,
        );

    return {'body_type': type, 'body_length': body.length};
  }

  /// 获取响应信息
  Future<Map<String, dynamic>> _getResponseInfo() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final response = _ref!.read(requestResponseProvider)[activeTab.id];

    if (response == null) {
      return {'has_response': false};
    }

    return {
      'has_response': true,
      'status_code': response.statusCode,
      'status_text': response.statusText,
      'duration_ms': response.durationMs,
      'size_bytes': response.sizeBytes,
      'content_type': response.headers
          .firstWhere(
            (h) => h.key.toLowerCase() == 'content-type',
            orElse: () => KeyValuePair.empty(),
          )
          .value,
      'has_certificate': response.certificateInfo != null,
    };
  }

  /// 关闭当前 Tab
  Future<Map<String, dynamic>> _closeTab() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    _ref!.read(requestTabProvider.notifier).closeTab(activeTab.id);

    return {'closed': true};
  }

  /// 保存请求
  Future<Map<String, dynamic>> _saveRequest() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    _ref!.read(collectionProvider.notifier).updateRequestInCollection(
          activeTab.request,
        );
    _ref!.read(requestTabProvider.notifier).markAsSaved(activeTab.request.id);

    return {'saved': true};
  }

  /// 直接重命名请求（非交互式）
  Future<Map<String, dynamic>> _renameRequest(
      String? requestId, String newName) async {
    final targetId = requestId ?? _ref!.read(activeTabIdProvider);
    if (targetId == null) {
      throw Exception('没有指定请求 ID，且没有活动的请求 Tab');
    }

    // 查找请求
    HttpRequest? request;
    final activeTab = _ref!.read(requestTabProvider.notifier).getTab(targetId);
    if (activeTab != null) {
      request = activeTab.request;
    } else {
      // 从 Collection 中查找
      request = _findRequestInCollections(targetId);
    }

    if (request == null) {
      throw Exception('未找到请求: $targetId');
    }

    // 更新名称
    final updatedRequest = request.copyWith(name: newName);

    // 更新 Collection
    await _ref!
        .read(collectionProvider.notifier)
        .updateRequestInCollection(updatedRequest);

    // 更新 Tab（如果打开）
    final tab = _ref!.read(requestTabProvider.notifier).getTab(targetId);
    if (tab != null) {
      _ref!
          .read(requestTabProvider.notifier)
          .updateRequest(targetId, updatedRequest);
    }

    return {
      'request_id': targetId,
      'old_name': request.name,
      'new_name': newName,
    };
  }

  /// 开始编辑请求名称（交互式）
  Future<Map<String, dynamic>> _startEditRequestName(String? requestId) async {
    final targetId = requestId ?? _ref!.read(activeTabIdProvider);
    if (targetId == null) {
      throw Exception('没有指定请求 ID，且没有活动的请求 Tab');
    }

    // 查找请求
    HttpRequest? request;
    final activeTab = _ref!.read(requestTabProvider.notifier).getTab(targetId);
    if (activeTab != null) {
      request = activeTab.request;
    } else {
      request = _findRequestInCollections(targetId);
    }

    if (request == null) {
      throw Exception('未找到请求: $targetId');
    }

    // 设置编辑状态
    _ref!.read(uiTestEditingRequestIdProvider.notifier).state = targetId;
    _ref!.read(uiTestEditingRequestNameTextProvider.notifier).state =
        request.name;
    _ref!.read(uiTestEditCompleteProvider.notifier).state = null;

    return {
      'request_id': targetId,
      'current_name': request.name,
      'editing': true,
    };
  }

  /// 设置编辑中的名称文本
  Future<Map<String, dynamic>> _setRequestName(String name) async {
    final editingId = _ref!.read(uiTestEditingRequestIdProvider);
    if (editingId == null) {
      throw Exception('没有正在编辑的请求，请先调用 start_edit_request_name');
    }

    _ref!.read(uiTestEditingRequestNameTextProvider.notifier).state = name;

    return {
      'request_id': editingId,
      'name': name,
    };
  }

  /// 确认编辑请求名称
  Future<Map<String, dynamic>> _confirmEditRequestName() async {
    final editingId = _ref!.read(uiTestEditingRequestIdProvider);
    if (editingId == null) {
      throw Exception('没有正在编辑的请求，请先调用 start_edit_request_name');
    }

    final newName = _ref!.read(uiTestEditingRequestNameTextProvider);
    if (newName.trim().isEmpty) {
      throw Exception('名称不能为空');
    }

    // 查找请求
    HttpRequest? request;
    final activeTab = _ref!.read(requestTabProvider.notifier).getTab(editingId);
    if (activeTab != null) {
      request = activeTab.request;
    } else {
      request = _findRequestInCollections(editingId);
    }

    if (request == null) {
      throw Exception('未找到请求: $editingId');
    }

    final oldName = request.name;

    // 更新请求
    final updatedRequest = request.copyWith(name: newName.trim());

    // 更新 Collection
    await _ref!
        .read(collectionProvider.notifier)
        .updateRequestInCollection(updatedRequest);

    // 更新 Tab（如果打开）
    if (activeTab != null) {
      _ref!
          .read(requestTabProvider.notifier)
          .updateRequest(editingId, updatedRequest);
    }

    // 清除编辑状态
    _ref!.read(uiTestEditingRequestIdProvider.notifier).state = null;
    _ref!.read(uiTestEditingRequestNameTextProvider.notifier).state = '';
    _ref!.read(uiTestEditCompleteProvider.notifier).state = {
      'request_id': editingId,
      'old_name': oldName,
      'new_name': newName,
      'confirmed': true,
    };

    return {
      'request_id': editingId,
      'old_name': oldName,
      'new_name': newName,
      'confirmed': true,
    };
  }

  /// 取消编辑请求名称
  Future<Map<String, dynamic>> _cancelEditRequestName() async {
    final editingId = _ref!.read(uiTestEditingRequestIdProvider);
    if (editingId == null) {
      throw Exception('没有正在编辑的请求');
    }

    // 清除编辑状态
    _ref!.read(uiTestEditingRequestIdProvider.notifier).state = null;
    _ref!.read(uiTestEditingRequestNameTextProvider.notifier).state = '';
    _ref!.read(uiTestEditCompleteProvider.notifier).state = {
      'request_id': editingId,
      'cancelled': true,
    };

    return {
      'request_id': editingId,
      'cancelled': true,
    };
  }

  /// 获取请求信息
  Future<Map<String, dynamic>> _getRequestInfo(String? requestId) async {
    final targetId = requestId ?? _ref!.read(activeTabIdProvider);
    if (targetId == null) {
      throw Exception('没有指定请求 ID，且没有活动的请求 Tab');
    }

    // 查找请求
    HttpRequest? request;
    final activeTab = _ref!.read(requestTabProvider.notifier).getTab(targetId);
    if (activeTab != null) {
      request = activeTab.request;
    } else {
      request = _findRequestInCollections(targetId);
    }

    if (request == null) {
      throw Exception('未找到请求: $targetId');
    }

    // 检查是否有响应
    final response = _ref!.read(requestResponseProvider)[targetId];

    return {
      'request_id': request.id,
      'name': request.name,
      'method': request.method.value,
      'url': request.url,
      'has_response': response != null,
      'is_open_in_tab': activeTab != null,
    };
  }

  /// 在 Collection 中查找请求
  HttpRequest? _findRequestInCollections(String requestId) {
    final collectionsAsync = _ref!.read(collectionProvider);

    if (collectionsAsync case AsyncData(:final value)) {
      HttpRequest? findInCollections(List<Collection> collections) {
        for (final collection in collections) {
          // 检查当前 collection 的请求
          try {
            final request = collection.requests.firstWhere(
              (r) => r.id == requestId,
            );
            return request;
          } catch (_) {
            // 未找到，继续检查子 collection
          }

          // 递归检查子 collection
          if (collection.children.isNotEmpty) {
            final found = findInCollections(collection.children);
            if (found != null) return found;
          }
        }
        return null;
      }

      return findInCollections(value);
    }

    return null;
  }

  /// 获取响应体信息
  Future<Map<String, dynamic>> _getResponseBodyInfo() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final response = _ref!.read(requestResponseProvider)[activeTab.id];

    if (response == null || response.body == null) {
      return {'has_body': false};
    }

    final body = response.body!;
    final lines = body.split('\n');

    return {
      'has_body': true,
      'size_bytes': body.length,
      'size_kb': (body.length / 1024).toStringAsFixed(2),
      'line_count': lines.length,
      'preview': body.length > 200 ? body.substring(0, 200) : body,
    };
  }

  /// 设置响应显示模式
  Future<Map<String, dynamic>> _setResponseDisplayMode(String mode) async {
    final validModes = ['auto', 'performance', 'full', 'raw'];
    final modeLower = mode.toLowerCase();

    if (!validModes.contains(modeLower)) {
      throw Exception('无效的显示模式: $mode, 可选: $validModes');
    }

    // 存储目标显示模式，UI 组件可以监听这个状态
    _ref!.read(uiTestResponseDisplayModeProvider.notifier).state = modeLower;

    return {'mode': modeLower};
  }

  /// 模拟大响应（用于测试性能优化）
  Future<Map<String, dynamic>> _simulateLargeResponse(int size) async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    // 生成大 JSON 数据
    final buffer = StringBuffer();
    buffer.writeln('{');
    buffer.writeln('  "data": [');

    final itemCount = size ~/ 100; // 每个项目约 100 字节
    for (var i = 0; i < itemCount; i++) {
      buffer.write('    {"id": $i, "name": "Item $i", "value": ${i * 10}}');
      if (i < itemCount - 1) {
        buffer.writeln(',');
      } else {
        buffer.writeln();
      }
    }

    buffer.writeln('  ],');
    buffer.writeln('  "total": $itemCount,');
    buffer.writeln('  "page": 1,');
    buffer.writeln('  "size": $itemCount');
    buffer.writeln('}');

    final largeBody = buffer.toString();

    // 创建模拟响应
    final mockResponse = HttpResponse(
      statusCode: 200,
      statusText: 'OK',
      body: largeBody,
      headers: [
        KeyValuePair.empty().copyWith(
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        ),
        KeyValuePair.empty().copyWith(
          key: 'Content-Length',
          value: largeBody.length.toString(),
          enabled: true,
        ),
      ],
      durationMs: 150,
      sizeBytes: largeBody.length,
    );

    // 设置响应
    _ref!.read(requestResponseProvider.notifier).setMockResponse(
          activeTab.id,
          mockResponse,
        );

    return {
      'simulated': true,
      'size_bytes': largeBody.length,
      'size_kb': (largeBody.length / 1024).toStringAsFixed(2),
      'line_count': largeBody.split('\n').length,
    };
  }

  /// 关闭测试服务器
  Future<void> dispose() async {
    await _server?.close();
    _server = null;
  }
}

/// UI 测试目标 Tab 状态
final uiTestTargetTabProvider = StateProvider<String?>((ref) => null);

/// UI 测试 - 当前正在编辑的请求 ID
final uiTestEditingRequestIdProvider = StateProvider<String?>((ref) => null);

/// UI 测试 - 当前编辑的名称文本
final uiTestEditingRequestNameTextProvider = StateProvider<String>((ref) => '');

/// UI 测试 - 编辑完成通知
final uiTestEditCompleteProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// UI 测试 - 响应显示模式
final uiTestResponseDisplayModeProvider =
    StateProvider<String>((ref) => 'auto');
