import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden 测试跨平台容差。
///
/// golden 基线图在 macOS 上生成与目检（字体渲染为唯一事实来源）；CI 运行在
/// Linux，字体光栅化差异会造成 0.1%~0.6% 的像素差（同一张图逐像素对比）。
/// 因此在非 macOS 主机上安装容差比较器：diff ≤ 1% 视为通过（仍覆盖渲染
/// 崩溃与结构性破损），macOS 本地保持严格 0 容差，视觉回归不放宽。
const double _kNonMacOsGoldenTolerance = 0.01;

class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _kNonMacOsGoldenTolerance) {
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (!Platform.isMacOS && goldenFileComparator is LocalFileComparator) {
    final base = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = _TolerantGoldenComparator(
      Uri.parse('${base}test.dart'),
    );
  }
  await testMain();
}
