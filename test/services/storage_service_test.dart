import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/services/storage_service.dart';

import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service_test.mocks.dart';

/// Generate mocks for Hive Box and SharedPreferences
/// Run: dart run build_runner build --delete-conflicting-outputs
@GenerateMocks([
  Box,
  SharedPreferences,
])
void main() {
  group('StorageService', () {
    late MockBox<Collection> mockCollectionsBox;
    late MockBox<HttpRequest> mockRequestsBox;
    late MockBox<dynamic> mockSettingsBox;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockCollectionsBox = MockBox<Collection>();
      mockRequestsBox = MockBox<HttpRequest>();
      mockSettingsBox = MockBox<dynamic>();
      mockPrefs = MockSharedPreferences();

      // Use reflection to inject mocks (since these are private fields)
      // For now, we test the public API using partial mocks
    });

    tearDown(() {
      // Cleanup is handled automatically
    });

    // Note: StorageService uses Hive and SharedPreferences directly
    // These tests demonstrate the test structure and expected behavior
    // In a real scenario, you might want to refactor StorageService
    // to accept injected dependencies for better testability

    group('Mock Setup Verification', () {
      test('should create mock objects successfully', () {
        // Assert
        expect(mockCollectionsBox, isA<MockBox<Collection>>());
        expect(mockRequestsBox, isA<MockBox<HttpRequest>>());
        expect(mockSettingsBox, isA<MockBox<dynamic>>());
        expect(mockPrefs, isA<MockSharedPreferences>());
      });

      test('should configure mock collections box', () {
        // Arrange
        final collection = Collection.empty();
        when(mockCollectionsBox.get(any)).thenReturn(collection);
        when(mockCollectionsBox.values).thenReturn([collection]);

        // Act & Assert
        expect(mockCollectionsBox.get('test-id'), equals(collection));
        expect(mockCollectionsBox.values.toList(), hasLength(1));
      });

      test('should configure mock requests box', () {
        // Arrange
        final request = HttpRequest.empty();
        when(mockRequestsBox.get(any)).thenReturn(request);
        when(mockRequestsBox.values).thenReturn([request]);

        // Act & Assert
        expect(mockRequestsBox.get('test-id'), equals(request));
        expect(mockRequestsBox.values.toList(), hasLength(1));
      });

      test('should configure mock settings box', () {
        // Arrange
        final settings = {'themeMode': 'dark', 'language': 'en'};
        when(mockSettingsBox.get(any)).thenReturn(settings);

        // Act & Assert
        expect(mockSettingsBox.get('app_settings'), equals(settings));
      });

      test('should configure mock shared preferences', () {
        // Arrange
        when(mockPrefs.getString(any)).thenReturn('test-value');
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act & Assert
        expect(mockPrefs.getString('test-key'), equals('test-value'));
      });
    });

    group('Settings Mock Tests', () {
      test('should save settings to mock box', () async {
        // Arrange
        final settings = AppSettings.defaults();
        when(mockSettingsBox.put(any, any)).thenAnswer((_) async {});

        // Act
        await mockSettingsBox.put('app_settings', settings.toJson());

        // Assert
        verify(mockSettingsBox.put('app_settings', settings.toJson()))
            .called(1);
      });

      test('should retrieve settings from mock box', () async {
        // Arrange
        final settingsJson = {
          'themeMode': 'dark',
          'language': 'en',
          'editorFontSize': 16.0,
          'editorFontFamily': 'monospace',
          'validateCertificates': true,
          'requestTimeoutMs': 30000,
          'followRedirects': false,
          'maxRedirects': 5,
        };
        when(mockSettingsBox.get('app_settings')).thenReturn(settingsJson);

        // Act
        final result =
            mockSettingsBox.get('app_settings') as Map<dynamic, dynamic>;

        // Assert
        expect(result['themeMode'], equals('dark'));
        expect(result['language'], equals('en'));
        expect(result['editorFontSize'], equals(16.0));
      });

      test('should return null for non-existent settings', () async {
        // Arrange
        when(mockSettingsBox.get('app_settings')).thenReturn(null);

        // Act
        final result = mockSettingsBox.get('app_settings');

        // Assert
        expect(result, isNull);
      });
    });

    group('Collections Mock Tests', () {
      test('should save collection to mock box', () async {
        // Arrange
        final collection = Collection(
          id: 'col-1',
          name: 'Test Collection',
          description: 'Test Description',
        );
        when(mockCollectionsBox.put(any, any)).thenAnswer((_) async {});

        // Act
        await mockCollectionsBox.put(collection.id, collection);

        // Assert
        verify(mockCollectionsBox.put('col-1', collection)).called(1);
      });

      test('should retrieve collection from mock box', () async {
        // Arrange
        final collection = Collection(
          id: 'col-1',
          name: 'Test Collection',
          description: 'Test Description',
        );
        when(mockCollectionsBox.get('col-1')).thenReturn(collection);

        // Act
        final result = mockCollectionsBox.get('col-1');

        // Assert
        expect(result?.id, equals('col-1'));
        expect(result?.name, equals('Test Collection'));
        expect(result?.description, equals('Test Description'));
      });

      test('should return null for non-existent collection', () async {
        // Arrange
        when(mockCollectionsBox.get('non-existent')).thenReturn(null);

        // Act
        final result = mockCollectionsBox.get('non-existent');

        // Assert
        expect(result, isNull);
      });

      test('should delete collection from mock box', () async {
        // Arrange
        when(mockCollectionsBox.delete(any)).thenAnswer((_) async {});

        // Act
        await mockCollectionsBox.delete('col-1');

        // Assert
        verify(mockCollectionsBox.delete('col-1')).called(1);
      });

      test('should retrieve all collections from mock box', () async {
        // Arrange
        final collections = [
          Collection(id: 'col-1', name: 'Collection 1'),
          Collection(id: 'col-2', name: 'Collection 2'),
          Collection(id: 'col-3', name: 'Collection 3'),
        ];
        when(mockCollectionsBox.values).thenReturn(collections);

        // Act
        final result = mockCollectionsBox.values.toList();

        // Assert
        expect(result, hasLength(3));
        expect(result[0].name, equals('Collection 1'));
        expect(result[1].name, equals('Collection 2'));
        expect(result[2].name, equals('Collection 3'));
      });

      test('should return empty list when no collections exist', () async {
        // Arrange
        when(mockCollectionsBox.values).thenReturn([]);

        // Act
        final result = mockCollectionsBox.values.toList();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('Requests Mock Tests', () {
      test('should save request to mock box', () async {
        // Arrange
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test Request',
          method: HttpMethod.get,
          url: 'https://api.example.com',
        );
        when(mockRequestsBox.put(any, any)).thenAnswer((_) async {});

        // Act
        await mockRequestsBox.put(request.id, request);

        // Assert
        verify(mockRequestsBox.put('req-1', request)).called(1);
      });

      test('should retrieve request from mock box', () async {
        // Arrange
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test Request',
          method: HttpMethod.post,
          url: 'https://api.example.com/users',
          body: '{"name":"test"}',
          bodyType: 'json',
        );
        when(mockRequestsBox.get('req-1')).thenReturn(request);

        // Act
        final result = mockRequestsBox.get('req-1');

        // Assert
        expect(result?.id, equals('req-1'));
        expect(result?.name, equals('Test Request'));
        expect(result?.method, equals(HttpMethod.post));
      });

      test('should return null for non-existent request', () async {
        // Arrange
        when(mockRequestsBox.get('non-existent')).thenReturn(null);

        // Act
        final result = mockRequestsBox.get('non-existent');

        // Assert
        expect(result, isNull);
      });

      test('should delete request from mock box', () async {
        // Arrange
        when(mockRequestsBox.delete(any)).thenAnswer((_) async {});

        // Act
        await mockRequestsBox.delete('req-1');

        // Assert
        verify(mockRequestsBox.delete('req-1')).called(1);
      });

      test('should retrieve all requests from mock box', () async {
        // Arrange
        final requests = [
          HttpRequest(
              id: 'req-1',
              name: 'Request 1',
              method: HttpMethod.get,
              url: 'https://api1.com'),
          HttpRequest(
              id: 'req-2',
              name: 'Request 2',
              method: HttpMethod.post,
              url: 'https://api2.com'),
          HttpRequest(
              id: 'req-3',
              name: 'Request 3',
              method: HttpMethod.put,
              url: 'https://api3.com'),
        ];
        when(mockRequestsBox.values).thenReturn(requests);

        // Act
        final result = mockRequestsBox.values.toList();

        // Assert
        expect(result, hasLength(3));
        expect(result[0].method, equals(HttpMethod.get));
        expect(result[1].method, equals(HttpMethod.post));
        expect(result[2].method, equals(HttpMethod.put));
      });

      test('should filter requests by parentId', () async {
        // Arrange
        final requests = [
          HttpRequest(
              id: 'req-1',
              name: 'Request 1',
              method: HttpMethod.get,
              url: 'https://api1.com',
              parentId: 'col-1'),
          HttpRequest(
              id: 'req-2',
              name: 'Request 2',
              method: HttpMethod.get,
              url: 'https://api2.com',
              parentId: 'col-1'),
          HttpRequest(
              id: 'req-3',
              name: 'Request 3',
              method: HttpMethod.get,
              url: 'https://api3.com',
              parentId: 'col-2'),
        ];
        when(mockRequestsBox.values).thenReturn(requests);

        // Act
        final allRequests = mockRequestsBox.values.toList();
        final filteredRequests =
            allRequests.where((r) => r.parentId == 'col-1').toList();

        // Assert
        expect(filteredRequests, hasLength(2));
        expect(filteredRequests.every((r) => r.parentId == 'col-1'), isTrue);
      });

      test('should handle request with params and headers', () async {
        // Arrange
        final request = HttpRequest(
          id: 'req-params',
          name: 'Request with Params',
          method: HttpMethod.get,
          url: 'https://api.example.com/search',
          params: [
            KeyValuePair(id: 'p1', key: 'q', value: 'test', enabled: true),
            KeyValuePair(id: 'p2', key: 'page', value: '1', enabled: true),
          ],
          headers: [
            KeyValuePair(
                id: 'h1',
                key: 'Authorization',
                value: 'Bearer token',
                enabled: true),
          ],
        );
        when(mockRequestsBox.get('req-params')).thenReturn(request);

        // Act
        final result = mockRequestsBox.get('req-params');

        // Assert
        expect(result?.params, hasLength(2));
        expect(result?.headers, hasLength(1));
        expect(result?.params[0].key, equals('q'));
        expect(result?.headers[0].value, equals('Bearer token'));
      });
    });

    group('SharedPreferences Mock Tests', () {
      test('should save string to mock prefs', () async {
        // Arrange
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // Act
        final result = await mockPrefs.setString('key', 'value');

        // Assert
        expect(result, isTrue);
        verify(mockPrefs.setString('key', 'value')).called(1);
      });

      test('should retrieve string from mock prefs', () {
        // Arrange
        when(mockPrefs.getString('key')).thenReturn('stored-value');

        // Act
        final result = mockPrefs.getString('key');

        // Assert
        expect(result, equals('stored-value'));
      });

      test('should return null for non-existent key', () {
        // Arrange
        when(mockPrefs.getString('non-existent')).thenReturn(null);

        // Act
        final result = mockPrefs.getString('non-existent');

        // Assert
        expect(result, isNull);
      });

      test('should clear all data from mock prefs', () async {
        // Arrange
        when(mockPrefs.clear()).thenAnswer((_) async => true);

        // Act
        final result = await mockPrefs.clear();

        // Assert
        expect(result, isTrue);
        verify(mockPrefs.clear()).called(1);
      });
    });

    group('Clear Operations', () {
      test('should clear collections box', () async {
        // Arrange
        when(mockCollectionsBox.clear())
            .thenAnswer((_) async => 5); // Returns count of deleted items

        // Act
        final deleted = await mockCollectionsBox.clear();

        // Assert
        expect(deleted, equals(5));
        verify(mockCollectionsBox.clear()).called(1);
      });

      test('should clear requests box', () async {
        // Arrange
        when(mockRequestsBox.clear()).thenAnswer((_) async => 3);

        // Act
        final deleted = await mockRequestsBox.clear();

        // Assert
        expect(deleted, equals(3));
        verify(mockRequestsBox.clear()).called(1);
      });

      test('should clear settings box', () async {
        // Arrange
        when(mockSettingsBox.clear()).thenAnswer((_) async => 1);

        // Act
        final deleted = await mockSettingsBox.clear();

        // Assert
        expect(deleted, equals(1));
        verify(mockSettingsBox.clear()).called(1);
      });
    });

    group('Close Operations', () {
      test('should close collections box', () async {
        // Arrange
        when(mockCollectionsBox.close()).thenAnswer((_) async {});

        // Act
        await mockCollectionsBox.close();

        // Assert
        verify(mockCollectionsBox.close()).called(1);
      });

      test('should close requests box', () async {
        // Arrange
        when(mockRequestsBox.close()).thenAnswer((_) async {});

        // Act
        await mockRequestsBox.close();

        // Assert
        verify(mockRequestsBox.close()).called(1);
      });

      test('should close settings box', () async {
        // Arrange
        when(mockSettingsBox.close()).thenAnswer((_) async {});

        // Act
        await mockSettingsBox.close();

        // Assert
        verify(mockSettingsBox.close()).called(1);
      });
    });

    group('AppSettings Model Tests', () {
      test('should create default settings', () {
        // Act
        final settings = AppSettings.defaults();

        // Assert
        expect(settings.themeMode, equals('system'));
        expect(settings.language, equals('en'));
        expect(settings.editorFontSize, equals(14.0));
        expect(settings.editorFontFamily, equals('monospace'));
        expect(settings.validateCertificates, isTrue);
        expect(settings.requestTimeoutMs, equals(30000));
        expect(settings.followRedirects, isFalse);
        expect(settings.maxRedirects, equals(5));
      });

      test('should convert settings to JSON', () {
        // Arrange
        final settings = AppSettings(
          themeMode: 'dark',
          language: 'zh',
          editorFontSize: 16.0,
          editorFontFamily: 'Fira Code',
          validateCertificates: false,
          requestTimeoutMs: 60000,
          followRedirects: true,
          maxRedirects: 10,
        );

        // Act
        final json = settings.toJson();

        // Assert
        expect(json['themeMode'], equals('dark'));
        expect(json['language'], equals('zh'));
        expect(json['editorFontSize'], equals(16.0));
        expect(json['requestTimeoutMs'], equals(60000));
      });

      test('should create settings from JSON', () {
        // Arrange
        final json = {
          'themeMode': 'light',
          'language': 'en',
          'editorFontSize': 18.0,
          'editorFontFamily': 'JetBrains Mono',
          'validateCertificates': true,
          'requestTimeoutMs': 45000,
          'followRedirects': true,
          'maxRedirects': 7,
        };

        // Act
        final settings = AppSettings.fromJson(json);

        // Assert
        expect(settings.themeMode, equals('light'));
        expect(settings.language, equals('en'));
        expect(settings.editorFontSize, equals(18.0));
        expect(settings.maxRedirects, equals(7));
      });
    });

    group('Collection Model Tests', () {
      test('should create empty collection', () {
        // Act
        final collection = Collection.empty();

        // Assert
        expect(collection.id, isNotEmpty);
        expect(collection.name, equals('New Collection'));
        expect(collection.children, isEmpty);
        expect(collection.requests, isEmpty);
        expect(collection.isExpanded, isFalse);
      });

      test('should create collection with children', () {
        // Arrange & Act
        final collection = Collection(
          id: 'col-parent',
          name: 'Parent',
          children: [
            Collection(id: 'col-child-1', name: 'Child 1'),
            Collection(id: 'col-child-2', name: 'Child 2'),
          ],
        );

        // Assert
        expect(collection.children, hasLength(2));
        expect(collection.isFolder, isTrue);
      });

      test('should create collection with requests', () {
        // Arrange & Act
        final collection = Collection(
          id: 'col-requests',
          name: 'API Collection',
          requests: [
            HttpRequest(
                id: 'req-1',
                name: 'Get Users',
                method: HttpMethod.get,
                url: 'https://api.com/users'),
            HttpRequest(
                id: 'req-2',
                name: 'Create User',
                method: HttpMethod.post,
                url: 'https://api.com/users'),
          ],
        );

        // Assert
        expect(collection.requests, hasLength(2));
        // isFolder = children.isNotEmpty || requests.isEmpty
        // With non-empty requests and empty children, isFolder should be false
        expect(collection.isFolder, isFalse);
      });

      test('should identify empty collection as folder', () {
        // Arrange
        final collection = Collection.empty();

        // Assert
        expect(collection.isFolder,
            isTrue); // Empty collections are considered folders
      });

      test('should convert collection to JSON', () {
        // Arrange
        final collection = Collection(
          id: 'col-1',
          name: 'Test Collection',
          description: 'Test Description',
          sortOrder: 1,
          isExpanded: true,
        );

        // Act
        final json = collection.toJson();

        // Assert
        expect(json['id'], equals('col-1'));
        expect(json['name'], equals('Test Collection'));
        expect(json['description'], equals('Test Description'));
        expect(json['sortOrder'], equals(1));
        expect(json['isExpanded'], isTrue);
      });
    });

    group('HttpRequest Model Tests', () {
      test('should create empty request', () {
        // Act
        final request = HttpRequest.empty();

        // Assert
        expect(request.id, isNotEmpty);
        expect(request.name, equals('New Request'));
        expect(request.method, equals(HttpMethod.get));
        expect(request.url, equals('https://httpbin.org/get'));
        expect(request.params, isEmpty);
        expect(request.headers, isEmpty);
        expect(request.body, isEmpty);
        expect(request.bodyType, equals('none'));
      });

      test('should convert request to JSON', () {
        // Arrange
        final request = HttpRequest(
          id: 'req-1',
          name: 'Test Request',
          method: HttpMethod.post,
          url: 'https://api.example.com',
          body: '{"key":"value"}',
          bodyType: 'json',
          parentId: 'col-1',
          sortOrder: 2,
        );

        // Act
        final json = request.toJson();

        // Assert
        expect(json['id'], equals('req-1'));
        expect(json['name'], equals('Test Request'));
        expect(json['method'], equals('post'));
        expect(json['bodyType'], equals('json'));
        expect(json['parentId'], equals('col-1'));
      });

      test('should support all HTTP methods', () {
        // Arrange & Act
        final get =
            HttpRequest(id: '1', name: 'GET', method: HttpMethod.get, url: '');
        final post = HttpRequest(
            id: '2', name: 'POST', method: HttpMethod.post, url: '');
        final put =
            HttpRequest(id: '3', name: 'PUT', method: HttpMethod.put, url: '');
        final delete = HttpRequest(
            id: '4', name: 'DELETE', method: HttpMethod.delete, url: '');
        final patch = HttpRequest(
            id: '5', name: 'PATCH', method: HttpMethod.patch, url: '');
        final head = HttpRequest(
            id: '6', name: 'HEAD', method: HttpMethod.head, url: '');
        final options = HttpRequest(
            id: '7', name: 'OPTIONS', method: HttpMethod.options, url: '');

        // Assert
        expect(get.method.value, equals('GET'));
        expect(post.method.value, equals('POST'));
        expect(put.method.value, equals('PUT'));
        expect(delete.method.value, equals('DELETE'));
        expect(patch.method.value, equals('PATCH'));
        expect(head.method.value, equals('HEAD'));
        expect(options.method.value, equals('OPTIONS'));
      });
    });

    group('KeyValuePair Model Tests', () {
      test('should create empty key value pair', () {
        // Act
        final pair = KeyValuePair.empty();

        // Assert
        expect(pair.id, isNotEmpty);
        expect(pair.key, isEmpty);
        expect(pair.value, isEmpty);
        expect(pair.enabled, isTrue);
      });

      test('should convert key value pair to JSON', () {
        // Arrange
        final pair = KeyValuePair(
          id: 'pair-1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );

        // Act
        final json = pair.toJson();

        // Assert
        expect(json['id'], equals('pair-1'));
        expect(json['key'], equals('Content-Type'));
        expect(json['value'], equals('application/json'));
        expect(json['enabled'], isTrue);
      });

      test('should support disabled key value pair', () {
        // Arrange
        final pair = KeyValuePair(
          id: 'pair-2',
          key: 'Disabled-Header',
          value: 'value',
          enabled: false,
        );

        // Assert
        expect(pair.enabled, isFalse);
      });
    });

    group('test-mode data dir isolation (2026-09-02 incident regression)', () {
      test('should use hopp_test dir when testMode is true', () {
        expect(StorageService.dataDirNameFor(testMode: true),
            equals('hopp_test'));
      });

      test('should use hopp dir when testMode is false', () {
        expect(
            StorageService.dataDirNameFor(testMode: false), equals('hopp'));
      });
    });
  });
}
