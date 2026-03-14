import 'package:freezed_annotation/freezed_annotation.dart';

part 'timing_info.freezed.dart';
part 'timing_info.g.dart';

/// HTTP 请求时间分析信息模型
///
/// 记录 HTTP 请求各阶段的耗时，包括 DNS 解析、TCP 连接、TLS 握手、TTFB、下载等。
///
/// 使用示例：
/// ```dart
/// final timing = TimingInfo(
///   dnsMs: 12,
///   tcpMs: 23,
///   tlsMs: 45,
///   ttfbMs: 8,
///   downloadMs: 112,
///   totalMs: 200,
/// );
/// ```
@freezed
class TimingInfo with _$TimingInfo {
  const factory TimingInfo({
    /// DNS 解析时间 (ms)
    ///
    /// 从发起请求到 DNS 解析完成的时间
    int? dnsMs,

    /// TCP 连接时间 (ms)
    ///
    /// 从 DNS 解析完成到 TCP 连接建立的时间
    int? tcpMs,

    /// TLS 握手时间 (ms)
    ///
    /// 从 TCP 连接建立到 TLS 握手完成的时间（仅 HTTPS）
    int? tlsMs,

    /// 首字节时间 TTFB (ms)
    ///
    /// 从发送 HTTP 请求到收到第一个响应字节的时间
    int? ttfbMs,

    /// 数据传输时间 (ms)
    ///
    /// 从收到第一个字节到完成数据传输的时间
    int? downloadMs,

    /// 总耗时 (ms)
    ///
    /// 从发起请求到完成响应的完整时间
    required int totalMs,
  }) = _TimingInfo;

  factory TimingInfo.fromJson(Map<String, dynamic> json) =>
      _$TimingInfoFromJson(json);

  const TimingInfo._();

  /// 获取等待服务器响应时间 (ms)
  ///
  /// 从请求发送到收到第一个字节的时间，不包含网络传输时间
  int? get waitMs {
    if (ttfbMs == null) return null;
    return ttfbMs;
  }

  /// 获取网络传输总时间 (ms)
  ///
  /// TCP 连接 + TLS 握手 + 下载时间
  int? get networkMs {
    if (tcpMs == null && tlsMs == null && downloadMs == null) return null;
    return (tcpMs ?? 0) + (tlsMs ?? 0) + (downloadMs ?? 0);
  }

  /// 获取格式化的时间字符串
  String formatDuration(int? ms) {
    if (ms == null) return '-';
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  /// 获取 DNS 解析时间字符串
  String get dnsFormatted => formatDuration(dnsMs);

  /// 获取 TCP 连接时间字符串
  String get tcpFormatted => formatDuration(tcpMs);

  /// 获取 TLS 握手时间字符串
  String get tlsFormatted => formatDuration(tlsMs);

  /// 获取 TTFB 时间字符串
  String get ttfbFormatted => formatDuration(ttfbMs);

  /// 获取下载时间字符串
  String get downloadFormatted => formatDuration(downloadMs);

  /// 获取总时间字符串
  String get totalFormatted => formatDuration(totalMs);

  /// 检查是否包含 HTTPS 相关时间
  bool get hasHttpsTiming => tlsMs != null;

  /// 获取各阶段时间占比
  ///
  /// 返回 Map<阶段名称, 百分比>
  Map<String, double> getPhasePercentages() {
    if (totalMs <= 0) return {};

    final percentages = <String, double>{};

    if (dnsMs != null && dnsMs! > 0) {
      percentages['dns'] = (dnsMs! / totalMs * 100).clamp(0, 100);
    }
    if (tcpMs != null && tcpMs! > 0) {
      percentages['tcp'] = (tcpMs! / totalMs * 100).clamp(0, 100);
    }
    if (tlsMs != null && tlsMs! > 0) {
      percentages['tls'] = (tlsMs! / totalMs * 100).clamp(0, 100);
    }
    if (ttfbMs != null && ttfbMs! > 0) {
      percentages['ttfb'] = (ttfbMs! / totalMs * 100).clamp(0, 100);
    }
    if (downloadMs != null && downloadMs! > 0) {
      percentages['download'] = (downloadMs! / totalMs * 100).clamp(0, 100);
    }

    return percentages;
  }
}
