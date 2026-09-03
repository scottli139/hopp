import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/theme/app_theme.dart';
import 'package:hopp/theme/app_theme_data.dart';
import 'package:hopp/widgets/common/app_segmented_control.dart';

import '../../helpers/test_app.dart';

/// AppSegmentedControl 规格测试。
void main() {
  const items = [
    AppSegmentedItem(
      value: 'system',
      icon: Icons.brightness_auto_outlined,
      tooltip: 'System',
    ),
    AppSegmentedItem(
      value: 'light',
      icon: Icons.light_mode_outlined,
      tooltip: 'Light',
    ),
    AppSegmentedItem(
      value: 'dark',
      icon: Icons.dark_mode_outlined,
      tooltip: 'Dark',
    ),
  ];

  Widget wrap(Widget child, {bool dark = false}) {
    return hoppTestApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  Widget control({String value = 'system', ValueChanged<String>? onChanged}) {
    return AppSegmentedControl<String>(
      items: items,
      value: value,
      onChanged: onChanged ?? (_) {},
    );
  }

  group('AppSegmentedControl rendering', () {
    testWidgets('renders all items at spec size', (tester) async {
      await tester.pumpWidget(wrap(control()));

      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

      // 容器高 24；宽 = 3 段 × 28 + 内 padding 2×2
      final size = tester.getSize(find.byType(AppSegmentedControl<String>));
      expect(size.height, 24);
      expect(size.width, 3 * 28 + 4);
    });

    testWidgets('selected segment icon uses brand color', (tester) async {
      await tester.pumpWidget(wrap(control(value: 'dark')));
      final t =
          tester.element(find.byType(AppSegmentedControl<String>)).appTheme;

      final selected =
          tester.widget<Icon>(find.byIcon(Icons.dark_mode_outlined));
      expect(selected.color, t.brand);

      final unselected =
          tester.widget<Icon>(find.byIcon(Icons.light_mode_outlined));
      expect(unselected.color, t.textTertiary);
    });

    testWidgets('tooltips are exposed', (tester) async {
      await tester.pumpWidget(wrap(control()));
      expect(find.byTooltip('System'), findsOneWidget);
      expect(find.byTooltip('Light'), findsOneWidget);
      expect(find.byTooltip('Dark'), findsOneWidget);
    });
  });

  group('AppSegmentedControl behavior', () {
    testWidgets('tap reports the item value', (tester) async {
      String? tapped;
      await tester.pumpWidget(wrap(control(onChanged: (v) => tapped = v)));

      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      expect(tapped, 'dark');

      await tester.tap(find.byIcon(Icons.brightness_auto_outlined));
      expect(tapped, 'system');
    });
  });
}
