/// cURL 导入结果模型
///
/// 包含解析后的 HttpRequest 和相关信息。
library;

import '../../models/http_request.dart';

/// cURL 导入结果
class CurlImportResult {
  /// 是否成功
  final bool success;

  /// 解析后的请求
  final HttpRequest? request;

  /// 错误信息
  final String? errorMessage;

  /// 解析警告
  final List<String> warnings;

  const CurlImportResult({
    required this.success,
    this.request,
    this.errorMessage,
    this.warnings = const [],
  });

  /// 成功结果工厂方法
  factory CurlImportResult.success({
    required HttpRequest request,
    List<String> warnings = const [],
  }) {
    return CurlImportResult(
      success: true,
      request: request,
      warnings: warnings,
    );
  }

  /// 失败结果工厂方法
  factory CurlImportResult.error(String message) {
    return CurlImportResult(
      success: false,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'CurlImportResult(success, request: ${request?.name}, warnings: ${warnings.length})';
    } else {
      return 'CurlImportResult(error: $errorMessage)';
    }
  }
}
