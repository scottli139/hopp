import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/json.dart';

void main() {
  List<InlineSpan> buildSpans(List<Node>? nodes) {
    if (nodes == null) return const [];
    return [
      for (final node in nodes)
        TextSpan(
          text: node.children == null ? node.value : null,
          children: node.children == null ? null : buildSpans(node.children),
        ),
    ];
  }

  test('highlight span 树纯文本与原内容逐字符一致（含 CJK）', () {
    highlight.registerLanguage('json', json);
    final lines = <String>[
      '{',
      '  "code": 0,',
      '      "endpointId": 100000,',
      '      "displayName": "江忆怀0号会议室",',
      '      "sn": "SNxxxxxxxxxxxxxxxxxxxx",',
      '      "note": null,',
      '      "lastSeen": 1788929000000,',
      '      "tags": ["meeting", "floor1", "backup"],',
      '    },',
      '  ]',
      '}',
    ];
    final content = lines.join('\n');

    final result = highlight.parse(content, language: 'json');
    final spans = buildSpans(result.nodes);
    final plain = spans.map((s) => s.toPlainText()).join();

    if (plain.length != content.length) {
      // 找出第一处分叉
      var i = 0;
      while (i < plain.length && i < content.length && plain[i] == content[i]) {
        i++;
      }
      debugPrint('first diff at $i: '
          'plain=${plain.substring(i, (i + 20).clamp(0, plain.length))} | '
          'content=${content.substring(i, (i + 20).clamp(0, content.length))}');
    }
    expect(plain.length, content.length,
        reason: 'span 纯文本长度必须等于原内容，否则行号 caret 偏移错位');
    expect(plain, content);
  });
}
