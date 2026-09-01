/// 响应 JSON 时间戳人性化注解（F8.5 / M8.6）
///
/// 检测 JSON 数值 token 中的 epoch 秒（10 位）/ 毫秒（13 位），命中后
/// 渲染层追加灰色注释 `→ yyyy-MM-dd HH:mm:ss`（本地时区）。
/// 字符串字面量内的数字不标注。
///
/// 范围策略（防 id 误判，用户实测反馈）：
/// - 秒级（< 1e11）：2001-09-09 ~ 当前时间 +5 年——真实秒级时间戳必然
///   near-now，10 位纯数字 id（如 3365948418 → 2076 年）超出缓冲即拒绝
/// - 毫秒级（≥ 1e11）：2001-09-09 ~ 9999-12-31——13 位 id 极少见
///
/// 纯函数：调用方负责把 [scanLine] 的分段结果转成富文本 span
/// （Performance 模式）或 [annotateLine] 拼回显示文本（Full 模式
/// CodeField）。原始报文与 Copy 内容不受影响。
class EpochAnnotation {
  EpochAnnotation._();

  /// epoch 秒/毫秒下限：2001-09-09（防普通大数字误判）
  static const int _minSeconds = 1000000000;

  /// 毫秒上限：9999-12-31
  static const int _maxMillis = 253402300799000;

  /// 秒级上限缓冲：当前时间 +5 年（毫秒）
  static const int _futureBufferMs = 157824000000; // 5×365.25×24×3600×1000

  /// 秒/毫秒分界：绝对值小于 1e11 视为秒（当前秒级 ≈ 1.7e9，
  /// 毫秒级 ≈ 1.7e12，两个量级无重叠）
  static const int _secondsThreshold = 100000000000;

  /// 单行扫描分段：[(文本, 是否 epoch 数字)]
  ///
  /// 数字 token 为 JSON 字符串以外的最长数字串（允许前导 `-`，
  /// 负数必不满足范围，自然不标注）；字符串内数字并入普通分段。
  static List<({String text, bool isEpoch})> scanLine(String line) {
    final segments = <({String text, bool isEpoch})>[];
    final plain = StringBuffer();
    var inString = false;
    var i = 0;

    void flushPlain() {
      if (plain.isNotEmpty) {
        segments.add((text: plain.toString(), isEpoch: false));
        plain.clear();
      }
    }

    while (i < line.length) {
      final ch = line[i];

      if (inString) {
        plain.write(ch);
        if (ch == r'\') {
          // 转义序列整体并入字符串（\" 不误判为字符串结束）
          if (i + 1 < line.length) {
            plain.write(line[i + 1]);
            i += 2;
            continue;
          }
        } else if (ch == '"') {
          inString = false;
        }
        i++;
        continue;
      }

      if (ch == '"') {
        inString = true;
        plain.write(ch);
        i++;
        continue;
      }

      final isDigit = ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
      final isSignedStart = ch == '-' &&
          i + 1 < line.length &&
          line[i + 1].codeUnitAt(0) >= 48 &&
          line[i + 1].codeUnitAt(0) <= 57;
      if (!isDigit && !isSignedStart) {
        plain.write(ch);
        i++;
        continue;
      }

      // 数字 token：吃掉连续数字
      final start = i;
      if (ch == '-') {
        i++;
      }
      while (i < line.length &&
          line[i].codeUnitAt(0) >= 48 &&
          line[i].codeUnitAt(0) <= 57) {
        i++;
      }
      final token = line.substring(start, i);
      if (isEpoch(token)) {
        flushPlain();
        segments.add((text: token, isEpoch: true));
      } else {
        plain.write(token);
      }
    }

    flushPlain();
    return segments;
  }

  /// 给单行 JSON 文本追加 epoch 注解，返回可直接显示的字符串；
  /// 无命中时原样返回。
  static String annotateLine(String line) {
    final segments = scanLine(line);
    if (!segments.any((s) => s.isEpoch)) {
      return line;
    }
    final buffer = StringBuffer();
    for (final segment in segments) {
      buffer.write(segment.text);
      if (segment.isEpoch) {
        buffer.write('  ${format(segment.text)}');
      }
    }
    return buffer.toString();
  }

  /// 判定整数字符串是否为可标注的 epoch 值
  static bool isEpoch(String digits) => format(digits) != null;

  /// 格式化为本地可读时间注释 `→ yyyy-MM-dd HH:mm:ss`；非 epoch 返回 null
  ///
  /// 判定规则：绝对值 < 1e11 按秒解析（2001-09-09 ~ 当前 +5 年缓冲），
  /// 否则按毫秒解析（2001-09-09 ~ 9999-12-31）；秒级上限收紧是为防
  /// 10 位纯数字 id（如 3365948418 → 2076 年）被误判（用户实测反馈）。
  static String? format(String digits) {
    final value = int.tryParse(digits);
    if (value == null) {
      return null;
    }
    final int millis;
    if (value.abs() < _secondsThreshold) {
      final nowPlusBuffer =
          DateTime.now().millisecondsSinceEpoch + _futureBufferMs;
      if (value < _minSeconds || value * 1000 > nowPlusBuffer) {
        return null;
      }
      millis = value * 1000;
    } else {
      if (value < _minSeconds * 1000 || value > _maxMillis) {
        return null;
      }
      millis = value;
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int n) => n.toString().padLeft(2, '0');
    return '→ ${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}
