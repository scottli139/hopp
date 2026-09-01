import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/widgets/common/variable_highlight_controller.dart';

String _flatten(TextSpan span) {
  final buffer = StringBuffer(span.text ?? '');
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is TextSpan) {
      buffer.write(_flatten(child));
    }
  }
  return buffer.toString();
}

void main() {
  group('VariableHighlightController 渲染不变量', () {
    Future<String> renderedText(
      WidgetTester tester,
      String value,
    ) async {
      final controller = VariableHighlightController()..text = value;
      late String result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            final span = controller.buildTextSpan(
              context: context,
              style: const TextStyle(),
              withComposing: false,
            );
            result = _flatten(span);
            return const SizedBox();
          },
        ),
      ));
      return result;
    }

    testWidgets('管道表达式：分段渲染与原文逐字一致（回归：不许多画 }）', (tester) async {
      const value = '{{\$timestampMs | date_floor(day)}}';
      expect(await renderedText(tester, value), value);
    });

    testWidgets('多管道链：分段渲染与原文逐字一致', (tester) async {
      const value = '{{\$timestampMs | date_floor(day) | date_add(-7d)}}';
      expect(await renderedText(tester, value), value);
    });

    testWidgets('无管道 / 纯文本 / 未闭合表达式不崩且逐字一致', (tester) async {
      expect(await renderedText(tester, '{{token}}'), '{{token}}');
      expect(await renderedText(tester, 'plain text'), 'plain text');
      expect(await renderedText(tester, '{{a | md5'), '{{a | md5');
      expect(await renderedText(tester, '{{password | sha1}} x {{b}}'),
          '{{password | sha1}} x {{b}}');
    });
  });
}
