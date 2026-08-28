/// Hopp CLI 入口（F4.4）
///
/// 用法：`hopp run <file.hopp.json> [options]`（见 cli_args.dart usage）。
/// 退出码：0 全过 / 1 有失败 / 2 参数或文件错误。
library;

import 'dart:io';

import 'src/app.dart';

Future<void> main(List<String> args) async {
  final exitCode = await runHoppCli(args);
  exit(exitCode);
}
