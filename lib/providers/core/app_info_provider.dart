import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../utils/constants.dart';

/// 应用版本号 Provider（Issue #13）。
///
/// 版本号唯一事实来源是 `pubspec.yaml` 的 `version` 字段：Flutter 构建时
/// 会把它写入应用包信息，运行时通过 package_info_plus 读回，避免在代码中
/// 多处硬编码。读取失败（如单元测试环境无平台插件）时回退到
/// [AppConstants.appVersion]（与 pubspec 的同步由 app_version_test 守护）。
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  } catch (_) {
    return AppConstants.appVersion;
  }
});
