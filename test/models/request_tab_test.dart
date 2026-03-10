import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/request_tab.dart';

void main() {
  group('RequestTab', () {
    late HttpRequest testRequest;

    setUp(() {
      testRequest = HttpRequest(
        id: 'req-1',
        name: 'Test Request',
        method: HttpMethod.get,
        url: 'https://api.example.com',
      );
    });

    group('creation', () {
      test('should create RequestTab with all required fields', () {
        final tab = RequestTab(
          id: 'tab-1',
          request: testRequest,
          isDirty: true,
          lastAccessed: DateTime(2024, 1, 1, 12, 0, 0),
        );

        expect(tab.id, equals('tab-1'));
        expect(tab.request, equals(testRequest));
        expect(tab.isDirty, isTrue);
        expect(tab.lastAccessed, equals(DateTime(2024, 1, 1, 12, 0, 0)));
      });

      test('should create RequestTab with default values', () {
        final tab = RequestTab(
          id: 'tab-1',
          request: testRequest,
        );

        expect(tab.isDirty, isFalse);
        expect(tab.lastAccessed, isNull);
      });
    });

    group('fromRequest factory', () {
      test('should create RequestTab from HttpRequest', () {
        final request = HttpRequest(
          id: 'req-2',
          name: 'My Request',
          method: HttpMethod.post,
          url: 'https://api.example.com/users',
        );

        final tab = RequestTab.fromRequest(request);

        expect(tab.id, equals('req-2'));
        expect(tab.request, equals(request));
        expect(tab.isDirty, isFalse);
        expect(tab.lastAccessed, isNotNull);
      });

      test('should set id from request id', () {
        final request = HttpRequest(
          id: 'custom-request-id',
          name: 'Test',
          method: HttpMethod.get,
          url: 'https://example.com',
        );

        final tab = RequestTab.fromRequest(request);

        expect(tab.id, equals('custom-request-id'));
        expect(tab.id, equals(request.id));
      });

      test('should set lastAccessed to current time', () {
        final before = DateTime.now();
        final tab = RequestTab.fromRequest(testRequest);
        final after = DateTime.now();

        expect(tab.lastAccessed, isNotNull);
        expect(tab.lastAccessed!.isAfter(before) || tab.lastAccessed!.isAtSameMomentAs(before), isTrue);
        expect(tab.lastAccessed!.isBefore(after) || tab.lastAccessed!.isAtSameMomentAs(after), isTrue);
      });
    });

    group('copyWith', () {
      test('should copy with new request', () {
        final tab = RequestTab(
          id: 'tab-1',
          request: testRequest,
        );

        final newRequest = testRequest.copyWith(name: 'Updated Request');
        final copied = tab.copyWith(request: newRequest);

        expect(copied.id, equals('tab-1'));
        expect(copied.request.name, equals('Updated Request'));
      });

      test('should copy with new isDirty state', () {
        final tab = RequestTab(
          id: 'tab-1',
          request: testRequest,
          isDirty: false,
        );

        final copied = tab.copyWith(isDirty: true);

        expect(copied.isDirty, isTrue);
      });

      test('should copy with new lastAccessed', () {
        final tab = RequestTab(
          id: 'tab-1',
          request: testRequest,
        );

        final newTime = DateTime(2024, 6, 15, 10, 30, 0);
        final copied = tab.copyWith(lastAccessed: newTime);

        expect(copied.lastAccessed, equals(newTime));
      });

      test('should copy without changes when no arguments provided', () {
        final tab = RequestTab(
          id: 'tab-1',
          request: testRequest,
          isDirty: true,
        );

        final copied = tab.copyWith();

        expect(copied, equals(tab));
      });

      test('should allow setting lastAccessed to null', () {
        final tab = RequestTab(
          id: 'tab-1',
          request: testRequest,
          lastAccessed: DateTime.now(),
        );

        final copied = tab.copyWith(lastAccessed: null);

        expect(copied.lastAccessed, isNull);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final tab = RequestTab(
          id: 'tab-1',
          request: testRequest,
          isDirty: true,
          lastAccessed: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final json = tab.toJson();

        expect(json['id'], equals('tab-1'));
        expect(json['isDirty'], equals(true));
        expect(json['lastAccessed'], equals('2024-01-01T12:00:00.000'));
        // Request field is serialized (Freezed handles nested objects)
        expect(json['request'], isNotNull);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'tab-1',
          'request': {
            'id': 'req-1',
            'name': 'Test Request',
            'method': 'get',
            'url': 'https://api.example.com',
            'params': [],
            'headers': [],
            'body': '',
            'bodyType': 'none',
            'sortOrder': 0,
          },
          'isDirty': false,
          'lastAccessed': null,
        };

        final tab = RequestTab.fromJson(json);

        expect(tab.id, equals('tab-1'));
        expect(tab.request.id, equals('req-1'));
        expect(tab.request.name, equals('Test Request'));
        expect(tab.isDirty, isFalse);
        expect(tab.lastAccessed, isNull);
      });

      test('should handle JSON with timestamp', () {
        final json = {
          'id': 'tab-1',
          'request': {
            'id': 'req-1',
            'name': 'Test',
            'method': 'get',
            'url': 'https://example.com',
            'params': [],
            'headers': [],
            'body': '',
            'bodyType': 'none',
            'sortOrder': 0,
          },
          'isDirty': true,
          'lastAccessed': '2024-03-15T09:30:00.000',
        };

        final tab = RequestTab.fromJson(json);

        expect(tab.lastAccessed, equals(DateTime(2024, 3, 15, 9, 30, 0)));
        expect(tab.isDirty, isTrue);
      });

      test('should handle JSON with different HTTP methods', () {
        for (final method in HttpMethod.values) {
          final json = {
            'id': 'tab-1',
            'request': {
              'id': 'req-1',
              'name': 'Test',
              'method': method.name,
              'url': 'https://example.com',
              'params': [],
              'headers': [],
              'body': '',
              'bodyType': 'none',
              'sortOrder': 0,
            },
            'isDirty': false,
            'lastAccessed': null,
          };

          final tab = RequestTab.fromJson(json);
          expect(tab.request.method, equals(method), reason: 'Failed for ${method.name}');
        }
      });
    });

    group('equality', () {
      test('identical tabs should be equal', () {
        final tab1 = RequestTab(
          id: 'tab-1',
          request: testRequest,
          isDirty: true,
        );
        final tab2 = RequestTab(
          id: 'tab-1',
          request: testRequest,
          isDirty: true,
        );

        expect(tab1, equals(tab2));
      });

      test('tabs with different ids should not be equal', () {
        final tab1 = RequestTab(
          id: 'tab-1',
          request: testRequest,
        );
        final tab2 = RequestTab(
          id: 'tab-2',
          request: testRequest,
        );

        expect(tab1, isNot(equals(tab2)));
      });

      test('tabs with different isDirty states should not be equal', () {
        final tab1 = RequestTab(
          id: 'tab-1',
          request: testRequest,
          isDirty: false,
        );
        final tab2 = RequestTab(
          id: 'tab-1',
          request: testRequest,
          isDirty: true,
        );

        expect(tab1, isNot(equals(tab2)));
      });

      test('tabs with different requests should not be equal', () {
        final tab1 = RequestTab(
          id: 'tab-1',
          request: testRequest,
        );
        final tab2 = RequestTab(
          id: 'tab-1',
          request: testRequest.copyWith(name: 'Different'),
        );

        expect(tab1, isNot(equals(tab2)));
      });
    });

    group('edge cases', () {
      test('should handle empty id', () {
        final tab = RequestTab(
          id: '',
          request: testRequest,
        );

        expect(tab.id, equals(''));
      });

      test('should handle request with empty URL', () {
        final request = testRequest.copyWith(url: '');
        final tab = RequestTab.fromRequest(request);

        expect(tab.request.url, equals(''));
      });

      test('should handle rapid fromRequest calls', () async {
        final request1 = HttpRequest.empty();
        await Future<void>.delayed(const Duration(milliseconds: 2));
        final request2 = HttpRequest.empty();

        final tab1 = RequestTab.fromRequest(request1);
        await Future<void>.delayed(const Duration(milliseconds: 2));
        final tab2 = RequestTab.fromRequest(request2);

        expect(tab1.id, isNot(equals(tab2.id)));
        expect(tab1.lastAccessed, isNotNull);
        expect(tab2.lastAccessed, isNotNull);
      });
    });
  });
}
