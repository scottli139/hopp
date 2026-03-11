import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/collection.dart';
import '../models/http_method.dart';
import '../models/http_request.dart';
import '../models/key_value_pair.dart';
import '../utils/app_logger.dart';

class StorageService {
  static const String _settingsBoxName = 'settings';
  static const String _collectionsBoxName = 'collections';
  static const String _requestsBoxName = 'requests';
  static const String _settingsKey = 'app_settings';

  Box<Collection>? _collectionsBox;
  Box<HttpRequest>? _requestsBox;
  Box<dynamic>? _settingsBox;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    AppLogger.info('[StorageService] Initializing...');
    final appDir = await getApplicationDocumentsDirectory();
    AppLogger.debug('[StorageService] App directory: ${appDir.path}');

    Hive.init('${appDir.path}/hopp');

    // Register adapters
    Hive.registerAdapter(HttpMethodAdapter());
    Hive.registerAdapter(KeyValuePairAdapter());
    Hive.registerAdapter(HttpRequestAdapter());
    Hive.registerAdapter(CollectionAdapter());
    AppLogger.debug('[StorageService] Hive adapters registered');

    // Open boxes
    _collectionsBox = await Hive.openBox<Collection>(_collectionsBoxName);
    _requestsBox = await Hive.openBox<HttpRequest>(_requestsBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    _prefs = await SharedPreferences.getInstance();

    AppLogger.info('[StorageService] Initialized successfully');
    AppLogger.debug(
        '[StorageService] Collections: ${_collectionsBox?.length}, Requests: ${_requestsBox?.length}');
  }

  // Settings
  Future<AppSettings> getSettings() async {
    final json = _settingsBox?.get(_settingsKey) as Map<dynamic, dynamic>?;
    if (json == null) return AppSettings.defaults();

    return AppSettings.fromJson(
      json.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox?.put(_settingsKey, settings.toJson());
  }

  // Collections
  Future<List<Collection>> getCollections() async {
    return _collectionsBox?.values.toList() ?? [];
  }

  Future<Collection?> getCollection(String id) async {
    return _collectionsBox?.get(id);
  }

  Future<void> saveCollection(Collection collection) async {
    AppLogger.debug(
        '[StorageService] Saving collection: ${collection.id} (${collection.name})');
    await _collectionsBox?.put(collection.id, collection);
    AppLogger.debug('[StorageService] Collection saved: ${collection.id}');
  }

  Future<void> deleteCollection(String id) async {
    AppLogger.debug('[StorageService] Deleting collection: $id');
    await _collectionsBox?.delete(id);
    AppLogger.debug('[StorageService] Collection deleted: $id');
  }

  // Requests
  Future<List<HttpRequest>> getRequests({String? parentId}) async {
    final requests = _requestsBox?.values.toList() ?? [];
    if (parentId == null) return requests;
    return requests.where((r) => r.parentId == parentId).toList();
  }

  Future<HttpRequest?> getRequest(String id) async {
    return _requestsBox?.get(id);
  }

  Future<void> saveRequest(HttpRequest request) async {
    AppLogger.debug(
        '[StorageService] Saving request: ${request.id} (${request.name})');
    await _requestsBox?.put(request.id, request);
    AppLogger.debug('[StorageService] Request saved: ${request.id}');
  }

  Future<void> deleteRequest(String id) async {
    await _requestsBox?.delete(id);
  }

  // SharedPreferences (for simple key-value storage)
  Future<String?> getString(String key) async {
    return _prefs?.getString(key);
  }

  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> clear() async {
    await _collectionsBox?.clear();
    await _requestsBox?.clear();
    await _settingsBox?.clear();
    await _prefs?.clear();
  }

  Future<void> close() async {
    await _collectionsBox?.close();
    await _requestsBox?.close();
    await _settingsBox?.close();
  }
}
