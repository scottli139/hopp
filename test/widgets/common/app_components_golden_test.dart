import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/theme/app_theme.dart';
import 'package:hopp/widgets/common/app_badge.dart';
import 'package:hopp/widgets/common/app_button.dart';
import 'package:hopp/widgets/common/app_card.dart';
import 'package:hopp/widgets/common/app_controls.dart';
import 'package:hopp/widgets/common/app_dialog.dart';
import 'package:hopp/widgets/common/app_divider.dart';
import 'package:hopp/widgets/common/app_empty_state.dart';
import 'package:hopp/widgets/common/app_popup_menu.dart';
import 'package:hopp/widgets/common/app_segmented_control.dart';
import 'package:hopp/widgets/common/app_tabs.dart';
import 'package:hopp/widgets/common/app_text_field.dart';

import '../../helpers/test_app.dart';

/// 设计系统组件 Golden 测试（亮/暗双主题）。
///
/// 更新基线图：fvm flutter test test/widgets/common/ --update-goldens
/// 样式回归时本文件变红，先对照 goldens/ 确认是预期变化再更新。
void main() {
  Widget wrap(Widget child,
      {required bool dark, Size size = const Size(420, 320)}) {
    return hoppTestApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> expectGolden(
    WidgetTester tester,
    Widget child,
    String name, {
    Size size = const Size(420, 320),
  }) async {
    for (final dark in [false, true]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(wrap(child, dark: dark, size: size));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${name}_${dark ? 'dark' : 'light'}.png'),
      );
    }
  }

  group('AppButton', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                AppButton.primary(label: 'Send', onPressed: () {}),
                const SizedBox(width: 12),
                AppButton.secondary(label: 'Save', onPressed: () {}),
                const SizedBox(width: 12),
                AppButton.ghost(label: 'Cancel', onPressed: () {}),
                const SizedBox(width: 12),
                AppButton.danger(label: 'Delete', onPressed: () {}),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                AppButton.primary(
                  label: 'Send',
                  icon: Icons.send,
                  size: AppButtonSize.small,
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                AppButton.secondary(
                  label: 'Small',
                  size: AppButtonSize.small,
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                const AppButton.primary(label: 'Disabled', onPressed: null),
              ]),
            ],
          ),
        ),
        'app_button',
        size: const Size(560, 320),
      );
    });
  });

  group('AppIconButton', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            AppIconButton(icon: Icons.add, onPressed: () {}),
            const SizedBox(width: 12),
            AppIconButton(
              icon: Icons.save,
              bordered: true,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            AppIconButton(
              icon: Icons.delete_outline,
              color: Colors.red,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            const AppIconButton(icon: Icons.more_horiz, onPressed: null),
          ]),
        ),
        'app_icon_button',
        size: const Size(420, 120),
      );
    });
  });

  group('AppTabs', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        Column(
          children: [
            AppTabs(
              tabs: const [
                AppTabItem(icon: Icons.tune, label: 'Params', count: 3),
                AppTabItem(icon: Icons.http, label: 'Headers', count: 12),
                AppTabItem(icon: Icons.code, label: 'Body', dot: true),
                AppTabItem(icon: Icons.lock_outline, label: 'Auth'),
              ],
              selectedIndex: 1,
              onChanged: (_) {},
            ),
          ],
        ),
        'app_tabs',
        size: const Size(420, 120),
      );
    });
  });

  group('AppDialog', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        AppDialog(
          title: 'Delete Collection',
          actions: [
            AppButton.ghost(label: 'Cancel', onPressed: () {}),
            AppButton.danger(label: 'Delete', onPressed: () {}),
          ],
          child: const Text('This action cannot be undone.'),
        ),
        'app_dialog',
        size: const Size(480, 260),
      );
    });
  });

  group('AppSwitch & AppCheckbox', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                AppSwitch(value: true, onChanged: (_) {}),
                const SizedBox(width: 16),
                AppSwitch(value: false, onChanged: (_) {}),
                const SizedBox(width: 16),
                const AppSwitch(value: true, onChanged: null),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                AppCheckbox(value: true, onChanged: (_) {}),
                const SizedBox(width: 16),
                AppCheckbox(value: false, onChanged: (_) {}),
                const SizedBox(width: 16),
                AppCheckbox(
                  value: true,
                  label: 'Enabled',
                  onChanged: (_) {},
                ),
              ]),
            ],
          ),
        ),
        'app_controls',
        size: const Size(420, 160),
      );
    });
  });

  group('AppSegmentedControl', () {
    testWidgets('golden', (tester) async {
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
      await expectGolden(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSegmentedControl<String>(
                items: items,
                value: 'system',
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              AppSegmentedControl<String>(
                items: items,
                value: 'dark',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        'app_segmented_control',
        size: const Size(200, 120),
      );
    });
  });

  group('AppCard', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              AppCard(child: Text('Standard card')),
              SizedBox(height: 16),
              AppCard.elevated(child: Text('Elevated card')),
            ],
          ),
        ),
        'app_card',
        size: const Size(420, 220),
      );
    });
  });

  group('AppTextField', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              AppTextField(hintText: 'Enter URL'),
              SizedBox(height: 16),
              AppTextField(hintText: 'Search', compact: true),
            ],
          ),
        ),
        'app_text_field',
        size: const Size(420, 160),
      );
    });
  });

  group('Badges', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                MethodBadge('GET'),
                SizedBox(width: 8),
                MethodBadge('POST'),
                SizedBox(width: 8),
                MethodBadge('PUT'),
                SizedBox(width: 8),
                MethodBadge('DELETE'),
                SizedBox(width: 8),
                MethodBadge('PATCH'),
              ]),
              SizedBox(height: 16),
              Row(children: [
                StatusChip(200),
                SizedBox(width: 8),
                StatusChip(301),
                SizedBox(width: 8),
                StatusChip(404),
                SizedBox(width: 8),
                StatusChip(500),
              ]),
            ],
          ),
        ),
        'app_badge',
        size: const Size(420, 160),
      );
    });
  });

  group('AppPopupSelect', () {
    // 只截触发器形态：弹出层经由 Overlay 渲染，在 golden 环境中
    // 位置/尺寸不稳定，因此不覆盖 AppPopupMenu 弹出面板本身。
    testWidgets('golden', (tester) async {
      const entries = [
        AppPopupSelectEntry(value: 'get', label: 'GET'),
        AppPopupSelectEntry(value: 'post', label: 'POST'),
        AppPopupSelectEntry(value: 'put', label: 'PUT'),
      ];
      await expectGolden(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                SizedBox(
                  width: 120,
                  child: AppPopupSelect<String>(
                    value: 'post',
                    items: entries,
                    onSelected: (_) {},
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 120,
                  child: AppPopupSelect<String>(
                    value: null,
                    hint: 'Method',
                    items: entries,
                    onSelected: (_) {},
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              AppPopupSelect<String>(
                value: 'get',
                items: entries,
                boxed: true,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
        'app_popup_select',
        size: const Size(420, 160),
      );
    });
  });

  group('AppDivider', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        const Padding(
          padding: EdgeInsets.all(24),
          // stretch：水平分隔线需要占满宽度（否则 SizedBox 宽度塌缩为 0）
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDivider(),
              SizedBox(height: 20),
              AppDivider(subtle: true),
              SizedBox(height: 20),
              AppDivider(height: 16),
              SizedBox(height: 20),
              SizedBox(
                height: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppDivider.vertical(),
                    SizedBox(width: 20),
                    AppDivider.vertical(subtle: true),
                    SizedBox(width: 20),
                    AppDivider.vertical(width: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
        'app_divider',
        size: const Size(420, 180),
      );
    });
  });

  group('AppEmptyState', () {
    testWidgets('golden', (tester) async {
      await expectGolden(
        tester,
        Column(
          children: [
            Expanded(
              child: AppEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No collections yet',
                subtitle: 'Create a collection to organize your requests.',
                action: AppButton.primary(
                  label: 'New Collection',
                  size: AppButtonSize.small,
                  onPressed: () {},
                ),
              ),
            ),
            const AppDivider(),
            const Expanded(
              child: AppEmptyState(
                icon: Icons.search_off,
                title: 'No results',
              ),
            ),
          ],
        ),
        'app_empty_state',
        size: const Size(420, 360),
      );
    });
  });
}
