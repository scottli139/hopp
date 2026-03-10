import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../core/providers.dart';

class CollectionNotifier extends StateNotifier<AsyncValue<List<Collection>>> {
  final Ref _ref;
  
  CollectionNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadCollections();
  }

  Future<void> loadCollections() async {
    state = const AsyncValue.loading();
    
    try {
      final storage = _ref.read(storageServiceProvider);
      final collections = await storage.getCollections();
      state = AsyncValue.data(collections);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCollection(Collection collection) async {
    try {
      final storage = _ref.read(storageServiceProvider);
      await storage.saveCollection(collection);
      await loadCollections();
    } catch (e) {
      // Handle error
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
      final updated = value.map((c) {
        if (c.id == collectionId) {
          return c.copyWith(isExpanded: !c.isExpanded);
        }
        return c;
      }).toList();
      
      state = AsyncValue.data(updated);
      
      // Persist change
      final collection = updated.firstWhere((c) => c.id == collectionId);
      final storage = _ref.read(storageServiceProvider);
      await storage.saveCollection(collection);
    }
  }

  Future<void> addRequestToCollection(String collectionId, HttpRequest request) async {
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
    }
  }
}

final collectionProvider = StateNotifierProvider<CollectionNotifier, AsyncValue<List<Collection>>>((ref) {
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
