import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/services/import_export/import_export_exception.dart';
import 'package:hopp/services/import_export/openapi/openapi_import_service.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/service_mocks.mocks.dart';

void main() {
  group('OpenApiImportService', () {
    late MockStorageService storage;
    late OpenApiImportService service;

    final petstoreJson =
        File('test/fixtures/openapi/petstore3.json').readAsStringSync();

    setUp(() {
      storage = MockStorageService();
      service = OpenApiImportService(storage);
    });

    void stubSavePaths() {
      when(storage.getCollections()).thenAnswer((_) async => []);
      when(storage.saveCollection(any)).thenAnswer((_) async {});
      when(storage.saveRequest(any)).thenAnswer((_) async {});
      when(storage.getGlobalVariables()).thenAnswer((_) async => []);
      when(storage.saveGlobalVariables(any)).thenAnswer((_) async {});
    }

    group('importSpec(content:)', () {
      test('成功：保存集合与请求，upsert baseUrl 全局变量', () async {
        stubSavePaths();

        final outcome = await service.importSpec(content: petstoreJson);

        expect(outcome.status, OpenApiImportStatus.success);
        final report = outcome.report!;
        expect(report.collectionName, 'Swagger Petstore');
        expect(report.requestCount, 8);
        expect(report.collectionCount, 3);
        expect(report.renamed, false);
        expect(report.merged, false);
        expect(report.baseUrl, 'https://petstore3.swagger.io/api/v3');
        expect(report.baseUrlExisted, false);
        expect(report.authDescription, contains('api_key'));
        expect(report.oauthNotices, contains('petstore_auth'));
        expect(report.placeholders, isNotEmpty);

        // 1 根集合 + 3 子集合
        verify(storage.saveCollection(any)).called(4);
        verify(storage.saveRequest(any)).called(8);

        final captured =
            verify(storage.saveGlobalVariables(captureAny)).captured;
        final variables = captured.last as List<EnvironmentVariable>;
        expect(variables.single.key, 'baseUrl');
        expect(variables.single.value, 'https://petstore3.swagger.io/api/v3');
        expect(variables.single.type, VariableType.string);
        expect(variables.single.enabled, true);
      });

      test('selectedOpIds 过滤后保存', () async {
        stubSavePaths();

        final outcome = await service.importSpec(
          content: petstoreJson,
          selectedOpIds: {'post /pet', 'get /misc/ping'},
        );

        expect(outcome.status, OpenApiImportStatus.success);
        expect(outcome.report!.requestCount, 2);
        expect(outcome.report!.collectionCount, 1);
        verify(storage.saveCollection(any)).called(2);
        verify(storage.saveRequest(any)).called(2);
      });

      test('空 operations 抛 emptyCollection', () {
        final empty = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'Empty'},
          'paths': <String, dynamic>{},
        });

        expect(
          () => service.importSpec(content: empty),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              ImportErrorCode.emptyCollection,
            ),
          ),
        );
      });

      test('未提供来源抛 unknownFormat', () {
        expect(
          () => service.importSpec(),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              ImportErrorCode.unknownFormat,
            ),
          ),
        );
      });
    });

    group('importSpec(filePath:)', () {
      test('读取 YAML 文件并成功导入', () async {
        stubSavePaths();

        final outcome = await service.importSpec(
          filePath: 'test/fixtures/openapi/petstore3_min.yaml',
        );

        expect(outcome.status, OpenApiImportStatus.success);
        expect(outcome.report!.collectionName, 'Mini Petstore YAML');
        expect(outcome.report!.requestCount, 3);
      });

      test('文件不存在抛 fileNotFound', () {
        expect(
          () => service.importSpec(filePath: 'test/fixtures/openapi/nope.json'),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              ImportErrorCode.fileNotFound,
            ),
          ),
        );
      });
    });

    group('冲突与解决', () {
      test('同名集合已存在 → status=conflict，不写入存储', () async {
        const existing =
            Collection(id: 'existing-id', name: 'Swagger Petstore');
        when(storage.getCollections()).thenAnswer((_) async => [existing]);

        final outcome = await service.importSpec(content: petstoreJson);

        expect(outcome.status, OpenApiImportStatus.conflict);
        expect(outcome.existingId, 'existing-id');
        expect(outcome.conflictCollection!.name, 'Swagger Petstore');
        expect(outcome.childCollections!.length, 3);
        expect(outcome.allRequests!.length, 8);
        // conflict 时 report 预填数据，供 resolveConflict 回传
        expect(outcome.report!.baseUrl, 'https://petstore3.swagger.io/api/v3');
        expect(outcome.report!.placeholders, isNotEmpty);

        verifyNever(storage.saveCollection(any));
        verifyNever(storage.saveRequest(any));
        verifyNever(storage.saveGlobalVariables(any));
      });

      test('resolveConflict(rename)：重命名导入，二次 upsert baseUrlExisted=true',
          () async {
        const existing =
            Collection(id: 'existing-id', name: 'Swagger Petstore');
        when(storage.getCollections()).thenAnswer((_) async => [existing]);

        // 第一次导入 → 冲突
        final outcome = await service.importSpec(content: petstoreJson);
        expect(outcome.status, OpenApiImportStatus.conflict);

        // 模拟 baseUrl 已存在（如首次成功导入时写入）
        when(storage.saveCollection(any)).thenAnswer((_) async {});
        when(storage.saveRequest(any)).thenAnswer((_) async {});
        when(storage.getGlobalVariables()).thenAnswer(
          (_) async => [
            const EnvironmentVariable(
              id: 'g1',
              key: 'baseUrl',
              value: 'https://old.example.com',
            ),
          ],
        );
        when(storage.saveGlobalVariables(any)).thenAnswer((_) async {});

        final report0 = outcome.report!;
        final resolved = await service.resolveConflict(
          resolution: ConflictResolution.rename,
          collection: outcome.conflictCollection!,
          existingId: outcome.existingId,
          childCollections: outcome.childCollections,
          allRequests: outcome.allRequests,
          baseUrl: report0.baseUrl,
          placeholders: report0.placeholders,
          oauthNotices: report0.oauthNotices,
          authDescription: report0.authDescription,
        );

        expect(resolved.status, OpenApiImportStatus.success);
        final report = resolved.report!;
        expect(report.renamed, true);
        expect(report.newName, 'Swagger Petstore (1)');
        expect(report.collectionName, 'Swagger Petstore (1)');
        expect(report.requestCount, 8);
        expect(report.collectionCount, 3);
        expect(report.baseUrl, 'https://petstore3.swagger.io/api/v3');
        expect(report.baseUrlExisted, true);
        expect(report.placeholders, isNotEmpty);
        expect(report.oauthNotices, contains('petstore_auth'));

        // 根集合 + 3 子集合被保存
        verify(storage.saveCollection(any)).called(4);
        verify(storage.saveRequest(any)).called(8);

        // baseUrl 变量被更新（保留原 id）
        final captured =
            verify(storage.saveGlobalVariables(captureAny)).captured;
        final variables = captured.last as List<EnvironmentVariable>;
        expect(variables.single.id, 'g1');
        expect(variables.single.value, 'https://petstore3.swagger.io/api/v3');
      });

      test('resolveConflict(skip)：skipped 且不写存储', () async {
        const existing =
            Collection(id: 'existing-id', name: 'Swagger Petstore');
        when(storage.getCollections()).thenAnswer((_) async => [existing]);

        final outcome = await service.importSpec(content: petstoreJson);
        final resolved = await service.resolveConflict(
          resolution: ConflictResolution.skip,
          collection: outcome.conflictCollection!,
          existingId: outcome.existingId,
          childCollections: outcome.childCollections,
          allRequests: outcome.allRequests,
          baseUrl: outcome.report!.baseUrl,
        );

        expect(resolved.status, OpenApiImportStatus.skipped);
        expect(resolved.report, isNull);
        verifyNever(storage.saveCollection(any));
        verifyNever(storage.saveRequest(any));
        verifyNever(storage.saveGlobalVariables(any));
      });
    });

    group('readFile', () {
      test('读取存在的文件', () async {
        final content =
            await service.readFile('test/fixtures/openapi/petstore3_min.yaml');
        expect(content, contains('Mini Petstore YAML'));
      });
    });
  });
}
