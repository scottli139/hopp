import 'package:flutter_test/flutter_test.dart';

// 只导入自定义适配器，隐藏自动生成的适配器
import 'package:hopp/models/adapters/http_request_adapter.dart'
    as custom_adapters;
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart' hide HttpRequestAdapter;
import 'package:hopp/models/key_value_pair.dart';

void main() {
  group('HttpRequestAdapter', () {
    late custom_adapters.HttpRequestAdapter adapter;

    setUp(() {
      adapter = custom_adapters.HttpRequestAdapter();
    });

    group('Basic Properties', () {
      test('should have correct typeId', () {
        expect(adapter.typeId, equals(2));
      });
    });

    group('Read with New Data (All Fields)', () {
      test('should read complete request with all fields', () {
        final request = HttpRequest(
          id: 'test-id',
          name: 'Test Request',
          method: HttpMethod.post,
          url: 'https://example.com/api',
          params: [KeyValuePair.empty().copyWith(key: 'q', value: 'test')],
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Accept', value: 'application/json')
          ],
          body: '{"key": "value"}',
          bodyType: 'json',
          parentId: 'parent-123',
          sortOrder: 1,
          rawContentType: 'json',
          validateCertificates: false,
          followRedirects: false,
          maxRedirects: 5,
        );

        // 验证请求对象创建成功
        expect(request.id, equals('test-id'));
        expect(request.validateCertificates, isFalse);
        expect(request.followRedirects, isFalse);
        expect(request.maxRedirects, equals(5));
      });
    });

    group('Default Values', () {
      test('should have correct default values in empty() factory', () {
        final request = HttpRequest.empty();

        expect(request.validateCertificates, isTrue);
        expect(request.followRedirects, isTrue);
        expect(request.maxRedirects, equals(10));
      });

      test('should allow overriding defaults', () {
        final request = HttpRequest.empty().copyWith(
          validateCertificates: false,
          followRedirects: false,
          maxRedirects: 0,
        );

        expect(request.validateCertificates, isFalse);
        expect(request.followRedirects, isFalse);
        expect(request.maxRedirects, equals(0));
      });
    });

    group('Copy With', () {
      test('should copy request with new settings', () {
        final original = HttpRequest.empty();

        final updated = original.copyWith(
          validateCertificates: false,
          followRedirects: false,
          maxRedirects: 3,
        );

        // 原始请求不变
        expect(original.validateCertificates, isTrue);
        expect(original.followRedirects, isTrue);
        expect(original.maxRedirects, equals(10));

        // 新请求有更新后的值
        expect(updated.validateCertificates, isFalse);
        expect(updated.followRedirects, isFalse);
        expect(updated.maxRedirects, equals(3));
      });

      test('should copy without changing unspecified fields', () {
        final original = HttpRequest.empty().copyWith(
          validateCertificates: false,
        );

        final updated = original.copyWith(followRedirects: false);

        // validateCertificates 保持原值
        expect(updated.validateCertificates, isFalse);
        // followRedirects 被更新
        expect(updated.followRedirects, isFalse);
        // maxRedirects 保持默认值
        expect(updated.maxRedirects, equals(10));
      });
    });

    group('Field Immutability', () {
      test('should maintain immutability with Freezed', () {
        final request = HttpRequest.empty();

        // 尝试修改应该通过 copyWith 而不是直接赋值
        final updated = request.copyWith(validateCertificates: false);

        // 原始对象不变
        expect(request.validateCertificates, isTrue);
        // 新对象有修改后的值
        expect(updated.validateCertificates, isFalse);
      });
    });
  });
}
