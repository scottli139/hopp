import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';
import '../../models/http_response.dart';
import '../../providers/ai/ai_provider.dart';
import '../../providers/request/request_response_provider.dart';
import '../../providers/request/request_tab_provider.dart';
import '../../providers/settings/settings_provider.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_badge.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import 'ai_settings_dialog.dart';
import 'ai_sparkle_button.dart';

/// 解释响应入口按钮（✨ icon-btn，挂在 ResponseViewer info bar 的
/// Copy / Save 旁）。
///
/// 门控：无响应（或响应体为空 / 请求出错）→ SnackBar「暂无响应可解释」；
/// AI 未启用或未配置模型 → SnackBar 提示 + 「打开设置」动作。
class ExplainResponseButton extends ConsumerWidget {
  const ExplainResponseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AiSparkleButton(
      tooltip: '解释响应',
      onPressed: () => _handlePressed(context, ref),
    );
  }

  void _handlePressed(BuildContext context, WidgetRef ref) {
    final response = ref.read(currentResponseProvider);
    final body = response?.body ?? '';
    if (response == null || response.error != null || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无响应可解释')),
      );
      return;
    }
    if (!isAiReady(ref.read(settingsProvider).valueOrNull)) {
      showAiNotReadySnackBar(context);
      return;
    }

    ref.read(explainProvider.notifier).reset();
    final request = ref.read(activeTabProvider)?.request;
    showAppDialog(
      context: context,
      title: '解释响应',
      width: 560,
      child: ExplainResponseDialogContent(
        response: response,
        request: request,
      ),
    );
  }
}

/// 解释响应对话框内容（非流式：打开即生成，结果一次性呈现）。
///
/// 布局按原型画板 B：上下文摘要行（method + url 截断 · 状态码 ·
/// body 大小 · 模型名）→ 正文三态（loading 转圈 / success 可选择文本 /
/// error 文案 + 重试）→ 底部「重新生成」「复制」「关闭」。
class ExplainResponseDialogContent extends ConsumerStatefulWidget {
  const ExplainResponseDialogContent({
    super.key,
    required this.response,
    this.request,
  });

  final HttpResponse response;
  final HttpRequest? request;

  @override
  ConsumerState<ExplainResponseDialogContent> createState() =>
      _ExplainResponseDialogContentState();
}

class _ExplainResponseDialogContentState
    extends ConsumerState<ExplainResponseDialogContent> {
  @override
  void initState() {
    super.initState();
    // 首帧后再触发解释：initState 内同步改 provider 会触发
    //「building 期间修改 provider」断言
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _explain();
    });
  }

  void _explain() {
    ref.read(explainProvider.notifier).explain(
          statusCode: widget.response.statusCode ?? 0,
          statusText: widget.response.statusText ?? '',
          body: widget.response.body ?? '',
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final aiState = ref.watch(explainProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final model = settings?.aiModel ?? '';

    final request = widget.request;
    final url = request?.url ?? '';
    final summary =
        '${_truncate(url, 42)} · ${widget.response.statusCode ?? '-'} '
        '${widget.response.statusText ?? ''} · '
        '${_formatSize(widget.response.sizeBytes)} · $model';

    return Column(
      key: const Key('explain_response_dialog'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 上下文摘要行
        Row(
          children: [
            if (request != null) ...[
              MethodBadge(request.method.value),
              const SizedBox(width: AppMetrics.space8 - 2),
            ],
            Expanded(
              child: Text(
                summary,
                style: AppTextStyles.code11.copyWith(color: t.textTertiary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppMetrics.space12),

        // 正文三态
        _buildBody(context, aiState),

        // 底部按钮
        const SizedBox(height: AppMetrics.space16),
        Row(
          children: [
            AppButton.ghost(
              label: '重新生成',
              size: AppButtonSize.small,
              onPressed: aiState.isLoading
                  ? null
                  : () {
                      ref.read(explainProvider.notifier).reset();
                      _explain();
                    },
            ),
            const SizedBox(width: AppMetrics.space8),
            AppButton.ghost(
              label: '复制',
              size: AppButtonSize.small,
              onPressed: aiState.isSuccess
                  ? () => Clipboard.setData(
                        ClipboardData(text: aiState.result ?? ''),
                      )
                  : null,
            ),
            const Spacer(),
            AppButton.primary(
              label: '关闭',
              size: AppButtonSize.small,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AiOpState<String> aiState) {
    final t = context.appTheme;

    if (aiState.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppMetrics.space32 + 14),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: AppMetrics.br8,
        ),
        child: Column(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: t.brand),
            ),
            const SizedBox(height: AppMetrics.space12),
            Text(
              '正在解释…（本地模型可能需要 10–30 秒）',
              style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
            ),
          ],
        ),
      );
    }

    if (aiState.isError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppMetrics.space12 + 2),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: AppMetrics.br8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: t.error),
                const SizedBox(width: AppMetrics.space8 - 2),
                Expanded(
                  child: Text(
                    aiState.errorMessage ?? 'AI 调用失败',
                    style: AppTextStyles.caption12.copyWith(color: t.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppMetrics.space12),
            AppButton.ghost(
              label: '重试',
              size: AppButtonSize.small,
              onPressed: () {
                ref.read(explainProvider.notifier).reset();
                _explain();
              },
            ),
          ],
        ),
      );
    }

    if (aiState.isSuccess) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 252),
        padding: const EdgeInsets.symmetric(
          horizontal: AppMetrics.space12 + 2,
          vertical: AppMetrics.space12,
        ),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: AppMetrics.br8,
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            aiState.result ?? '',
            style: AppTextStyles.caption12.copyWith(
              color: t.textSecondary,
              height: 1.8,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _truncate(String text, int max) =>
      text.length > max ? '${text.substring(0, max)}…' : text;

  String _formatSize(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
