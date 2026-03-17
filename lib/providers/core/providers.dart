import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../services/http_service.dart';
import '../../services/storage_service.dart';

// Core services
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final httpServiceProvider = Provider<HttpService>((ref) {
  final service = HttpService();
  // 默认配置（符合 Request Settings 规划：SSL 验证默认 ON）
  service.configure(
    timeoutMs: 30000,
    followRedirects: true,
    maxRedirects: 10,
    validateCertificates: true, // 默认启用证书验证（符合安全最佳实践）
  );
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
