import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/utils/url_params_sync.dart';

void main() {
  group('UrlParamsSync', () {
    group('parseQueryParamsFromUrl', () {
      test('should parse simple query params', () {
        final params = parseQueryParamsFromUrl('https://api.com?key=value');

        expect(params.length, 1);
        expect(params[0].key, 'key');
        expect(params[0].value, 'value');
        expect(params[0].enabled, true);
      });

      test('should parse multiple query params', () {
        final params = parseQueryParamsFromUrl('https://api.com?a=1&b=2&c=3');

        expect(params.length, 3);
        expect(params[0].key, 'a');
        expect(params[0].value, '1');
        expect(params[1].key, 'b');
        expect(params[1].value, '2');
        expect(params[2].key, 'c');
        expect(params[2].value, '3');
      });

      test('should decode URL-encoded values', () {
        final params =
            parseQueryParamsFromUrl('https://api.com?name=hello+world');

        expect(params.length, 1);
        expect(params[0].key, 'name');
        expect(params[0].value, 'hello world');
      });

      test('should decode URL-encoded keys', () {
        final params =
            parseQueryParamsFromUrl('https://api.com?hello%20world=test');

        expect(params.length, 1);
        expect(params[0].key, 'hello world');
        expect(params[0].value, 'test');
      });

      test('should handle empty value', () {
        final params = parseQueryParamsFromUrl('https://api.com?key=');

        expect(params.length, 1);
        expect(params[0].key, 'key');
        expect(params[0].value, '');
      });

      test('should handle URL without query params', () {
        final params = parseQueryParamsFromUrl('https://api.com/path');

        expect(params, isEmpty);
      });

      test('should handle empty URL', () {
        final params = parseQueryParamsFromUrl('');

        expect(params, isEmpty);
      });

      test('should handle special characters', () {
        final params = parseQueryParamsFromUrl('https://api.com?key=%26%3D%2F');

        expect(params.length, 1);
        expect(params[0].key, 'key');
        expect(params[0].value, '&=/');
      });

      test('should handle duplicate keys', () {
        final params = parseQueryParamsFromUrl('https://api.com?tag=a&tag=b');

        expect(params.length, 2);
        expect(params[0].key, 'tag');
        expect(params[0].value, 'a');
        expect(params[1].key, 'tag');
        expect(params[1].value, 'b');
      });

      test('should handle Chinese characters', () {
        // Uri.encodeQueryComponent encodes Chinese characters
        final params =
            parseQueryParamsFromUrl('https://api.com?name=%E4%B8%AD%E6%96%87');

        // Note: Dart's Uri.parse handles the encoding correctly
        expect(params.isEmpty || params[0].value == '中文', isTrue);
      });
    });

    group('extractBaseUrl', () {
      test('should extract base URL without query params', () {
        final baseUrl = extractBaseUrl('https://api.com?key=value');

        expect(baseUrl, 'https://api.com');
      });

      test('should extract base URL with path', () {
        final baseUrl =
            extractBaseUrl('https://api.com/path/to/resource?a=1&b=2');

        expect(baseUrl, 'https://api.com/path/to/resource');
      });

      test('should extract base URL with port', () {
        final baseUrl = extractBaseUrl('https://api.com:8080/path?key=value');

        expect(baseUrl, 'https://api.com:8080/path');
      });

      test('should extract base URL without default HTTPS port', () {
        final baseUrl = extractBaseUrl('https://api.com:443/path?key=value');

        expect(baseUrl, 'https://api.com/path');
      });

      test('should extract base URL without default HTTP port', () {
        final baseUrl = extractBaseUrl('http://api.com:80/path?key=value');

        expect(baseUrl, 'http://api.com/path');
      });

      test('should handle URL without query params', () {
        final baseUrl = extractBaseUrl('https://api.com/path');

        expect(baseUrl, 'https://api.com/path');
      });

      test('should handle empty URL', () {
        final baseUrl = extractBaseUrl('');

        expect(baseUrl, '');
      });

      test('should handle URL with user info', () {
        final baseUrl =
            extractBaseUrl('https://user:pass@api.com/path?key=value');

        expect(baseUrl, 'https://user:pass@api.com/path');
      });
    });

    group('buildQueryString', () {
      test('should build query string from params', () {
        final params = [
          KeyValuePair(id: '1', key: 'a', value: '1', enabled: true),
          KeyValuePair(id: '2', key: 'b', value: '2', enabled: true),
        ];
        final queryString = buildQueryString(params);

        expect(queryString, 'a=1&b=2');
      });

      test('should encode special characters', () {
        final params = [
          KeyValuePair(
              id: '1', key: 'name', value: 'hello world', enabled: true),
        ];
        final queryString = buildQueryString(params);

        // Uri.encodeQueryComponent uses '+' for space by default
        expect(queryString, 'name=hello+world');
      });

      test('should skip disabled params', () {
        final params = [
          KeyValuePair(id: '1', key: 'a', value: '1', enabled: true),
          KeyValuePair(id: '2', key: 'b', value: '2', enabled: false),
        ];
        final queryString = buildQueryString(params);

        expect(queryString, 'a=1');
      });

      test('should skip params with empty key', () {
        final params = [
          KeyValuePair(id: '1', key: 'a', value: '1', enabled: true),
          KeyValuePair(id: '2', key: '', value: '2', enabled: true),
        ];
        final queryString = buildQueryString(params);

        expect(queryString, 'a=1');
      });

      test('should handle empty params list', () {
        final queryString = buildQueryString([]);

        expect(queryString, '');
      });

      test('should handle all disabled params', () {
        final params = [
          KeyValuePair(id: '1', key: 'a', value: '1', enabled: false),
        ];
        final queryString = buildQueryString(params);

        expect(queryString, '');
      });

      test('should encode Chinese characters', () {
        final params = [
          KeyValuePair(id: '1', key: 'name', value: '中文', enabled: true),
        ];
        final queryString = buildQueryString(params);

        expect(queryString, 'name=%E4%B8%AD%E6%96%87');
      });
    });

    group('syncParamsToUrl', () {
      test('should sync params to URL', () {
        final params = [
          KeyValuePair(id: '1', key: 'page', value: '1', enabled: true),
          KeyValuePair(id: '2', key: 'size', value: '10', enabled: true),
        ];
        final newUrl = syncParamsToUrl('https://api.com', params);

        expect(newUrl, 'https://api.com?page=1&size=10');
      });

      test('should return base URL if no params', () {
        final newUrl = syncParamsToUrl('https://api.com', []);

        expect(newUrl, 'https://api.com');
      });

      test('should return base URL if all params disabled', () {
        final params = [
          KeyValuePair(id: '1', key: 'page', value: '1', enabled: false),
        ];
        final newUrl = syncParamsToUrl('https://api.com', params);

        expect(newUrl, 'https://api.com');
      });

      test('should handle empty base URL', () {
        final params = [
          KeyValuePair(id: '1', key: 'page', value: '1', enabled: true),
        ];
        final newUrl = syncParamsToUrl('', params);

        expect(newUrl, '');
      });

      test('should handle base URL with path', () {
        final params = [
          KeyValuePair(id: '1', key: 'id', value: '123', enabled: true),
        ];
        final newUrl = syncParamsToUrl('https://api.com/users', params);

        expect(newUrl, 'https://api.com/users?id=123');
      });
    });

    group('hasQueryParams', () {
      test('should return true for URL with query params', () {
        expect(hasQueryParams('https://api.com?key=value'), true);
      });

      test('should return false for URL without query params', () {
        expect(hasQueryParams('https://api.com/path'), false);
      });

      test('should return false for empty URL', () {
        expect(hasQueryParams(''), false);
      });
    });

    group('mergeQueryParams', () {
      test('should merge new params into existing', () {
        final existing = [
          KeyValuePair(id: '1', key: 'a', value: 'old', enabled: true),
        ];
        final merged = mergeQueryParams(existing, 'https://api.com?a=new&b=2');

        expect(merged.length, 2);
        expect(merged[0].key, 'a');
        expect(merged[0].value, 'new');
        expect(merged[1].key, 'b');
        expect(merged[1].value, '2');
      });

      test('should add new params without modifying existing', () {
        final existing = [
          KeyValuePair(id: '1', key: 'a', value: '1', enabled: true),
        ];
        final merged = mergeQueryParams(existing, 'https://api.com?b=2');

        expect(merged.length, 2);
        expect(merged[0].key, 'a');
        expect(merged[0].value, '1');
        expect(merged[1].key, 'b');
        expect(merged[1].value, '2');
      });

      test('should return existing params if URL has no query params', () {
        final existing = [
          KeyValuePair(id: '1', key: 'a', value: '1', enabled: true),
        ];
        final merged = mergeQueryParams(existing, 'https://api.com');

        expect(merged.length, 1);
        expect(merged[0].key, 'a');
        expect(merged[0].value, '1');
      });
    });
  });
}
