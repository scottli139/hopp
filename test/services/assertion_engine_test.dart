import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/models/http_response.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/services/assertion/assertion_engine.dart';
import 'package:hopp/services/variable_resolver.dart';

void main() {
  final resolver = VariableResolver();

  KeyValuePair header(String key, String value) =>
      KeyValuePair(id: key, key: key, value: value);

  HttpResponse resp({
    int? statusCode,
    String? body,
    List<KeyValuePair> headers = const [],
    int? durationMs,
  }) =>
      HttpResponse(
        statusCode: statusCode,
        body: body,
        headers: headers,
        durationMs: durationMs,
      );

  AssertionRule rule({
    AssertionTarget target = AssertionTarget.status,
    String targetArg = '',
    AssertionOperator operator = AssertionOperator.equals,
    String expected = '',
    bool enabled = true,
  }) =>
      AssertionRule(
        id: 'a1',
        enabled: enabled,
        target: target,
        targetArg: targetArg,
        operator: operator,
        expected: expected,
      );

  AssertionResult evalOne(
    AssertionRule r,
    HttpResponse response, {
    Map<String, String> variables = const {},
  }) =>
      AssertionEngine.evaluate(
        rules: [r],
        response: response,
        resolver: resolver,
        variables: variables,
      ).single;

  /// 断言单条规则的求值 outcome
  void expectOutcome(
    AssertionRule r,
    HttpResponse response,
    AssertionOutcome outcome, {
    Map<String, String> variables = const {},
  }) {
    expect(evalOne(r, response, variables: variables).outcome, outcome);
  }

  group('通用', () {
    test('disabled 规则记 skipped，不求值（非法 regex 也不报）', () {
      final result = evalOne(
        rule(
          target: AssertionTarget.body,
          operator: AssertionOperator.matches,
          expected: '([',
          enabled: false,
        ),
        resp(body: 'x'),
      );

      expect(result.outcome, AssertionOutcome.skipped);
      expect(result.message, isNull);
    });

    test('结果顺序与规则顺序一致', () {
      final results = AssertionEngine.evaluate(
        rules: [
          rule(expected: '200'),
          rule(expected: '404'),
          rule(expected: '500', enabled: false),
        ],
        response: resp(statusCode: 200),
        resolver: resolver,
        variables: const {},
      );

      expect(results.map((r) => r.outcome), [
        AssertionOutcome.passed,
        AssertionOutcome.failed,
        AssertionOutcome.skipped,
      ]);
    });

    test('期望值 {{var}} 插值生效', () {
      expectOutcome(
        rule(expected: '{{code}}'),
        resp(statusCode: 201),
        AssertionOutcome.passed,
        variables: {'code': '201'},
      );
    });

    test('操作符与目标不匹配判失败', () {
      final result = evalOne(
        rule(target: AssertionTarget.body, operator: AssertionOperator.lt),
        resp(body: 'x'),
      );
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, contains('not supported'));
    });
  });

  group('operatorsByTarget 矩阵（与 PRD F4.1 一致）', () {
    test('矩阵内容', () {
      expect(AssertionEngine.operatorsByTarget, {
        AssertionTarget.status: [
          AssertionOperator.equals,
          AssertionOperator.notEquals,
          AssertionOperator.lt,
          AssertionOperator.lte,
          AssertionOperator.gt,
          AssertionOperator.gte,
        ],
        AssertionTarget.header: [
          AssertionOperator.equals,
          AssertionOperator.notEquals,
          AssertionOperator.contains,
          AssertionOperator.notContains,
          AssertionOperator.exists,
          AssertionOperator.notExists,
          AssertionOperator.matches,
        ],
        AssertionTarget.body: [
          AssertionOperator.contains,
          AssertionOperator.notContains,
          AssertionOperator.equals,
          AssertionOperator.notEquals,
          AssertionOperator.matches,
        ],
        AssertionTarget.jsonPath: [
          AssertionOperator.exists,
          AssertionOperator.notExists,
          AssertionOperator.equals,
          AssertionOperator.notEquals,
          AssertionOperator.contains,
          AssertionOperator.lt,
          AssertionOperator.lte,
          AssertionOperator.gt,
          AssertionOperator.gte,
        ],
        AssertionTarget.responseTime: [
          AssertionOperator.lt,
          AssertionOperator.lte,
          AssertionOperator.gt,
          AssertionOperator.gte,
        ],
      });
    });

    test('needsTargetArg：仅 header / jsonPath 需要', () {
      expect(AssertionEngine.needsTargetArg(AssertionTarget.status), isFalse);
      expect(AssertionEngine.needsTargetArg(AssertionTarget.header), isTrue);
      expect(AssertionEngine.needsTargetArg(AssertionTarget.body), isFalse);
      expect(AssertionEngine.needsTargetArg(AssertionTarget.jsonPath), isTrue);
      expect(
        AssertionEngine.needsTargetArg(AssertionTarget.responseTime),
        isFalse,
      );
    });

    test('needsExpected：exists / notExists 不需要', () {
      for (final op in AssertionOperator.values) {
        final expected =
            op != AssertionOperator.exists && op != AssertionOperator.notExists;
        expect(
          AssertionEngine.needsExpected(op),
          expected,
          reason: 'Failed for ${op.name}',
        );
      }
    });
  });

  group('status', () {
    final response = resp(statusCode: 200);

    test('equals / notEquals', () {
      expectOutcome(rule(expected: '200'), response, AssertionOutcome.passed);
      expectOutcome(rule(expected: '404'), response, AssertionOutcome.failed);
      expectOutcome(
        rule(operator: AssertionOperator.notEquals, expected: '404'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        rule(operator: AssertionOperator.notEquals, expected: '200'),
        response,
        AssertionOutcome.failed,
      );
    });

    test('lt / lte / gt / gte 数值比较', () {
      final cases = {
        // op: (pass expected, fail expected)
        AssertionOperator.lt: ('201', '200'),
        AssertionOperator.lte: ('200', '199'),
        AssertionOperator.gt: ('199', '200'),
        AssertionOperator.gte: ('200', '201'),
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        expectOutcome(
          rule(operator: key, expected: value.$1),
          response,
          AssertionOutcome.passed,
        );
        expectOutcome(
          rule(operator: key, expected: value.$2),
          response,
          AssertionOutcome.failed,
        );
      }
    });

    test('statusCode 为 null → failed no response', () {
      final result = evalOne(rule(expected: '200'), resp(body: 'ok'));
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'no response');
      expect(result.actual, isNull);
    });

    test('期望值非数字 → failed expected not a number', () {
      final result = evalOne(rule(expected: 'abc'), response);
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'expected not a number');
      expect(result.actual, '200');
    });
  });

  group('header', () {
    final response = resp(
      headers: [
        header('Content-Type', 'application/json; charset=utf-8'),
        header('X-Request-Id', 'req-42'),
      ],
    );

    AssertionRule h({
      String name = 'Content-Type',
      AssertionOperator operator = AssertionOperator.exists,
      String expected = '',
    }) =>
        rule(
          target: AssertionTarget.header,
          targetArg: name,
          operator: operator,
          expected: expected,
        );

    test('header 名大小写不敏感', () {
      expectOutcome(h(name: 'content-type'), response, AssertionOutcome.passed);
      expectOutcome(h(name: 'CONTENT-TYPE'), response, AssertionOutcome.passed);
    });

    test('exists / notExists', () {
      expectOutcome(h(), response, AssertionOutcome.passed);
      expectOutcome(h(name: 'X-Missing'), response, AssertionOutcome.failed);
      expectOutcome(
        h(name: 'X-Missing', operator: AssertionOperator.notExists),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        h(operator: AssertionOperator.notExists),
        response,
        AssertionOutcome.failed,
      );
    });

    test('header 不存在且非 notExists → failed header not found', () {
      final result = evalOne(
        h(
          name: 'X-Missing',
          operator: AssertionOperator.equals,
          expected: 'x',
        ),
        response,
      );
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'header not found');
    });

    test('equals / notEquals / contains / notContains 对值操作', () {
      expectOutcome(
        h(
          operator: AssertionOperator.equals,
          expected: 'application/json; charset=utf-8',
        ),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        h(operator: AssertionOperator.equals, expected: 'text/html'),
        response,
        AssertionOutcome.failed,
      );
      expectOutcome(
        h(operator: AssertionOperator.notEquals, expected: 'text/html'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        h(operator: AssertionOperator.contains, expected: 'json'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        h(operator: AssertionOperator.notContains, expected: 'xml'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        h(operator: AssertionOperator.notContains, expected: 'json'),
        response,
        AssertionOutcome.failed,
      );
    });

    test('matches 正则；非法正则 → failed invalid regex', () {
      expectOutcome(
        h(operator: AssertionOperator.matches, expected: r'application/\w+'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        h(operator: AssertionOperator.matches, expected: r'^\d+$'),
        response,
        AssertionOutcome.failed,
      );

      final invalid = evalOne(
        h(operator: AssertionOperator.matches, expected: '(['),
        response,
      );
      expect(invalid.outcome, AssertionOutcome.failed);
      expect(invalid.message, 'invalid regex');
    });

    test('targetArg 支持 {{var}} 插值', () {
      final result = evalOne(
        h(name: '{{traceHeader}}'),
        response,
        variables: {'traceHeader': 'X-Request-Id'},
      );
      expect(result.outcome, AssertionOutcome.passed);
      expect(result.actual, 'req-42');
    });
  });

  group('body', () {
    AssertionRule b({
      AssertionOperator operator = AssertionOperator.contains,
      String expected = '',
    }) =>
        rule(
          target: AssertionTarget.body,
          operator: operator,
          expected: expected,
        );

    test('contains / notContains / equals / notEquals / matches', () {
      final response = resp(body: '{"message": "hello world"}');

      expectOutcome(b(expected: 'hello'), response, AssertionOutcome.passed);
      expectOutcome(b(expected: 'bye'), response, AssertionOutcome.failed);
      expectOutcome(
        b(operator: AssertionOperator.notContains, expected: 'bye'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        b(
          operator: AssertionOperator.equals,
          expected: '{"message": "hello world"}',
        ),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        b(operator: AssertionOperator.notEquals, expected: 'hello'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        b(
          operator: AssertionOperator.matches,
          expected: r'"message": "\w+ \w+"',
        ),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        b(operator: AssertionOperator.matches, expected: r'\d+'),
        response,
        AssertionOutcome.failed,
      );
    });

    test('body 为 null 按空串处理', () {
      final response = resp(statusCode: 204);

      expectOutcome(
        b(operator: AssertionOperator.notContains, expected: 'x'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        b(operator: AssertionOperator.equals),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(b(expected: 'x'), response, AssertionOutcome.failed);
    });

    test('非法正则 → failed invalid regex', () {
      final result = evalOne(
        b(operator: AssertionOperator.matches, expected: '(['),
        resp(body: 'x'),
      );
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'invalid regex');
    });
  });

  group('jsonPath', () {
    final response = resp(
      body: '{"code": 200, "data": {"token": "tk-1", '
          '"expire": 7200, "active": true, "items": [1, 2]}}',
    );

    AssertionRule j({
      String path = r'$.code',
      AssertionOperator operator = AssertionOperator.exists,
      String expected = '',
    }) =>
        rule(
          target: AssertionTarget.jsonPath,
          targetArg: path,
          operator: operator,
          expected: expected,
        );

    test('exists / notExists', () {
      expectOutcome(j(), response, AssertionOutcome.passed);
      expectOutcome(j(path: r'$.missing'), response, AssertionOutcome.failed);
      expectOutcome(
        j(path: r'$.missing', operator: AssertionOperator.notExists),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        j(operator: AssertionOperator.notExists),
        response,
        AssertionOutcome.failed,
      );
    });

    test('equals：JSON 数字与字符串数字互认（归一化）', () {
      expectOutcome(
        j(operator: AssertionOperator.equals, expected: '200'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        j(operator: AssertionOperator.equals, expected: '201'),
        response,
        AssertionOutcome.failed,
      );
      // bool 转 'true'/'false'
      expectOutcome(
        j(
          path: r'$.data.active',
          operator: AssertionOperator.equals,
          expected: 'true',
        ),
        response,
        AssertionOutcome.passed,
      );
      // 字符串原样比较
      expectOutcome(
        j(
          path: r'$.data.token',
          operator: AssertionOperator.equals,
          expected: 'tk-1',
        ),
        response,
        AssertionOutcome.passed,
      );
    });

    test('notEquals', () {
      expectOutcome(
        j(operator: AssertionOperator.notEquals, expected: '404'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        j(operator: AssertionOperator.notEquals, expected: '200'),
        response,
        AssertionOutcome.failed,
      );
    });

    test('contains 对匹配值的字符串表示', () {
      expectOutcome(
        j(
          path: r'$.data.token',
          operator: AssertionOperator.contains,
          expected: 'tk',
        ),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        j(
          path: r'$.data.token',
          operator: AssertionOperator.contains,
          expected: 'xx',
        ),
        response,
        AssertionOutcome.failed,
      );
    });

    test('数值操作符：值可转 num', () {
      expectOutcome(
        j(
          path: r'$.data.expire',
          operator: AssertionOperator.gt,
          expected: '3600',
        ),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        j(
          path: r'$.data.expire',
          operator: AssertionOperator.lt,
          expected: '3600',
        ),
        response,
        AssertionOutcome.failed,
      );

      // 值不是数字
      final notNumber = evalOne(
        j(
          path: r'$.data.token',
          operator: AssertionOperator.gt,
          expected: '1',
        ),
        response,
      );
      expect(notNumber.outcome, AssertionOutcome.failed);
      expect(notNumber.message, 'value is not a number');

      // 期望值不是数字
      final badExpected = evalOne(
        j(
          path: r'$.data.expire',
          operator: AssertionOperator.gt,
          expected: 'abc',
        ),
        response,
      );
      expect(badExpected.outcome, AssertionOutcome.failed);
      expect(badExpected.message, 'expected not a number');
    });

    test('path not found：非 exists/notExists 操作符判失败', () {
      final result = evalOne(
        j(
          path: r'$.missing',
          operator: AssertionOperator.equals,
          expected: '1',
        ),
        response,
      );
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'path not found');
    });

    test('非法 JSON body → failed response body is not valid JSON', () {
      final result = evalOne(j(), resp(body: 'not json'));
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'response body is not valid JSON');
    });

    test('body 为 null → failed response body is not valid JSON', () {
      final result = evalOne(j(), resp(statusCode: 204));
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'response body is not valid JSON');
    });

    test('非法 JSONPath 表达式 → failed invalid JSONPath expression', () {
      final result = evalOne(j(path: r'$['), response);
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'invalid JSONPath expression');
    });

    test('targetArg 与 expected 均支持 {{var}} 插值', () {
      final result = evalOne(
        j(
          path: r'$.data.{{field}}',
          operator: AssertionOperator.equals,
          expected: '{{expectedToken}}',
        ),
        response,
        variables: {'field': 'token', 'expectedToken': 'tk-1'},
      );
      expect(result.outcome, AssertionOutcome.passed);
    });
  });

  group('responseTime', () {
    final response = resp(statusCode: 200, durationMs: 120);

    AssertionRule t({
      AssertionOperator operator = AssertionOperator.lt,
      String expected = '200',
    }) =>
        rule(
          target: AssertionTarget.responseTime,
          operator: operator,
          expected: expected,
        );

    test('lt / lte / gt / gte', () {
      expectOutcome(t(), response, AssertionOutcome.passed);
      expectOutcome(t(expected: '100'), response, AssertionOutcome.failed);
      expectOutcome(
        t(operator: AssertionOperator.lte, expected: '120'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        t(operator: AssertionOperator.gt, expected: '100'),
        response,
        AssertionOutcome.passed,
      );
      expectOutcome(
        t(operator: AssertionOperator.gte, expected: '121'),
        response,
        AssertionOutcome.failed,
      );
    });

    test('durationMs 为 null → failed no timing info', () {
      final result = evalOne(t(), resp(statusCode: 200));
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'no timing info');
    });

    test('期望值非数字 → failed expected not a number', () {
      final result = evalOne(t(expected: 'fast'), response);
      expect(result.outcome, AssertionOutcome.failed);
      expect(result.message, 'expected not a number');
    });
  });
}
