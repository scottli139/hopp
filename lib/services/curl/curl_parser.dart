/// cURL 命令解析器
///
/// 将 Token 列表解析为结构化的 cURL 命令数据。
library;

import '../../models/http_method.dart';
import '../../models/key_value_pair.dart';
import '../../utils/app_logger.dart';
import 'curl_tokenizer.dart';

/// 解析后的 cURL 命令
class ParsedCurlCommand {
  /// HTTP 方法
  final HttpMethod method;

  /// URL
  final String url;

  /// Headers 列表
  final List<KeyValuePair> headers;

  /// Body 内容
  final String body;

  /// Body 类型 (none, raw, formData, formUrlEncoded)
  final String bodyType;

  /// Raw Content Type (用于 raw body)
  final String rawContentType;

  /// Form Data 字段（用于 formData body）
  final List<FormDataField> formDataFields;

  /// URL 编码数据字段（用于 formUrlEncoded body）
  final List<KeyValuePair> urlEncodedFields;

  /// 是否禁用 SSL 验证
  final bool insecure;

  /// 是否跟随重定向
  final bool followRedirects;

  /// 基础认证用户名
  final String? authUsername;

  /// 基础认证密码
  final String? authPassword;

  /// 解析警告信息
  final List<String> warnings;

  const ParsedCurlCommand({
    this.method = HttpMethod.get,
    this.url = '',
    this.headers = const [],
    this.body = '',
    this.bodyType = 'none',
    this.rawContentType = 'text',
    this.formDataFields = const [],
    this.urlEncodedFields = const [],
    this.insecure = false,
    this.followRedirects = false,
    this.authUsername,
    this.authPassword,
    this.warnings = const [],
  });

  /// 是否有认证信息
  bool get hasAuth => authUsername != null;

  /// 获取 Content-Type header 值
  String? get contentType {
    for (final header in headers) {
      if (header.key.toLowerCase() == 'content-type') {
        return header.value;
      }
    }
    return null;
  }
}

/// Form Data 字段
class FormDataField {
  final String name;
  final String value;
  final bool isFile;
  final String? filePath;

  const FormDataField({
    required this.name,
    required this.value,
    this.isFile = false,
    this.filePath,
  });
}

/// cURL 解析器
class CurlParser with LogMixin {
  final CurlTokenizer _tokenizer = CurlTokenizer();

  /// 解析 cURL 命令字符串
  ParsedCurlCommand parse(String command) {
    logInfo('Parsing cURL command');

    final tokens = _tokenizer.tokenize(command);
    return _parseTokens(tokens);
  }

  /// 解析 Token 列表
  ParsedCurlCommand _parseTokens(List<CurlToken> tokens) {
    final warnings = <String>[];

    // 验证命令以 curl 开头
    if (tokens.isEmpty || tokens.first.type != CurlTokenType.command) {
      throw const CurlParseException(
          'Invalid cURL command: must start with "curl"');
    }

    var method = HttpMethod.get;
    String? url;
    final headers = <KeyValuePair>[];
    final bodyBuffer = StringBuffer();
    var bodyType = 'none';
    var rawContentType = 'text';
    final formDataFields = <FormDataField>[];
    final urlEncodedFields = <KeyValuePair>[];
    var insecure = false;
    var followRedirects = false;
    String? authUsername;
    String? authPassword;

    // 解析选项和值
    for (var i = 1; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.type == CurlTokenType.eof) {
        break;
      }

      if (token.type == CurlTokenType.url) {
        url = token.value;
        continue;
      }

      if (token.type == CurlTokenType.optionShort ||
          token.type == CurlTokenType.optionLong) {
        final option = token.value;
        final nextToken = i + 1 < tokens.length ? tokens[i + 1] : null;
        final nextValue =
            nextToken?.type == CurlTokenType.value ? nextToken!.value : null;

        switch (option) {
          // HTTP 方法
          case 'X':
          case 'request':
            if (nextValue != null) {
              method = _parseMethod(nextValue);
              i++;
            }
            break;

          // Headers
          case 'H':
          case 'header':
            if (nextValue != null) {
              final header = _parseHeader(nextValue);
              if (header != null) {
                headers.add(header);
              }
              i++;
            }
            break;

          // Data (raw body)
          case 'd':
          case 'data':
          case 'data-raw':
            if (nextValue != null) {
              if (bodyBuffer.isNotEmpty) {
                bodyBuffer.write('&');
              }
              bodyBuffer.write(nextValue);
              bodyType = 'raw';
              _inferContentType(nextValue, headers, (type) {
                rawContentType = type;
              });
              i++;
            }
            break;

          // Data binary (same as data for our purposes)
          case 'data-binary':
            if (nextValue != null) {
              if (bodyBuffer.isNotEmpty) {
                bodyBuffer.write('&');
              }
              bodyBuffer.write(nextValue);
              bodyType = 'raw';
              i++;
            }
            break;

          // URL encoded data
          case 'data-urlencode':
            if (nextValue != null) {
              final encoded = Uri.encodeQueryComponent(nextValue);
              if (bodyBuffer.isNotEmpty) {
                bodyBuffer.write('&');
              }
              bodyBuffer.write(encoded);
              bodyType = 'formUrlEncoded';
              urlEncodedFields.add(_parseUrlEncodedField(nextValue));
              i++;
            }
            break;

          // Form data
          case 'F':
          case 'form':
            if (nextValue != null) {
              final field = _parseFormField(nextValue);
              formDataFields.add(field);
              bodyType = 'formData';
              i++;
            }
            break;

          // User authentication
          case 'u':
          case 'user':
            if (nextValue != null) {
              final auth = _parseAuth(nextValue);
              authUsername = auth.username;
              authPassword = auth.password;
              i++;
            }
            break;

          // Insecure (disable SSL verification)
          case 'k':
          case 'insecure':
            insecure = true;
            break;

          // Follow redirects
          case 'L':
          case 'location':
            followRedirects = true;
            break;

          // URL (explicit)
          case 'url':
            if (nextValue != null) {
              url = nextValue;
              i++;
            }
            break;

          default:
            warnings.add('Unsupported option: -$option');
            logWarning('Unsupported cURL option: $option');
        }
      }
    }

