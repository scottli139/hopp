/// cURL 导入服务
///
/// 将解析后的 cURL 命令转换为 Hopp HttpRequest 模型。
library;

import 'dart:convert';

import '../../models/http_request.dart';
import '../../models/key_value_pair.dart';
import '../../utils/app_logger.dart';
import 'curl_import_result.dart';
import 'curl_parser.dart';

/// cURL 导入服务
class CurlImportService with LogMixin {
  final CurlParser _parser = CurlParser();

  /// 解析 cURL 命令并创建 HttpRequest
  CurlImportResult parse(String command) {
    logInfo('Importing from cURL command');

    try {
      // 解析命令
      final parsed = _parser.parse(command);

      // 构建 HttpRequest
      final request = _buildHttpRequest(parsed);

      logInfo('cURL import successful: ${request.name}');

      return CurlImportResult.success(
        request: request,
        warnings: parsed.warnings,
      );
    } on CurlParseException catch (e) {
      logError('cURL parse error', e);
      return CurlImportResult.error(e.message);
    } catch (e, stack) {
      logError('cURL import failed', e, stack);
      return CurlImportResult.error('Failed to parse cURL command: $e');
    }
  }

  /// 从解析后的命令构建 HttpRequest
  HttpRequest _buildHttpRequest(ParsedCurlCommand parsed) {
    // 构建 headers
    final headers = <KeyValuePair>[...parsed.headers];

    // 如果有基础认证，添加 Authorization header
    if (parsed.hasAuth) {
      final authValue = _buildBasicAuth(
        parsed.authUsername!,
        parsed.authPassword,
      );
      // 检查是否已存在 Authorization header
      final existingAuthIndex = headers.indexWhere(
        (h) => h.key.toLowerCase() == 'authorization',
      );
      if (existingAuthIndex == -1) {
        headers.add(
          KeyValuePair.empty().copyWith(
            key: 'Authorization',
            value: authValue,
            enabled: true,
          ),
        );
      }
    }

    // 确定 body type 和 content
    var bodyType = parsed.bodyType;
    var body = parsed.body;
    var rawContentType = parsed.rawContentType;

    // 处理 form data
    if (parsed.formDataFields.isNotEmpty) {
      bodyType = 'formData';
      // Form data 在 UI 中单独处理，body 存储原始数据
      body = parsed.formDataFields.map((f) => '${f.name}=${f.value}').join('&');
    }

    // 处理 URL 编码数据
    if (parsed.urlEncodedFields.isNotEmpty && bodyType == 'formUrlEncoded') {
      bodyType = 'formUrlEncoded';
      body = parsed.urlEncodedFields
          .map((f) => '${f.key}=${Uri.encodeQueryComponent(f.value)}')
          .join('&');
    }

    // 根据 Content-Type 推断 rawContentType
    final contentType = parsed.contentType;
    if (contentType != null) {
      if (contentType.contains('application/json')) {
        rawContentType = 'json';
      } else if (contentType.contains('application/xml') ||
          contentType.contains('text/xml')) {
        rawContentType = 'xml';
      } else if (contentType.contains('text/html')) {
        rawContentType = 'html';
      } else if (contentType.contains('application/javascript') ||
          contentType.contains('application/x-javascript')) {
        rawContentType = 'javascript';
      } else if (contentType.contains('text/plain')) {
        rawContentType = 'text';
      }
    }

    // 生成请求名称
    final name = _generateRequestName(parsed);

    return HttpRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      method: parsed.method,
      url: parsed.url,
      headers: headers,
      params: [], // cURL 命令中的参数通常在 URL 中，需要解析
      body: body,
      bodyType: bodyType,
      rawContentType: rawContentType,
      // 请求设置
      validateCertificates: !parsed.insecure,
      followRedirects: parsed.followRedirects,
      maxRedirects: 10,
    );
  }

  /// 构建基础认证字符串
  String _buildBasicAuth(String username, String? password) {
    final credentials = password != null ? '$username:$password' : username;
    final encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  /// 生成请求名称
  String _generateRequestName(ParsedCurlCommand parsed) {
    // 从 URL 路径生成名称
    if (parsed.url.isNotEmpty) {
      try {
        final uri = Uri.parse(parsed.url);
        final pathSegments =
            uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (pathSegments.isNotEmpty) {
          final lastSegment = pathSegments.last;
          // 转换为首字母大写格式
          final formatted = lastSegment
              .split('_')
              .map((s) =>
                  s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '')
              .join(' ');
          return '$formatted (${parsed.method.value.toUpperCase()})';
        }
      } catch (_) {
        // 解析失败，使用默认名称
      }
    }

    return 'Imported Request (${parsed.method.value.toUpperCase()})';
  }

  /// 验证 cURL 命令是否有效
  bool isValidCurlCommand(String command) {
    final trimmed = command.trim();
    return trimmed.startsWith('curl ') || trimmed == 'curl';
  }
}
