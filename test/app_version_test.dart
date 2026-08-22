import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/utils/constants.dart';

/// 版本号同步守护（Issue #13）。
///
/// 运行时版本号由 package_info_plus 从应用包信息读取（构建时来源于
/// pubspec.yaml 的 version 字段）；[AppConstants.appVersion] 只是读取失败
/// 时的兜底值，必须与 pubspec 保持同步，否则兜底值会悄悄过时。
void main() {
  test('AppConstants.appVersion 与 pubspec.yaml version 一致', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true).firstMatch(
      pubspec,
    );
    expect(match, isNotNull, reason: 'pubspec.yaml 缺少 version 字段');
    expect(
      AppConstants.appVersion,
      match!.group(1),
      reason: 'AppConstants.appVersion 与 pubspec.yaml version 不一致，'
          '请同步更新 lib/utils/constants.dart',
    );
  });
}
