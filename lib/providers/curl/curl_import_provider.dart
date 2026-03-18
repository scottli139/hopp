/// cURL 导入状态管理
///
/// 管理 cURL 导入对话框的状态和解析逻辑。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';

import '../../services/curl/curl_import_service.dart';
import '../../utils/app_logger.dart';

/// cURL 导入状态
enum CurlImportStatus {
  /// 空闲状态
  idle,

  /// 解析中
  parsing,

  /// 解析成功
  success,

  /// 解析错误
  error,
}

/// cURL 导入状态类
@immutable
class CurlImportState {
  final CurlImportStatus status;
  final HttpRequest? request;
  final String? errorMessage;
  final List<String> warnings;
  final String inputText;

  const CurlImportState({
    this.status = CurlImportStatus.idle,
    this.request,
    this.errorMessage,
    this.warnings = const [],
    this.inputText = '',
  });

  CurlImportState copyWith({
    CurlImportStatus? status,
    HttpRequest? request,
    String? errorMessage,
    List<String>? warnings,
    String? inputText,
  }) {
    return CurlImportState(
      status: status ?? this.status,
      request: request ?? this.request,
      errorMessage: errorMessage ?? this.errorMessage,
      warnings: warnings ?? this.warnings,
      inputText: inputText ?? this.inputText,
    );
  }

  bool get isIdle => status == CurlImportStatus.idle;
  bool get isParsing => status == CurlImportStatus.parsing;
  bool get isSuccess => status == CurlImportStatus.success;
  bool get isError => status == CurlImportStatus.error;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// cURL 导入服务 Provider
final curlImportServiceProvider = Provider<CurlImportService>((ref) {
  return CurlImportService();
});

/// cURL 导入状态 Provider
final curlImportProvider =
    StateNotifierProvider<CurlImportNotifier, CurlImportState>((ref) {
  return CurlImportNotifier(ref);
});

/// cURL 导入状态管理器
class CurlImportNotifier extends StateNotifier<CurlImportState> with LogMixin {
  final Ref _ref;

  CurlImportNotifier(this._ref) : super(const CurlImportState());

  /// 更新输入文本
  void updateInput(String text) {
    state = state.copyWith(inputText: text);
    // 输入变化时重置状态
    if (state.status != CurlImportStatus.idle) {
      state = state.copyWith(status: CurlImportStatus.idle);
    }
  }

  /// 解析 cURL 命令
  Future<void> parse() async {
    final input = state.inputText.trim();

    if (input.isEmpty) {
      state = state.copyWith(
        status: CurlImportStatus.error,
        errorMessage: 'Please enter a cURL command',
      );
      return;
    }

    // 验证是否是有效的 cURL 命令
    final service = _ref.read(curlImportServiceProvider);
    if (!service.isValidCurlCommand(input)) {
      state = state.copyWith(
        status: CurlImportStatus.error,
        errorMessage: 'Invalid cURL command. Must start with "curl"',
      );
      return;
    }

    state = state.copyWith(status: CurlImportStatus.parsing);

    try {
      final result = service.parse(input);

      if (result.success && result.request != null) {
        state = state.copyWith(
          status: CurlImportStatus.success,
          request: result.request,
          warnings: result.warnings,
          errorMessage: null,
        );
        logInfo('cURL parsed successfully: ${result.request!.name}');
      } else {
        state = state.copyWith(
          status: CurlImportStatus.error,
          errorMessage: result.errorMessage ?? 'Unknown error',
          request: null,
        );
      }
    } catch (e, stack) {
      logError('cURL parse failed', e, stack);
      state = state.copyWith(
        status: CurlImportStatus.error,
        errorMessage: e.toString(),
        request: null,
      );
    }
  }

  /// 获取解析后的请求
  HttpRequest? get parsedRequest => state.request;

  /// 重置状态
  void reset() {
    state = const CurlImportState();
  }

  /// 清除错误
  void clearError() {
    if (state.isError) {
      state = state.copyWith(status: CurlImportStatus.idle, errorMessage: null);
    }
  }
}
