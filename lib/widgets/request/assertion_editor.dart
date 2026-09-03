import 'package:flutter/material.dart';
import 'package:hopp/l10n/l10n.dart';
import 'package:uuid/uuid.dart';

import '../../models/assertion_rule.dart';
import '../../services/assertion/assertion_engine.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_controls.dart';
import '../common/app_popup_menu.dart';
import '../common/app_text_field.dart';
import '../common/variable_highlight_controller.dart';
import '../ai/generate_assertions_dialog.dart';

/// 断言展示名（编辑页签 / Tests 页签共用，F4.1）
class AssertionLabels {
  AssertionLabels._();

  static Map<AssertionTarget, String> get target => {
        AssertionTarget.status: L10nBridge.t.assertion_targetStatus,
        AssertionTarget.header: L10nBridge.t.assertion_targetHeader,
        AssertionTarget.body: L10nBridge.t.assertion_targetBody,
        AssertionTarget.jsonPath: L10nBridge.t.assertion_targetJsonPath,
        AssertionTarget.responseTime: L10nBridge.t.assertion_targetResponseTime,
      };

  /// 与原型一致：单词操作符用文案，比较操作用符号
  static const Map<AssertionOperator, String> operator = {
    AssertionOperator.equals: 'equals',
    AssertionOperator.notEquals: 'not equals',
    AssertionOperator.contains: 'contains',
    AssertionOperator.notContains: 'not contains',
    AssertionOperator.exists: 'exists',
    AssertionOperator.notExists: 'not exists',
    AssertionOperator.matches: 'regex',
    AssertionOperator.lt: '<',
    AssertionOperator.lte: '≤',
    AssertionOperator.gt: '>',
    AssertionOperator.gte: '≥',
  };
}

/// 断言编辑器（F4.1）
///
/// 请求编辑器的 Assertions 页签，按 UI 原型
/// `docs/design/assertions_preview.html` 画板 A 实现：
/// - 表头 [空 | TARGET | NAME / PATH | OPERATOR | EXPECTED | 空]
/// - 每行 = 启用 checkbox + Target 下拉 + Name/Path 输入 + Operator 下拉 +
///   Expected 输入 + 删除按钮；禁用行整体 55% 透明度
/// - Target 切到 Header / JSONPath 才显示 Name/Path 输入，其余目标显示
///   "—" 占位；exists / notExists 时 Expected 列同样占位
/// - 操作符下拉只列 `AssertionEngine.operatorsByTarget[target]`
///
/// 所有编辑通过 [onChanged] 即时回写（与 Pre-request 链编辑器同模式），
/// 由宿主负责持久化。
class AssertionEditor extends StatefulWidget {
  const AssertionEditor({
    super.key,
    required this.assertions,
    required this.onChanged,
  });

  final List<AssertionRule> assertions;
  final ValueChanged<List<AssertionRule>> onChanged;

  @override
  State<AssertionEditor> createState() => _AssertionEditorState();
}

class _AssertionEditorState extends State<AssertionEditor> {
  // 输入框 controller 缓存（key = rule.id）
  final Map<String, TextEditingController> _argControllers = {};
  final Map<String, VariableHighlightController> _expectedControllers = {};

