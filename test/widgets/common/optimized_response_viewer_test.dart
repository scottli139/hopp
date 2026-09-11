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

  group('OptimizedResponseViewer 完整模式渲染器（巨文本层回归）', () {
    testWidgets('完整模式虚拟化行渲染：无 CodeField、无整段 SelectableText', (tester) async {
      await tester.pumpWidget(buildViewer(
        content: jsonWithEpoch,
        contentType: 'application/json',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CodeField), findsNothing);
      // 虚拟化后完整模式不再有承载整份响应的 SelectableText/EditableText
      expect(find.byType(EditableText), findsNothing);
      expect(find.byType(ListView), findsWidgets);
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
    /// 完整/原始模式：逐文档行比较「行号 top」与「该行首个可视行 top」，
    /// 返回每行 (行号top - 文本行top) delta 列表。
    /// 虚拟化渲染后内容行是 ListView 里的 Text.rich，按行前缀定位。
    Future<List<double>> fullModeDeltas(
      WidgetTester tester,
      String content, {
      ResponseDisplayMode mode = ResponseDisplayMode.full,
      double textScaler = 1.0,
    }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScaler)),
          child: hoppTestApp(
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
        ),
      );
      await tester.pumpAndSettle();

      final displayLines = content.split('\n');
      final deltas = <double>[];
      for (var i = 0; i < displayLines.length; i++) {
        final line = displayLines[i];
        if (line.trim().isEmpty) continue;
        final numberFind = find.text('${i + 1}');
        expect(numberFind, findsWidgets, reason: '第 ${i + 1} 行必须有行号（含末尾行）');
        // 行前缀定位该文档行首个可视行（软换行续行不含行首）
        final prefix = line.substring(0, line.length < 12 ? line.length : 12);
        final rowFind = find.textContaining(prefix);
        expect(rowFind, findsWidgets, reason: '第 ${i + 1} 行必须有内容行');
        // 行号在行高盒内垂直居中（字形视觉中心 = 行中心），与内容行比较中心
        deltas.add(
          tester.getCenter(numberFind.first).dy -
              tester.getCenter(rowFind.first).dy,
        );
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

    testWidgets('完整模式：软换行续行无行号且切片拼接还原原文', (tester) async {
      final tokenLine = '  "token": "${'B' * 400}",';
      final lines = <String>[
        '{',
        tokenLine,
        '  "after": 1,',
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
                initialMode: ResponseDisplayMode.full,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ListView 内的行 Text 按树序 = 可视行顺序；含 'B' 的都是 token 行切片
      final rowTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.textSpan?.toPlainText() ?? t.data ?? '')
          .toList();
      final tokenSlices = rowTexts.where((t) => t.contains('B')).toList();
      expect(tokenSlices.length, greaterThan(1), reason: '400 字符长行应软换行为多行');
      expect(tokenSlices.join(), tokenLine, reason: '切片拼接必须逐字符还原原文档行');
      // 行号 3 属于 token 之后的内容行，验证其存在且只出现一次
      expect(find.text('3'), findsOneWidget);
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

    testWidgets('完整模式：textScaler 1.25（uiScale 125%）下行号逐行对齐', (tester) async {
      // itemExtent/行号 pitch 必须为当前缩放下的实测行高：固定 18 会让
      // 行号与内容逐行脱节（回归：1.25 下行号曾上移一整行）。
      // 行数控制在缩放后仍全部可见（虚拟化 gutter 只渲染视口内行号）
      final lines = <String>[
        '{',
        for (var i = 1; i <= 5; i++) '  "key$i": $i,',
        '  "token": "${'B' * 200}",',
        '  "after": 1,',
        '}',
      ].join('\n');
      final deltas = await fullModeDeltas(tester, lines, textScaler: 1.25);
      final lo = deltas.reduce((a, b) => a < b ? a : b);
      final hi = deltas.reduce((a, b) => a > b ? a : b);
      expect(hi - lo, lessThan(2.0), reason: '1.25 缩放下各行 delta 应恒定：$lo ~ $hi');
    });

    testWidgets('性能模式：textScaler 1.25 下行距随缩放、行号逐行对齐', (tester) async {
      final lines = <String>[
        '{',
        for (var i = 1; i <= 30; i++) '  "key$i": $i,',
        '}',
      ].join('\n');
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
          child: hoppTestApp(
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
        ),
      );
      await tester.pumpAndSettle();
      for (final pair in [(2, 'key1'), (11, 'key10'), (21, 'key20')]) {
        final numberFind = find.text('${pair.$1}');
        final contentFind = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              ((w.data ?? w.textSpan?.toPlainText())?.contains(
                    '"${pair.$2}"',
                  ) ??
                  false),
        );
        expect(numberFind, findsWidgets);
        expect(contentFind, findsWidgets);
        // 行号在行高盒内垂直居中（视觉中心 = 条目中心），比较中心
        final numberCenter = tester.getCenter(numberFind.first).dy;
        final itemCenter = tester.getCenter(contentFind.first).dy;
        expect((numberCenter - itemCenter).abs(), lessThan(2.0),
            reason: '1.25 下性能模式第 ${pair.$1} 行行号应贴齐条目');
      }
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
              w is Text &&
              ((w.data ?? w.textSpan?.toPlainText())?.contains(
                    '"${pair.$2}"',
                  ) ??
                  false),
        );
        expect(numberFind, findsWidgets);
        expect(contentFind, findsWidgets);
        // 行号在行高盒内垂直居中（视觉中心 = 条目中心），比较中心
        final numberCenter = tester.getCenter(numberFind.first).dy;
        final itemCenter = tester.getCenter(contentFind.first).dy;
        expect((numberCenter - itemCenter).abs(), lessThan(2.0),
            reason: '性能模式第 ${pair.$1} 行行号应贴齐条目');
      }
    });

    testWidgets('完整模式：超大响应走异步管线且行数齐全（9000 行卡顿回归）', (tester) async {
      // > 100KB 触发异步管线（isolate 高亮 + 分块行计算）；
      // 6000 行 × ~27 字符 ≈ 165KB
      final lines =
          List.generate(6000, (i) => '  "key$i": "value-$i",').join('\n');
      final content = '{\n$lines\n}';
      final controller = ScrollController();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          hoppTestApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: OptimizedResponseViewer(
                  content: content,
                  contentType: 'application/json',
                  initialMode: ResponseDisplayMode.full,
                  scrollController: controller,
                ),
              ),
            ),
          ),
        );
        // 等异步管线完成（isolate 往返 + 分块计算为真实异步，需真实事件
        // 循环）。管线期间内容区显示进度指示（无限动画，不能
        // pumpAndSettle）；进度控件消失即管线完成。
        final sw = Stopwatch()..start();
        while (sw.elapsed < const Duration(seconds: 120)) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 20));
          final busy =
              find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
                  find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
          if (!busy) break;
        }
        expect(sw.elapsed, lessThan(const Duration(seconds: 120)),
            reason: '异步管线必须在时限内完成');
      });
      await tester.pumpAndSettle();

      // 首行号与首行内容在视口内
      expect(find.text('1'), findsWidgets);
      expect(find.textContaining('{'), findsWidgets);

      // 滚到底：末行号 6002（{ + 6000 行 + }）进入视口
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('6002'), findsWidgets);
    });

    testWidgets('模式来回切换后行号仍随滚动更新', (tester) async {
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

      // 完整 → 性能 → 完整：每次切换后行号都应正常渲染
      await tester.tap(find.text('Performance'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsWidgets);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsNothing);
      expect(find.text('52'), findsWidgets);

      await tester.tap(find.text('Full'));
      await tester.pumpAndSettle();
      // 模式切换会重建滚动视图（滚动位置回到顶部），行号仍应正常渲染
      expect(find.text('1'), findsWidgets);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('52'), findsWidgets);
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsWidgets);
    });
  });
}
