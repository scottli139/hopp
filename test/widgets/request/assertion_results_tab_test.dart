import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/http_response.dart';
import 'package:hopp/models/request_tab.dart';
import 'package:hopp/providers/providers.dart';
import 'package:hopp/services/assertion/assertion_engine.dart';
import 'package:hopp/theme/app_theme_data.dart';
import 'package:hopp/widgets/request/response_viewer.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/test_app.dart';
import '../../mocks/service_mocks.mocks.dart';

void main() {
  group('ResponseViewer Tests 页签（F4.1）', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      when(mockStorageService.getCollections()).thenAnswer((_) async => []);
      when(mockStorageService.getRequests()).thenAnswer((_) async => []);
    });

    Widget buildTestWidget({required ProviderContainer container}) {
      return UncontrolledProviderScope(
        container: container,
        child: hoppTestApp(
          home: const Scaffold(
            body: ResponseViewer(),
          ),
        ),
      );
    }

    AssertionRule rule({
      required String id,
      bool enabled = true,
      AssertionTarget target = AssertionTarget.status,
      String targetArg = '',
      AssertionOperator operator = AssertionOperator.equals,
      String expected = '200',
    }) =>
        AssertionRule(
          id: id,
          enabled: enabled,
          target: target,
          targetArg: targetArg,
          operator: operator,
          expected: expected,
        );

    /// 组装容器：活动 Tab + 响应 + 断言求值结果
    ProviderContainer createContainer({
      required List<AssertionRule> assertions,
      required List<AssertionResult> results,
      String activeTabId = 'tab1',
      Map<String, List<AssertionResult>>? allResults,
      HttpResponse? response,
      Map<String, String>? variables,
    }) {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
          if (variables != null)
            resolvedVariablesProvider.overrideWithValue(variables),
        ],
      );

      container.read(requestTabProvider.notifier).state = [
        RequestTab(
          id: activeTabId,
          request: HttpRequest.empty().copyWith(
            id: 'req_$activeTabId',
            name: 'Test',
            assertions: assertions,
          ),
        ),
      ];
      container.read(activeTabIdProvider.notifier).state = activeTabId;
      if (response != null) {
        container.read(requestResponseProvider.notifier).state = {
          activeTabId: response,
        };
      }
      container.read(assertionResultsProvider.notifier).state =
          allResults ?? {activeTabId: results};
      return container;
    }

    HttpResponse okResponse() => HttpResponse(
          statusCode: 200,
          statusText: 'OK',
          body: '{"ok":true}',
          durationMs: 100,
          sizeBytes: 128,
          timestamp: DateTime.now(),
        );

    testWidgets('无断言配置时显示空态灰字，meta 栏与页签均无徽标', (tester) async {
      final container = createContainer(
        assertions: const [],
        results: const [],
        response: okResponse(),
      );

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tests'));
      await tester.pumpAndSettle();

      expect(
        find.text('No assertions configured — add them in the Assertions tab.'),
        findsOneWidget,
      );
      expect(find.textContaining('passed'), findsNothing);
    });

    testWidgets('有断言但未发送过时显示灰字提示', (tester) async {
      final container = createContainer(
        assertions: [rule(id: 'a1')],
        results: const [],
        response: okResponse(),
        allResults: const {}, // 本轮无求值结果
      );

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tests'));
      await tester.pumpAndSettle();

      expect(
        find.text('Not run yet — send the request to evaluate assertions.'),
        findsOneWidget,
      );
    });

    testWidgets('其他 Tab 的求值结果不会串显到当前 Tab', (tester) async {
      final container = createContainer(
        assertions: [rule(id: 'a1')],
        results: const [],
        response: okResponse(),
        allResults: {
          'other-tab': [
            AssertionResult(
              rule: rule(id: 'a1'),
              outcome: AssertionOutcome.passed,
              actual: '200',
            ),
          ],
        },
      );

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tests'));
      await tester.pumpAndSettle();

      expect(
        find.text('Not run yet — send the request to evaluate assertions.'),
        findsOneWidget,
      );
    });

    testWidgets('渲染 passed / failed / skipped 行与失败明细', (tester) async {
      final rules = [
        rule(id: 'a1'),
        rule(
          id: 'a2',
          target: AssertionTarget.jsonPath,
          targetArg: r'$.data.token',
          operator: AssertionOperator.exists,
          expected: '',
        ),
        rule(
          id: 'a3',
          enabled: false,
          target: AssertionTarget.responseTime,
          operator: AssertionOperator.lt,
          expected: '800',
        ),
      ];
      final container = createContainer(
        assertions: rules,
        results: [
          AssertionResult(
            rule: rules[0],
            outcome: AssertionOutcome.passed,
            actual: '200',
          ),
          const AssertionResult(
            rule: AssertionRule(
              id: 'a2',
              target: AssertionTarget.jsonPath,
              targetArg: r'$.data.token',
              operator: AssertionOperator.exists,
            ),
            outcome: AssertionOutcome.failed,
            message: 'path not found',
          ),
          AssertionResult(
            rule: rules[2],
            outcome: AssertionOutcome.skipped,
          ),
        ],
        response: okResponse(),
      );

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tests'));
      await tester.pumpAndSettle();

      // 三种结果图标（限定在 Tests 页签列表内，meta 栏徽标也有同图标）
      final testsList = find.byType(ListView);
      expect(
        find.descendant(of: testsList, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: testsList, matching: find.byIcon(Icons.close)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: testsList, matching: find.byIcon(Icons.remove)),
        findsOneWidget,
      );
      // 禁用行标注
      expect(find.textContaining('· disabled'), findsOneWidget);
      // 失败行就地展开 EXPECTED / ACTUAL
      expect(find.text('EXPECTED'), findsOneWidget);
      expect(find.text('ACTUAL'), findsOneWidget);
      expect(find.text(r'value at $.data.token'), findsOneWidget);
      expect(find.text('path not found'), findsOneWidget);
    });

    testWidgets('meta 栏展示 n/m passed 徽标：有失败为红色，skipped 不计入分母', (tester) async {
      final rules = [
        rule(id: 'a1'),
        rule(
          id: 'a2',
          target: AssertionTarget.jsonPath,
          targetArg: r'$.data.token',
          operator: AssertionOperator.exists,
        ),
        rule(
          id: 'a3',
          enabled: false,
          target: AssertionTarget.responseTime,
          operator: AssertionOperator.lt,
          expected: '800',
        ),
      ];
      final container = createContainer(
        assertions: rules,
        results: [
          AssertionResult(
            rule: rules[0],
            outcome: AssertionOutcome.passed,
            actual: '200',
          ),
          AssertionResult(
            rule: rules[1],
            outcome: AssertionOutcome.failed,
            message: 'path not found',
          ),
          AssertionResult(
            rule: rules[2],
            outcome: AssertionOutcome.skipped,
          ),
        ],
        response: okResponse(),
      );

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      // skipped 不计入分母：1/2
      expect(find.text('1/2 passed'), findsOneWidget);
      final badge = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('1/2 passed'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (badge.decoration as BoxDecoration).color,
        AppThemeData.light.errorSoft,
      );
      // Tests 页签计数徽标（有失败红色）
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('全部通过时徽标为绿色', (tester) async {
      final rules = [rule(id: 'a1'), rule(id: 'a2', expected: '201')];
      final container = createContainer(
        assertions: rules,
        results: [
          AssertionResult(
            rule: rules[0],
            outcome: AssertionOutcome.passed,
            actual: '200',
          ),
          AssertionResult(
            rule: rules[1],
            outcome: AssertionOutcome.passed,
            actual: '200',
          ),
        ],
        response: okResponse(),
      );

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(find.text('2/2 passed'), findsOneWidget);
      final badge = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('2/2 passed'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        (badge.decoration as BoxDecoration).color,
        AppThemeData.light.successSoft,
      );
    });

    testWidgets('通过的 {{var}} 规则展示 RESOLVED 插值结果', (tester) async {
      final rules = [
        rule(
          id: 'a1',
          target: AssertionTarget.jsonPath,
          targetArg: r'$.data.deviceSn',
          operator: AssertionOperator.equals,
          expected: '{{deviceSn}}',
        ),
      ];
      final container = createContainer(
        assertions: rules,
        results: [
          AssertionResult(
            rule: rules[0],
            outcome: AssertionOutcome.passed,
            actual: '123456',
          ),
        ],
        response: okResponse(),
        variables: {'deviceSn': '123456'},
      );

      await tester.pumpWidget(buildTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tests'));
      await tester.pumpAndSettle();

      expect(find.text('RESOLVED'), findsOneWidget);
      expect(find.text('"123456"'), findsOneWidget);
    });
  });
}
