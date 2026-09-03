import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/auth_config.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/http_response.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/models/pre_request_step.dart';
import 'package:hopp/services/pre_request/pre_request_chain_runner.dart';
import 'package:hopp/services/pre_request/response_extractor.dart';
import 'package:hopp/services/variable_resolver.dart';
import 'package:logger/logger.dart';
import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('ResponseExtractor', () {
    HttpResponse jsonResponse(String body) => HttpResponse(
          body: body,
          statusCode: 200,
          headers: [
            KeyValuePair.empty().copyWith(key: 'X-Request-Id', value: 'req-42'),
          ],
        );

    group('bodyJsonPath', () {
      final response = jsonResponse(
        '{"code":0,"data":{"token":"tk-abc","expire":7200,"items":[{"id":7}]}}',
      );

      ExtractionRule rule(String path) => ExtractionRule(
            id: 'r1',
            source: ExtractionSourceType.bodyJsonPath,
            path: path,
            targetVariable: 'token',
          );

      test('点路径提取字符串', () {
        expect(ResponseExtractor.extract(response, rule(r'$.data.token')),
            'tk-abc');
      });

      test('数字标量转字符串', () {
        expect(ResponseExtractor.extract(response, rule(r'$.data.expire')),
            '7200');
      });

      test('数组下标', () {
        expect(
          ResponseExtractor.extract(response, rule(r'$.data.items[0].id')),
          '7',
        );
      });

      test('对象重新编码为 JSON 字符串', () {
        final result =
            ResponseExtractor.extract(response, rule(r'$.data.items'));
        expect(result, '[{"id":7}]');
      });

      test('路径不存在 / 非 JSON / 非法语法返回 null', () {
        expect(ResponseExtractor.extract(response, rule(r'$.data.missing')),
            isNull);
        expect(
            ResponseExtractor.extract(jsonResponse('not json'), rule(r'$.a')),
            isNull);
        expect(ResponseExtractor.extract(response, rule('data.token')), isNull);
        expect(ResponseExtractor.extract(response, rule(r'$.data["token"]')),
            isNull);
      });
    });

    group('header', () {
      test('大小写不敏感匹配', () {
        final rule = ExtractionRule(
          id: 'r1',
          source: ExtractionSourceType.header,
          path: 'x-request-id',
          targetVariable: 'rid',
        );
        expect(ResponseExtractor.extract(jsonResponse(''), rule), 'req-42');
      });

      test('不存在的 header 返回 null', () {
        final rule = ExtractionRule(
          id: 'r1',
          source: ExtractionSourceType.header,
          path: 'X-Missing',
          targetVariable: 'x',
        );
        expect(ResponseExtractor.extract(jsonResponse(''), rule), isNull);
      });
    });

    group('bodyRegex', () {
      ExtractionRule rule(String pattern) => ExtractionRule(
            id: 'r1',
            source: ExtractionSourceType.bodyRegex,
            path: pattern,
            targetVariable: 'x',
          );

      test('取第一个捕获组', () {
        expect(
          ResponseExtractor.extract(
              jsonResponse('token=abc123;'), rule(r'token=(\w+);')),
          'abc123',
        );
      });

      test('无捕获组取整体匹配', () {
        expect(
          ResponseExtractor.extract(jsonResponse('a-b-c'), rule(r'[a-z]-')),
          'a-',
        );
      });

      test('不匹配 / 非法正则返回 null', () {
        expect(ResponseExtractor.extract(jsonResponse('xyz'), rule(r'\d+')),
            isNull);
        expect(
            ResponseExtractor.extract(jsonResponse('xyz'), rule('([')), isNull);
      });
    });
  });

  group('PreRequestChainRunner.resolveEffective', () {
    HttpRequest request({
      List<PreRequestStep> chain = const [],
      bool retry = false,
      String? parentId,
    }) =>
        HttpRequest(
          id: 'main',
          name: 'Main',
          preRequestChain: chain,
          preRequestRetryOn401: retry,
          parentId: parentId,
        );

    PreRequestStep step(String id) =>
        PreRequestStep(id: id, requestId: 'login-req');

    test('请求级链非空时优先', () {
      final req = request(chain: [step('s1')], retry: true, parentId: 'c1');
      final collections = {
        'c1': Collection(id: 'c1', name: 'C1', preRequestChain: [step('s2')]),
      };

      final (chain, retry) =
          PreRequestChainRunner.resolveEffective(req, collections);
      expect(chain.single.id, 's1');
      expect(retry, isTrue);
    });

    test('请求级为空时继承最近集合的链（含 401 策略）', () {
      final req = request(parentId: 'child');
      final collections = {
        'child': Collection(id: 'child', name: 'Child', parentId: 'root'),
        'root': Collection(
          id: 'root',
          name: 'Root',
          preRequestChain: [step('s1')],
          preRequestRetryOn401: true,
        ),
      };

      final (chain, retry) =
          PreRequestChainRunner.resolveEffective(req, collections);
      expect(chain.single.id, 's1');
      expect(retry, isTrue);
    });

    test('全链为空返回空链；parentId 成环安全', () {
      expect(PreRequestChainRunner.resolveEffective(request(), {}).$1, isEmpty);

      final req = request(parentId: 'c1');
      final collections = {
        'c1': Collection(id: 'c1', name: 'C1', parentId: 'c1'),
      };
      expect(
        PreRequestChainRunner.resolveEffective(req, collections).$1,
        isEmpty,
      );
    });
  });

  group('PreRequestChainRunner.run', () {
    late MockHttpService httpService;
    late MockStorageService storage;
    late PreRequestChainRunner runner;

    final loginRequest = HttpRequest(
      id: 'login-req',
      name: 'Login',
      method: HttpMethod.post,
      url: '{{host}}/login',
      body: '{"password": "{{password | sha1}}"}',
      bodyType: 'json',
    );

    PreRequestStep loginStep({bool enabled = true}) => PreRequestStep(
          id: 's1',
          requestId: 'login-req',
          enabled: enabled,
          extractions: [
            ExtractionRule(
              id: 'e1',
              source: ExtractionSourceType.bodyJsonPath,
              path: r'$.data.token',
              targetVariable: 'token',
            ),
          ],
        );

    setUp(() {
      httpService = MockHttpService();
      storage = MockStorageService();
      runner = PreRequestChainRunner(
        httpService: httpService,
        requestLookup: (id) => storage.getRequest(id),
        resolver: VariableResolver(),
        // 静默日志，避免 PrettyPrinter 刷屏测试输出
        logger: Logger(level: Level.off),
      );
    });

    test('happy path：变量解析（含管道）→ 发送 → 提取 token', () async {
      when(storage.getRequest('login-req'))
          .thenAnswer((_) async => loginRequest);
      when(httpService.sendRequest(any)).thenAnswer(
        (_) async => HttpResponse(
          statusCode: 200,
          body: '{"data":{"token":"tk-1"}}',
        ),
      );

      final result = await runner.run(
        chain: [loginStep()],
        variables: {'host': 'https://api.example.com', 'password': 'pw'},
        collectionsById: {},
      );

      expect(result.allSucceeded, isTrue);
      expect(result.produced['token'], 'tk-1');

      // 验证子请求发送前完成了变量替换与 sha1 管道
      final sent = verify(httpService.sendRequest(captureAny)).captured.single
          as HttpRequest;
      expect(sent.url, 'https://api.example.com/login');
      expect(sent.body, contains('"password": "'));
      expect(sent.body, isNot(contains('{{'))); // 管道已被求值
    });

    test('链式：后续步骤可见前序产出的变量', () async {
      final second = HttpRequest(
        id: 'refresh-req',
        name: 'Refresh',
        method: HttpMethod.post,
        url: 'https://api.example.com/refresh',
        headers: [
          KeyValuePair.empty().copyWith(key: 'X-Token', value: '{{token}}')
        ],
      );
      when(storage.getRequest('login-req'))
          .thenAnswer((_) async => loginRequest);
      when(storage.getRequest('refresh-req')).thenAnswer((_) async => second);
      when(httpService.sendRequest(any)).thenAnswer(
        (_) async => HttpResponse(
          statusCode: 200,
          body: '{"data":{"token":"tk-1"}}',
        ),
      );

      await runner.run(
        chain: [
          loginStep(),
          PreRequestStep(id: 's2', requestId: 'refresh-req'),
        ],
        variables: {'host': 'https://api.example.com', 'password': 'pw'},
        collectionsById: {},
      );

      final captured = verify(httpService.sendRequest(captureAny)).captured;
      final secondSent = captured[1] as HttpRequest;
      expect(secondSent.headers.single.value, 'tk-1');
    });

    test('被引用请求的 Auth 配置生效', () async {
      final authedLogin = loginRequest.copyWith(
        auth: const AuthConfig(type: AuthType.bearer, token: 'static-tk'),
      );
      when(storage.getRequest('login-req'))
          .thenAnswer((_) async => authedLogin);
      when(httpService.sendRequest(any)).thenAnswer(
        (_) async =>
            HttpResponse(statusCode: 200, body: '{"data":{"token":"tk-1"}}'),
      );

      await runner.run(
        chain: [loginStep()],
        variables: {'host': 'h', 'password': 'pw'},
        collectionsById: {},
      );

      final sent = verify(httpService.sendRequest(captureAny)).captured.single
          as HttpRequest;
      expect(sent.headers.single.key, 'Authorization');
      expect(sent.headers.single.value, 'Bearer static-tk');
    });

    test('引用的请求不存在：步骤失败并中断', () async {
      when(storage.getRequest('login-req')).thenAnswer((_) async => null);

      final result = await runner.run(
        chain: [loginStep()],
        variables: {},
        collectionsById: {},
      );

      expect(result.allSucceeded, isFalse);
      expect(result.firstError, contains('Referenced request not found'));
      verifyNever(httpService.sendRequest(any));
    });

    test('网络错误：中断并不再执行后续步骤', () async {
      when(storage.getRequest('login-req'))
          .thenAnswer((_) async => loginRequest);
      when(httpService.sendRequest(any)).thenAnswer(
        (_) async => HttpResponse.error('connection timeout'),
      );

      final result = await runner.run(
        chain: [loginStep(), loginStep()],
        variables: {'host': 'h', 'password': 'pw'},
        collectionsById: {},
      );

      expect(result.allSucceeded, isFalse);
      expect(result.firstError, 'connection timeout');
      verify(httpService.sendRequest(any)).called(1);
    });

    test('停用的步骤被跳过且不影响成功判定', () async {
      final result = await runner.run(
        chain: [loginStep(enabled: false)],
        variables: {},
        collectionsById: {},
      );

      expect(result.allSucceeded, isTrue);
      verifyNever(storage.getRequest(any));
    });

    test('提取路径不存在：记入 missing，变量不产出', () async {
      when(storage.getRequest('login-req'))
          .thenAnswer((_) async => loginRequest);
      when(httpService.sendRequest(any)).thenAnswer(
        (_) async => HttpResponse(statusCode: 200, body: '{"data":{}}'),
      );

      final result = await runner.run(
        chain: [loginStep()],
        variables: {'host': 'h', 'password': 'pw'},
        collectionsById: {},
      );

      expect(result.allSucceeded, isTrue); // HTTP 成功，提取缺失不算步骤失败
      expect(result.produced.containsKey('token'), isFalse);
      expect(result.steps.single.missing, hasLength(1));
    });
  });
}
