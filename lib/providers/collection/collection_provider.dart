import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    try {
      final storage = _ref.read(storageServiceProvider);
      await storage.deleteCollection(id);
      await loadCollections();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleExpanded(String collectionId) async {
    final currentState = state;
    if (currentState case AsyncData(:final value)) {
      // 递归更新嵌套集合
      List<Collection> updateCollections(List<Collection> collections) {
        return collections.map((c) {
          if (c.id == collectionId) {
            return c.copyWith(isExpanded: !c.isExpanded);
          }
          // 递归检查子集合
          if (c.children.isNotEmpty) {
            return c.copyWith(children: updateCollections(c.children));
          }
          return c;
        }).toList();
      }

      final updated = updateCollections(value);
      state = AsyncValue.data(updated);

      // 找到集合并持久化（需要递归查找）
      Collection? findCollection(List<Collection> collections) {
        for (final c in collections) {
          if (c.id == collectionId) return c;
          if (c.children.isNotEmpty) {
            final found = findCollection(c.children);
            if (found != null) return found;
          }
        }
        return null;
      }

      final collection = findCollection(updated);
      if (collection != null) {
        final storage = _ref.read(storageServiceProvider);
        await storage.saveCollection(collection);
      }
    }
  }

  Future<void> addRequestToCollection(
      String collectionId, HttpRequest request) async {
    AppLogger.info(
        '[CollectionNotifier] Adding request ${request.name} to collection $collectionId');
    final currentState = state;
    if (currentState case AsyncData(:final value)) {
      final updated = value.map((c) {
        if (c.id == collectionId) {
          return c.copyWith(
            requests: [...c.requests, request],
          );
        }
        return c;
      }).toList();

      state = AsyncValue.data(updated);

      // Persist change
      final collection = updated.firstWhere((c) => c.id == collectionId);
      final storage = _ref.read(storageServiceProvider);
      await storage.saveCollection(collection);
      await storage.saveRequest(request);
      AppLogger.info(
          '[CollectionNotifier] Request added to collection: ${request.id}');
    }
  }

  /// Update a request within a collection - synchronizes tab changes to sidebar
  Future<void> updateRequestInCollection(HttpRequest request) async {
    AppLogger.info(
        '[CollectionNotifier] Updating request in collection: ${request.id}');
    final currentState = state;
    if (currentState case AsyncData(:final value)) {
      // Find and update the request in the collection hierarchy
      List<Collection> updateCollections(List<Collection> collections) {
        return collections.map((c) {
          // Check if request is in this collection's requests
          final requestIndex = c.requests.indexWhere((r) => r.id == request.id);
          if (requestIndex != -1) {
            final updatedRequests = [...c.requests];
            updatedRequests[requestIndex] = request;
            return c.copyWith(requests: updatedRequests);
          }
          // Check in children
          if (c.children.isNotEmpty) {
            return c.copyWith(children: updateCollections(c.children));
          }
          return c;
        }).toList();
      }

      final updated = updateCollections(value);
      state = AsyncValue.data(updated);

      // Persist changes
      final storage = _ref.read(storageServiceProvider);
      await storage.saveRequest(request);

      // Also update the collection that contains this request
      for (final collection in updated) {
        if (collection.requests.any((r) => r.id == request.id)) {
          await storage.saveCollection(collection);
          break;
        }
      }

      // Remove from dirty set
      _ref.read(dirtyRequestsProvider.notifier).update((set) {
        final newSet = Set<String>.from(set);
        newSet.remove(request.id);
        return newSet;
      });

      AppLogger.info(
          '[CollectionNotifier] Request updated in collection: ${request.id}');
    }
  }

  /// Find which collection contains a request
  String? findRequestCollectionId(String requestId) {
    final currentState = state;
    if (currentState case AsyncData(:final value)) {
      for (final collection in value) {
        if (collection.requests.any((r) => r.id == requestId)) {
          return collection.id;
        }
        // Check children recursively
        for (final child in collection.children) {
          if (child.requests.any((r) => r.id == requestId)) {
            return child.id;
          }
        }
      }
    }
    return null;
  }

  /// Check if a request exists in any collection
  bool isRequestInAnyCollection(String requestId) {
    return findRequestCollectionId(requestId) != null;
  }

  /// Save or update a request - automatically adds to default collection if new
  /// If no collection exists, creates a default one automatically
  Future<void> saveRequest(HttpRequest request,
      {String? targetCollectionId}) async {
    final currentState = state;
    if (currentState is AsyncData<List<Collection>>) {
      final collections = currentState.value;
      // Check if request already exists in any collection
      final existingCollectionId = findRequestCollectionId(request.id);

      if (existingCollectionId != null) {
        // Request exists, update it
        await updateRequestInCollection(request);
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
          throw Exception(
              'Failed to create or find a collection to save the request.');
        }
      }
    } else {
      throw Exception('Collections not loaded yet');
    }
  }

  /// Delete a request from a collection
  Future<void> deleteRequestFromCollection(
      String collectionId, String requestId) async {
    AppLogger.info(
        '[CollectionNotifier] Deleting request $requestId from collection $collectionId');
    final currentState = state;
    if (currentState case AsyncData(:final value)) {
      // Find and update the collection
      List<Collection> updateCollections(List<Collection> collections) {
        return collections.map((c) {
          if (c.id == collectionId) {
            final updatedRequests =
                c.requests.where((r) => r.id != requestId).toList();
            return c.copyWith(requests: updatedRequests);
          }
          // Check in children
          if (c.children.isNotEmpty) {
            return c.copyWith(children: updateCollections(c.children));
          }
          return c;
        }).toList();
      }

      final updated = updateCollections(value);
      state = AsyncValue.data(updated);

      // Persist changes
      final storage = _ref.read(storageServiceProvider);
      final collection = updated.firstWhere((c) => c.id == collectionId);
      await storage.saveCollection(collection);
      await storage.deleteRequest(requestId);

      AppLogger.info(
          '[CollectionNotifier] Request deleted: $requestId from collection: $collectionId');
    }
  }
}

final collectionProvider =
    StateNotifierProvider<CollectionNotifier, AsyncValue<List<Collection>>>(
        (ref) {
  return CollectionNotifier(ref);
});

final flattenedCollectionsProvider = Provider<List<Collection>>((ref) {
  final collectionsAsync = ref.watch(collectionProvider);

  return collectionsAsync.when(
    data: (collections) {
      final result = <Collection>[];
      void flatten(Collection c, int depth) {
        result.add(c);
        for (final child in c.children) {
          flatten(child, depth + 1);
        }
      }

      for (final c in collections) {
        flatten(c, 0);
      }
      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
