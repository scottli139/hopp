import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart' hide CodeEditor;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/theme/app_text_styles.dart';
import 'package:hopp/widgets/common/code_editor.dart';

import '../../helpers/test_app.dart';

void main() {
  Widget buildEditor({
    required String content,
    double height = 300,
    double textScaler = 1.0,
  }) {
    return ProviderScope(
      child: hoppTestApp(
        textScaler: TextScaler.linear(textScaler),
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: height,
            child: CodeEditor(
              code: content,
              expands: true,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  /// 收集当前可见行号（gutter 里的纯数字 Text）
  List<int> visibleNumbers(WidgetTester tester) {
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((d) => RegExp(r'^\d+$').hasMatch(d))
        .map(int.parse)
        .toList();
  }

  group('CodeEditor 行号滚动同步（Issue #4 回归）', () {
    testWidgets('行号随滚轮滚动更新：首行滚出、后续行号进入视口', (tester) async {
      final content =
          [for (var i = 1; i <= 100; i++) '  "key$i": $i,'].join('\n');
      await tester.pumpWidget(buildEditor(content: content));
      await tester.pumpAndSettle();
      expect(visibleNumbers(tester).first, 1);

      // 旧实现行号列是 NeverScrollableScrollPhysics 静态列，滚动后仍
      // 冻结显示 1..N；新实现行号随内容滚动
      final center = tester.getCenter(find.byType(CodeField));
      for (var i = 0; i < 4; i++) {
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: center,
            scrollDelta: const Offset(0, 120),
          ),
        );
      }
      await tester.pumpAndSettle();

      final nums = visibleNumbers(tester);
      expect(nums, isNotEmpty);
      expect(nums.first, greaterThan(5), reason: '滚动后首个可见行号应明显后移，实际：$nums');
    });

    testWidgets('行号与内容行逐行对齐（textScaler 1.0 与 1.25）', (tester) async {
      for (final scalerValue in [1.0, 1.25]) {
        final content =
            [for (var i = 1; i <= 50; i++) '  "key$i": $i,'].join('\n');
        await tester.pumpWidget(
          buildEditor(content: content, textScaler: scalerValue),
        );
        await tester.pumpAndSettle();

        // 内容行是 CodeField 内单个大 TextField，无法按行定位；改为验证
        // 行号间距 = 当前缩放下实测行高，且首行号 top 与 CodeField 内容
        // 起点一致（contentPadding 16）
        final expectedPitch = () {
          final p = TextPainter(
            text: TextSpan(
              text: 'A',
              style: AppTextStyles.code12.copyWith(height: 1.5),
            ),
            textDirection: TextDirection.ltr,
            textScaler: TextScaler.linear(scalerValue),
            strutStyle: const StrutStyle(),
          )..layout();
          return p.height;
        }();
        final t1 = tester.getTopLeft(find.text('1')).dy;
        final t2 = tester.getTopLeft(find.text('2')).dy;
        expect((t2 - t1 - expectedPitch).abs(), lessThan(1.5),
            reason: 'scaler=$scalerValue 行号间距应等于实测行高');
        // 首行号在行高盒内垂直居中：中心 = 内容起点 + 半个行高
        final c1 = tester.getCenter(find.text('1')).dy;
        final fieldTop = tester.getTopLeft(find.byType(CodeField)).dy;
        expect((c1 - fieldTop - 16 - expectedPitch / 2).abs(), lessThan(2.0),
            reason: 'scaler=$scalerValue 首行号中心应贴齐内容首行中心（padding 16）');
      }
    });
  });
}
