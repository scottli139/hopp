import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../services/http_service.dart';
import '../../services/storage_service.dart';

// Core services
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final httpServiceProvider = Provider<HttpService>((ref) {
  return HttpService();
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
