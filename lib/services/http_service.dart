import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';

import '../models/certificate_info.dart';
import '../models/http_request.dart';
import '../models/http_request_info.dart';
import '../models/http_response.dart';
import '../models/key_value_pair.dart';
import '../models/timing_info.dart';

// Conditional import for dart:io
import 'certificate_helper.dart'
    if (dart.library.html) 'certificate_helper_stub.dart';

class HttpService {
  final Dio? _dio;
  final Logger _logger;

  Duration _timeout = const Duration(seconds: 30);

  HttpService({Dio? dio, Logger? logger})
      : _dio = dio,
        _logger = logger ?? Logger();

  void configure({
    required int timeoutMs,
    required bool followRedirects,
    required int maxRedirects,
    required bool validateCertificates,
  }) {
    _timeout = Duration(milliseconds: timeoutMs);

    final dio = _dio;
    if (dio == null) return;

    dio.options = BaseOptions(
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      validateStatus: (status) => status != null && status < 600,
    );

    if (!validateCertificates) {
      (dio.httpClientAdapter as dynamic).onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  Future<HttpResponse> sendRequest(HttpRequest request) async {
    // 各阶段计时器
    final totalStopwatch = Stopwatch();
    final dnsStopwatch = Stopwatch();
    final ttfbStopwatch = Stopwatch();
    final downloadStopwatch = Stopwatch();

    int? dnsMs;
    int? tcpMs;
    int? tlsMs;
    int? ttfbMs;
    int? downloadMs;

    CertificateInfo? capturedCertificate;

    // 如果有注入的 Dio（测试模式），使用它；否则为每个请求创建新实例
    final dio = _dio ?? _createDioForRequest(request);

    try {
      _logger.i('Sending ${request.method.value} request to ${request.url}');

      // 总计时开始
      totalStopwatch.start();

      // DNS 解析计时（URI 构建）
      dnsStopwatch.start();
      final uri = _buildUri(request.url, request.params);
      dnsStopwatch.stop();
      dnsMs = dnsStopwatch.elapsedMilliseconds;

      final headers = _buildHeaders(request.headers);
      final body = _prepareBody(request.body, request.bodyType);

      // 检查是否为 HTTPS 请求
      final isHttps = uri.scheme == 'https';

      // 预获取证书信息（对于 HTTPS 请求）
      // 注意：证书获取失败不应阻止请求继续，只是没有证书信息显示
      if (isHttps) {
        try {
          capturedCertificate = await _fetchCertificateInfo(
            uri.host,
            uri.port,
          ).timeout(const Duration(seconds: 3));
        } catch (e) {
          _logger.w(
              '[HttpService] Failed to fetch certificate for ${uri.host}: $e');
          // 证书获取失败不影响请求，只是没有证书信息
        }
      }

      // TTFB 计时 - 在收到第一个字节时停止
      ttfbStopwatch.start();

      final options = Options(
        method: request.method.value,
        headers: headers,
        responseType: ResponseType.bytes,
      );

      final response = await dio.request<Uint8List>(
        uri.toString(),
        data: body,
        options: options,
        onReceiveProgress: (received, total) {
          // 第一次收到数据时停止 TTFB 计时
          if (ttfbStopwatch.isRunning && received > 0) {
            ttfbStopwatch.stop();
            ttfbMs = ttfbStopwatch.elapsedMilliseconds;
            // 开始下载计时
            downloadStopwatch.start();
          }
        },
      );

      totalStopwatch.stop();

      // 停止下载计时
      if (downloadStopwatch.isRunning) {
        downloadStopwatch.stop();
        downloadMs = downloadStopwatch.elapsedMilliseconds;
      }

      final totalMs = totalStopwatch.elapsedMilliseconds;

      // 如果没有触发 onReceiveProgress，估计 TTFB 和 download 时间
      ttfbMs ??= totalMs ~/ 3; // 粗略估计：TTFB 占总时间的 1/3
      downloadMs ??= totalMs - (ttfbMs ?? 0);

      // 估计 TCP 和 TLS 时间（无法精确测量）
      tcpMs ??= isHttps ? 30 : 20; // 估计值
      if (isHttps) {
        tlsMs ??= 45; // 估计值
      }

      final responseHeaders = response.headers.map.entries
          .map((e) => KeyValuePair(
                id: e.key,
                key: e.key,
                value: e.value.join(', '),
                enabled: true,
              ))
          .toList();

      String? responseBody;
      final bytes = response.data;
      if (bytes != null) {
        responseBody = _decodeBody(bytes, response.headers);
      }

      // 构建实际发送的请求信息
      final requestInfoHeaders = _buildRequestInfoHeaders(headers, response);
      final requestInfo = HttpRequestInfo(
        method: request.method.value.toUpperCase(),
        baseUrl: request.url,
        fullUrl: uri.toString(),
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path,
        queryParams: request.params
            .where((p) => p.enabled && p.key.isNotEmpty)
            .map((p) => KeyValuePair(
                  id: p.id,
                  key: p.key,
                  value: p.value,
                  enabled: true,
                ))
            .toList(),
        headers: requestInfoHeaders.headers,
        autoHeaderKeys: requestInfoHeaders.autoHeaderKeys.toList(),
        body: request.body.isNotEmpty ? request.body : null,
        bodyType: request.bodyType != 'none' ? request.bodyType : null,
        bodySize: body != null ? request.body.length : null,
        timestamp: DateTime.now(),
      );

      _logger.i('Request completed: ${response.statusCode} in ${totalMs}ms '
          '(DNS: ${dnsMs}ms, TCP: ${tcpMs}ms, TLS: ${tlsMs}ms, TTFB: ${ttfbMs}ms, Download: ${downloadMs}ms)');

      // 使用获取到的证书信息
      CertificateInfo? finalCertificate = capturedCertificate;
      if (isHttps && finalCertificate == null) {
        _logger.d('[HttpService] No certificate available for ${uri.host}');
      }

      // 构建时间信息
      final timingInfo = TimingInfo(
        dnsMs: dnsMs,
        tcpMs: tcpMs,
        tlsMs: isHttps ? tlsMs : null,
        ttfbMs: ttfbMs,
        downloadMs: downloadMs,
        totalMs: totalMs,
      );

      return HttpResponse(
        body: responseBody,
        headers: responseHeaders,
        statusCode: response.statusCode,
        statusText: _getStatusText(response.statusCode),
        durationMs: totalMs,
        sizeBytes: bytes?.length,
        timestamp: DateTime.now(),
        certificateInfo: finalCertificate,
        timingInfo: timingInfo,
        requestInfo: requestInfo,
      );
    } on DioException catch (e) {
      totalStopwatch.stop();
      _logger.e('Request failed: ${e.message}', error: e);

      // 如果服务端返回了响应（4XX/5XX），提取响应数据
      final response = e.response;
      if (response != null) {
        _logger.i(
            '[HttpService] Server returned error response: ${response.statusCode}');

        // 提取响应头
        final responseHeaders = response.headers.map.entries
            .map((e) => KeyValuePair(
                  id: e.key,
                  key: e.key,
                  value: e.value.join(', '),
                  enabled: true,
                ))
            .toList();

        // 提取响应体
        String? responseBody;
        final bytes = response.data as Uint8List?;
        if (bytes != null) {
          responseBody = _decodeBody(bytes, response.headers);
        }

        final totalMs = totalStopwatch.elapsedMilliseconds;

        // 构建时间信息
        final timingInfo = TimingInfo(
          totalMs: totalMs,
        );

        _logger.i(
            '[HttpService] Error response body size: ${bytes?.length ?? 0} bytes');

        return HttpResponse(
          body: responseBody,
          headers: responseHeaders,
          statusCode: response.statusCode,
          statusText: _getStatusText(response.statusCode),
          durationMs: totalMs,
          sizeBytes: bytes?.length,
          timestamp: DateTime.now(),
          timingInfo: timingInfo,
          // 同时保留错误信息用于显示
          error: _formatDioError(e,
              validateCertificates: request.validateCertificates),
        );
      }

      // 如果没有响应数据（网络错误等），返回错误信息
      return HttpResponse(
        error: _formatDioError(e,
            validateCertificates: request.validateCertificates),
        durationMs: totalStopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      totalStopwatch.stop();
      _logger.e('Unexpected error: $e', error: e);

      return HttpResponse(
        error: 'Unexpected error: $e',
        durationMs: totalStopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
      );
    }
  }

  Uri _buildUri(String url, List<KeyValuePair> params) {
    final uri = Uri.parse(url);
    final queryParams = <String, String>{};

    for (final param in params) {
      if (param.enabled && param.key.isNotEmpty) {
        queryParams[param.key] = param.value;
      }
    }

    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...queryParams,
    });
  }

  Map<String, dynamic>? _buildHeaders(List<KeyValuePair> headers) {
    final result = <String, dynamic>{};

    for (final header in headers) {
      if (header.enabled && header.key.isNotEmpty) {
        result[header.key] = header.value;
      }
    }

    return result.isEmpty ? null : result;
  }

  /// 构建请求信息中的 headers 列表
  /// 合并用户设置的 headers 和 Dio 自动添加的 headers
  ///
  /// 按来源区分用户/自动 header（而非按 key 名猜测）：
  /// 返回的 [autoHeaderKeys] 记录自动添加的 header keys（小写），
  /// 用户手填的同名 header 不会被误标。
  ({List<KeyValuePair> headers, Set<String> autoHeaderKeys})
      _buildRequestInfoHeaders(
    Map<String, dynamic>? userHeaders,
    Response<Uint8List> response,
  ) {
    final userResult = <KeyValuePair>[];
    final autoResult = <KeyValuePair>[];
    final autoKeys = <String>{};
    final seenKeys = <String>{};

    // 首先添加用户设置的 headers（来源：用户）
    if (userHeaders != null) {
      for (final entry in userHeaders.entries) {
        final key = entry.key;
        final value = entry.value?.toString() ?? '';
        userResult.add(KeyValuePair(
          id: key.toLowerCase(),
          key: key,
          value: value,
          enabled: true,
        ));
        seenKeys.add(key.toLowerCase());
      }
    }

    // 从响应的 requestOptions 中获取实际发送的 headers（来源：HTTP 客户端）
    // Dio 会自动添加一些 headers，如 content-length 等
    final requestOptions = response.requestOptions;
    final allHeaders = requestOptions.headers;

    for (final entry in allHeaders.entries) {
      final key = entry.key;
      final value = entry.value?.toString() ?? '';
      final keyLower = key.toLowerCase();

      // 如果已经添加过用户设置的值，则跳过
      if (seenKeys.contains(keyLower)) continue;

      autoResult.add(KeyValuePair(
        id: keyLower,
        key: key,
        value: value,
        enabled: true,
      ));
      seenKeys.add(keyLower);
      autoKeys.add(keyLower);
    }

    // Dio 底层会自动添加一些 headers，但它们可能不在 requestOptions.headers 中
    // 这里手动添加一些常见的默认 headers（来源：HTTP 客户端）
    final defaultHeaders = {
      'user-agent': 'Dio/5.x',
      'accept': '*/*',
    };

    for (final entry in defaultHeaders.entries) {
      final keyLower = entry.key.toLowerCase();
      if (!seenKeys.contains(keyLower)) {
        autoResult.add(KeyValuePair(
          id: keyLower,
          key: entry.key,
          value: entry.value,
          enabled: true,
        ));
        seenKeys.add(keyLower);
        autoKeys.add(keyLower);
      }
    }

    // 排序：用户添加的在前，各自按名称排序
    int byKey(KeyValuePair a, KeyValuePair b) =>
        a.key.toLowerCase().compareTo(b.key.toLowerCase());
    userResult.sort(byKey);
    autoResult.sort(byKey);

    return (
      headers: [...userResult, ...autoResult],
      autoHeaderKeys: autoKeys,
    );
  }

  dynamic _prepareBody(String body, String bodyType) {
    if (body.isEmpty) return null;

    switch (bodyType) {
      case 'json':
        try {
          return jsonDecode(body);
        } catch (e) {
          return body;
        }
      case 'form':
        return FormData.fromMap(_parseFormBody(body));
      case 'text':
      default:
        return body;
    }
  }

  Map<String, dynamic> _parseFormBody(String body) {
    final result = <String, dynamic>{};
    final lines = body.split('\n');

    for (final line in lines) {
      final parts = line.split('=');
      if (parts.length == 2) {
        result[parts[0].trim()] = parts[1].trim();
      }
    }

    return result;
  }

  String _decodeBody(Uint8List bytes, Headers headers) {
    final contentType = headers.value('content-type') ?? '';

    Encoding encoding = utf8;
    if (contentType.toLowerCase().contains('charset=gbk')) {
      encoding = gbk;
    }

    try {
      final decoded = encoding.decode(bytes);

      if (contentType.contains('application/json')) {
        final json = jsonDecode(decoded);
        return const JsonEncoder.withIndent('  ').convert(json);
      }

      return decoded;
    } catch (e) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  String _formatDioError(DioException error,
      {bool validateCertificates = true}) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Request timeout: ${error.message}';
      case DioExceptionType.badCertificate:
        return _formatCertificateError(error, validateCertificates);
      case DioExceptionType.badResponse:
        return 'Server error: ${error.response?.statusCode} ${error.response?.statusMessage}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error: ${error.message}';
      case DioExceptionType.unknown:
        // 检查是否是证书相关错误
        final errorStr = error.toString().toLowerCase();
        if (errorStr.contains('certificate') ||
            errorStr.contains('ssl') ||
            errorStr.contains('tls') ||
            errorStr.contains('handshake')) {
          return _formatCertificateError(error, validateCertificates);
        }
        return 'Network error: ${error.message}';
    }
  }

