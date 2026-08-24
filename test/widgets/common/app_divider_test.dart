import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/theme/app_theme.dart';
import 'package:hopp/widgets/common/app_button.dart';
import 'package:hopp/widgets/common/app_dialog.dart';
import 'package:hopp/widgets/common/app_divider.dart';

void main() {
  group('AppDivider', () {
    /// 宽度塌缩回归（UI 审计发现）：无子节点的 DecoratedBox 在宽松
    /// 约束下宽度为 0，非 stretch 的 Column 里整条线不渲染——环境管理
    /// 对话框头/尾部分隔线即因此缺失。修复后水平分隔线撑满可用宽度。
    testWidgets('horizontal divider expands to full width in loose column',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: Column(
                  // 默认 center（宽松宽度约束），不得塌缩为 0 宽
                  children: const [AppDivider()],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(AppDivider)).width, 400);
    });

    testWidgets('AppDialog showDividers renders header/footer dividers',
        (tester) async {
      // 放大 surface，避免 insetPadding 把 840 宽对话框夹小
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: AppDialog(
                title: 'Debug',
                width: 840,
                height: 560,
                contentPadding: EdgeInsets.zero,
                showDividers: true,
                actions: [
                  AppButton.ghost(label: 'Cancel', onPressed: () {}),
                ],
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dividers = find.byType(AppDivider);
      expect(dividers, findsNWidgets(2));
      for (final e in dividers.evaluate()) {
        // 对话框内容宽 = 840 - 两侧 1px 边框
        expect(e.size!.width, 838, reason: 'divider must span dialog width');
        expect(e.size!.height, 1);
      }
    });
  });
}
