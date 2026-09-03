import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../utils/app_logger.dart';
import '../core/providers.dart';

/// Provider to track dirty requests (modified but not saved to collection)
final dirtyRequestsProvider = StateProvider<Set<String>>((ref) => {});

class CollectionNotifier extends StateNotifier<AsyncValue<List<Collection>>> {
  final Ref _ref;

  CollectionNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadCollections();
  }

  Future<void> loadCollections() async {
    AppLogger.debug('[CollectionNotifier] Loading collections...');
    state = const AsyncValue.loading();

    try {
      final storage = _ref.read(storageServiceProvider);
      final collections = await storage.getCollections();
      state = AsyncValue.data(collections);
      AppLogger.info(
          '[CollectionNotifier] Loaded ${collections.length} collections');
    } catch (e, stack) {
      AppLogger.error(
          '[CollectionNotifier] Failed to load collections', e, stack);
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCollection(Collection collection) async {
    AppLogger.info(
        '[CollectionNotifier] Adding collection: ${collection.name}');
    try {
      final storage = _ref.read(storageServiceProvider);
      await storage.saveCollection(collection);
      await loadCollections();
      AppLogger.info('[CollectionNotifier] Collection added: ${collection.id}');
    } catch (e, stack) {
      AppLogger.error(
          '[CollectionNotifier] Failed to add collection', e, stack);
    }
  }

  Future<void> updateCollection(Collection collection) async {
    try {
      final storage = _ref.read(storageServiceProvider);
      await storage.saveCollection(collection);
      await loadCollections();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteCollection(String id) async {
    AppLogger.info('[CollectionNotifier] Deleting collection: $id');
    try {
      final storage = _ref.read(storageServiceProvider);

      // 获取当前集合列表以找到要删除的集合及其子集合
      final currentState = state;
      if (currentState case AsyncData(:final value)) {
        // 收集所有需要删除的集合 ID（包括子集合）
        final idsToDelete = <String>[];
        final requestsToDelete = <String>[];

        // 1. 从扁平化列表中找到目标集合及其所有子孙集合（通过 parentId 关联）
        void collectDescendants(String parentId) {
          idsToDelete.add(parentId);

          for (final collection in value) {
            // 检查是否是这个父集合的直接子集合（通过 parentId 关联）
            if (collection.parentId == parentId) {
              collectDescendants(collection.id);
            }
          }
        }

        // 2. 找到目标集合
        Collection? findTargetCollection(String targetId) {
          for (final collection in value) {
            if (collection.id == targetId) {
              return collection;
            }
          }
          return null;
        }

        final targetCollection = findTargetCollection(id);
        if (targetCollection == null) {
          AppLogger.warning('[CollectionNotifier] Collection not found: $id');
          return;
        }

        // 3. 收集目标集合及其所有子孙
        collectDescendants(id);

        // 4. 收集要删除的请求（扁平化存储：请求通过 parentId 关联到集合）
        final allRequests = await storage.getRequests();
        for (final request in allRequests) {
          if (request.parentId != null &&
              idsToDelete.contains(request.parentId)) {
            requestsToDelete.add(request.id);
          }
        }

        AppLogger.info(
          '[CollectionNotifier] Deleting ${idsToDelete.length} collections and ${requestsToDelete.length} requests',
        );

        // 5. 删除所有收集到的集合
        for (final collectionId in idsToDelete) {
          await storage.deleteCollection(collectionId);
          AppLogger.debug(
              '[CollectionNotifier] Deleted collection: $collectionId');
        }

        // 6. 删除所有收集到的请求
        for (final requestId in requestsToDelete) {
          await storage.deleteRequest(requestId);
          AppLogger.debug('[CollectionNotifier] Deleted request: $requestId');
        }
      }

      await loadCollections();
      AppLogger.info('[CollectionNotifier] Collection deletion completed: $id');
    } catch (e, stack) {
      AppLogger.error(
          '[CollectionNotifier] Failed to delete collection', e, stack);
    }
  }

  Future<void> toggleExpanded(String collectionId) async {
    final currentState = state;
    if (currentState case AsyncData(:final value)) {
      // 检查集合是否存在
      final collectionIndex = value.indexWhere((c) => c.id == collectionId);
      if (collectionIndex == -1) {
        // 集合不存在，静默返回
        return;
      }

      // 扁平化结构：直接更新集合
      final updated = value.map((c) {
        if (c.id == collectionId) {
          return c.copyWith(isExpanded: !c.isExpanded);
        }
        return c;
      }).toList();

      state = AsyncValue.data(updated);

      // 持久化更改
      final storage = _ref.read(storageServiceProvider);
      await storage.saveCollection(updated[collectionIndex]);
    }
  }

  Future<void> addRequestToCollection(
      String collectionId, HttpRequest request) async {
    AppLogger.info(
        '[CollectionNotifier] Adding request ${request.name} to collection $collectionId');
    final currentState = state;
    if (currentState case AsyncData()) {
      // 扁平化存储：只通过 parentId 关联，不修改 collection.requests
      final storage = _ref.read(storageServiceProvider);

      // 设置 parentId 并保存请求
      final requestWithParent = request.copyWith(parentId: collectionId);
      await storage.saveRequest(requestWithParent);

      // 触发集合刷新以更新 UI
      await loadCollections();

      AppLogger.info(
          '[CollectionNotifier] Request added to collection: ${requestWithParent.id}');
    }
  }

  /// Update a request within a collection - synchronizes tab changes to sidebar
  Future<void> updateRequestInCollection(HttpRequest request) async {
    AppLogger.info(
        '[CollectionNotifier] Updating request in collection: ${request.id}');

    // 扁平化存储：直接保存请求即可，不需要修改 collection.requests
    final storage = _ref.read(storageServiceProvider);
    await storage.saveRequest(request);

    // 触发刷新以更新 UI
    await loadCollections();

    // Remove from dirty set
    _ref.read(dirtyRequestsProvider.notifier).update((set) {
      final newSet = Set<String>.from(set);
      newSet.remove(request.id);
      return newSet;
    });

    AppLogger.info(
        '[CollectionNotifier] Request updated in collection: ${request.id}');
  }

  /// Save or update a request - automatically adds to default collection if new
  /// If no collection exists, creates a default one automatically
  Future<void> saveRequest(HttpRequest request,
      {String? targetCollectionId}) async {
    final currentState = state;
    if (currentState is AsyncData<List<Collection>>) {
      final collections = currentState.value;
      final storage = _ref.read(storageServiceProvider);

      // 检查请求是否已存在（通过查询 storage）
      final existingRequest = await storage.getRequest(request.id);

      if (existingRequest != null) {
        // Request exists, update it (保持原有的 parentId)
        final updatedRequest = request.copyWith(
          parentId: existingRequest.parentId ?? targetCollectionId,
        );
        await updateRequestInCollection(updatedRequest);
      } else {
        // Request is new, need to add to a collection
        String? collectionIdToUse = targetCollectionId;

        // If no target specified and no collections exist, create a default one
        if (collectionIdToUse == null && collections.isEmpty) {
          AppLogger.info(
              '[CollectionNotifier] No collections found, creating default collection');
          final defaultCollection = Collection.empty().copyWith(
            id: 'default-collection',
            name: 'My Collection',
            description: 'Default collection for saved requests',
          );
          await addCollection(defaultCollection);

          // After creating default collection, reload and get the first one
          final currentCollections = state.valueOrNull ?? [];
          if (currentCollections.isNotEmpty) {
            collectionIdToUse = currentCollections.first.id;
          }
        } else if (collectionIdToUse == null && collections.isNotEmpty) {
          // Use the first available collection
          collectionIdToUse = collections.first.id;
          AppLogger.info(
              '[CollectionNotifier] Auto-adding request to first collection: ${collections.first.name}');
        }

        if (collectionIdToUse != null) {
          await addRequestToCollection(collectionIdToUse, request);
        } else {
          throw Exception(L10nBridge.t.collection_saveNoCollection);
        }
      }
    } else {
      throw Exception(L10nBridge.t.collection_notLoaded);
    }
  }

  /// Delete a request from a collection
  /// 注意：扁平化存储下，直接删除请求即可，不需要 collectionId
  Future<void> deleteRequestFromCollection(
      String? collectionId, String requestId) async {
    AppLogger.info('[CollectionNotifier] Deleting request $requestId');

    // 扁平化存储：直接删除请求，parentId 会自然失效
    final storage = _ref.read(storageServiceProvider);
    await storage.deleteRequest(requestId);

    // 触发刷新以更新 UI
    await loadCollections();

    AppLogger.info('[CollectionNotifier] Request deleted: $requestId');
  }

  /// Find all child collections by parent ID (for sidebar rendering)
  List<Collection> findChildrenByParentId(String parentId) {
    final currentState = state;
    if (currentState case AsyncData(:final value)) {
      return value.where((c) => c.parentId == parentId).toList();
    }
    return [];
  }

  /// Find collection by ID
  Collection? findCollectionById(String id) {
    final currentState = state;
    if (currentState case AsyncData(:final value)) {
      for (final collection in value) {
        if (collection.id == id) {
          return collection;
        }
      }
    }
    return null;
  }
}

final collectionProvider =
    StateNotifierProvider<CollectionNotifier, AsyncValue<List<Collection>>>(
        (ref) {
  return CollectionNotifier(ref);
});

/// Provider that returns all collections as a flat list (no hierarchy)
/// This is the default for flat storage - UI can reconstruct hierarchy using parentId
final flattenedCollectionsProvider = Provider<List<Collection>>((ref) {
  final collectionsAsync = ref.watch(collectionProvider);

  return collectionsAsync.when(
    data: (collections) => collections,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider that indexes all collections by id
/// 用于 Auth 继承链解析（F8.1）、预请求链集合级配置（F8.2）等按 id 查找的场景
final collectionsByIdProvider = Provider<Map<String, Collection>>((ref) {
  final collections = ref.watch(flattenedCollectionsProvider);
  return {for (final c in collections) c.id: c};
});

/// Provider that returns root-level collections only (those with null parentId)
final rootCollectionsProvider = Provider<List<Collection>>((ref) {
  final collectionsAsync = ref.watch(collectionProvider);

  return collectionsAsync.when(
    data: (collections) =>
        collections.where((c) => c.parentId == null).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider that returns all requests
/// 监听 collectionProvider 的变化，在导入新集合后自动刷新
final requestsProvider = FutureProvider<List<HttpRequest>>((ref) async {
  // 监听集合变化，确保导入新集合后请求列表自动刷新
  ref.watch(collectionProvider);

  final storage = ref.read(storageServiceProvider);
  return storage.getRequests();
});
