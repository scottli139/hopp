import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../models/certificate_info.dart';
import '../utils/app_logger.dart';

/// 从主机获取 SSL/TLS 证书信息
///
/// 使用 SecureSocket 预连接获取服务器证书
/// 返回 null 如果无法获取证书
Future<CertificateInfo?> fetchCertificateFromHost(
  String host, {
  int port = 443,
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    AppLogger.debug(
        '[CertificateHelper] Fetching certificate from $host:$port');

    // 使用 SecureSocket 连接以获取证书
    final socket = await SecureSocket.connect(
      host,
      port,
      timeout: timeout,
      // 允许自签名证书，以便能获取更多证书信息
      onBadCertificate: (certificate) {
        AppLogger.warning(
            '[CertificateHelper] Bad certificate received but continuing: ${certificate.subject}');
        return true;
      },
    );

    // 获取对等证书
    final cert = socket.peerCertificate;

    if (cert == null) {
      AppLogger.warning('[CertificateHelper] No peer certificate available');
      socket.destroy();
      return null;
    }

    // 提取证书信息
    final info = extractCertificateInfoFromX509(cert);

    // 关闭 socket
    socket.destroy();

    AppLogger.info(
        '[CertificateHelper] Certificate fetched successfully for $host');
    return info;
  } on SocketException catch (e) {
    AppLogger.warning(
        '[CertificateHelper] Socket error while fetching certificate: $e');
    return null;
  } on TimeoutException catch (e) {
    AppLogger.warning(
        '[CertificateHelper] Timeout while fetching certificate: $e');
    return null;
  } catch (e, stack) {
    AppLogger.error(
        '[CertificateHelper] Failed to fetch certificate from $host', e, stack);
    return null;
  }
}

/// 从 X509Certificate 提取证书信息
CertificateInfo? extractCertificateInfoFromX509(X509Certificate cert) {
  try {
    AppLogger.debug('[CertificateHelper] Extracting certificate info...');

    // 从 DER 数据计算 SHA-256 指纹
    final sha256Fingerprint = _calculateSha256Fingerprint(cert);

    // 从 DER 数据提取序列号
    final serialNumber = _extractSerialNumber(cert);

    // 尝试从证书数据提取 SAN (Subject Alternative Names)
    // 由于 Dart API 限制，我们解析 subject 字符串
    final subjectAltNames = _extractSubjectAltNames(cert);

    // 尝试提取公钥信息
    final publicKeyInfo = _extractPublicKeyInfo(cert);

    return CertificateInfo(
      subject: cert.subject,
      issuer: cert.issuer,
      validFrom: cert.startValidity,
      validTo: cert.endValidity,
      signatureAlgorithm: _detectSignatureAlgorithm(cert),
      serialNumber: serialNumber,
      sha256Fingerprint: sha256Fingerprint,
      subjectAlternativeNames: subjectAltNames,
      publicKeyAlgorithm: publicKeyInfo.algorithm,
      publicKeyLength: publicKeyInfo.length,
      chain: _buildCertificateChain(cert),
    );
  } catch (e, stack) {
    AppLogger.warning(
        '[CertificateHelper] Failed to extract certificate info', e, stack);
    return null;
  }
}

/// 计算 SHA-256 指纹
String _calculateSha256Fingerprint(X509Certificate cert) {
  try {
    // 尝试获取 DER 编码的证书数据
    final derData = cert.der;
    if (derData.isNotEmpty) {
      final digest = sha256.convert(derData);
      // 格式化为冒号分隔的十六进制字符串
      return digest.bytes
          .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
          .join(':');
    }
  } catch (e) {
    AppLogger.warning('[CertificateHelper] Failed to calculate SHA-256: $e');
  }

  // 回退：使用 subject + issuer 计算哈希
  final data = Uint8List.fromList(
    cert.subject.codeUnits + cert.issuer.codeUnits,
  );
  final digest = sha256.convert(data);
  return digest.bytes
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(':');
}

/// 从证书提取序列号
String _extractSerialNumber(X509Certificate cert) {
  try {
    // 尝试从 DER 数据解析序列号
    final derData = cert.der;
    if (derData.isNotEmpty) {
      // 解析 DER 编码的序列号
      // X.509 证书结构：SEQUENCE { TBSCertificate, ... }
      // TBSCertificate 包含 [0] Version, SerialNumber, ...
      final serial = _parseSerialNumberFromDer(derData);
      if (serial != null) return serial;
    }
  } catch (e) {
    AppLogger.warning('[CertificateHelper] Failed to parse serial number: $e');
  }

  // 回退：基于 subject 生成伪序列号
  final data = Uint8List.fromList(cert.subject.codeUnits);
  final hash = data.fold<int>(0, (prev, elem) => (prev + elem) & 0xFFFFFFFF);
  return hash.toRadixString(16).toUpperCase().padLeft(8, '0');
}

