import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// 只导入自定义适配器，隐藏自动生成的适配器
import 'package:hopp/models/adapters/http_request_adapter.dart'
    as custom_adapters;
import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/models/auth_config.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart' hide HttpRequestAdapter;
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/models/pre_request_step.dart';

void main() {
  group('AssertionRule', () {
    group('creation', () {
      test('should create with all fields', () {
        const rule = AssertionRule(
          id: 'a1',
          enabled: false,
          target: AssertionTarget.header,
          targetArg: 'Content-Type',
          operator: AssertionOperator.contains,
          expected: 'json',
        );

        expect(rule.id, equals('a1'));
        expect(rule.enabled, isFalse);
        expect(rule.target, equals(AssertionTarget.header));
        expect(rule.targetArg, equals('Content-Type'));
        expect(rule.operator, equals(AssertionOperator.contains));
        expect(rule.expected, equals('json'));
      });

      test('should have correct default values', () {
        const rule = AssertionRule(id: 'a1');

        expect(rule.enabled, isTrue);
        expect(rule.target, equals(AssertionTarget.status));
        expect(rule.targetArg, equals(''));
        expect(rule.operator, equals(AssertionOperator.equals));
        expect(rule.expected, equals(''));
      });
    });

    group('JSON serialization', () {
      test('toJson / fromJson 往返一致', () {
        const rule = AssertionRule(
          id: 'a1',
          enabled: false,
          target: AssertionTarget.jsonPath,
          targetArg: r'$.data.token',
          operator: AssertionOperator.exists,
        );

        final restored = AssertionRule.fromJson(rule.toJson());
        expect(restored, equals(rule));
      });

      test('序列化使用枚举 name', () {
        const rule = AssertionRule(
          id: 'a1',
          target: AssertionTarget.responseTime,
          operator: AssertionOperator.lte,
          expected: '500',
        );

        final json = rule.toJson();
        expect(json['target'], equals('responseTime'));
        expect(json['operator'], equals('lte'));
      });

      test('fromJson 缺失字段使用默认值', () {
        final rule = AssertionRule.fromJson(const {'id': 'a1'});

        expect(rule.enabled, isTrue);
        expect(rule.target, equals(AssertionTarget.status));
        expect(rule.operator, equals(AssertionOperator.equals));
      });

      test('所有目标与操作符枚举值可往返', () {
        for (final target in AssertionTarget.values) {
          for (final operator in AssertionOperator.values) {
            final rule = AssertionRule(
              id: 'a1',
              target: target,
              operator: operator,
            );
            expect(
              AssertionRule.fromJson(rule.toJson()),
              equals(rule),
              reason: 'Failed for ${target.name}/${operator.name}',
            );
          }
        }
      });
    });

    group('HttpRequest.assertions', () {
      test('默认空列表，copyWith 可设置', () {
        const request = HttpRequest(id: 'r1', name: 'Test');
        expect(request.assertions, isEmpty);

        final copied = request.copyWith(
          assertions: [
            const AssertionRule(id: 'a1', expected: '200'),
          ],
        );
        expect(copied.assertions, hasLength(1));
        expect(copied.assertions.single.expected, equals('200'));
      });

      test('随请求 JSON 反序列化', () {
        // 注意：HttpRequest.toJson() 不深度序列化嵌套对象（既有行为，
        // 无 explicit_to_json），这里与现有测试一致，用手工 JSON 验证 fromJson
        final request = HttpRequest.fromJson(const {
          'id': 'r1',
          'name': 'Test',
          'assertions': [
            {
              'id': 'a1',
              'enabled': true,
              'target': 'body',
              'targetArg': '',
              'operator': 'contains',
              'expected': 'ok',
            },
          ],
        });

        expect(request.assertions, hasLength(1));
        expect(request.assertions.single.target, AssertionTarget.body);
        expect(request.assertions.single.expected, 'ok');
      });
    });

    group('Hive adapter', () {
      late Directory tempDir;

      setUpAll(() {
        tempDir = Directory.systemTemp.createTempSync('hopp_assertion_test');
        // 与 StorageService._registerAdapters() 保持一致（HttpRequest 嵌套
        // 类型的 adapter 也需注册，否则写入时抛异常）
        Hive
          ..init(tempDir.path)
          ..registerAdapter(HttpMethodAdapter())
          ..registerAdapter(KeyValuePairAdapter())
          ..registerAdapter(AuthTypeAdapter())
          ..registerAdapter(AuthConfigAdapter())
          ..registerAdapter(ExtractionSourceTypeAdapter())
          ..registerAdapter(ExtractionRuleAdapter())
          ..registerAdapter(PreRequestStepAdapter())
          ..registerAdapter(AssertionTargetAdapter())
          ..registerAdapter(AssertionOperatorAdapter())
          ..registerAdapter(AssertionRuleAdapter())
          ..registerAdapter(custom_adapters.HttpRequestAdapter());
      });

      tearDownAll(() async {
        await Hive.close();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('typeId 分配正确', () {
        expect(AssertionRuleAdapter().typeId, equals(19));
        expect(AssertionTargetAdapter().typeId, equals(20));
        expect(AssertionOperatorAdapter().typeId, equals(21));
      });

      test('AssertionRule 写入/读出往返', () async {
        final box = await Hive.openBox<AssertionRule>('assertion_rules');
        const rule = AssertionRule(
          id: 'a1',
          enabled: false,
          target: AssertionTarget.jsonPath,
          targetArg: r'$.data.items[0].id',
          operator: AssertionOperator.gte,
          expected: '10',
        );

        await box.put('a1', rule);
        final restored = box.get('a1');

        expect(restored, isNotNull);
        expect(restored, equals(rule));
        await box.deleteFromDisk();
      });

      test('HttpRequest 携带断言经自定义 adapter 往返（field 17）', () async {
        final box = await Hive.openBox<HttpRequest>('requests_with_assertions');
        const request = HttpRequest(
          id: 'r1',
          name: 'Test',
          method: HttpMethod.post,
          assertions: [
            AssertionRule(id: 'a1', expected: '200'),
            AssertionRule(
              id: 'a2',
              enabled: false,
              target: AssertionTarget.header,
              targetArg: 'X-Trace',
              operator: AssertionOperator.exists,
            ),
          ],
        );

        await box.put('r1', request);
        final restored = box.get('r1');

        expect(restored, isNotNull);
        expect(restored!.assertions, hasLength(2));
        expect(restored.assertions[0], equals(request.assertions[0]));
        expect(restored.assertions[1], equals(request.assertions[1]));
        await box.deleteFromDisk();
      });
    });
  });
}
