import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    group('creation', () {
      test('should create AppSettings with all fields', () {
        const settings = AppSettings(
          themeMode: 'dark',
          language: 'zh',
          editorFontSize: 16,
          editorFontFamily: 'Fira Code',
          validateCertificates: false,
          requestTimeoutMs: 60000,
          followRedirects: true,
          maxRedirects: 10,
        );

        expect(settings.themeMode, equals('dark'));
        expect(settings.language, equals('zh'));
        expect(settings.editorFontSize, equals(16));
        expect(settings.editorFontFamily, equals('Fira Code'));
        expect(settings.validateCertificates, isFalse);
        expect(settings.requestTimeoutMs, equals(60000));
        expect(settings.followRedirects, isTrue);
        expect(settings.maxRedirects, equals(10));
      });

      test('should create AppSettings with default values', () {
        const settings = AppSettings();

        expect(settings.themeMode, equals('system'));
        expect(settings.language, equals('en'));
        expect(settings.editorFontSize, equals(14));
        expect(settings.editorFontFamily, equals('monospace'));
        expect(settings.validateCertificates, isTrue);
        expect(settings.requestTimeoutMs, equals(30000));
        expect(settings.followRedirects, isFalse);
        expect(settings.maxRedirects, equals(5));
      });

      test('should create AppSettings with partial custom values', () {
        const settings = AppSettings(
          themeMode: 'light',
          language: 'en',
        );

        expect(settings.themeMode, equals('light'));
        expect(settings.language, equals('en'));
        expect(settings.editorFontSize, equals(14)); // default
        expect(settings.validateCertificates, isTrue); // default
      });
    });

    group('defaults factory', () {
      test('should create default AppSettings', () {
        final settings = AppSettings.defaults();

        expect(settings.themeMode, equals('system'));
        expect(settings.language, equals('en'));
        expect(settings.editorFontSize, equals(14));
        expect(settings.editorFontFamily, equals('monospace'));
        expect(settings.validateCertificates, isTrue);
        expect(settings.requestTimeoutMs, equals(30000));
        expect(settings.followRedirects, isFalse);
        expect(settings.maxRedirects, equals(5));
      });

      test('defaults factory should be equivalent to const constructor', () {
        const constSettings = AppSettings();
        final defaultsSettings = AppSettings.defaults();

        expect(constSettings, equals(defaultsSettings));
      });
    });

    group('copyWith', () {
      test('should copy with new themeMode', () {
        const settings = AppSettings(themeMode: 'system');

        final copied = settings.copyWith(themeMode: 'dark');

        expect(copied.themeMode, equals('dark'));
        expect(copied.language, equals('en')); // unchanged
      });

      test('should copy with new language', () {
        const settings = AppSettings(language: 'en');

        final copied = settings.copyWith(language: 'zh');

        expect(copied.language, equals('zh'));
      });

      test('should copy with new editorFontSize', () {
        const settings = AppSettings(editorFontSize: 14);

        final copied = settings.copyWith(editorFontSize: 18);

        expect(copied.editorFontSize, equals(18));
      });

      test('should copy with new editorFontFamily', () {
        const settings = AppSettings(editorFontFamily: 'monospace');

        final copied = settings.copyWith(editorFontFamily: 'JetBrains Mono');

        expect(copied.editorFontFamily, equals('JetBrains Mono'));
      });

      test('should copy with new validateCertificates', () {
        const settings = AppSettings(validateCertificates: true);

        final copied = settings.copyWith(validateCertificates: false);

        expect(copied.validateCertificates, isFalse);
      });

      test('should copy with new requestTimeoutMs', () {
        const settings = AppSettings(requestTimeoutMs: 30000);

        final copied = settings.copyWith(requestTimeoutMs: 60000);

        expect(copied.requestTimeoutMs, equals(60000));
      });

      test('should copy with new followRedirects', () {
        const settings = AppSettings(followRedirects: false);

        final copied = settings.copyWith(followRedirects: true);

        expect(copied.followRedirects, isTrue);
      });

      test('should copy with new maxRedirects', () {
        const settings = AppSettings(maxRedirects: 5);

        final copied = settings.copyWith(maxRedirects: 10);

        expect(copied.maxRedirects, equals(10));
      });

      test('should copy without changes when no arguments provided', () {
        const settings = AppSettings(
          themeMode: 'dark',
          language: 'zh',
          editorFontSize: 16,
        );

        final copied = settings.copyWith();

        expect(copied, equals(settings));
      });

      test('should allow chaining copyWith calls', () {
        const settings = AppSettings();

        final copied = settings
            .copyWith(themeMode: 'dark')
            .copyWith(language: 'zh')
            .copyWith(editorFontSize: 16);

        expect(copied.themeMode, equals('dark'));
        expect(copied.language, equals('zh'));
        expect(copied.editorFontSize, equals(16));
        expect(copied.validateCertificates, isTrue); // unchanged
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        const settings = AppSettings(
          themeMode: 'dark',
          language: 'zh',
          editorFontSize: 16,
          editorFontFamily: 'Fira Code',
          validateCertificates: false,
          requestTimeoutMs: 60000,
          followRedirects: true,
          maxRedirects: 10,
        );

        final json = settings.toJson();

        expect(json['themeMode'], equals('dark'));
        expect(json['language'], equals('zh'));
        expect(json['editorFontSize'], equals(16));
        expect(json['editorFontFamily'], equals('Fira Code'));
        expect(json['validateCertificates'], equals(false));
        expect(json['requestTimeoutMs'], equals(60000));
        expect(json['followRedirects'], equals(true));
        expect(json['maxRedirects'], equals(10));
      });

      test('should serialize default values to JSON', () {
        final json = AppSettings.defaults().toJson();

        expect(json['themeMode'], equals('system'));
        expect(json['language'], equals('en'));
        expect(json['editorFontSize'], equals(14));
        expect(json['validateCertificates'], equals(true));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'themeMode': 'light',
          'language': 'ja',
          'editorFontSize': 18,
          'editorFontFamily': 'Source Code Pro',
          'validateCertificates': false,
          'requestTimeoutMs': 45000,
          'followRedirects': true,
          'maxRedirects': 3,
        };

        final settings = AppSettings.fromJson(json);

        expect(settings.themeMode, equals('light'));
        expect(settings.language, equals('ja'));
        expect(settings.editorFontSize, equals(18));
        expect(settings.editorFontFamily, equals('Source Code Pro'));
        expect(settings.validateCertificates, isFalse);
        expect(settings.requestTimeoutMs, equals(45000));
        expect(settings.followRedirects, isTrue);
        expect(settings.maxRedirects, equals(3));
      });

      test('should handle JSON with partial fields', () {
        final json = {
          'themeMode': 'dark',
          'language': 'en',
        };

        final settings = AppSettings.fromJson(json);

        expect(settings.themeMode, equals('dark'));
        expect(settings.language, equals('en'));
        // Other fields should use defaults from Freezed
        expect(settings.editorFontSize, equals(14));
        expect(settings.validateCertificates, isTrue);
      });
    });

    group('equality', () {
      test('identical settings should be equal', () {
        const settings1 = AppSettings(
          themeMode: 'dark',
          language: 'zh',
          editorFontSize: 16,
        );
        const settings2 = AppSettings(
          themeMode: 'dark',
          language: 'zh',
          editorFontSize: 16,
        );

        expect(settings1, equals(settings2));
      });

      test('settings with different theme modes should not be equal', () {
        const settings1 = AppSettings(themeMode: 'light');
        const settings2 = AppSettings(themeMode: 'dark');

        expect(settings1, isNot(equals(settings2)));
      });

      test('settings with different languages should not be equal', () {
        const settings1 = AppSettings(language: 'en');
        const settings2 = AppSettings(language: 'zh');

        expect(settings1, isNot(equals(settings2)));
      });

      test('settings with different font sizes should not be equal', () {
        const settings1 = AppSettings(editorFontSize: 12);
        const settings2 = AppSettings(editorFontSize: 14);

        expect(settings1, isNot(equals(settings2)));
      });

      test('settings with different certificate validation should not be equal',
          () {
        const settings1 = AppSettings(validateCertificates: true);
        const settings2 = AppSettings(validateCertificates: false);

        expect(settings1, isNot(equals(settings2)));
      });
    });

    group('edge cases', () {
      test('should handle zero font size', () {
        const settings = AppSettings(editorFontSize: 0);

        expect(settings.editorFontSize, equals(0));
      });

      test('should handle very large font size', () {
        const settings = AppSettings(editorFontSize: 100);

        expect(settings.editorFontSize, equals(100));
      });

      test('should handle zero timeout', () {
        const settings = AppSettings(requestTimeoutMs: 0);

        expect(settings.requestTimeoutMs, equals(0));
      });

      test('should handle very long timeout', () {
        const settings = AppSettings(requestTimeoutMs: 300000);

        expect(settings.requestTimeoutMs, equals(300000));
      });

      test('should handle zero max redirects', () {
        const settings = AppSettings(maxRedirects: 0);

        expect(settings.maxRedirects, equals(0));
      });

      test('should handle empty font family', () {
        const settings = AppSettings(editorFontFamily: '');

        expect(settings.editorFontFamily, equals(''));
      });

      test('should handle custom theme modes', () {
        const settings = AppSettings(themeMode: 'custom');

        expect(settings.themeMode, equals('custom'));
      });

      test('should handle custom language codes', () {
        const settings = AppSettings(language: 'fr');

        expect(settings.language, equals('fr'));
      });
    });

    group('typical use cases', () {
      test('should support dark mode configuration', () {
        final darkModeSettings = AppSettings.defaults().copyWith(
          themeMode: 'dark',
          editorFontSize: 16,
        );

        expect(darkModeSettings.themeMode, equals('dark'));
        expect(darkModeSettings.editorFontSize, equals(16));
      });

      test('should support high-contrast configuration', () {
        final accessibleSettings = AppSettings.defaults().copyWith(
          themeMode: 'light',
          editorFontSize: 18,
          editorFontFamily: 'Arial',
        );

        expect(accessibleSettings.editorFontSize, equals(18));
        expect(accessibleSettings.editorFontFamily, equals('Arial'));
      });

      test('should support development configuration', () {
        final devSettings = AppSettings.defaults().copyWith(
          validateCertificates: false,
          requestTimeoutMs: 10000,
          followRedirects: true,
        );

        expect(devSettings.validateCertificates, isFalse);
        expect(devSettings.requestTimeoutMs, equals(10000));
        expect(devSettings.followRedirects, isTrue);
      });
    });

    group('uiScale (F5.7)', () {
      test('should default to 1.0', () {
        expect(const AppSettings().uiScale, equals(1.0));
        expect(AppSettings.defaults().uiScale, equals(1.0));
      });

      test('should copyWith uiScale', () {
        const settings = AppSettings();

        final copied = settings.copyWith(uiScale: 1.5);

        expect(copied.uiScale, equals(1.5));
      });

      test('should roundtrip uiScale through JSON', () {
        const settings = AppSettings(uiScale: 1.25);

        final restored = AppSettings.fromJson(settings.toJson());

        expect(restored.uiScale, equals(1.25));
      });

      test('should default to 1.0 for legacy JSON without uiScale', () {
        final settings = AppSettings.fromJson({'themeMode': 'dark'});

        expect(settings.uiScale, equals(1.0));
      });
    });
  });
}
