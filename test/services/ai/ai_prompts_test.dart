import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/services/ai/ai_prompts.dart';
import 'package:hopp/services/ai/llm_client.dart';

void main() {
  group('buildExplainPrompt', () {
    test('包含状态行与响应体', () {
      final messages = AiPrompts.buildExplainPrompt(
        statusCode: 404,
        statusText: 'Not Found',
        body: '{"error": "no such user"}',
      );

      expect(messages.length, equals(2));
      expect(messages[0].role, equals('system'));
      expect(messages[1].role, equals('user'));
      expect(messages[1].content, contains('HTTP 404 Not Found'));
      expect(messages[1].content, contains('{"error": "no such user"}'));
    });

    test('system 提示词含「只能基于给出的响应内容」防脑补约束', () {
      final messages = AiPrompts.buildExplainPrompt(
        statusCode: 200,
        statusText: 'OK',
        body: '{}',
      );

      expect(messages[0].content, contains('只能基于给出的响应内容'));
    });

    test('body 超过 8KB 截断且含截断标注', () {
      final bigBody = 'a' * 9000;
      final messages = AiPrompts.buildExplainPrompt(
        statusCode: 200,
        statusText: 'OK',
        body: bigBody,
      );

      final userContent = messages[1].content;
      expect(userContent.length, lessThan(bigBody.length));
      expect(userContent, contains('已截断'));
      // 截断标注之后的原文不再出现
      expect(userContent.contains('a' * 8300), isFalse);
    });

    test('body 不超过 8KB 时不加截断标注', () {
      final messages = AiPrompts.buildExplainPrompt(
        statusCode: 200,
        statusText: 'OK',
        body: 'short',
      );

      expect(messages[1].content, isNot(contains('已截断')));
    });
  });

  group('buildAssertionPrompt', () {
    const responseBody = '{"id": 1, "name": "hopp"}';

    List<LlmMessage> build() => AiPrompts.buildAssertionPrompt(
          method: 'GET',
          url: 'http://x/users',
          responseBody: responseBody,
        );

    test('user 含请求方法与 URL、响应样本', () {
      final messages = build();
      expect(messages[1].content, contains('GET http://x/users'));
      expect(messages[1].content, contains(responseBody));
    });

    test('响应样本超过 8KB 截断且含截断标注（防超大 body 撑爆 context）', () {
      final bigBody = 'b' * 9000;
      final messages = AiPrompts.buildAssertionPrompt(
        method: 'GET',
        url: 'http://x/users',
        responseBody: bigBody,
      );

      final userContent = messages[1].content;
      expect(userContent.length, lessThan(bigBody.length));
      expect(userContent, contains('已截断'));
      expect(userContent.contains('b' * 8300), isFalse);
    });

    test('响应样本不超过 8KB 时不加截断标注', () {
      final messages = build();
      expect(messages[1].content, isNot(contains('已截断')));
    });

    test('要求只输出严格 JSON、不要 markdown 代码围栏', () {
      final system = build().first.content;
      expect(system, contains('只输出严格 JSON'));
      expect(system, contains('不要输出 markdown 代码围栏'));
    });

    test('含防脑补硬约束（expected 只能来自响应样本）', () {
      final system = build().first.content;
      expect(system, contains('expected'));
      expect(system, contains('只能来自响应样本'));
      expect(system, contains('禁止脑补'));
    });

    test('枚举值与 assertion_rule.dart 完全一致', () {
      final system = build().first.content;
      for (final target in AssertionTarget.values) {
        expect(system, contains(target.name), reason: 'target ${target.name}');
      }
      for (final operator in AssertionOperator.values) {
        expect(system, contains(operator.name),
            reason: 'operator ${operator.name}',);
      }
      // 组合矩阵提示
      expect(system, contains('${AssertionTarget.status.name}:'));
    });
  });

  group('buildRequestPrompt', () {
    test('user 含用户描述原文', () {
      final messages = AiPrompts.buildRequestPrompt(
        description: '创建一个用户，名字叫 tom',
      );
      expect(messages.length, equals(2));
      expect(messages[1].content, contains('创建一个用户，名字叫 tom'));
    });

    test('含只输出严格 JSON 与输出格式说明', () {
      final system = AiPrompts.buildRequestPrompt(description: 'x').first.content;
      expect(system, contains('只输出严格 JSON'));
      expect(system, contains('"method"'));
      expect(system, contains('"bodyType"'));
      expect(system, contains('form-urlencoded'));
      expect(system, contains('multipart'));
    });

    test('含防脑补硬约束与 {{var}} 支持', () {
      final system = AiPrompts.buildRequestPrompt(description: 'x').first.content;
      expect(system, contains('只能来自用户描述'));
      expect(system, contains('缺失'));
      expect(system, contains('禁止脑补'));
      expect(system, contains('{{var}}'));
    });
  });
}
