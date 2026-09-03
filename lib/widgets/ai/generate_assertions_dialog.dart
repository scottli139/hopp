import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/l10n.dart';
import '../../models/assertion_rule.dart';
import '../../models/http_request.dart';
import '../../models/http_response.dart';
import '../../providers/ai/ai_provider.dart';
import '../../providers/request/request_response_provider.dart';
import '../../providers/request/request_tab_provider.dart';
import '../../providers/settings/settings_provider.dart';
import '../../services/ai/ai_models.dart';
import '../../services/assertion/assertion_engine.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_controls.dart';
import '../common/app_dialog.dart';
import '../common/app_popup_menu.dart';
import '../common/app_text_field.dart';
import '../request/assertion_editor.dart';
import 'ai_settings_dialog.dart';

/// AI 生成断言入口按钮（Assertions 页首，Add assertion 左侧）。
///
/// 门控：当前 tab 无响应样本 → SnackBar「请先在 Tests 运行或发送请求」；
/// AI 未启用或未配置模型 → 直接打开 AI 设置对话框。
/// 确认后通过 [onConfirm] 把勾选的规则追加进断言列表（由宿主持久化）。
class GenerateAssertionsButton extends ConsumerWidget {
  const GenerateAssertionsButton({
    super.key,
    required this.onConfirm,
  });

  final ValueChanged<List<AssertionRule>> onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton.secondary(
      label: context.l10n.ai_generateButton,
      icon: Icons.auto_awesome,
      size: AppButtonSize.small,
      onPressed: () => _handlePressed(context, ref),
    );
  }

  void _handlePressed(BuildContext context, WidgetRef ref) {
    final response = ref.read(currentResponseProvider);
    final body = response?.body ?? '';
    if (response == null || response.error != null || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ai_needResponseSample)),
      );
      return;
    }
    if (!isAiReady(ref.read(settingsProvider).valueOrNull)) {
      openAiSettingsDialog(context);
      return;
    }

    final request = ref.read(activeTabProvider)?.request;
    ref.read(generateAssertionsProvider.notifier).reset();
    showAppDialog(
      context: context,
      title: context.l10n.ai_genAssertionsTitle,
      width: 640,
      child: GenerateAssertionsDialogContent(
        request: request,
        response: response,
        onConfirm: onConfirm,
      ),
    );
  }
}

/// 草稿行：本地编辑态（勾选 + 可编辑字段），确认后才转 [AssertionRule]
class _DraftRow {
  _DraftRow({required this.draft})
      : checked = true,
        argCtrl = TextEditingController(text: draft.targetArg),
        expectedCtrl = TextEditingController(text: draft.expected);

  AiAssertionDraft draft;
  bool checked;
  final TextEditingController argCtrl;
  final TextEditingController expectedCtrl;

  void dispose() {
    argCtrl.dispose();
    expectedCtrl.dispose();
  }
}

/// AI 生成断言对话框内容（F4.2，防脑补：AI 返回先过 schema 校验，
/// 非法项丢弃并计数可视化）。
///
/// 布局按原型画板 C：说明行（已选 N/M）→ 草稿列表（勾选 + target +
/// path + operator + expected + 删除，可就地编辑）→ discarded 警告行 →
/// 底部「重新生成」「取消」「添加 N 条」。
class GenerateAssertionsDialogContent extends ConsumerStatefulWidget {
  const GenerateAssertionsDialogContent({
    super.key,
    this.request,
    required this.response,
    required this.onConfirm,
  });

  final HttpRequest? request;
  final HttpResponse response;
  final ValueChanged<List<AssertionRule>> onConfirm;

  @override
  ConsumerState<GenerateAssertionsDialogContent> createState() =>
      _GenerateAssertionsDialogContentState();
}

