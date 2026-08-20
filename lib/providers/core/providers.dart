import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../models/app_settings.dart';
import '../../providers/settings/settings_provider.dart';
import '../../services/http_service.dart';
import '../../services/storage_service.dart';

// Core services
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final httpServiceProvider = Provider<HttpService>((ref) {
  final service = HttpService();

  void applySettings(AppSettings? settings) {
    service.configure(
      timeoutMs: settings?.requestTimeoutMs ?? 30000,
      followRedirects: settings?.followRedirects ?? true,
      maxRedirects: settings?.maxRedirects ?? 10,
      validateCertificates: settings?.validateCertificates ?? true,
    );
  }

  // 监听应用设置变化，动态更新请求超时/重定向/证书验证等默认值
  ref.listen(settingsProvider, (previous, next) {
    applySettings(next.valueOrNull);
  });

  // 初始配置（使用已加载的设置，或默认值）
  applySettings(ref.read(settingsProvider).valueOrNull);
  return service;
});

final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );
});
