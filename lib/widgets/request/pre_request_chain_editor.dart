import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopp/l10n/l10n.dart';
import 'package:uuid/uuid.dart';

import '../../models/pre_request_step.dart';
import '../../providers/providers.dart';
import '../../services/pre_request/pre_request_chain_runner.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_controls.dart';
import '../common/app_popup_menu.dart';
import '../common/app_text_field.dart';

/// 预请求链编辑器（F8.2）
///
/// 请求 Pre-request tab 与集合设置对话框复用。按 UI 原型
/// `docs/design/f8_prerequest_chain_preview.html` 实现：
/// - 步骤卡片：请求选择器（引用集合中已保存请求）+ 提取规则表 +
///   排序（拖拽）/ 停用 / 删除
/// - 底部策略条：401 自动重跑开关 + 本地作用域说明
/// - 试运行：就地执行链并展示产出变量（不发目标请求）
///
/// 所有编辑通过 [onChainChanged] / [onRetryChanged] 即时回写。
class PreRequestChainEditor extends ConsumerStatefulWidget {
  const PreRequestChainEditor({
    super.key,
    required this.chain,
    required this.retryOn401,
    required this.onChainChanged,
    required this.onRetryChanged,
    required this.ownerId,
    this.excludeRequestId,
    this.onTestRun,
  });

  final List<PreRequestStep> chain;
  final bool retryOn401;
  final ValueChanged<List<PreRequestStep>> onChainChanged;
  final ValueChanged<bool> onRetryChanged;

  /// 试运行结果的查询 key（请求 tab 用 request.id，集合设置用 collection.id）
  final String ownerId;

  /// 请求编辑场景排除自身（不能引用自己作为前置步骤）
  final String? excludeRequestId;

  /// 试运行回调（由宿主触发链执行；为 null 时隐藏试运行按钮）
  final VoidCallback? onTestRun;

  @override
  ConsumerState<PreRequestChainEditor> createState() =>
      _PreRequestChainEditorState();
}

class _PreRequestChainEditorState extends ConsumerState<PreRequestChainEditor> {
  // 提取规则输入框 controller 缓存（key = rule.id）
  final Map<String, TextEditingController> _pathControllers = {};
  final Map<String, TextEditingController> _targetControllers = {};

