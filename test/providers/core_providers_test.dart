import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/services/http_service.dart';
import 'package:hopp/services/storage_service.dart';
import 'package:logger/logger.dart';

void main() {
  group('Core Providers', () {
    group('storageServiceProvider', () {
      test('should provide StorageService instance', () {
        final container = ProviderContainer();
        final service = container.read(storageServiceProvider);

        expect(service, isA<StorageService>());
      });

      test('should provide same instance on multiple reads', () {
        final container = ProviderContainer();
        final service1 = container.read(storageServiceProvider);
        final service2 = container.read(storageServiceProvider);

        expect(identical(service1, service2), isTrue);
      });
    });

    group('httpServiceProvider', () {
      test('should provide HttpService instance', () {
        final container = ProviderContainer();
        final service = container.read(httpServiceProvider);

        expect(service, isA<HttpService>());
      });

      test('should provide same instance on multiple reads', () {
        final container = ProviderContainer();
        final service1 = container.read(httpServiceProvider);
        final service2 = container.read(httpServiceProvider);

        expect(identical(service1, service2), isTrue);
      });
    });

    group('loggerProvider', () {
      test('should provide Logger instance', () {
        final container = ProviderContainer();
        final logger = container.read(loggerProvider);

        expect(logger, isA<Logger>());
      });

      test('should provide same instance on multiple reads', () {
        final container = ProviderContainer();
        final logger1 = container.read(loggerProvider);
        final logger2 = container.read(loggerProvider);

        expect(identical(logger1, logger2), isTrue);
      });
    });
  });
}
