import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/services/http_service.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../fixtures/fixtures.dart';
import 'http_service_test.mocks.dart';

/// Generate mocks for Dio
/// Run: dart run build_runner build --delete-conflicting-outputs
@GenerateMocks([Dio])
void main() {
  group('HttpService', () {
    late HttpService httpService;
    late MockDio mockDio;
    late Logger logger;

    setUp(() {
      mockDio = MockDio();
      logger = Logger(level: Level.off); // Disable logging in tests
      httpService = HttpService(dio: mockDio, logger: logger);
    });

    tearDown(() {
      // Cleanup is handled automatically
    });

    group('configure', () {
      test('should configure Dio with default options', () {
        // Act
        httpService.configure(
          timeoutMs: 30000,
          followRedirects: true,
          maxRedirects: 5,
          validateCertificates: true,
        );

        // Assert - Dio options should be updated
        verify(mockDio.options = any).called(1);
      });

      test('should configure with custom timeout', () {
        // Act
        httpService.configure(
          timeoutMs: 5000,
          followRedirects: true,
          maxRedirects: 5,
          validateCertificates: true,
        );

        // Assert
        final captured = verify(mockDio.options = captureAny).captured;
        final options = captured.first as BaseOptions;
        expect(
            options.connectTimeout, equals(const Duration(milliseconds: 5000)));
        expect(
            options.receiveTimeout, equals(const Duration(milliseconds: 5000)));
        expect(options.sendTimeout, equals(const Duration(milliseconds: 5000)));
      });

      test('should configure redirect settings', () {
        // Act
        httpService.configure(
          timeoutMs: 30000,
          followRedirects: false,
          maxRedirects: 10,
          validateCertificates: true,
        );

        // Assert
        final captured = verify(mockDio.options = captureAny).captured;
        final options = captured.first as BaseOptions;
        expect(options.followRedirects, isFalse);
        expect(options.maxRedirects, equals(10));
      });
    });

    group('sendRequest - success cases', () {
      test('should return successful response for GET request', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();
        final responseData = utf8.encode('{"id": 1, "name": "Test"}');

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List.fromList(responseData),
              statusCode: 200,
              statusMessage: 'OK',
              requestOptions: RequestOptions(path: request.url),
              headers: Headers.fromMap({
                'content-type': ['application/json'],
                'content-length': [responseData.length.toString()],
              }),
            ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.statusText, equals('OK'));
        expect(response.body, isNotNull);
        expect(response.error, isNull);
        expect(response.durationMs, greaterThanOrEqualTo(0));
        expect(response.sizeBytes, equals(responseData.length));
        expect(response.headers, isNotEmpty);
        expect(response.timestamp, isNotNull);
      });

      test('should handle 201 Created response', () async {
        // Arrange
        final request = RequestFixtures.postWithJson();
        final responseData = utf8.encode('{"id": 1, "created": true}');

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List.fromList(responseData),
              statusCode: 201,
              statusMessage: 'Created',
              requestOptions: RequestOptions(path: request.url),
              headers: Headers.fromMap({
                'content-type': ['application/json'],
              }),
            ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.statusCode, equals(201));
        expect(response.statusText, equals('Created'));
      });

      test('should handle 204 No Content response', () async {
        // Arrange
        final request = RequestFixtures.deleteRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: null,
              statusCode: 204,
              statusMessage: 'No Content',
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.statusCode, equals(204));
        expect(response.statusText, equals('No Content'));
        expect(response.body, isNull);
        expect(response.sizeBytes, isNull);
      });

      test('should handle response with text content type', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();
        final responseText = 'Hello, World!';

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List.fromList(utf8.encode(responseText)),
              statusCode: 200,
              statusMessage: 'OK',
              requestOptions: RequestOptions(path: request.url),
              headers: Headers.fromMap({
                'content-type': ['text/plain'],
              }),
            ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.statusCode, equals(200));
        expect(response.body, equals(responseText));
      });
    });

    group('sendRequest - error handling', () {
      test('should handle connection timeout error', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
          requestOptions: RequestOptions(path: request.url),
        ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.statusCode, isNull);
        expect(response.error, contains('timeout'));
        expect(response.durationMs, greaterThanOrEqualTo(0));
      });

      test('should handle receive timeout error', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          type: DioExceptionType.receiveTimeout,
          message: 'Receive timeout',
          requestOptions: RequestOptions(path: request.url),
        ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.error, contains('timeout'));
      });

      test('should handle bad response error (4xx)', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          message: 'Bad Request',
          response: Response(
            statusCode: 400,
            statusMessage: 'Bad Request',
            requestOptions: RequestOptions(path: request.url),
          ),
          requestOptions: RequestOptions(path: request.url),
        ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.error, contains('Server error'));
        expect(response.error, contains('400'));
      });

      test('should handle bad response error (5xx)', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          message: 'Internal Server Error',
          response: Response(
            statusCode: 500,
            statusMessage: 'Internal Server Error',
            requestOptions: RequestOptions(path: request.url),
          ),
          requestOptions: RequestOptions(path: request.url),
        ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.error, contains('Server error'));
        expect(response.error, contains('500'));
      });

      test('should handle connection error', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          message: 'Failed to connect',
          requestOptions: RequestOptions(path: request.url),
        ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.error, contains('Connection error'));
      });

      test('should handle cancelled request', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          type: DioExceptionType.cancel,
          message: 'Request cancelled',
          requestOptions: RequestOptions(path: request.url),
        ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.error, contains('cancelled'));
      });

      test('should handle bad certificate error', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(DioException(
          type: DioExceptionType.badCertificate,
          message: 'Certificate verification failed',
          requestOptions: RequestOptions(path: request.url),
        ));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.error, contains('SSL Certificate Error'));
      });

      test('should handle unexpected errors', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenThrow(Exception('Unexpected error'));

        // Act
        final response = await httpService.sendRequest(request);

        // Assert
        expect(response.error, contains('Unexpected error'));
      });
    });

    group('sendRequest - query parameters', () {
      test('should include enabled query parameters in URL', () async {
        // Arrange
        final request = RequestFixtures.requestWithDisabledParams();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 200,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          captureAny,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final url = captured.first as String;
        expect(url, contains('enabled=yes'));
        expect(url, isNot(contains('disabled=no')));
      });

      test('should merge query parameters with existing URL params', () async {
        // Arrange
        final request = HttpRequest(
          id: 'req-merge',
          name: 'Merge Test',
          method: HttpMethod.get,
          url: 'https://api.example.com/search?existing=value',
          params: [
            KeyValuePair(
              id: 'param-1',
              key: 'new',
              value: 'param',
              enabled: true,
            ),
          ],
          headers: [],
          body: '',
          bodyType: 'none',
        );

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 200,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          captureAny,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final url = captured.first as String;
        expect(url, contains('existing=value'));
        expect(url, contains('new=param'));
      });
    });

    group('sendRequest - headers', () {
      test('should include enabled headers only', () async {
        // Arrange
        final request = RequestFixtures.requestWithDisabledHeaders();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 200,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: captureAnyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final options = captured.first as Options;
        expect(options.headers?['Authorization'], equals('Bearer token123'));
        expect(options.headers?.containsKey('X-Disabled'), isFalse);
      });

      test('should send null headers when no enabled headers', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 200,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: captureAnyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final options = captured.first as Options;
        expect(options.headers, isNull);
      });
    });

    group('sendRequest - body handling', () {
      test('should send JSON body as parsed object', () async {
        // Arrange
        final request = RequestFixtures.postWithJson();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 201,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          any,
          data: captureAnyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final body = captured.first;
        expect(body, isA<Map<String, dynamic>>());
        expect(body['name'], equals('John'));
        expect(body['email'], equals('john@example.com'));
      });

      test('should send text body as string', () async {
        // Arrange
        final request = RequestFixtures.postWithText();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 200,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          any,
          data: captureAnyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final body = captured.first;
        expect(body, equals('Plain text body'));
      });

      test('should send null body when body is empty', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 200,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          any,
          data: captureAnyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final body = captured.first;
        expect(body, isNull);
      });
    });

    group('cancel token', () {
      test('createCancelToken should return a CancelToken', () {
        // Act
        final token = httpService.createCancelToken();

        // Assert
        expect(token, isA<CancelToken>());
      });

      test('cancelRequest should cancel the token', () {
        // Arrange
        final token = CancelToken();

        // Act
        httpService.cancelRequest(token, 'Test cancel reason');

        // Assert
        expect(token.isCancelled, isTrue);
      });
    });

    group('HTTP methods', () {
      test('should use correct method for GET request', () async {
        // Arrange
        final request = RequestFixtures.simpleGetRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 200,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: captureAnyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final options = captured.first as Options;
        expect(options.method, equals('GET'));
      });

      test('should use correct method for POST request', () async {
        // Arrange
        final request = RequestFixtures.postWithJson();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 201,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: captureAnyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final options = captured.first as Options;
        expect(options.method, equals('POST'));
      });

      test('should use correct method for PUT request', () async {
        // Arrange
        final request = RequestFixtures.putRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 200,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: captureAnyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final options = captured.first as Options;
        expect(options.method, equals('PUT'));
      });

      test('should use correct method for DELETE request', () async {
        // Arrange
        final request = RequestFixtures.deleteRequest();

        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List(0),
              statusCode: 204,
              requestOptions: RequestOptions(path: request.url),
              headers: Headers(),
            ));

        // Act
        await httpService.sendRequest(request);

        // Assert
        final captured = verify(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: captureAnyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).captured;
        final options = captured.first as Options;
        expect(options.method, equals('DELETE'));
      });
    });

    group('requestInfo auto header classification (UI-04)', () {
      HttpRequest buildRequestWithHeaders() {
        return HttpRequest.empty().copyWith(
          method: HttpMethod.get,
          url: 'http://api.example.com/users',
          headers: [
            KeyValuePair(id: 'h1', key: 'Accept', value: 'application/json'),
            KeyValuePair(id: 'h2', key: 'Host', value: 'custom.internal'),
            KeyValuePair(id: 'h3', key: 'X-Api-Key', value: 'abc'),
          ],
        );
      }

      void stubDioSuccess(Map<String, String> dioAutoHeaders) {
        when(mockDio.request<Uint8List>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => Response<Uint8List>(
              data: Uint8List.fromList(utf8.encode('{"ok": true}')),
              statusCode: 200,
              requestOptions: RequestOptions(
                path: 'http://api.example.com/users',
                headers: dioAutoHeaders,
              ),
              headers: Headers.fromMap({
                'content-type': ['application/json'],
              }),
            ));
      }

      test('manually added headers with auto-like names are not marked auto',
          () async {
        // 用户手填了 Accept / Host（与常见自动 header 同名）
        final request = buildRequestWithHeaders();
        stubDioSuccess({'content-length': '12'});

        final response = await httpService.sendRequest(request);

        final requestInfo = response.requestInfo!;
        // 手填的 accept/host/x-api-key 都不在 auto 集合中
        expect(requestInfo.autoHeaderKeys, isNot(contains('accept')));
        expect(requestInfo.autoHeaderKeys, isNot(contains('host')));
        expect(requestInfo.autoHeaderKeys, isNot(contains('x-api-key')));
        // Dio 注入的 content-length 与默认 user-agent 标记为 auto
        expect(requestInfo.autoHeaderKeys, contains('content-length'));
        expect(requestInfo.autoHeaderKeys, contains('user-agent'));
      });

      test('user-set Accept prevents default accept injection', () async {
        final request = buildRequestWithHeaders();
        stubDioSuccess({});

        final response = await httpService.sendRequest(request);

        final acceptHeaders = response.requestInfo!.headers
            .where((h) => h.key.toLowerCase() == 'accept')
            .toList();
        // 只保留用户设置的 Accept，不再追加默认 */*
        expect(acceptHeaders.length, 1);
        expect(acceptHeaders.single.value, 'application/json');
        expect(response.requestInfo!.autoHeaderKeys, isNot(contains('accept')));
      });

      test('headers list keeps user headers before auto headers', () async {
        final request = buildRequestWithHeaders();
        stubDioSuccess({'content-length': '12'});

        final response = await httpService.sendRequest(request);

        final keys = response.requestInfo!.headers
            .map((h) => h.key.toLowerCase())
            .toList();
        final lastUserIndex = keys.lastIndexOf('x-api-key');
        final firstAutoIndex =
            keys.indexWhere((k) => k == 'content-length' || k == 'user-agent');
        expect(firstAutoIndex, greaterThan(lastUserIndex));
      });

      test('auto keys are empty when no headers are auto-added', () async {
        // 用户覆盖了所有默认 header，Dio 也未注入新 header
        final request = HttpRequest.empty().copyWith(
          method: HttpMethod.get,
          url: 'http://api.example.com/users',
          headers: [
            KeyValuePair(id: 'h1', key: 'user-agent', value: 'Hopp-Test/1.0'),
            KeyValuePair(id: 'h2', key: 'accept', value: 'text/plain'),
          ],
        );
        stubDioSuccess({});

        final response = await httpService.sendRequest(request);

        expect(response.requestInfo!.autoHeaderKeys, isEmpty);
      });
    });
  });
}
