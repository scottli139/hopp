import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/environment.dart';

void main() {
  group('EnvironmentVariable', () {
    test('should create with required fields', () {
      const variable = EnvironmentVariable(
        id: 'v1',
        key: 'baseUrl',
        value: 'https://api.example.com',
      );

      expect(variable.id, 'v1');
      expect(variable.key, 'baseUrl');
      expect(variable.value, 'https://api.example.com');
      expect(variable.type, VariableType.string);
      expect(variable.enabled, true);
      expect(variable.isSecret, false);
    });

    test('empty() should create blank variable with unique id', () {
      final a = EnvironmentVariable.empty();
      final b = EnvironmentVariable.empty();

      expect(a.key, '');
      expect(a.value, '');
      expect(a.id, isNotEmpty);
    });

    test('isSecret should reflect type', () {
      const secret = EnvironmentVariable(
        id: 'v1',
        key: 'token',
        value: 'abc',
        type: VariableType.secret,
      );

      expect(secret.isSecret, true);
    });

    test('copyWith should update fields', () {
      const variable = EnvironmentVariable(id: 'v1', key: 'k', value: 'v');
      final updated = variable.copyWith(
        value: 'v2',
        enabled: false,
        type: VariableType.secret,
      );

      expect(updated.value, 'v2');
      expect(updated.enabled, false);
      expect(updated.type, VariableType.secret);
      expect(updated.key, 'k');
    });

    test('toJson/fromJson round-trip', () {
      const variable = EnvironmentVariable(
        id: 'v1',
        key: 'token',
        value: 'secret',
        type: VariableType.secret,
        enabled: false,
      );

      final restored = EnvironmentVariable.fromJson(variable.toJson());

      expect(restored, equals(variable));
    });
  });

  group('Environment', () {
    test('should create with defaults', () {
      const env = Environment(id: 'e1', name: 'Dev');

      expect(env.id, 'e1');
      expect(env.name, 'Dev');
      expect(env.description, isNull);
      expect(env.variables, isEmpty);
      expect(env.sortOrder, 0);
    });

    test('empty() should create with default name', () {
      final env = Environment.empty();

      expect(env.name, 'New Environment');
      expect(env.id, isNotEmpty);
    });

    test('toVariableMap should include only enabled non-empty keys', () {
      const env = Environment(
        id: 'e1',
        name: 'Dev',
        variables: [
          EnvironmentVariable(id: 'v1', key: 'a', value: '1'),
          EnvironmentVariable(id: 'v2', key: 'b', value: '2', enabled: false),
          EnvironmentVariable(id: 'v3', key: '', value: '3'),
          EnvironmentVariable(id: 'v4', key: 'c', value: '4'),
        ],
      );

      final map = env.toVariableMap();

      expect(map, {'a': '1', 'c': '4'});
    });

    test('toVariableMap should keep last value for duplicate keys', () {
      const env = Environment(
        id: 'e1',
        name: 'Dev',
        variables: [
          EnvironmentVariable(id: 'v1', key: 'a', value: '1'),
          EnvironmentVariable(id: 'v2', key: 'a', value: '2'),
        ],
      );

      expect(env.toVariableMap()['a'], '2');
    });

    test('toJson/fromJson round-trip', () {
      const env = Environment(
        id: 'e1',
        name: 'Staging',
        description: 'Staging environment',
        sortOrder: 2,
        variables: [
          EnvironmentVariable(
            id: 'v1',
            key: 'token',
            value: 'abc',
            type: VariableType.secret,
          ),
        ],
      );

      // 顶层字段序列化
      final json = env.toJson();
      expect(json['id'], 'e1');
      expect(json['name'], 'Staging');
      expect(json['description'], 'Staging environment');
      expect(json['sortOrder'], 2);

      // 从深层 JSON map 反序列化（与 toJson 输出结构一致）
      final restored = Environment.fromJson({
        'id': 'e1',
        'name': 'Staging',
        'description': 'Staging environment',
        'sortOrder': 2,
        'variables': [
          {
            'id': 'v1',
            'key': 'token',
            'value': 'abc',
            'type': 'secret',
            'enabled': true,
          },
        ],
      });

      expect(restored, equals(env));
    });
  });
}
