import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/collection.dart';
import '../models/http_request.dart';
import '../models/key_value_pair.dart';

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
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init('${appDir.path}/hopp');

    // Register adapters
    Hive.registerAdapter(KeyValuePairAdapter());
    Hive.registerAdapter(HttpRequestAdapter());
    Hive.registerAdapter(CollectionAdapter());

    // Open boxes
    _collectionsBox = await Hive.openBox<Collection>(_collectionsBoxName);
    _requestsBox = await Hive.openBox<HttpRequest>(_requestsBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    _prefs = await SharedPreferences.getInstance();
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
    await _collectionsBox?.put(collection.id, collection);
  }

  Future<void> deleteCollection(String id) async {
    await _collectionsBox?.delete(id);
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
    await _requestsBox?.put(request.id, request);
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