class _GenerateAssertionsDialogContentState
    extends ConsumerState<GenerateAssertionsDialogContent> {
  List<_DraftRow> _rows = [];
  int _discarded = 0;

  @override
  void initState() {
    super.initState();
    // 首帧后再触发生成：initState 内同步改 provider 会触发
    //「building 期间修改 provider」断言
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _generate();
    });
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _generate() {
    ref.read(generateAssertionsProvider.notifier).generate(
          method: widget.request?.method.value ?? '',
          url: widget.request?.url ?? '',
          responseBody: widget.response.body ?? '',
        );
  }

  void _initRows(AiAssertionParseResult result) {
    for (final row in _rows) {
      row.dispose();
    }
    _rows = [for (final item in result.items) _DraftRow(draft: item)];
    _discarded = result.discarded;
  }

  int get _checkedCount => _rows.where((r) => r.checked).length;

  void _confirm() {
    final rules = <AssertionRule>[
      for (final row in _rows)
        if (row.checked)
          AssertionRule(
            id: const Uuid().v4(),
            target: row.draft.target,
            targetArg: AssertionEngine.needsTargetArg(row.draft.target)
                ? row.argCtrl.text.trim()
                : '',
            operator: row.draft.operator,
            expected: AssertionEngine.needsExpected(row.draft.operator)
                ? row.expectedCtrl.text.trim()
                : '',
          ),
    ];
    widget.onConfirm(rules);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiOpState<AiAssertionParseResult>>(
      generateAssertionsProvider,
      (previous, current) {
        if (current.isSuccess && current.result != null) {
          setState(() => _initRows(current.result!));
        }
      },
    );

    final t = context.appTheme;
    final aiState = ref.watch(generateAssertionsProvider);
    final total = _rows.length;
    final checked = _checkedCount;

    return Column(
      key: const Key('generate_assertions_dialog'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 说明行
        Text(
          context.l10n.ai_genSelected('$checked', '$total'),
          style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppMetrics.space12),

        // 正文三态
        Flexible(
          child: SingleChildScrollView(
            child: _buildBody(context, aiState),
          ),
        ),

        // discarded 警告行
        if (aiState.isSuccess && _discarded > 0) ...[
          const SizedBox(height: AppMetrics.space8),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 12, color: t.warning),
              const SizedBox(width: AppMetrics.space4 + 2),
              Text(
                context.l10n.ai_genDiscarded('$_discarded'),
                style: AppTextStyles.tiny11.copyWith(color: t.warning),
              ),
            ],
          ),
        ],

        // 底部按钮
        const SizedBox(height: AppMetrics.space16),
        Row(
          children: [
            AppButton.ghost(
              label: context.l10n.ai_regenerate,
              size: AppButtonSize.small,
              onPressed: aiState.isLoading
                  ? null
                  : () {
                      ref.read(generateAssertionsProvider.notifier).reset();
                      _generate();
                    },
            ),
            const Spacer(),
            AppButton.ghost(
              label: context.l10n.common_cancel,
              size: AppButtonSize.small,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppMetrics.space8),
            AppButton.primary(
              label: context.l10n.ai_addChecked('$checked'),
              size: AppButtonSize.small,
              onPressed: aiState.isSuccess && checked > 0 ? _confirm : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AiOpState<AiAssertionParseResult> aiState,
  ) {
    final t = context.appTheme;

    if (aiState.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppMetrics.space32 + 14),
        child: Column(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: t.brand),
            ),
            const SizedBox(height: AppMetrics.space12),
            Text(
              context.l10n.ai_generatingAssertions,
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
                    aiState.errorMessage ?? context.l10n.ai_callFailedGeneric,
                    style: AppTextStyles.caption12.copyWith(color: t.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppMetrics.space12),
            AppButton.ghost(
              label: context.l10n.ai_retry,
              size: AppButtonSize.small,
              onPressed: () {
                ref.read(generateAssertionsProvider.notifier).reset();
                _generate();
              },
            ),
          ],
        ),
      );
    }

    if (aiState.isSuccess) {
      if (_rows.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppMetrics.space24),
          child: Center(
            child: Text(
              context.l10n.ai_noSuggestions,
              style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
            ),
          ),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGridHead(context),
          for (final row in _rows) _buildRow(context, row),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildGridHead(BuildContext context) {
    final t = context.appTheme;
    const labelStyle = AppTextStyles.micro10;

    Widget headCell(String text, {double? width}) {
      final cell = Text(
        text,
        style: labelStyle.copyWith(
          color: t.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      );
      return width == null
          ? Expanded(child: cell)
          : SizedBox(width: width, child: cell);
    }

    return Container(
      height: 26,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),
          const SizedBox(width: AppMetrics.space8),
          headCell(context.l10n.ai_colTarget, width: 108),
          const SizedBox(width: AppMetrics.space8),
          headCell(context.l10n.ai_colPath),
          const SizedBox(width: AppMetrics.space8),
          headCell(context.l10n.ai_colOperator, width: 120),
          const SizedBox(width: AppMetrics.space8),
          headCell(context.l10n.ai_colExpected, width: 120),
          const SizedBox(width: AppMetrics.space8),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, _DraftRow row) {
    final t = context.appTheme;
    final rule = row.draft;
    final operators = AssertionEngine.operatorsByTarget[rule.target] ??
        const <AssertionOperator>[];
    final effectiveOperator =
        operators.contains(rule.operator) ? rule.operator : operators.first;
    final showArg = AssertionEngine.needsTargetArg(rule.target);
    final showExpected = AssertionEngine.needsExpected(effectiveOperator);

    void commit(AiAssertionDraft updated) =>
        setState(() => row.draft = updated);

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(vertical: AppMetrics.space4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Center(
              child: AppCheckbox(
                value: row.checked,
                onChanged: (v) => setState(() => row.checked = v),
              ),
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          SizedBox(
            width: 108,
            child: AppPopupSelect<AssertionTarget>(
              value: rule.target,
              boxed: true,
              compact: true,
              items: [
                for (final target in AssertionTarget.values)
                  AppPopupSelectEntry(
                    value: target,
                    label: AssertionLabels.target[target]!,
                  ),
              ],
              onSelected: (target) {
                final allowed = AssertionEngine.operatorsByTarget[target] ??
                    const <AssertionOperator>[];
                final operator = allowed.contains(rule.operator)
                    ? rule.operator
                    : allowed.first;
                commit(rule.copyWith(target: target, operator: operator));
              },
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: AppTextField(
              controller: row.argCtrl,
              compact: true,
              enabled: showArg,
              hintText: showArg
                  ? (rule.target == AssertionTarget.header
                      ? context.l10n.ai_headerNameHint
                      : r'$.data.id')
                  : '—',
              onChanged: (_) {},
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          SizedBox(
            width: 120,
            child: AppPopupSelect<AssertionOperator>(
              value: effectiveOperator,
              boxed: true,
              compact: true,
              textStyle: AppTextStyles.code11,
              items: [
                for (final op in operators)
                  AppPopupSelectEntry(
                    value: op,
                    label: AssertionLabels.operator[op]!,
                  ),
              ],
              onSelected: (op) => commit(rule.copyWith(operator: op)),
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          SizedBox(
            width: 120,
            child: AppTextField(
              controller: row.expectedCtrl,
              compact: true,
              enabled: showExpected,
              hintText: showExpected ? context.l10n.ai_expectedValueHint : '—',
              onChanged: (_) {},
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          AppIconButton(
            icon: Icons.close,
            tooltip: context.l10n.common_delete,
            danger: true,
            size: 24,
            iconSize: 13,
            onPressed: () => setState(() {
              row.dispose();
              _rows.remove(row);
            }),
          ),
        ],
      ),
    );
  }
}