  @override
  void dispose() {
    for (final c in _pathControllers.values) {
      c.dispose();
    }
    for (final c in _targetControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppMetrics.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：说明 + 操作
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.prerequest_title,
                      style: AppTextStyles.body13.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppMetrics.space4),
                    Text(
                      context.l10n.prerequest_subtitle,
                      style: AppTextStyles.tiny11.copyWith(
                        color: t.textTertiary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppMetrics.space12),
              AppButton.secondary(
                label: context.l10n.prerequest_addStep,
                icon: Icons.add,
                size: AppButtonSize.small,
                onPressed: _addStep,
              ),
              if (widget.onTestRun != null) ...[
                const SizedBox(width: AppMetrics.space8),
                AppButton.primary(
                  label: context.l10n.prerequest_testRun,
                  icon: Icons.play_arrow,
                  size: AppButtonSize.small,
                  onPressed: widget.chain.isEmpty ? null : widget.onTestRun,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppMetrics.space12),

          // 步骤列表
          if (widget.chain.isEmpty)
            _buildEmptyState(context)
          else
            _buildStepList(context),

          // 运行策略
          _buildPolicyBar(context),

          // 试运行结果
          _buildRunResult(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final t = context.appTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppMetrics.space24),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppMetrics.br6,
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Icon(Icons.link_off, size: 24, color: t.textTertiary),
          const SizedBox(height: AppMetrics.space8),
          Text(
            context.l10n.prerequest_emptyTitle,
            style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppMetrics.space4),
          Text(
            context.l10n.prerequest_emptyHint('{{token}}'),
            style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    );
  }

  // ---------- 步骤列表 ----------

  Widget _buildStepList(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: widget.chain.length,
      onReorder: _reorderStep,
      itemBuilder: (context, index) =>
          _buildStepCard(context, widget.chain[index], index),
    );
  }

  Widget _buildStepCard(BuildContext context, PreRequestStep step, int index) {
    final t = context.appTheme;
    final requests = ref.watch(requestsProvider).valueOrNull ?? [];
    final candidates =
        requests.where((r) => r.id != widget.excludeRequestId).toList();
    final linked = requests.where((r) => r.id == step.requestId).firstOrNull;

    return Opacity(
      key: ValueKey(step.id),
      opacity: step.enabled ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppMetrics.space12),
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: AppMetrics.br8,
          border: Border.all(color: t.border),
        ),
        child: Column(
          children: [
            // 步骤头：拖拽柄 + 序号 + 请求选择器 + 操作
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppMetrics.space8),
                      child: Icon(Icons.drag_indicator,
                          size: 16, color: t.textTertiary),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: t.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.micro10.copyWith(
                          color: t.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppMetrics.space8),
                  // 请求选择器
                  SizedBox(
                    width: 260,
                    child: AppPopupSelect<String>(
                      value: linked?.id,
                      hint: context.l10n.prerequest_selectRequest,
                      boxed: true,
                      compact: true,
                      items: [
                        for (final r in candidates)
                          AppPopupSelectEntry(
                            value: r.id,
                            label: '${r.method.value} ${r.name}',
                          ),
                      ],
                      onSelected: (id) =>
                          _updateStep(index, step.copyWith(requestId: id)),
                    ),
                  ),
                  if (step.requestId.isNotEmpty && linked == null) ...[
                    const SizedBox(width: AppMetrics.space8),
                    Tooltip(
                      message: context.l10n.prerequest_requestDeleted,
                      child:
                          Icon(Icons.error_outline, size: 14, color: t.error),
                    ),
                  ],
                  const Spacer(),
                  AppSwitch(
                    value: step.enabled,
                    onChanged: (v) =>
                        _updateStep(index, step.copyWith(enabled: v)),
                  ),
                  const SizedBox(width: AppMetrics.space4),
                  AppIconButton(
                    icon: Icons.delete_outline,
                    tooltip: context.l10n.prerequest_deleteStep,
                    danger: true,
                    onPressed: () => _removeStep(index),
                  ),
                  const SizedBox(width: AppMetrics.space8),
                ],
              ),
            ),
            // 提取规则表
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppMetrics.space12),
              decoration: BoxDecoration(
                color: t.surface,
                border: Border(top: BorderSide(color: t.border)),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppMetrics.radius8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.prerequest_extractHeader,
                    style: AppTextStyles.micro10.copyWith(
                      color: t.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: AppMetrics.space8),
                  for (var i = 0; i < step.extractions.length; i++)
                    _buildRuleRow(context, index, step, step.extractions[i], i),
                  _buildAddRuleRow(context, index, step),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(
    BuildContext context,
    int stepIndex,
    PreRequestStep step,
    ExtractionRule rule,
    int ruleIndex,
  ) {
    final t = context.appTheme;

    final pathController = _pathControllers.putIfAbsent(
      rule.id,
      () => TextEditingController(text: rule.path),
    );
    final targetController = _targetControllers.putIfAbsent(
      rule.id,
      () => TextEditingController(text: rule.targetVariable),
    );
    if (pathController.text != rule.path) pathController.text = rule.path;
    if (targetController.text != rule.targetVariable) {
      targetController.text = rule.targetVariable;
    }

    void commitRule({ExtractionRule? Function(ExtractionRule)? transform}) {
      final current = transform?.call(rule) ??
          rule.copyWith(
            path: pathController.text,
            targetVariable: targetController.text,
          );
      final rules = [...step.extractions];
      rules[ruleIndex] = current;
      _updateStep(stepIndex, step.copyWith(extractions: rules));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppMetrics.space8),
      child: Row(
        children: [
          AppCheckbox(
            value: rule.enabled,
            onChanged: (v) =>
                commitRule(transform: (r) => r.copyWith(enabled: v)),
          ),
          const SizedBox(width: AppMetrics.space8),
          // 来源选择
          SizedBox(
            width: 150,
            child: AppPopupSelect<ExtractionSourceType>(
              value: rule.source,
              boxed: true,
              compact: true,
              items: [
                AppPopupSelectEntry(
                  value: ExtractionSourceType.bodyJsonPath,
                  label: context.l10n.prerequest_sourceJsonPath,
                ),
                AppPopupSelectEntry(
                  value: ExtractionSourceType.header,
                  label: context.l10n.prerequest_sourceHeader,
                ),
                AppPopupSelectEntry(
                  value: ExtractionSourceType.bodyRegex,
                  label: context.l10n.prerequest_sourceRegex,
                ),
              ],
              onSelected: (v) =>
                  commitRule(transform: (r) => r.copyWith(source: v)),
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          // 路径 / 模式
          Expanded(
            flex: 3,
            child: AppTextField(
              controller: pathController,
              compact: true,
              borderless: true,
              hintText: switch (rule.source) {
                ExtractionSourceType.bodyJsonPath => r'$.data.token',
                ExtractionSourceType.header => 'X-Request-Id',
                ExtractionSourceType.bodyRegex => r'token=(\w+)',
              },
              onSubmitted: (_) => commitRule(),
              onChanged: (_) => commitRule(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space4),
            child: Icon(Icons.arrow_forward, size: 12, color: t.textTertiary),
          ),
          // 目标变量
          SizedBox(
            width: 150,
            child: AppTextField(
              controller: targetController,
              compact: true,
              borderless: true,
              hintText: 'token',
              onSubmitted: (_) => commitRule(),
              onChanged: (_) => commitRule(),
            ),
          ),
          AppIconButton(
            icon: Icons.close,
            tooltip: context.l10n.prerequest_deleteRule,
            danger: true,
            size: 24,
            iconSize: 13,
            onPressed: () {
              final rules = [...step.extractions]..removeAt(ruleIndex);
              _pathControllers.remove(rule.id)?.dispose();
              _targetControllers.remove(rule.id)?.dispose();
              _updateStep(stepIndex, step.copyWith(extractions: rules));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddRuleRow(
      BuildContext context, int stepIndex, PreRequestStep step) {
    return AppButton.secondary(
      label: context.l10n.prerequest_addRule,
      icon: Icons.add,
      size: AppButtonSize.small,
      onPressed: () {
        final rules = [
          ...step.extractions,
          ExtractionRule(id: const Uuid().v4()),
        ];
        _updateStep(stepIndex, step.copyWith(extractions: rules));
      },
    );
  }

  // ---------- 策略条与试运行结果 ----------

  Widget _buildPolicyBar(BuildContext context) {
    final t = context.appTheme;
    return Container(
      margin: const EdgeInsets.only(top: AppMetrics.space4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.space12,
        vertical: AppMetrics.space8,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppMetrics.br6,
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Text(
            context.l10n.prerequest_policyTitle,
            style: AppTextStyles.caption12.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppMetrics.space16),
          AppSwitch(value: widget.retryOn401, onChanged: widget.onRetryChanged),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: Text(
              context.l10n.prerequest_retry401Hint,
              style: AppTextStyles.tiny11.copyWith(color: t.textSecondary),
            ),
          ),
          Tooltip(
            message: context.l10n.prerequest_scopeTooltip,
            child: Row(
              children: [
                Icon(Icons.dns_outlined, size: 13, color: t.textTertiary),
                const SizedBox(width: AppMetrics.space4),
                Text(
                  context.l10n.prerequest_scopeLocal,
                  style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunResult(BuildContext context) {
    final result = ref.watch(preRequestRunResultsProvider)[widget.ownerId];
    if (result == null) return const SizedBox.shrink();

    final t = context.appTheme;
    final succeeded = result.allSucceeded;

    return Container(
      margin: const EdgeInsets.only(top: AppMetrics.space12),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: AppMetrics.br6,
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space12),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Text(
                  context.l10n.prerequest_resultTitle,
                  style: AppTextStyles.caption12.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppMetrics.space8),
                Icon(
                  succeeded ? Icons.check_circle : Icons.error,
                  size: 13,
                  color: succeeded ? t.success : t.error,
                ),
                Text(
                  succeeded
                      ? ' ${context.l10n.prerequest_allSucceeded}'
                      : ' ${result.firstError ?? context.l10n.prerequest_someStepsFailed}',
                  style: AppTextStyles.tiny11.copyWith(
                    color: succeeded ? t.success : t.error,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppMetrics.space12),
            child: Column(
              children: [
                for (final stepResult in result.steps)
                  if (stepResult.step.enabled)
                    _buildResultRow(context, stepResult),
                if (result.produced.isEmpty && succeeded)
                  Text(
                    context.l10n.prerequest_noVariables,
                    style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, ChainStepResult stepResult) {
    final t = context.appTheme;
    final step = stepResult.step;
    final extracted = stepResult.extracted;
    final missing = stepResult.missing;
    final error = stepResult.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppMetrics.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                error == null
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 13,
                color: error == null ? t.success : t.error,
              ),
              const SizedBox(width: AppMetrics.space4),
              Text(
                context.l10n
                    .prerequest_stepN('${widget.chain.indexOf(step) + 1}'),
                style: AppTextStyles.tiny11.copyWith(
                  color: t.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (stepResult.statusCode != null) ...[
                const SizedBox(width: AppMetrics.space8),
                Text(
                  '${stepResult.statusCode}',
                  style: AppTextStyles.code11.copyWith(color: t.textTertiary),
                ),
              ],
              if (error != null) ...[
                const SizedBox(width: AppMetrics.space8),
                Expanded(
                  child: Text(
                    error,
                    style: AppTextStyles.tiny11.copyWith(color: t.error),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          for (final entry in extracted.entries)
            Padding(
              padding: const EdgeInsets.only(left: 17, top: 2),
              child: Row(
                children: [
                  Text(
                    '{{${entry.key}}}',
                    style: AppTextStyles.code11.copyWith(color: t.brand),
                  ),
                  const SizedBox(width: AppMetrics.space8),
                  Expanded(
                    child: Text(
                      entry.value.length <= 48
                          ? entry.value
                          : '${entry.value.substring(0, 45)}...',
                      style:
                          AppTextStyles.code11.copyWith(color: t.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          for (final rule in missing)
            Padding(
              padding: const EdgeInsets.only(left: 17, top: 2),
              child: Text(
                context.l10n.prerequest_missingValue(
                    rule.path, '{{${rule.targetVariable}}}'),
                style: AppTextStyles.tiny11.copyWith(color: t.warning),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- 链操作 ----------

  void _addStep() {
    widget.onChainChanged([
      ...widget.chain,
      PreRequestStep(id: const Uuid().v4()),
    ]);
  }

  void _removeStep(int index) {
    final chain = [...widget.chain]..removeAt(index);
    widget.onChainChanged(chain);
  }

  void _reorderStep(int oldIndex, int newIndex) {
    final chain = [...widget.chain];
    final step = chain.removeAt(oldIndex);
    chain.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, step);
    widget.onChainChanged(chain);
  }

  void _updateStep(int index, PreRequestStep updated) {
    final chain = [...widget.chain];
    chain[index] = updated;
    widget.onChainChanged(chain);
  }
}
