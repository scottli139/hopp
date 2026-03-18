/// cURL 解析器单元测试
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/services/curl/curl_import_service.dart';
import 'package:hopp/services/curl/curl_parser.dart';
import 'package:hopp/services/curl/curl_tokenizer.dart';

void main() {
  group('CurlTokenizer', () {
    late CurlTokenizer tokenizer;

    setUp(() {
      tokenizer = CurlTokenizer();
    });

    test('should tokenize simple GET request', () {
      final tokens = tokenizer.tokenize('curl https://api.example.com/users');

      expect(tokens.length, greaterThanOrEqualTo(3));
      expect(tokens[0].type, CurlTokenType.command);
      expect(tokens[0].value, 'curl');
      expect(tokens[1].type, CurlTokenType.url);
      expect(tokens[1].value, 'https://api.example.com/users');
    });

    test('should tokenize request with short options', () {
      final tokens = tokenizer.tokenize(
          'curl -X POST -H "Content-Type: application/json" https://api.example.com/users');

      final optionTokens =
          tokens.where((t) => t.type == CurlTokenType.optionShort).toList();
      expect(optionTokens.length, 2);
      expect(optionTokens[0].value, 'X');
      expect(optionTokens[1].value, 'H');
    });

    test('should tokenize request with long options', () {
      final tokens = tokenizer.tokenize(
          'curl --request POST --header "Content-Type: application/json" https://api.example.com');

      final optionTokens =
          tokens.where((t) => t.type == CurlTokenType.optionLong).toList();
      expect(optionTokens.length, 2);
      expect(optionTokens[0].value, 'request');
      expect(optionTokens[1].value, 'header');
    });

    test('should handle double quoted values', () {
      final tokens = tokenizer.tokenize(
          'curl -H "Content-Type: application/json" https://api.example.com');

      final valueToken =
          tokens.firstWhere((t) => t.value == 'Content-Type: application/json');
      expect(valueToken.type, CurlTokenType.value);
    });

    test('should handle single quoted values', () {
      final tokens = tokenizer
          .tokenize("curl -d '{\"name\":\"test\"}' https://api.example.com");

      final valueToken = tokens.firstWhere((t) => t.value == '{"name":"test"}');
      expect(valueToken.type, CurlTokenType.value);
    });

    test('should handle multiline command with backslash', () {
      final tokens = tokenizer.tokenize(
          'curl -X POST \\\n  -H "Authorization: Bearer token" \\\n  https://api.example.com/users');

      expect(tokens.any((t) => t.value == 'POST'), isTrue);
      expect(
          tokens.any((t) => t.value == 'Authorization: Bearer token'), isTrue);
      expect(tokens.any((t) => t.value == 'https://api.example.com/users'),
          isTrue);
    });

    test('should handle escaped characters in quotes', () {
      final tokens = tokenizer.tokenize(
          'curl -d "{\\"name\\":\\"test\\"}" https://api.example.com');

      final valueToken = tokens.firstWhere((t) => t.value.contains('name'));
      expect(valueToken.value, '{\"name\":\"test\"}');
    });
  });

  group('CurlParser', () {
    late CurlParser parser;

    setUp(() {
      parser = CurlParser();
    });

    test('should parse simple GET request', () {
      final result = parser.parse('curl https://api.example.com/users');

      expect(result.method, HttpMethod.get);
      expect(result.url, 'https://api.example.com/users');
      expect(result.bodyType, 'none');
    });

    test('should parse POST request with -X', () {
      final result = parser.parse('curl -X POST https://api.example.com/users');

      expect(result.method, HttpMethod.post);
    });

    test('should parse POST request with --request', () {
      final result =
          parser.parse('curl --request POST https://api.example.com/users');

      expect(result.method, HttpMethod.post);
    });

    test('should parse all HTTP methods', () {
      final methods = {
        'GET': HttpMethod.get,
        'POST': HttpMethod.post,
        'PUT': HttpMethod.put,
        'DELETE': HttpMethod.delete,
        'PATCH': HttpMethod.patch,
        'HEAD': HttpMethod.head,
        'OPTIONS': HttpMethod.options,
      };

      for (final entry in methods.entries) {
        final result =
            parser.parse('curl -X ${entry.key} https://api.example.com');
        expect(result.method, entry.value,
            reason: 'Method ${entry.key} should be parsed correctly');
      }
    });

    test('should parse headers with -H', () {
      final result = parser.parse(
        'curl -H "Content-Type: application/json" -H "Authorization: Bearer token" https://api.example.com',
      );

      expect(result.headers.length, 2);
      expect(result.headers[0].key, 'Content-Type');
      expect(result.headers[0].value, 'application/json');
      expect(result.headers[1].key, 'Authorization');
      expect(result.headers[1].value, 'Bearer token');
    });

    test('should parse headers with --header', () {
      final result = parser.parse(
        'curl --header "Content-Type: application/json" https://api.example.com',
      );

      expect(result.headers.length, 1);
      expect(result.headers[0].key, 'Content-Type');
    });

    test('should parse body with -d', () {
      final result = parser.parse(
        'curl -X POST -d \'{"name":"test"}\' https://api.example.com/users',
      );

      expect(result.bodyType, 'raw');
      expect(result.body, '{"name":"test"}');
    });

    test('should parse body with --data', () {
      final result = parser.parse(
        'curl -X POST --data \'{"name":"test"}\' https://api.example.com/users',
      );

      expect(result.bodyType, 'raw');
      expect(result.body, '{"name":"test"}');
    });

    test('should infer JSON content type from body', () {
      final result = parser.parse(
        'curl -X POST -d \'{"name":"test"}\' https://api.example.com/users',
      );

      expect(result.rawContentType, 'json');
    });

    test('should infer XML content type from body', () {
      final result = parser.parse(
        'curl -X POST -d "<user><name>test</name></user>" https://api.example.com/users',
      );

      expect(result.rawContentType, 'xml');
    });

    test('should use content type from header', () {
      final result = parser.parse(
        'curl -X POST -H "Content-Type: application/json" -d "data" https://api.example.com',
      );

      expect(result.rawContentType, 'json');
    });

    test('should parse form data with -F', () {
      final result = parser.parse(
        'curl -X POST -F "name=John" -F "email=john@example.com" https://api.example.com/upload',
      );

      expect(result.bodyType, 'formData');
      expect(result.formDataFields.length, 2);
      expect(result.formDataFields[0].name, 'name');
      expect(result.formDataFields[0].value, 'John');
      expect(result.formDataFields[1].name, 'email');
      expect(result.formDataFields[1].value, 'john@example.com');
    });

    test('should parse file upload in form data', () {
      final result = parser.parse(
        'curl -X POST -F "file=@/path/to/file.png" https://api.example.com/upload',
      );

      expect(result.formDataFields.length, 1);
      expect(result.formDataFields[0].name, 'file');
      expect(result.formDataFields[0].value, '/path/to/file.png');
      expect(result.formDataFields[0].isFile, isTrue);
    });

    test('should parse URL encoded data', () {
      final result = parser.parse(
        'curl -X POST --data-urlencode "name=John Doe" https://api.example.com/search',
      );

      expect(result.bodyType, 'formUrlEncoded');
    });

    test('should parse basic auth with -u', () {
      final result = parser.parse(
        'curl -u username:password https://api.example.com/protected',
      );

      expect(result.hasAuth, isTrue);
      expect(result.authUsername, 'username');
      expect(result.authPassword, 'password');
    });

    test('should parse basic auth with --user', () {
      final result = parser.parse(
        'curl --user admin:secret https://api.example.com/admin',
      );

      expect(result.hasAuth, isTrue);
      expect(result.authUsername, 'admin');
      expect(result.authPassword, 'secret');
    });

    test('should parse auth with only username', () {
      final result = parser.parse(
        'curl -u username https://api.example.com/protected',
      );

      expect(result.hasAuth, isTrue);
      expect(result.authUsername, 'username');
      expect(result.authPassword, isNull);
    });

    test('should parse insecure flag -k', () {
      final result = parser.parse(
        'curl -k https://self-signed.example.com',
      );

      expect(result.insecure, isTrue);
    });

    test('should parse insecure flag --insecure', () {
      final result = parser.parse(
        'curl --insecure https://self-signed.example.com',
      );

      expect(result.insecure, isTrue);
    });

    test('should parse follow redirects flag -L', () {
      final result = parser.parse(
        'curl -L https://api.example.com/redirect',
      );

      expect(result.followRedirects, isTrue);
    });

    test('should parse follow redirects flag --location', () {
      final result = parser.parse(
        'curl --location https://api.example.com/redirect',
      );

      expect(result.followRedirects, isTrue);
    });

    test('should handle multiline command', () {
      final result = parser.parse(
        'curl -X POST \\\n'
        '  -H "Content-Type: application/json" \\\n'
        '  -H "Authorization: Bearer token" \\\n'
        '  -d \'{"name":"test"}\' \\\n'
        '  https://api.example.com/users',
      );

      expect(result.method, HttpMethod.post);
      expect(result.headers.length, 2);
      expect(result.headers[0].key, 'Content-Type');
      expect(result.headers[1].key, 'Authorization');
      expect(result.body, '{"name":"test"}');
      expect(result.url, 'https://api.example.com/users');
    });

    test('should handle complex browser cURL command', () {
      final command = '''
curl 'https://api.example.com/graphql' \\
  -H 'authority: api.example.com' \\
  -H 'accept: application/json' \\
  -H 'content-type: application/json' \\
  -H 'authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' \\
  --data-raw '{"query":"query GetUser {\\n  user {\\n    id\\n    name\\n  }\\n}"}' \\
  --compressed
'''
          .trim();

      final result = parser.parse(command);

      expect(result.method, HttpMethod.get); // 没有 -X，默认 GET
      expect(result.url, 'https://api.example.com/graphql');
      expect(result.headers.any((h) => h.key == 'authorization'), isTrue);
      expect(result.bodyType, 'raw');
    });

    test('should handle empty command', () {
      expect(
        () => parser.parse(''),
        throwsA(isA<CurlParseException>()),
      );
    });

    test('should handle invalid command without curl', () {
      expect(
        () => parser.parse('wget https://example.com'),
        throwsA(isA<CurlParseException>()),
      );
    });

    test('should provide warnings for unsupported options', () {
      final result = parser.parse(
        'curl --unsupported-option https://api.example.com',
      );

      expect(result.warnings.isNotEmpty, isTrue);
      expect(
          result.warnings.any((w) => w.contains('unsupported-option')), isTrue);
    });
  });

  group('CurlImportService', () {
    late CurlImportService service;

    setUp(() {
      service = CurlImportService();
    });

    test('should successfully import simple GET request', () {
      final result = service.parse('curl https://api.example.com/users');

      expect(result.success, isTrue);
      expect(result.request, isNotNull);
      expect(result.request!.method, HttpMethod.get);
      expect(result.request!.url, 'https://api.example.com/users');
    });

    test('should create request name from URL', () {
      final result = service.parse('curl https://api.example.com/users/123');

      // 使用 URL 的最后一个路径段作为名称
      expect(result.request!.name, isNotEmpty);
      expect(result.request!.name, contains('(GET)'));
    });

    test('should add Authorization header for basic auth', () {
      final result = service.parse('curl -u user:pass https://api.example.com');

      expect(
          result.request!.headers.any(
            (h) => h.key == 'Authorization' && h.value.startsWith('Basic '),
          ),
          isTrue);
    });

    test('should set validateCertificates to false for -k', () {
      final result = service.parse('curl -k https://example.com');

      expect(result.request!.validateCertificates, isFalse);
    });

    test('should set followRedirects to true for -L', () {
      final result = service.parse('curl -L https://example.com');

      expect(result.request!.followRedirects, isTrue);
    });

    test('should return error for invalid cURL command', () {
      final result = service.parse('invalid command');

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('isValidCurlCommand should return true for valid command', () {
      expect(service.isValidCurlCommand('curl https://example.com'), isTrue);
      expect(service.isValidCurlCommand('curl'), isTrue);
    });

    test('isValidCurlCommand should return false for invalid command', () {
      expect(service.isValidCurlCommand('wget https://example.com'), isFalse);
      expect(service.isValidCurlCommand(''), isFalse);
    });

    test('should correctly set bodyType for raw data', () {
      final result = service.parse(
        'curl -X POST -d "data" https://api.example.com',
      );

      expect(result.request!.bodyType, 'raw');
    });

    test('should correctly set bodyType for form data', () {
      final result = service.parse(
        'curl -X POST -F "key=value" https://api.example.com',
      );

      expect(result.request!.bodyType, 'formData');
    });

    test('should set rawContentType based on Content-Type header', () {
      final result = service.parse(
        'curl -X POST -H "Content-Type: application/json" -d "{}" https://api.example.com',
      );

      expect(result.request!.rawContentType, 'json');
    });
  });
}
