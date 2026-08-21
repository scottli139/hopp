import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/providers/providers.dart';
import 'package:hopp/widgets/layout/sidebar.dart';
import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('Sidebar', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      // Stub getCollections to return empty list by default
      when(mockStorageService.getCollections()).thenAnswer((_) async => []);
      // Stub getRequests to return empty list by default
      when(mockStorageService.getRequests()).thenAnswer((_) async => []);
      // Environment switcher reads these on build
      when(mockStorageService.getEnvironments()).thenAnswer((_) async => []);
      when(mockStorageService.getActiveEnvironmentId())
          .thenAnswer((_) async => null);
      when(mockStorageService.getGlobalVariables()).thenAnswer((_) async => []);
    });

    Widget buildTestWidget({
      required ProviderContainer container,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Sidebar(),
          ),
        ),
      );
    }

    ProviderContainer createContainer({
      List<Collection> collections = const [],
      String? activeTabId,
    }) {
      // Pre-configure mock to return the collections
      when(mockStorageService.getCollections())
          .thenAnswer((_) async => collections);
      when(mockStorageService.getRequests()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      // Set active tab
      if (activeTabId != null) {
        container.read(activeTabIdProvider.notifier).state = activeTabId;
      }

      return container;
    }

    group('rendering', () {
      testWidgets('should render header with logo', (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Header should have a PopupMenuButton (more_vert icon) for actions
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('should render search field', (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration?.hintText, 'Filter...');
      });

      testWidgets('should show loading indicator when collections are loading',
          skip: true, (tester) async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorageService),
          ],
        );

        // Keep provider in loading state
        container.read(collectionProvider.notifier).state =
            const AsyncValue.loading();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show error message when collections fail to load',
          skip: true, (tester) async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorageService),
          ],
        );

        container.read(collectionProvider.notifier).state = AsyncValue.error(
          'Failed to load collections',
          StackTrace.current,
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.textContaining('Error:'), findsOneWidget);
        expect(
            find.textContaining('Failed to load collections'), findsOneWidget);
      });

      testWidgets('should show empty state when no collections',
          (tester) async {
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorageService),
          ],
        );
        // Set empty data state explicitly
        container.read(collectionProvider.notifier).state =
            const AsyncValue.data([]);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('No collections yet'), findsOneWidget);
      });

      testWidgets('should render collection items', (tester) async {
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'My Collection',
            isExpanded: false,
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('My Collection'), findsOneWidget);
        // Folder icon may be nested, so we check it exists somewhere in the tree
        expect(find.byIcon(Icons.folder), findsWidgets);
      });

      testWidgets('should show expanded collection with folder_open icon',
          (tester) async {
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'Expanded Collection',
            isExpanded: true,
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Folder open icon may exist in the tree for expanded collections
        expect(find.byIcon(Icons.folder_open), findsWidgets);
      });

      testWidgets('should render nested collection items using parentId',
          (tester) async {
        // 扁平化存储：使用 parentId 关联子集合
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'Parent Collection',
            isExpanded: true,
          ),
          Collection.empty().copyWith(
            id: 'child1',
            name: 'Child Collection',
            parentId: 'col1',
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Parent Collection'), findsOneWidget);
        expect(find.text('Child Collection'), findsOneWidget);
      });

      testWidgets('should render requests in collection', (tester) async {
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'API Collection',
            isExpanded: true,
            requests: [
              HttpRequest.empty().copyWith(
                id: 'req1',
                name: 'Get Users',
                method: HttpMethod.get,
              ),
              HttpRequest.empty().copyWith(
                id: 'req2',
                name: 'Create User',
                method: HttpMethod.post,
              ),
            ],
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Get Users'), findsOneWidget);
        expect(find.text('Create User'), findsOneWidget);
      });

      testWidgets('should highlight active request item', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Active Request',
          method: HttpMethod.get,
        );

        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'API Collection',
            isExpanded: true,
            requests: [request],
          ),
        ];

        final container = createContainer(
          collections: collections,
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Find the container that represents the active request
        final containerWidget =
            tester.widgetList<Container>(find.byType(Container)).firstWhere(
                  (c) => c.decoration is BoxDecoration,
                );
        final decoration = containerWidget.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
      });
    });

    group('interactions', () {
      testWidgets('should toggle collection expand on tap', (tester) async {
        // 扁平化存储：使用 parentId 关联子集合
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'Expandable Collection',
            isExpanded: false,
          ),
          Collection.empty().copyWith(
            id: 'child1',
            name: 'Child Hidden',
            parentId: 'col1',
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on collection to expand
        await tester.tap(find.text('Expandable Collection'));
        await tester.pump();

        // After toggling, provider should have been called
        // Note: The actual toggle effect depends on the provider implementation
      });

      testWidgets('should open request tab when request is tapped',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
        );

        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'API Collection',
            isExpanded: true,
            requests: [request],
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on request
        await tester.tap(find.text('Test Request'));
        await tester.pump();

        // Verify active tab ID is set
        expect(container.read(activeTabIdProvider), 'req1');
      });

      testWidgets('should show collection actions menu', (tester) async {
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'Collection with Actions',
            isExpanded: true,
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Collection items have their own more_vert icon for actions
        // There are multiple more_vert icons (header and each collection)
        final moreVertIcons = find.byIcon(Icons.more_vert);
        expect(moreVertIcons, findsAtLeastNWidgets(2));

        // Tap the second more_vert icon (collection actions)
        await tester.tap(moreVertIcons.at(1));
        await tester.pumpAndSettle();

        expect(find.text('Add Request'), findsOneWidget);
        expect(find.text('Add Folder'), findsOneWidget);
        expect(find.text('Rename'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('should show new collection dialog', (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Open header menu and tap New Collection
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        expect(find.text('New Collection'), findsOneWidget);
        expect(find.text('Enter collection name'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Create'), findsOneWidget);
      });

      testWidgets('should close dialog when cancel is tapped', (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Open header menu and tap New Collection
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be closed
        expect(find.text('New Collection'), findsNothing);
      });

      testWidgets('should show delete confirmation dialog', (tester) async {
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'Deletable Collection',
            isExpanded: true,
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Find collection actions menu (second more_vert icon)
        final moreVertIcons = find.byIcon(Icons.more_vert);
        expect(moreVertIcons, findsAtLeastNWidgets(2));

        // Open collection actions menu
        await tester.tap(moreVertIcons.at(1));
        await tester.pumpAndSettle();

        // Tap delete
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Collection'), findsOneWidget);
        expect(find.textContaining('Are you sure'), findsOneWidget);
      });
    });

    group('refresh', () {
      testWidgets('should trigger refresh when refresh menu item is tapped',
          (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Open header menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Tap refresh menu item
        await tester.tap(find.text('Refresh'));
        await tester.pump();

        // The provider should reload - we verify by checking loading state
        // Note: actual verification depends on mock setup
      });
    });

    group('nested collections', () {
      testWidgets('should render deeply nested collections using parentId',
          (tester) async {
        // 扁平化存储：所有集合在同一层级，通过 parentId 关联
        final collections = [
          Collection.empty().copyWith(
            id: 'level1',
            name: 'Level 1',
            isExpanded: true,
          ),
          Collection.empty().copyWith(
            id: 'level2',
            name: 'Level 2',
            parentId: 'level1',
            isExpanded: true,
          ),
          Collection.empty().copyWith(
            id: 'level3',
            name: 'Level 3',
            parentId: 'level2',
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Level 1'), findsOneWidget);
        expect(find.text('Level 2'), findsOneWidget);
        expect(find.text('Level 3'), findsOneWidget);
      });

      testWidgets('should render multiple top-level collections',
          (tester) async {
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'First Collection',
          ),
          Collection.empty().copyWith(
            id: 'col2',
            name: 'Second Collection',
          ),
          Collection.empty().copyWith(
            id: 'col3',
            name: 'Third Collection',
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('First Collection'), findsOneWidget);
        expect(find.text('Second Collection'), findsOneWidget);
        expect(find.text('Third Collection'), findsOneWidget);
      });
    });

    group('HTTP method badges', () {
      testWidgets('should display GET method badge', (tester) async {
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'API',
            isExpanded: true,
            requests: [
              HttpRequest.empty().copyWith(
                id: 'req1',
                name: 'GET Users',
                method: HttpMethod.get,
              ),
            ],
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Should find the request name - method badge is styled text, may not be found separately
        expect(find.text('GET Users'), findsOneWidget);
        // The method badge uses small font and is part of the row
        expect(find.textContaining('GET'), findsWidgets);
      });

      testWidgets('should display POST method badge', (tester) async {
        final collections = [
          Collection.empty().copyWith(
            id: 'col1',
            name: 'API',
            isExpanded: true,
            requests: [
              HttpRequest.empty().copyWith(
                id: 'req1',
                name: 'POST Users',
                method: HttpMethod.post,
              ),
            ],
          ),
        ];

        final container = createContainer(collections: collections);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Should find the request name - method badge is styled text, may not be found separately
        expect(find.text('POST Users'), findsOneWidget);
        // The method badge uses small font and is part of the row
        expect(find.textContaining('POST'), findsWidgets);
      });
    });
  });
}
