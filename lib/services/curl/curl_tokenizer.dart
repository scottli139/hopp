/// cURL 命令词法分析器
///
/// 将 cURL 命令字符串分解为 Token 列表，支持：
/// - 单引号和双引号字符串
/// - 反斜杠转义字符
/// - 多行命令（反斜杠续行）
library;

import '../../utils/app_logger.dart';

/// Token 类型
enum CurlTokenType {
  /// cURL 命令本身
  command,

  /// 短选项，如 -X, -H
  optionShort,

  /// 长选项，如 --header, --data
  optionLong,

  /// 选项值或参数值
  value,

  /// URL
  url,

  /// 文件结束
  eof,
}

/// Token 定义
class CurlToken {
  /// Token 类型
  final CurlTokenType type;

  /// Token 值
  final String value;

  /// 原始文本（保留引号等）
  final String rawValue;

  /// 在输入中的位置
  final int position;

  const CurlToken({
    required this.type,
    required this.value,
    required this.rawValue,
    required this.position,
  });

  @override
  String toString() => 'CurlToken(${type.name}, "$value", pos: $position)';
}

/// cURL 词法分析器
class CurlTokenizer with LogMixin {
  String _input = '';
  int _position = 0;

  /// 将 cURL 命令字符串分解为 Token 列表
  List<CurlToken> tokenize(String input) {
    logDebug(
        'Tokenizing cURL command: ${input.substring(0, input.length > 50 ? 50 : input.length)}...');

    // 预处理：处理多行命令（反斜杠续行）
    _input = _preprocess(input);
    _position = 0;

    final tokens = <CurlToken>[];

    while (!_isAtEnd()) {
      _skipWhitespace();

      if (_isAtEnd()) break;

      final token = _readToken();
      if (token != null) {
        tokens.add(token);
      }
    }

    tokens.add(CurlToken(
      type: CurlTokenType.eof,
      value: '',
      rawValue: '',
      position: _position,
    ));

    logDebug('Tokenized ${tokens.length} tokens');
    return tokens;
  }

  /// 预处理：移除反斜杠续行符
  String _preprocess(String input) {
    // 处理反斜杠续行：\[换行符] 转换为空格
    return input.replaceAll(RegExp(r'\\\s*\n\s*'), ' ');
  }

  /// 读取下一个 Token
  CurlToken? _readToken() {
    final startPos = _position;
    final char = _peek();

    // 选项（以 - 开头）
    if (char == '-') {
      return _readOption(startPos);
    }

    // 引号字符串
    if (char == '"' || char == "'") {
      return _readQuotedString(startPos);
    }

    // 普通值或 URL
    return _readValue(startPos);
  }

  /// 读取选项
  CurlToken _readOption(int startPos) {
    // 跳过开头的 -
    _advance();

    // 检查是否是长选项 --
    if (_peek() == '-') {
      _advance();
      final optionName = _readUntilWhitespace();
      return CurlToken(
        type: CurlTokenType.optionLong,
        value: optionName,
        rawValue: '--$optionName',
        position: startPos,
      );
    }

    // 短选项
    final optionName = _readUntilWhitespace();
    return CurlToken(
      type: CurlTokenType.optionShort,
      value: optionName,
      rawValue: '-$optionName',
      position: startPos,
    );
  }

  /// 读取引号字符串
  CurlToken _readQuotedString(int startPos) {
    final quote = _advance(); // " 或 '
    final buffer = StringBuffer();

    while (!_isAtEnd()) {
      final char = _peek();

      if (char == quote) {
        _advance(); // 消费结束引号
        break;
      }

      if (char == '\\') {
        _advance();
        if (!_isAtEnd()) {
          buffer.write(_advance());
        }
      } else {
        buffer.write(_advance());
      }
    }

    final value = buffer.toString();
    // 检查值是否是 URL
    final isUrl = _isUrl(value);

    return CurlToken(
      type: isUrl ? CurlTokenType.url : CurlTokenType.value,
      value: value,
      rawValue: '$quote$value$quote',
      position: startPos,
    );
  }

  /// 读取普通值
  CurlToken? _readValue(int startPos) {
    // 检查是否是 cURL 命令
    final remaining = _input.substring(_position);
    if (remaining.startsWith('curl') &&
        (remaining.length == 4 || _isWhitespace(remaining[4]))) {
      _advance(); // c
      _advance(); // u
      _advance(); // r
      _advance(); // l
      return CurlToken(
        type: CurlTokenType.command,
        value: 'curl',
        rawValue: 'curl',
        position: startPos,
      );
    }

    // 读取普通值
    final value = _readUntilWhitespace();
    if (value.isEmpty) {
      // 跳过空值，返回 null 让调用者处理
      return null;
    }

    // 判断是否是 URL（简单启发式）
    final isUrl = _isUrl(value);

    return CurlToken(
      type: isUrl ? CurlTokenType.url : CurlTokenType.value,
      value: value,
      rawValue: value,
      position: startPos,
    );
  }

  /// 读取直到空白字符
  String _readUntilWhitespace() {
    final buffer = StringBuffer();

    while (!_isAtEnd()) {
      final char = _peek();
      if (_isWhitespace(char) || char == '"' || char == "'") {
        break;
      }
      buffer.write(_advance());
    }

    return buffer.toString();
  }

  /// 跳过空白字符
  void _skipWhitespace() {
    while (!_isAtEnd() && _isWhitespace(_peek())) {
      _advance();
    }
  }

  /// 检查字符是否为空白字符
  bool _isWhitespace(String char) {
    return char == ' ' || char == '\t' || char == '\n' || char == '\r';
  }

  /// 检查是否为 URL（简单启发式）
  bool _isUrl(String value) {
    final urlPattern = RegExp(
      r'^(https?://|ftp://|http://|www\.)',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(value);
  }

  /// 查看当前字符
  String _peek() {
    if (_isAtEnd()) return '';
    return _input[_position];
  }

  /// 消费当前字符并返回
  String _advance() {
    if (_isAtEnd()) return '';
    return _input[_position++];
  }

  /// 检查是否到达输入末尾
  bool _isAtEnd() {
    return _position >= _input.length;
  }
}
