import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 使用自定义适配器，隐藏自动生成的适配器避免冲突
import '../models/adapters/adapters.dart'
    show HttpRequestAdapter, AppSettingsAdapter, CollectionAdapter;
import '../models/app_settings.dart' hide AppSettingsAdapter;
import '../models/collection.dart' hide CollectionAdapter;
import '../models/environment.dart';
import '../models/http_method.dart';
import '../models/http_request.dart' hide HttpRequestAdapter;
import '../models/key_value_pair.dart';
import '../utils/app_logger.dart';
import 'database_migration_service.dart';

/// 存储服务
///
/// 负责应用数据的持久化存储，包括：
/// - Collections 和 Requests 的 Hive 存储
/// - 应用设置的 SharedPreferences 存储
/// - 数据库版本控制和自动迁移
class StorageService {
  static const String _settingsBoxName = 'settings';
  static const String _collectionsBoxName = 'collections';
  static const String _requestsBoxName = 'requests';
  static const String _environmentsBoxName = 'environments';
  static const String _settingsKey = 'app_settings';
  static const String _activeEnvironmentIdKey = 'active_environment_id';

  /// 全局变量在 environments box 中的保留 ID
  static const String globalsEnvironmentId = 'globals';

  Box<Collection>? _collectionsBox;
  Box<HttpRequest>? _requestsBox;
  Box<Environment>? _environmentsBox;
  Box<dynamic>? _settingsBox;
  SharedPreferences? _prefs;

  /// 初始化存储服务
  ///
  /// 执行以下步骤：
  /// 1. 初始化 Hive 目录
  /// 2. 初始化 SharedPreferences（用于版本控制）
  /// 3. 执行数据库迁移检查
  /// 4. 注册 Hive 适配器（使用自定义向后兼容适配器）
  /// 5. 打开 Hive boxes
  Future<void> initialize() async {
    AppLogger.info('[StorageService] Initializing...');

    // 1. 初始化 Hive 目录
    final appDir = await getApplicationDocumentsDirectory();
    AppLogger.debug('[StorageService] App directory: ${appDir.path}');
    Hive.init('${appDir.path}/hopp');

    // 2. 先初始化 SharedPreferences（用于版本控制）
    _prefs = await SharedPreferences.getInstance();

    // 3. 执行数据库迁移
    await _runMigration();

    // 4. 注册适配器（使用自定义向后兼容适配器）
    _registerAdapters();

    // 5. 打开 boxes
    await _openBoxes();

    AppLogger.info('[StorageService] Initialized successfully');
    AppLogger.debug(
      '[StorageService] Collections: ${_collectionsBox?.length}, '
      'Requests: ${_requestsBox?.length}',
    );
  }

  /// 运行数据库迁移
  Future<void> _runMigration() async {
    try {
      final migrationService = DatabaseMigrationService(_prefs!);
      await migrationService.migrateIfNeeded();
    } catch (e, stack) {
      // 迁移失败不应该阻止应用启动
      // 适配器会处理向后兼容
      AppLogger.error('[StorageService] Migration failed', e, stack);
    }
  }

