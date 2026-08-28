import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/services/import_export/import_export_exception.dart';
import 'package:hopp/services/import_export/openapi/openapi_parser.dart';
import 'package:hopp/services/import_export/openapi/openapi_spec.dart';

void main() {
  group('OpenApiParser', () {
    final parser = OpenApiParser();

    String loadFixture(String name) =>
        File('test/fixtures/openapi/$name').readAsStringSync();

    OpenApiOperation findOp(OpenApiSpec spec, String id) =>
        spec.operations.firstWhere((op) => op.id == id);

    group('格式与版本识别', () {
      test('解析 OpenAPI 3.x JSON', () {
        final spec = parser.parse(loadFixture('petstore3.json'));

        expect(spec.title, 'Swagger Petstore');
        expect(spec.specVersion, '3.0.3');
        expect(spec.serverUrl, 'https://petstore3.swagger.io/api/v3');
        expect(spec.operations.length, 8);
      });

      test('解析 YAML 文档', () {
        final spec = parser.parse(loadFixture('petstore3_min.yaml'));

        expect(spec.title, 'Mini Petstore YAML');
        expect(spec.specVersion, '3.0.0');
        expect(spec.serverUrl, 'https://api.mini-petstore.test/v1');
        expect(spec.operations.length, 3);

        final listPets = findOp(spec, 'get /pets');
        expect(listPets.queryParams.single.name, 'limit');
        expect(listPets.queryParams.single.value, '20');
        expect(listPets.queryParams.single.enabled, true);

        final createPet = findOp(spec, 'post /pets');
        expect(createPet.body, isNotNull);
        expect(createPet.body!.content, contains('kitty'));
        expect(createPet.body!.isSkeleton, false);
      });

      test('解析 Swagger 2.0 并内部转换', () {
        final spec = parser.parse(loadFixture('swagger2_petstore.json'));

        expect(spec.title, 'Swagger Petstore 2.0');
        expect(spec.specVersion, '2.0');
        // schemes[0] + host + basePath
        expect(spec.serverUrl, 'https://petstore.swagger.io/v2');
        expect(spec.operations.length, 4);
      });

      test('无法解码的内容抛 unknownFormat', () {
        expect(
          () => parser.parse('this is not a spec at all: [broken'),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              ImportErrorCode.unknownFormat,
            ),
          ),
        );
      });

      test('非 Map 内容抛 unknownFormat', () {
        expect(
          () => parser.parse('[1, 2, 3]'),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              ImportErrorCode.unknownFormat,
            ),
          ),
        );
      });

      test('缺少版本标识抛 unknownFormat', () {
        expect(
          () => parser.parse(jsonEncode({'foo': 'bar', 'paths': {}})),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              ImportErrorCode.unknownFormat,
            ),
          ),
        );
      });

      test('缺少 paths 抛 unknownFormat', () {
        expect(
          () => parser.parse(
            jsonEncode({
              'openapi': '3.0.0',
              'info': {'title': 'No Paths'},
            }),
          ),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              ImportErrorCode.unknownFormat,
            ),
          ),
        );
      });
    });

    group('参数解析', () {
      late OpenApiSpec spec;

      setUpAll(() {
        spec = parser.parse(loadFixture('petstore3.json'));
      });

      test('取值优先级：default 用于 status', () {
        final op = findOp(spec, 'get /pet/findByStatus');
        final status = op.queryParams.firstWhere((p) => p.name == 'status');
        expect(status.value, 'available');
        expect(status.enabled, true);
      });

      test('无值非 required → value 空且 disabled', () {
        final op = findOp(spec, 'get /pet/findByStatus');
        final page = op.queryParams.firstWhere((p) => p.name == 'page');
        expect(page.value, '');
        expect(page.enabled, false);
      });

      test('required 无 example → value 空但 enabled', () {
        final op = findOp(spec, 'get /pet/findByStatus');
        final limit = op.queryParams.firstWhere((p) => p.name == 'limit');
        expect(limit.value, '');
        expect(limit.enabled, true);
      });

      test('参数级 example 优先于 schema', () {
        final op = findOp(spec, 'get /pet/findByStatus');
        final header =
            op.headerParams.firstWhere((p) => p.name == 'X-Request-Id');
        expect(header.value, 'req-123');
        expect(header.enabled, true);
      });

      test('enum[0] 在无 example/default 时使用', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {
              'get': {
                'parameters': [
                  {
                    'name': 'color',
                    'in': 'query',
                    'schema': {
                      'type': 'string',
                      'enum': ['red', 'green'],
                    },
                  },
                ],
              },
            },
          },
        });
        final inlineSpec = parser.parse(inline);
        final color = findOp(inlineSpec, 'get /a').queryParams.single;
        expect(color.value, 'red');
        expect(color.enabled, true);
      });

      test('path 参数恒 enabled 且留空占位', () {
        final op = findOp(spec, 'get /pet/{petId}');
        expect(op.pathParams.single.name, 'petId');
        expect(op.pathParams.single.value, '');
        expect(op.pathParams.single.enabled, true);
      });

      test('path 级与 operation 级参数合并，同名同 in 时 operation 覆盖', () {
        final op = findOp(spec, 'get /pet/{petId}');
        // path 级定义了 default: on，operation 级覆盖为 default: off
        final trace = op.headerParams.firstWhere((p) => p.name == 'X-Trace');
        expect(trace.value, 'off');
      });
    });

    group('body 解析', () {
      late OpenApiSpec spec;

      setUpAll(() {
        spec = parser.parse(loadFixture('petstore3.json'));
      });

      test('example 优先（isSkeleton=false）', () {
        final op = findOp(spec, 'post /pet');
        final body = op.body!;
        expect(body.isSkeleton, false);
        expect(body.bodyType, 'raw');
        expect(body.rawContentType, 'json');
        final decoded = jsonDecode(body.content) as Map<String, dynamic>;
        expect(decoded['name'], 'doggie');
      });

      test('examples[0].value 作为 example', () {
        final op = findOp(spec, 'post /store/order');
        final body = op.body!;
        expect(body.isSkeleton, false);
        final decoded = jsonDecode(body.content) as Map<String, dynamic>;
        expect(decoded['petId'], 198772);
      });

      test(r'无 example 生成骨架：嵌套 object + array + $ref 循环', () {
        final op = findOp(spec, 'post /pet/{petId}/uploadImage');
        final body = op.body!;
        expect(body.isSkeleton, true);
        expect(body.bodyType, 'raw');
        expect(body.rawContentType, 'json');

        final skeleton = jsonDecode(body.content) as Map<String, dynamic>;
        // example/default/enum 占位
        expect(skeleton['id'], 10);
        expect(skeleton['name'], 'doggie');
        expect(skeleton['status'], 'available');
        // array → []
        expect(skeleton['tags'], isEmpty);
        // 嵌套 \$ref
        final category = skeleton['category'] as Map<String, dynamic>;
        expect(category['name'], 'Dogs');
        // 循环引用 → {}
        expect(category['parent'], isEmpty);
      });

      test('content key 优先级：application/json 优先', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {
              'post': {
                'requestBody': {
                  'content': {
                    'text/plain': {
                      'schema': {'type': 'string'},
                      'example': 'plain',
                    },
                    'application/json': {
                      'schema': {'type': 'object'},
                      'example': {'a': 1},
                    },
                  },
                },
              },
            },
          },
        });
        final inlineSpec = parser.parse(inline);
        final body = findOp(inlineSpec, 'post /a').body!;
        expect(body.rawContentType, 'json');
        expect(body.content, contains('"a": 1'));
      });

      test('content key 优先级：含 +json 次之', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {
              'post': {
                'requestBody': {
                  'content': {
                    'text/plain': {
                      'schema': {'type': 'string'},
                    },
                    'application/problem+json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'detail': {'type': 'string'},
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        });
        final inlineSpec = parser.parse(inline);
        final body = findOp(inlineSpec, 'post /a').body!;
        expect(body.rawContentType, 'json');
        expect(body.isSkeleton, true);
        expect(body.content, contains('detail'));
      });

      test('非 JSON 内容 → raw + 推断 rawContentType', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {
              'post': {
                'requestBody': {
                  'content': {
                    'application/xml': {
                      'schema': {'type': 'string'},
                      'example': '<a/>',
                    },
                  },
                },
              },
            },
          },
        });
        final inlineSpec = parser.parse(inline);
        final body = findOp(inlineSpec, 'post /a').body!;
        expect(body.bodyType, 'raw');
        expect(body.rawContentType, 'xml');
        expect(body.content, '<a/>');
      });
    });

    group('Swagger 2.0 转换细节', () {
      late OpenApiSpec spec;

      setUpAll(() {
        spec = parser.parse(loadFixture('swagger2_petstore.json'));
      });

      test('in: body 参数 → requestBody（全局 consumes 决定 content key）', () {
        final op = findOp(spec, 'post /pet');
        final body = op.body!;
        expect(body.bodyType, 'raw');
        expect(body.rawContentType, 'json');
        expect(body.isSkeleton, true);
        // #/definitions/Pet 引用已重写并解析
        final skeleton = jsonDecode(body.content) as Map<String, dynamic>;
        expect(skeleton['name'], 'doggie');
        expect(skeleton['category'], isNotNull);
      });

      test('in: formData 参数 → urlencoded（a=b&c= 形式）', () {
        final op = findOp(spec, 'post /pet/{petId}');
        final body = op.body!;
        expect(body.bodyType, 'x-www-form-urlencoded');
        expect(body.isSkeleton, true);
        expect(body.content, 'name=&status=available');
      });

      test('2.0 参数内联 default → 参数值', () {
        final op = findOp(spec, 'get /user/login');
        final username = op.queryParams.single;
        expect(username.name, 'username');
        expect(username.value, 'demo');
        expect(username.enabled, true);
      });

      test('2.0 basic securityDefinition → http basic', () {
        expect(spec.auth, isNotNull);
        expect(spec.auth!.kind, 'basic');
        expect(spec.oauthNotices, contains('petstore_oauth'));
      });
    });

    group('命名与 tag', () {
      late OpenApiSpec spec;

      setUpAll(() {
        spec = parser.parse(loadFixture('petstore3.json'));
      });

      test('summary 优先', () {
        expect(findOp(spec, 'post /pet').name, 'Add a new pet to the store');
      });

      test('operationId 次之', () {
        expect(
          findOp(spec, 'post /pet/{petId}/uploadImage').name,
          'uploadFile',
        );
      });

      test('兜底 METHOD /path', () {
        expect(findOp(spec, 'get /misc/ping').name, 'GET /misc/ping');
      });

      test('tagOrder 按 paths 首次出现顺序', () {
        expect(spec.tagOrder, ['pet', 'store', 'user']);
      });

      test('无 tag 的 op tag 为 null', () {
        expect(findOp(spec, 'get /misc/ping').tag, isNull);
      });
    });

    group('security 选择', () {
      test('root security 引用受支持的 apiKey → 采用', () {
        final spec = parser.parse(loadFixture('petstore3.json'));
        expect(spec.auth, isNotNull);
        expect(spec.auth!.kind, 'apiKey');
        expect(spec.auth!.apiKeyName, 'api_key');
        expect(spec.auth!.apiKeyInQuery, false);
      });

      test('oauth2 记入 oauthNotices', () {
        final spec = parser.parse(loadFixture('petstore3.json'));
        expect(spec.oauthNotices, ['petstore_auth']);
      });

      test('security: [] 显式空 → 不配置', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {'get': {}},
          },
          'components': {
            'securitySchemes': {
              'key': {'type': 'apiKey', 'name': 'k', 'in': 'header'},
            },
          },
          'security': <dynamic>[],
        });
        final spec = parser.parse(inline);
        expect(spec.auth, isNull);
      });

      test('首个条目不受支持 → 回退文档序第一个受支持的', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {'get': {}},
          },
          'components': {
            'securitySchemes': {
              'oauth_thing': {'type': 'oauth2', 'flows': {}},
              'basic_auth': {'type': 'http', 'scheme': 'basic'},
            },
          },
          'security': [
            {'oauth_thing': []},
          ],
        });
        final spec = parser.parse(inline);
        expect(spec.auth, isNotNull);
        expect(spec.auth!.kind, 'basic');
        expect(spec.oauthNotices, ['oauth_thing']);
      });

      test('bearer scheme → kind bearer', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {'get': {}},
          },
          'components': {
            'securitySchemes': {
              'jwt': {'type': 'http', 'scheme': 'bearer'},
            },
          },
          'security': [
            {'jwt': []},
          ],
        });
        final spec = parser.parse(inline);
        expect(spec.auth!.kind, 'bearer');
      });

      test('无 securitySchemes → auth 为 null', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {'get': {}},
          },
        });
        final spec = parser.parse(inline);
        expect(spec.auth, isNull);
        expect(spec.oauthNotices, isEmpty);
      });
    });

    group(r'$ref 解析', () {
      test('components/parameters 引用解析', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {
              'get': {
                'parameters': [
                  {r'$ref': '#/components/parameters/Limit'},
                ],
              },
            },
          },
          'components': {
            'parameters': {
              'Limit': {
                'name': 'limit',
                'in': 'query',
                'required': true,
                'schema': {'type': 'integer', 'default': 50},
              },
            },
          },
        });
        final spec = parser.parse(inline);
        final limit = findOp(spec, 'get /a').queryParams.single;
        expect(limit.name, 'limit');
        expect(limit.value, '50');
        expect(limit.enabled, true);
      });

      test('自引用 schema 骨架不堆栈溢出且循环节点为 {}', () {
        final inline = jsonEncode({
          'openapi': '3.0.0',
          'info': {'title': 'T'},
          'paths': {
            '/a': {
              'post': {
                'requestBody': {
                  'content': {
                    'application/json': {
                      'schema': {r'$ref': '#/components/schemas/Node'},
                    },
                  },
                },
              },
            },
          },
          'components': {
            'schemas': {
              'Node': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'string'},
                  'next': {r'$ref': '#/components/schemas/Node'},
                },
              },
            },
          },
        });
        final spec = parser.parse(inline);
        final body = findOp(spec, 'post /a').body!;
        expect(body.isSkeleton, true);
        final skeleton = jsonDecode(body.content) as Map<String, dynamic>;
        expect(skeleton['value'], '');
        expect(skeleton['next'], isEmpty);
      });
    });
  });
}
