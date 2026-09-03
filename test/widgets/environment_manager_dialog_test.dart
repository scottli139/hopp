import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/widgets/common/app_text_field.dart';
import 'package:hopp/widgets/environment/environment_manager_dialog.dart';
import 'package:mockito/mockito.dart';

import '../helpers/test_app.dart';
import '../mocks/service_mocks.mocks.dart';

void main() {
  const devEnv = Environment(
    id: 'env-dev',
    name: 'Development',
    variables: [
      EnvironmentVariable(id: 'v1', key: 'host', value: 'dev.local'),
    ],
  );

  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
    when(mockStorageService.getEnvironments()).thenAnswer((_) async => []);
    when(mockStorageService.saveEnvironment(any)).thenAnswer((_) async {});
    when(mockStorageService.deleteEnvironment(any)).thenAnswer((_) async {});
    when(mockStorageService.getActiveEnvironmentId())
        .thenAnswer((_) async => null);
    when(mockStorageService.setActiveEnvironmentId(any))
        .thenAnswer((_) async {});
    when(mockStorageService.getGlobalVariables()).thenAnswer((_) async => []);
    when(mockStorageService.saveGlobalVariables(any)).thenAnswer((_) async {});
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorageService),
      ],
    );
  }

  Widget buildTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: hoppTestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showEnvironmentManagerDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('environment_manager_dialog')), findsOneWidget);
  }

  group('EnvironmentManagerDialog', () {
    testWidgets('should show existing environments in side panel',
        (tester) async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);

      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await openDialog(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('environment_entry_env-dev')),
          matching: find.text('Development'),
        ),
        findsOneWidget,
      );
      expect(find.text('Globals'), findsOneWidget);
      // 名称输入框显示选中环境的名称
      final nameField = tester
          .widget<TextField>(find.byKey(const Key('environment_name_field')));
      expect(nameField.controller?.text, 'Development');
    });

    testWidgets('should create new environment with variables and save',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await openDialog(tester);

      // 新建环境
      await tester.tap(find.byKey(const Key('new_environment_button')));
      await tester.pumpAndSettle();

      // 修改名称
      await tester.enterText(
        find.byKey(const Key('environment_name_field')),
        'Staging',
      );
      await tester.pumpAndSettle();

      // 添加变量并填写 key/value（TextField 顺序：名称、key、value）
      await tester.tap(find.byKey(const Key('add_variable_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'baseUrl');
      await tester.enterText(
        find.byType(TextField).at(2),
        'https://staging.example.com',
      );
      await tester.pumpAndSettle();

      // 保存
      await tester.tap(find.byKey(const Key('environment_dialog_save_button')));
      await tester.pumpAndSettle();

      final captured =
          verify(mockStorageService.saveEnvironment(captureAny)).captured;
      expect(captured, hasLength(1));

      final saved = captured.single as Environment;
      expect(saved.name, 'Staging');
      expect(saved.variables, hasLength(1));
      expect(saved.variables.single.key, 'baseUrl');
      expect(saved.variables.single.value, 'https://staging.example.com');

      // 对话框已关闭
      expect(find.byKey(const Key('environment_manager_dialog')), findsNothing);
    });

    testWidgets('should rename existing environment and save', (tester) async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);

      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await openDialog(tester);

      await tester.enterText(
        find.byKey(const Key('environment_name_field')),
        'Dev Renamed',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('environment_dialog_save_button')));
      await tester.pumpAndSettle();

      final captured =
          verify(mockStorageService.saveEnvironment(captureAny)).captured;
      final saved = captured.last as Environment;
      expect(saved.id, 'env-dev');
      expect(saved.name, 'Dev Renamed');
      // 原有变量保留
      expect(saved.variables.single.key, 'host');
    });

    testWidgets('should delete environment on save after removal',
        (tester) async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);

      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await openDialog(tester);

      await tester.tap(find.byKey(const Key('delete_environment_button')));
      await tester.pumpAndSettle();

      // 侧栏中环境已移除
      expect(find.text('Development'), findsNothing);

      await tester.tap(find.byKey(const Key('environment_dialog_save_button')));
      await tester.pumpAndSettle();

      verify(mockStorageService.deleteEnvironment('env-dev')).called(1);
      verifyNever(mockStorageService.saveEnvironment(any));
    });

    testWidgets('should edit globals and save', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await openDialog(tester);

      // 切到 Globals（无环境时默认已选中）
      await tester.tap(find.byKey(const Key('globals_entry')));
      await tester.pumpAndSettle();

      // 添加全局变量（Globals 空状态下的主按钮）
      await tester.tap(find.byKey(const Key('add_variable_button')));
      await tester.pumpAndSettle();

      // Globals 名称为只读标题，不占 TextField：key/value 为第 1/2 个输入框
      await tester.enterText(find.byType(TextField).at(0), 'sharedKey');
      await tester.enterText(find.byType(TextField).at(1), 'sharedValue');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('environment_dialog_save_button')));
      await tester.pumpAndSettle();

      final captured =
          verify(mockStorageService.saveGlobalVariables(captureAny)).captured;
      final saved = captured.last as List<EnvironmentVariable>;
      expect(saved, hasLength(1));
      expect(saved.single.key, 'sharedKey');
      expect(saved.single.value, 'sharedValue');
    });

    testWidgets('should cancel without persisting', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await openDialog(tester);

      await tester.tap(find.byKey(const Key('new_environment_button')));
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const Key('environment_dialog_cancel_button')));
      await tester.pumpAndSettle();

      verifyNever(mockStorageService.saveEnvironment(any));
      expect(find.byKey(const Key('environment_manager_dialog')), findsNothing);
    });

    /// 高度一致性回归（UI 审计发现）：
    /// 旧实现 InputDecorator 描边不随外层 SizedBox 撑开，导致同页输入框
    /// 出现 16/18/24/28 多种高度。新实现显式盒子，渲染盒 == 绘制盒。
    /// 重设计后规格：名称行内标题 32、行内单元格 28、类型徽章 24。
    testWidgets('variable row controls share uniform heights', (tester) async {
      const envWithSecret = Environment(
        id: 'env-sec',
        name: 'Secrets',
        variables: [
          EnvironmentVariable(id: 'v1', key: 'host', value: 'x'),
          EnvironmentVariable(
            id: 'v2',
            key: 'token',
            value: 'y',
            type: VariableType.secret,
          ),
        ],
      );
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [envWithSecret]);

      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await openDialog(tester);

      // 名称字段：行内标题规格 32
      final nameField = find.ancestor(
        of: find.byKey(const Key('environment_name_field')),
        matching: find.byType(AppTextField),
      );
      expect(tester.getSize(nameField).height, 32);

      // 行内 Key/Value 输入框统一 28（含 secret 带显隐按钮行）
      final rowFields = find.descendant(
        of: find.byKey(const Key('variable_row_v1')),
        matching: find.byType(AppTextField),
      );
      final secretRowFields = find.descendant(
        of: find.byKey(const Key('variable_row_v2')),
        matching: find.byType(AppTextField),
      );
      for (final f in [rowFields, secretRowFields]) {
        expect(f, findsNWidgets(2));
        for (final e in f.evaluate()) {
          expect(e.size!.height, 28, reason: 'row field must be 28pt');
        }
      }
      // 类型徽章选择器统一 24
      final pills = find.byType(TypePillSelect);
      expect(pills, findsNWidgets(2));
      for (final e in pills.evaluate()) {
        expect(e.size!.height, 24, reason: 'type pill must be 24pt');
      }
    });

    testWidgets('should mark the active environment with a dot',
        (tester) async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);
      when(mockStorageService.getActiveEnvironmentId())
          .thenAnswer((_) async => 'env-dev');

      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await openDialog(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('environment_entry_env-dev')),
          matching: find.byKey(const Key('active_env_dot')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should switch variable type via pill and save',
        (tester) async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);

      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await openDialog(tester);

      // 打开类型徽章菜单并选择 secret
      await tester.tap(find.byKey(const Key('variable_type_pill_v1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('secret').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('environment_dialog_save_button')));
      await tester.pumpAndSettle();

      final captured =
          verify(mockStorageService.saveEnvironment(captureAny)).captured;
      final saved = captured.last as Environment;
      expect(saved.variables.single.type, VariableType.secret);
    });
  });
}
