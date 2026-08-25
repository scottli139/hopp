import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/environment.dart';
import '../../services/variable_resolver.dart';
import '../../utils/app_logger.dart';
import '../core/providers.dart';
import '../request/request_tab_provider.dart';

/// Environment 列表管理
class EnvironmentNotifier extends StateNotifier<AsyncValue<List<Environment>>> {
  final Ref _ref;

  EnvironmentNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadEnvironments();
  }

  Future<void> loadEnvironments() async {
    state = const AsyncValue.loading();

    try {
      final storage = _ref.read(storageServiceProvider);
      final environments = await storage.getEnvironments();
      environments.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = AsyncValue.data(environments);
      AppLogger.info(
          '[EnvironmentNotifier] Loaded ${environments.length} environments');
    } catch (e, stack) {
      AppLogger.error(
          '[EnvironmentNotifier] Failed to load environments', e, stack);
      state = AsyncValue.error(e, stack);
    }
  }

  /// 新建或更新 Environment
  Future<void> saveEnvironment(Environment environment) async {
    try {
      final storage = _ref.read(storageServiceProvider);
      await storage.saveEnvironment(environment);
      await loadEnvironments();
      AppLogger.info(
          '[EnvironmentNotifier] Environment saved: ${environment.id}');
    } catch (e, stack) {
      AppLogger.error(
          '[EnvironmentNotifier] Failed to save environment', e, stack);
    }
  }

  /// 删除 Environment；若删除的是当前激活环境，同时清除激活状态
  Future<void> deleteEnvironment(String id) async {
    try {
      final storage = _ref.read(storageServiceProvider);
      await storage.deleteEnvironment(id);

      if (_ref.read(activeEnvironmentIdProvider) == id) {
        await _ref.read(activeEnvironmentIdProvider.notifier).setActive(null);
      }

      await loadEnvironments();
      AppLogger.info('[EnvironmentNotifier] Environment deleted: $id');
    } catch (e, stack) {
      AppLogger.error(
          '[EnvironmentNotifier] Failed to delete environment', e, stack);
    }
  }

  /// 复制 Environment（生成新 ID，名称加 " copy" 后缀）
  Future<void> duplicateEnvironment(Environment environment) async {
    final copy = Environment.empty().copyWith(
      name: '${environment.name} copy',
      description: environment.description,
      variables: environment.variables
          .map((v) => EnvironmentVariable.empty().copyWith(
                key: v.key,
                value: v.value,
                type: v.type,
                enabled: v.enabled,
              ))
          .toList(),
    );
    await saveEnvironment(copy);
  }
}

final environmentProvider =
    StateNotifierProvider<EnvironmentNotifier, AsyncValue<List<Environment>>>(
        (ref) {
  return EnvironmentNotifier(ref);
});

/// 当前激活的 Environment ID（持久化到 SharedPreferences）
class ActiveEnvironmentIdNotifier extends StateNotifier<String?> {
  final Ref _ref;

  ActiveEnvironmentIdNotifier(this._ref) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final storage = _ref.read(storageServiceProvider);
    state = await storage.getActiveEnvironmentId();
  }

  Future<void> setActive(String? id) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setActiveEnvironmentId(id);
    state = id;
    AppLogger.info('[ActiveEnvironmentIdNotifier] Active environment: $id');
  }
}

final activeEnvironmentIdProvider =
    StateNotifierProvider<ActiveEnvironmentIdNotifier, String?>((ref) {
  return ActiveEnvironmentIdNotifier(ref);
});

/// 全局变量（跨环境共享，持久化）
class GlobalVariablesNotifier extends StateNotifier<List<EnvironmentVariable>> {
  final Ref _ref;

  GlobalVariablesNotifier(this._ref) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final storage = _ref.read(storageServiceProvider);
    state = await storage.getGlobalVariables();
  }

  Future<void> setVariables(List<EnvironmentVariable> variables) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.saveGlobalVariables(variables);
    state = variables;
  }
}

final globalVariablesProvider =
    StateNotifierProvider<GlobalVariablesNotifier, List<EnvironmentVariable>>(
        (ref) {
  return GlobalVariablesNotifier(ref);
});

/// 当前激活的 Environment 对象
final activeEnvironmentProvider = Provider<Environment?>((ref) {
  final activeId = ref.watch(activeEnvironmentIdProvider);
  if (activeId == null) return null;

  final environments = ref.watch(environmentProvider);
  return environments.when(
    data: (list) {
      for (final env in list) {
        if (env.id == activeId) return env;
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 本地（会话级）变量表（F8.2）
///
/// 预请求链等运行时产出写入此处：不持久化、不污染环境；
/// 优先级最高（本地 > 环境 > 全局）。
final localVariablesProvider = StateProvider<Map<String, String>>((ref) => {});

/// 合并后的变量表：本地 > 激活环境 > 全局（就近原则）
final resolvedVariablesProvider = Provider<Map<String, String>>((ref) {
  final globals = ref.watch(globalVariablesProvider);
  final activeEnv = ref.watch(activeEnvironmentProvider);
  final locals = ref.watch(localVariablesProvider);
  return VariableResolver.buildScope(
      globals: globals, activeEnvironment: activeEnv)
    ..addAll(locals);
});

/// 变量替换引擎
final variableResolverProvider = Provider<VariableResolver>((ref) {
  return VariableResolver();
});

/// 当前活动请求中未定义的变量列表（用于 UI 标记）
final unresolvedVariablesProvider = Provider<List<String>>((ref) {
  final activeTab = ref.watch(activeTabProvider);
  if (activeTab == null) return const [];

  final variables = ref.watch(resolvedVariablesProvider);
  final resolver = ref.watch(variableResolverProvider);
  return resolver.findUnresolvedInRequest(activeTab.request, variables);
});
