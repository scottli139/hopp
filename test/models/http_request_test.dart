import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/key_value_pair.dart';

void main() {
  group('HttpRequest', () {
    group('creation', () {
      test('should create HttpRequest with all required fields', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test Request',
          method: HttpMethod.post,
          url: 'https://api.example.com/users',
          params: [
            KeyValuePair.empty().copyWith(key: 'page', value: '1'),
          ],
          headers: [
            const KeyValuePair(
              id: 'h1',
              key: 'Content-Type',
              value: 'application/json',
              enabled: true,
            ),
          ],
          body: '{"name": "test"}',
          bodyType: 'json',
          parentId: 'col-1',
          sortOrder: 1,
        );

        expect(request.id, equals('req-1'));
        expect(request.name, equals('Test Request'));
        expect(request.method, equals(HttpMethod.post));
        expect(request.url, equals('https://api.example.com/users'));
        expect(request.params.length, equals(1));
        expect(request.headers.length, equals(1));
        expect(request.body, equals('{"name": "test"}'));
        expect(request.bodyType, equals('json'));
        expect(request.parentId, equals('col-1'));
        expect(request.sortOrder, equals(1));
      });

      test('should create HttpRequest with default values', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Simple Request',
        );

        expect(request.method, equals(HttpMethod.get));
        expect(request.url, equals(''));
        expect(request.params, isEmpty);
        expect(request.headers, isEmpty);
        expect(request.body, equals(''));
        expect(request.bodyType, equals('none'));
        expect(request.parentId, isNull);
        expect(request.sortOrder, equals(0));
      });
    });

    group('empty factory', () {
      test('should create empty HttpRequest with generated id and defaults',
          () {
        final request = HttpRequest.empty();

        expect(request.id, isNotEmpty);
        expect(request.name, equals('New Request'));
        expect(request.method, equals(HttpMethod.get));
        expect(request.url, equals('https://httpbin.org/get'));
        expect(request.params, isEmpty);
        expect(request.headers, isEmpty);
        expect(request.body, equals(''));
        expect(request.bodyType, equals('none'));
      });

      test('should generate unique ids for multiple empty requests', () async {
        final request1 = HttpRequest.empty();
        await Future<void>.delayed(const Duration(milliseconds: 2));
        final request2 = HttpRequest.empty();

        expect(request1.id, isNot(equals(request2.id)));
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Original Name',
        );

        final copied = request.copyWith(name: 'Updated Name');

        expect(copied.id, equals('req-1'));
        expect(copied.name, equals('Updated Name'));
        expect(copied.method, equals(HttpMethod.get));
      });

      test('should copy with new method', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test',
        );

        final copied = request.copyWith(method: HttpMethod.post);

        expect(copied.method, equals(HttpMethod.post));
      });

      test('should copy with new URL', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test',
          url: 'https://old.example.com',
        );

        final copied = request.copyWith(url: 'https://new.example.com');

        expect(copied.url, equals('https://new.example.com'));
      });

      test('should copy with new params list', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test',
          params: [KeyValuePair.empty()],
        );

        final newParams = [
          const KeyValuePair(
            id: 'p1',
            key: 'search',
            value: 'query',
            enabled: true,
          ),
        ];
        final copied = request.copyWith(params: newParams);

        expect(copied.params.length, equals(1));
        expect(copied.params.first.key, equals('search'));
      });

      test('should copy with new headers list', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test',
          headers: [],
        );

        final newHeaders = [
          const KeyValuePair(
            id: 'h1',
            key: 'Authorization',
            value: 'Bearer token',
            enabled: true,
          ),
        ];
        final copied = request.copyWith(headers: newHeaders);

        expect(copied.headers.length, equals(1));
        expect(copied.headers.first.key, equals('Authorization'));
      });

      test('should copy with new body', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test',
          body: 'old body',
        );

        final copied = request.copyWith(body: 'new body');

        expect(copied.body, equals('new body'));
      });

      test('should copy with new bodyType', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test',
          bodyType: 'none',
        );

        final copied = request.copyWith(bodyType: 'form-data');

        expect(copied.bodyType, equals('form-data'));
      });

      test('should copy without changes when no arguments provided', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test',
          method: HttpMethod.post,
          url: 'https://example.com',
        );

        final copied = request.copyWith();

        expect(copied, equals(request));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test Request',
          method: HttpMethod.post,
          url: 'https://api.example.com/users',
          params: [],
          headers: [],
          body: '{"test": true}',
          bodyType: 'json',
          parentId: 'col-1',
          sortOrder: 1,
        );

        final json = request.toJson();

        expect(json['id'], equals('req-1'));
        expect(json['name'], equals('Test Request'));
        expect(json['method'], equals('post'));
        expect(json['url'], equals('https://api.example.com/users'));
        expect(json['body'], equals('{\"test\": true}'));
        expect(json['bodyType'], equals('json'));
        expect(json['parentId'], equals('col-1'));
        expect(json['sortOrder'], equals(1));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'req-1',
          'name': 'Test Request',
          'method': 'put',
          'url': 'https://api.example.com/users/1',
          'params': [],
          'headers': [],
          'body': '',
          'bodyType': 'none',
          'parentId': null,
          'sortOrder': 0,
        };

        final request = HttpRequest.fromJson(json);

        expect(request.id, equals('req-1'));
        expect(request.name, equals('Test Request'));
        expect(request.method, equals(HttpMethod.put));
        expect(request.url, equals('https://api.example.com/users/1'));
      });

      test('should handle JSON with nested KeyValuePair objects', () {
        final json = {
          'id': 'req-1',
          'name': 'Test',
          'method': 'get',
          'url': 'https://example.com',
          'params': [
            {
              'id': 'p1',
              'key': 'page',
              'value': '1',
              'enabled': true,
            },
          ],
          'headers': [
            {
              'id': 'h1',
              'key': 'Accept',
              'value': 'application/json',
              'enabled': true,
            },
          ],
          'body': '',
          'bodyType': 'none',
          'sortOrder': 0,
        };

        final request = HttpRequest.fromJson(json);

        expect(request.params.length, equals(1));
        expect(request.params.first.key, equals('page'));
        expect(request.headers.length, equals(1));
        expect(request.headers.first.key, equals('Accept'));
      });

      test('should handle all HTTP methods in JSON', () {
        for (final method in HttpMethod.values) {
          final json = {
            'id': 'req-1',
            'name': 'Test',
            'method': method.name,
            'url': 'https://example.com',
            'params': [],
            'headers': [],
            'body': '',
            'bodyType': 'none',
            'sortOrder': 0,
          };

          final request = HttpRequest.fromJson(json);
          expect(request.method, equals(method),
              reason: 'Failed for ${method.name}');
        }
      });
    });

    group('equality', () {
      test('identical requests should be equal', () {
        final request1 = HttpRequest(
          id: 'req-1',
          name: 'Test',
          method: HttpMethod.get,
          url: 'https://example.com',
        );
        final request2 = HttpRequest(
          id: 'req-1',
          name: 'Test',
          method: HttpMethod.get,
          url: 'https://example.com',
        );

        expect(request1, equals(request2));
      });

      test('requests with different ids should not be equal', () {
        final request1 = HttpRequest(id: 'req-1', name: 'Test');
        final request2 = HttpRequest(id: 'req-2', name: 'Test');

        expect(request1, isNot(equals(request2)));
      });

      test('requests with different names should not be equal', () {
        final request1 = HttpRequest(id: 'req-1', name: 'Test 1');
        final request2 = HttpRequest(id: 'req-1', name: 'Test 2');

        expect(request1, isNot(equals(request2)));
      });
    });
  });
}
