import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/auth_config.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/services/auth_resolver.dart';
import 'package:hopp/services/variable_resolver.dart';

void main() {
  late VariableResolver resolver;

  setUp(() {
    resolver = VariableResolver();
  });

  HttpRequest buildRequest({
    AuthConfig auth = const AuthConfig(),
    String? parentId,
    List<KeyValuePair> headers = const [],
    List<KeyValuePair> params = const [],
  }) {
    return HttpRequest(
      id: 'req-1',
      name: 'Test',
      auth: auth,
      parentId: parentId,
      headers: headers,
      params: params,
    );
  }

  Collection buildCollection(
    String id, {
    AuthConfig auth = const AuthConfig(),
    String? parentId,
  }) {
    return Collection(id: id, name: 'Col-$id', auth: auth, parentId: parentId);
  }

  group('resolveEffective', () {
    test('请求级配置优先，直接返回', () {
      final request = buildRequest(
        auth: const AuthConfig(type: AuthType.bearer, token: '{{token}}'),
        parentId: 'c1',
      );
      final collections = {
        'c1': buildCollection(
          'c1',
          auth: const AuthConfig(type: AuthType.basic),
        ),
      };

      final auth = AuthResolver.resolveEffective(request, collections);

      expect(auth?.type, equals(AuthType.bearer));
      expect(auth?.token, equals('{{token}}'));
    });

    test('请求 inherit 时取所属集合配置', () {
      final request = buildRequest(parentId: 'c1');
      final collections = {
        'c1': buildCollection(
          'c1',
          auth: const AuthConfig(type: AuthType.bearer, token: 'abc'),
        ),
      };

      final auth = AuthResolver.resolveEffective(request, collections);

      expect(auth?.type, equals(AuthType.bearer));
    });

    test('集合嵌套时沿 parentId 向上找最近配置', () {
      final request = buildRequest(parentId: 'child');
      final collections = {
        'child': buildCollection('child', parentId: 'root'),
        'root': buildCollection(
          'root',
          auth: const AuthConfig(type: AuthType.apiKey, apiKeyName: 'X-Key'),
        ),
      };

      final auth = AuthResolver.resolveEffective(request, collections);

      expect(auth?.type, equals(AuthType.apiKey));
    });

    test('请求级 none 阻断继承', () {
      final request = buildRequest(
        auth: const AuthConfig(type: AuthType.none),
        parentId: 'c1',
      );
      final collections = {
        'c1': buildCollection(
          'c1',
          auth: const AuthConfig(type: AuthType.bearer, token: 'abc'),
        ),
      };

      expect(AuthResolver.resolveEffective(request, collections), isNull);
    });

    test('集合级 none 阻断继续向上继承', () {
      final request = buildRequest(parentId: 'child');
      final collections = {
        'child': buildCollection(
          'child',
          auth: const AuthConfig(type: AuthType.none),
          parentId: 'root',
        ),
        'root': buildCollection(
          'root',
          auth: const AuthConfig(type: AuthType.bearer, token: 'abc'),
        ),
      };

      expect(AuthResolver.resolveEffective(request, collections), isNull);
    });

    test('全链 inherit（含无 parentId）返回 null', () {
      expect(AuthResolver.resolveEffective(buildRequest(), {}), isNull);

      final request = buildRequest(parentId: 'c1');
      final collections = {'c1': buildCollection('c1')};
      expect(AuthResolver.resolveEffective(request, collections), isNull);
    });

    test('parentId 悬空或成环时安全返回 null', () {
      final dangling = buildRequest(parentId: 'missing');
      expect(AuthResolver.resolveEffective(dangling, {}), isNull);

      // 成环：c1.parentId = c1
      final cyclic = buildRequest(parentId: 'c1');
      final collections = {'c1': buildCollection('c1', parentId: 'c1')};
      expect(AuthResolver.resolveEffective(cyclic, collections), isNull);
    });
  });

  group('inheritedFrom', () {
    test('请求 inherit 且命中集合配置时返回来源集合', () {
      final request = buildRequest(parentId: 'c1');
      final collections = {
        'c1': buildCollection(
          'c1',
          auth: const AuthConfig(type: AuthType.bearer),
        ),
      };

      expect(AuthResolver.inheritedFrom(request, collections)?.id, 'c1');
    });

    test('请求自身有配置时返回 null', () {
      final request = buildRequest(
        auth: const AuthConfig(type: AuthType.bearer),
        parentId: 'c1',
      );
      final collections = {
        'c1': buildCollection(
          'c1',
          auth: const AuthConfig(type: AuthType.bearer),
        ),
      };

      expect(AuthResolver.inheritedFrom(request, collections), isNull);
    });
  });

  group('inheritedFromCollection', () {
    test('返回最近一个非 inherit 的祖先集合', () {
      final collections = {
        'child': buildCollection('child', parentId: 'mid'),
        'mid': buildCollection('mid', parentId: 'root'),
        'root': buildCollection(
          'root',
          auth: const AuthConfig(type: AuthType.basic),
        ),
      };

      final source = AuthResolver.inheritedFromCollection(
        collections['child']!,
        collections,
      );

      expect(source?.id, equals('root'));
    });
  });

  group('apply', () {
    test('bearer：写入 Authorization header 并解析变量', () {
      final request = buildRequest();
      const auth = AuthConfig(type: AuthType.bearer, token: '{{token}}');

      final result = AuthResolver.apply(
        request,
        auth,
        {'token': 'abc123'},
        resolver,
      );

      final header = result.headers
          .firstWhere((h) => h.key.toLowerCase() == 'authorization');
      expect(header.value, equals('Bearer abc123'));
      expect(header.enabled, isTrue);
    });

    test('bearer：覆盖手工填写的同名 header（忽略大小写）', () {
      final request = buildRequest(headers: [
        KeyValuePair.empty()
            .copyWith(key: 'authorization', value: 'Bearer old'),
        KeyValuePair.empty().copyWith(key: 'Accept', value: '*/*'),
      ]);
      const auth = AuthConfig(type: AuthType.bearer, token: 'new');

      final result = AuthResolver.apply(request, auth, {}, resolver);

      final auths = result.headers
          .where((h) => h.key.toLowerCase() == 'authorization')
          .toList();
      expect(auths, hasLength(1));
      expect(auths.single.value, equals('Bearer new'));
      // 其他 header 不受影响
      expect(result.headers.any((h) => h.key == 'Accept'), isTrue);
    });

    test('basic：base64(user:pass)', () {
      final request = buildRequest();
      const auth = AuthConfig(
        type: AuthType.basic,
        username: 'alice',
        password: 'wonderland',
      );

      final result = AuthResolver.apply(request, auth, {}, resolver);

      final expected = base64Encode(utf8.encode('alice:wonderland'));
      expect(result.headers.single.value, equals('Basic $expected'));
    });

    test('apiKey 注入 header（默认）', () {
      final request = buildRequest();
      const auth = AuthConfig(
        type: AuthType.apiKey,
        apiKeyName: 'X-API-Key',
        apiKeyValue: '{{key}}',
      );

      final result = AuthResolver.apply(request, auth, {'key': 'k1'}, resolver);

      expect(result.headers.single.key, equals('X-API-Key'));
      expect(result.headers.single.value, equals('k1'));
      expect(result.params, isEmpty);
    });

    test('apiKey 注入 query 参数并覆盖同名', () {
      final request = buildRequest(params: [
        KeyValuePair.empty().copyWith(key: 'api_key', value: 'old'),
      ]);
      const auth = AuthConfig(
        type: AuthType.apiKey,
        apiKeyName: 'api_key',
        apiKeyValue: 'new',
        apiKeyAddTo: AuthConfig.apiKeyAddToQuery,
      );

      final result = AuthResolver.apply(request, auth, {}, resolver);

      expect(result.params, hasLength(1));
      expect(result.params.single.value, equals('new'));
    });

    test('apiKey 键名为空时不改动请求', () {
      final request = buildRequest();
      const auth = AuthConfig(type: AuthType.apiKey, apiKeyValue: 'v');

      final result = AuthResolver.apply(request, auth, {}, resolver);

      expect(result.headers, isEmpty);
      expect(result.params, isEmpty);
    });

    test('none / inherit 原样返回', () {
      final request = buildRequest(headers: [
        KeyValuePair.empty().copyWith(key: 'Accept', value: '*/*'),
      ]);

      for (final type in [AuthType.none, AuthType.inherit]) {
        final result = AuthResolver.apply(
          request,
          const AuthConfig().copyWith(type: type),
          {},
          resolver,
        );
        expect(result.headers, hasLength(1));
        expect(result.headers.single.key, equals('Accept'));
      }
    });
  });

  group('模型默认值与序列化', () {
    test('HttpRequest / Collection 的 auth 默认为 inherit', () {
      expect(HttpRequest.empty().auth.type, equals(AuthType.inherit));
      expect(Collection.empty().auth.type, equals(AuthType.inherit));
    });

    test('AuthConfig JSON 往返', () {
      const auth = AuthConfig(
        type: AuthType.apiKey,
        apiKeyName: 'X-Key',
        apiKeyValue: 'v',
        apiKeyAddTo: AuthConfig.apiKeyAddToQuery,
      );

      final restored = AuthConfig.fromJson(auth.toJson());

      expect(restored, equals(auth));
    });

    test('HttpRequest JSON 往返携带 auth', () {
      final request = buildRequest(
        auth: const AuthConfig(type: AuthType.bearer, token: 't'),
      );

      // 与导出/导入路径一致：toJson 的嵌套对象需经 jsonEncode 归一化
      final restored = HttpRequest.fromJson(
        jsonDecode(jsonEncode(request.toJson())) as Map<String, dynamic>,
      );

      expect(restored.auth.type, equals(AuthType.bearer));
      expect(restored.auth.token, equals('t'));
    });
  });
}
