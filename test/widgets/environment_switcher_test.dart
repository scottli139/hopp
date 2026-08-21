import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/request/request_tab_provider.dart';
import 'package:hopp/widgets/environment/environment_switcher.dart';
import 'package:mockito/mockito.dart';

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
      child: const MaterialApp(
        home: Scaffold(body: EnvironmentSwitcher()),
      ),
    );
  }

  group('EnvironmentSwitcher', () {
    testWidgets('should show No Environment hint when nothing active',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();

      expect(find.text('No Environment'), findsOneWidget);
      expect(
          find.byKey(const Key('manage_environments_button')), findsOneWidget);
    });

    testWidgets('should list environments in dropdown and activate selection',
        (tester) async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);

      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();

      // 打开下拉菜单
      await tester.tap(find.byKey(const Key('environment_switcher_dropdown')));
      await tester.pumpAndSettle();

      // 选择 Development（菜单项是最后一个匹配）
      await tester.tap(find.text('Development').last);
      await tester.pumpAndSettle();

      verify(mockStorageService.setActiveEnvironmentId('env-dev')).called(1);
    });

    testWidgets('should show active environment name', (tester) async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);
      when(mockStorageService.getActiveEnvironmentId())
          .thenAnswer((_) async => 'env-dev');

      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();

      expect(find.text('Development'), findsOneWidget);
    });

    testWidgets(
        'should show warning icon when request has unresolved variables',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      // 打开一个包含 {{host}} 的请求（无匹配变量）
      container
          .read(requestTabProvider.notifier)
          .openTab(HttpRequest.empty().copyWith(url: 'https://{{host}}/api'));
      container.read(activeTabIdProvider.notifier).state =
          container.read(requestTabProvider).first.id;

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('unresolved_variables_warning')),
        findsOneWidget,
      );
    });

    testWidgets('should not show warning when all variables resolve',
        (tester) async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);
      when(mockStorageService.getActiveEnvironmentId())
          .thenAnswer((_) async => 'env-dev');

      final container = buildContainer();
      addTearDown(container.dispose);

      container
          .read(requestTabProvider.notifier)
          .openTab(HttpRequest.empty().copyWith(url: 'https://{{host}}/api'));
      container.read(activeTabIdProvider.notifier).state =
          container.read(requestTabProvider).first.id;

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('unresolved_variables_warning')),
        findsNothing,
      );
    });

    testWidgets('should open manager dialog when tapping manage button',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildTestWidget(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manage_environments_button')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('environment_manager_dialog')), findsOneWidget);
    });
  });
}
