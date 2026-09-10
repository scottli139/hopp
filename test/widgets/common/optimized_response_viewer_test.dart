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

    testWidgets('行号随滚动更新：滚到底后首行号消失、末行号出现', (tester) async {
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
      expect(find.text('1'), findsWidgets);

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      // 行号随内容一起滚动：行号 1 滚出视口（虚拟化 gutter 不再渲染），
      // 末行行号 52（{ + 50 行 + }）进入视口
      expect(find.text('1'), findsNothing);
      expect(find.text('52'), findsWidgets);
      expect(find.text('51'), findsWidgets);
    });
  });

  group('OptimizedResponseViewer 行号对齐（软换行感知 gutter）', () {
    /// 完整/原始模式：用 RenderEditable 的真实行位置对比行号 top，
    /// 返回每行 (行号top - 文本行top) delta 列表
    Future<List<double>> fullModeDeltas(
      WidgetTester tester,
      String content, {
      ResponseDisplayMode mode = ResponseDisplayMode.full,
    }) async {
      await tester.pumpWidget(
        hoppTestApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: OptimizedResponseViewer(
                content: content,
                contentType: 'application/json',
                initialMode: mode,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editableState =
          tester.state<EditableTextState>(find.byType(EditableText));
      final ro = editableState.renderEditable;
      final displayLines = ro.text!.toPlainText().split('\n');
      final deltas = <double>[];
      var charOffset = 0;
      for (var i = 0; i < displayLines.length; i++) {
        final end = charOffset + displayLines[i].length;
        final boxes = ro.getBoxesForSelection(
          TextSelection(
            baseOffset: charOffset,
            extentOffset: end > charOffset ? end : charOffset + 1,
          ),
        );
        final top = ro.localToGlobal(Offset(0, boxes.first.top)).dy;
        final numberFind = find.text('${i + 1}');
        expect(numberFind, findsWidgets, reason: '第 ${i + 1} 行必须有行号（含末尾行）');
        deltas.add(tester.getTopLeft(numberFind.first).dy - top);
        charOffset = end + 1;
      }
      return deltas;
    }

    testWidgets('完整模式：长行软换行后行号逐行对齐且末行不缺', (tester) async {
      // 含 400 字符不可断长行 + 其后多行：验证换行数测算与渲染一致，
      // 行号不漂移、末行行号不被裁剪
      final lines = <String>[
        '{',
        for (var i = 1; i <= 5; i++) '  "key$i": $i,',
        '  "token": "${'B' * 400}",',
        '  "url": "ws://host/path?token=${'C' * 380}",',
        for (var i = 6; i <= 12; i++) '  "key$i": $i,',
        '}',
      ].join('\n');
      final deltas = await fullModeDeltas(tester, lines);
      final lo = deltas.reduce((a, b) => a < b ? a : b);
      final hi = deltas.reduce((a, b) => a > b ? a : b);
      // 字形盒与行盒存在恒定小偏差；关键是逐行一致（无累计漂移）
      expect(hi - lo, lessThan(2.0), reason: '各行 delta 应恒定：$lo ~ $hi');
    });

    testWidgets('原始模式：行号逐行对齐', (tester) async {
      final lines = <String>[
        for (var i = 1; i <= 20; i++) 'line $i content',
      ].join('\n');
      final deltas =
          await fullModeDeltas(tester, lines, mode: ResponseDisplayMode.raw);
      final lo = deltas.reduce((a, b) => a < b ? a : b);
      final hi = deltas.reduce((a, b) => a > b ? a : b);
      expect(hi - lo, lessThan(2.0), reason: '原始模式各行 delta 应恒定：$lo ~ $hi');
    });

    testWidgets('性能模式：行号与虚拟化条目逐行对齐', (tester) async {
      final lines = <String>[
        '{',
        for (var i = 1; i <= 30; i++) '  "key$i": $i,',
        '  "token": "${'C' * 400}"',
        '}',
      ].join('\n');
      await tester.pumpWidget(
        hoppTestApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: OptimizedResponseViewer(
                content: lines,
                contentType: 'application/json',
                initialMode: ResponseDisplayMode.performance,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 内容首行是 '{'，keyN 是第 N+1 行 → 数字 N+1 对应 keyN 条目
      for (final pair in [(2, 'key1'), (6, 'key5'), (11, 'key10')]) {
        final numberFind = find.text('${pair.$1}');
        final contentFind = find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              (w.data?.contains('"${pair.$2}"') ?? false),
        );
        expect(numberFind, findsWidgets);
        expect(contentFind, findsWidgets);
        final numberTop = tester.getTopLeft(numberFind.first).dy;
        // 条目容器 padding vertical: 2 → 条目 top = 文本 top - 2
        final itemTop = tester.getTopLeft(contentFind.first).dy - 2;
        expect((numberTop - itemTop).abs(), lessThan(2.0),
            reason: '性能模式第 ${pair.$1} 行行号应贴齐条目');
      }
    });
  });
}
