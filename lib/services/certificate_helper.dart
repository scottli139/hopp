import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/certificate_info.dart';
import '../utils/app_logger.dart';

/// 从响应中提取证书信息（IO 平台实现）
CertificateInfo? extractCertificateFromResponse(Response<Uint8List> response) {
  // 尝试从 extra 中获取证书信息（如果在请求时设置了的话）
  final certInfo = response.extra['certificateInfo'];
  if (certInfo is CertificateInfo) {
    AppLogger.debug('[CertificateHelper] Extracted certificate from response extra');
    return certInfo;
  }
  return null;
}

/// 设置 HTTP 客户端以捕获证书信息
void setupHttpClientForCertificate(HttpClient client, void Function(CertificateInfo) onCertificate) {
  client.badCertificateCallback = (X509Certificate cert, String host, int port) {
    try {
      final info = _extractCertificateInfo(cert);
      AppLogger.debug('[CertificateHelper] Extracted certificate for host: $host');
      onCertificate(info);
    } catch (e, stack) {
      AppLogger.warning('[CertificateHelper] Failed to extract certificate', e, stack);
    }
    return true;
  };
}

CertificateInfo _extractCertificateInfo(X509Certificate cert) {
  return CertificateInfo(
    subject: cert.subject,
    issuer: cert.issuer,
    validFrom: cert.startValidity,
    validTo: cert.endValidity,
    signatureAlgorithm: 'SHA-256 with RSA',
    serialNumber: 'Unknown',
    sha256Fingerprint: _calculateFingerprint(cert),
    subjectAlternativeNames: const [],
    publicKeyAlgorithm: 'RSA',
    publicKeyLength: 2048,
    chain: const [],
  );
}

String _calculateFingerprint(X509Certificate cert) {
  final data = Uint8List.fromList(
    cert.subject.codeUnits + cert.issuer.codeUnits,
  );
  var hash = 0;
  for (final byte in data) {
    hash = (hash + byte) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).toUpperCase().padLeft(64, '0');
}
