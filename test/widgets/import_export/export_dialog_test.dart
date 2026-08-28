import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/import_export/import_export_provider.dart';
import 'package:hopp/widgets/common/app_button.dart';
import 'package:hopp/widgets/import_export/export_dialog.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/service_mocks.mocks.dart';

/// 伪 FilePicker：saveFile 直接返回预定路径（file_picker 10.x 需注入实例，
/// 仅 mock method channel 会触发 LateInitializationError）
class _FakeFilePicker extends fp.FilePicker {
  _FakeFilePicker(this.savePath);

  final String savePath;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    fp.FileType type = fp.FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    expect(fileName, 'HaiShen.hopp.json');
    return savePath;
  }
}

/// Export 对话框 widget 测试（F4.4 格式选项）
///
/// - FORMAT 区两个 radio 卡片 + secret 提示条
/// - 格式切换：Postman 显示 Format Version，Hopp CLI 隐藏
/// - Hopp CLI 导出：mock file_picker 保存路径，验证写出的 .hopp.json
///   形状与 secret 置空
void main() {
  late MockStorageService mockStorage;
  late Directory tempDir;

  const root = Collection(id: 'col-1', name: 'HaiShen');

  const request = HttpRequest(
    id: 'req-1',
    name: 'Login',
    method: HttpMethod.post,
    url: '{{host}}/login',
    parentId: 'col-1',
  );

  const staging = Environment(
    id: 'env-1',
    name: 'staging',
    variables: [
      EnvironmentVariable(
        id: 'v1',
        key: 'password',
        value: 'top-secret',
        type: VariableType.secret,
      ),
      EnvironmentVariable(id: 'v2', key: 'host', value: 'http://localhost'),
    ],
  );

  setUp(() {
    mockStorage = MockStorageService();
    tempDir = Directory.systemTemp.createTempSync('hopp_export_dialog_');
    when(mockStorage.getCollections()).thenAnswer((_) async => [root]);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorage),
      ],
    );
  }

  Future<void> pumpDialog(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ExportDialog(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ExportDialog FORMAT 区', () {
    testWidgets('展示两个格式选项与 secret 提示条', (tester) async {
      final container = buildContainer();
      await pumpDialog(tester, container);

      expect(find.text('FORMAT'), findsOneWidget);
      expect(find.textContaining('Postman Collection'), findsOneWidget);
      expect(find.textContaining('Hopp CLI'), findsOneWidget);
      expect(
        find.textContaining('Secret variable values are exported empty'),
        findsOneWidget,
      );
      expect(find.textContaining('--env-var KEY=VALUE'), findsOneWidget);
    });

    testWidgets('默认 Postman 选中显示 Format Version；切到 Hopp CLI 后隐藏',
        (tester) async {
      final container = buildContainer();
      await pumpDialog(tester, container);

      // 默认 Postman：Format Version 可见
      expect(find.text('Format Version'), findsOneWidget);

      // 切到 Hopp CLI
      await tester.tap(find.textContaining('Hopp CLI'));
      await tester.pumpAndSettle();
      expect(find.text('Format Version'), findsNothing);
      // Prettify 对两种格式都保留
      expect(find.text('Prettify JSON Output'), findsOneWidget);

      // 切回 Postman 恢复显示
      await tester.tap(find.textContaining('Postman Collection'));
      await tester.pumpAndSettle();
      expect(find.text('Format Version'), findsOneWidget);
    });
  });

  group('ExportDialog Hopp CLI 导出', () {
    testWidgets('选中集合 + Hopp CLI 导出分发正确（进入导出中状态）', (tester) async {
      when(mockStorage.getRequests()).thenAnswer((_) async => [request]);
      when(mockStorage.getEnvironments()).thenAnswer((_) async => [staging]);
      when(mockStorage.getGlobalVariables()).thenAnswer((_) async => []);
      when(mockStorage.getActiveEnvironmentId())
          .thenAnswer((_) async => 'env-1');

      final savePath = '${tempDir.path}/HaiShen.hopp.json';
      fp.FilePicker.platform = _FakeFilePicker(savePath);

      final container = buildContainer();
      await pumpDialog(tester, container);

      // 选择集合（触发器 hint 与区块标签同名，取最后一个）
      await tester.tap(find.text('Select Collection').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('HaiShen').last);
      await tester.pumpAndSettle();
      expect(find.text('HaiShen'), findsWidgets);

      // 选择 Hopp CLI 格式
      await tester.tap(find.textContaining('Hopp CLI'));
      await tester.pumpAndSettle();

      // 点击 Export：notifier 同步置 loading 态（真实文件 IO 不会在这一帧
      // 内完成，因此 loading 态的出现是确定性的，不依赖 FakeAsync 下的
      // dart:io 完成时序）
      await tester.tap(find.widgetWithText(AppButton, 'Export'));
      await tester.pump();

      expect(find.text('Exporting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Hopp CLI 导出内容（notifier 级，纯异步）', () {
    test('exportCollectionForCli 写出 .hopp.json（secret 置空）', () async {
      when(mockStorage.getRequests()).thenAnswer((_) async => [request]);
      when(mockStorage.getEnvironments()).thenAnswer((_) async => [staging]);
      when(mockStorage.getGlobalVariables()).thenAnswer(
        (_) async => [
          const EnvironmentVariable(
            id: 'g1',
            key: 'app_secret',
            value: 'global-secret',
            type: VariableType.secret,
          ),
        ],
      );
      when(mockStorage.getActiveEnvironmentId()).thenAnswer(
        (_) async => 'env-1',
      );

      final container = buildContainer();
      addTearDown(container.dispose);

      final savePath = '${tempDir.path}/HaiShen.hopp.json';
      await container
          .read(importExportProvider.notifier)
          .exportCollectionForCli(
            collectionId: 'col-1',
            savePath: savePath,
          );

      final state = container.read(importExportProvider);
      expect(state.exportPath, savePath);
      expect(state.error, isNull);

      // 校验写出的文件
      final file = File(savePath);
      expect(file.existsSync(), isTrue);
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(json['format'], 'hopp-cli');
      expect(json['version'], 1);
      expect(json['activeEnvironmentId'], 'env-1');
      expect((json['collection'] as Map)['name'], 'HaiShen');
      expect((json['requests'] as List).single['name'], 'Login');

      // secret 置空 / 普通变量保留
      final envVars = ((json['environments'] as List).single
          as Map<String, dynamic>)['variables'] as List;
      final password = envVars.firstWhere(
        (v) => (v as Map)['key'] == 'password',
      ) as Map<String, dynamic>;
      expect(password['value'], '');
      final host = envVars.firstWhere((v) => (v as Map)['key'] == 'host')
          as Map<String, dynamic>;
      expect(host['value'], 'http://localhost');

      final globals = (json['globals'] as List).single as Map<String, dynamic>;
      expect(globals['value'], '');
    });
  });
}
