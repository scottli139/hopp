import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/key_value_pair.dart';

void main() {
  group('KeyValuePair', () {
    group('creation', () {
      test('should create KeyValuePair with all required fields', () {
        const pair = KeyValuePair(
          id: '1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );

        expect(pair.id, equals('1'));
        expect(pair.key, equals('Content-Type'));
        expect(pair.value, equals('application/json'));
        expect(pair.enabled, isTrue);
      });

      test('should create KeyValuePair with enabled defaulting to true', () {
        const pair = KeyValuePair(
          id: '1',
          key: 'Accept',
          value: '*/*',
        );

        expect(pair.enabled, isTrue);
      });

      test('should create disabled KeyValuePair', () {
        const pair = KeyValuePair(
          id: '1',
          key: 'Authorization',
          value: 'Bearer token',
          enabled: false,
        );

        expect(pair.enabled, isFalse);
      });
    });

    group('empty factory', () {
      test('should create empty KeyValuePair with generated id', () {
        final pair = KeyValuePair.empty();

        expect(pair.id, isNotEmpty);
        expect(pair.key, equals(''));
        expect(pair.value, equals(''));
        expect(pair.enabled, isTrue);
      });

      test('should generate unique ids for multiple empty pairs', () async {
        final pair1 = KeyValuePair.empty();
        await Future<void>.delayed(const Duration(milliseconds: 2));
        final pair2 = KeyValuePair.empty();

        expect(pair1.id, isNot(equals(pair2.id)));
      });
    });

    group('copyWith', () {
      test('should copy with new key', () {
        const pair = KeyValuePair(
          id: '1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );

        final copied = pair.copyWith(key: 'Accept');

        expect(copied.id, equals('1'));
        expect(copied.key, equals('Accept'));
        expect(copied.value, equals('application/json'));
        expect(copied.enabled, isTrue);
      });

      test('should copy with new value', () {
        const pair = KeyValuePair(
          id: '1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );

        final copied = pair.copyWith(value: 'text/plain');

        expect(copied.key, equals('Content-Type'));
        expect(copied.value, equals('text/plain'));
      });

      test('should copy with new enabled state', () {
        const pair = KeyValuePair(
          id: '1',
          key: 'Authorization',
          value: 'Bearer token',
          enabled: true,
        );

        final copied = pair.copyWith(enabled: false);

        expect(copied.enabled, isFalse);
      });

      test('should copy without changes when no arguments provided', () {
        const pair = KeyValuePair(
          id: '1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );

        final copied = pair.copyWith();

        expect(copied, equals(pair));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        const pair = KeyValuePair(
          id: '1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );

        final json = pair.toJson();

        expect(json['id'], equals('1'));
        expect(json['key'], equals('Content-Type'));
        expect(json['value'], equals('application/json'));
        expect(json['enabled'], equals(true));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': '1',
          'key': 'Authorization',
          'value': 'Bearer token123',
          'enabled': false,
        };

        final pair = KeyValuePair.fromJson(json);

        expect(pair.id, equals('1'));
        expect(pair.key, equals('Authorization'));
        expect(pair.value, equals('Bearer token123'));
        expect(pair.enabled, isFalse);
      });

      test('should handle JSON with special characters', () {
        final json = {
          'id': 'special-id',
          'key': 'X-Custom-Header',
          'value': 'value with spaces & symbols!',
          'enabled': true,
        };

        final pair = KeyValuePair.fromJson(json);

        expect(pair.value, equals('value with spaces & symbols!'));
      });

      test('should handle empty string values in JSON', () {
        final json = {
          'id': 'empty-id',
          'key': '',
          'value': '',
          'enabled': true,
        };

        final pair = KeyValuePair.fromJson(json);

        expect(pair.key, equals(''));
        expect(pair.value, equals(''));
      });
    });

    group('equality', () {
      test('identical pairs should be equal', () {
        const pair1 = KeyValuePair(
          id: '1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );
        const pair2 = KeyValuePair(
          id: '1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );

        expect(pair1, equals(pair2));
      });

      test('pairs with different ids should not be equal', () {
        const pair1 = KeyValuePair(
          id: '1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );
        const pair2 = KeyValuePair(
          id: '2',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );

        expect(pair1, isNot(equals(pair2)));
      });

      test('pairs with different keys should not be equal', () {
        const pair1 = KeyValuePair(
          id: '1',
          key: 'Content-Type',
          value: 'application/json',
          enabled: true,
        );
        const pair2 = KeyValuePair(
          id: '1',
          key: 'Accept',
          value: 'application/json',
          enabled: true,
        );

        expect(pair1, isNot(equals(pair2)));
      });
    });
  });
}
