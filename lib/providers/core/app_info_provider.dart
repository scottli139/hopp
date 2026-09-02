import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 应用版本号兜底值（与 pubspec.yaml `version` 保持一致，
/// 由 test/app_version_test.dart 守护同步）。
///
/// 正常运行时版本号由 package_info_plus 从应用包信息读取
/// （见 [appVersionProvider]），此常量仅在该读取失败（如单元测试
/// 环境）时使用。
const kFallbackAppVersion = '0.15.0';

/// 应用版本号 Provider（Issue #13）。
///
/// 版本号唯一事实来源是 `pubspec.yaml` 的 `version` 字段：Flutter 构建时
/// 会把它写入应用包信息，运行时通过 package_info_plus 读回，避免在代码中
/// 多处硬编码。读取失败（如单元测试环境无平台插件）时回退到
/// [kFallbackAppVersion]（与 pubspec 的同步由 app_version_test 守护）。
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  } catch (_) {
    return kFallbackAppVersion;
  }
});
