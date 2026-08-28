import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/import_export/openapi_import_provider.dart';
import 'package:hopp/widgets/import_export/import_dialog.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/service_mocks.mocks.dart';

/// OpenAPI 导入面板 widget 测试
///
/// 通过 MockStorageService 驱动真实 OpenApiImportService（覆盖解析 →
/// 预览 → 导入全链路），验证四屏流转与勾选统计联动。
void main() {
  // 2 个 op：1 个带 tag（pet）、1 个无 tag
  const specJson = '''
{
  "openapi": "3.0.0",
  "info": {"title": "Test API", "version": "1.0.0"},
  "servers": [{"url": "https://api.example.com"}],
  "paths": {
    "/pets": {
      "get": {
        "tags": ["pet"],
        "summary": "List pets",
        "responses": {}
      }
    },
    "/pets/{petId}": {
      "get": {
        "summary": "Get pet",
        "parameters": [
          {"name": "petId", "in": "path", "required": true, "schema": {"type": "string"}}
        ],
        "responses": {}
      }
    }
  }
}
''';

  late MockStorageService mockStorage;

  setUp(() {
    mockStorage = MockStorageService();
    when(mockStorage.getCollections()).thenAnswer((_) async => []);
    when(mockStorage.saveCollection(any)).thenAnswer((_) async {});
    when(mockStorage.saveRequest(any)).thenAnswer((_) async {});
    when(mockStorage.getGlobalVariables()).thenAnswer((_) async => []);
    when(mockStorage.saveGlobalVariables(any)).thenAnswer((_) async {});
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorage),
      ],
    );
  }

  Widget buildTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: ImportDialog(initialFormat: ImportFormat.openApi),
        ),
      ),
    );
  }

  Future<void> toPreview(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await container
        .read(openApiImportProvider.notifier)
        .parseContent(specJson, sourceLabel: 'test.json');
    await tester.pumpAndSettle();
  }

  group('OpenApiImportPanel', () {
    testWidgets('idle 态渲染文件拖放区与 URL 输入', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();

      expect(find.text('Or import from URL'), findsOneWidget);
      expect(find.text('Select File'), findsOneWidget);
      expect(find.text('Parse'), findsOneWidget);
      expect(find.text('Spec URL'), findsOneWidget);
    });

    testWidgets('解析后渲染预览：spec 信息条、分组、底部统计', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();
      await toPreview(tester, container);

      // spec 信息条（Text.rich 需 findRichText）
      expect(
        find.textContaining('Test API', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('1 tags · 2 operations', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('https://api.example.com', findRichText: true),
        findsOneWidget,
      );

      // 分组与接口行
      expect(find.text('pet'), findsOneWidget);
      expect(find.text('No tag'), findsOneWidget);
      expect(find.text('/pets'), findsOneWidget);
      expect(find.text('/pets/{petId}'), findsOneWidget);

      // 底部统计与导入按钮
      expect(
        find.text('Selected 2 / 2 · 1 collection + 1 sub-collections'),
        findsOneWidget,
      );
      expect(find.text('Import 2 requests'), findsOneWidget);
    });

    testWidgets('勾选切换联动统计与子集合计数', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();
      await toPreview(tester, container);

      // 取消勾选带 tag 的 op → 子集合计数从 1 变 0
      container.read(openApiImportProvider.notifier).toggleOp('get /pets');
      await tester.pump();

      expect(
        find.text('Selected 1 / 2 · 1 collection + 0 sub-collections'),
        findsOneWidget,
      );
      expect(find.text('Import 1 request'), findsOneWidget);
      // pet 组头显示 0/1
      expect(find.text('0/1'), findsOneWidget);

      // 全选恢复
      container.read(openApiImportProvider.notifier).selectAll(true);
      await tester.pump();
      expect(
        find.text('Selected 2 / 2 · 1 collection + 1 sub-collections'),
        findsOneWidget,
      );
    });

    testWidgets('导入成功渲染结果报告', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();
      await toPreview(tester, container);

      await tester.tap(find.text('Import 2 requests'));
      await tester.pumpAndSettle();

      // 统计卡
      expect(find.text('Requests imported'), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);
      expect(find.text('Placeholders'), findsOneWidget);
      // 占位清单（petId path 变量留空）
      expect(find.text('pathVars'), findsOneWidget);
      // 动作按钮
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Open collection'), findsOneWidget);

      // 落盘：1 根集合 + 1 子集合 + 2 请求；baseUrl 全局变量写入
      verify(mockStorage.saveCollection(any)).called(2);
      verify(mockStorage.saveRequest(any)).called(2);
      verify(mockStorage.saveGlobalVariables(any)).called(1);
    });
  });
}
