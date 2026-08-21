import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 设计守卫：静态扫描 lib/ 源码，拦截违反设计系统的写法。
///
/// 规则（G1–G5 白名单 lib/theme/；G6/G7 全局适用，含 lib/theme/）：
///   G1 禁止 Colors.*（Material 色板）
///   G2 禁止 Color(0x…) 字面色值
///   G3 禁止内联 fontSize
///   G4 禁止 fontFamily 字面量
///   G5 禁止 BorderRadius.circular(数字)
///   G6 禁止 withOpacity(（统一 withValues(alpha:) 或 token）
///   G7 禁止 FontWeight.bold（显式 w600/w700）
///
/// 基线 ratchet：存量违规记录在 test/design_guard_baseline.json（文件×规则
/// 计数），只允许减少、不允许增加。违规减少后运行以下命令收紧基线并随改动
/// 一起提交：
///   DESIGN_GUARD_UPDATE=1 fvm flutter test test/design_guard_test.dart
const _baselinePath = 'test/design_guard_baseline.json';

final _rules = <String, RegExp>{
  'G1': RegExp(r'(^|[^A-Za-z])Colors\.'),
  'G2': RegExp(r'(^|[^A-Za-z])Color\(0x'),
  'G3': RegExp('(^|[^A-Za-z])fontSize:'),
  'G4': RegExp('(^|[^A-Za-z])fontFamily:'),
  'G5': RegExp(r'BorderRadius\.circular\(\s*\d'),
  'G6': RegExp(r'withOpacity\('),
  'G7': RegExp(r'(^|[^A-Za-z])FontWeight\.bold\b'),
};

/// G6/G7 全局适用；G1–G5 跳过 lib/theme/（token 定义所在地）
const _globalRules = {'G6', 'G7'};

bool _excluded(String path) {
  return path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.startsWith('lib/l10n/');
}

/// 扫描 lib/，返回 {文件: {规则: 次数}}（仅保留非零项）
Map<String, Map<String, int>> _scan() {
  final result = <String, Map<String, int>>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => !_excluded(p))
      .toList()
    ..sort();

  for (final path in files) {
    final inTheme = path.startsWith('lib/theme/');
    final lines = File(path).readAsLinesSync();
    for (final entry in _rules.entries) {
      if (inTheme && !_globalRules.contains(entry.key)) {
        continue;
      }
      var count = 0;
      for (final line in lines) {
        if (line.trimLeft().startsWith('//')) {
          continue;
        }
        count += entry.value.allMatches(line).length;
      }
      if (count > 0) {
        result.putIfAbsent(path, () => {})[entry.key] = count;
      }
    }
  }
  return result;
}

Map<String, Map<String, int>> _readBaseline() {
  final file = File(_baselinePath);
  if (!file.existsSync()) {
    return {};
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final files = json['files'] as Map<String, dynamic>? ?? {};
  return files.map(
    (path, rules) => MapEntry(
      path,
      (rules as Map<String, dynamic>).map(
        (rule, count) => MapEntry(rule, count as int),
      ),
    ),
  );
}

void _writeBaseline(Map<String, Map<String, int>> actual) {
  final sorted = Map.fromEntries(
    actual.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  final payload = {
    'note': '设计守卫基线（文件×规则计数，只减不增）。更新命令：'
        'DESIGN_GUARD_UPDATE=1 fvm flutter test test/design_guard_test.dart',
    'files': sorted,
  };
  File(_baselinePath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
  );
}

int _total(Map<String, Map<String, int>> m) => m.values
    .expand((rules) => rules.values)
    .fold(0, (sum, count) => sum + count);

void main() {
  test('设计守卫：lib/ 样式违规不超过基线', () {
    final actual = _scan();

    // 基线更新模式：DESIGN_GUARD_UPDATE=1 时重写基线并直接通过
    if (Platform.environment['DESIGN_GUARD_UPDATE'] == '1') {
      _writeBaseline(actual);
      // ignore: avoid_print
      print('设计守卫基线已更新：${_total(actual)} 处存量违规 -> $_baselinePath');
      return;
    }

    final baseline = _readBaseline();
    final increased = <String>[];
    final decreased = <String>[];

    final paths = <String>{...baseline.keys, ...actual.keys}.toList()..sort();
    for (final path in paths) {
      final rules = <String>{
        ...?baseline[path]?.keys,
        ...?actual[path]?.keys,
      }.toList()
        ..sort();
      for (final rule in rules) {
        final base = baseline[path]?[rule] ?? 0;
        final now = actual[path]?[rule] ?? 0;
        final line = '$rule $path: 基线 $base -> 实际 $now';
        if (now > base) {
          increased.add(line);
        }
        if (now < base) {
          decreased.add(line);
        }
      }
    }

    expect(
      increased,
      isEmpty,
      reason: '发现新增样式违规（违反设计系统，见 docs/DESIGN_SYSTEM.md）：\n'
          '${increased.map((e) => '  $e').join('\n')}\n'
          '请改用 lib/theme/ token 或 lib/widgets/common/ 组件。',
    );
    expect(
      decreased,
      isEmpty,
      reason: '违规减少，请收紧基线（ratchet 只减不增）：\n'
          '${decreased.map((e) => '  $e').join('\n')}\n'
          '运行：DESIGN_GUARD_UPDATE=1 '
          'fvm flutter test test/design_guard_test.dart',
    );
  });
}
