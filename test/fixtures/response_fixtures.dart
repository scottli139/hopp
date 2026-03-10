import 'dart:convert';
import 'dart:typed_data';

import 'package:hopp/models/http_response.dart';
import 'package:hopp/models/key_value_pair.dart';

/// HttpResponse fixtures for testing
class ResponseFixtures {
  ResponseFixtures._();

  /// Successful 200 OK response with JSON body
  static HttpResponse successJson() => HttpResponse(
        body: '{\n  "id": 1,\n  "name": "Test User"\n}',
        headers: [
          KeyValuePair(
            id: 'content-type',
            key: 'content-type',
            value: 'application/json',
            enabled: true,
          ),
          KeyValuePair(
            id: 'content-length',
            key: 'content-length',
            value: '32',
            enabled: true,
          ),
        ],
        statusCode: 200,
        statusText: 'OK',
        durationMs: 150,
        sizeBytes: 32,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// Successful 201 Created response
  static HttpResponse created() => HttpResponse(
        body: '{\n  "id": 1,\n  "created": true\n}',
        headers: [
          KeyValuePair(
            id: 'content-type',
            key: 'content-type',
            value: 'application/json',
            enabled: true,
          ),
        ],
        statusCode: 201,
        statusText: 'Created',
        durationMs: 200,
        sizeBytes: 28,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// 204 No Content response
  static HttpResponse noContent() => HttpResponse(
        body: null,
        headers: [],
        statusCode: 204,
        statusText: 'No Content',
        durationMs: 100,
        sizeBytes: 0,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// 400 Bad Request error response
  static HttpResponse badRequest() => HttpResponse(
        body: '{\n  "error": "Bad Request"\n}',
        headers: [
          KeyValuePair(
            id: 'content-type',
            key: 'content-type',
            value: 'application/json',
            enabled: true,
          ),
        ],
        statusCode: 400,
        statusText: 'Bad Request',
        durationMs: 100,
        sizeBytes: 25,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// 401 Unauthorized error response
  static HttpResponse unauthorized() => HttpResponse(
        body: '{\n  "error": "Unauthorized"\n}',
        headers: [],
        statusCode: 401,
        statusText: 'Unauthorized',
        durationMs: 50,
        sizeBytes: 27,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// 404 Not Found error response
  static HttpResponse notFound() => HttpResponse(
        body: '{\n  "error": "Not Found"\n}',
        headers: [],
        statusCode: 404,
        statusText: 'Not Found',
        durationMs: 80,
        sizeBytes: 24,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// 500 Internal Server Error response
  static HttpResponse serverError() => HttpResponse(
        body: '{\n  "error": "Internal Server Error"\n}',
        headers: [],
        statusCode: 500,
        statusText: 'Internal Server Error',
        durationMs: 300,
        sizeBytes: 38,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// Network error response
  static HttpResponse networkError() => HttpResponse(
        error: 'Connection error: Failed to connect',
        durationMs: 5000,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// Timeout error response
  static HttpResponse timeoutError() => HttpResponse(
        error: 'Request timeout: Connection timed out',
        durationMs: 30000,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// Empty successful response
  static HttpResponse emptySuccess() => HttpResponse(
        body: '',
        headers: [],
        statusCode: 200,
        statusText: 'OK',
        durationMs: 50,
        sizeBytes: 0,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// Response with text body
  static HttpResponse textResponse() => HttpResponse(
        body: 'Hello, World!',
        headers: [
          KeyValuePair(
            id: 'content-type',
            key: 'content-type',
            value: 'text/plain',
            enabled: true,
          ),
        ],
        statusCode: 200,
        statusText: 'OK',
        durationMs: 100,
        sizeBytes: 13,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// Response with multiple headers having same name
  static HttpResponse multipleHeaders() => HttpResponse(
        body: '{}',
        headers: [
          KeyValuePair(
            id: 'set-cookie',
            key: 'set-cookie',
            value: 'session=abc123',
            enabled: true,
          ),
          KeyValuePair(
            id: 'set-cookie-2',
            key: 'set-cookie',
            value: 'user=john',
            enabled: true,
          ),
        ],
        statusCode: 200,
        statusText: 'OK',
        durationMs: 100,
        sizeBytes: 2,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

  /// Creates a mock Response object from Dio
  static dynamic mockDioResponse({
    dynamic data,
    int statusCode = 200,
    Map<String, List<String>> headers = const {},
    String statusMessage = 'OK',
    bool redirects = false,
  }) {
    return {
      'data': data,
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'headers': headers,
      'redirects': redirects,
      'extra': {},
    };
  }

  /// Sample JSON response bytes
  static Uint8List jsonResponseBytes() =>
      Uint8List.fromList(utf8.encode('{"id":1,"name":"Test"}'));

  /// Sample text response bytes
  static Uint8List textResponseBytes() =>
      Uint8List.fromList(utf8.encode('Hello, World!'));

  /// Sample error response bytes
  static Uint8List errorResponseBytes() =>
      Uint8List.fromList(utf8.encode('{"error":"Something went wrong"}'));

  /// Empty response bytes
  static Uint8List emptyResponseBytes() => Uint8List(0);
}
