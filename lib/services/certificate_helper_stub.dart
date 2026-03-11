import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/certificate_info.dart';

/// 从响应中提取证书信息（Web 平台 Stub 实现）
/// Web 平台无法直接访问底层证书信息
CertificateInfo? extractCertificateFromResponse(Response<Uint8List> response) {
  return null;
}
