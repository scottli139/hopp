import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/main.dart' as app;
import 'package:hopp/widgets/layout/sidebar.dart';
import 'package:hopp/widgets/layout/request_tabs.dart';
import 'package:hopp/widgets/request/request_editor.dart';
import 'package:hopp/widgets/request/response_viewer.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end HTTP request tests
///
/// These tests verify:
/// 1. App can create and send HTTP requests
/// 2. Network connectivity works (outbound connections)
/// 3. Response is correctly displayed
void main([List<String> args = const []]) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HTTP Request E2E Tests', () {
    testWidgets('should create request and verify UI layout', (tester) async {
      // Launch the app
      app.main([]);
      await tester.pumpAndSettle();

      // Verify app loaded with sidebar
      expect(find.byType(Sidebar), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);

      // Create a new collection
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Enter collection name
      await tester.enterText(
          find.byType(TextField).last, 'E2E Test Collection');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify collection created
      expect(find.text('E2E Test Collection'), findsOneWidget);

      // Open collection menu and add request
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Request'));
      await tester.pumpAndSettle();

      // Verify request tab opened
      expect(find.byType(RequestTabs), findsOneWidget);
      expect(find.text('New Request'), findsOneWidget);

      // Verify request editor is displayed
      expect(find.byType(RequestEditor), findsOneWidget);

      // Enter URL
      final urlField = find.byType(TextField).first;
      await tester.enterText(urlField, 'https://httpbin.org/get');
      await tester.pumpAndSettle();

      // Tap Send button
      await tester.tap(find.text('Send'));
      await tester.pump(const Duration(seconds: 1));

      // Wait for response (max 10 seconds)
      bool responseReceived = false;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));

        // Check if response info bar shows success
        final infoBar = find.textContaining('200');
        if (tester.any(infoBar)) {
          responseReceived = true;
          break;
        }

        // Check if error occurred
        final errorFinder = find.textContaining('error');
        if (tester.any(errorFinder)) {
          final errorText = tester.widget<Text>(errorFinder.first);
          fail('Request failed with error: ${errorText.data}');
        }
      }

      expect(responseReceived, isTrue,
          reason: 'Should receive HTTP 200 response');

      // Verify response viewer is displayed
      expect(find.byType(ResponseViewer), findsOneWidget);
    });

    testWidgets('should handle connection errors gracefully', (tester) async {
      app.main([]);
      await tester.pumpAndSettle();

      // Create collection and request
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Error Test');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Request'));
      await tester.pumpAndSettle();

      // Enter invalid URL
      final urlField = find.byType(TextField).first;
      await tester.enterText(urlField, 'http://localhost:99999');
      await tester.pumpAndSettle();

      // Send request
      await tester.tap(find.text('Send'));
      await tester.pump(const Duration(seconds: 3));

      // Verify error is displayed (either timeout or connection error)
      final errorFinder = find.byIcon(Icons.error_outline);
      expect(errorFinder, findsOneWidget);
    });
  });
}
