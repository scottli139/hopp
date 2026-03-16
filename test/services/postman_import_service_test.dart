import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/services/import_export/import_export_exception.dart';
import 'package:hopp/services/import_export/postman_import_service.dart';
import 'package:hopp/services/import_export/postman_mapper.dart';
import 'package:hopp/services/import_export/postman_schema.dart';
import 'package:hopp/services/storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'postman_import_service_test.mocks.dart';

@GenerateMocks([StorageService])
void main() {
  group('PostmanImportService', () {
    late PostmanImportService service;
    late MockStorageService mockStorage;

    setUp(() {
      mockStorage = MockStorageService();
      service = PostmanImportService(mockStorage);
    });

    group('importCollection', () {
      test('should import v2.1 collection successfully', () async {
        // Arrange
        final json = jsonEncode({
          'info': {
            '_postman_id': 'test-id',
            'name': 'Test Collection',
            'schema':
                'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
          },
          'item': [
            {
              'name': 'GET Request',
              'request': {
                'method': 'GET',
                'header': [],
                'url': {
                  'raw': 'https://example.com/api',
                  'protocol': 'https',
                  'host': ['example', 'com'],
                  'path': ['api'],
                },
              },
            },
          ],
        });

        when(mockStorage.getCollections()).thenAnswer((_) async => []);
        when(mockStorage.saveCollection(any)).thenAnswer((_) async {});
        when(mockStorage.saveRequest(any)).thenAnswer((_) async {});

        // Act
        final result = await service.importCollection(json);

        // Assert
        expect(result.success, true);
        expect(result.importedRequestCount, 1);
        expect(result.renamed, false);
        verify(mockStorage.saveCollection(any)).called(greaterThanOrEqualTo(1));
      });

      test('should throw error for v1.0 collection', () async {
        // Arrange - v1.0 is not supported
        final json = jsonEncode({
          'info': {
            '_postman_id': 'test-id',
            'name': 'Test Collection',
            'schema': 'https://schema.getpostman.com/json/collection/v1.0.0/',
          },
          'item': [
            {
              'name': 'Request',
              'request': {
                'method': 'GET',
                'header': [],
                'url': {
                  'raw': 'https://example.com',
                  'protocol': 'https',
                  'host': ['example', 'com'],
                  'path': [],
                },
              },
            },
          ],
        });

        // Arrange - stub getCollections
        when(mockStorage.getCollections()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => service.importCollection(json),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              ImportErrorCode.unsupportedVersion,
            ),
          ),
        );
      });

      test('should throw error for empty collection', () async {
        // Arrange
        final json = jsonEncode({
          'info': {
            '_postman_id': 'test-id',
            'name': 'Empty Collection',
            'schema':
                'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
          },
          'item': [],
        });

        // Act & Assert
        expect(
          () => service.importCollection(json),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              ImportErrorCode.emptyCollection,
            ),
          ),
        );
      });

      test('should return conflict for existing collection', () async {
        // Arrange
        final json = jsonEncode({
          'info': {
            '_postman_id': 'test-id',
            'name': 'Existing Collection',
            'schema':
                'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
          },
          'item': [
            {
              'name': 'Request',
              'request': {
                'method': 'GET',
                'header': [],
                'url': {
                  'raw': 'https://example.com',
                  'protocol': 'https',
                  'host': ['example', 'com'],
                  'path': [],
                },
              },
            },
          ],
        });

        // Arrange - stub getCollections to return existing collection
        final existingCollection = Collection(
          id: 'existing-id',
          name: 'Existing Collection',
          requests: [],
        );
        when(mockStorage.getCollections())
            .thenAnswer((_) async => [existingCollection]);

        // Act
        final result = await service.importCollection(json);

        // Assert
        expect(result.success, false);
        expect(result.conflictCollection, isNotNull);
        expect(result.existingId, 'existing-id');
      });
    });

    group('importEnvironment', () {
      test('should parse environment successfully', () async {
        // Arrange
        final json = jsonEncode({
          'id': 'env-id',
          'name': 'Test Environment',
          '_postman_variable_scope': 'environment',
          'values': [
            {
              'key': 'baseUrl',
              'value': 'https://api.example.com',
              'enabled': true,
              'type': 'default',
            },
          ],
        });

        // Act
        final result = await service.importEnvironment(json);

        // Assert
        expect(result.success, true);
        expect(result.importedRequestCount, 1);
      });
    });

    group('resolveConflict', () {
      test('should rename collection when rename strategy selected', () async {
        // Arrange
        final collection = PostmanMapper.toHoppCollection(
          const PostmanCollection(
            info: PostmanInfo(name: 'Test Collection'),
            item: [],
          ),
        );

        when(mockStorage.getCollections()).thenAnswer((_) async => []);
        when(mockStorage.saveCollection(any)).thenAnswer((_) async {});

        // Act
        final result = await service.resolveConflict(
          collection: collection,
          resolution: ConflictResolution.rename,
        );

        // Assert
        expect(result.success, true);
        expect(result.renamed, true);
        expect(result.newName, isNotNull);
      });

      test('should skip collection when skip strategy selected', () async {
        // Arrange
        final collection = PostmanMapper.toHoppCollection(
          const PostmanCollection(
            info: PostmanInfo(name: 'Test Collection'),
            item: [],
          ),
        );

        // Act
        final result = await service.resolveConflict(
          collection: collection,
          resolution: ConflictResolution.skip,
        );

        // Assert
        expect(result.success, false);
        expect(result.skipped, true);
        verifyNever(mockStorage.saveCollection(any));
      });
    });
  });
}
