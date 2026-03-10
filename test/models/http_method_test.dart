import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_method.dart';

void main() {
  group('HttpMethod', () {
    group('values', () {
      test('should have correct values for all methods', () {
        expect(HttpMethod.get.value, equals('GET'));
        expect(HttpMethod.post.value, equals('POST'));
        expect(HttpMethod.put.value, equals('PUT'));
        expect(HttpMethod.delete.value, equals('DELETE'));
        expect(HttpMethod.patch.value, equals('PATCH'));
        expect(HttpMethod.head.value, equals('HEAD'));
        expect(HttpMethod.options.value, equals('OPTIONS'));
      });

      test('should have exactly 7 HTTP methods', () {
        expect(HttpMethod.values.length, equals(7));
      });
    });

    group('fromString', () {
      test('should convert uppercase strings correctly', () {
        expect(HttpMethod.fromString('GET'), equals(HttpMethod.get));
        expect(HttpMethod.fromString('POST'), equals(HttpMethod.post));
        expect(HttpMethod.fromString('PUT'), equals(HttpMethod.put));
        expect(HttpMethod.fromString('DELETE'), equals(HttpMethod.delete));
        expect(HttpMethod.fromString('PATCH'), equals(HttpMethod.patch));
        expect(HttpMethod.fromString('HEAD'), equals(HttpMethod.head));
        expect(HttpMethod.fromString('OPTIONS'), equals(HttpMethod.options));
      });

      test('should convert lowercase strings correctly', () {
        expect(HttpMethod.fromString('get'), equals(HttpMethod.get));
        expect(HttpMethod.fromString('post'), equals(HttpMethod.post));
        expect(HttpMethod.fromString('put'), equals(HttpMethod.put));
        expect(HttpMethod.fromString('delete'), equals(HttpMethod.delete));
      });

      test('should convert mixed case strings correctly', () {
        expect(HttpMethod.fromString('Get'), equals(HttpMethod.get));
        expect(HttpMethod.fromString('PoSt'), equals(HttpMethod.post));
        expect(HttpMethod.fromString('PUT'), equals(HttpMethod.put));
      });

      test('should return GET for unknown method strings', () {
        expect(HttpMethod.fromString('UNKNOWN'), equals(HttpMethod.get));
        expect(HttpMethod.fromString(''), equals(HttpMethod.get));
        expect(HttpMethod.fromString('INVALID'), equals(HttpMethod.get));
        expect(HttpMethod.fromString('TRACE'), equals(HttpMethod.get));
      });

      test('should return GET for whitespace strings', () {
        expect(HttpMethod.fromString(' '), equals(HttpMethod.get));
        expect(HttpMethod.fromString('  GET  '), equals(HttpMethod.get));
      });
    });

    group('toString', () {
      test('should return the correct string value', () {
        expect(HttpMethod.get.toString(), equals('GET'));
        expect(HttpMethod.post.toString(), equals('POST'));
        expect(HttpMethod.put.toString(), equals('PUT'));
        expect(HttpMethod.delete.toString(), equals('DELETE'));
      });
    });

    group('equality', () {
      test('same methods should be equal', () {
        expect(HttpMethod.get, equals(HttpMethod.get));
        expect(HttpMethod.post, equals(HttpMethod.post));
      });

      test('different methods should not be equal', () {
        expect(HttpMethod.get, isNot(equals(HttpMethod.post)));
        expect(HttpMethod.put, isNot(equals(HttpMethod.delete)));
      });
    });
  });
}
