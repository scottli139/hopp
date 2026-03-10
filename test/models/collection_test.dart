import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';

void main() {
  group('Collection', () {
    group('creation', () {
      test('should create Collection with all required fields', () {
        final collection = Collection(
          id: 'col-1',
          name: 'My Collection',
          description: 'Test description',
          parentId: 'parent-col',
          children: [],
          requests: [],
          sortOrder: 1,
          isExpanded: true,
        );

        expect(collection.id, equals('col-1'));
        expect(collection.name, equals('My Collection'));
        expect(collection.description, equals('Test description'));
        expect(collection.parentId, equals('parent-col'));
        expect(collection.children, isEmpty);
        expect(collection.requests, isEmpty);
        expect(collection.sortOrder, equals(1));
        expect(collection.isExpanded, isTrue);
      });

      test('should create Collection with default values', () {
        final collection = Collection(
          id: 'col-1',
          name: 'My Collection',
        );

        expect(collection.description, isNull);
        expect(collection.parentId, isNull);
        expect(collection.children, isEmpty);
        expect(collection.requests, isEmpty);
        expect(collection.sortOrder, equals(0));
        expect(collection.isExpanded, isFalse);
      });
    });

    group('empty factory', () {
      test('should create empty Collection with generated id and defaults', () {
        final collection = Collection.empty();

        expect(collection.id, isNotEmpty);
        expect(collection.name, equals('New Collection'));
        expect(collection.children, isEmpty);
        expect(collection.requests, isEmpty);
        expect(collection.isExpanded, isFalse);
      });

      test('should generate unique ids for multiple empty collections', () async {
        final collection1 = Collection.empty();
        await Future<void>.delayed(const Duration(milliseconds: 2));
        final collection2 = Collection.empty();

        expect(collection1.id, isNot(equals(collection2.id)));
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Original Name',
        );

        final copied = collection.copyWith(name: 'Updated Name');

        expect(copied.id, equals('col-1'));
        expect(copied.name, equals('Updated Name'));
      });

      test('should copy with new description', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test',
        );

        final copied = collection.copyWith(description: 'New description');

        expect(copied.description, equals('New description'));
      });

      test('should copy with new parentId', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test',
        );

        final copied = collection.copyWith(parentId: 'new-parent');

        expect(copied.parentId, equals('new-parent'));
      });

      test('should copy with new children list', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test',
          children: [],
        );

        final newChildren = [
          Collection.empty().copyWith(name: 'Child 1'),
        ];
        final copied = collection.copyWith(children: newChildren);

        expect(copied.children.length, equals(1));
        expect(copied.children.first.name, equals('Child 1'));
      });

      test('should copy with new requests list', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test',
          requests: [],
        );

        final newRequests = [
          HttpRequest.empty().copyWith(name: 'Request 1'),
        ];
        final copied = collection.copyWith(requests: newRequests);

        expect(copied.requests.length, equals(1));
        expect(copied.requests.first.name, equals('Request 1'));
      });

      test('should copy with new sortOrder', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test',
          sortOrder: 0,
        );

        final copied = collection.copyWith(sortOrder: 5);

        expect(copied.sortOrder, equals(5));
      });

      test('should copy with new isExpanded state', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test',
          isExpanded: false,
        );

        final copied = collection.copyWith(isExpanded: true);

        expect(copied.isExpanded, isTrue);
      });

      test('should copy without changes when no arguments provided', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test',
          description: 'Description',
        );

        final copied = collection.copyWith();

        expect(copied, equals(collection));
      });
    });

    group('isFolder getter', () {
      test('should return true when collection has children', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Parent',
          children: [
            Collection.empty(),
          ],
        );

        expect(collection.isFolder, isTrue);
      });

      test('should return true when collection has no children and no requests', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Empty Folder',
          children: [],
          requests: [],
        );

        expect(collection.isFolder, isTrue);
      });

      test('should return false when collection has requests but no children', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Request Container',
          children: [],
          requests: [
            HttpRequest.empty(),
          ],
        );

        expect(collection.isFolder, isFalse);
      });

      test('should return false when collection has both children and requests', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Mixed Container',
          children: [
            Collection.empty(),
          ],
          requests: [
            HttpRequest.empty(),
          ],
        );

        expect(collection.isFolder, isTrue);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test Collection',
          description: 'A test collection',
          parentId: 'parent-1',
          sortOrder: 1,
          isExpanded: true,
        );

        final json = collection.toJson();

        expect(json['id'], equals('col-1'));
        expect(json['name'], equals('Test Collection'));
        expect(json['description'], equals('A test collection'));
        expect(json['parentId'], equals('parent-1'));
        expect(json['sortOrder'], equals(1));
        expect(json['isExpanded'], equals(true));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'col-1',
          'name': 'Test Collection',
          'description': 'Description',
          'parentId': null,
          'children': [],
          'requests': [],
          'sortOrder': 0,
          'isExpanded': false,
        };

        final collection = Collection.fromJson(json);

        expect(collection.id, equals('col-1'));
        expect(collection.name, equals('Test Collection'));
        expect(collection.description, equals('Description'));
      });

      test('should handle JSON with nested children', () {
        final json = {
          'id': 'parent-col',
          'name': 'Parent',
          'children': [
            {
              'id': 'child-1',
              'name': 'Child 1',
              'children': [],
              'requests': [],
              'sortOrder': 0,
              'isExpanded': false,
            },
          ],
          'requests': [],
          'sortOrder': 0,
          'isExpanded': true,
        };

        final collection = Collection.fromJson(json);

        expect(collection.children.length, equals(1));
        expect(collection.children.first.name, equals('Child 1'));
        expect(collection.isExpanded, isTrue);
      });

      test('should handle JSON with nested requests', () {
        final json = {
          'id': 'col-1',
          'name': 'API Collection',
          'children': [],
          'requests': [
            {
              'id': 'req-1',
              'name': 'Get Users',
              'method': 'get',
              'url': 'https://api.example.com/users',
              'params': [],
              'headers': [],
              'body': '',
              'bodyType': 'none',
              'sortOrder': 0,
            },
          ],
          'sortOrder': 0,
          'isExpanded': false,
        };

        final collection = Collection.fromJson(json);

        expect(collection.requests.length, equals(1));
        expect(collection.requests.first.name, equals('Get Users'));
        expect(collection.requests.first.method, equals(HttpMethod.get));
      });

      test('should handle deeply nested collection structure', () {
        final json = {
          'id': 'root',
          'name': 'Root',
          'children': [
            {
              'id': 'level1',
              'name': 'Level 1',
              'children': [
                {
                  'id': 'level2',
                  'name': 'Level 2',
                  'children': [],
                  'requests': [],
                  'sortOrder': 0,
                  'isExpanded': false,
                },
              ],
              'requests': [],
              'sortOrder': 0,
              'isExpanded': false,
            },
          ],
          'requests': [],
          'sortOrder': 0,
          'isExpanded': false,
        };

        final collection = Collection.fromJson(json);

        expect(collection.children.first.children.first.id, equals('level2'));
      });
    });

    group('equality', () {
      test('identical collections should be equal', () {
        final collection1 = Collection(
          id: 'col-1',
          name: 'Test',
          description: 'Description',
        );
        final collection2 = Collection(
          id: 'col-1',
          name: 'Test',
          description: 'Description',
        );

        expect(collection1, equals(collection2));
      });

      test('collections with different ids should not be equal', () {
        final collection1 = Collection(id: 'col-1', name: 'Test');
        final collection2 = Collection(id: 'col-2', name: 'Test');

        expect(collection1, isNot(equals(collection2)));
      });

      test('collections with different names should not be equal', () {
        final collection1 = Collection(id: 'col-1', name: 'Test 1');
        final collection2 = Collection(id: 'col-1', name: 'Test 2');

        expect(collection1, isNot(equals(collection2)));
      });
    });

    group('edge cases', () {
      test('should handle empty name', () {
        final collection = Collection(
          id: 'col-1',
          name: '',
        );

        expect(collection.name, equals(''));
        expect(collection.isFolder, isTrue);
      });

      test('should handle null description', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test',
          description: null,
        );

        expect(collection.description, isNull);
      });

      test('should handle large sortOrder values', () {
        final collection = Collection(
          id: 'col-1',
          name: 'Test',
          sortOrder: 999999,
        );

        expect(collection.sortOrder, equals(999999));
      });
    });
  });
}
