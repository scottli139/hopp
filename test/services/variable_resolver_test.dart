import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/services/variable_resolver.dart';

void main() {
  late VariableResolver resolver;

  setUp(() {
    resolver = VariableResolver();
  });

  group('resolve', () {
    test('should replace single variable', () {
      final result = resolver.resolve(
        'https://{{host}}/api',
        {'host': 'example.com'},
      );

      expect(result, 'https://example.com/api');
    });

    test('should replace multiple occurrences of same variable', () {
      final result = resolver.resolve(
        '{{host}}/{{host}}',
        {'host': 'x'},
      );

      expect(result, 'x/x');
    });

    test('should tolerate whitespace inside braces', () {
      final result = resolver.resolve(
        '{{ host }}',
        {'host': 'example.com'},
      );

      expect(result, 'example.com');
    });

    test('should keep unknown variables as-is', () {
      final result = resolver.resolve(
        'https://{{unknown}}/api',
        {'host': 'example.com'},
      );

      expect(result, 'https://{{unknown}}/api');
    });

    test('should return input unchanged when no placeholders', () {
      final result = resolver.resolve('plain text', {'a': '1'});

      expect(result, 'plain text');
    });

    test('should handle adjacent placeholders', () {
      final result = resolver.resolve(
        '{{a}}{{b}}',
        {'a': '1', 'b': '2'},
      );

      expect(result, '12');
    });
  });

  group('dynamic variables', () {
    test(r'$timestamp should resolve to unix seconds', () {
      final result = resolver.resolve('{{\$timestamp}}', {});

      final seconds = int.tryParse(result);
      expect(seconds, isNotNull);
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      expect((nowSeconds - seconds!).abs(), lessThan(5));
    });

    test(r'$timestampMs should resolve to unix milliseconds', () {
      final result = resolver.resolve('{{\$timestampMs}}', {});

      final ms = int.tryParse(result);
      expect(ms, isNotNull);
      expect(ms!, greaterThan(1000000000000));
    });

    test(r'$isoTimestamp should resolve to ISO 8601 string', () {
      final result = resolver.resolve('{{\$isoTimestamp}}', {});

      expect(DateTime.tryParse(result), isNotNull);
    });

    test(r'$randomUUID should resolve to UUID v4 format', () {
      final result = resolver.resolve('{{\$randomUUID}}', {});

      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(result),
        true,
      );
    });

    test(r'$randomInt should resolve to integer in range', () {
      final result = resolver.resolve('{{\$randomInt}}', {});

      final value = int.tryParse(result);
      expect(value, isNotNull);
      expect(value!, inInclusiveRange(0, 1000000));
    });

    test('unknown dynamic variable should be kept as-is', () {
      final result = resolver.resolve('{{\$unknownDynamic}}', {});

      expect(result, '{{\$unknownDynamic}}');
    });
  });

  group('findUnresolved', () {
    test('should list variables not in map', () {
      final unresolved = resolver.findUnresolved(
        '{{a}}/{{b}}/{{c}}',
        {'a': '1'},
      );

      expect(unresolved, ['b', 'c']);
    });

    test('should not list dynamic variables as unresolved', () {
      final unresolved = resolver.findUnresolved('{{\$timestamp}}', {});

      expect(unresolved, isEmpty);
    });

    test('should list unknown dynamic variables', () {
      final unresolved = resolver.findUnresolved('{{\$foo}}', {});

      expect(unresolved, ['\$foo']);
    });

    test('should deduplicate names', () {
      final unresolved = resolver.findUnresolved('{{a}}{{a}}', {});

      expect(unresolved, ['a']);
    });
  });

  group('buildScope', () {
    test('should merge globals and environment variables', () {
      final scope = VariableResolver.buildScope(
        globals: const [
          EnvironmentVariable(id: 'g1', key: 'shared', value: 'global'),
        ],
        activeEnvironment: const Environment(
          id: 'e1',
          name: 'Dev',
          variables: [
            EnvironmentVariable(id: 'v1', key: 'host', value: 'dev.local'),
          ],
        ),
      );

      expect(scope, {'shared': 'global', 'host': 'dev.local'});
    });

    test('environment variable should override global with same key', () {
      final scope = VariableResolver.buildScope(
        globals: const [
          EnvironmentVariable(id: 'g1', key: 'host', value: 'global.local'),
        ],
        activeEnvironment: const Environment(
          id: 'e1',
          name: 'Dev',
          variables: [
            EnvironmentVariable(id: 'v1', key: 'host', value: 'dev.local'),
          ],
        ),
      );

      expect(scope['host'], 'dev.local');
    });

    test('disabled variables should be excluded', () {
      final scope = VariableResolver.buildScope(
        globals: const [
          EnvironmentVariable(id: 'g1', key: 'a', value: '1', enabled: false),
        ],
        activeEnvironment: const Environment(
          id: 'e1',
          name: 'Dev',
          variables: [
            EnvironmentVariable(id: 'v1', key: 'b', value: '2', enabled: false),
          ],
        ),
      );

      expect(scope, isEmpty);
    });

    test('null environment should yield globals only', () {
      final scope = VariableResolver.buildScope(
        globals: const [
          EnvironmentVariable(id: 'g1', key: 'a', value: '1'),
        ],
      );

      expect(scope, {'a': '1'});
    });
  });

  group('resolveRequest', () {
    HttpRequest buildRequest() {
      return HttpRequest.empty().copyWith(
        method: HttpMethod.post,
        url: 'https://{{host}}/api/{{version}}',
        params: [
          KeyValuePair.empty().copyWith(key: 'token', value: '{{token}}'),
          KeyValuePair.empty().copyWith(key: 'static', value: 'plain'),
        ],
        headers: [
          KeyValuePair.empty()
              .copyWith(key: 'Authorization', value: 'Bearer {{token}}'),
        ],
        body: '{"user": "{{username}}"}',
      );
    }

    test('should resolve url, params, headers and body', () {
      final variables = {
        'host': 'example.com',
        'version': 'v1',
        'token': 'abc123',
        'username': 'hopp',
      };

      final resolved = resolver.resolveRequest(buildRequest(), variables);

      expect(resolved.url, 'https://example.com/api/v1');
      expect(resolved.params[0].value, 'abc123');
      expect(resolved.params[1].value, 'plain');
      expect(resolved.headers[0].value, 'Bearer abc123');
      expect(resolved.body, '{"user": "hopp"}');
    });

    test('should keep unresolved placeholders as-is', () {
      final resolved = resolver.resolveRequest(buildRequest(), {});

      expect(resolved.url, 'https://{{host}}/api/{{version}}');
      expect(resolved.headers[0].value, 'Bearer {{token}}');
    });

    test('should not mutate the original request', () {
      final request = buildRequest();
      resolver.resolveRequest(request, {'host': 'example.com'});

      expect(request.url, 'https://{{host}}/api/{{version}}');
    });
  });

  group('findUnresolvedInRequest', () {
    test('should collect unresolved from all request parts', () {
      final request = HttpRequest.empty().copyWith(
        url: 'https://{{host}}',
        params: [KeyValuePair.empty().copyWith(key: 'a', value: '{{p1}}')],
        headers: [KeyValuePair.empty().copyWith(key: 'X', value: '{{h1}}')],
        body: '{{b1}}',
      );

      final unresolved = resolver.findUnresolvedInRequest(request, {});

      expect(unresolved, containsAll(['host', 'p1', 'h1', 'b1']));
    });

    test('should return empty when everything resolves', () {
      final request = HttpRequest.empty().copyWith(url: 'https://{{host}}');

      final unresolved =
          resolver.findUnresolvedInRequest(request, {'host': 'x'});

      expect(unresolved, isEmpty);
    });
  });
}
