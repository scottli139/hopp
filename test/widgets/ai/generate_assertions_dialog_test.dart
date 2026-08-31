import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';
import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/http_response.dart';
import 'package:hopp/models/request_tab.dart';
import 'package:hopp/providers/ai/ai_provider.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/request/request_response_provider.dart';
import 'package:hopp/providers/request/request_tab_provider.dart';
import 'package:hopp/providers/settings/settings_provider.dart';
import 'package:hopp/services/ai/ai_models.dart';
import 'package:hopp/widgets/common/app_controls.dart';
import 'package:hopp/widgets/request/assertion_editor.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/service_mocks.mocks.dart';

class FakeGenerateAssertionsNotifier extends GenerateAssertionsNotifier {
  FakeGenerateAssertionsNotifier(super.ref);

  final items = const [
    AiAssertionDraft(
      target: AssertionTarget.status,
      targetArg: '',
      operator: AssertionOperator.equals,
      expected: '200',
    ),
    AiAssertionDraft(
      target: AssertionTarget.jsonPath,
      targetArg: r'$.data.id',
      operator: AssertionOperator.exists,
      expected: '',
    ),
    AiAssertionDraft(
      target: AssertionTarget.jsonPath,
      targetArg: r'$.data.name',
      operator: AssertionOperator.equals,
      expected: '张三',
    ),
  ];
  final discarded = 2;

  @override
  Future<void> generate({
    required String method,
    required String url,
    required String? responseBody,
  }) async {
    state = const AiOpState<AiAssertionParseResult>.loading();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = AiOpState<AiAssertionParseResult>.success(
      AiAssertionParseResult(items: items, discarded: discarded),
    );
  }
}

void main() {
  group('GenerateAssertionsButton / dialog', () {
    late MockStorageService mockStorageService;

    final response = HttpResponse(
      statusCode: 200,
      statusText: 'OK',
      body: '{"data":{"id":42,"name":"张三"}}',
      sizeBytes: 32,
      timestamp: DateTime(2026, 8, 31),
    );
    final tab = RequestTab(
      id: 'tab1',
      request: HttpRequest.empty().copyWith(
        url: 'https://api.example.com/users',
      ),
    );

    setUp(() {
      mockStorageService = MockStorageService();
      when(mockStorageService.getSettings()).thenAnswer(
        (_) async => const AppSettings(aiEnabled: true, aiModel: 'qwen2.5:7b'),
      );
      when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});
    });

    ProviderContainer buildContainer({
      required HttpResponse? currentResponse,
    }) {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
          currentResponseProvider.overrideWithValue(currentResponse),
          activeTabProvider.overrideWithValue(tab),
          generateAssertionsProvider
              .overrideWith((ref) => FakeGenerateAssertionsNotifier(ref)),
        ],
      );
      // 预触发 settings 加载，避免门控读到 loading 态
      container.read(settingsProvider);
      return container;
    }

    Future<void> pumpEditor(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AssertionEditor(
                assertions: [],
                onChanged: _noopOnChanged,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('AI 生成'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('generate_assertions_dialog')),
        findsOneWidget,
      );
    }

    testWidgets('renders generated list and discarded warning', (tester) async {
      final container = buildContainer(currentResponse: response);
      addTearDown(container.dispose);
      await pumpEditor(tester, container);
      await openDialog(tester);

      expect(find.text('基于最近一次响应生成 · 已选 3/3 条'), findsOneWidget);
      expect(find.text('添加 3 条'), findsOneWidget);
      expect(find.text('已丢弃 2 条不合规建议'), findsOneWidget);
      expect(find.text('张三'), findsOneWidget);

      // 行内值通过 TextField controller 校验（hint 与值同文本时会
      // 产生多个 Text 匹配，不能直接 find.text）
      final values = [
        for (final f in tester.widgetList<TextField>(find.byType(TextField)))
          f.controller!.text,
      ];
      expect(
        values,
        ['', '200', r'$.data.id', '', r'$.data.name', '张三'],
      );
    });

    testWidgets('toggling checkbox updates count and confirm label',
        (tester) async {
      final container = buildContainer(currentResponse: response);
      addTearDown(container.dispose);
      await pumpEditor(tester, container);
      await openDialog(tester);

      await tester.tap(find.byType(AppCheckbox).first);
      await tester.pump();
      expect(find.text('基于最近一次响应生成 · 已选 2/3 条'), findsOneWidget);
      expect(find.text('添加 2 条'), findsOneWidget);

      await tester.tap(find.byType(AppCheckbox).first);
      await tester.pump();
      expect(find.text('基于最近一次响应生成 · 已选 3/3 条'), findsOneWidget);
      expect(find.text('添加 3 条'), findsOneWidget);
    });

    testWidgets('confirm appends selected rules via onChanged', (tester) async {
      final container = buildContainer(currentResponse: response);
      addTearDown(container.dispose);

      final captured = <AssertionRule>[];
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AssertionEditor(
                assertions: const [],
                onChanged: (list) => captured
                  ..clear()
                  ..addAll(list),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openDialog(tester);

      // 取消勾选第 3 条，只添加前 2 条
      await tester.tap(find.byType(AppCheckbox).at(2));
      await tester.pump();
      await tester.tap(find.text('添加 2 条'));
      await tester.pumpAndSettle();

      expect(captured, hasLength(2));
      expect(captured[0].target, AssertionTarget.status);
      expect(captured[0].operator, AssertionOperator.equals);
      expect(captured[0].expected, '200');
      expect(captured[0].id, isNotEmpty);
      expect(captured[1].target, AssertionTarget.jsonPath);
      expect(captured[1].targetArg, r'$.data.id');
      expect(captured[1].operator, AssertionOperator.exists);
      expect(captured[1].expected, isEmpty);

      expect(
        find.byKey(const Key('generate_assertions_dialog')),
        findsNothing,
      );
    });

    testWidgets('gate: shows snackbar when no response sample', (tester) async {
      final container = buildContainer(currentResponse: null);
      addTearDown(container.dispose);
      await pumpEditor(tester, container);

      await tester.tap(find.text('AI 生成'));
      await tester.pumpAndSettle();

      expect(find.text('请先在 Tests 运行或发送请求'), findsOneWidget);
      expect(
        find.byKey(const Key('generate_assertions_dialog')),
        findsNothing,
      );
    });
  });
}

void _noopOnChanged(List<AssertionRule> rules) {}
