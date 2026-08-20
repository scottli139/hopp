import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/import_export/import_export_provider.dart';
import 'package:hopp/services/import_export/import_export_exception.dart';
import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('ImportExportNotifier conflict resolution', () {
    late MockStorageService mockStorage;
    late ProviderContainer container;
    late Directory tempDir;

    setUp(() {
      mockStorage = MockStorageService();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
      );
      tempDir = Directory.systemTemp.createTempSync('hopp_import_test_');
    });

    tearDown(() {
      container.dispose();
      tempDir.deleteSync(recursive: true);
    });

    test('resolving a conflict preserves child collections and requests',
        () async {
      // 已存在同名集合，用于触发冲突
      final existing =
          Collection.empty().copyWith(id: 'existing-id', name: 'Imported');
      when(mockStorage.getCollections()).thenAnswer((_) async => [existing]);

      final json = jsonEncode({
        'info': {
          'name': 'Imported',
          'schema':
              'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        },
        'item': [
          {
            'name': 'Sub Folder',
            'item': [
              {
                'name': 'GET Request',
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
          },
        ],
      });
      final file = File('${tempDir.path}/collection.json');
      file.writeAsStringSync(json);

      when(mockStorage.getRequests()).thenAnswer((_) async => []);
      when(mockStorage.saveCollection(any)).thenAnswer((_) async {});
      when(mockStorage.saveRequest(any)).thenAnswer((_) async {});
      when(mockStorage.deleteCollection(any)).thenAnswer((_) async {});

      await container
          .read(importExportProvider.notifier)
          .importFile(file.path);

      // 应检测到冲突
      expect(container.read(importExportProvider).conflict, isNotNull);

      await container
          .read(importExportProvider.notifier)
          .resolveConflict(ConflictResolution.overwrite);

      // 覆盖后应保存根集合 + 子集合，以及请求
      verify(mockStorage.saveCollection(any)).called(2);
      verify(mockStorage.saveRequest(any)).called(1);
    });
  });
}
