/// `hopp` CLI 应用编排（F4.4）
///
/// 组合参数解析 → 文件加载 → 文档解析 → 环境解析 → 执行 → 报告输出，
/// 返回进程退出码（0 全过 / 1 有失败 / 2 参数或文件错误）。
///
/// 输出经 out/err 回调注入（测试可捕获），默认打印到控制台。
library;

import 'dart:convert';
import 'dart:io';

import 'package:hopp/services/http_service.dart';

import 'cli_args.dart';
import 'export_document.dart';
import 'report.dart';
import 'runner.dart';

/// CLI 退出码
const int exitOk = 0;
const int exitFailed = 1;
const int exitUsage = 2;

/// 运行 hopp CLI，返回退出码
Future<int> runHoppCli(
  List<String> args, {
  HttpService? httpService,
  void Function(String line)? out,
  void Function(String line)? err,
}) async {
  final printOut = out ?? print;
  final printErr = err ?? stderr.writeln;

  // 1. 参数解析
  final parsed = parseCliArgs(args);
  if (parsed.showHelp) {
    printOut(usage);
    return exitOk;
  }
  if (parsed.error != null) {
    printErr(parsed.error!);
    return exitUsage;
  }
  final options = parsed.options!;

  // 2. 读取导出文件
  final File file = File(options.filePath);
  if (!file.existsSync()) {
    printErr('File not found: ${options.filePath}');
    return exitUsage;
  }
  final Map<String, dynamic> json;
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('expected a JSON object');
    }
    json = decoded;
  } on FormatException catch (e) {
    printErr('Invalid JSON in ${options.filePath}: ${e.message}');
    return exitUsage;
  }

  // 3. 解析导出文档
  final HoppExportDocument doc;
  try {
    doc = HoppExportDocument.fromJson(json);
  } on FormatException catch (e) {
    printErr('Invalid Hopp export file: ${e.message}');
    return exitUsage;
  }

  // 4. 解析环境
  final EnvironmentResolution environment;
  try {
    environment = resolveEnvironment(doc: doc, options: options);
  } on FormatException catch (e) {
    printErr(e.message);
    return exitUsage;
  }

  // 5. 执行
  final runner = CliRunner(httpService: httpService);
  final report = await runner.run(
    doc: doc,
    environment: environment,
    timeoutMs: options.timeoutMs,
  );

  // 6. 报告输出
  final rendered = switch (options.reporter) {
    'console' => renderConsoleReport(report, outputPath: options.output),
    'json' => renderJsonReport(report, outputPath: options.output),
    'junit' => renderJUnitReport(report, outputPath: options.output),
    _ => renderConsoleReport(report, outputPath: options.output),
  };

  if (options.output != null) {
    final outputFile = File(options.output!);
    try {
      outputFile.writeAsStringSync(rendered);
    } on FileSystemException catch (e) {
      printErr('Cannot write report to ${options.output}: ${e.message}');
      return exitUsage;
    }
    // console 报告写文件后仍向终端输出一份（交互反馈）；
    // json/junit 落到文件后 stdout 保持安静，便于管道处理
    if (options.reporter == 'console') {
      printOut(rendered);
    }
  } else {
    printOut(rendered);
  }

  return report.exitCode;
}
