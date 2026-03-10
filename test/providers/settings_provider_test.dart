import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/settings/settings_provider.dart';

import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('SettingsNotifier', () {
    late MockStorageService mockStorageService;
    late ProviderContainer container;

    setUp(() {
      mockStorageService = MockStorageService();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('loadSettings', () {
      test('should load settings successfully', () async {
        final settings = AppSettings.defaults().copyWith(
          themeMode: 'dark',
          language: 'zh',
        );

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => settings);

        await container.read(settingsProvider.notifier).loadSettings();

        final state = container.read(settingsProvider);
        expect(state, isA<AsyncData<AppSettings>>());
        expect(state.valueOrNull?.themeMode, equals('dark'));
        expect(state.valueOrNull?.language, equals('zh'));
      });

      test('should load default settings when storage is empty', () async {
        final defaultSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => defaultSettings);

        await container.read(settingsProvider.notifier).loadSettings();

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.themeMode, equals('system'));
        expect(state.valueOrNull?.language, equals('en'));
        expect(state.valueOrNull?.editorFontSize, equals(14));
      });

      test('should handle error', () async {
        when(mockStorageService.getSettings())
            .thenThrow(Exception('Storage error'));

        await container.read(settingsProvider.notifier).loadSettings();

        final state = container.read(settingsProvider);
        expect(state, isA<AsyncError<AppSettings>>());
      });
    });

    group('updateSettings', () {
      test('should update settings and persist', () async {
        final newSettings = AppSettings.defaults().copyWith(themeMode: 'dark');

        when(mockStorageService.saveSettings(newSettings))
            .thenAnswer((_) async {});

        await container
            .read(settingsProvider.notifier)
            .updateSettings(newSettings);

        verify(mockStorageService.saveSettings(newSettings)).called(1);

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.themeMode, equals('dark'));
      });

      test('should handle save error', () async {
        final newSettings = AppSettings.defaults().copyWith(themeMode: 'dark');

        when(mockStorageService.saveSettings(newSettings))
            .thenThrow(Exception('Save error'));

        await container
            .read(settingsProvider.notifier)
            .updateSettings(newSettings);

        final state = container.read(settingsProvider);
        expect(state, isA<AsyncError<AppSettings>>());
      });
    });

    group('updateThemeMode', () {
      test('should update theme mode', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container.read(settingsProvider.notifier).updateThemeMode('dark');

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.themeMode, equals('dark'));
      });

      test('should not update when current state is in error', () async {
        when(mockStorageService.getSettings())
            .thenThrow(Exception('Load error'));

        // Constructor calls loadSettings, so state becomes AsyncError
        await Future.delayed(Duration.zero);
        
        // When in error state, state.value throws, so updateThemeMode will fail
        // This is expected behavior based on the current implementation
        expect(
          () => container.read(settingsProvider.notifier).updateThemeMode('dark'),
          throwsA(isA<Exception>()),
        );

        // Constructor calls getSettings once
        verify(mockStorageService.getSettings()).called(1);
        verifyNever(mockStorageService.saveSettings(any));
      });

      test('should persist theme mode change', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container.read(settingsProvider.notifier).updateThemeMode('light');

        final captured = verify(mockStorageService.saveSettings(captureAny))
            .captured
            .first as AppSettings;
        expect(captured.themeMode, equals('light'));
      });
    });

    group('updateLanguage', () {
      test('should update language', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container.read(settingsProvider.notifier).updateLanguage('zh');

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.language, equals('zh'));
      });

      test('should handle multiple language changes', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container.read(settingsProvider.notifier).updateLanguage('zh');
        await container.read(settingsProvider.notifier).updateLanguage('en');
        await container.read(settingsProvider.notifier).updateLanguage('ja');

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.language, equals('ja'));
        verify(mockStorageService.saveSettings(any)).called(3);
      });
    });

    group('updateEditorFontSize', () {
      test('should update editor font size', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container
            .read(settingsProvider.notifier)
            .updateEditorFontSize(18.0);

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.editorFontSize, equals(18.0));
      });

      test('should handle different font sizes', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container
            .read(settingsProvider.notifier)
            .updateEditorFontSize(12.0);
        await container
            .read(settingsProvider.notifier)
            .updateEditorFontSize(16.0);
        await container
            .read(settingsProvider.notifier)
            .updateEditorFontSize(20.0);

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.editorFontSize, equals(20.0));
      });
    });

    group('updateRequestTimeout', () {
      test('should update request timeout', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container
            .read(settingsProvider.notifier)
            .updateRequestTimeout(60000);

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.requestTimeoutMs, equals(60000));
      });

      test('should persist timeout change', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container
            .read(settingsProvider.notifier)
            .updateRequestTimeout(10000);

        final captured = verify(mockStorageService.saveSettings(captureAny))
            .captured
            .first as AppSettings;
        expect(captured.requestTimeoutMs, equals(10000));
      });
    });

    group('updateValidateCertificates', () {
      test('should update validate certificates', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container
            .read(settingsProvider.notifier)
            .updateValidateCertificates(false);

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.validateCertificates, isFalse);
      });

      test('should toggle validate certificates', () async {
        final initialSettings =
            AppSettings.defaults().copyWith(validateCertificates: true);

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container
            .read(settingsProvider.notifier)
            .updateValidateCertificates(false);
        await container
            .read(settingsProvider.notifier)
            .updateValidateCertificates(true);

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.validateCertificates, isTrue);
      });
    });

    group('updateFollowRedirects', () {
      test('should update follow redirects', () async {
        final initialSettings = AppSettings.defaults();

        when(mockStorageService.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

        await container.read(settingsProvider.notifier).loadSettings();
        await container
            .read(settingsProvider.notifier)
            .updateFollowRedirects(true);

        final state = container.read(settingsProvider);
        expect(state.valueOrNull?.followRedirects, isTrue);
      });
    });
  });

  group('themeModeProvider', () {
    test('should return system theme when loading', () {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenAnswer((_) async => AppSettings.defaults());

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      expect(container.read(themeModeProvider), equals(ThemeMode.system));
    });

    test('should return system theme on error', () async {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenThrow(Exception('Load error'));

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(settingsProvider.notifier).loadSettings();

      expect(container.read(themeModeProvider), equals(ThemeMode.system));
    });

    test('should return light theme', () async {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenAnswer((_) async => AppSettings.defaults().copyWith(themeMode: 'light'));

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(settingsProvider.notifier).loadSettings();

      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    test('should return dark theme', () async {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenAnswer((_) async => AppSettings.defaults().copyWith(themeMode: 'dark'));

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(settingsProvider.notifier).loadSettings();

      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });

    test('should return system theme for unknown value', () async {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenAnswer((_) async => AppSettings.defaults().copyWith(themeMode: 'unknown'));

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(settingsProvider.notifier).loadSettings();

      expect(container.read(themeModeProvider), equals(ThemeMode.system));
    });
  });

  group('localeProvider', () {
    test('should return English locale when loading', () {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenAnswer((_) async => AppSettings.defaults());

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      expect(container.read(localeProvider), equals(const Locale('en')));
    });

    test('should return English locale on error', () async {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenThrow(Exception('Load error'));

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(settingsProvider.notifier).loadSettings();

      expect(container.read(localeProvider), equals(const Locale('en')));
    });

    test('should return Chinese locale', () async {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenAnswer((_) async => AppSettings.defaults().copyWith(language: 'zh'));

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(settingsProvider.notifier).loadSettings();

      expect(container.read(localeProvider), equals(const Locale('zh', 'CN')));
    });

    test('should return English locale for unknown language', () async {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenAnswer((_) async => AppSettings.defaults().copyWith(language: 'unknown'));

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(settingsProvider.notifier).loadSettings();

      expect(container.read(localeProvider), equals(const Locale('en')));
    });

    test('should update when language changes', () async {
      final mockStorageService = MockStorageService();
      when(mockStorageService.getSettings())
          .thenAnswer((_) async => AppSettings.defaults());
      when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      await container.read(settingsProvider.notifier).loadSettings();
      expect(container.read(localeProvider), equals(const Locale('en')));

      await container.read(settingsProvider.notifier).updateLanguage('zh');
      expect(container.read(localeProvider), equals(const Locale('zh', 'CN')));
    });
  });
}
