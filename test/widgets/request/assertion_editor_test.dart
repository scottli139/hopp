import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/widgets/common/app_controls.dart';
import 'package:hopp/widgets/common/app_popup_menu.dart';
import 'package:hopp/widgets/common/app_text_field.dart';
import 'package:hopp/widgets/request/assertion_editor.dart';

void main() {
  group('AssertionEditor', () {
    AssertionRule buildRule({
      String id = 'rule-1',
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

    /// 模拟真实宿主（request_editor）：onChanged 立即把新列表写回状态并重建
    Widget buildHarness(
      List<AssertionRule> assertions,
      void Function(List<AssertionRule>) onChanged,
    ) {
      return MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AssertionEditor(
                assertions: assertions,
                onChanged: (updated) {
                  onChanged(updated);
                  setState(() => assertions = updated);
                },
              );
            },
          ),
        ),
      );
    }

    testWidgets('空态渲染占位文案与 Add 按钮', (tester) async {
      final captured = <List<AssertionRule>>[];
      await tester.pumpWidget(buildHarness([], captured.add));
      await tester.pumpAndSettle();

      expect(find.text('No assertions yet'), findsOneWidget);
      expect(find.text('Add assertion'), findsOneWidget);
      expect(find.text('Response assertions'), findsOneWidget);
      expect(
          find.textContaining('Evaluated after every send.'), findsOneWidget);
      expect(
        find.textContaining('Operators are filtered by target'),
        findsOneWidget,
      );
    });

    testWidgets('Add assertion 追加默认规则行', (tester) async {
      final captured = <List<AssertionRule>>[];
      await tester.pumpWidget(buildHarness([], captured.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add assertion'));
      await tester.pumpAndSettle();

      expect(captured.last, hasLength(1));
      final rule = captured.last.single;
      expect(rule.target, AssertionTarget.status);
      expect(rule.operator, AssertionOperator.equals);
      expect(rule.enabled, isTrue);
      // 表格表头出现
      expect(find.text('TARGET'), findsOneWidget);
      expect(find.text('NAME / PATH'), findsOneWidget);
      expect(find.text('OPERATOR'), findsOneWidget);
      expect(find.text('EXPECTED'), findsOneWidget);
    });

    testWidgets('输入即提交：Name/Path 与 Expected 无需回车生效', (tester) async {
      final captured = <List<AssertionRule>>[];
      await tester.pumpWidget(buildHarness([
        buildRule(
          target: AssertionTarget.header,
          operator: AssertionOperator.contains,
          targetArg: 'Content-Type',
          expected: 'application/json',
        ),
      ], captured.add));
      await tester.pumpAndSettle();

      final fields = find.byType(AppTextField);
      expect(fields, findsNWidgets(2));

      await tester.enterText(fields.at(0), 'X-Request-Id');
      await tester.pump();
      expect(captured.last.single.targetArg, 'X-Request-Id');

      await tester.enterText(fields.at(1), 'text/plain');
      await tester.pump();
      expect(captured.last.single.expected, 'text/plain');
    });

    testWidgets('禁用行：勾选框关闭后规则 disabled 且行透明度 55%', (tester) async {
      final captured = <List<AssertionRule>>[];
      await tester.pumpWidget(buildHarness([buildRule()], captured.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppCheckbox));
      await tester.pump();

      expect(captured.last.single.enabled, isFalse);
      final row = tester.widget<Opacity>(
        find.byKey(const Key('assertion_row_rule-1')),
      );
      expect(row.opacity, 0.55);
    });

    testWidgets('删除行：点击删除按钮移除规则并回到空态', (tester) async {
      final captured = <List<AssertionRule>>[];
      await tester.pumpWidget(buildHarness([buildRule()], captured.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(captured.last, isEmpty);
      expect(find.text('No assertions yet'), findsOneWidget);
    });

    testWidgets('Status code 目标的操作符菜单只有比较类', (tester) async {
      final captured = <List<AssertionRule>>[];
      await tester.pumpWidget(buildHarness([buildRule()], captured.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppPopupSelect<AssertionOperator>));
      await tester.pumpAndSettle();

      expect(find.text('equals'), findsWidgets);
      expect(find.text('<'), findsOneWidget);
      // status 不支持 contains / exists / regex
      expect(find.text('contains'), findsNothing);
      expect(find.text('regex'), findsNothing);
      // hint 里有一个 exists 代码片，但不应有菜单项
      expect(find.text('exists'), findsOneWidget);
    });

    testWidgets('切换 Target 后 Operator 列表按目标过滤且可正确提交', (tester) async {
      final captured = <List<AssertionRule>>[];
      await tester.pumpWidget(buildHarness([buildRule()], captured.add));
      await tester.pumpAndSettle();

      // status → header：equals 对 header 合法，操作符保留
      await tester.tap(find.byType(AppPopupSelect<AssertionTarget>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Header').last);
      await tester.pumpAndSettle();
      expect(captured.last.single.target, AssertionTarget.header);
      expect(captured.last.single.operator, AssertionOperator.equals);

      // header 操作符菜单含 contains / exists / regex
      await tester.tap(find.byType(AppPopupSelect<AssertionOperator>));
      await tester.pumpAndSettle();
      expect(find.text('contains'), findsOneWidget);
      expect(find.text('regex'), findsOneWidget);

      // 选择 exists 后 Expected 列变为 "—" 占位
      await tester.tap(find.text('exists').last);
      await tester.pumpAndSettle();
      expect(captured.last.single.operator, AssertionOperator.exists);
      expect(
        find.byKey(const Key('assertion_expected_dash_rule-1')),
        findsOneWidget,
      );
    });

    testWidgets('切换 Target 后原操作符不兼容时回退到目标第一个操作符', (tester) async {
      final captured = <List<AssertionRule>>[];
      // status + < 500
      await tester.pumpWidget(buildHarness([
        buildRule(operator: AssertionOperator.lt, expected: '500'),
      ], captured.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppPopupSelect<AssertionTarget>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Body text').last);
      await tester.pumpAndSettle();

      // body 操作符集第一个为 contains（不支持 <，回退）
      expect(captured.last.single.target, AssertionTarget.body);
      expect(captured.last.single.operator, AssertionOperator.contains);
    });

    testWidgets('Name/Path 列仅 Header / JSONPath 可编辑，其余目标显示占位', (tester) async {
      final captured = <List<AssertionRule>>[];
      await tester.pumpWidget(buildHarness([buildRule()], captured.add));
      await tester.pumpAndSettle();

      // status：arg 列占位、expected 列可输入
      expect(
        find.byKey(const Key('assertion_arg_dash_rule-1')),
        findsOneWidget,
      );
      expect(find.byType(AppTextField), findsOneWidget);

      // → JSONPath：arg 列变为输入框
      await tester.tap(find.byType(AppPopupSelect<AssertionTarget>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('JSONPath').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('assertion_arg_dash_rule-1')), findsNothing);
      expect(find.byType(AppTextField), findsNWidgets(2));

      await tester.enterText(find.byType(AppTextField).at(0), r'$.data.token');
      await tester.pump();
      expect(captured.last.single.targetArg, r'$.data.token');
    });
  });
}
