import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/services/import_export/postman_export_service.dart';
import 'package:mockito/mockito.dart';

import '../fixtures/request_fixtures.dart';
import '../mocks/service_mocks.mocks.dart';

void main() {
  group('PostmanExportService', () {
    late MockStorageService mockStorage;
    late PostmanExportService service;
    late Directory tempDir;

    setUp(() {
      mockStorage = MockStorageService();
      service = PostmanExportService(mockStorage);
      tempDir = Directory.systemTemp.createTempSync('hopp_export_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should export child collections and requests (flat storage)',
        () async {
      final root =
          Collection.empty().copyWith(id: 'root', name: 'Root');
      final child = Collection.empty()
          .copyWith(id: 'child', name: 'Child', parentId: 'root');
      final request =
          RequestFixtures.simpleGetRequest().copyWith(parentId: 'root');

      when(mockStorage.getCollection('root')).thenAnswer((_) async => root);
      when(mockStorage.getCollections())
          .thenAnswer((_) async => [root, child]);
      when(mockStorage.getRequests()).thenAnswer((_) async => [request]);

      final savePath = '${tempDir.path}/collection.json';
      await service.exportCollection(
        collectionId: 'root',
        savePath: savePath,
      );

      final content = await File(savePath).readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final items = json['item'] as List<dynamic>;

      // 根集合下应有 1 个文件夹 + 1 个请求
      expect(items, hasLength(2));
      expect(jsonEncode(items), contains('Child'));
      expect(jsonEncode(items), contains('Test GET Request'));
    });
  });
}
