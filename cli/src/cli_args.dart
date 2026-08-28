/// `hopp run` 命令行参数解析（F4.4 CLI）
///
/// 用法：
///   `hopp run <file.hopp.json> [--env <name|路径>] [--env-var K=V]...`
///       `[--reporter console|json|junit] [--output <路径>] [--timeout <毫秒>]`
library;

import 'package:args/args.dart';

/// 解析后的 run 命令参数
class RunOptions {
  const RunOptions({
    required this.filePath,
    this.env,
    this.envVars = const {},
    this.reporter = 'console',
    this.output,
    this.timeoutMs,
  });

  /// 导出文件路径（位置参数）
  final String filePath;

  /// 环境：名称（匹配导出文件内 environments[].name）或外部 env json 路径
  final String? env;

  /// `--env-var KEY=VALUE`，最高优先级
  final Map<String, String> envVars;

  /// 报告器：console / json / junit
  final String reporter;

  /// 报告输出路径；null = 按报告器默认（console 打 stdout，其余同）
  final String? output;

  /// 请求超时（毫秒）；null = 30s 默认
  final int? timeoutMs;
}

/// 参数解析结果：要么 options 非空，要么 error 非空
class CliParseResult {
  const CliParseResult._({this.options, this.error, this.showHelp = false});

  factory CliParseResult.ok(RunOptions options) =>
      CliParseResult._(options: options);

  factory CliParseResult.fail(String error) => CliParseResult._(error: error);

  factory CliParseResult.help() => const CliParseResult._(showHelp: true);

  final RunOptions? options;
  final String? error;
  final bool showHelp;
}

/// 构建 run 子命令的 ArgParser
ArgParser buildRunParser() {
  final parser = ArgParser()
    ..addOption('env', help: 'Environment name or path to an env JSON file.')
    ..addMultiOption(
      'env-var',
      help: 'Variable override KEY=VALUE (highest priority). Repeatable.',
    )
    ..addOption(
      'reporter',
      allowed: ['console', 'json', 'junit'],
      defaultsTo: 'console',
      help: 'Report format.',
    )
    ..addOption('output', help: 'Write report to this path.')
    ..addOption(
      'timeout',
      help: 'Request timeout in milliseconds (default 30000).',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');
  return parser;
}

/// 应用级用法文本
const String usage = '''
Hopp CLI — run exported collections in CI.

Usage:
  hopp run <file.hopp.json> [options]

Options:
  --env <name|path>       Environment name (matched in the export file) or
                          path to a native env JSON file.
  --env-var KEY=VALUE     Variable override (highest priority). Repeatable.
  --reporter <name>       console (default) | json | junit.
  --output <path>         Write the report to a file.
  --timeout <ms>          Request timeout in milliseconds (default 30000).
  -h, --help              Show this help.

Exit codes: 0 = all passed, 1 = failures, 2 = usage/parse error.
''';

/// 解析命令行参数（含 `run` 子命令分派）
CliParseResult parseCliArgs(List<String> args) {
  if (args.isEmpty) {
    return CliParseResult.fail('Missing command.\n\n$usage');
  }
  if (args.first == '--help' || args.first == '-h') {
    return CliParseResult.help();
  }
  if (args.first != 'run') {
    return CliParseResult.fail('Unknown command: ${args.first}.\n\n$usage');
  }

  final parser = buildRunParser();
  final ArgResults results;
  try {
    results = parser.parse(args.sublist(1));
  } on FormatException catch (e) {
    return CliParseResult.fail('${e.message}\n\n$usage');
  }

  if (results['help'] as bool) {
    return CliParseResult.help();
  }

  final rest = results.rest;
  if (rest.isEmpty) {
    return CliParseResult.fail('Missing <file.hopp.json> argument.\n\n$usage');
  }
  if (rest.length > 1) {
    return CliParseResult.fail(
      'Unexpected extra arguments: ${rest.sublist(1).join(' ')}.\n\n$usage',
    );
  }

  // 解析 --env-var K=V
  final envVars = <String, String>{};
  for (final raw in results['env-var'] as List<String>) {
    final idx = raw.indexOf('=');
    if (idx <= 0) {
      return CliParseResult.fail(
        'Invalid --env-var "$raw" (expected KEY=VALUE).\n\n$usage',
      );
    }
    envVars[raw.substring(0, idx)] = raw.substring(idx + 1);
  }

  int? timeoutMs;
  final timeoutRaw = results['timeout'] as String?;
  if (timeoutRaw != null) {
    timeoutMs = int.tryParse(timeoutRaw);
    if (timeoutMs == null || timeoutMs <= 0) {
      return CliParseResult.fail(
        'Invalid --timeout "$timeoutRaw" (expected positive milliseconds).\n\n$usage',
      );
    }
  }

  return CliParseResult.ok(
    RunOptions(
      filePath: rest.single,
      env: results['env'] as String?,
      envVars: envVars,
      reporter: results['reporter'] as String,
      output: results['output'] as String?,
      timeoutMs: timeoutMs,
    ),
  );
}
