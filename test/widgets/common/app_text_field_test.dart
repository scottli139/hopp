import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/theme/app_theme.dart';
import 'package:hopp/theme/app_theme_data.dart';
import 'package:hopp/widgets/common/app_text_field.dart';

/// AppTextField 规格测试。
///
/// 背景：旧实现用 `SizedBox(height:) + InputDecorator(isDense)` 控高，
/// 但 InputDecorator 的描边只包住「文字行高 + contentPadding」，不会撑满
/// 外层 SizedBox（渲染 28 但描边只有 ~16），且 widget test 量 render box
/// 量不出来。新实现用显式 Container 盒子，渲染盒 == 绘制盒，可测。
void main() {
  Widget wrap(Widget child, {bool dark = true}) {
    return MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))),
    );
  }

  group('AppTextField heights', () {
    testWidgets('default height is 32', (tester) async {
      await tester.pumpWidget(wrap(const AppTextField(hintText: 'URL')));
      expect(tester.getSize(find.byType(AppTextField)).height, 32);
    });

    testWidgets('compact height is 28', (tester) async {
      await tester
          .pumpWidget(wrap(const AppTextField(hintText: 'Key', compact: true)));
      expect(tester.getSize(find.byType(AppTextField)).height, 28);
    });

    testWidgets('explicit height wins over compact', (tester) async {
      await tester.pumpWidget(
          wrap(const AppTextField(hintText: 'F', compact: true, height: 30)));
      expect(tester.getSize(find.byType(AppTextField)).height, 30);
    });

    testWidgets('height with suffix stays at spec', (tester) async {
      await tester.pumpWidget(wrap(const AppTextField(
        compact: true,
        hintText: 'Value',
        suffix: Icon(Icons.visibility, size: 14),
      )));
      expect(tester.getSize(find.byType(AppTextField)).height, 28);
    });
  });

  group('AppTextField behavior', () {
    testWidgets('fieldKey reaches the inner TextField', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(wrap(AppTextField(
        fieldKey: const Key('f'),
        controller: controller,
      )));
      await tester.enterText(find.byKey(const Key('f')), 'abc');
      expect(controller.text, 'abc');
    });

    testWidgets('disabled reaches inner TextField and dims text',
        (tester) async {
      final controller = TextEditingController(text: 'Globals');
      addTearDown(controller.dispose);
      await tester.pumpWidget(wrap(AppTextField(
        fieldKey: const Key('f'),
        controller: controller,
        enabled: false,
      )));
      final field = tester.widget<TextField>(find.byKey(const Key('f')));
      expect(field.enabled, isFalse);
      final t = tester.element(find.byType(AppTextField)).appTheme;
      expect(field.style?.color, t.textTertiary);
    });

    testWidgets('focus switches border to brand 1.5', (tester) async {
      await tester.pumpWidget(wrap(const AppTextField(hintText: 'URL')));
      final t = tester.element(find.byType(AppTextField)).appTheme;
      Container box() => tester.widget<Container>(find.descendant(
            of: find.byType(AppTextField),
            matching: find.byType(Container),
          ));
      var decoration = box().decoration! as BoxDecoration;
      expect(decoration.border!.top.color, t.borderStrong);
      expect(decoration.border!.top.width, 1);

      await tester.tap(find.byType(AppTextField));
      await tester.pump();
      decoration = box().decoration! as BoxDecoration;
      expect(decoration.border!.top.color, t.brand);
      expect(decoration.border!.top.width, 1.5);
    });
  });
}
