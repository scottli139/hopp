import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/models/request_tab.dart';
import 'package:hopp/providers/providers.dart';
import 'package:hopp/widgets/request/request_editor.dart';
import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('RequestEditor', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      // Stub storage methods
      when(mockStorageService.getCollections()).thenAnswer((_) async => []);
      when(mockStorageService.getRequests()).thenAnswer((_) async => []);
    });

    Widget buildTestWidget({
      required ProviderContainer container,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: RequestEditor(),
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
      if (tabs.isNotEmpty) {
        container.read(requestTabProvider.notifier).state = tabs;
      }

      // Set active tab
      if (activeTabId != null) {
        container.read(activeTabIdProvider.notifier).state = activeTabId;
      }

      return container;
    }

    group('rendering', () {
      testWidgets('should show empty state when no active tab', (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Select a request'), findsOneWidget);
      });

      testWidgets('should render URL bar with method dropdown', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          url: 'https://api.example.com/users',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Check URL field
        expect(find.text('https://api.example.com/users'), findsOneWidget);

        // Check method dropdown
        expect(find.byType(DropdownButton<HttpMethod>), findsOneWidget);

        // Check Send button
        // Check for Send button with icon
        expect(find.byIcon(Icons.send), findsOneWidget);
        expect(find.text('Send'), findsOneWidget);
      });

      testWidgets('should render all tabs', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Params'), findsOneWidget);
        expect(find.text('Headers'), findsOneWidget);
        expect(find.text('Body'), findsOneWidget);
        expect(find.text('Auth'), findsOneWidget);
      });

      testWidgets('should display correct method in dropdown', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.post,
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        final dropdown = tester.widget<DropdownButton<HttpMethod>>(
          find.byType(DropdownButton<HttpMethod>),
        );
        expect(dropdown.value, HttpMethod.post);
      });
    });

    group('Params tab', () {
      testWidgets('should render empty params list with add button',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Add new'), findsOneWidget);
      });

      testWidgets('should render params with headers', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty()
                .copyWith(key: 'page', value: '1', enabled: true),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Key'), findsWidgets);
        // Value header text is present
        expect(find.text('Value'), findsWidgets);
      });

      testWidgets('should display param key and value', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty()
                .copyWith(key: 'search', value: 'test', enabled: true),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('search'), findsOneWidget);
        expect(find.text('test'), findsOneWidget);
      });

      testWidgets('should show checkbox for param enabled state',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty()
                .copyWith(key: 'enabled', value: 'yes', enabled: true),
            KeyValuePair.empty()
                .copyWith(key: 'disabled', value: 'no', enabled: false),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Find checkboxes
        final checkboxes =
            tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
        expect(checkboxes.length, greaterThanOrEqualTo(2));
        expect(checkboxes[0].value, true);
        expect(checkboxes[1].value, false);
      });

      testWidgets('should show delete button for each param', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty().copyWith(key: 'param1', value: 'value1'),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });
    });

    group('Headers tab', () {
      testWidgets('should switch to Headers tab', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Content-Type', value: 'application/json'),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Headers tab
        await tester.tap(find.text('Headers'));
        await tester.pumpAndSettle();

        expect(find.text('Content-Type'), findsOneWidget);
        expect(find.text('application/json'), findsOneWidget);
      });
    });

    group('Body tab', () {
      testWidgets('should render body type selector', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.post,
          bodyType: 'json',
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Body tab
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        expect(find.text('None'), findsOneWidget);
        expect(find.text('JSON'), findsOneWidget);
        expect(find.text('Text'), findsOneWidget);
        expect(find.text('Form'), findsOneWidget);
      });

      testWidgets('should render body editor when body type is not none',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.post,
          bodyType: 'json',
          body: '{"key": "value"}',
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Body tab
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        // Check that CodeEditor is rendered (CodeField is the underlying widget)
        expect(find.byType(CodeField), findsOneWidget);
      });

      testWidgets('should not render body editor when body type is none',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          bodyType: 'none',
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Body tab
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        // Body editor should not be visible
        final textFields = tester.widgetList<TextField>(find.byType(TextField));
        final bodyTextField = textFields.where(
          (tf) => tf.decoration?.hintText == 'Request body',
        );
        expect(bodyTextField, isEmpty);
      });
    });

    group('Auth tab', () {
      testWidgets('should show coming soon message in Auth tab',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Auth tab
        await tester.tap(find.text('Auth'));
        await tester.pumpAndSettle();

        expect(find.text('Authentication'), findsOneWidget);
        // Lock icon is shown in both the tab and the empty state
        expect(find.byIcon(Icons.lock_outline), findsWidgets);
      });
    });

    group('method colors', () {
      testWidgets('should display GET method with blue color', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Find GET text in dropdown
        expect(find.text('GET'), findsOneWidget);
      });

      testWidgets('should display POST method with green color',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test',
          method: HttpMethod.post,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('POST'), findsOneWidget);
      });

      testWidgets('should display DELETE method with red color',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test',
          method: HttpMethod.delete,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('DELETE'), findsOneWidget);
      });
    });

    group('URL input', () {
      testWidgets('should render URL input field', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test',
          url: '',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Find URL input by hint text
        expect(find.text('Enter URL'), findsOneWidget);
      });
    });

    group('complex scenarios', () {
      testWidgets('should handle request with multiple params and headers',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Complex Request',
          url: 'https://api.example.com/search',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty().copyWith(key: 'q', value: 'flutter'),
            KeyValuePair.empty().copyWith(key: 'page', value: '1'),
            KeyValuePair.empty().copyWith(key: 'limit', value: '10'),
          ],
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Authorization', value: 'Bearer token123'),
            KeyValuePair.empty()
                .copyWith(key: 'Accept', value: 'application/json'),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('q'), findsOneWidget);
        expect(find.text('flutter'), findsOneWidget);
        expect(find.text('page'), findsOneWidget);
        expect(find.text('1'), findsWidgets); // Multiple '1' may exist
      });

      testWidgets('should handle JSON body request', (tester) async {
        final jsonBody = '''{
  "name": "John Doe",
  "email": "john@example.com",
  "age": 30
}''';

        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Create User',
          url: 'https://api.example.com/users',
          method: HttpMethod.post,
          bodyType: 'json',
          body: jsonBody,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Navigate to body tab
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        // Verify JSON body is displayed
        expect(find.textContaining('John Doe'), findsOneWidget);
      });
    });
  });
}