  /// 注册 Hive 适配器
  ///
  /// 使用自定义适配器替代自动生成适配器，提供向后兼容能力
  void _registerAdapters() {
    // 枚举适配器（不需要向后兼容处理）
    Hive.registerAdapter(HttpMethodAdapter());

    // 基础模型适配器（较稳定）
    Hive.registerAdapter(KeyValuePairAdapter());
    Hive.registerAdapter(CollectionAdapter());

    // 使用自定义向后兼容适配器
    // 这些适配器处理字段缺失问题，为新增字段提供默认值
    Hive.registerAdapter(HttpRequestAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    // 环境变量模型适配器（新模型，无历史数据，使用生成适配器）
    Hive.registerAdapter(VariableTypeAdapter());
    Hive.registerAdapter(EnvironmentVariableAdapter());
    Hive.registerAdapter(EnvironmentAdapter());

    AppLogger.debug('[StorageService] Hive adapters registered');
  }

  /// 打开 Hive boxes
  Future<void> _openBoxes() async {
    try {
      _collectionsBox = await Hive.openBox<Collection>(_collectionsBoxName);
      _requestsBox = await Hive.openBox<HttpRequest>(_requestsBoxName);
      _environmentsBox = await Hive.openBox<Environment>(_environmentsBoxName);
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    } catch (e, stack) {
      AppLogger.error('[StorageService] Failed to open boxes', e, stack);
      // 如果打开失败，可能是数据损坏，尝试清除并重新创建
      await _handleBoxOpenError();
    }
  }

  /// 处理 Box 打开错误
  ///
  /// 当数据损坏导致无法打开时，删除并重新创建
  Future<void> _handleBoxOpenError() async {
    AppLogger.warning('[StorageService] Attempting to recover from box error');
    try {
      await Hive.deleteBoxFromDisk(_collectionsBoxName);
      await Hive.deleteBoxFromDisk(_requestsBoxName);
      await Hive.deleteBoxFromDisk(_environmentsBoxName);
      await Hive.deleteBoxFromDisk(_settingsBoxName);

      _collectionsBox = await Hive.openBox<Collection>(_collectionsBoxName);
      _requestsBox = await Hive.openBox<HttpRequest>(_requestsBoxName);
      _environmentsBox = await Hive.openBox<Environment>(_environmentsBoxName);
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

      AppLogger.info('[StorageService] Boxes recovered successfully');
    } catch (e, stack) {
      AppLogger.fatal('[StorageService] Failed to recover boxes', e, stack);
      rethrow;
    }
  }

  // ==================== Settings ====================

  /// 获取应用设置
  Future<AppSettings> getSettings() async {
    final json = _settingsBox?.get(_settingsKey) as Map<dynamic, dynamic>?;
    if (json == null) return AppSettings.defaults();

    return AppSettings.fromJson(
      json.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  /// 保存应用设置
  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox?.put(_settingsKey, settings.toJson());
  }

  // ==================== Collections ====================

  /// 获取所有 Collections
  Future<List<Collection>> getCollections() async {
    return _collectionsBox?.values.toList() ?? [];
  }

  /// 获取指定 Collection
  Future<Collection?> getCollection(String id) async {
    return _collectionsBox?.get(id);
  }

  /// 保存 Collection
  Future<void> saveCollection(Collection collection) async {
    AppLogger.debug(
      '[StorageService] Saving collection: ${collection.id} (${collection.name})',
    );
    await _collectionsBox?.put(collection.id, collection);
    AppLogger.debug('[StorageService] Collection saved: ${collection.id}');
  }

  /// 删除 Collection
  Future<void> deleteCollection(String id) async {
    AppLogger.debug('[StorageService] Deleting collection: $id');
    await _collectionsBox?.delete(id);
    AppLogger.debug('[StorageService] Collection deleted: $id');
  }

  // ==================== Requests ====================

  /// 获取所有 Requests
  Future<List<HttpRequest>> getRequests({String? parentId}) async {
    final requests = _requestsBox?.values.toList() ?? [];
    if (parentId == null) return requests;
    return requests.where((r) => r.parentId == parentId).toList();
  }

  /// 获取指定 Request
  Future<HttpRequest?> getRequest(String id) async {
    return _requestsBox?.get(id);
  }

  /// 保存 Request
  Future<void> saveRequest(HttpRequest request) async {
    AppLogger.debug(
      '[StorageService] Saving request: ${request.id} (${request.name})',
    );
    await _requestsBox?.put(request.id, request);
    AppLogger.debug('[StorageService] Request saved: ${request.id}');
  }

  /// 删除 Request
  Future<void> deleteRequest(String id) async {
    await _requestsBox?.delete(id);
  }

  // ==================== Environments ====================

  /// 获取所有 Environments（不含保留的全局变量记录）
  Future<List<Environment>> getEnvironments() async {
    final environments = _environmentsBox?.values.toList() ?? [];
    return environments.where((e) => e.id != globalsEnvironmentId).toList();
  }

  /// 获取指定 Environment
  Future<Environment?> getEnvironment(String id) async {
    return _environmentsBox?.get(id);
  }

  /// 保存 Environment
  Future<void> saveEnvironment(Environment environment) async {
    AppLogger.debug(
      '[StorageService] Saving environment: ${environment.id} (${environment.name})',
    );
    await _environmentsBox?.put(environment.id, environment);
  }

  /// 删除 Environment
  Future<void> deleteEnvironment(String id) async {
    AppLogger.debug('[StorageService] Deleting environment: $id');
    await _environmentsBox?.delete(id);
  }

  /// 获取当前激活的 Environment ID（null 表示未选择）
  Future<String?> getActiveEnvironmentId() async {
    return _prefs?.getString(_activeEnvironmentIdKey);
  }

  /// 设置当前激活的 Environment ID（null 表示取消选择）
  Future<void> setActiveEnvironmentId(String? id) async {
    if (id == null) {
      await _prefs?.remove(_activeEnvironmentIdKey);
    } else {
      await _prefs?.setString(_activeEnvironmentIdKey, id);
    }
  }

  /// 获取全局变量（跨环境共享）
  Future<List<EnvironmentVariable>> getGlobalVariables() async {
    final globals = _environmentsBox?.get(globalsEnvironmentId);
    return globals?.variables ?? [];
  }

  /// 保存全局变量（跨环境共享）
  Future<void> saveGlobalVariables(List<EnvironmentVariable> variables) async {
    final current = _environmentsBox?.get(globalsEnvironmentId);
    final globals = (current ??
            const Environment(
              id: globalsEnvironmentId,
              name: 'Globals',
            ))
        .copyWith(variables: variables);
    await _environmentsBox?.put(globalsEnvironmentId, globals);
  }

  // ==================== SharedPreferences ====================

  /// 获取字符串值
  Future<String?> getString(String key) async {
    return _prefs?.getString(key);
  }

  /// 设置字符串值
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  /// 清除所有数据
  Future<void> clear() async {
    await _collectionsBox?.clear();
    await _requestsBox?.clear();
    await _environmentsBox?.clear();
    await _settingsBox?.clear();
    await _prefs?.clear();
  }

  /// 关闭存储服务
  Future<void> close() async {
    await _collectionsBox?.close();
    await _requestsBox?.close();
    await _environmentsBox?.close();
    await _settingsBox?.close();
  }

  /// 重置数据库（用于测试）
  ///
  /// 危险操作，仅用于测试环境
  Future<void> resetForTesting() async {
    AppLogger.warning('[StorageService] Resetting database for testing');
    await clear();
    final migrationService = DatabaseMigrationService(_prefs!);
    await migrationService.resetVersionForTesting();
  }

  /// 获取 SharedPreferences（用于测试）
  SharedPreferences? get prefs => _prefs;
}
