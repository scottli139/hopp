import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/certificate_info.dart';

void main() {
  group('CertificateInfo', () {
    group('creation', () {
      test('should create CertificateInfo with all required fields', () {
        final now = DateTime.now();
        final cert = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now,
          validTo: now.add(const Duration(days: 365)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '1234567890',
          sha256Fingerprint: 'AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90',
        );

        expect(cert.subject, equals('CN=example.com'));
        expect(cert.issuer, equals('CN=Test CA'));
        expect(cert.validFrom, equals(now));
        expect(cert.validTo, equals(now.add(const Duration(days: 365))));
        expect(cert.signatureAlgorithm, equals('SHA-256 with RSA'));
        expect(cert.serialNumber, equals('1234567890'));
        expect(cert.sha256Fingerprint,
            equals('AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90'));
        expect(cert.subjectAlternativeNames, isEmpty);
        expect(cert.chain, isEmpty);
      });

      test('should create CertificateInfo with all fields', () {
        final now = DateTime.now();
        final cert = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now,
          validTo: now.add(const Duration(days: 365)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '1234567890',
          sha256Fingerprint: 'ABCDEF1234567890',
          subjectAlternativeNames: ['example.com', '*.example.com'],
          publicKeyAlgorithm: 'RSA',
          publicKeyLength: 2048,
          chain: [
            const CertificateChainEntry(
              subject: 'CN=Test CA',
              issuer: 'CN=Root CA',
              isValid: true,
            ),
          ],
        );

        expect(cert.subjectAlternativeNames,
            equals(['example.com', '*.example.com']));
        expect(cert.publicKeyAlgorithm, equals('RSA'));
        expect(cert.publicKeyLength, equals(2048));
        expect(cert.chain.length, equals(1));
      });
    });

    group('isValid getter', () {
      test('should return true for valid certificate', () {
        final now = DateTime.now();
        final cert = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now.subtract(const Duration(days: 1)),
          validTo: now.add(const Duration(days: 365)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '123',
          sha256Fingerprint: 'ABC',
        );

        expect(cert.isValid, isTrue);
      });

      test('should return false for expired certificate', () {
        final now = DateTime.now();
        final cert = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now.subtract(const Duration(days: 365)),
          validTo: now.subtract(const Duration(days: 1)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '123',
          sha256Fingerprint: 'ABC',
        );

        expect(cert.isValid, isFalse);
      });

      test('should return false for not yet valid certificate', () {
        final now = DateTime.now();
        final cert = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now.add(const Duration(days: 1)),
          validTo: now.add(const Duration(days: 365)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '123',
          sha256Fingerprint: 'ABC',
        );

        expect(cert.isValid, isFalse);
      });
    });

    group('remainingDays getter', () {
      test('should return correct remaining days for valid certificate', () {
        final now = DateTime.now();
        final cert = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now.subtract(const Duration(days: 1)),
          validTo: now.add(const Duration(days: 30)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '123',
          sha256Fingerprint: 'ABC',
        );

        // remainingDays may vary slightly due to time precision, check range
        expect(cert.remainingDays, greaterThanOrEqualTo(29));
        expect(cert.remainingDays, lessThanOrEqualTo(30));
      });

      test('should return 0 for expired certificate', () {
        final now = DateTime.now();
        final cert = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now.subtract(const Duration(days: 365)),
          validTo: now.subtract(const Duration(days: 1)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '123',
          sha256Fingerprint: 'ABC',
        );

        expect(cert.remainingDays, equals(0));
      });
    });

    group('validityPeriod getter', () {
      test('should return formatted validity period', () {
        final validFrom = DateTime(2024, 1, 1);
        final validTo = DateTime(2025, 1, 1);
        final cert = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: validFrom,
          validTo: validTo,
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '123',
          sha256Fingerprint: 'ABC',
        );

        expect(cert.validityPeriod, equals('2024-01-01 - 2025-01-01'));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final now = DateTime.now();
        final cert = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now,
          validTo: now.add(const Duration(days: 365)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '1234567890',
          sha256Fingerprint: 'ABCDEF',
          subjectAlternativeNames: ['example.com'],
          publicKeyAlgorithm: 'RSA',
          publicKeyLength: 2048,
        );

        final json = cert.toJson();

        expect(json['subject'], equals('CN=example.com'));
        expect(json['issuer'], equals('CN=Test CA'));
        expect(json['signatureAlgorithm'], equals('SHA-256 with RSA'));
        expect(json['serialNumber'], equals('1234567890'));
        expect(json['sha256Fingerprint'], equals('ABCDEF'));
        expect(json['subjectAlternativeNames'], equals(['example.com']));
        expect(json['publicKeyAlgorithm'], equals('RSA'));
        expect(json['publicKeyLength'], equals(2048));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'subject': 'CN=example.com',
          'issuer': 'CN=Test CA',
          'validFrom': '2024-01-01T00:00:00.000',
          'validTo': '2025-01-01T00:00:00.000',
          'signatureAlgorithm': 'SHA-256 with RSA',
          'serialNumber': '1234567890',
          'sha256Fingerprint': 'ABCDEF',
          'subjectAlternativeNames': ['example.com', '*.example.com'],
          'publicKeyAlgorithm': 'RSA',
          'publicKeyLength': 2048,
          'chain': [],
        };

        final cert = CertificateInfo.fromJson(json);

        expect(cert.subject, equals('CN=example.com'));
        expect(cert.issuer, equals('CN=Test CA'));
        expect(cert.signatureAlgorithm, equals('SHA-256 with RSA'));
        expect(cert.subjectAlternativeNames,
            equals(['example.com', '*.example.com']));
      });
    });

    group('equality', () {
      test('identical certificates should be equal', () {
        final now = DateTime.now();
        final cert1 = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now,
          validTo: now.add(const Duration(days: 365)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '123',
          sha256Fingerprint: 'ABC',
        );

        expect(cert1, equals(cert1));
      });

      test('certificates with different subjects should not be equal', () {
        final now = DateTime.now();
        final cert1 = CertificateInfo(
          subject: 'CN=example.com',
          issuer: 'CN=Test CA',
          validFrom: now,
          validTo: now.add(const Duration(days: 365)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '123',
          sha256Fingerprint: 'ABC',
        );

        final cert2 = CertificateInfo(
          subject: 'CN=other.com',
          issuer: 'CN=Test CA',
          validFrom: now,
          validTo: now.add(const Duration(days: 365)),
          signatureAlgorithm: 'SHA-256 with RSA',
          serialNumber: '123',
          sha256Fingerprint: 'ABC',
        );

        expect(cert1, isNot(equals(cert2)));
      });
    });
  });

  group('CertificateChainEntry', () {
    test('should create CertificateChainEntry with required fields', () {
      const entry = CertificateChainEntry(
        subject: 'CN=Intermediate CA',
        issuer: 'CN=Root CA',
        isValid: true,
      );

      expect(entry.subject, equals('CN=Intermediate CA'));
      expect(entry.issuer, equals('CN=Root CA'));
      expect(entry.isValid, isTrue);
    });

    test('should serialize to JSON correctly', () {
      const entry = CertificateChainEntry(
        subject: 'CN=Intermediate CA',
        issuer: 'CN=Root CA',
        isValid: true,
      );

      final json = entry.toJson();

      expect(json['subject'], equals('CN=Intermediate CA'));
      expect(json['issuer'], equals('CN=Root CA'));
      expect(json['isValid'], isTrue);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'subject': 'CN=Intermediate CA',
        'issuer': 'CN=Root CA',
        'isValid': false,
      };

      final entry = CertificateChainEntry.fromJson(json);

      expect(entry.subject, equals('CN=Intermediate CA'));
      expect(entry.issuer, equals('CN=Root CA'));
      expect(entry.isValid, isFalse);
    });
  });
}