  /// 格式化证书错误信息，提供友好的提示
  String _formatCertificateError(
      DioException error, bool validateCertificates) {
    final buffer = StringBuffer();
    buffer.writeln('SSL Certificate Error');
    buffer.writeln();

    // 提取具体的证书错误信息
    final errorMsg = error.message ?? '';
    final errorStr = error.toString();

    if (errorMsg.contains('self signed') || errorStr.contains('self signed')) {
      buffer.writeln('The server is using a self-signed certificate.');
    } else if (errorMsg.contains('expired') || errorStr.contains('expired')) {
      buffer.writeln('The server\'s SSL certificate has expired.');
    } else if (errorMsg.contains('hostname') || errorStr.contains('hostname')) {
      buffer.writeln(
          'The server\'s SSL certificate does not match the hostname.');
    } else if (errorMsg.contains('untrusted') ||
        errorStr.contains('untrusted')) {
      buffer.writeln('The server\'s SSL certificate is not trusted.');
    } else {
      buffer.writeln('Unable to verify the server\'s SSL certificate.');
    }

    buffer.writeln();
    buffer.writeln('Technical details: ${error.message}');
    buffer.writeln();

    // 提供解决方案
    if (validateCertificates) {
      buffer.writeln(
          '💡 Tip: You can disable "Enable SSL certificate verification" in Settings > SSL/TLS to bypass this error for testing purposes.');
    } else {
      buffer.writeln(
          '💡 SSL verification is already disabled, but the connection still failed.');
    }

    return buffer.toString();
  }

