import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';
import '../../providers/ai/ai_provider.dart';
import '../../providers/settings/settings_provider.dart';
import '../../services/ai/ai_models.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_badge.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_text_field.dart';
import 'ai_settings_dialog.dart';
import 'ai_sparkle_button.dart';

/// 自然语言建请求入口按钮（✨ icon-btn，挂在 RequestEditor URL 栏
/// Method 下拉左侧）。
///
/// 门控：AI 未启用或未配置模型 → SnackBar 提示 + 「打开设置」动作。
/// 「填入当前请求」通过 [onApply] 交给宿主（RequestEditor）按既有
/// 请求更新路径写回当前 tab。
class NaturalLanguageRequestButton extends ConsumerWidget {
  const NaturalLanguageRequestButton({
    super.key,
    required this.currentRequest,
    required this.onApply,
  });

  final HttpRequest currentRequest;
  final ValueChanged<AiRequestDraft> onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AiSparkleButton(
      tooltip: '自然语言建请求',
      onPressed: () => _handlePressed(context, ref),
    );
  }

  void _handlePressed(BuildContext context, WidgetRef ref) {
    if (!isAiReady(ref.read(settingsProvider).valueOrNull)) {
      showAiNotReadySnackBar(context);
      return;
    }
    ref.read(buildRequestProvider.notifier).reset();
    showAppDialog(
      context: context,
      title: '自然语言建请求',
      width: 560,
      child: BuildRequestDialogContent(
        currentRequest: currentRequest,
        onApply: onApply,
      ),
    );
  }
}

/// 自然语言建请求对话框内容（F9.5，两步：输入态 → 结果确认态）。
///
/// 布局按原型画板 D：输入态 = 多行描述输入 + 提示条 + 「取消」「生成」；
/// 结果态 = 摘要行（方法徽章 + url）+ Params / Headers 两行预览 +
/// Body mono 片段 + 「重新生成」「取消」「填入当前请求」。
/// 生成的是草稿：字段取值仅来自描述，填入编辑器后可继续修改。
class BuildRequestDialogContent extends ConsumerStatefulWidget {
  const BuildRequestDialogContent({
    super.key,
    required this.currentRequest,
    required this.onApply,
  });

  final HttpRequest currentRequest;
  final ValueChanged<AiRequestDraft> onApply;

  @override
  ConsumerState<BuildRequestDialogContent> createState() =>
      _BuildRequestDialogContentState();
}