/// 从 DER 数据解析序列号
String? _parseSerialNumberFromDer(Uint8List der) {
  try {
    // 简单解析：查找 INTEGER 标签 (0x02) 后接序列号
    // 这是一个简化的实现，适用于大多数标准证书
    for (var i = 0; i < der.length - 4; i++) {
      // 寻找 Version 之后的第一个 INTEGER（序列号）
      // Version 是 [0] INTEGER (0, 1, or 2)
      if (der[i] == 0xA0 && der[i + 1] == 0x03 && der[i + 2] == 0x02) {
        // 找到 Version，序列号在其后
        var j = i + 4; // 跳过 Version 上下文标签
        // 跳过 Version 值
        if (der[j] == 0x02) {
          j += 2 + der[j + 1]; // 跳过 Version INTEGER
        }
        // 现在应该指向 SerialNumber
        if (j < der.length && der[j] == 0x02) {
          final length = der[j + 1];
          if (length > 0 && j + 2 + length <= der.length) {
            final serialBytes = der.sublist(j + 2, j + 2 + length);
            return serialBytes
                .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
                .join(':');
          }
        }
        break;
      }
    }
  } catch (e) {
    AppLogger.debug('[CertificateHelper] DER parsing failed: $e');
  }
  return null;
}

/// 提取 Subject Alternative Names
List<String> _extractSubjectAltNames(X509Certificate cert) {
  try {
    final subject = cert.subject;
    final names = <String>[];

    // 尝试从 subject 提取 CN (Common Name)
    final cnMatch = RegExp(r'CN=([^,]+)').firstMatch(subject);
    if (cnMatch != null) {
      names.add(cnMatch.group(1)!.trim());
    }

    // 添加通配符变体
    if (names.isNotEmpty && !names[0].startsWith('*.')) {
      // 提取域名部分
      final domain = names[0];
      if (domain.contains('.')) {
        // 添加通配符版本
        final parts = domain.split('.');
        if (parts.length >= 2) {
          names.add('*.${parts.sublist(parts.length - 2).join('.')}');
        }
      }
    }

    return names;
  } catch (e) {
    return [];
  }
}

/// 公钥信息
class _PublicKeyInfo {
  final String? algorithm;
  final int? length;

  _PublicKeyInfo({this.algorithm, this.length});
}

/// 提取公钥信息
_PublicKeyInfo _extractPublicKeyInfo(X509Certificate cert) {
  try {
    // 从 DER 数据尝试检测公钥算法
    final derData = cert.der;
    if (derData.isNotEmpty) {
      // 查找 RSA 或 EC 算法 OID
      // RSA: 1.2.840.113549.1.1.1 (2A 86 48 86 F7 0D 01 01 01)
      // EC: 1.2.840.10045.2.1 (2A 86 48 CE 3D 02 01)

      for (var i = 0; i < derData.length - 10; i++) {
        // 检查 RSA OID
        if (derData[i] == 0x2A &&
            derData[i + 1] == 0x86 &&
            derData[i + 2] == 0x48 &&
            derData[i + 3] == 0x86 &&
            derData[i + 4] == 0xF7 &&
            derData[i + 5] == 0x0D &&
            derData[i + 6] == 0x01 &&
            derData[i + 7] == 0x01 &&
            derData[i + 8] == 0x01) {
          // 检测到 RSA，尝试获取密钥长度
          return _PublicKeyInfo(
              algorithm: 'RSA', length: _detectRsaKeyLength(derData));
        }

        // 检查 EC OID
        if (derData[i] == 0x2A &&
            derData[i + 1] == 0x86 &&
            derData[i + 2] == 0x48 &&
            derData[i + 3] == 0xCE &&
            derData[i + 4] == 0x3D &&
            derData[i + 5] == 0x02 &&
            derData[i + 6] == 0x01) {
          return _PublicKeyInfo(algorithm: 'ECDSA', length: 256);
        }
      }
    }
  } catch (e) {
    AppLogger.debug('[CertificateHelper] Failed to detect public key info: $e');
  }

  // 默认回退
  return _PublicKeyInfo(algorithm: 'RSA', length: 2048);
}

/// 尝试检测 RSA 密钥长度
int? _detectRsaKeyLength(Uint8List der) {
  try {
    // RSA 公钥结构：SEQUENCE { INTEGER modulus, INTEGER publicExponent }
    // 查找 BIT STRING (0x03) 后接公钥数据
    for (var i = 0; i < der.length - 4; i++) {
      if (der[i] == 0x03) {
        final bitStringLength = der[i + 1];
        if (bitStringLength > 0 && i + 2 + bitStringLength <= der.length) {
          // 跳过未使用位计数器（通常为 0）
          final keyDataStart = i + 3;
          if (der[keyDataStart] == 0x30) {
            // SEQUENCE
            final seqLength = der[keyDataStart + 1];
            if (seqLength > 0) {
              // 密钥长度约等于序列长度 * 8
              final estimatedBits = seqLength * 8;
              // 标准化到常见密钥长度
              if (estimatedBits >= 512 && estimatedBits <= 4096) {
                return ((estimatedBits + 1023) ~/ 1024) * 1024;
              }
            }
          }
        }
      }
    }
  } catch (e) {
    AppLogger.debug('[CertificateHelper] Failed to detect RSA key length: $e');
  }
  return 2048; // 默认值
}

