/// 运行报告模型与 reporter 渲染（F4.4 CLI）
///
/// 纯 Dart、零依赖（除 models），console 输出仿原型画板 C 的终端样式。
/// 密钥纪律：报告只含断言的 expected/actual/message，不含变量值与响应体。
library;

import 'dart:convert';

import 'package:hopp/models/assertion_rule.dart';
import 'package:hopp/services/assertion/assertion_engine.dart';

/// 单条断言的执行记录
class AssertionEntry {
  const AssertionEntry({
    required this.description,
    required this.outcome,
    this.actual,
    this.message,
    this.expected = '',
  });

  /// 展示描述：`Status code equals 200` / `JSONPath $.a exists`
  final String description;
  final AssertionOutcome outcome;

  /// 实际值（取不到为 null）
  final String? actual;

  /// 失败原因 / skipped 说明
  final String? message;

  /// 期望值（exists / notExists 为空）
  final String expected;

  bool get passed => outcome == AssertionOutcome.passed;
  bool get failed => outcome == AssertionOutcome.failed;
  bool get skipped => outcome == AssertionOutcome.skipped;
}

/// 预请求链单步执行记录（只记变量名，不记值）
class ChainStepEntry {
  const ChainStepEntry({
    required this.name,
    this.statusCode,
    this.error,
    this.extractedKeys = const [],
  });

  /// 被引用请求名（找不到时为 requestId）
  final String name;
  final int? statusCode;
  final String? error;
  final List<String> extractedKeys;
}

/// 单个请求的执行报告
class RequestReport {
  const RequestReport({
    required this.name,
    required this.method,
    required this.displayPath,
    this.statusCode,
    this.statusText,
    this.durationMs,
    this.error,
    this.chainSteps = const [],
    this.assertions = const [],
    this.passed = false,
  });

  final String name;

  /// HTTP 方法大写（GET / POST …）
  final String method;

  /// 展示用路径（解析后的 path + query）
  final String displayPath;
  final int? statusCode;
  final String? statusText;
  final int? durationMs;

  /// 网络错误 / 预请求链失败原因；null = 请求成功发出
  final String? error;
  final List<ChainStepEntry> chainSteps;
  final List<AssertionEntry> assertions;

  /// 总判定：无错误且启用断言全部通过
  final bool passed;

  int get assertionsPassed => assertions.where((a) => a.passed).length;
  int get assertionsEvaluated => assertions.where((a) => !a.skipped).length;
  int get assertionsFailed => assertions.where((a) => a.failed).length;
}

/// 整次运行的报告
class RunReport {
  const RunReport({
    required this.collectionName,
    required this.envName,
    required this.requests,
    required this.durationMs,
  });

  final String collectionName;

  /// 实际使用的环境名（无环境时为 "(none)"）
  final String envName;
  final List<RequestReport> requests;
  final int durationMs;

  int get total => requests.length;
  int get passed => requests.where((r) => r.passed).length;
  int get failed => total - passed;

  int get assertionsPassed =>
      requests.fold(0, (sum, r) => sum + r.assertionsPassed);
  int get assertionsEvaluated =>
      requests.fold(0, (sum, r) => sum + r.assertionsEvaluated);

  /// CI 退出码：全过 0，有失败 1
  int get exitCode => failed == 0 ? 0 : 1;
}

/// 断言规则的展示描述
String describeAssertion(AssertionRule rule) {
  final target = switch (rule.target) {
    AssertionTarget.status => 'Status code',
    AssertionTarget.header => 'Header ${rule.targetArg}',
    AssertionTarget.body => 'Body',
    AssertionTarget.jsonPath => 'JSONPath ${rule.targetArg}',
    AssertionTarget.responseTime => 'Response time',
  };
  final buffer = StringBuffer('$target ${rule.operator.name}');
  if (rule.expected.isNotEmpty) {
    buffer.write(' ${rule.expected}');
  }
  return buffer.toString();
}

// ============================================================
// Reporters
// ============================================================

