import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/models/auth_config.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/pre_request_step.dart';
import 'package:hopp/services/import_export/hopp_export_service.dart';

void main() {
  group('HoppExportService', () {
    const service = HoppExportService();

    Collection collection({
      required String id,
      required String name,
      String? parentId,
      int sortOrder = 0,
      AuthConfig auth = const AuthConfig(),
      List<PreRequestStep> chain = const [],
      bool preRequestRetryOn401 = false,
    }) =>
        Collection(
          id: id,
          name: name,
          parentId: parentId,
          sortOrder: sortOrder,
          auth: auth,
          preRequestChain: chain,
          preRequestRetryOn401: preRequestRetryOn401,
        );

    HttpRequest request({
      required String id,
      required String name,
      String? parentId,
      int sortOrder = 0,
      List<AssertionRule> assertions = const [],
      List<PreRequestStep> chain = const [],
      AuthConfig auth = const AuthConfig(),
    }) =>
        HttpRequest(
          id: id,
          name: name,
          method: HttpMethod.post,
          url: '{{host}}/api/login',
          parentId: parentId,
          sortOrder: sortOrder,
          assertions: assertions,
          preRequestChain: chain,
          auth: auth,
        );

    group('buildDocument 形状', () {
      test('头部字段齐全；集合树嵌套；请求平铺含 parentId/sortOrder', () {
        final root = collection(id: 'root', name: 'Root');
        final child = collection(
          id: 'child',
          name: 'Child',
          parentId: 'root',
          sortOrder: 1,
          chain: const [PreRequestStep(id: 's1', requestId: 'req-1')],
        );
        final grandChild = collection(id: 'gc', name: 'GC', parentId: 'child');

        final r1 = request(id: 'req-1', name: 'R1', parentId: 'root');

        final r2 = request(id: 'req-2', name: 'R2', parentId: 'child');
        // parentId 指向子树外的请求不导出
        final outside = request(id: 'req-x', name: 'X', parentId: 'other');

        final doc = service.buildDocument(
          root: root,
          allCollections: [root, child, grandChild],
          allRequests: [r1, r2, outside],
          environments: const [],
          globals: const [],
          exportedAt: DateTime.utc(2026, 8, 28),
        );

        expect(doc['format'], 'hopp-cli');
        expect(doc['version'], 1);
        expect(doc['exportedAt'], '2026-08-28T00:00:00.000Z');
        expect(doc.containsKey('activeEnvironmentId'), isFalse);

        // 集合树：root → child → grandChild
        final tree = doc['collection'] as Map<String, dynamic>;
        expect(tree['id'], 'root');
        final children = tree['children'] as List<dynamic>;
        expect(children, hasLength(1));
        expect(children.single['id'], 'child');
        final gcChildren =
            (children.single as Map<String, dynamic>)['children'] as List;
        expect(gcChildren.single['id'], 'gc');

        // 请求平铺
        final requests = doc['requests'] as List<dynamic>;
        expect(requests, hasLength(2));
        expect(
          requests.map((r) => (r as Map)['id']),
          containsAll(['req-1', 'req-2']),
        );
        final r2Json = requests.firstWhere(
          (r) => (r as Map)['id'] == 'req-2',
        ) as Map<String, dynamic>;
        expect(r2Json['parentId'], 'child');
        expect(r2Json.containsKey('sortOrder'), isTrue);
        expect(r2Json.containsKey('assertions'), isTrue);
        expect(r2Json.containsKey('preRequestChain'), isTrue);
        expect(r2Json.containsKey('auth'), isTrue);
      });

      test('链 / Auth / 断言深度序列化到请求与集合', () {
        final root = collection(
          id: 'root',
          name: 'Root',
          auth: const AuthConfig(type: AuthType.bearer, token: 'tk'),
          chain: const [
            PreRequestStep(
              id: 's1',
              requestId: 'login',
              extractions: [
                ExtractionRule(
                  id: 'e1',
                  path: r'$.data.token',
                  targetVariable: 'token',
                ),
              ],
            ),
          ],
        );
        final r1 = request(
          id: 'req-1',
          name: 'R1',
          parentId: 'root',
          assertions: [
            const AssertionRule(
              id: 'a1',
              target: AssertionTarget.jsonPath,
              targetArg: r'$.code',
              expected: '0',
            ),
          ],
          auth: const AuthConfig(
            type: AuthType.apiKey,
            apiKeyName: 'X-Key',
            apiKeyValue: 'v',
            apiKeyAddTo: AuthConfig.apiKeyAddToQuery,
          ),
        );

        final doc = service.buildDocument(
          root: root,
          allCollections: [root],
          allRequests: [r1],
          environments: const [],
          globals: const [],
        );

        final tree = doc['collection'] as Map<String, dynamic>;
        expect(tree['auth'], isA<Map<String, dynamic>>());
        expect(tree['auth']['type'], 'bearer');
        expect(tree['preRequestChain'], hasLength(1));
        final step = (tree['preRequestChain'] as List).single as Map;
        expect(step['requestId'], 'login');
        expect((step['extractions'] as List).single['source'], 'bodyJsonPath');

        final r1Json = (doc['requests'] as List).single as Map<String, dynamic>;
        expect(r1Json['auth']['type'], 'apiKey');
        expect(r1Json['auth']['apiKeyAddTo'], 'query');
        final assertion = (r1Json['assertions'] as List).single as Map;
        expect(assertion['target'], 'jsonPath');
        expect(assertion['operator'], 'equals');
        expect(assertion['expected'], '0');
      });
    });

    group('secret 置空', () {
      test('环境与全局变量中的 secret 值导出为空字符串', () {
        final root = collection(id: 'root', name: 'Root');
        const env = Environment(
          id: 'env-1',
          name: 'staging',
          variables: [
            EnvironmentVariable(
              id: 'v1',
              key: 'password',
              value: 'super-secret',
              type: VariableType.secret,
            ),
            EnvironmentVariable(
              id: 'v2',
              key: 'host',
              value: 'https://api.example.com',
            ),
          ],
        );
        const globals = [
          EnvironmentVariable(
            id: 'g1',
            key: 'app_secret',
            value: 'global-secret',
            type: VariableType.secret,
          ),
          EnvironmentVariable(id: 'g2', key: 'region', value: 'cn'),
        ];

        final doc = service.buildDocument(
          root: root,
          allCollections: [root],
          allRequests: const [],
          environments: [env],
          globals: globals,
          activeEnvironmentId: 'env-1',
        );

        final envJson =
            (doc['environments'] as List).single as Map<String, dynamic>;
        final variables = envJson['variables'] as List;
        final password = variables.firstWhere(
          (v) => (v as Map)['key'] == 'password',
        ) as Map<String, dynamic>;
        expect(password['value'], '');
        expect(password['type'], 'secret');
        final host = variables.firstWhere(
          (v) => (v as Map)['key'] == 'host',
        ) as Map<String, dynamic>;
        expect(host['value'], 'https://api.example.com');

        final globalsJson = doc['globals'] as List;
        final appSecret = globalsJson.firstWhere(
          (v) => (v as Map)['key'] == 'app_secret',
        ) as Map<String, dynamic>;
        expect(appSecret['value'], '');
        expect(
          (globalsJson.firstWhere((v) => (v as Map)['key'] == 'region')
              as Map)['value'],
          'cn',
        );

        expect(doc['activeEnvironmentId'], 'env-1');
      });
    });

    group('空集合 / 空环境', () {
      test('空集合导出为空树与空请求；空环境/全局为空数组', () {
        final root = collection(id: 'root', name: 'Empty');
        final doc = service.buildDocument(
          root: root,
          allCollections: [root],
          allRequests: const [],
          environments: const [],
          globals: const [],
        );

        final tree = doc['collection'] as Map<String, dynamic>;
        expect(tree['children'], isEmpty);
        expect(doc['requests'], isEmpty);
        expect(doc['environments'], isEmpty);
        expect(doc['globals'], isEmpty);

        // 文档可正常 JSON 编码
        expect(() => jsonEncode(doc), returnsNormally);
      });
    });

    group('往返（导出 → CLI 侧解析模型）', () {
      test('请求 / 环境 / 集合可按模型 fromJson 还原', () {
        final root = collection(
          id: 'root',
          name: 'Root',
          auth: const AuthConfig(type: AuthType.basic, username: 'u'),
          chain: const [PreRequestStep(id: 's1', requestId: 'login')],
          preRequestRetryOn401: true,
        );
        final r1 = request(
          id: 'req-1',
          name: 'Login',
          parentId: 'root',
          sortOrder: 3,
          assertions: const [
            AssertionRule(
              id: 'a1',
              expected: '200',
            ),
          ],
        );
        const env = Environment(
          id: 'env-1',
          name: 'staging',
          variables: [
            EnvironmentVariable(id: 'v1', key: 'host', value: 'http://h'),
          ],
        );

        final doc = service.buildDocument(
          root: root,
          allCollections: [root],
          allRequests: [r1],
          environments: [env],
          globals: const [],
        );
        // 走一次 JSON 编码/解码，模拟落盘后再读取
        final decoded = jsonDecode(jsonEncode(doc)) as Map<String, dynamic>;

        // 集合
        final tree = decoded['collection'] as Map<String, dynamic>;
        final parsedRoot = Collection.fromJson(tree);
        expect(parsedRoot.id, 'root');
        expect(parsedRoot.auth.type, AuthType.basic);
        expect(parsedRoot.preRequestChain.single.requestId, 'login');
        expect(parsedRoot.preRequestRetryOn401, isTrue);

        // 请求
        final requests = decoded['requests'] as List;
        final parsed = HttpRequest.fromJson(
          requests.single as Map<String, dynamic>,
        );
        expect(parsed.id, 'req-1');
        expect(parsed.name, 'Login');
        expect(parsed.method, HttpMethod.post);
        expect(parsed.parentId, 'root');
        expect(parsed.sortOrder, 3);
        expect(parsed.assertions.single.target, AssertionTarget.status);
        expect(parsed.assertions.single.expected, '200');

        // 环境
        final parsedEnv = Environment.fromJson(
          (decoded['environments'] as List).single as Map<String, dynamic>,
        );
        expect(parsedEnv.name, 'staging');
        expect(parsedEnv.variables.single.key, 'host');
      });
    });

    group('exportToFile', () {
      test('prettyPrint 写入可解码文件', () async {
        final tempDir = Directory.systemTemp.createTempSync('hopp_export_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final root = collection(id: 'root', name: 'Root');
        final savePath = '${tempDir.path}/root.hopp.json';
        await service.exportToFile(
          root: root,
          allCollections: [root],
          allRequests: const [],
          environments: const [],
          globals: const [],
          savePath: savePath,
        );

        final content = await File(savePath).readAsString();
        expect(content, contains('\n')); // prettyPrint 缩进
        final json = jsonDecode(content) as Map<String, dynamic>;
        expect(json['format'], 'hopp-cli');
        expect(json['version'], 1);
      });
    });
  });
}
