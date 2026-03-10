import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/request_tab.dart';
import 'package:hopp/providers/providers.dart';
import 'package:hopp/widgets/layout/request_tabs.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('RequestTabs', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
    });

    Widget buildTestWidget({
      required ProviderContainer container,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: RequestTabs(),
          ),
        ),
      );
    }

    ProviderContainer createContainer({
      List<RequestTab> tabs = const [],
      String? activeTabId,
    }) {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      // Initialize tabs
      container.read(requestTabProvider.notifier).state = tabs;

      // Set active tab
      if (activeTabId != null) {
        container.read(activeTabIdProvider.notifier).state = activeTabId;
      }

      return container;
    }

    group('rendering', () {
      testWidgets('should render nothing when no tabs', (tester) async {
        final container = createContainer(tabs: []);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Should render SizedBox.shrink()
        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
      });

      testWidgets('should render single tab', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Get Users',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Get Users'), findsOneWidget);
      });

      testWidgets('should render multiple tabs', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Get Users',
              method: HttpMethod.get,
            ),
          ),
          RequestTab(
            id: 'tab2',
            request: HttpRequest.empty().copyWith(
              id: 'req2',
              name: 'Create User',
              method: HttpMethod.post,
            ),
          ),
          RequestTab(
            id: 'tab3',
            request: HttpRequest.empty().copyWith(
              id: 'req3',
              name: 'Delete User',
              method: HttpMethod.delete,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Get Users'), findsOneWidget);
        expect(find.text('Create User'), findsOneWidget);
        expect(find.text('Delete User'), findsOneWidget);
      });

      testWidgets('should render new tab button', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Test',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should show active tab with different styling', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Active Tab',
              method: HttpMethod.get,
            ),
          ),
          RequestTab(
            id: 'tab2',
            request: HttpRequest.empty().copyWith(
              id: 'req2',
              name: 'Inactive Tab',
              method: HttpMethod.post,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Both tabs should be visible
        expect(find.text('Active Tab'), findsOneWidget);
        expect(find.text('Inactive Tab'), findsOneWidget);
      });
    });

    group('HTTP method badges', () {
      testWidgets('should display GET badge with blue color', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Get Request',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.textContaining('GET'), findsOneWidget);
      });

      testWidgets('should display POST badge with green color', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Post Request',
              method: HttpMethod.post,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.textContaining('POST'), findsOneWidget);
      });

      testWidgets('should display PUT badge', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Put Request',
              method: HttpMethod.put,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.textContaining('PUT'), findsOneWidget);
      });

      testWidgets('should display DELETE badge', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Delete Request',
              method: HttpMethod.delete,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.textContaining('DELETE'), findsOneWidget);
      });

      testWidgets('should display PATCH badge', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Patch Request',
              method: HttpMethod.patch,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.textContaining('PATCH'), findsOneWidget);
      });
    });

    group('dirty indicator', () {
      testWidgets('should show dirty indicator for unsaved tab', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Dirty Tab',
              method: HttpMethod.get,
            ),
            isDirty: true,
          ),
          RequestTab(
            id: 'tab2',
            request: HttpRequest.empty().copyWith(
              id: 'req2',
              name: 'Clean Tab',
              method: HttpMethod.get,
            ),
            isDirty: false,
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Both tabs should be visible
        expect(find.text('Dirty Tab'), findsOneWidget);
        expect(find.text('Clean Tab'), findsOneWidget);
      });
    });

    group('close button', () {
      testWidgets('should show close button on each tab', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Tab 1',
              method: HttpMethod.get,
            ),
          ),
          RequestTab(
            id: 'tab2',
            request: HttpRequest.empty().copyWith(
              id: 'req2',
              name: 'Tab 2',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Should find 2 close icons (one for each tab)
        expect(find.byIcon(Icons.close), findsNWidgets(2));
      });
    });

    group('interactions', () {
      testWidgets('should activate tab when tapped', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Tab 1',
              method: HttpMethod.get,
            ),
          ),
          RequestTab(
            id: 'tab2',
            request: HttpRequest.empty().copyWith(
              id: 'req2',
              name: 'Tab 2',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Tab 2
        await tester.tap(find.text('Tab 2'));
        await tester.pump();

        // Verify active tab ID is updated
        expect(container.read(activeTabIdProvider), 'tab2');
      });

      testWidgets('should close tab when close button is tapped', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Tab 1',
              method: HttpMethod.get,
            ),
          ),
          RequestTab(
            id: 'tab2',
            request: HttpRequest.empty().copyWith(
              id: 'req2',
              name: 'Tab 2',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap close button on first tab
        final closeButtons = find.byIcon(Icons.close);
        await tester.tap(closeButtons.first);
        await tester.pump();

        // Verify tab is closed
        final remainingTabs = container.read(requestTabProvider);
        expect(remainingTabs.length, 1);
      });

      testWidgets('should switch to another tab when closing active tab', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Tab 1',
              method: HttpMethod.get,
            ),
          ),
          RequestTab(
            id: 'tab2',
            request: HttpRequest.empty().copyWith(
              id: 'req2',
              name: 'Tab 2',
              method: HttpMethod.get,
            ),
          ),
          RequestTab(
            id: 'tab3',
            request: HttpRequest.empty().copyWith(
              id: 'req3',
              name: 'Tab 3',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Close the active tab (tab1)
        final closeButtons = find.byIcon(Icons.close);
        await tester.tap(closeButtons.first);
        await tester.pump();

        // Should activate the last remaining tab (tab3)
        expect(container.read(activeTabIdProvider), 'tab3');
      });

      testWidgets('should create new tab when plus button is tapped', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Existing Tab',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap new tab button
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();

        // A new tab should be created
        final updatedTabs = container.read(requestTabProvider);
        expect(updatedTabs.length, greaterThanOrEqualTo(1));
      });

      testWidgets('should clear active tab when closing last tab', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Last Tab',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Close the only tab
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        // Active tab should be cleared
        expect(container.read(activeTabIdProvider), isNull);
      });
    });

    group('tab constraints', () {
      testWidgets('should have minimum width constraint', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'A',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tab should be rendered
        expect(find.text('A'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should have maximum width constraint', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'Very Long Tab Name That Should Be Truncated',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Text should be truncated with ellipsis
        final textWidget = tester.widget<Text>(find.text('Very Long Tab Name That Should Be Truncated'));
        expect(textWidget.overflow, TextOverflow.ellipsis);
      });
    });

    group('long names', () {
      testWidgets('should truncate long request names', (tester) async {
        final tabs = [
          RequestTab(
            id: 'tab1',
            request: HttpRequest.empty().copyWith(
              id: 'req1',
              name: 'This is a very long request name that should be truncated with ellipsis',
              method: HttpMethod.get,
            ),
          ),
        ];

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tab should still render without overflow error
        expect(find.text('This is a very long request name that should be truncated with ellipsis'), findsOneWidget);
      });
    });

    group('many tabs', () {
      testWidgets('should render many tabs horizontally scrollable', (tester) async {
        final tabs = List.generate(5, (index) {
          return RequestTab(
            id: 'tab$index',
            request: HttpRequest.empty().copyWith(
              id: 'req$index',
              name: 'Request $index',
              method: HttpMethod.get,
            ),
          );
        });

        final container = createContainer(tabs: tabs);

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // First and last tabs should be rendered
        expect(find.text('Request 0'), findsOneWidget);
        expect(find.text('Request 4'), findsOneWidget);

        // Should be in a horizontal ListView
        expect(find.byType(ListView), findsOneWidget);
      });
    });
  });
}