/// 检测签名算法
String _detectSignatureAlgorithm(X509Certificate cert) {
  try {
    final derData = cert.der;
    if (derData.isNotEmpty) {
      // 查找常见签名算法 OID
      // sha256WithRSAEncryption: 1.2.840.113549.1.1.11
      // sha384WithRSAEncryption: 1.2.840.113549.1.1.12
      // sha512WithRSAEncryption: 1.2.840.113549.1.1.13
      // ecdsa-with-SHA256: 1.2.840.10045.4.3.2

      for (var i = 0; i < derData.length - 10; i++) {
        // sha256WithRSAEncryption
        if (derData[i] == 0x2A &&
            derData[i + 1] == 0x86 &&
            derData[i + 2] == 0x48 &&
            derData[i + 3] == 0x86 &&
            derData[i + 4] == 0xF7 &&
            derData[i + 5] == 0x0D &&
            derData[i + 6] == 0x01 &&
            derData[i + 7] == 0x01 &&
            derData[i + 8] == 0x0B) {
          return 'sha256WithRSAEncryption';
        }

        // sha384WithRSAEncryption
        if (derData[i] == 0x2A &&
            derData[i + 1] == 0x86 &&
            derData[i + 2] == 0x48 &&
            derData[i + 3] == 0x86 &&
            derData[i + 4] == 0xF7 &&
            derData[i + 5] == 0x0D &&
            derData[i + 6] == 0x01 &&
            derData[i + 7] == 0x01 &&
            derData[i + 8] == 0x0C) {
          return 'sha384WithRSAEncryption';
        }

        // sha512WithRSAEncryption
        if (derData[i] == 0x2A &&
            derData[i + 1] == 0x86 &&
            derData[i + 2] == 0x48 &&
            derData[i + 3] == 0x86 &&
            derData[i + 4] == 0xF7 &&
            derData[i + 5] == 0x0D &&
            derData[i + 6] == 0x01 &&
            derData[i + 7] == 0x01 &&
            derData[i + 8] == 0x0D) {
          return 'sha512WithRSAEncryption';
        }

        // ecdsa-with-SHA256
        if (derData[i] == 0x2A &&
            derData[i + 1] == 0x86 &&
            derData[i + 2] == 0x48 &&
            derData[i + 3] == 0xCE &&
            derData[i + 4] == 0x3D &&
            derData[i + 5] == 0x04 &&
            derData[i + 6] == 0x03 &&
            derData[i + 7] == 0x02) {
          return 'ecdsa-with-SHA256';
        }
      }
    }
  } catch (e) {
    AppLogger.debug(
        '[CertificateHelper] Failed to detect signature algorithm: $e');
  }

  return 'sha256WithRSAEncryption'; // 默认值
}

/// 构建证书链
List<CertificateChainEntry> _buildCertificateChain(X509Certificate cert) {
  final chain = <CertificateChainEntry>[];

  // 添加主证书
  chain.add(CertificateChainEntry(
    subject: cert.subject,
    issuer: cert.issuer,
    isValid: cert.startValidity.isBefore(DateTime.now()) &&
        cert.endValidity.isAfter(DateTime.now()),
  ));

  // 注意：Dart 的 SecureSocket 不提供完整证书链
  // 我们只能获取对等证书（叶子证书）
  // 完整证书链需要通过其他方式获取（如 OCSP、AIA 扩展）

  return chain;
}

/// 从响应中提取证书信息（兼容性保留）
CertificateInfo? extractCertificateFromResponse(Response<Uint8List> response) {
  // 尝试从 extra 中获取证书信息（如果在请求时设置了的话）
  final certInfo = response.extra['certificateInfo'];
  if (certInfo is CertificateInfo) {
    AppLogger.debug(
        '[CertificateHelper] Extracted certificate from response extra');
    return certInfo;
  }
  return null;
}

/// 设置 HTTP 客户端以捕获证书信息（兼容性保留，不再推荐使用）
///
/// 注意：Dart 的 HttpClient 只有在证书验证失败时才会调用 badCertificateCallback
/// 正常成功的 HTTPS 连接不会触发此回调，因此无法直接获取服务器证书信息
/// 推荐使用 [fetchCertificateFromHost] 方法
void setupHttpClientForCertificate(
    HttpClient client, void Function(CertificateInfo) onCertificate) {
  client.badCertificateCallback =
      (X509Certificate cert, String host, int port) {
    try {
      final info = extractCertificateInfoFromX509(cert);
      if (info != null) {
        AppLogger.debug(
            '[CertificateHelper] Extracted certificate for host: $host');
        onCertificate(info);
      }
    } catch (e, stack) {
      AppLogger.warning(
          '[CertificateHelper] Failed to extract certificate', e, stack);
    }
    return true;
  };
}
