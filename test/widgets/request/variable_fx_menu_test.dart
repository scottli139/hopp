import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/providers/providers.dart';
import 'package:hopp/services/variable_resolver.dart';
import 'package:hopp/widgets/request/variable_fx_menu.dart';

void main() {
  Widget buildMenu(TextEditingController controller) {
    return ProviderScope(
      overrides: [
        resolvedVariablesProvider.overrideWithValue(const {}),
        variableResolverProvider.overrideWithValue(VariableResolver()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: VariableFxMenu(
              controller: controller,
              onInserted: () {},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('变量预览与转换函数'));
    await tester.pumpAndSettle();
  }

  group('VariableFxMenu 动态变量直达（F8.5）', () {
    testWidgets('菜单含 INSERT DYNAMIC VARIABLE 区与全部动态变量', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(buildMenu(controller));
      await openMenu(tester);

      expect(find.text('INSERT DYNAMIC VARIABLE'), findsOneWidget);
      expect(find.text(r'$timestamp'), findsOneWidget);
      expect(find.text(r'$timestampMs'), findsOneWidget);
      expect(find.text(r'$isoTimestamp'), findsOneWidget);
      expect(find.text(r'$randomUUID'), findsOneWidget);
      expect(find.text(r'$randomInt'), findsOneWidget);
      // 时间函数出现在 INSERT TRANSFORM 区
      expect(find.text('date_add(offset)'), findsOneWidget);
      expect(find.text('date_floor(unit)'), findsOneWidget);
    });

    testWidgets('点击动态变量项一键插入对应占位符', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(buildMenu(controller));
      await openMenu(tester);

      await tester.tap(find.text(r'$timestampMs'));
      await tester.pumpAndSettle();
      expect(controller.text, r'{{$timestampMs}}');
    });
  });

  group('VariableFxMenu 时间函数参数表单（F8.5）', () {
    testWidgets('date_floor：默认 day，插入生成管道片段', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(buildMenu(controller));
      await openMenu(tester);

      await tester.tap(find.text('date_floor(unit)'));
      await tester.pumpAndSettle();
      expect(find.text('date_floor(unit)'), findsOneWidget); // 对话框标题

      await tester.tap(find.text('插入'));
      await tester.pumpAndSettle();
      expect(controller.text, ' | date_floor(day)');
    });

    testWidgets('date_add：合法 offset 才可插入', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(buildMenu(controller));
      await openMenu(tester);

      await tester.tap(find.text('date_add(offset)'));
      await tester.pumpAndSettle();

      // 非法值：插入按钮不可用
      await tester.enterText(find.byType(TextField).first, '7');
      await tester.pumpAndSettle();
      await tester.tap(find.text('插入'));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);

      // 合法值：插入成功
      await tester.enterText(find.byType(TextField).first, '-7d');
      await tester.pumpAndSettle();
      await tester.tap(find.text('插入'));
      await tester.pumpAndSettle();
      expect(controller.text, ' | date_add(-7d)');
    });

    testWidgets('手输 | 后插入不重复管道（试用反馈回归）', (tester) async {
      final controller = TextEditingController(text: '{{\$timestampMs|}}');
      controller.selection = const TextSelection.collapsed(offset: 15);
      addTearDown(controller.dispose);
      await tester.pumpWidget(buildMenu(controller));
      await openMenu(tester);

      await tester.tap(find.text('date_floor(unit)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('插入'));
      await tester.pumpAndSettle();

      // 光标前已有 |，插入片段复用已有管道而非再加一个
      expect(controller.text, '{{\$timestampMs| date_floor(day)}}');
    });

    testWidgets('非折叠选区被插入片段替换（试用反馈回归）', (tester) async {
      final controller = TextEditingController(text: '{{token}}');
      // 选中末尾的 }}
      controller.selection = const TextSelection(baseOffset: 7, extentOffset: 9);
      addTearDown(controller.dispose);
      await tester.pumpWidget(buildMenu(controller));
      await openMenu(tester);

      await tester.tap(find.text('md5').last);
      await tester.pumpAndSettle();

      expect(controller.text, '{{token | md5');
    });
  });
}
