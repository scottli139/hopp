import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/services/variable_resolver.dart';
import 'package:hopp/services/variable_transforms.dart';

void main() {
  late VariableResolver resolver;

  /// 参数不做变量解析的便捷入口
  String? apply(String value, String segment) =>
      VariableTransforms.applySingle(value, segment, (s) => s);

  setUp(() {
    resolver = VariableResolver();
  });

  group('splitPipeline', () {
    test('无管道时原样返回', () {
      expect(VariableTransforms.splitPipeline('token'), ['token']);
    });

    test('按顶层 | 切分并 trim', () {
      expect(
        VariableTransforms.splitPipeline(' password | sha1 | base64 '),
        ['password', 'sha1', 'base64'],
      );
    });

    test('括号内的 | 不切分', () {
      expect(
        VariableTransforms.splitPipeline('body | hmac(sha256, {{key}})'),
        ['body', 'hmac(sha256, {{key}})'],
      );
    });

    test('baseName 取第一段', () {
      expect(VariableTransforms.baseName('password | sha1'), 'password');
      expect(VariableTransforms.baseName('token'), 'token');
    });
  });

  group('哈希与编码函数', () {
    test('md5 / sha1 / sha256 输出 hex', () {
      expect(apply('password', 'md5'),
          md5.convert(utf8.encode('password')).toString());
      expect(apply('password', 'sha1'),
          sha1.convert(utf8.encode('password')).toString());
      expect(apply('password', 'sha256'),
          sha256.convert(utf8.encode('password')).toString());
    });

    test('base64 编码', () {
      expect(apply('hello', 'base64'), base64Encode(utf8.encode('hello')));
    });

    test('无参函数多传参数时失败（null）', () {
      expect(apply('x', 'sha1(extra)'), isNull);
    });
  });

  group('hmac', () {
    test('hmac(sha256, key) 输出 hex', () {
      final expected = Hmac(sha256, utf8.encode('key1'))
          .convert(utf8.encode('body'))
          .toString();
      expect(apply('body', 'hmac(sha256, key1)'), expected);
    });

    test('hmac 支持 md5 / sha1', () {
      expect(apply('b', 'hmac(md5, k)'),
          Hmac(md5, utf8.encode('k')).convert(utf8.encode('b')).toString());
      expect(apply('b', 'hmac(sha1, k)'),
          Hmac(sha1, utf8.encode('k')).convert(utf8.encode('b')).toString());
    });

    test('参数个数不符或算法不支持时失败', () {
      expect(apply('b', 'hmac(sha256)'), isNull);
      expect(apply('b', 'hmac(sha512, k)'), isNull);
      expect(apply('b', 'hmac(sha256, k, extra)'), isNull);
    });
  });

  group('aes', () {
    // 与 pointycastle/encrypt 一致的固定向量
    const key16 = '0123456789abcdef';
    const iv16 = 'abcdef0123456789';

    test('cbc 默认输出 base64，可复现', () {
      final result = apply('hello world', 'aes(cbc, $key16, $iv16)');
      expect(result, isNotNull);
      // 同参数两次结果一致（CBC + 固定 iv）
      expect(apply('hello world', 'aes(cbc, $key16, $iv16)'), result);
    });

    test('hex 输出格式', () {
      final result = apply('hello', 'aes(cbc, $key16, $iv16, hex)');
      expect(result, isNotNull);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(result!), isTrue);
    });

    test('ecb 模式（iv 占位不参与）', () {
      final result = apply('hello', 'aes(ecb, $key16, 0000000000000000)');
      expect(result, isNotNull);
    });

    test('key 长度非法时失败', () {
      expect(apply('x', 'aes(cbc, short, $iv16)'), isNull);
    });

    test('cbc 缺 iv 或 iv 长度非法时失败', () {
      expect(apply('x', 'aes(cbc, $key16, )'), isNull);
      expect(apply('x', 'aes(cbc, $key16, short)'), isNull);
    });

    test('未知 mode / format 时失败', () {
      expect(apply('x', 'aes(gcm, $key16, $iv16)'), isNull);
      expect(apply('x', 'aes(cbc, $key16, $iv16, base32)'), isNull);
    });
  });

  group('date_add（F8.5）', () {
    test('毫秒基准按天偏移（-7d）', () {
      expect(apply('1756608000000', 'date_add(-7d)'), '1756003200000');
    });

    test('秒基准偏移输出保持秒（+1h）', () {
      expect(apply('1756608000', 'date_add(1h)'), '1756611600');
    });

    test('各单位 s/m/h/d/w', () {
      const base = 1756608000000; // 固定毫秒值，纯算术与时区无关
      expect(apply('$base', 'date_add(30s)'), '${base + 30000}');
      expect(apply('$base', 'date_add(30m)'), '${base + 1800000}');
      expect(apply('$base', 'date_add(12h)'), '${base + 43200000}');
      expect(apply('$base', 'date_add(+2d)'), '${base + 172800000}');
      expect(apply('$base', 'date_add(1w)'), '${base + 604800000}');
    });

    test('非法输入返回 null：缺单位 / 未知单位 / 参数个数 / 非数字基准', () {
      expect(apply('1756608000000', 'date_add(7)'), isNull);
      expect(apply('1756608000000', 'date_add(7x)'), isNull);
      expect(apply('1756608000000', 'date_add()'), isNull);
      expect(apply('1756608000000', 'date_add(1d, 2d)'), isNull);
      expect(apply('abc', 'date_add(1d)'), isNull);
      expect(apply('', 'date_add(1d)'), isNull);
    });
  });

  group('date_floor（F8.5）', () {
    // 期望值用 local DateTime 构造独立计算，两边都是本地午夜 ↔ epoch 换算，
    // 与测试机时区无关。
    final base = DateTime(2024, 3, 10, 15, 42, 33, 500);
    final baseMs = base.millisecondsSinceEpoch.toString();
    final baseSec = (base.millisecondsSinceEpoch ~/ 1000).toString();

    test('day 取本地今天零点', () {
      final expected = DateTime(2024, 3, 10).millisecondsSinceEpoch;
      expect(apply(baseMs, 'date_floor(day)'), '$expected');
    });

    test('hour 取本小时零点', () {
      final expected = DateTime(2024, 3, 10, 15).millisecondsSinceEpoch;
      expect(apply(baseMs, 'date_floor(hour)'), '$expected');
    });

    test('week 取本周一零点（2024-03-10 周日 → 03-04 周一）', () {
      final expected = DateTime(2024, 3, 4).millisecondsSinceEpoch;
      expect(apply(baseMs, 'date_floor(week)'), '$expected');
    });

    test('month 取本月 1 号零点', () {
      final expected = DateTime(2024, 3, 1).millisecondsSinceEpoch;
      expect(apply(baseMs, 'date_floor(month)'), '$expected');
    });

    test('秒基准输出保持秒', () {
      final expected = DateTime(2024, 3, 10).millisecondsSinceEpoch ~/ 1000;
      expect(apply(baseSec, 'date_floor(day)'), '$expected');
    });

    test('非法单位 / 参数个数 / 非数字基准返回 null', () {
      expect(apply(baseMs, 'date_floor(year)'), isNull);
      expect(apply(baseMs, 'date_floor()'), isNull);
      expect(apply(baseMs, 'date_floor(day, extra)'), isNull);
      expect(apply('abc', 'date_floor(day)'), isNull);
    });
  });

  group('解析器集成（resolve 管道）', () {
    test('{{password | sha1}}', () {
      final result = resolver.resolve(
        '{{password | sha1}}',
        {'password': 'password'},
      );
      expect(result, sha1.convert(utf8.encode('password')).toString());
    });

    test('链式管道：{{text | sha1 | base64}}', () {
      final sha1Hex = sha1.convert(utf8.encode('x')).toString();
      final result =
          resolver.resolve('{{text | sha1 | base64}}', {'text': 'x'});
      expect(result, base64Encode(utf8.encode(sha1Hex)));
    });

    test('参数内嵌套变量：{{body | hmac(sha256, {{secret}})}}', () {
      final result = resolver.resolve(
        '{{body | hmac(sha256, {{secret}})}}',
        {'body': 'b', 'secret': 'k'},
      );
      expect(result,
          Hmac(sha256, utf8.encode('k')).convert(utf8.encode('b')).toString());
    });

    test('动态变量参与管道：{{\$timestampMs | md5}} 产出 32 位 hex', () {
      final result = resolver.resolve('{{\$timestampMs | md5}}', {});
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(result), isTrue);
    });

    test('基础变量未定义时保留原文', () {
      expect(resolver.resolve('{{unknown | sha1}}', {}), '{{unknown | sha1}}');
    });

    test('未知函数时保留原文', () {
      expect(
        resolver.resolve('{{v | rot13}}', {'v': 'x'}),
        '{{v | rot13}}',
      );
    });

    test('普通占位符行为不变', () {
      expect(
        resolver.resolve('https://{{host}}/api', {'host': 'example.com'}),
        'https://example.com/api',
      );
    });

    test('同一文本多个管道表达式', () {
      final result = resolver.resolve(
        '{{a | base64}}-{{b}}',
        {'a': 'x', 'b': 'y'},
      );
      expect(result, '${base64Encode(utf8.encode('x'))}-y');
    });
  });

  group('extractVariables / findUnresolved 管道兼容', () {
    test('extractVariables 取基础变量名', () {
      expect(resolver.extractVariables('{{password | sha1}}'), ['password']);
    });

    test('extractVariables 包含参数中的嵌套变量', () {
      expect(
        resolver.extractVariables('{{body | hmac(sha256, {{secret}})}}'),
        ['body', 'secret'],
      );
    });

    test('findUnresolved 不误报管道表达式', () {
      expect(
        resolver.findUnresolved(
          '{{password | sha1}}',
          {'password': 'x'},
        ),
        isEmpty,
      );
    });

    test('findUnresolved 报告参数中未定义的嵌套变量', () {
      expect(
        resolver.findUnresolved(
            '{{body | hmac(sha256, {{secret}})}}', {'body': 'b'}),
        ['secret'],
      );
    });
  });
}
