import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/http_response.dart';
import 'package:hopp/models/request_tab.dart';
import 'package:hopp/providers/ai/ai_provider.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/request/request_response_provider.dart';
import 'package:hopp/providers/request/request_tab_provider.dart';
import 'package:hopp/providers/settings/settings_provider.dart';
import 'package:hopp/widgets/ai/explain_response_dialog.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/test_app.dart';
import '../../mocks/service_mocks.mocks.dart';

class FakeExplainNotifier extends ExplainNotifier {
  FakeExplainNotifier(super.ref);

  String resultText = '这是 AI 生成的解释文本';
  String? errorText;

  @override
  Future<void> explain({
    required int statusCode,
    required String statusText,
    required String body,
  }) async {
    state = const AiOpState<String>.loading();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = errorText != null
        ? AiOpState<String>.error(errorText!)
        : AiOpState<String>.success(resultText);
  }
}

void main() {
  group('ExplainResponseButton / ExplainResponseDialog', () {
    late MockStorageService mockStorageService;
    late AppSettings settings;

    final response = HttpResponse(
      statusCode: 200,
      statusText: 'OK',
      body: '{"id":42}',
      sizeBytes: 10,
      timestamp: DateTime(2026, 8, 31),
    );
    final tab = RequestTab(
      id: 'tab1',
      request: HttpRequest.empty().copyWith(
        url: 'https://api.example.com/users',
        method: HttpMethod.post,
      ),
    );

    setUp(() {
      mockStorageService = MockStorageService();
      settings = const AppSettings(aiEnabled: true, aiModel: 'qwen2.5:7b');
      when(mockStorageService.getSettings()).thenAnswer((_) async => settings);
      when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});
    });

    ProviderContainer buildContainer({
      required FakeExplainNotifier Function(Ref) create,
      HttpResponse? currentResponse,
    }) {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
          currentResponseProvider.overrideWithValue(currentResponse),
          activeTabProvider.overrideWithValue(tab),
          explainProvider.overrideWith(create),
        ],
      );
      // 预触发 settings 加载，避免门控读到 loading 态
      container.read(settingsProvider);
      return container;
    }

    Future<void> tapEntry(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Explain Response'));
      await tester.pump();
    }

    testWidgets('success state shows result text and actions', (tester) async {
      final container = buildContainer(
        create: FakeExplainNotifier.new,
        currentResponse: response,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: hoppTestApp(
            home: const Scaffold(body: ExplainResponseButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapEntry(tester);
      await tester.pumpAndSettle();

      expect(find.text('Explain Response'), findsWidgets);
      expect(find.text('这是 AI 生成的解释文本'), findsOneWidget);
      expect(find.text('Regenerate'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('loading state shows spinner hint', (tester) async {
      final container = buildContainer(
        create: FakeExplainNotifier.new,
        currentResponse: response,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: hoppTestApp(
            home: const Scaffold(body: ExplainResponseButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapEntry(tester);
      await tester.pump(); // postFrame 触发 explain → loading
      await tester.pump(); // loading 状态重建上树

      expect(
        find.text('Explaining... (local models may take 10–30 seconds)'),
        findsOneWidget,
      );

      // 冲刷 fake 的延迟 future，避免遗留 pending timer
      await tester.pumpAndSettle();
    });

    testWidgets('error state shows error message and retry button',
        (tester) async {
      final container = buildContainer(
        create: (ref) => FakeExplainNotifier(ref)..errorText = '未检测到本地模型服务',
        currentResponse: response,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: hoppTestApp(
            home: const Scaffold(body: ExplainResponseButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapEntry(tester);
      await tester.pumpAndSettle();

      expect(find.text('未检测到本地模型服务'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('gate: shows snackbar when AI is not enabled', (tester) async {
      settings = const AppSettings(); // aiEnabled = false, model = ''
      final container = buildContainer(
        create: FakeExplainNotifier.new,
        currentResponse: response,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: hoppTestApp(
            home: const Scaffold(body: ExplainResponseButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapEntry(tester);
      await tester.pumpAndSettle();

      expect(find.text('Local AI is not enabled or no model is configured'),
          findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.byKey(const Key('explain_response_dialog')), findsNothing);
    });

    testWidgets('gate: shows snackbar when no response to explain',
        (tester) async {
      final container = buildContainer(
        create: FakeExplainNotifier.new,
        currentResponse: null,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: hoppTestApp(
            home: const Scaffold(body: ExplainResponseButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapEntry(tester);
      await tester.pumpAndSettle();

      expect(find.text('No response to explain'), findsOneWidget);
    });
  });
}
