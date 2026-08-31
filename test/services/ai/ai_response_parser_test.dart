import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/services/ai/ai_models.dart';
import 'package:hopp/services/ai/ai_response_parser.dart';

void main() {
  group('decodeAiJson', () {
    test('剥离 ```json 围栏后解码', () {
      final decoded = AiResponseParser.decodeAiJson('''
```json
[{"target": "status", "operator": "equals", "expected": 200}]
```
''');
      expect(decoded, isA<List<dynamic>>());
      expect((decoded as List<dynamic>).length, equals(1));
    });

    test('无围栏时直接解码', () {
      final decoded = AiResponseParser.decodeAiJson('[1, 2]');
      expect(decoded, equals([1, 2]));
    });

    test('非 JSON 抛 AiParseException', () {
      expect(
        () => AiResponseParser.decodeAiJson('这不是 JSON'),
        throwsA(isA<AiParseException>()),
      );
    });
  });

  group('parseAssertionDrafts', () {
    AiAssertionParseResult parse(List<dynamic> list) =>
        AiResponseParser.parseAssertionDrafts(list);

    test('operatorsByTarget 矩阵内全部合法组合通过', () {
      const matrix = {
        'status': ['equals', 'notEquals', 'lt', 'lte', 'gt', 'gte'],
        'header': [
          'equals',
          'notEquals',
          'contains',
          'notContains',
          'exists',
          'notExists',
          'matches',
        ],
        'body': ['contains', 'notContains', 'equals', 'notEquals', 'matches'],
        'jsonPath': [
          'exists',
          'notExists',
          'equals',
          'notEquals',
          'contains',
          'lt',
          'lte',
          'gt',
          'gte',
        ],
        'responseTime': ['lt', 'lte', 'gt', 'gte'],
      };

      final input = <dynamic>[
        for (final entry in matrix.entries)
          for (final op in entry.value)
            {
              'target': entry.key,
              'targetArg':
                  entry.key == 'header' || entry.key == 'jsonPath' ? 'x' : '',
              'operator': op,
              if (op != 'exists' && op != 'notExists') 'expected': '1',
            },
      ];

      final result = parse(input);

      expect(result.discarded, equals(0));
      expect(result.items.length, equals(input.length));
      expect(
        result.items.first,
        equals(
          const AiAssertionDraft(
            target: AssertionTarget.status,
            targetArg: '',
            operator: AssertionOperator.equals,
            expected: '1',
          ),
        ),
      );
    });

    test('剥离围栏后解析正常', () {
      final decoded = AiResponseParser.decodeAiJson('''
```json
[{"target": "status", "operator": "equals", "expected": 200}]
```
''');
      final result = AiResponseParser.parseAssertionDrafts(decoded);
      expect(result.items.single.operator, equals(AssertionOperator.equals));
      expect(result.items.single.expected, equals('200'));
    });

    test('非法 target / operator 丢弃并计数', () {
      final result = parse([
        {'target': 'status', 'operator': 'equals', 'expected': 200},
        {'target': 'nonsense', 'operator': 'equals', 'expected': 200},
        {'target': 'status', 'operator': 'nonsense', 'expected': 200},
      ]);

      expect(result.items.length, equals(1));
      expect(result.discarded, equals(2));
    });

    test('矩阵外组合（status + matches）丢弃', () {
      final result = parse([
        {'target': 'status', 'operator': 'matches', 'expected': r'2\d\d'},
      ]);

      expect(result.items, isEmpty);
      expect(result.discarded, equals(1));
    });

    test('expected 类型非法（bool）丢弃', () {
      final result = parse([
        {'target': 'status', 'operator': 'equals', 'expected': true},
      ]);

      expect(result.items, isEmpty);
      expect(result.discarded, equals(1));
    });

    test('num expected 归一为字符串保留', () {
      final result = parse([
        {'target': 'status', 'operator': 'equals', 'expected': 200},
      ]);

      expect(result.items.single.expected, equals('200'));
    });

    test('matches 正则不合法丢弃，合法保留', () {
      final result = parse([
        {'target': 'body', 'operator': 'matches', 'expected': '(['},
        {'target': 'body', 'operator': 'matches', 'expected': r'\d+'},
      ]);

      expect(result.items.length, equals(1));
      expect(result.items.single.expected, equals(r'\d+'));
      expect(result.discarded, equals(1));
    });

    test('header / jsonPath 缺 targetArg 丢弃', () {
      final result = parse([
        {'target': 'header', 'operator': 'equals', 'expected': 'a'},
        {'target': 'jsonPath', 'operator': 'exists'},
      ]);

      expect(result.items, isEmpty);
      expect(result.discarded, equals(2));
    });

    test('exists / notExists 不需要 expected', () {
      final result = parse([
        {'target': 'jsonPath', 'targetArg': r'$.id', 'operator': 'exists'},
      ]);

      expect(result.items.single.expected, equals(''));
    });

    test('非 List 输入抛 AiParseException', () {
      expect(
        () => AiResponseParser.parseAssertionDrafts({'a': 1}),
        throwsA(isA<AiParseException>()),
      );
    });

    test('非 Map 元素丢弃', () {
      final result = parse([42, 'x', null]);

      expect(result.items, isEmpty);
      expect(result.discarded, equals(3));
    });
  });

  group('parseRequestDraft', () {
    Map<String, dynamic> validDraft() => {
          'name': '创建用户',
          'method': 'POST',
          'url': '{{baseUrl}}/users',
          'params': [
            {'key': 'page', 'value': '1', 'enabled': true},
          ],
          'headers': [
            {'key': 'Content-Type', 'value': 'application/json'},
          ],
          'bodyType': 'raw',
          'rawContentType': 'json',
          'body': '{"a":1}',
        };

    test('合法草稿通过', () {
      final draft = AiResponseParser.parseRequestDraft(validDraft());

      expect(draft.name, equals('创建用户'));
      expect(draft.method, equals('POST'));
      expect(draft.url, equals('{{baseUrl}}/users'));
      expect(
        draft.params.single,
        equals(const AiKeyValueDraft(key: 'page', value: '1', enabled: true)),
      );
      expect(draft.headers.single.enabled, isTrue); // 缺省 enabled
      expect(draft.bodyType, equals('raw'));
      expect(draft.rawContentType, equals('json'));
      expect(draft.body, equals('{"a":1}'));
    });

    test('method 小写归一为大写', () {
      final draft = AiResponseParser.parseRequestDraft(
        validDraft()..['method'] = 'post',
      );
      expect(draft.method, equals('POST'));
    });

    test('未知 method 抛 AiParseException', () {
      expect(
        () => AiResponseParser.parseRequestDraft(
          validDraft()..['method'] = 'QUERY',
        ),
        throwsA(isA<AiParseException>()),
      );
    });

    test('url 为空抛 AiParseException', () {
      expect(
        () => AiResponseParser.parseRequestDraft(validDraft()..['url'] = ''),
        throwsA(isA<AiParseException>()),
      );
    });

    test('params 元素缺 key 抛 AiParseException', () {
      expect(
        () => AiResponseParser.parseRequestDraft(
          validDraft()
            ..['params'] = [
              {'value': '1'},
            ],
        ),
        throwsA(isA<AiParseException>()),
      );
    });

    test('bodyType 非法抛 AiParseException', () {
      expect(
        () => AiResponseParser.parseRequestDraft(
          validDraft()..['bodyType'] = 'weird',
        ),
        throwsA(isA<AiParseException>()),
      );
    });

    test('raw 时 rawContentType 非法抛 AiParseException', () {
      expect(
        () => AiResponseParser.parseRequestDraft(
          validDraft()..['rawContentType'] = 'yaml',
        ),
        throwsA(isA<AiParseException>()),
      );
    });

    test('bodyType 缺省为 none，rawContentType 仅 raw 时保留', () {
      final draft = AiResponseParser.parseRequestDraft(const {
        'method': 'GET',
        'url': 'http://x',
      });

      expect(draft.bodyType, equals('none'));
      expect(draft.rawContentType, isNull);
      expect(draft.params, isEmpty);
      expect(draft.name, equals(''));
    });

    test('非 Map 输入抛 AiParseException', () {
      expect(
        () => AiResponseParser.parseRequestDraft([1, 2]),
        throwsA(isA<AiParseException>()),
      );
    });
  });
}
