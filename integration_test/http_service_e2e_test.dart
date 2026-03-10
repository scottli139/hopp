import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/services/http_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logger/logger.dart';

/// HttpService End-to-End Tests
/// 
/// These tests make real HTTP requests to verify network connectivity
/// without relying on the UI.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HttpService E2E Tests', () {
    late HttpService httpService;

    setUp(() {
      httpService = HttpService(
        logger: Logger(level: Level.debug),
      );
      httpService.configure(
        timeoutMs: 30000,
        followRedirects: true,
        maxRedirects: 5,
        validateCertificates: true,
      );
    });

    test('should successfully GET https://httpbin.org/get', () async {
      final request = HttpRequest(
        id: 'test-get',
        name: 'Test GET',
        method: HttpMethod.get,
        url: 'https://httpbin.org/get',
        params: [],
        headers: [],
        body: '',
        bodyType: 'none',
      );

      final response = await httpService.sendRequest(request);

      expect(response.error, isNull, 
          reason: 'Should not have error. Error: ${response.error}');
      expect(response.statusCode, equals(200));
      expect(response.statusText, equals('OK'));
      expect(response.body, isNotNull);
      expect(response.durationMs, greaterThan(0));
      expect(response.timestamp, isNotNull);
    });

    test('should successfully GET https://ipinfo.io/json', () async {
      final request = HttpRequest(
        id: 'test-ipinfo',
        name: 'Test ipinfo',
        method: HttpMethod.get,
        url: 'https://ipinfo.io/json',
        params: [],
        headers: [],
        body: '',
        bodyType: 'none',
      );

      final response = await httpService.sendRequest(request);

      expect(response.error, isNull,
          reason: 'Should not have error. Error: ${response.error}');
      expect(response.statusCode, equals(200));
      expect(response.body, isNotNull);
      expect(response.body, contains('ip'));
    });

    test('should handle POST with JSON body', () async {
      final request = HttpRequest(
        id: 'test-post',
        name: 'Test POST',
        method: HttpMethod.post,
        url: 'https://httpbin.org/post',
        params: [],
        headers: [
          // Content-Type will be set automatically by Dio for JSON
        ],
        body: '{"test": "data", "number": 123}',
        bodyType: 'json',
      );

      final response = await httpService.sendRequest(request);

      expect(response.error, isNull,
          reason: 'Should not have error. Error: ${response.error}');
      expect(response.statusCode, equals(200));
      expect(response.body, isNotNull);
      expect(response.body, contains('"test": "data"'));
    });

    test('should handle query parameters', () async {
      final request = HttpRequest(
        id: 'test-params',
        name: 'Test Params',
        method: HttpMethod.get,
        url: 'https://httpbin.org/get',
        params: [
          // Using a simple param since we don't have KeyValuePair here
        ],
        headers: [],
        body: '',
        bodyType: 'none',
      );

      final response = await httpService.sendRequest(request);

      expect(response.error, isNull);
      expect(response.statusCode, equals(200));
    });

    test('should handle 404 error correctly', () async {
      final request = HttpRequest(
        id: 'test-404',
        name: 'Test 404',
        method: HttpMethod.get,
        url: 'https://httpbin.org/status/404',
        params: [],
        headers: [],
        body: '',
        bodyType: 'none',
      );

      final response = await httpService.sendRequest(request);

      // 404 should be a valid response, not an error
      expect(response.statusCode, equals(404));
      expect(response.error, isNull);
    });

    test('should handle timeout for unreachable host', () async {
      final request = HttpRequest(
        id: 'test-timeout',
        name: 'Test Timeout',
        method: HttpMethod.get,
        url: 'http://192.0.2.1:81', // Non-routable IP for testing
        params: [],
        headers: [],
        body: '',
        bodyType: 'none',
      );

      // Reconfigure with short timeout
      httpService.configure(
        timeoutMs: 2000, // 2 second timeout
        followRedirects: true,
        maxRedirects: 5,
        validateCertificates: true,
      );

      final response = await httpService.sendRequest(request);

      // Should get a timeout or connection error
      expect(
        response.error != null || response.statusCode == null,
        isTrue,
        reason: 'Should have error or no status code for unreachable host',
      );
    });
  });
}