    // 如果没有找到 URL，尝试从 body 或 headers 中推断（某些特殊情况）
    url ??= '';

    // 检查是否有 form data，有则覆盖 body type
    if (formDataFields.isNotEmpty) {
      bodyType = 'formData';
    }

    // 构建 body 字符串
    final body = bodyBuffer.toString();

    logInfo(
        'Parsed cURL command: method=${method.value}, url=$url, bodyType=$bodyType');

    return ParsedCurlCommand(
      method: method,
      url: url,
      headers: headers,
      body: body,
      bodyType: bodyType,
      rawContentType: rawContentType,
      formDataFields: formDataFields,
      urlEncodedFields: urlEncodedFields,
      insecure: insecure,
      followRedirects: followRedirects,
      authUsername: authUsername,
      authPassword: authPassword,
      warnings: warnings,
    );
  }

  /// 解析 HTTP 方法
  HttpMethod _parseMethod(String value) {
    final upper = value.toUpperCase();
    switch (upper) {
      case 'GET':
        return HttpMethod.get;
      case 'POST':
        return HttpMethod.post;
      case 'PUT':
        return HttpMethod.put;
      case 'DELETE':
        return HttpMethod.delete;
      case 'PATCH':
        return HttpMethod.patch;
      case 'HEAD':
        return HttpMethod.head;
      case 'OPTIONS':
        return HttpMethod.options;
      default:
        logWarning('Unknown HTTP method: $value, defaulting to GET');
        return HttpMethod.get;
    }
  }

  /// 解析 Header 字符串
  KeyValuePair? _parseHeader(String value) {
    final colonIndex = value.indexOf(':');
    if (colonIndex == -1) {
      logWarning('Invalid header format: $value');
      return null;
    }

    final key = value.substring(0, colonIndex).trim();
    final headerValue = value.substring(colonIndex + 1).trim();

    return KeyValuePair.empty().copyWith(
      key: key,
      value: headerValue,
      enabled: true,
    );
  }

  /// 解析 Form Data 字段
  FormDataField _parseFormField(String value) {
    // 检查是否是文件上传: key=@filepath 或 key=@filepath;type=mime
    final fileMatch = RegExp(r'^([^=]+)=@(.+)$').firstMatch(value);
    if (fileMatch != null) {
      final name = fileMatch.group(1)!;
      final filePath = fileMatch.group(2)!;
      return FormDataField(
        name: name,
        value: filePath,
        isFile: true,
        filePath: filePath,
      );
    }

    // 普通字段: key=value
    final equalsIndex = value.indexOf('=');
    if (equalsIndex == -1) {
      return FormDataField(name: value, value: '');
    }

    final name = value.substring(0, equalsIndex);
    final fieldValue = value.substring(equalsIndex + 1);
    return FormDataField(name: name, value: fieldValue);
  }

  /// 解析 URL 编码字段
  KeyValuePair _parseUrlEncodedField(String value) {
    final equalsIndex = value.indexOf('=');
    if (equalsIndex == -1) {
      return KeyValuePair.empty().copyWith(key: value, value: '');
    }

    final key = value.substring(0, equalsIndex);
    final fieldValue = value.substring(equalsIndex + 1);
    return KeyValuePair.empty().copyWith(key: key, value: fieldValue);
  }

  /// 解析认证字符串
  _AuthInfo _parseAuth(String value) {
    final colonIndex = value.indexOf(':');
    if (colonIndex == -1) {
      return _AuthInfo(username: value, password: null);
    }

    return _AuthInfo(
      username: value.substring(0, colonIndex),
      password: value.substring(colonIndex + 1),
    );
  }

  /// 从 body 内容推断 Content-Type
  void _inferContentType(
    String body,
    List<KeyValuePair> headers,
    void Function(String) setRawContentType,
  ) {
    // 如果已有 Content-Type header，使用它
    for (final header in headers) {
      if (header.key.toLowerCase() == 'content-type') {
        final value = header.value.toLowerCase();
        if (value.contains('json')) {
          setRawContentType('json');
        } else if (value.contains('xml')) {
          setRawContentType('xml');
        } else if (value.contains('html')) {
          setRawContentType('html');
        } else if (value.contains('javascript')) {
          setRawContentType('javascript');
        }
        return;
      }
    }

    // 尝试从 body 内容推断
    final trimmed = body.trim();
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      setRawContentType('json');
    } else if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
      setRawContentType('xml');
    }
  }
}

/// 认证信息
class _AuthInfo {
  final String username;
  final String? password;

  const _AuthInfo({required this.username, this.password});
}

/// cURL 解析异常
class CurlParseException implements Exception {
  final String message;

  const CurlParseException(this.message);

  @override
  String toString() => 'CurlParseException: $message';
}
