import 'package:freezed_annotation/freezed_annotation.dart';

part 'certificate_info.freezed.dart';
part 'certificate_info.g.dart';

/// HTTPS 证书信息模型
@freezed
class CertificateInfo with _$CertificateInfo {
  const factory CertificateInfo({
    /// 证书主题 (Subject)
    required String subject,

    /// 证书颁发者 (Issuer)
    required String issuer,

    /// 生效时间
    required DateTime validFrom,

    /// 过期时间
    required DateTime validTo,

    /// 签名算法
    required String signatureAlgorithm,

    /// 序列号
    required String serialNumber,

    /// SHA-256 指纹
    required String sha256Fingerprint,

    /// 主题备用名称 (Subject Alternative Names)
    @Default([]) List<String> subjectAlternativeNames,

    /// 公钥算法
    String? publicKeyAlgorithm,

    /// 公钥长度 (位)
    int? publicKeyLength,

    /// 证书链
    @Default([]) List<CertificateChainEntry> chain,
  }) = _CertificateInfo;

  factory CertificateInfo.fromJson(Map<String, dynamic> json) =>
      _$CertificateInfoFromJson(json);

  const CertificateInfo._();

  /// 检查证书是否有效
  bool get isValid {
    final now = DateTime.now();
    return now.isAfter(validFrom) && now.isBefore(validTo);
  }

  /// 获取剩余有效天数
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(validTo)) return 0;
    return validTo.difference(now).inDays;
  }

  /// 获取有效期格式化字符串
  String get validityPeriod {
    return '${_formatDate(validFrom)} - ${_formatDate(validTo)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 证书链条目
@freezed
class CertificateChainEntry with _$CertificateChainEntry {
  const factory CertificateChainEntry({
    /// 主题
    required String subject,

    /// 颁发者
    required String issuer,

    /// 是否有效
    required bool isValid,
  }) = _CertificateChainEntry;

  factory CertificateChainEntry.fromJson(Map<String, dynamic> json) =>
      _$CertificateChainEntryFromJson(json);
}