  @override
  void dispose() {
    for (final c in _argControllers.values) {
      c.dispose();
    }
    for (final c in _expectedControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 页首：标题 + 副文案 + Add 按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppMetrics.space16,
            AppMetrics.space12,
            AppMetrics.space16,
            AppMetrics.space8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.assertion_title,
                      style: AppTextStyles.body13.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppMetrics.space4),
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.tiny11.copyWith(
                          color: t.textTertiary,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: context.l10n.assertion_noteEvaluated),
                          TextSpan(
                              text: context.l10n.assertion_noteExpectedPrefix),
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _InlineCode('{{var}}'),
                          ),
                          TextSpan(
                              text: context.l10n.assertion_noteExpectedSuffix),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppMetrics.space12),
              // F4.2：AI 生成断言入口（基于最近一次响应，确认后追加）
              GenerateAssertionsButton(
                onConfirm: (rules) =>
                    widget.onChanged([...widget.assertions, ...rules]),
              ),
              const SizedBox(width: AppMetrics.space8),
              AppButton.secondary(
                label: context.l10n.assertion_add,
                icon: Icons.add,
                size: AppButtonSize.small,
                onPressed: _addAssertion,
              ),
            ],
          ),
        ),

        // 表格
        if (widget.assertions.isEmpty)
          const Expanded(child: _EmptyState())
        else ...[
          _buildGridHead(context),
          Expanded(
            child: ListView.builder(
              itemCount: widget.assertions.length,
              itemBuilder: (context, index) =>
                  _buildRow(context, widget.assertions[index], index),
            ),
          ),
        ],

        // 底部 hint
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppMetrics.space16,
            AppMetrics.space12,
            AppMetrics.space16,
            AppMetrics.space16,
          ),
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.tiny11.copyWith(
                color: t.textTertiary,
                height: 1.5,
              ),
              children: [
                TextSpan(text: context.l10n.assertion_hintPrefix),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _InlineCode('exists'),
                ),
                TextSpan(text: context.l10n.assertion_hintNoExpected),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _InlineCode('< >'),
                ),
                TextSpan(
                  text: context.l10n.assertion_hintComparison,
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),
          const SizedBox(width: AppMetrics.space8),
          headCell(context.l10n.assertion_colTarget, width: 128),
          const SizedBox(width: AppMetrics.space8),
          headCell(context.l10n.assertion_colNamePath, width: 160),
          const SizedBox(width: AppMetrics.space8),
          headCell(context.l10n.assertion_colOperator, width: 128),
          const SizedBox(width: AppMetrics.space8),
          headCell(context.l10n.assertion_colExpected),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AssertionRule rule, int index) {
    final t = context.appTheme;
    final operators = AssertionEngine.operatorsByTarget[rule.target] ??
        const <AssertionOperator>[];
    final effectiveOperator =
        operators.contains(rule.operator) ? rule.operator : operators.first;
    final showArg = AssertionEngine.needsTargetArg(rule.target);
    final showExpected = AssertionEngine.needsExpected(effectiveOperator);

    final argController = _argControllers.putIfAbsent(
      rule.id,
      () => TextEditingController(text: rule.targetArg),
    );
    if (argController.text != rule.targetArg) {
      argController.text = rule.targetArg;
    }
    final expectedController = _expectedControllers.putIfAbsent(
      rule.id,
      () => VariableHighlightController()
        ..text = rule.expected
        ..appTheme = t,
    );
    if (expectedController.text != rule.expected) {
      expectedController.text = rule.expected;
    }

    void commit(AssertionRule updated) {
      final list = [...widget.assertions];
      list[index] = updated;
      widget.onChanged(list);
    }

    return Opacity(
      key: Key('assertion_row_${rule.id}'),
      opacity: rule.enabled ? 1 : 0.55,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.border)),
        ),
        child: Row(
          children: [
            // 启用开关
            SizedBox(
              width: 28,
              child: Center(
                child: AppCheckbox(
                  value: rule.enabled,
                  onChanged: (v) => commit(rule.copyWith(enabled: v)),
                ),
              ),
            ),
            const SizedBox(width: AppMetrics.space8),
            // Target
            SizedBox(
              width: 128,
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
                  // 操作符按目标过滤：不兼容时回退到该目标的第一个操作符
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
            // Name / Path（仅 header / jsonPath 可编辑）
            SizedBox(
              width: 160,
              child: showArg
                  ? AppTextField(
                      controller: argController,
                      compact: true,
                      hintText: rule.target == AssertionTarget.header
                          ? context.l10n.assertion_headerNameHint
                          : r'$.data.token',
                      onChanged: (_) =>
                          commit(rule.copyWith(targetArg: argController.text)),
                    )
                  : KeyedSubtree(
                      key: Key('assertion_arg_dash_${rule.id}'),
                      child: const _DashCell(),
                    ),
            ),
            const SizedBox(width: AppMetrics.space8),
            // Operator（按目标过滤）
            SizedBox(
              width: 128,
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
            // Expected（exists / notExists 不需要）
            Expanded(
              child: showExpected
                  ? AppTextField(
                      controller: expectedController,
                      compact: true,
                      hintText: context.l10n.assertion_expectedHint,
                      onChanged: (_) => commit(
                        rule.copyWith(expected: expectedController.text),
                      ),
                    )
                  : KeyedSubtree(
                      key: Key('assertion_expected_dash_${rule.id}'),
                      child: const _DashCell(),
                    ),
            ),
            const SizedBox(width: AppMetrics.space8),
            // 删除
            AppIconButton(
              icon: Icons.close,
              tooltip: context.l10n.common_delete,
              danger: true,
              size: 24,
              iconSize: 13,
              onPressed: () {
                _argControllers.remove(rule.id)?.dispose();
                _expectedControllers.remove(rule.id)?.dispose();
                widget.onChanged([...widget.assertions]..removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addAssertion() {
    widget.onChanged([
      ...widget.assertions,
      AssertionRule(id: const Uuid().v4()),
    ]);
  }
}

/// 行内代码片（副文案 / hint 里的 `{{var}}`、`exists` 等）
class _InlineCode extends StatelessWidget {
  const _InlineCode(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: AppMetrics.br4,
      ),
      child: Text(
        text,
        style: AppTextStyles.micro10.copyWith(color: t.textSecondary),
      ),
    );
  }
}

/// "—" 占位单元格（目标参数 / 期望值不适用的禁用态）
class _DashCell extends StatelessWidget {
  const _DashCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppMetrics.height28,
      alignment: Alignment.center,
      child: Text(
        '—',
        style: AppTextStyles.caption12.copyWith(
          color: context.appTheme.textTertiary,
        ),
      ),
    );
  }
}

/// 空态：暂无断言
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 24, color: t.textTertiary),
          const SizedBox(height: AppMetrics.space8),
          Text(
            context.l10n.assertion_emptyTitle,
            style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppMetrics.space4),
          Text(
            context.l10n.assertion_emptySubtitle,
            style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}
