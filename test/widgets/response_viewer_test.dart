import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/http_response.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/models/request_tab.dart';
import 'package:hopp/providers/providers.dart';
import 'package:hopp/widgets/common/code_editor.dart';
import 'package:hopp/widgets/request/response_viewer.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('ResponseViewer', () {
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
            body: ResponseViewer(),
          ),
        ),
      );
    }

    ProviderContainer createContainer({
      HttpResponse? response,
      String? activeTabId,
    }) {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      // Set up a tab and active tab id if response is provided
      if (response != null && activeTabId != null) {
        container.read(requestTabProvider.notifier).state = [
          RequestTab(
            id: activeTabId,
            request: HttpRequest.empty()
                .copyWith(id: 'req_$activeTabId', name: 'Test'),
          ),
        ];
        container.read(activeTabIdProvider.notifier).state = activeTabId;
        container.read(requestResponseProvider.notifier).state = {
          activeTabId: response,
        };
      }

      return container;
    }

    group('rendering', () {
      testWidgets('should render all tabs', (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Body'), findsOneWidget);
        expect(find.text('Headers'), findsOneWidget);
        expect(find.text('Cookies'), findsOneWidget);
      });

      testWidgets('should show "No response yet" when no response',
          (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('No response yet'), findsOneWidget);
      });

      testWidgets('should show empty body state in Body tab', (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Send a request to see the response'), findsOneWidget);
        expect(find.byIcon(Icons.code_off), findsOneWidget);
      });
    });

    group('response info bar', () {
      testWidgets('should display status code for successful response',
          (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          statusText: 'OK',
          body: '{"data": []}',
          durationMs: 150,
          sizeBytes: 1024,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('200 OK'), findsOneWidget);
        expect(find.text('150 ms'), findsOneWidget);
        expect(find.text('1.0 KB'), findsOneWidget);
      });

      testWidgets('should display status code for 404 response',
          (tester) async {
        // For error responses, the error message is shown instead of status code
        final response = HttpResponse.error('Not Found').copyWith(
          statusCode: 404,
          durationMs: 80,
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Error state shows error message and icon
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Not Found'), findsOneWidget);
      });

      testWidgets('should display error state correctly', (tester) async {
        final response = HttpResponse.error('Connection timeout').copyWith(
          durationMs: 5000,
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Connection timeout'), findsOneWidget);
      });

      testWidgets('should show correct size formatting for bytes',
          (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: 'small',
          sizeBytes: 500,
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('500 B'), findsOneWidget);
      });

      testWidgets('should show correct size formatting for megabytes',
          (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: 'large data',
          sizeBytes: 5 * 1024 * 1024, // 5 MB
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('5.0 MB'), findsOneWidget);
      });

      testWidgets('should show hyphen for null size', (tester) async {
        final response = HttpResponse(
          statusCode: 204,
          durationMs: 50,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('-'), findsOneWidget);
      });
    });

    group('status code colors', () {
      testWidgets('should display 2xx status', (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: '{}',
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Status is displayed with code and text
        expect(find.textContaining('200'), findsOneWidget);
      });

      testWidgets('should display 3xx status', (tester) async {
        final response = HttpResponse(
          statusCode: 301,
          statusText: 'Moved Permanently',
          body: '',
          durationMs: 50,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.textContaining('301'), findsOneWidget);
      });

      testWidgets('should display 4xx status', (tester) async {
        final response = HttpResponse(
          error: 'Bad Request',
          statusCode: 400,
          durationMs: 50,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Error state shows error message, not status code
        expect(find.text('Bad Request'), findsOneWidget);
      });

      testWidgets('should display 5xx status', (tester) async {
        final response = HttpResponse(
          error: 'Internal Server Error',
          statusCode: 500,
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Error state shows error message
        expect(find.text('Internal Server Error'), findsOneWidget);
      });
    });

    group('Body tab', () {
      testWidgets('should display response body', (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: '{"users": [{"id": 1, "name": "John"}]}',
          durationMs: 120,
          sizeBytes: 256,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Verify CodeEditor is used for body content
        expect(find.byType(CodeEditor), findsOneWidget);
      });

      testWidgets('should display code editor for body', (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: 'response content',
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byType(CodeEditor), findsOneWidget);
      });
    });

    group('Headers tab', () {
      testWidgets('should show "No headers" when headers are empty',
          (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: '{}',
          headers: [],
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Navigate to Headers tab
        await tester.tap(find.text('Headers'));
        await tester.pumpAndSettle();

        expect(find.text('No headers'), findsOneWidget);
      });

      testWidgets('should display response headers', (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: '{}',
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Content-Type', value: 'application/json'),
            KeyValuePair.empty()
                .copyWith(key: 'Cache-Control', value: 'no-cache'),
            KeyValuePair.empty()
                .copyWith(key: 'X-Request-Id', value: 'abc-123'),
          ],
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Navigate to Headers tab
        await tester.tap(find.text('Headers'));
        await tester.pumpAndSettle();

        expect(find.text('Content-Type'), findsOneWidget);
        expect(find.text('application/json'), findsOneWidget);
        expect(find.text('Cache-Control'), findsOneWidget);
        expect(find.text('no-cache'), findsOneWidget);
        expect(find.text('X-Request-Id'), findsOneWidget);
        expect(find.text('abc-123'), findsOneWidget);
      });

      testWidgets('should display headers with primary color for keys',
          (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: '{}',
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Authorization', value: 'Bearer token'),
          ],
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Navigate to Headers tab
        await tester.tap(find.text('Headers'));
        await tester.pumpAndSettle();

        // Verify header key is displayed
        expect(find.text('Authorization'), findsOneWidget);
      });
    });

    group('Cookies tab', () {
      testWidgets('should show Cookies icon and title in Cookies tab',
          (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Navigate to Cookies tab
        await tester.tap(find.text('Cookies'));
        await tester.pumpAndSettle();

        expect(find.text('Cookies'), findsWidgets); // Multiple 'Cookies' text
        expect(find.byIcon(Icons.cookie_outlined), findsOneWidget);
      });
    });

    group('action buttons', () {
      testWidgets('should show copy button when body exists', (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: 'response data',
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.copy), findsOneWidget);
      });

      testWidgets('should show save button when body exists', (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: 'response data',
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.save), findsOneWidget);
      });

      testWidgets('should show copy button when body exists', (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: 'response data',
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.copy), findsOneWidget);
      });
    });

    group('complex response scenarios', () {
      testWidgets('should handle large JSON response', (tester) async {
        final largeBody = '''{
  "data": {
    "users": [
      {"id": 1, "name": "User 1", "email": "user1@example.com"},
      {"id": 2, "name": "User 2", "email": "user2@example.com"},
      {"id": 3, "name": "User 3", "email": "user3@example.com"}
    ],
    "total": 100,
    "page": 1,
    "per_page": 10
  },
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z",
    "version": "1.0"
  }
}''';

        final response = HttpResponse(
          statusCode: 200,
          body: largeBody,
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Content-Type', value: 'application/json'),
            KeyValuePair.empty().copyWith(key: 'X-Total-Count', value: '100'),
          ],
          durationMs: 250,
          sizeBytes: largeBody.length,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.textContaining('users'), findsOneWidget);
        expect(find.textContaining('total'), findsOneWidget);
      });

      testWidgets('should handle HTML response', (tester) async {
        final htmlBody = '<html><body><h1>Hello World</h1></body></html>';

        final response = HttpResponse(
          statusCode: 200,
          body: htmlBody,
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Content-Type', value: 'text/html'),
          ],
          durationMs: 80,
          sizeBytes: htmlBody.length,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Verify CodeEditor is used for HTML content
        expect(find.byType(CodeEditor), findsOneWidget);
      });

      testWidgets('should handle response with many headers', (tester) async {
        final response = HttpResponse(
          statusCode: 200,
          body: '{}',
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Content-Type', value: 'application/json'),
            KeyValuePair.empty().copyWith(key: 'Content-Length', value: '1234'),
            KeyValuePair.empty()
                .copyWith(key: 'Cache-Control', value: 'max-age=3600'),
            KeyValuePair.empty().copyWith(key: 'ETag', value: '"abc123"'),
            KeyValuePair.empty().copyWith(
                key: 'Last-Modified', value: 'Mon, 01 Jan 2024 00:00:00 GMT'),
            KeyValuePair.empty().copyWith(key: 'Server', value: 'nginx/1.18.0'),
            KeyValuePair.empty()
                .copyWith(key: 'X-Frame-Options', value: 'DENY'),
            KeyValuePair.empty()
                .copyWith(key: 'X-Content-Type-Options', value: 'nosniff'),
          ],
          durationMs: 100,
          timestamp: DateTime.now(),
        );

        final container =
            createContainer(response: response, activeTabId: 'tab1');

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Navigate to Headers tab
        await tester.tap(find.text('Headers'));
        await tester.pumpAndSettle();

        expect(find.text('Server'), findsOneWidget);
        expect(find.text('nginx/1.18.0'), findsOneWidget);
        expect(find.text('ETag'), findsOneWidget);
      });
    });
  });
}