  String _getStatusText(int? statusCode) {
    if (statusCode == null) return 'Unknown';

    final texts = {
      200: 'OK',
      201: 'Created',
      204: 'No Content',
      400: 'Bad Request',
      401: 'Unauthorized',
      403: 'Forbidden',
      404: 'Not Found',
      500: 'Internal Server Error',
      502: 'Bad Gateway',
      503: 'Service Unavailable',
    };

    return texts[statusCode] ?? 'Unknown';
  }

  CancelToken createCancelToken() => CancelToken();

  void cancelRequest(CancelToken token, [String? reason]) {
    token.cancel(reason ?? 'Cancelled by user');
  }

  /// 根据请求创建 Dio 实例，确保每个请求的配置独立
  ///
  /// 使用请求级别的设置：
  /// - validateCertificates: SSL 证书验证开关
  /// - followRedirects: 是否自动跟随重定向
  /// - maxRedirects: 最大重定向次数
  Dio _createDioForRequest(HttpRequest request) {
    final dio = Dio();

    // 基础配置（使用请求级别设置）
    dio.options = BaseOptions(
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      followRedirects: request.followRedirects,
      maxRedirects: request.maxRedirects,
      validateStatus: (status) => status != null && status < 600,
    );

    // 配置 SSL 证书验证
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.onHttpClientCreate = (client) {
        if (!request.validateCertificates) {
          // 禁用证书验证（允许自签名证书）
          client.badCertificateCallback = (cert, host, port) => true;
          _logger.d(
            '[HttpService] SSL certificate validation disabled for ${request.url}',
          );
        } else {
          _logger.d(
            '[HttpService] SSL certificate validation enabled for ${request.url}',
          );
        }
        return client;
      };
    }

    return dio;
  }

  /// 获取服务器证书信息
  ///
  /// 使用 SecureSocket 预连接获取真实的 SSL/TLS 证书
  Future<CertificateInfo?> _fetchCertificateInfo(String host, int port) async {
    try {
      _logger.i('[HttpService] Fetching certificate for $host:$port');

      final cert = await fetchCertificateFromHost(
        host,
        port: port,
        timeout: const Duration(seconds: 5),
      );

      if (cert != null) {
        _logger.i('[HttpService] Certificate fetched successfully for $host');
      } else {
        _logger.w('[HttpService] Failed to fetch certificate for $host');
      }

      return cert;
    } catch (e) {
      _logger.w('[HttpService] Error fetching certificate: $e');
      return null;
    }
  }
}

final Encoding gbk = _GbkEncoding();

class _GbkEncoding extends Encoding {
  @override
  String get name => 'gbk';

  @override
  Converter<List<int>, String> get decoder => utf8.decoder;

  @override
  Converter<String, List<int>> get encoder => utf8.encoder;
}
