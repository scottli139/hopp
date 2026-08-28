import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/auth_config.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/services/import_export/openapi/openapi_mapper.dart';
import 'package:hopp/services/import_export/openapi/openapi_parser.dart';
import 'package:hopp/services/import_export/openapi/openapi_spec.dart';

void main() {
  group('OpenApiMapper', () {
    final mapper = OpenApiMapper();

    String loadFixture(String name) =>
        File('test/fixtures/openapi/$name').readAsStringSync();

    group('petstore3', () {
      late OpenApiSpec spec;
      late OpenApiMapResult result;

      setUpAll(() {
        spec = OpenApiParser().parse(loadFixture('petstore3.json'));
        result = mapper.toHopp(spec);
      });

      test('三元组：1 根集合 + 3 子集合 + 8 请求', () {
        expect(result.rootCollection.name, 'Swagger Petstore');
        expect(result.childCollections.length, 3);
        expect(result.allRequests.length, 8);
      });

      test('子集合 parentId 指向根集合，sortOrder 按 tagOrder', () {
        final rootId = result.rootCollection.id;
        expect(
          result.childCollections.map((c) => c.name),
          ['pet', 'store', 'user'],
        );
        for (var i = 0; i < result.childCollections.length; i++) {
          expect(result.childCollections[i].parentId, rootId);
          expect(result.childCollections[i].sortOrder, i);
        }
      });

      test('请求 parentId 串联到所属 tag 子集合', () {
        final petCollection =
            result.childCollections.firstWhere((c) => c.name == 'pet');
        final getPet =
            result.allRequests.firstWhere((r) => r.name == 'Find pet by ID');
        expect(getPet.parentId, petCollection.id);
      });

      test('无 tag 的请求平铺到根集合', () {
        final ping =
            result.allRequests.firstWhere((r) => r.name == 'GET /misc/ping');
        expect(ping.parentId, result.rootCollection.id);
      });

      test('URL：{{baseUrl}} 前缀 + {petId} → {{petId}}', () {
        final getPet =
            result.allRequests.firstWhere((r) => r.name == 'Find pet by ID');
        expect(getPet.url, '{{baseUrl}}/pet/{{petId}}');
      });

      test('method 映射为 HttpMethod 枚举', () {
        final getPet =
            result.allRequests.firstWhere((r) => r.name == 'Find pet by ID');
        final addPet = result.allRequests
            .firstWhere((r) => r.name == 'Add a new pet to the store');
        expect(getPet.method, HttpMethod.get);
        expect(addPet.method, HttpMethod.post);
      });

      test('sortOrder 按文档序', () {
        final addPet = result.allRequests
            .firstWhere((r) => r.name == 'Add a new pet to the store');
        final getPet =
            result.allRequests.firstWhere((r) => r.name == 'Find pet by ID');
        expect(addPet.sortOrder, 0);
        expect(getPet.sortOrder, 1);
      });

      test('params/headers 映射为 KeyValuePair', () {
        final findByStatus = result.allRequests
            .firstWhere((r) => r.name == 'Finds Pets by status');
        expect(findByStatus.params.length, 3);
        expect(findByStatus.params[0].key, 'status');
        expect(findByStatus.params[0].value, 'available');
        expect(findByStatus.params[0].enabled, true);
        expect(findByStatus.params[1].key, 'page');
        expect(findByStatus.params[1].enabled, false);
        expect(findByStatus.headers.single.key, 'X-Request-Id');
        expect(findByStatus.headers.single.value, 'req-123');
      });

      test('body 字段照 OpenApiBody', () {
        final addPet = result.allRequests
            .firstWhere((r) => r.name == 'Add a new pet to the store');
        expect(addPet.bodyType, 'raw');
        expect(addPet.rawContentType, 'json');
        expect(addPet.body, contains('doggie'));

        final inventory = result.allRequests
            .firstWhere((r) => r.name == 'Returns pet inventories');
        expect(inventory.bodyType, 'none');
        expect(inventory.body, '');
      });

      test('AuthConfig：apiKey（header）挂到根集合', () {
        final auth = result.rootCollection.auth;
        expect(auth.type, AuthType.apiKey);
        expect(auth.apiKeyName, 'api_key');
        expect(auth.apiKeyValue, '');
        expect(auth.apiKeyAddTo, AuthConfig.apiKeyAddToHeader);
        expect(result.authDescription, contains('api_key'));
      });

      test('placeholders：pathVars 与 body 骨架', () {
        final pathVars =
            result.placeholders.where((p) => p.kind == 'pathVars').toList();
        expect(pathVars.length, 2);
        expect(pathVars.every((p) => p.detail.contains('petId')), true);

        final bodies =
            result.placeholders.where((p) => p.kind == 'body').toList();
        expect(bodies.length, 1);
        expect(bodies.single.method, 'POST');
        expect(bodies.single.path, '/pet/{petId}/uploadImage');
      });

      test('oauthNotices 透传', () {
        expect(result.oauthNotices, ['petstore_auth']);
      });

      test('baseUrl 透传', () {
        expect(result.baseUrl, 'https://petstore3.swagger.io/api/v3');
      });
    });

    group('selectedOpIds', () {
      test('只映射选中的 op，空 tag 子集合省略', () {
        final spec = OpenApiParser().parse(loadFixture('petstore3.json'));
        final result = mapper.toHopp(
          spec,
          selectedOpIds: {'post /pet', 'get /misc/ping'},
        );

        expect(result.allRequests.length, 2);
        // 只有 pet tag 有选中请求
        expect(result.childCollections.length, 1);
        expect(result.childCollections.single.name, 'pet');

        final addPet = result.allRequests
            .firstWhere((r) => r.name == 'Add a new pet to the store');
        expect(addPet.parentId, result.childCollections.single.id);
        final ping =
            result.allRequests.firstWhere((r) => r.name == 'GET /misc/ping');
        expect(ping.parentId, result.rootCollection.id);
      });
    });

    group('swagger 2.0', () {
      test('formData → x-www-form-urlencoded + formData placeholder', () {
        final spec =
            OpenApiParser().parse(loadFixture('swagger2_petstore.json'));
        final result = mapper.toHopp(spec);

        final formReq = result.allRequests
            .firstWhere((r) => r.name == 'Updates a pet with form data');
        expect(formReq.bodyType, 'x-www-form-urlencoded');
        expect(formReq.body, 'name=&status=available');

        final formData =
            result.placeholders.where((p) => p.kind == 'formData').toList();
        expect(formData.length, 1);
        expect(formData.single.path, '/pet/{petId}');

        expect(result.rootCollection.auth.type, AuthType.basic);
      });
    });

    group('手工构造 spec', () {
      OpenApiSpec buildSpec({
        String? serverUrl,
        AuthSchemeInfo? auth,
      }) {
        return OpenApiSpec(
          title: 'Manual',
          specVersion: '3.0.0',
          serverUrl: serverUrl,
          operations: const [
            OpenApiOperation(
              id: 'get /a',
              method: 'get',
              path: '/a',
              name: 'A',
            ),
          ],
          auth: auth,
        );
      }

      test('无 serverUrl 时 URL 不含 {{baseUrl}}', () {
        final result = mapper.toHopp(buildSpec());
        expect(result.allRequests.single.url, '/a');
        expect(result.baseUrl, isNull);
      });

      test('bearer → AuthConfig(type bearer, token 空)', () {
        final result = mapper.toHopp(
          buildSpec(auth: const AuthSchemeInfo(kind: 'bearer')),
        );
        expect(result.rootCollection.auth.type, AuthType.bearer);
        expect(result.rootCollection.auth.token, '');
        expect(result.authDescription, contains('Bearer'));
      });

      test('basic → AuthConfig(type basic)', () {
        final result = mapper.toHopp(
          buildSpec(auth: const AuthSchemeInfo(kind: 'basic')),
        );
        expect(result.rootCollection.auth.type, AuthType.basic);
      });

      test('apiKey in query → apiKeyAddTo query', () {
        final result = mapper.toHopp(
          buildSpec(
            auth: const AuthSchemeInfo(
              kind: 'apiKey',
              apiKeyName: 'api_key',
              apiKeyInQuery: true,
            ),
          ),
        );
        expect(
          result.rootCollection.auth.apiKeyAddTo,
          AuthConfig.apiKeyAddToQuery,
        );
      });

      test('无 auth → 默认 AuthConfig（inherit），authDescription 为 null', () {
        final result = mapper.toHopp(buildSpec());
        expect(result.rootCollection.auth.type, AuthType.inherit);
        expect(result.authDescription, isNull);
      });

      test('未知 method 回退 get（项目惯例）', () {
        const spec = OpenApiSpec(
          title: 'T',
          specVersion: '3.0.0',
          operations: [
            OpenApiOperation(
              id: 'trace /a',
              method: 'trace',
              path: '/a',
              name: 'T',
            ),
          ],
        );
        final result = mapper.toHopp(spec);
        expect(result.allRequests.single.method, HttpMethod.get);
      });
    });
  });
}