class _BuildRequestDialogContentState
    extends ConsumerState<BuildRequestDialogContent> {
  late final TextEditingController _descCtrl;
  String _lastDescription = '';

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    _lastDescription = _descCtrl.text.trim();
    ref
        .read(buildRequestProvider.notifier)
        .build(description: _lastDescription);
  }

  Future<void> _apply(AiRequestDraft draft) async {
    final request = widget.currentRequest;
    final hasContent = request.url.isNotEmpty ||
        request.params.isNotEmpty ||
        request.headers.isNotEmpty ||
        request.body.isNotEmpty;
    if (hasContent) {
      final confirmed = await showAppDialog<bool>(
        context: context,
        title: '覆盖当前请求内容？',
        child: Text(
          '当前请求已有内容，填入草稿将覆盖 URL、Params、Headers 与 Body。',
          style: AppTextStyles.body13.copyWith(
            color: context.appTheme.textSecondary,
          ),
        ),
        actions: [
          AppButton.ghost(
            label: '取消',
            size: AppButtonSize.small,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton.primary(
            label: '覆盖',
            size: AppButtonSize.small,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
      if (confirmed != true) return;
    }
    widget.onApply(draft);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(buildRequestProvider);

    return Column(
      key: const Key('build_request_dialog'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: SingleChildScrollView(child: _buildBody(context, aiState)),
        ),
        const SizedBox(height: AppMetrics.space16),
        _buildFooter(context, aiState),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AiOpState<AiRequestDraft> aiState) {
    if (aiState.isLoading) {
      final t = context.appTheme;
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        alignment: Alignment.center,
        child: Column(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: t.brand),
            ),
            const SizedBox(height: AppMetrics.space12),
            Text(
              '正在生成…（本地模型可能需要 10–30 秒）',
              style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
            ),
          ],
        ),
      );
    }

    if (aiState.isError) {
      final t = context.appTheme;
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
                ref.read(buildRequestProvider.notifier).reset();
                _generate();
              },
            ),
          ],
        ),
      );
    }

    if (aiState.isSuccess && aiState.result != null) {
      return _buildResultPreview(context, aiState.result!);
    }

    // 输入态
    final t = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          fieldKey: const Key('ai_request_description_field'),
          controller: _descCtrl,
          maxLines: 5,
          hintText: '描述你想创建的请求，例如：POST 创建用户，JSON body 含 '
              'name 和 email，需要认证',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppMetrics.space12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.space12 - 2,
            vertical: AppMetrics.space8 + 1,
          ),
          decoration: BoxDecoration(
            color: t.infoSoft,
            borderRadius: AppMetrics.br6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 13, color: t.info),
              const SizedBox(width: AppMetrics.space8 - 1),
              Expanded(
                child: Text(
                  '生成的是草稿，填入编辑器后可继续修改；字段取值仅来自你的描述',
                  style: AppTextStyles.tiny11.copyWith(
                    color: t.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultPreview(BuildContext context, AiRequestDraft draft) {
    final t = context.appTheme;

    Widget sectionLabel(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: AppMetrics.space12, bottom: 5),
        child: Text(
          text,
          style: AppTextStyles.micro10.copyWith(
            color: t.textTertiary,
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    Widget kvRows(List<AiKeyValueDraft> items) {
      if (items.isEmpty) {
        return Text(
          '0 行',
          style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
        );
      }
      return Column(
        children: [
          for (final kv in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      kv.key,
                      style: AppTextStyles.code11.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppMetrics.space8),
                  Expanded(
                    child: Text(
                      kv.value,
                      style: AppTextStyles.code11.copyWith(
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    final bodyLabel = draft.bodyType == 'raw'
        ? 'BODY · ${(draft.rawContentType ?? '').toUpperCase()}'
        : 'BODY · ${draft.bodyType.toUpperCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 摘要行
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.space12 - 2,
            vertical: AppMetrics.space8,
          ),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: AppMetrics.br6,
          ),
          child: Row(
            children: [
              MethodBadge(draft.method),
              const SizedBox(width: AppMetrics.space8),
              Expanded(
                child: Text(
                  draft.url,
                  style: AppTextStyles.code12.copyWith(color: t.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        sectionLabel('PARAMS'),
        kvRows(draft.params),
        sectionLabel('HEADERS'),
        kvRows(draft.headers),
        if (draft.bodyType != 'none' && (draft.body ?? '').isNotEmpty) ...[
          sectionLabel(bodyLabel),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppMetrics.space12),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border.all(color: t.border),
              borderRadius: AppMetrics.br6,
            ),
            child: Text(
              draft.body!,
              style: AppTextStyles.code11.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AiOpState<AiRequestDraft> aiState) {
    if (aiState.isSuccess && aiState.result != null) {
      return Row(
        children: [
          AppButton.ghost(
            label: '重新生成',
            size: AppButtonSize.small,
            onPressed: () {
              ref.read(buildRequestProvider.notifier).reset();
              _generate();
            },
          ),
          const Spacer(),
          AppButton.ghost(
            label: '取消',
            size: AppButtonSize.small,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppMetrics.space8),
          AppButton.primary(
            key: const Key('ai_apply_draft_button'),
            label: '填入当前请求',
            size: AppButtonSize.small,
            onPressed: () => _apply(aiState.result!),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton.ghost(
          label: '取消',
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppMetrics.space8),
        AppButton.primary(
          key: const Key('ai_generate_request_button'),
          label: '生成',
          size: AppButtonSize.small,
          onPressed: aiState.isLoading || _descCtrl.text.trim().isEmpty
              ? null
              : _generate,
        ),
      ],
    );
  }
}
