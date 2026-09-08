import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/utils/epoch_annotation.dart';
import 'package:hopp/widgets/common/optimized_response_viewer.dart';

import '../../helpers/test_app.dart';

void main() {
  const jsonWithEpoch = '{\n'
      '  "startTime": 1564156800000,\n'
      '  "duration": 3600,\n'
      '  "orderNo": "1564761599000"\n'
      '}';

  String expectedAnnotation() => EpochAnnotation.format('1564156800000')!;

  Widget buildViewer({
    required String content,
    ResponseDisplayMode mode = ResponseDisplayMode.full,
    String? contentType,
  }) {
    return hoppTestApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: OptimizedResponseViewer(
            content: content,
            contentType: contentType,
            initialMode: mode,
          ),
        ),
      ),
    );
  }

  group('OptimizedResponseViewer epoch 注解（F8.5）', () {
    testWidgets('Full 模式：JSON 数值追加可读时间注释', (tester) async {
      await tester.pumpWidget(buildViewer(
        content: jsonWithEpoch,
        contentType: 'application/json',
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining(expectedAnnotation()), findsWidgets);
      // 普通数字与字符串内数字不标注
      expect(find.textContaining('3600  →'), findsNothing);
      expect(find.textContaining('1564761599000  →'), findsNothing);
    });

    testWidgets('注解开关关闭后注释消失，再开启恢复', (tester) async {
      await tester.pumpWidget(buildViewer(
        content: jsonWithEpoch,
        contentType: 'application/json',
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining(expectedAnnotation()), findsWidgets);

      await tester.tap(find.byTooltip('Hide timestamp annotations'));
      await tester.pumpAndSettle();
      expect(find.textContaining(expectedAnnotation()), findsNothing);
      // 原文仍在
      expect(find.textContaining('1564156800000'), findsWidgets);

      await tester.tap(find.byTooltip('Show timestamp annotations'));
      await tester.pumpAndSettle();
      expect(find.textContaining(expectedAnnotation()), findsWidgets);
    });

    testWidgets('Performance 模式：行渲染同样带注释', (tester) async {
      await tester.pumpWidget(buildViewer(
        content: jsonWithEpoch,
        contentType: 'application/json',
        mode: ResponseDisplayMode.performance,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining(expectedAnnotation()), findsWidgets);
    });

    testWidgets('Raw 模式不标注', (tester) async {
      await tester.pumpWidget(buildViewer(
        content: jsonWithEpoch,
        contentType: 'application/json',
        mode: ResponseDisplayMode.raw,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining(expectedAnnotation()), findsNothing);
      expect(find.textContaining('1564156800000'), findsWidgets);
    });

    testWidgets('非 JSON 内容不标注且无开关按钮', (tester) async {
      await tester.pumpWidget(buildViewer(
        content: 'plain text 1564156800000',
        mode: ResponseDisplayMode.full,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('→ 20'), findsNothing);
      expect(find.byTooltip('Hide timestamp annotations'), findsNothing);
    });
  });

  group('OptimizedResponseViewer 完整模式渲染器（字号翻转回归）', () {
    testWidgets('完整模式用 SelectableText.rich 渲染而非 CodeField', (tester) async {
      await tester.pumpWidget(buildViewer(
        content: jsonWithEpoch,
        contentType: 'application/json',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CodeField), findsNothing);
      expect(find.byType(SelectableText), findsWidgets);
    });

    testWidgets('行号与正文同一滚动视图：滚动后行号随动', (tester) async {
      final controller = ScrollController();
      final lines = List.generate(50, (i) => '  "key$i": $i,').join('\n');
      await tester.pumpWidget(
        hoppTestApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 200,
              child: OptimizedResponseViewer(
                content: '{\n$lines\n}',
                contentType: 'application/json',
                initialMode: ResponseDisplayMode.full,
                scrollController: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.text('1')).dy;
      expect(before, greaterThanOrEqualTo(0));

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      // 行号随内容一起滚动：行号 1 滚出视口顶部
      expect(
        tester.getTopLeft(find.text('1')).dy,
        lessThan(before - controller.position.maxScrollExtent + 1),
      );
      expect(tester.getTopLeft(find.text('1')).dy, lessThan(0));
    });
  });
}
