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

import '../../providers/import_export/import_export_provider.dart';
import '../../providers/providers.dart';
import '../../services/import_export/postman_import_service.dart';
import '../../utils/app_logger.dart';
import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../models/http_method.dart';
import '../../models/http_request_info.dart';
import '../../models/key_value_pair.dart';
import '../../models/http_response.dart';
import '../../models/timing_info.dart';

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

      case 'get_request_details':
        return await _getRequestDetails();

      case 'simulate_response_with_timing':
        return await _simulateResponseWithTiming();

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

      case 'get_timing_info':
        return await _getTimingInfo();

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

      case 'click_new_tab_button':
        return await _clickNewTabButton();

      case 'get_ui_info':
        return await _getUIInfo();

      case 'expand_method_dropdown':
        return await _expandMethodDropdown();

      case 'expand_raw_content_type_dropdown':
        return await _expandRawContentTypeDropdown();

      case 'switch_request_tab':
        final tab = params['tab'] as String;
        return await _switchRequestTab(tab);

      case 'scroll_response':
        final direction = params['direction'] as String? ?? 'down';
        final amount = params['amount'] as int? ?? 100;
        return await _scrollResponse(direction, amount);

      case 'set_window_size':
        final width = params['width'] as int?;
        final height = params['height'] as int?;
        return await _setWindowSize(width, height);

      case 'set_divider_position':
        final ratio = params['ratio'] as double? ?? 0.5;
        return await _setDividerPosition(ratio);

      case 'focus_url_input':
        return await _focusUrlInput();

      case 'get_request_editor_info':
        return await _getRequestEditorInfo();

      case 'add_param':
        final key = params['key'] as String;
        final value = params['value'] as String;
        return await _addParam(key, value);

      case 'add_header_with_description':
        final key = params['key'] as String;
        final value = params['value'] as String;
        final description = params['description'] as String?;
        return await _addHeaderWithDescription(key, value, description);

      case 'set_body_type':
        final bodyType = params['body_type'] as String;
        return await _setBodyType(bodyType);

      case 'set_raw_content_type':
        final contentType = params['content_type'] as String;
        return await _setRawContentType(contentType);

      case 'get_body_info':
        return await _getBodyInfo();

      case 'beautify_code':
        return await _beautifyCode();

      case 'capture_screenshot':
        final name = params['name'] as String? ?? 'screenshot';
        return await _captureScreenshot(name);

      case 'get_collections':
        return await _getCollections();

      case 'import_collection':
        final filePath = params['file_path'] as String;
        return await _importCollection(filePath);

      case 'trigger_import_dialog':
        return await _triggerImportDialog();

      case 'trigger_export_dialog':
        return await _triggerExportDialog();

      case 'simulate_4xx_response':
        final statusCode = params['status_code'] as int? ?? 400;
        return await _simulate4xxResponse(statusCode);

      case 'simulate_5xx_response':
        final statusCode = params['status_code'] as int? ?? 500;
        return await _simulate5xxResponse(statusCode);

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
    final validTabs = [
      'body',
      'headers',
      'cookies',
      'timing',
      'certificate',
      'request'
    ];
    final tabLower = tab.toLowerCase();

    if (!validTabs.contains(tabLower)) {
      throw Exception('无效的 Tab 名称: $tab, 可选: $validTabs');
    }

    // 存储目标 Tab，UI 组件可以监听这个状态
    _ref!.read(uiTestTargetTabProvider.notifier).state = tabLower;

    return {'tab': tabLower};
  }

  /// 模拟带时间分析的响应（用于测试 Timing Tab）
  Future<Map<String, dynamic>> _simulateResponseWithTiming() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final request = activeTab.request;
    final uri = Uri.parse(request.url);

    // 构建查询参数
    final enabledParams =
        request.params.where((p) => p.enabled && p.key.isNotEmpty).toList();
    String fullUrl = request.url;
    if (enabledParams.isNotEmpty) {
      final queryString = enabledParams
          .map((p) =>
              '${Uri.encodeComponent(p.key)}=${Uri.encodeComponent(p.value)}')
          .join('&');
      final separator = fullUrl.contains('?') ? '&' : '?';
      fullUrl = '$fullUrl$separator$queryString';
    }

    // 构建 headers：用户添加的 + 自动添加的
    final headers = <KeyValuePair>[];

    // 用户添加的 headers
    for (final header in request.headers) {
      if (header.enabled && header.key.isNotEmpty) {
        headers.add(KeyValuePair(
          id: header.id,
          key: header.key,
          value: header.value,
          enabled: true,
        ));
      }
    }

    // 自动添加的 headers
    final autoHeaders = [
      KeyValuePair.empty().copyWith(
        key: 'User-Agent',
        value: 'Hopp/1.0 (Flutter HTTP Client)',
        enabled: true,
      ),
      KeyValuePair.empty().copyWith(
        key: 'Accept',
        value: '*/*',
        enabled: true,
      ),
      KeyValuePair.empty().copyWith(
        key: 'Accept-Encoding',
        value: 'gzip',
        enabled: true,
      ),
    ];

    // 只添加不存在重复 key 的自动 headers
    for (final autoHeader in autoHeaders) {
      final exists = headers.any(
        (h) => h.key.toLowerCase() == autoHeader.key.toLowerCase(),
      );
      if (!exists) {
        headers.add(autoHeader);
      }
    }

    // 创建请求信息
    final requestInfo = HttpRequestInfo(
      method: request.method.value.toUpperCase(),
      baseUrl: request.url,
      fullUrl: fullUrl,
      scheme: uri.scheme.isNotEmpty ? uri.scheme : 'https',
      host: uri.host.isNotEmpty ? uri.host : 'example.com',
      path: uri.path.isNotEmpty ? uri.path : '/',
      port: uri.hasPort ? uri.port : null,
      queryParams: enabledParams
          .map((p) => KeyValuePair(
                id: p.id,
                key: p.key,
                value: p.value,
                enabled: true,
              ))
          .toList(),
      headers: headers,
      body: request.body.isNotEmpty && request.bodyType != 'none'
          ? request.body
          : null,
      bodyType: request.bodyType != 'none' ? request.bodyType : null,
      bodySize: request.body.isNotEmpty ? request.body.length : null,
      timestamp: DateTime.now(),
    );

    // 创建带时间信息的模拟响应
    final mockResponse = HttpResponse(
      statusCode: 200,
      statusText: 'OK',
      body: '{"message": "Hello, World!", "status": "success"}',
      headers: [
        KeyValuePair.empty().copyWith(
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        ),
        KeyValuePair.empty().copyWith(
          key: 'Content-Length',
          value: '50',
          enabled: true,
        ),
      ],
      durationMs: 245,
      sizeBytes: 50,
      timingInfo: const TimingInfo(
        dnsMs: 12,
        tcpMs: 25,
        tlsMs: 45,
        ttfbMs: 56,
        downloadMs: 107,
        totalMs: 245,
      ),
      requestInfo: requestInfo,
    );

    // 设置响应
    _ref!.read(requestResponseProvider.notifier).setMockResponse(
          activeTab.id,
          mockResponse,
        );

    return {
      'simulated': true,
      'has_timing': true,
      'total_ms': 245,
      'has_request_info': true,
    };
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
      'has_timing': response.timingInfo != null,
    };
  }

  /// 获取时间分析信息
  Future<Map<String, dynamic>> _getTimingInfo() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final response = _ref!.read(requestResponseProvider)[activeTab.id];

    if (response == null) {
      return {'has_response': false};
    }

    final timing = response.timingInfo;
    if (timing == null) {
      return {
        'has_response': true,
        'has_timing': false,
      };
    }

    return {
      'has_response': true,
      'has_timing': true,
      'dns_ms': timing.dnsMs,
      'tcp_ms': timing.tcpMs,
      'tls_ms': timing.tlsMs,
      'ttfb_ms': timing.ttfbMs,
      'download_ms': timing.downloadMs,
      'total_ms': timing.totalMs,
      'dns_formatted': timing.dnsFormatted,
      'tcp_formatted': timing.tcpFormatted,
      'tls_formatted': timing.tlsFormatted,
      'ttfb_formatted': timing.ttfbFormatted,
      'download_formatted': timing.downloadFormatted,
      'total_formatted': timing.totalFormatted,
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

    // Use the new saveRequest method that handles both new and existing requests
    await _ref!
        .read(collectionProvider.notifier)
        .saveRequest(activeTab.request);
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

  /// 获取请求详情（用于 Request Tab）
  Future<Map<String, dynamic>> _getRequestDetails() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final request = activeTab.request;

    // 构建完整 URL（包含查询参数）
    final enabledParams =
        request.params.where((p) => p.enabled && p.key.isNotEmpty).toList();
    String fullUrl = request.url;
    if (enabledParams.isNotEmpty) {
      final queryString = enabledParams
          .map((p) =>
              '${Uri.encodeComponent(p.key)}=${Uri.encodeComponent(p.value)}')
          .join('&');
      final separator = fullUrl.contains('?') ? '&' : '?';
      fullUrl = '$fullUrl$separator$queryString';
    }

    // 获取 enabled headers
    final enabledHeaders = request.headers
        .where((h) => h.enabled && h.key.isNotEmpty)
        .map((h) => {'key': h.key, 'value': h.value})
        .toList();

    // 检查是否有响应和 requestInfo
    final response = _ref!.read(requestResponseProvider)[activeTab.id];
    final requestInfo = response?.requestInfo;

    // 如果有 requestInfo，使用它来提供实际发送的请求详情
    if (requestInfo != null) {
      return {
        'method': requestInfo.method,
        'url': requestInfo.baseUrl,
        'full_url': requestInfo.fullUrl,
        'scheme': requestInfo.scheme,
        'host': requestInfo.host,
        'path': requestInfo.path,
        'port': requestInfo.port,
        'query_params_count': requestInfo.queryParams.length,
        'query_params': requestInfo.queryParams
            .map((p) => {'key': p.key, 'value': p.value})
            .toList(),
        'headers_count': requestInfo.headers.length,
        'headers': requestInfo.headers
            .map((h) => {'key': h.key, 'value': h.value})
            .toList(),
        'has_body': requestInfo.hasBody,
        'body_type': requestInfo.bodyType,
        'body_size': requestInfo.bodySize,
        'body_preview':
            requestInfo.body != null && requestInfo.body!.length > 200
                ? requestInfo.body!.substring(0, 200)
                : requestInfo.body,
        'user_agent': requestInfo.userAgent,
        'content_type': requestInfo.contentType,
        'authorization': requestInfo.authorization != null ? '***' : null,
        'has_request_info': true,
      };
    }

    // 否则返回原始的请求详情
    return {
      'method': request.method.value,
      'url': request.url,
      'full_url': fullUrl,
      'headers_count': enabledHeaders.length,
      'headers': enabledHeaders,
      'has_body': request.body.isNotEmpty && request.bodyType != 'none',
      'body_type': request.bodyType,
      'body_length': request.body.length,
      'body_preview': request.body.length > 200
          ? request.body.substring(0, 200)
          : request.body,
      'has_request_info': false,
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

    final request = activeTab.request;

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

    // 创建请求信息
    final requestInfo = HttpRequestInfo(
      method: request.method.value.toUpperCase(),
      baseUrl: request.url,
      fullUrl: request.url,
      scheme: 'https',
      host: Uri.parse(request.url).host,
      path: Uri.parse(request.url).path,
      headers: [
        KeyValuePair.empty().copyWith(
          key: 'Accept',
          value: '*/*',
          enabled: true,
        ),
        KeyValuePair.empty().copyWith(
          key: 'User-Agent',
          value: 'Hopp/1.0 (Flutter HTTP Client)',
          enabled: true,
        ),
      ],
      timestamp: DateTime.now(),
    );

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
      requestInfo: requestInfo,
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

  /// 点击新建标签按钮
  Future<Map<String, dynamic>> _clickNewTabButton() async {
    final newRequest = HttpRequest.empty();
    _ref!.read(requestTabProvider.notifier).openTab(newRequest);
    _ref!.read(activeTabIdProvider.notifier).state = newRequest.id;

    return {
      'clicked': true,
      'request_id': newRequest.id,
      'request_name': newRequest.name,
    };
  }

  /// 获取 UI 信息
  Future<Map<String, dynamic>> _getUIInfo() async {
    final tabs = _ref!.read(requestTabProvider);
    final activeTabId = _ref!.read(activeTabIdProvider);
    final activeTab = _ref!.read(activeTabProvider);

    final tabInfo = tabs
        .map((tab) => {
              'id': tab.id,
              'name': tab.request.name,
              'method': tab.request.method.value,
              'is_active': tab.id == activeTabId,
              'is_dirty': tab.isDirty,
            })
        .toList();

    return {
      'tab_count': tabs.length,
      'active_tab_id': activeTabId,
      'tabs': tabInfo,
      'has_active_request': activeTab != null,
      'active_request_url': activeTab?.request.url,
      'active_request_method': activeTab?.request.method.value,
    };
  }

  /// 格式化代码
  Future<Map<String, dynamic>> _beautifyCode() async {
    // 通过 provider 通知 UI 执行 beautify
    _ref!.read(uiTestBeautifyCodeProvider.notifier).state =
        DateTime.now().millisecondsSinceEpoch;

    return {
      'beautified': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 截图
  Future<Map<String, dynamic>> _captureScreenshot(String name) async {
    try {
      // 使用 screencapture 命令截图
      final result = await io.Process.run('screencapture', [
        '-x',
        '${io.Platform.environment['HOME']}/Downloads/hopp_${name}.png',
      ]);

      if (result.exitCode == 0) {
        return {
          'captured': true,
          'name': name,
          'path':
              '${io.Platform.environment['HOME']}/Downloads/hopp_${name}.png',
        };
      } else {
        throw Exception('截图失败: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('截图失败: $e');
    }
  }

  /// 关闭测试服务器
  Future<void> dispose() async {
    await _server?.close();
    _server = null;
  }

  /// 展开 Method 下拉菜单（通过状态通知 UI）
  Future<Map<String, dynamic>> _expandMethodDropdown() async {
    // 设置状态通知 UI 展开下拉菜单
    _ref!.read(uiTestExpandMethodDropdownProvider.notifier).state =
        DateTime.now().millisecondsSinceEpoch;

    return {
      'expanded': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 展开 Raw 子类型下拉菜单（通过状态通知 UI）
  Future<Map<String, dynamic>> _expandRawContentTypeDropdown() async {
    AppLogger.info('[UI_TEST] Expanding Raw content type dropdown');

    // 先切换到 Body Tab
    await _switchRequestTab('body');
    await Future.delayed(const Duration(milliseconds: 100));

    // 设置 Body 类型为 raw
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab != null) {
      final updatedRequest = activeTab.request.copyWith(bodyType: 'raw');
      _ref!.read(requestTabProvider.notifier).updateRequest(
            activeTab.id,
            updatedRequest,
          );
      AppLogger.info('[UI_TEST] Body type set to raw');
    }
    await Future.delayed(const Duration(milliseconds: 200));

    // 设置状态通知 UI 展开下拉菜单
    _ref!.read(uiTestExpandRawContentTypeDropdownProvider.notifier).state =
        DateTime.now().millisecondsSinceEpoch;

    return {
      'expanded': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 切换 Request Editor Tab
  Future<Map<String, dynamic>> _switchRequestTab(String tab) async {
    AppLogger.info('[UI_TEST] _switchRequestTab called: $tab');
    final validTabs = ['params', 'headers', 'body', 'auth'];
    final tabLower = tab.toLowerCase();

    if (!validTabs.contains(tabLower)) {
      AppLogger.error('[UI_TEST] Invalid tab: $tab');
      throw Exception('无效的 Tab: $tab, 可选: $validTabs');
    }

    // 设置目标 Tab
    _ref!.read(uiTestRequestTabProvider.notifier).state = tabLower;
    AppLogger.info(
        '[UI_TEST] uiTestRequestTabProvider.state set to: $tabLower');

    return {'tab': tabLower};
  }

  /// 滚动响应区域
  Future<Map<String, dynamic>> _scrollResponse(
      String direction, int amount) async {
    final validDirections = ['up', 'down', 'left', 'right'];
    final dirLower = direction.toLowerCase();

    if (!validDirections.contains(dirLower)) {
      throw Exception('无效的滚动方向: $direction, 可选: $validDirections');
    }

    // 设置滚动状态通知 UI
    _ref!.read(uiTestScrollResponseProvider.notifier).state = {
      'direction': dirLower,
      'amount': amount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return {
      'direction': dirLower,
      'amount': amount,
    };
  }

  /// 设置窗口大小
  Future<Map<String, dynamic>> _setWindowSize(int? width, int? height) async {
    // 设置窗口大小状态通知 UI
    _ref!.read(uiTestWindowSizeProvider.notifier).state = {
      'width': width ?? 1400,
      'height': height ?? 900,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return {
      'width': width ?? 1400,
      'height': height ?? 900,
    };
  }

  /// 设置分隔线位置（请求/响应区域的比例）
  Future<Map<String, dynamic>> _setDividerPosition(double ratio) async {
    // 确保 ratio 在有效范围内
    final validRatio = ratio.clamp(0.2, 0.8);

    // 设置分隔线位置
    _ref!.read(uiTestDividerPositionProvider.notifier).state = validRatio;

    return {
      'ratio': validRatio,
    };
  }

  /// 聚焦 URL 输入框
  Future<Map<String, dynamic>> _focusUrlInput() async {
    // 设置状态通知 UI 聚焦 URL 输入框
    _ref!.read(uiTestFocusUrlInputProvider.notifier).state =
        DateTime.now().millisecondsSinceEpoch;

    return {
      'focused': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 获取 Request Editor 信息
  Future<Map<String, dynamic>> _getRequestEditorInfo() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final request = activeTab.request;

    // 计算 enabled 且非空的 params 和 headers 数量
    final paramsCount =
        request.params.where((p) => p.enabled && p.key.isNotEmpty).length;
    final headersCount =
        request.headers.where((h) => h.enabled && h.key.isNotEmpty).length;
    final hasBodyContent =
        request.body.isNotEmpty && request.bodyType != 'none';

    return {
      'params_count': paramsCount,
      'headers_count': headersCount,
      'has_body_content': hasBodyContent,
      'body_type': request.bodyType,
      'body_length': request.body.length,
      'params': request.params
          .where((p) => p.enabled && p.key.isNotEmpty)
          .map((p) => {'key': p.key, 'value': p.value})
          .toList(),
      'headers': request.headers
          .where((h) => h.enabled && h.key.isNotEmpty)
          .map((h) => {'key': h.key, 'value': h.value})
          .toList(),
    };
  }

  /// 添加 Param
  Future<Map<String, dynamic>> _addParam(String key, String value) async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final params = [...activeTab.request.params];
    params.add(
      KeyValuePair.empty().copyWith(
        key: key,
        value: value,
        enabled: true,
      ),
    );

    final updatedRequest = activeTab.request.copyWith(params: params);
    _ref!.read(requestTabProvider.notifier).updateRequest(
          activeTab.id,
          updatedRequest,
        );

    return {
      'added': true,
      'param': '$key=$value',
      'total_params': params.length,
    };
  }

  /// 添加 Header（带描述）
  Future<Map<String, dynamic>> _addHeaderWithDescription(
    String key,
    String value,
    String? description,
  ) async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final headers = [...activeTab.request.headers];
    headers.add(
      KeyValuePair.empty().copyWith(
        key: key,
        value: value,
        enabled: true,
      ),
    );

    final updatedRequest = activeTab.request.copyWith(headers: headers);
    _ref!.read(requestTabProvider.notifier).updateRequest(
          activeTab.id,
          updatedRequest,
        );

    return {
      'added': true,
      'header': '$key: $value',
      'description': description,
      'total_headers': headers.length,
    };
  }

  /// 设置 Body 类型
  Future<Map<String, dynamic>> _setBodyType(String bodyType) async {
    print('[UI_TEST] _setBodyType called: $bodyType');
    final validTypes = [
      'none',
      'form-data',
      'x-www-form-urlencoded',
      'raw',
      'binary',
      'graphql',
    ];
    if (!validTypes.contains(bodyType)) {
      throw Exception('无效的 body 类型: $bodyType, 可选: $validTypes');
    }

    final activeTab = _ref!.read(activeTabProvider);
    print(
        '[UI_TEST] activeTab: ${activeTab?.id}, request: ${activeTab?.request.name}');
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final updatedRequest = activeTab.request.copyWith(bodyType: bodyType);
    print('[UI_TEST] Updating request with bodyType: $bodyType');
    _ref!.read(requestTabProvider.notifier).updateRequest(
          activeTab.id,
          updatedRequest,
        );

    // 触发 UI 更新通知
    _ref!.read(uiTestBodyTypeProvider.notifier).state = bodyType;
    print('[UI_TEST] uiTestBodyTypeProvider state set to: $bodyType');

    return {
      'body_type': bodyType,
      'updated': true,
    };
  }

  /// 设置 Raw 内容类型
  Future<Map<String, dynamic>> _setRawContentType(String contentType) async {
    final validTypes = ['text', 'javascript', 'json', 'html', 'xml'];
    if (!validTypes.contains(contentType.toLowerCase())) {
      throw Exception('无效的 content 类型: $contentType, 可选: $validTypes');
    }

    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final updatedRequest = activeTab.request.copyWith(
      rawContentType: contentType.toLowerCase(),
    );
    _ref!.read(requestTabProvider.notifier).updateRequest(
          activeTab.id,
          updatedRequest,
        );

    // 触发 UI 更新通知
    _ref!.read(uiTestRawContentTypeProvider.notifier).state =
        contentType.toLowerCase();

    return {
      'raw_content_type': contentType.toLowerCase(),
      'updated': true,
    };
  }

  /// 获取 Body 信息
  Future<Map<String, dynamic>> _getBodyInfo() async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    final request = activeTab.request;

    return {
      'body_type': request.bodyType,
      'raw_content_type': request.rawContentType,
      'body_length': request.body.length,
      'has_body': request.body.isNotEmpty && request.bodyType != 'none',
    };
  }

  /// 获取所有集合
  Future<Map<String, dynamic>> _getCollections() async {
    final collectionsAsync = _ref!.read(collectionProvider);

    if (collectionsAsync case AsyncData(:final value)) {
      final collections = value
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'request_count': c.requests.length + _countNestedRequests(c),
              })
          .toList();

      return {
        'collection_count': collections.length,
        'collections': collections,
      };
    }

    return {'collection_count': 0, 'collections': []};
  }

  /// 计算嵌套请求数量
  int _countNestedRequests(Collection collection) {
    var count = collection.requests.length;
    for (final child in collection.children) {
      count += _countNestedRequests(child);
    }
    return count;
  }

  /// 导入 Postman Collection
  Future<Map<String, dynamic>> _importCollection(String filePath) async {
    final importService = _ref!.read(postmanImportServiceProvider);
    final result = await importService.importFile(filePath);

    if (result.success) {
      return {
        'imported': true,
        'collection_id': result.collectionId,
        'request_count': result.importedRequestCount,
        'renamed': result.renamed,
        'new_name': result.newName,
        'merged': result.merged,
      };
    } else if (result.conflictCollection != null) {
      return {
        'imported': false,
        'conflict': true,
        'collection_name': result.conflictCollection!.name,
        'existing_id': result.existingId,
      };
    } else {
      throw Exception(result.errorMessage ?? '导入失败');
    }
  }

  /// 触发导入对话框
  Future<Map<String, dynamic>> _triggerImportDialog() async {
    // 设置状态通知 UI 显示导入对话框
    _ref!.read(uiTestImportDialogProvider.notifier).state =
        DateTime.now().millisecondsSinceEpoch;

    return {'triggered': true};
  }

  /// 触发导出对话框
  Future<Map<String, dynamic>> _triggerExportDialog() async {
    // 设置状态通知 UI 显示导出对话框
    _ref!.read(uiTestExportDialogProvider.notifier).state =
        DateTime.now().millisecondsSinceEpoch;

    return {'triggered': true};
  }

  /// 模拟 4XX 错误响应（带服务端返回的错误详情）
  Future<Map<String, dynamic>> _simulate4xxResponse(int statusCode) async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    // 构建错误响应体（模拟服务端返回的 JSON 错误信息）
    final errorBody = jsonEncode({
      'error': 'Bad Request',
      'message': 'The request was invalid or cannot be served.',
      'details': {
        'field': 'email',
        'issue': 'Invalid email format',
      },
      'timestamp': DateTime.now().toIso8601String(),
      'request_id': 'req_${DateTime.now().millisecondsSinceEpoch}',
    });

    // 创建请求信息
    final requestInfo = HttpRequestInfo(
      method: activeTab.request.method.value.toUpperCase(),
      baseUrl: activeTab.request.url,
      fullUrl: activeTab.request.url,
      scheme: 'https',
      host: Uri.parse(activeTab.request.url).host,
      path: Uri.parse(activeTab.request.url).path,
      headers: [
        KeyValuePair.empty().copyWith(
          key: 'Accept',
          value: 'application/json',
          enabled: true,
        ),
        KeyValuePair.empty().copyWith(
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        ),
      ],
      timestamp: DateTime.now(),
    );

    // 创建 4XX 错误响应
    final errorResponse = HttpResponse(
      statusCode: statusCode,
      statusText: _getStatusTextForCode(statusCode),
      body: errorBody,
      headers: [
        KeyValuePair.empty().copyWith(
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        ),
        KeyValuePair.empty().copyWith(
          key: 'Content-Length',
          value: errorBody.length.toString(),
          enabled: true,
        ),
        KeyValuePair.empty().copyWith(
          key: 'X-Request-ID',
          value: 'req_${DateTime.now().millisecondsSinceEpoch}',
          enabled: true,
        ),
      ],
      durationMs: 150,
      sizeBytes: errorBody.length,
      timestamp: DateTime.now(),
      timingInfo: TimingInfo(
        totalMs: 150,
      ),
      requestInfo: requestInfo,
      // 保留错误信息
      error: 'Client error: $statusCode ${_getStatusTextForCode(statusCode)}',
    );

    // 设置响应
    _ref!.read(requestResponseProvider.notifier).setMockResponse(
          activeTab.id,
          errorResponse,
        );

    return {
      'simulated': true,
      'status_code': statusCode,
      'status_text': _getStatusTextForCode(statusCode),
      'body_size': errorBody.length,
      'has_error_info': true,
    };
  }

  /// 模拟 5XX 错误响应（带服务端返回的错误详情）
  Future<Map<String, dynamic>> _simulate5xxResponse(int statusCode) async {
    final activeTab = _ref!.read(activeTabProvider);
    if (activeTab == null) {
      throw Exception('没有活动的请求 Tab');
    }

    // 构建错误响应体（模拟服务端返回的 JSON 错误信息）
    final errorBody = jsonEncode({
      'error': 'Internal Server Error',
      'message':
          'The server encountered an unexpected condition that prevented it from fulfilling the request.',
      'details': {
        'exception': 'NullPointerException',
        'stack_trace': [
          'at com.example.service.handleRequest(Service.java:42)',
          'at com.example.controller.process(Controller.java:28)',
        ],
      },
      'timestamp': DateTime.now().toIso8601String(),
      'request_id': 'req_${DateTime.now().millisecondsSinceEpoch}',
    });

    // 创建请求信息
    final requestInfo = HttpRequestInfo(
      method: activeTab.request.method.value.toUpperCase(),
      baseUrl: activeTab.request.url,
      fullUrl: activeTab.request.url,
      scheme: 'https',
      host: Uri.parse(activeTab.request.url).host,
      path: Uri.parse(activeTab.request.url).path,
      headers: [
        KeyValuePair.empty().copyWith(
          key: 'Accept',
          value: 'application/json',
          enabled: true,
        ),
      ],
      timestamp: DateTime.now(),
    );

    // 创建 5XX 错误响应
    final errorResponse = HttpResponse(
      statusCode: statusCode,
      statusText: _getStatusTextForCode(statusCode),
      body: errorBody,
      headers: [
        KeyValuePair.empty().copyWith(
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        ),
        KeyValuePair.empty().copyWith(
          key: 'Retry-After',
          value: '30',
          enabled: true,
        ),
      ],
      durationMs: 500,
      sizeBytes: errorBody.length,
      timestamp: DateTime.now(),
      timingInfo: TimingInfo(
        totalMs: 500,
      ),
      requestInfo: requestInfo,
      // 保留错误信息
      error: 'Server error: $statusCode ${_getStatusTextForCode(statusCode)}',
    );

    // 设置响应
    _ref!.read(requestResponseProvider.notifier).setMockResponse(
          activeTab.id,
          errorResponse,
        );

    return {
      'simulated': true,
      'status_code': statusCode,
      'status_text': _getStatusTextForCode(statusCode),
      'body_size': errorBody.length,
      'has_error_info': true,
    };
  }

  /// 获取状态码对应的文本
  String _getStatusTextForCode(int? statusCode) {
    final texts = {
      400: 'Bad Request',
      401: 'Unauthorized',
      403: 'Forbidden',
      404: 'Not Found',
      405: 'Method Not Allowed',
      422: 'Unprocessable Entity',
      429: 'Too Many Requests',
      500: 'Internal Server Error',
      502: 'Bad Gateway',
      503: 'Service Unavailable',
      504: 'Gateway Timeout',
    };
    return texts[statusCode] ?? 'Unknown';
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

/// UI 测试 - 展开 Method 下拉菜单触发器（使用时间戳确保每次都能触发）
final uiTestExpandMethodDropdownProvider = StateProvider<int?>((ref) => null);

/// UI 测试 - 展开 Raw 子类型下拉菜单触发器（使用时间戳确保每次都能触发）
final uiTestExpandRawContentTypeDropdownProvider =
    StateProvider<int?>((ref) => null);

/// UI 测试 - Request Editor Tab 切换
final uiTestRequestTabProvider = StateProvider<String?>((ref) => null);

/// UI 测试 - 响应区域滚动控制
/// 格式: {'direction': 'up'/'down', 'amount': 100, 'timestamp': 123456}
final uiTestScrollResponseProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// UI 测试 - 窗口大小控制
/// 格式: {'width': 1400, 'height': 900, 'timestamp': 123456}
final uiTestWindowSizeProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// UI 测试 - 分隔线位置控制（0.0 - 1.0，表示请求/响应区域的比例）
final uiTestDividerPositionProvider = StateProvider<double>((ref) => 0.5);

/// UI 测试 - 聚焦 URL 输入框触发器（使用时间戳确保每次都能触发）
final uiTestFocusUrlInputProvider = StateProvider<int?>((ref) => null);

/// UI 测试 - Body 类型选择
final uiTestBodyTypeProvider = StateProvider<String?>((ref) => null);

/// UI 测试 - Raw 内容类型选择
final uiTestRawContentTypeProvider = StateProvider<String?>((ref) => null);

/// UI 测试 - Beautify 代码触发器
final uiTestBeautifyCodeProvider = StateProvider<int?>((ref) => null);

/// UI 测试 - 导入对话框触发器
final uiTestImportDialogProvider = StateProvider<int?>((ref) => null);

/// UI 测试 - 导出对话框触发器
final uiTestExportDialogProvider = StateProvider<int?>((ref) => null);
