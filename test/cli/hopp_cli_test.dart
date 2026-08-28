import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/models/auth_config.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/environment.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/models/pre_request_step.dart';
import 'package:hopp/services/assertion/assertion_engine.dart';
import 'package:hopp/services/import_export/hopp_export_service.dart';

import '../../cli/src/app.dart';
import '../../cli/src/cli_args.dart';
import '../../cli/src/export_document.dart';
import '../../cli/src/report.dart';
import '../../cli/src/runner.dart';

/// Hopp CLI 测试（F4.4）
///
/// - 单测：args 解析、环境合并优先级、reporter 输出、退出码
/// - 集成：dart:io HttpServer 起本地服务，跑预请求链（sha1 管道提 token）
///   → 下一请求 {{token}} + 断言，验证 exit 0/1
void main() {
  group('parseCliArgs', () {
    test('完整参数', () {
      final result = parseCliArgs([
        'run',
        'api.hopp.json',
        '--env',
        'staging',
        '--env-var',
        'A=1',
        '--env-var',
        'B=2',
        '--reporter',
        'junit',
        '--output',
        'report.xml',
        '--timeout',
        '5000',
      ]);
      expect(result.error, isNull);
      final o = result.options!;
      expect(o.filePath, 'api.hopp.json');
      expect(o.env, 'staging');
      expect(o.envVars, {'A': '1', 'B': '2'});
      expect(o.reporter, 'junit');
      expect(o.output, 'report.xml');
      expect(o.timeoutMs, 5000);
    });

    test('缺文件参数 / 多余参数 / 未知命令 → error', () {
      expect(parseCliArgs(['run']).error, isNotNull);
      expect(parseCliArgs(['run', 'a.json', 'b.json']).error, isNotNull);
      expect(parseCliArgs(['fetch']).error, isNotNull);
      expect(parseCliArgs([]).error, isNotNull);
    });

    test('--env-var 格式错误 / --timeout 非数字 / --reporter 非法 → error', () {
      expect(
        parseCliArgs(['run', 'a', '--env-var', 'NO_EQUALS']).error,
        isNotNull,
      );
      expect(parseCliArgs(['run', 'a', '--env-var', '=v']).error, isNotNull);
      expect(parseCliArgs(['run', 'a', '--timeout', 'abc']).error, isNotNull);
      expect(parseCliArgs(['run', 'a', '--reporter', 'xml']).error, isNotNull);
    });

    test('--help → showHelp；hopp --help 同', () {
      expect(parseCliArgs(['run', '--help']).showHelp, isTrue);
      expect(parseCliArgs(['--help']).showHelp, isTrue);
      expect(parseCliArgs(['run', 'a']).showHelp, isFalse);
    });
  });

  group('resolveEnvironment', () {
    HoppExportDocument docWith({
      List<Environment> environments = const [],
      List<EnvironmentVariable> globals = const [],
      String? activeEnvironmentId,
    }) {
      const root = Collection(id: 'c1', name: 'Root');
      return HoppExportDocument(
        collection: ExportCollectionNode(
          id: root.id,
          name: root.name,
          sortOrder: 0,
          auth: const AuthConfig(),
          preRequestChain: const [],
          preRequestRetryOn401: false,
          children: const [],
        ),
        requests: const [],
        environments: environments,
        globals: globals,
        activeEnvironmentId: activeEnvironmentId,
      );
    }

    const envStaging = Environment(
      id: 'e1',
      name: 'staging',
      variables: [
        EnvironmentVariable(id: 'v1', key: 'host', value: 'http://h'),
      ],
    );
    const envProd = Environment(
      id: 'e2',
      name: 'prod',
      variables: [
        EnvironmentVariable(id: 'v2', key: 'host', value: 'http://p'),
      ],
    );

    test('按名称匹配；未指定用 activeEnvironmentId；再退到第一个；都没有空环境', () {
      final doc = docWith(
        environments: [envStaging, envProd],
        activeEnvironmentId: 'e2',
      );

      final byName = resolveEnvironment(
        doc: doc,
        options: const RunOptions(filePath: 'x', env: 'staging'),
        processEnvironment: const {},
      );
      expect(byName.envName, 'staging');
      expect(byName.variables['host'], 'http://h');

      final byActive = resolveEnvironment(
        doc: doc,
        options: const RunOptions(filePath: 'x'),
        processEnvironment: const {},
      );
      expect(byActive.envName, 'prod');

      final empty = resolveEnvironment(
        doc: docWith(),
        options: const RunOptions(filePath: 'x'),
        processEnvironment: const {},
      );
      expect(empty.envName, '(none)');
      expect(empty.variables, isEmpty);
    });

    test('名称不存在 → FormatException', () {
      final doc = docWith(environments: [envStaging]);
      expect(
        () => resolveEnvironment(
          doc: doc,
          options: const RunOptions(filePath: 'x', env: 'nope'),
          processEnvironment: const {},
        ),
        throwsFormatException,
      );
    });

    test('优先级：--env-var > 环境 > 全局；进程环境只回填空值', () {
      final doc = docWith(
        environments: const [
          Environment(
            id: 'e1',
            name: 's',
            variables: [
              EnvironmentVariable(id: 'v1', key: 'host', value: 'http://env'),
              EnvironmentVariable(id: 'v2', key: 'shared', value: 'env-wins'),
              EnvironmentVariable(
                id: 'v3',
                key: 'password',
                value: '',
                type: VariableType.secret,
              ),
            ],
          ),
        ],
        globals: const [
          EnvironmentVariable(id: 'g1', key: 'shared', value: 'global'),
          EnvironmentVariable(id: 'g2', key: 'region', value: 'cn'),
        ],
      );

      final res = resolveEnvironment(
        doc: doc,
        options: const RunOptions(
          filePath: 'x',
          env: 's',
          envVars: {'host': 'http://override'},
        ),
        processEnvironment: {'password': 'from-proc', 'unused': 'x'},
      );

      expect(res.variables['host'], 'http://override'); // --env-var 最高
      expect(res.variables['shared'], 'env-wins'); // 环境 > 全局
      expect(res.variables['region'], 'cn'); // 全局在底
      expect(res.variables['password'], 'from-proc'); // 空值由进程环境回填
      expect(res.variables.containsKey('unused'), isFalse); // 不回插新 key
    });

    test('外部 env 文件路径：按原生 env json 解析', () async {
      final tempDir = Directory.systemTemp.createTempSync('hopp_cli_env_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final envFile = File('${tempDir.path}/local.env.json')
        ..writeAsStringSync(
          jsonEncode({
            'id': 'e9',
            'name': 'local',
            'variables': [
              {
                'id': 'v1',
                'key': 'host',
                'value': 'http://local',
                'type': 'string',
                'enabled': true,
              },
            ],
          }),
        );

      final res = resolveEnvironment(
        doc: docWith(environments: [envStaging]),
        options: RunOptions(filePath: 'x', env: envFile.path),
        processEnvironment: const {},
      );
      expect(res.envName, 'local');
      expect(res.variables['host'], 'http://local');
    });
  });

  group('reporters', () {
    RunReport sampleReport() {
      return const RunReport(
        collectionName: 'Demo & <Co>',
        envName: 'staging',
        durationMs: 6300,
        requests: [
          RequestReport(
            name: 'List',
            method: 'GET',
            displayPath: '/items',
            statusCode: 200,
            statusText: 'OK',
            durationMs: 245,
            passed: true,
            assertions: [
              AssertionEntry(
                description: 'Status code equals 200',
                outcome: AssertionOutcome.passed,
                expected: '200',
              ),
            ],
          ),
          RequestReport(
            name: 'Detail',
            method: 'GET',
            displayPath: '/items/1',
            statusCode: 200,
            statusText: 'OK',
            durationMs: 251,
            assertions: [
              AssertionEntry(
                description: r'JSONPath $.data.token exists',
                outcome: AssertionOutcome.failed,
                message: 'path not found',
              ),
            ],
          ),
          RequestReport(
            name: 'Down',
            method: 'POST',
            displayPath: '/down',
            error: 'Connection error: refused',
          ),
        ],
      );
    }

    test('console：请求行 + 失败明细缩进 + 汇总 + exit code', () {
      final text = renderConsoleReport(sampleReport(), outputPath: 'r.xml');
      expect(
        text,
        contains('Collection: Demo & <Co> · 3 requests · env: staging'),
      );
      expect(
        text,
        contains('✓ GET /items — 200 OK · 245 ms · 1/1 assertions passed'),
      );
      expect(
        text,
        contains('✗ GET /items/1 — 200 OK · 251 ms · 0/1 assertions passed'),
      );
      expect(
        text,
        contains(r'  ✗ JSONPath $.data.token exists — path not found'),
      );
      expect(
        text,
        contains('✗ POST /down — ERROR — Connection error: refused'),
      );
      expect(
        text,
        contains(
          '1 passed · 2 failed · 1/2 assertions · 6.3 s · report → r.xml',
        ),
      );
      expect(text, contains('exit code: 1'));
    });

    test('json：结构化可解码，断言逐条 outcome/message', () {
      final text = renderJsonReport(sampleReport());
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      expect(decoded['collection'], 'Demo & <Co>');
      final summary = decoded['summary'] as Map<String, dynamic>;
      expect(summary['requests'], 3);
      expect(summary['failed'], 2);
      final requests = decoded['requests'] as List;
      final failed = requests[1] as Map<String, dynamic>;
      final assertions = failed['assertions'] as List;
      expect((assertions.single as Map)['outcome'], 'failed');
      expect((assertions.single as Map)['message'], 'path not found');
    });

    test('junit：合法 XML 结构，failure 元素，特殊字符转义', () {
      final text = renderJUnitReport(sampleReport());
      expect(
        text,
        contains(
          '<testsuite name="Demo &amp; &lt;Co&gt;" tests="3" failures="2" time="6.300">',
        ),
      );
      expect(text, contains('<testcase name="GET /items"'));
      expect(
        text,
        contains('<failure message="1 assertion(s) failed">'),
      );
      expect(
        text,
        contains(r'JSONPath $.data.token exists — path not found'),
      );
      expect(text, contains('Connection error: refused'));
      expect(text, contains('</testsuite>'));
      // XML 可解析（用内置解析器验证结构合法性）
      expect(() => checkXml(text), returnsNormally);
    });
  });

  group('RunReport.exitCode', () {
    test('全过 0；有失败 1', () {
      const allPass = RunReport(
        collectionName: 'c',
        envName: 'e',
        durationMs: 1,
        requests: [
          RequestReport(
            name: 'a',
            method: 'GET',
            displayPath: '/',
            passed: true,
          ),
        ],
      );
      expect(allPass.exitCode, 0);

      const withFail = RunReport(
        collectionName: 'c',
        envName: 'e',
        durationMs: 1,
        requests: [
          RequestReport(
            name: 'a',
            method: 'GET',
            displayPath: '/',
            error: 'network',
          ),
        ],
      );
      expect(withFail.exitCode, 1);
    });
  });

  group('集成：HttpServer 实跑（预请求链 + sha1 管道 + 断言）', () {
    late HttpServer server;
    late Directory tempDir;
    late String baseUrl;
    final received = <String>[];

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://127.0.0.1:${server.port}';
      server.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        received.add('${request.method} ${request.uri.path} $body');
        if (request.uri.path == '/login' && request.method == 'POST') {
          final payload = jsonDecode(body) as Map<String, dynamic>;
          final expectedHash = sha1.convert(utf8.encode('pw123')).toString();
          final ok = payload['password'] == expectedHash;
          request.response.statusCode = ok ? 200 : 401;
          request.response.write(
            ok ? '{"data":{"token":"tk-1"}}' : '{"error":"bad credentials"}',
          );
        } else if (request.uri.path == '/devices' && request.method == 'GET') {
          final token = request.headers.value('x-token');
          if (token == 'tk-1') {
            request.response.statusCode = 200;
            request.response.write('{"code":0,"items":[1,2]}');
          } else {
            request.response.statusCode = 401;
            request.response.write('{"error":"unauthorized"}');
          }
        } else {
          request.response.statusCode = 404;
          request.response.write('{"error":"not found"}');
        }
        await request.response.close();
      });
    });

    tearDownAll(() async {
      await server.close(force: true);
    });

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('hopp_cli_it_');
      received.clear();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    /// 构造导出文件：login（被链引用）+ devices（带预请求链与断言）
    String writeExport({int expectedCode = 0}) {
      const root = Collection(id: 'col', name: 'HaiShen');
      const login = HttpRequest(
        id: 'login',
        name: 'Login',
        method: HttpMethod.post,
        url: '{{host}}/login',
        body: '{"password": "{{password | sha1}}"}',
        bodyType: 'json',
        parentId: 'col',
      );
      final devices = HttpRequest(
        id: 'devices',
        name: 'Devices',
        url: '{{host}}/devices',
        parentId: 'col',
        headers: const [
          KeyValuePair(
            id: 'h1',
            key: 'X-Token',
            value: '{{token}}',
          ),
        ],
        preRequestChain: const [
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
        assertions: [
          const AssertionRule(
            id: 'a1',
            expected: '200',
          ),
          AssertionRule(
            id: 'a2',
            target: AssertionTarget.jsonPath,
            targetArg: r'$.code',
            expected: '$expectedCode',
          ),
        ],
      );

      // secret 变量：导出时置空，由 --env-var 注入（CI 场景）
      final staging = Environment(
        id: 'env-1',
        name: 'staging',
        variables: [
          EnvironmentVariable(id: 'v1', key: 'host', value: baseUrl),
          const EnvironmentVariable(
            id: 'v2',
            key: 'password',
            value: '',
            type: VariableType.secret,
          ),
        ],
      );

      const service = HoppExportService();
      final doc = service.buildDocument(
        root: root,
        allCollections: [root],
        allRequests: [login, devices],
        environments: [staging],
        globals: const [],
        activeEnvironmentId: 'env-1',
      );

      final path = '${tempDir.path}/haishen.hopp.json';
      File(path).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(doc),
      );
      return path;
    }

    List<String> outLines = [];
    List<String> errLines = [];

    Future<int> runCli(List<String> args) async {
      outLines = [];
      errLines = [];
      return runHoppCli(
        args,
        out: outLines.add,
        err: errLines.add,
      );
    }

    test('全过：链提取 token → {{token}} 断言通过，exit 0', () async {
      final file = writeExport();
      final code = await runCli([
        'run',
        file,
        '--env',
        'staging',
        '--env-var',
        'password=pw123',
      ]);

      expect(code, 0);
      final out = outLines.join('\n');
      expect(out, contains('Collection: HaiShen · 2 requests · env: staging'));
      expect(out, contains('▸ pre-request chain Login → 200'));
      expect(out, contains('extracted token'));
      expect(out, contains('✓ GET /devices — 200'));
      expect(out, contains('2/2 assertions passed'));
      expect(out, contains('2 passed · 0 failed'));
      expect(out, contains('exit code: 0'));

      // 登录请求体确实携带 sha1 后的密码（管道真实生效）
      expect(
        received.any(
          (r) =>
              r.startsWith('POST /login ') &&
              r.contains(sha1.convert(utf8.encode('pw123')).toString()),
        ),
        isTrue,
      );
    });

    test('断言失败：exit 1，失败明细含断言 message', () async {
      final file = writeExport(expectedCode: 999);
      final code = await runCli([
        'run',
        file,
        '--env-var',
        'password=pw123',
      ]);

      expect(code, 1);
      final out = outLines.join('\n');
      expect(out, contains('✗ GET /devices'));
      expect(out, contains('1/2 assertions passed'));
      expect(out, contains('expected "999"'));
      expect(out, contains('exit code: 1'));
    });

    test('链失败（引用请求缺失）：该请求记 failed 并继续，exit 1', () async {
      final file = writeExport();
      final json =
          jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>;
      // 删除 login 请求，链步骤引用失效
      json['requests'] = (json['requests'] as List)
          .where((r) => (r as Map)['id'] != 'login')
          .toList();
      File(file).writeAsStringSync(jsonEncode(json));

      final code = await runCli(['run', file, '--env-var', 'password=pw123']);
      expect(code, 1);
      final out = outLines.join('\n');
      expect(out, contains('pre-request chain failed'));
      expect(out, contains('0 passed · 1 failed'));
    });

    test('网络错误（host 变量缺失指向无效地址）→ 请求 failed，exit 1', () async {
      final file = writeExport();
      final code = await runCli([
        'run',
        file,
        '--env-var',
        'password=pw123',
        '--env-var',
        'host=http://127.0.0.1:1', // 关闭的端口
        '--timeout',
        '800',
      ]);
      expect(code, 1);
      final out = outLines.join('\n');
      expect(out, contains('ERROR'));
      expect(out, contains('exit code: 1'));
    });

    test('文件不存在 / 非法 JSON / 非 hopp 格式 → exit 2', () async {
      expect(await runCli(['run', '${tempDir.path}/missing.json']), 2);
      expect(errLines.join(), contains('File not found'));

      final bad = File('${tempDir.path}/bad.json')
        ..writeAsStringSync('{not json');
      expect(await runCli(['run', bad.path]), 2);

      final notHopp = File('${tempDir.path}/other.json')
        ..writeAsStringSync('{"format":"postman"}');
      expect(await runCli(['run', notHopp.path]), 2);
      expect(errLines.join(), contains('Not a Hopp CLI file'));
    });

    test('junit reporter --output 写文件；json reporter 打 stdout', () async {
      final file = writeExport();
      final junitPath = '${tempDir.path}/report.xml';
      final code = await runCli([
        'run',
        file,
        '--env-var',
        'password=pw123',
        '--reporter',
        'junit',
        '--output',
        junitPath,
      ]);
      expect(code, 0);
      final xml = File(junitPath).readAsStringSync();
      expect(xml, contains('<testsuite name="HaiShen"'));
      expect(xml, contains('<testcase name="GET /devices"'));
      expect(xml, contains('time="'));

      final code2 = await runCli([
        'run',
        file,
        '--env-var',
        'password=pw123',
        '--reporter',
        'json',
      ]);
      expect(code2, 0);
      final decoded = jsonDecode(outLines.join('\n')) as Map<String, dynamic>;
      expect(decoded['collection'], 'HaiShen');
      final requestList = decoded['requests'] as List;
      expect(requestList, hasLength(2));
      expect(
        requestList.every((r) => (r as Map)['passed'] == true),
        isTrue,
      );
    });
  });
}

/// 最小 XML 结构校验（避免引入新依赖：检查标签配对的核心结构）
void checkXml(String xml) {
  // 移除声明与自闭合标签后，成对标签应完全闭合
  final cleaned = xml
      .replaceAll(RegExp(r'<\?[^?]*\?>'), '')
      .replaceAll(RegExp('<[A-Za-z][^>]*?/>'), '');
  final stack = <String>[];
  final pattern = RegExp('<(/?)([A-Za-z]+)[^>]*>');
  for (final m in pattern.allMatches(cleaned)) {
    final closing = m.group(1) == '/';
    final name = m.group(2)!;
    if (closing) {
      if (stack.isEmpty || stack.last != name) {
        throw FormatException('Mismatched </$name>');
      }
      stack.removeLast();
    } else {
      stack.add(name);
    }
  }
  if (stack.isNotEmpty) {
    throw FormatException('Unclosed tags: $stack');
  }
}
