import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../models/http_request.dart';
import '../models/http_response.dart';
import '../models/key_value_pair.dart';

class HttpService {
  final Dio _dio;
  final Logger _logger;

  HttpService({Dio? dio, Logger? logger})
      : _dio = dio ?? Dio(),
        _logger = logger ?? Logger();

  void configure({
    required int timeoutMs,
    required bool followRedirects,
    required int maxRedirects,
    required bool validateCertificates,
  }) {
    _dio.options = BaseOptions(
      connectTimeout: Duration(milliseconds: timeoutMs),
      receiveTimeout: Duration(milliseconds: timeoutMs),
      sendTimeout: Duration(milliseconds: timeoutMs),
      followRedirects: followRedirects,
      maxRedirects: maxRedirects,
      validateStatus: (status) => status != null && status < 600,
    );

    if (!validateCertificates) {
      (_dio.httpClientAdapter as dynamic).onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  Future<HttpResponse> sendRequest(HttpRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      _logger.i('Sending ${request.method.value} request to ${request.url}');

      final uri = _buildUri(request.url, request.params);
      final headers = _buildHeaders(request.headers);
      final body = _prepareBody(request.body, request.bodyType);

      final options = Options(
        method: request.method.value,
        headers: headers,
        responseType: ResponseType.bytes,
      );

      final response = await _dio.request<Uint8List>(
        uri.toString(),
        data: body,
        options: options,
      );

      stopwatch.stop();

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

      _logger.i(
          'Request completed: ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms');

      return HttpResponse(
        body: responseBody,
        headers: responseHeaders,
        statusCode: response.statusCode,
        statusText: _getStatusText(response.statusCode),
        durationMs: stopwatch.elapsedMilliseconds,
        sizeBytes: bytes?.length,
        timestamp: DateTime.now(),
      );
    } on DioException catch (e) {
      stopwatch.stop();
      _logger.e('Request failed: ${e.message}', error: e);

      return HttpResponse(
        error: _formatDioError(e),
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      _logger.e('Unexpected error: $e', error: e);

      return HttpResponse(
        error: 'Unexpected error: $e',
        durationMs: stopwatch.elapsedMilliseconds,
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

  String _formatDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timeout: ${error.message}';
      case DioExceptionType.badCertificate:
        return 'Certificate error: ${error.message}';
      case DioExceptionType.badResponse:
        return 'Server error: ${error.response?.statusCode} ${error.response?.statusMessage}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error: ${error.message}';
      case DioExceptionType.unknown:
        return 'Network error: ${error.message}';
    }
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
