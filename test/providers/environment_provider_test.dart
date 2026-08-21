import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/environment/environment_provider.dart';
import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  late MockStorageService mockStorageService;
  late ProviderContainer container;

  const devEnv = Environment(
    id: 'env-dev',
    name: 'Development',
    variables: [
      EnvironmentVariable(id: 'v1', key: 'host', value: 'dev.local'),
      EnvironmentVariable(id: 'v2', key: 'token', value: 'dev-token'),
    ],
  );

  const prodEnv = Environment(
    id: 'env-prod',
    name: 'Production',
    variables: [
      EnvironmentVariable(id: 'v3', key: 'host', value: 'api.example.com'),
    ],
  );

  setUp(() {
    mockStorageService = MockStorageService();

    // 默认桩：覆盖 notifier 初始化所需的所有存储读取
    when(mockStorageService.getEnvironments()).thenAnswer((_) async => []);
    when(mockStorageService.saveEnvironment(any)).thenAnswer((_) async {});
    when(mockStorageService.deleteEnvironment(any)).thenAnswer((_) async {});
    when(mockStorageService.getActiveEnvironmentId())
        .thenAnswer((_) async => null);
    when(mockStorageService.setActiveEnvironmentId(any))
        .thenAnswer((_) async {});
    when(mockStorageService.getGlobalVariables()).thenAnswer((_) async => []);
    when(mockStorageService.saveGlobalVariables(any)).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(mockStorageService),
      ],
    );
  });

  tearDown(() async {
    // 先冲刷未完成的异步加载（notifier 构造函数触发的 load），
    // 避免 dispose 后写 state 抛出未捕获异步错误
    await pumpEventQueue();
    container.dispose();
  });

  group('EnvironmentNotifier', () {
    test('should load environments on init', () async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv, prodEnv]);

      await container.read(environmentProvider.notifier).loadEnvironments();

      final state = container.read(environmentProvider);
      expect(state, isA<AsyncData<List<Environment>>>());
      expect(state.value, [devEnv, prodEnv]);
    });

    test('should handle load error', () async {
      when(mockStorageService.getEnvironments())
          .thenThrow(Exception('storage error'));

      await container.read(environmentProvider.notifier).loadEnvironments();

      final state = container.read(environmentProvider);
      expect(state, isA<AsyncError<List<Environment>>>());
    });

    test('saveEnvironment should persist and reload', () async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);

      await container
          .read(environmentProvider.notifier)
          .saveEnvironment(devEnv);

      verify(mockStorageService.saveEnvironment(devEnv)).called(1);
      expect(container.read(environmentProvider).value, [devEnv]);
    });

    test('deleteEnvironment should persist deletion', () async {
      await container
          .read(environmentProvider.notifier)
          .deleteEnvironment('env-dev');

      verify(mockStorageService.deleteEnvironment('env-dev')).called(1);
    });

    test('deleteEnvironment should clear active id when deleting active env',
        () async {
      await container
          .read(activeEnvironmentIdProvider.notifier)
          .setActive('env-dev');

      await container
          .read(environmentProvider.notifier)
          .deleteEnvironment('env-dev');

      verify(mockStorageService.setActiveEnvironmentId(null)).called(1);
      expect(container.read(activeEnvironmentIdProvider), isNull);
    });

    test('duplicateEnvironment should save copy with new id', () async {
      await container
          .read(environmentProvider.notifier)
          .duplicateEnvironment(devEnv);

      final captured =
          verify(mockStorageService.saveEnvironment(captureAny)).captured;
      final copy = captured.last as Environment;
      expect(copy.name, 'Development copy');
      expect(copy.id, isNot('env-dev'));
      expect(copy.variables.length, devEnv.variables.length);
      expect(copy.variables.first.key, 'host');
      expect(copy.variables.first.id, isNot('v1'));
    });
  });

  group('ActiveEnvironmentIdNotifier', () {
    test('should restore persisted active id on init', () async {
      when(mockStorageService.getActiveEnvironmentId())
          .thenAnswer((_) async => 'env-dev');

      // 触发 notifier 创建（lazy），其构造函数会异步加载持久化的 ID
      container.read(activeEnvironmentIdProvider.notifier);

      // 轮询等待异步加载完成
      for (var i = 0;
          i < 20 && container.read(activeEnvironmentIdProvider) == null;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(container.read(activeEnvironmentIdProvider), 'env-dev');
    });

    test('setActive should persist and update state', () async {
      await container
          .read(activeEnvironmentIdProvider.notifier)
          .setActive('env-prod');

      verify(mockStorageService.setActiveEnvironmentId('env-prod')).called(1);
      expect(container.read(activeEnvironmentIdProvider), 'env-prod');
    });
  });

  group('GlobalVariablesNotifier', () {
    test('setVariables should persist and update state', () async {
      const variables = [
        EnvironmentVariable(id: 'g1', key: 'shared', value: 'global-value'),
      ];

      await container
          .read(globalVariablesProvider.notifier)
          .setVariables(variables);

      verify(mockStorageService.saveGlobalVariables(variables)).called(1);
      expect(container.read(globalVariablesProvider), variables);
    });
  });

  group('activeEnvironmentProvider', () {
    test('should return null when no active id', () {
      expect(container.read(activeEnvironmentProvider), isNull);
    });

    test('should return active environment object', () async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv, prodEnv]);
      await container.read(environmentProvider.notifier).loadEnvironments();

      await container
          .read(activeEnvironmentIdProvider.notifier)
          .setActive('env-prod');

      expect(container.read(activeEnvironmentProvider), prodEnv);
    });

    test('should return null when active id not found', () async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);
      await container.read(environmentProvider.notifier).loadEnvironments();

      await container
          .read(activeEnvironmentIdProvider.notifier)
          .setActive('missing');

      expect(container.read(activeEnvironmentProvider), isNull);
    });
  });

  group('resolvedVariablesProvider', () {
    test('should merge globals and active env with env precedence', () async {
      when(mockStorageService.getEnvironments())
          .thenAnswer((_) async => [devEnv]);
      await container.read(environmentProvider.notifier).loadEnvironments();

      await container
          .read(activeEnvironmentIdProvider.notifier)
          .setActive('env-dev');

      await container
          .read(globalVariablesProvider.notifier)
          .setVariables(const [
        EnvironmentVariable(id: 'g1', key: 'host', value: 'global.local'),
        EnvironmentVariable(id: 'g2', key: 'shared', value: 'yes'),
      ]);

      final resolved = container.read(resolvedVariablesProvider);

      expect(resolved['host'], 'dev.local'); // 环境覆盖全局
      expect(resolved['token'], 'dev-token');
      expect(resolved['shared'], 'yes');
    });

    test('should return globals only when no active env', () async {
      await container
          .read(globalVariablesProvider.notifier)
          .setVariables(const [
        EnvironmentVariable(id: 'g1', key: 'shared', value: 'yes'),
      ]);

      final resolved = container.read(resolvedVariablesProvider);

      expect(resolved, {'shared': 'yes'});
    });
  });
}
