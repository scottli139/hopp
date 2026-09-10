import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('行号与内容行逐行对齐（textScaler 0.8/0.9/1.0/1.25）', (tester) async {
      for (final scalerValue in [0.8, 0.9, 1.0, 1.25]) {
        // 行数控制在最小行高档位（0.8→14px）下仍全部可见（虚拟化 gutter
        // 只渲染视口内行号）
        final content =
            [for (var i = 1; i <= 15; i++) '  "key$i": $i,'].join('\n');
        await tester.pumpWidget(
          buildEditor(content: content, textScaler: scalerValue, height: 600),
        );
        await tester.pumpAndSettle();

        // 用 RenderEditable 的 caret rect 作为内容行位置的唯一事实来源：
        // 行号中心必须等于对应文档行 caret rect 中心（任何 padding/缩放/
        // 字体度量环境下都成立）
        final editableState =
            tester.state<EditableTextState>(find.byType(EditableText));
        final ro = editableState.renderEditable;
        final plain = ro.text!.toPlainText();
        final lines = plain.split('\n');
        var charOffset = 0;
        for (var i = 0; i < lines.length; i++) {
          final rect = ro.getLocalRectForCaret(
            TextPosition(offset: charOffset),
          );
          final contentCenter = ro.localToGlobal(rect.center).dy;
          final numberFind = find.text('${i + 1}');
          expect(numberFind, findsWidgets,
              reason: 'scaler=$scalerValue 第 ${i + 1} 行必须有行号');
          final numberCenter = tester.getCenter(numberFind.first).dy;
          expect((numberCenter - contentCenter).abs(), lessThan(1.6),
              reason: 'scaler=$scalerValue 第 ${i + 1} 行行号与内容应对齐: '
                  '$numberCenter vs $contentCenter');
          charOffset += lines[i].length + 1;
        }
      }
    });
  });
}