/// console reporter：每请求一行，失败明细缩进，末尾汇总
String renderConsoleReport(RunReport report, {String? outputPath}) {
  final buffer = StringBuffer()
    ..writeln(
      'Collection: ${report.collectionName} · ${report.total} requests · '
      'env: ${report.envName}',
    );

  for (final r in report.requests) {
    for (final step in r.chainSteps) {
      final status = step.error != null
          ? 'FAILED — ${step.error}'
          : '${step.statusCode ?? '?'}';
      final extracted = step.extractedKeys.isEmpty
          ? ''
          : ' · extracted ${step.extractedKeys.join(', ')}';
      buffer.writeln(
        '  ▸ pre-request chain ${step.name} → $status$extracted',
      );
    }

    final mark = r.passed ? '✓' : '✗';
    final status = r.error != null
        ? 'ERROR — ${r.error}'
        : '${r.statusCode ?? '?'}${r.statusText != null ? ' ${r.statusText}' : ''}';
    final timing = r.durationMs != null ? ' · ${r.durationMs} ms' : '';
    final assertionSummary = r.assertionsEvaluated == 0
        ? ''
        : ' · ${r.assertionsPassed}/${r.assertionsEvaluated} assertions passed';
    buffer.writeln(
      '$mark ${r.method} ${r.displayPath} — $status$timing$assertionSummary',
    );

    for (final a in r.assertions) {
      if (a.failed) {
        var line = '  ✗ ${a.description} — ${a.message ?? 'failed'}';
        if (a.actual != null && a.message != null) {
          line = '  ✗ ${a.description} — ${a.message}, actual: ${a.actual}';
        }
        buffer.writeln(line);
      }
    }
    if (r.error != null && r.chainSteps.isNotEmpty) {
      // 链失败已在上方链明细中体现，无需重复
    }
  }

  final summary = StringBuffer(
    '${report.passed} passed · ${report.failed} failed · '
    '${report.assertionsPassed}/${report.assertionsEvaluated} assertions · '
    '${(report.durationMs / 1000).toStringAsFixed(1)} s',
  );
  if (outputPath != null) {
    summary.write(' · report → $outputPath');
  }
  buffer
    ..writeln(summary.toString())
    ..writeln('exit code: ${report.exitCode}');
  return buffer.toString();
}

/// json reporter：结构化结果（请求名、断言逐条 outcome/actual/message、汇总）
String renderJsonReport(RunReport report, {String? outputPath}) {
  final map = <String, dynamic>{
    'collection': report.collectionName,
    'env': report.envName,
    'durationMs': report.durationMs,
    'summary': <String, dynamic>{
      'requests': report.total,
      'passed': report.passed,
      'failed': report.failed,
      'assertions': <String, dynamic>{
        'evaluated': report.assertionsEvaluated,
        'passed': report.assertionsPassed,
        'failed': report.assertionsEvaluated - report.assertionsPassed,
      },
    },
    if (outputPath != null) 'output': outputPath,
    'requests': [
      for (final r in report.requests)
        <String, dynamic>{
          'name': r.name,
          'method': r.method,
          'path': r.displayPath,
          'passed': r.passed,
          'statusCode': r.statusCode,
          'durationMs': r.durationMs,
          if (r.error != null) 'error': r.error,
          if (r.chainSteps.isNotEmpty)
            'preRequestChain': [
              for (final s in r.chainSteps)
                <String, dynamic>{
                  'name': s.name,
                  'statusCode': s.statusCode,
                  if (s.error != null) 'error': s.error,
                  'extracted': s.extractedKeys,
                },
            ],
          'assertions': [
            for (final a in r.assertions)
              <String, dynamic>{
                'description': a.description,
                'outcome': a.outcome.name,
                if (a.expected.isNotEmpty) 'expected': a.expected,
                if (a.actual != null) 'actual': a.actual,
                if (a.message != null) 'message': a.message,
              },
          ],
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(map);
}

/// junit reporter：testsuite/testcase，失败用 failure 元素，XML 特殊字符转义
String renderJUnitReport(RunReport report, {String? outputPath}) {
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..write(
      '<testsuite name="${_xml(report.collectionName)}" tests="${report.total}" '
      'failures="${report.failed}" time="${_seconds(report.durationMs)}"'
      '${outputPath != null ? ' output="${_xml(outputPath)}"' : ''}>',
    );

  for (final r in report.requests) {
    buffer.write(
      '<testcase name="${_xml('${r.method} ${r.displayPath}')}" '
      'classname="${_xml(r.name)}" time="${_seconds(r.durationMs ?? 0)}"',
    );
    if (r.passed) {
      buffer.writeln('/>');
      continue;
    }

    final details = StringBuffer();
    if (r.error != null) {
      details.writeln(_xml(r.error!));
    }
    for (final a in r.assertions) {
      if (a.failed) {
        details.writeln(
          _xml('${a.description} — ${a.message ?? 'failed'}'),
        );
      }
    }
    final message = r.error ?? '${r.assertionsFailed} assertion(s) failed';
    buffer
      ..writeln('>')
      ..writeln('  <failure message="${_xml(message)}">')
      ..writeln(_xml(details.toString().trimRight()))
      ..writeln('  </failure>')
      ..writeln('</testcase>');
  }

  buffer.writeln('</testsuite>');
  return buffer.toString();
}

/// XML 特殊字符转义（含引号，属性与文本通用）
String _xml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// 毫秒 → 秒（3 位小数，JUnit time 属性）
String _seconds(int ms) => (ms / 1000).toStringAsFixed(3);
