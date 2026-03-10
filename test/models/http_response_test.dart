import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_response.dart';
import 'package:hopp/models/key_value_pair.dart';

void main() {
  group('HttpResponse', () {
    group('creation', () {
      test('should create HttpResponse with all fields', () {
        final response = HttpResponse(
          body: '{"success": true}',
          headers: [
            const KeyValuePair(
              id: 'h1',
              key: 'Content-Type',
              value: 'application/json',
              enabled: true,
            ),
          ],
          statusCode: 200,
          statusText: 'OK',
          durationMs: 150,
          sizeBytes: 1024,
          error: null,
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        );

        expect(response.body, equals('{\"success\": true}'));
        expect(response.headers.length, equals(1));
        expect(response.statusCode, equals(200));
        expect(response.statusText, equals('OK'));
        expect(response.durationMs, equals(150));
        expect(response.sizeBytes, equals(1024));
        expect(response.error, isNull);
        expect(response.timestamp, equals(DateTime(2024, 1, 1, 12, 0, 0)));
      });

      test('should create HttpResponse with default values', () {
        const response = HttpResponse();

        expect(response.body, isNull);
        expect(response.headers, isEmpty);
        expect(response.statusCode, isNull);
        expect(response.statusText, isNull);
        expect(response.durationMs, isNull);
        expect(response.sizeBytes, isNull);
        expect(response.error, isNull);
        expect(response.timestamp, isNull);
      });

      test('should create HttpResponse with partial fields', () {
        const response = HttpResponse(
          statusCode: 404,
          statusText: 'Not Found',
        );

        expect(response.statusCode, equals(404));
        expect(response.statusText, equals('Not Found'));
        expect(response.body, isNull);
      });
    });

    group('empty factory', () {
      test('should create empty HttpResponse', () {
        final response = HttpResponse.empty();

        expect(response.body, isNull);
        expect(response.headers, isEmpty);
        expect(response.statusCode, isNull);
        expect(response.statusText, isNull);
        expect(response.durationMs, isNull);
        expect(response.sizeBytes, isNull);
        expect(response.error, isNull);
        expect(response.timestamp, isNull);
      });
    });

    group('error factory', () {
      test('should create error HttpResponse with message', () {
        final response = HttpResponse.error('Network timeout');

        expect(response.error, equals('Network timeout'));
        expect(response.timestamp, isNotNull);
        expect(response.body, isNull);
        expect(response.statusCode, isNull);
      });

      test('should create error HttpResponse with different messages', () {
        final response1 = HttpResponse.error('Connection refused');
        final response2 = HttpResponse.error('DNS lookup failed');

        expect(response1.error, equals('Connection refused'));
        expect(response2.error, equals('DNS lookup failed'));
      });
    });

    group('copyWith', () {
      test('should copy with new body', () {
        const response = HttpResponse(body: 'old body');

        final copied = response.copyWith(body: 'new body');

        expect(copied.body, equals('new body'));
        expect(copied.statusCode, isNull);
      });

      test('should copy with new status code', () {
        const response = HttpResponse(statusCode: 200);

        final copied = response.copyWith(statusCode: 201);

        expect(copied.statusCode, equals(201));
      });

      test('should copy with new headers', () {
        const response = HttpResponse(headers: []);

        final newHeaders = [
          const KeyValuePair(
            id: 'h1',
            key: 'Content-Type',
            value: 'text/html',
            enabled: true,
          ),
        ];
        final copied = response.copyWith(headers: newHeaders);

        expect(copied.headers.length, equals(1));
        expect(copied.headers.first.value, equals('text/html'));
      });

      test('should copy with new duration', () {
        const response = HttpResponse(durationMs: 100);

        final copied = response.copyWith(durationMs: 250);

        expect(copied.durationMs, equals(250));
      });

      test('should copy with new size', () {
        const response = HttpResponse(sizeBytes: 512);

        final copied = response.copyWith(sizeBytes: 2048);

        expect(copied.sizeBytes, equals(2048));
      });

      test('should copy with new error', () {
        const response = HttpResponse(error: null);

        final copied = response.copyWith(error: 'New error');

        expect(copied.error, equals('New error'));
      });

      test('should copy without changes when no arguments provided', () {
        const response = HttpResponse(
          statusCode: 200,
          body: 'test',
        );

        final copied = response.copyWith();

        expect(copied, equals(response));
      });

      test('should allow setting fields to null explicitly', () {
        const response = HttpResponse(statusCode: 200, body: 'test');

        final copied = response.copyWith(statusCode: null, body: null);

        expect(copied.statusCode, isNull);
        expect(copied.body, isNull);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final response = HttpResponse(
          body: '{"data": []}',
          statusCode: 200,
          statusText: 'OK',
          durationMs: 100,
          sizeBytes: 512,
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final json = response.toJson();

        expect(json['body'], equals('{\"data\": []}'));
        expect(json['statusCode'], equals(200));
        expect(json['statusText'], equals('OK'));
        expect(json['durationMs'], equals(100));
        expect(json['sizeBytes'], equals(512));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'body': '{\"result\": \"success\"}',
          'headers': [],
          'statusCode': 201,
          'statusText': 'Created',
          'durationMs': 200,
          'sizeBytes': 1024,
          'error': null,
          'timestamp': '2024-01-01T12:00:00.000',
        };

        final response = HttpResponse.fromJson(json);

        expect(response.body, equals('{\"result\": \"success\"}'));
        expect(response.statusCode, equals(201));
        expect(response.statusText, equals('Created'));
        expect(response.durationMs, equals(200));
        expect(response.sizeBytes, equals(1024));
      });

      test('should handle JSON with nested headers', () {
        final json = {
          'body': null,
          'headers': [
            {
              'id': 'h1',
              'key': 'X-Request-Id',
              'value': 'abc123',
              'enabled': true,
            },
          ],
          'statusCode': 500,
          'statusText': 'Internal Server Error',
          'durationMs': 50,
          'sizeBytes': 256,
          'error': null,
        };

        final response = HttpResponse.fromJson(json);

        expect(response.headers.length, equals(1));
        expect(response.headers.first.key, equals('X-Request-Id'));
        expect(response.statusCode, equals(500));
      });

      test('should handle JSON with error', () {
        final json = {
          'body': null,
          'headers': [],
          'statusCode': null,
          'statusText': null,
          'durationMs': null,
          'sizeBytes': null,
          'error': 'Connection timeout',
          'timestamp': '2024-01-01T12:00:00.000',
        };

        final response = HttpResponse.fromJson(json);

        expect(response.error, equals('Connection timeout'));
        expect(response.statusCode, isNull);
      });
    });

    group('equality', () {
      test('identical responses should be equal', () {
        const response1 = HttpResponse(
          statusCode: 200,
          body: 'test',
        );
        const response2 = HttpResponse(
          statusCode: 200,
          body: 'test',
        );

        expect(response1, equals(response2));
      });

      test('responses with different status codes should not be equal', () {
        const response1 = HttpResponse(statusCode: 200);
        const response2 = HttpResponse(statusCode: 404);

        expect(response1, isNot(equals(response2)));
      });

      test('responses with different bodies should not be equal', () {
        const response1 = HttpResponse(body: 'test1');
        const response2 = HttpResponse(body: 'test2');

        expect(response1, isNot(equals(response2)));
      });
    });

    group('edge cases', () {
      test('should handle empty body string', () {
        const response = HttpResponse(body: '');

        expect(response.body, equals(''));
      });

      test('should handle very large size', () {
        const response = HttpResponse(sizeBytes: 999999999);

        expect(response.sizeBytes, equals(999999999));
      });

      test('should handle zero values', () {
        const response = HttpResponse(
          statusCode: 0,
          durationMs: 0,
          sizeBytes: 0,
        );

        expect(response.statusCode, equals(0));
        expect(response.durationMs, equals(0));
        expect(response.sizeBytes, equals(0));
      });

      test('should handle negative status codes', () {
        const response = HttpResponse(statusCode: -1);

        expect(response.statusCode, equals(-1));
      });
    });
  });
}
