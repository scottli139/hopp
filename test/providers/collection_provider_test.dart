import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/providers/collection/collection_provider.dart';
import 'package:hopp/providers/core/providers.dart';

import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('CollectionNotifier', () {
    late MockStorageService mockStorageService;
    late ProviderContainer container;

    setUp(() {
      mockStorageService = MockStorageService();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('loadCollections', () {
      test('should load collections successfully', () async {
        final collections = [
          Collection.empty().copyWith(id: 'col-1', name: 'Collection 1'),
          Collection.empty().copyWith(id: 'col-2', name: 'Collection 2'),
        ];

        when(mockStorageService.getCollections())
            .thenAnswer((_) async => collections);

        await container.read(collectionProvider.notifier).loadCollections();

        final state = container.read(collectionProvider);
        expect(state, isA<AsyncData<List<Collection>>>());
        expect(state.valueOrNull, equals(collections));
        expect(state.valueOrNull!.length, equals(2));
      });

      test('should handle empty collections', () async {
        when(mockStorageService.getCollections()).thenAnswer((_) async => []);

        await container.read(collectionProvider.notifier).loadCollections();

        final state = container.read(collectionProvider);
        expect(state, isA<AsyncData<List<Collection>>>());
        expect(state.valueOrNull, isEmpty);
      });

      test('should handle error', () async {
        when(mockStorageService.getCollections())
            .thenThrow(Exception('Storage error'));

        await container.read(collectionProvider.notifier).loadCollections();

        final state = container.read(collectionProvider);
        expect(state, isA<AsyncError<List<Collection>>>());
      });
    });

    group('addCollection', () {
      test('should add collection and reload', () async {
        final newCollection =
            Collection.empty().copyWith(id: 'col-new', name: 'New Collection');
        final existingCollections = [
          Collection.empty().copyWith(id: 'col-1', name: 'Collection 1'),
        ];

        when(mockStorageService.saveCollection(newCollection))
            .thenAnswer((_) async {});
        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [...existingCollections, newCollection]);

        await container
            .read(collectionProvider.notifier)
            .addCollection(newCollection);

        verify(mockStorageService.saveCollection(newCollection)).called(1);

        final state = container.read(collectionProvider);
        expect(state.valueOrNull!.length, equals(2));
      });

      test('should handle save error gracefully', () async {
        final newCollection =
            Collection.empty().copyWith(id: 'col-new', name: 'New Collection');

        when(mockStorageService.saveCollection(newCollection))
            .thenThrow(Exception('Save error'));

        await container
            .read(collectionProvider.notifier)
            .addCollection(newCollection);

        verify(mockStorageService.saveCollection(newCollection)).called(1);
      });
    });

    group('updateCollection', () {
      test('should update collection and reload', () async {
        final updatedCollection =
            Collection.empty().copyWith(id: 'col-1', name: 'Updated Name');

        when(mockStorageService.saveCollection(updatedCollection))
            .thenAnswer((_) async {});
        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [updatedCollection]);

        await container
            .read(collectionProvider.notifier)
            .updateCollection(updatedCollection);

        verify(mockStorageService.saveCollection(updatedCollection)).called(1);
      });

      test('should handle update error gracefully', () async {
        final updatedCollection =
            Collection.empty().copyWith(id: 'col-1', name: 'Updated Name');

        when(mockStorageService.saveCollection(updatedCollection))
            .thenThrow(Exception('Update error'));

        await container
            .read(collectionProvider.notifier)
            .updateCollection(updatedCollection);

        verify(mockStorageService.saveCollection(updatedCollection)).called(1);
      });
    });

    group('deleteCollection', () {
      test('should delete collection and reload', () async {
        final collection =
            Collection.empty().copyWith(id: 'col-1', name: 'Test Collection');

        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [collection]);
        await container.read(collectionProvider.notifier).loadCollections();

        when(mockStorageService.deleteCollection('col-1'))
            .thenAnswer((_) async {});
        when(mockStorageService.getCollections()).thenAnswer((_) async => []);

        await container
            .read(collectionProvider.notifier)
            .deleteCollection('col-1');

        verify(mockStorageService.deleteCollection('col-1')).called(1);
      });

      test('should handle delete error gracefully', () async {
        final collection =
            Collection.empty().copyWith(id: 'col-1', name: 'Test Collection');

        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [collection]);
        await container.read(collectionProvider.notifier).loadCollections();

        when(mockStorageService.deleteCollection('col-1'))
            .thenThrow(Exception('Delete error'));
        when(mockStorageService.getCollections()).thenAnswer((_) async => []);

        await container
            .read(collectionProvider.notifier)
            .deleteCollection('col-1');

        verify(mockStorageService.deleteCollection('col-1')).called(1);
      });

      group('cascade delete', () {
        test('should cascade delete child collections using parentId', () async {
          // 创建扁平化结构: Parent -> Child -> GrandChild (通过 parentId 关联)
          final grandChild = Collection.empty().copyWith(
            id: 'grandchild',
            name: 'GrandChild',
            parentId: 'child',
          );
          final child = Collection.empty().copyWith(
            id: 'child',
            name: 'Child',
            parentId: 'parent',
          );
          final parent = Collection.empty()
              .copyWith(id: 'parent', name: 'Parent');

          when(mockStorageService.getCollections())
              .thenAnswer((_) async => [parent, child, grandChild]);

          await container.read(collectionProvider.notifier).loadCollections();

          // 设置删除后的空列表
          when(mockStorageService.getCollections())
              .thenAnswer((_) async => []);
          when(mockStorageService.deleteCollection(any))
              .thenAnswer((_) async {});

          // 删除父集合
          await container
              .read(collectionProvider.notifier)
              .deleteCollection('parent');

          // 验证所有集合都被删除
          verify(mockStorageService.deleteCollection('parent')).called(1);
          verify(mockStorageService.deleteCollection('child')).called(1);
          verify(mockStorageService.deleteCollection('grandchild')).called(1);
        });

        test('should cascade delete multiple levels of children', () async {
          // 创建更深的嵌套结构 (扁平化存储)
          final level3 = Collection.empty().copyWith(
            id: 'level3',
            name: 'Level 3',
            parentId: 'level2',
          );
          final level2 = Collection.empty().copyWith(
            id: 'level2',
            name: 'Level 2',
            parentId: 'level1',
          );
          final level1 = Collection.empty().copyWith(
            id: 'level1',
            name: 'Level 1',
            parentId: 'root',
          );
          final root = Collection.empty()
              .copyWith(id: 'root', name: 'Root');

          when(mockStorageService.getCollections())
              .thenAnswer((_) async => [root, level1, level2, level3]);

          await container.read(collectionProvider.notifier).loadCollections();

          when(mockStorageService.getCollections())
              .thenAnswer((_) async => []);
          when(mockStorageService.deleteCollection(any))
              .thenAnswer((_) async {});

          await container
              .read(collectionProvider.notifier)
              .deleteCollection('root');

          // 验证所有层级的集合都被删除
          verify(mockStorageService.deleteCollection('root')).called(1);
          verify(mockStorageService.deleteCollection('level1')).called(1);
          verify(mockStorageService.deleteCollection('level2')).called(1);
          verify(mockStorageService.deleteCollection('level3')).called(1);
        });

        test('should not affect sibling collections', () async {
          // 创建两个独立的集合树 (扁平化存储)
          final childOfA = Collection.empty().copyWith(
            id: 'child-a',
            name: 'Child of A',
            parentId: 'collection-a',
          );
          final collectionA = Collection.empty()
              .copyWith(id: 'collection-a', name: 'Collection A');
          final collectionB = Collection.empty()
              .copyWith(id: 'collection-b', name: 'Collection B');

          when(mockStorageService.getCollections())
              .thenAnswer((_) async => [collectionA, collectionB, childOfA]);

          await container.read(collectionProvider.notifier).loadCollections();

          // 只保留 collectionB
          when(mockStorageService.getCollections())
              .thenAnswer((_) async => [collectionB]);
          when(mockStorageService.deleteCollection(any))
              .thenAnswer((_) async {});

          // 删除 collectionA（及其子集合）
          await container
              .read(collectionProvider.notifier)
              .deleteCollection('collection-a');

          // 验证 collectionA 和其子集合被删除
          verify(mockStorageService.deleteCollection('collection-a')).called(1);
          verify(mockStorageService.deleteCollection('child-a')).called(1);

          // 验证 collectionB 未被删除
          verifyNever(mockStorageService.deleteCollection('collection-b'));
        });

        test('should delete requests in deleted collections', () async {
          final childRequest = HttpRequest.empty()
              .copyWith(id: 'req-child', name: 'Child Request');
          final child = Collection.empty().copyWith(
            id: 'child',
            name: 'Child',
            parentId: 'parent',
            requests: [childRequest],
          );
          final parentRequest = HttpRequest.empty()
              .copyWith(id: 'req-parent', name: 'Parent Request');
          final parent = Collection.empty().copyWith(
            id: 'parent',
            name: 'Parent',
            requests: [parentRequest],
          );

          when(mockStorageService.getCollections())
              .thenAnswer((_) async => [parent, child]);

          await container.read(collectionProvider.notifier).loadCollections();

          when(mockStorageService.getCollections())
              .thenAnswer((_) async => []);
          when(mockStorageService.deleteCollection(any))
              .thenAnswer((_) async {});
          when(mockStorageService.deleteRequest(any))
              .thenAnswer((_) async {});

          await container
              .read(collectionProvider.notifier)
              .deleteCollection('parent');

          // 验证集合中的请求也被删除
          verify(mockStorageService.deleteRequest('req-parent')).called(1);
          verify(mockStorageService.deleteRequest('req-child')).called(1);
        });

        test('should handle collection not found gracefully', () async {
          final collection = Collection.empty()
              .copyWith(id: 'col-1', name: 'Collection 1');

          when(mockStorageService.getCollections())
              .thenAnswer((_) async => [collection]);

          await container.read(collectionProvider.notifier).loadCollections();

          // 删除不存在的集合
          when(mockStorageService.getCollections())
              .thenAnswer((_) async => [collection]);

          await container
              .read(collectionProvider.notifier)
              .deleteCollection('non-existent');

          // 验证没有调用删除操作
          verifyNever(mockStorageService.deleteCollection(any));
        });
      });
    });

    group('toggleExpanded', () {
      test('should toggle isExpanded state', () async {
        final collection = Collection.empty()
            .copyWith(id: 'col-1', name: 'Test', isExpanded: false);

        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [collection]);

        await container.read(collectionProvider.notifier).loadCollections();

        when(mockStorageService.saveCollection(any)).thenAnswer((_) async {});

        await container
            .read(collectionProvider.notifier)
            .toggleExpanded('col-1');

        final state = container.read(collectionProvider);
        expect(state.valueOrNull!.first.isExpanded, isTrue);
      });

      test('should persist toggled state', () async {
        final collection = Collection.empty()
            .copyWith(id: 'col-1', name: 'Test', isExpanded: false);

        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [collection]);

        await container.read(collectionProvider.notifier).loadCollections();
        when(mockStorageService.saveCollection(any)).thenAnswer((_) async {});

        await container
            .read(collectionProvider.notifier)
            .toggleExpanded('col-1');

        verify(mockStorageService.saveCollection(any)).called(1);
      });

      test('should not toggle when collection does not exist', () async {
        final collection =
            Collection.empty().copyWith(id: 'col-1', name: 'Test');

        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [collection]);

        await container.read(collectionProvider.notifier).loadCollections();

        // New implementation silently returns when collection not found
        // (recursive search doesn't throw, just doesn't update anything)
        await container
            .read(collectionProvider.notifier)
            .toggleExpanded('non-existent');

        // State should remain unchanged
        final state = container.read(collectionProvider);
        expect(state.valueOrNull?.first.isExpanded, false);
      });

      test('should handle toggle when in error state', () async {
        when(mockStorageService.getCollections())
            .thenThrow(Exception('Load error'));

        await container.read(collectionProvider.notifier).loadCollections();

        // Reset the mock to avoid MissingStubError on subsequent calls
        when(mockStorageService.getCollections()).thenAnswer((_) async => []);

        await container
            .read(collectionProvider.notifier)
            .toggleExpanded('col-1');

        final state = container.read(collectionProvider);
        expect(state, isA<AsyncError<List<Collection>>>());
      });
    });

    group('addRequestToCollection', () {
      test('should add request to collection with parentId', () async {
        final collection = Collection.empty()
            .copyWith(id: 'col-1', name: 'Test', requests: []);
        final newRequest = HttpRequest.empty().copyWith(
          id: 'req-1',
          name: 'New Request',
          method: HttpMethod.get,
        );

        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [collection]);

        await container.read(collectionProvider.notifier).loadCollections();

        // 捕获保存的请求以验证 parentId
        HttpRequest? savedRequest;
        when(mockStorageService.saveRequest(any))
            .thenAnswer((invocation) async {
          savedRequest = invocation.positionalArguments[0] as HttpRequest;
        });

        await container
            .read(collectionProvider.notifier)
            .addRequestToCollection('col-1', newRequest);

        // 验证请求被保存且设置了 parentId
        verify(mockStorageService.saveRequest(any)).called(1);
        expect(savedRequest, isNotNull);
        expect(savedRequest!.parentId, equals('col-1'));
      });

      test('should persist request with correct parentId', () async {
        final collection = Collection.empty()
            .copyWith(id: 'col-1', name: 'Test', requests: []);
        final newRequest = HttpRequest.empty().copyWith(id: 'req-1');

        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [collection]);

        await container.read(collectionProvider.notifier).loadCollections();

        HttpRequest? savedRequest;
        when(mockStorageService.saveRequest(any))
            .thenAnswer((invocation) async {
          savedRequest = invocation.positionalArguments[0] as HttpRequest;
        });

        await container
            .read(collectionProvider.notifier)
            .addRequestToCollection('col-1', newRequest);

        // 扁平化存储：只保存请求，设置 parentId
        verify(mockStorageService.saveRequest(any)).called(1);
        expect(savedRequest!.parentId, equals('col-1'));
      });

      test('should silently return when collection does not exist', () async {
        final collection = Collection.empty()
            .copyWith(id: 'col-1', name: 'Test', requests: []);
        final newRequest = HttpRequest.empty().copyWith(id: 'req-1');

        when(mockStorageService.getCollections())
            .thenAnswer((_) async => [collection]);

        await container.read(collectionProvider.notifier).loadCollections();

        // 扁平化存储实现：当集合不存在时静默返回（通过 loadCollections 刷新）
        await container
            .read(collectionProvider.notifier)
            .addRequestToCollection('non-existent', newRequest);

        // 应该尝试保存请求（即使集合不存在）
        verify(mockStorageService.saveRequest(any)).called(1);
      });
    });
  });

  group('flattenedCollectionsProvider', () {
    test('should return empty list when loading', () {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getCollections()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      expect(container.read(flattenedCollectionsProvider), isEmpty);
    });

    test('should return empty list on error', () async {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getCollections())
          .thenThrow(Exception('Load error'));

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(collectionProvider.notifier).loadCollections();

      expect(container.read(flattenedCollectionsProvider), isEmpty);
    });

    test('should return all collections from flat storage', () async {
      final mockStorageService = MockStorageService();
      // 扁平化存储：子集合直接存储，通过 parentId 关联
      final childCollection = Collection.empty().copyWith(
        id: 'child-1',
        name: 'Child',
        parentId: 'parent-1',
      );
      final parentCollection = Collection.empty().copyWith(
        id: 'parent-1',
        name: 'Parent',
      );

      when(mockStorageService.getCollections())
          .thenAnswer((_) async => [parentCollection, childCollection]);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(collectionProvider.notifier).loadCollections();

      final flattened = container.read(flattenedCollectionsProvider);
      // flattenedCollectionsProvider 现在直接返回扁平化列表
      expect(flattened.length, equals(2));
      expect(flattened.map((c) => c.id), containsAll(['parent-1', 'child-1']));
    });

    test('should return flat list preserving storage order', () async {
      final mockStorageService = MockStorageService();
      final collection1 =
          Collection.empty().copyWith(id: 'col-1', name: 'Collection 1');
      final collection2 =
          Collection.empty().copyWith(id: 'col-2', name: 'Collection 2');
      final collection3 = Collection.empty().copyWith(
        id: 'col-3',
        name: 'Collection 3',
        parentId: 'col-1',
      );

      when(mockStorageService.getCollections())
          .thenAnswer((_) async => [collection1, collection2, collection3]);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(collectionProvider.notifier).loadCollections();

      final flattened = container.read(flattenedCollectionsProvider);
      expect(flattened.length, equals(3));
      // 扁平化存储保持原始顺序
      expect(flattened[0].id, equals('col-1'));
      expect(flattened[1].id, equals('col-2'));
      expect(flattened[2].id, equals('col-3'));
    });

    test('should handle multiple root collections', () async {
      final mockStorageService = MockStorageService();
      final collection1 =
          Collection.empty().copyWith(id: 'col-1', name: 'Collection 1');
      final collection2 =
          Collection.empty().copyWith(id: 'col-2', name: 'Collection 2');

      when(mockStorageService.getCollections())
          .thenAnswer((_) async => [collection1, collection2]);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(collectionProvider.notifier).loadCollections();

      final flattened = container.read(flattenedCollectionsProvider);
      expect(flattened.length, equals(2));
    });
  });

  group('rootCollectionsProvider', () {
    test('should return only root-level collections', () async {
      final mockStorageService = MockStorageService();
      final rootCollection = Collection.empty()
          .copyWith(id: 'root-1', name: 'Root Collection');
      final childCollection = Collection.empty().copyWith(
        id: 'child-1',
        name: 'Child Collection',
        parentId: 'root-1',
      );
      final anotherRoot = Collection.empty()
          .copyWith(id: 'root-2', name: 'Another Root');

      when(mockStorageService.getCollections())
          .thenAnswer((_) async => [rootCollection, childCollection, anotherRoot]);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(collectionProvider.notifier).loadCollections();

      final roots = container.read(rootCollectionsProvider);
      expect(roots.length, equals(2));
      expect(roots.map((c) => c.id), containsAll(['root-1', 'root-2']));
    });

    test('should return empty list when all collections have parents', () async {
      final mockStorageService = MockStorageService();
      final child1 = Collection.empty().copyWith(
        id: 'child-1',
        name: 'Child 1',
        parentId: 'some-parent',
      );
      final child2 = Collection.empty().copyWith(
        id: 'child-2',
        name: 'Child 2',
        parentId: 'some-parent',
      );

      when(mockStorageService.getCollections())
          .thenAnswer((_) async => [child1, child2]);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(collectionProvider.notifier).loadCollections();

      final roots = container.read(rootCollectionsProvider);
      expect(roots, isEmpty);
    });
  });
}
