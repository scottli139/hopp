import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopp/l10n/l10n.dart';

import '../../models/environment.dart';
import '../../providers/providers.dart';
import '../../services/variable_resolver.dart';
import '../../services/variable_transforms.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_popup_menu.dart';
import '../common/app_text_field.dart';

/// KV 值单元格的变量辅助菜单（F8.3）
///
/// 点击值单元格右端的 fx 图标弹出，合并原型中的「悬停解析预览」与
/// 「函数插入菜单」两个能力：
/// - RESOLVED PREVIEW 区：逐条列出文本中的 `{{...}}` 表达式，展示
///   基础值（secret 变量脱敏）→ 各转换步 → 最终结果；未定义 / 转换
///   失败以 error 色标记
/// - INSERT TRANSFORM 区：无参函数直接插入 ` | fn`；带参函数
///   （aes/hmac）先弹参数小表单再插入
///
/// 插入位置为光标处（焦点不在时追加到末尾），插入后通过
/// [onInserted] 通知外层同步 provider。
class VariableFxMenu extends ConsumerWidget {
  const VariableFxMenu({
    super.key,
    required this.controller,
    required this.onInserted,
  });

  final TextEditingController controller;
  final VoidCallback onInserted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.appTheme;
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      tooltip: context.l10n.fx_tooltip,
      iconSize: 16,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 24),
      constraints: const BoxConstraints(minWidth: 380, maxWidth: 420),
      shape: AppPopupMenu.menuShape(theme),
      elevation: AppPopupMenu.menuElevation,
      color: AppPopupMenu.menuColor(theme),
      icon: Icon(Icons.functions, size: 14, color: t.textTertiary),
      onSelected: (value) => _onMenuSelected(context, ref, value),
      itemBuilder: (context) => _buildItems(context, ref),
    );
  }

  List<PopupMenuEntry<String>> _buildItems(
      BuildContext context, WidgetRef ref) {
    final t = context.appTheme;
    final theme = Theme.of(context);
    final items = <PopupMenuEntry<String>>[];

    // ---------- RESOLVED PREVIEW ----------
    final variables = ref.read(resolvedVariablesProvider);
    final resolver = ref.read(variableResolverProvider);
    final expressions = VariableResolver.scanExpressions(controller.text);

    if (expressions.isNotEmpty) {
      items.add(_buildHeader(context, context.l10n.fx_resolvedPreview));
      for (final match in expressions) {
        items.addAll(_buildExpressionPreview(
          context,
          match.expression,
          variables,
          resolver,
          ref,
        ));
      }
      items.add(const PopupMenuDivider(height: 1));
    }

    // ---------- INSERT DYNAMIC VARIABLE ----------
    // ---------- INSERT TRANSFORM ----------
    items
      ..add(_buildHeader(context, context.l10n.fx_insertDynamicVariable))
      ..addAll([
        for (final name in VariableResolver.dynamicVariables)
          _dynamicVariableItem(
            context,
            name,
            VariableResolver.dynamicVariableDescriptions[name] ?? '',
          ),
      ])
      ..add(const PopupMenuDivider(height: 1))
      ..add(_buildHeader(context, context.l10n.fx_insertTransform))
      ..addAll([
        for (final fn in VariableTransforms.noArgFunctions)
          AppPopupMenu.textItem(
            theme: theme,
            value: 'fn:$fn',
            label: fn,
          ),
      ])
      ..add(const PopupMenuDivider(height: 1))
      ..addAll([
        for (final sig in VariableTransforms.parameterizedSignatures)
          AppPopupMenu.textItem(
            theme: theme,
            value: 'fn-param:${sig.substring(0, sig.indexOf('('))}',
            label: sig,
          ),
      ]);

    // 空态提示
    if (expressions.isEmpty) {
      items.insert(
        0,
        PopupMenuItem<String>(
          enabled: false,
          height: 28,
          child: Text(
            context.l10n.fx_emptyHint('{{variable}}'),
            style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
          ),
        ),
      );
    }
    return items;
  }

  /// 动态变量插入项：名字（mono）+ 用途说明（右侧弱化）
  PopupMenuItem<String> _dynamicVariableItem(
    BuildContext context,
    String name,
    String description,
  ) {
    final t = context.appTheme;
    return PopupMenuItem<String>(
      value: 'dyn:$name',
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: AppTextStyles.code11.copyWith(color: t.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 单条表达式的解析预览（基础值 → 逐步转换 → 结果）
  List<PopupMenuEntry<String>> _buildExpressionPreview(
    BuildContext context,
    String expression,
    Map<String, String> variables,
    VariableResolver resolver,
    WidgetRef ref,
  ) {
    final t = context.appTheme;
    final entries = <PopupMenuEntry<String>>[];

    final segments = VariableTransforms.splitPipeline(expression.trim());
    final base = segments.first;

    // 基础值
    String? value;
    if (base.startsWith('\$')) {
      value = resolver.resolveDynamicVariable(base);
    } else {
      value = variables[base];
    }

    // secret 变量脱敏显示基础值
    final isSecret = !base.startsWith('\$') && _isSecretVariable(base, ref);
    final baseDisplay = value == null
        ? context.l10n.fx_undefined
        : (isSecret ? '••••••••' : _truncate(value));

    entries.add(_previewRow(
      context,
      '{{${expression.trim()}}}',
      baseDisplay,
      valueColor: value == null ? t.error : null,
      bold: true,
    ));

    // 逐步转换
    var failed = value == null;
    var current = value ?? '';
    for (final segment in segments.skip(1)) {
      if (failed) break;
      final next = VariableTransforms.applySingle(
        current,
        segment,
        (arg) => resolver.resolve(arg, variables),
      );
      if (next == null) {
        entries.add(_previewRow(
          context,
          '  ↓ $segment',
          context.l10n.fx_transformFailed,
          valueColor: t.error,
        ));
        failed = true;
      } else {
        current = next;
        entries.add(_previewRow(context, '  ↓ $segment', _truncate(next)));
      }
    }

    return entries;
  }

  bool _isSecretVariable(String name, WidgetRef ref) {
    bool secretIn(List<EnvironmentVariable> vars) =>
        vars.any((v) => v.key == name && v.enabled && v.isSecret);
    if (secretIn(ref.read(globalVariablesProvider))) {
      return true;
    }
    final activeEnv = ref.read(activeEnvironmentProvider);
    if (activeEnv != null && secretIn(activeEnv.variables)) {
      return true;
    }
    return false;
  }

  static String _truncate(String value) =>
      value.length <= 48 ? value : '${value.substring(0, 45)}...';

  PopupMenuItem<String> _buildHeader(BuildContext context, String label) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 24,
      child: Text(
        label,
        style: AppTextStyles.micro10.copyWith(
          color: context.appTheme.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  PopupMenuItem<String> _previewRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    final t = context.appTheme;
    return PopupMenuItem<String>(
      enabled: false,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.code11.copyWith(
                color: bold ? t.textPrimary : t.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.code11.copyWith(
                color: valueColor ?? t.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _onMenuSelected(BuildContext context, WidgetRef ref, String value) {
    if (value.startsWith('dyn:')) {
      _insertSnippet('{{${value.substring(4)}}}');
    } else if (value.startsWith('fn:')) {
      _insertSnippet(' | ${value.substring(3)}');
    } else if (value.startsWith('fn-param:')) {
      final fn = value.substring(9);
      // 等菜单关闭后再弹参数表单
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          _showParamDialog(context, fn);
        }
      });
    }
  }

  /// 在光标处插入片段（焦点不在 / 无光标时追加到末尾）
  ///
  /// 两个边界（试用反馈回归，2026-09-01）：
  /// - 非折叠选区：按编辑器惯例**替换**选区，而不是只插在选区起点
  ///   留下原字符（旧实现会产出错位/重复的大括号）
  /// - 管道去重：插入点左侧（跳过空白）已是 `|` 时，剥掉片段的 ` |`
  ///   前缀，避免手输 `|` 后再插入函数出现 `| |`
  void _insertSnippet(String snippet) {
    final text = controller.text;
    final selection = controller.selection;

    var start = text.length;
    var end = text.length;
    if (selection.isValid &&
        selection.baseOffset >= 0 &&
        selection.baseOffset <= text.length) {
      start = selection.start;
      end = selection.start == selection.end ? start : selection.end;
    }

    var effective = snippet;
    if (start == end) {
      // 管道去重：左侧跳过空白后是 | → 复用已有管道
      var left = start - 1;
      while (left >= 0 && text[left] == ' ') {
        left--;
      }
      if (left >= 0 && text[left] == '|' && snippet.startsWith(' |')) {
        effective = snippet.substring(2);
      }
    }

    controller.value = TextEditingValue(
      text: text.substring(0, start) + effective + text.substring(end),
      selection: TextSelection.collapsed(offset: start + effective.length),
    );
    onInserted();
  }

  /// 带参函数的参数小表单（aes / hmac / date_add / date_floor）
  Future<void> _showParamDialog(BuildContext context, String fn) async {
    final signature = VariableTransforms.parameterizedSignatures.firstWhere(
      (s) => s.startsWith('$fn('),
      orElse: () => fn,
    );
    final snippet = await showAppDialog<String>(
      context: context,
      title: signature,
      width: 380,
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: _TransformParamForm(fn: fn),
    );
    if (snippet != null && snippet.isNotEmpty) {
      _insertSnippet(snippet);
    }
  }
}

/// 带参函数参数表单：aes(mode, key, iv[, format]) / hmac(algo, key)
///
/// 参数值支持 `{{var}}` 引用（插入后由解析器在发送前解析）。
/// 底部按钮行内置（取消 / 插入），插入时 pop 组装好的片段。
class _TransformParamForm extends StatefulWidget {
  const _TransformParamForm({required this.fn});

  final String fn;

  @override
  State<_TransformParamForm> createState() => _TransformParamFormState();
}

class _TransformParamFormState extends State<_TransformParamForm> {
  final _keyController = TextEditingController();
  final _ivController = TextEditingController();
  final _offsetController = TextEditingController();
  String _mode = 'cbc';
  String _algo = 'sha256';
  String _format = 'base64';
  String _floorUnit = 'day';

  /// date_add offset 语法（与 VariableTransforms._dateAdd 同源）
  static final _offsetPattern =
      RegExp(r'^[+-]?\d+[smhdw]$', caseSensitive: false);

  bool get _offsetValid =>
      _offsetPattern.hasMatch(_offsetController.text.trim());

  @override
  void dispose() {
    _keyController.dispose();
    _ivController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  /// 组装 ` | fn(args)` 片段
  String buildSnippet() {
    switch (widget.fn) {
      case 'date_add':
        return ' | date_add(${_offsetController.text.trim()})';
      case 'date_floor':
        return ' | date_floor($_floorUnit)';
      case 'aes':
        final key = _keyController.text.trim();
        final iv = _ivController.text.trim();
        final formatSuffix = _format == 'base64' ? '' : ', $_format';
        return ' | aes($_mode, $key, $iv$formatSuffix)';
      default:
        return ' | hmac($_algo, ${_keyController.text.trim()})';
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.fn) {
      case 'date_add':
        return _buildDateAddForm(context);
      case 'date_floor':
        return _buildDateFloorForm(context);
      default:
        return _buildCryptoForm(context);
    }
  }

  /// date_add 参数表单：offset 输入 + 语法校验
  Widget _buildDateAddForm(BuildContext context) {
    final t = context.appTheme;
    final offset = _offsetController.text.trim();
    final showError = offset.isNotEmpty && !_offsetValid;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputRow(
          context,
          label: 'offset',
          controller: _offsetController,
          hint: '-7d / +12h / 30m',
          onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppMetrics.space8),
          child: Text(
            showError
                ? context.l10n.fx_dateAddFormatError
                : context.l10n.fx_dateAddUnitHint,
            style: AppTextStyles.tiny11.copyWith(
              color: showError ? t.error : t.textTertiary,
            ),
          ),
        ),
        _buildActions(context, canInsert: offset.isNotEmpty && _offsetValid),
      ],
    );
  }

  /// date_floor 参数表单：取整单位选择
  Widget _buildDateFloorForm(BuildContext context) {
    final t = context.appTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectRow(
          context,
          label: 'unit',
          value: _floorUnit,
          entries: [
            AppPopupSelectEntry(
                value: 'hour', label: context.l10n.fx_floorHour),
            AppPopupSelectEntry(value: 'day', label: context.l10n.fx_floorDay),
            AppPopupSelectEntry(
                value: 'week', label: context.l10n.fx_floorWeek),
            AppPopupSelectEntry(
                value: 'month', label: context.l10n.fx_floorMonth),
          ],
          onSelected: (v) => setState(() => _floorUnit = v),
        ),
        Text(
          context.l10n.fx_dateFloorHint,
          style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppMetrics.space12),
        _buildActions(context, canInsert: true),
      ],
    );
  }

  /// 底部按钮行（取消 / 插入）
  Widget _buildActions(BuildContext context, {required bool canInsert}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton.ghost(
          label: context.l10n.common_cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppMetrics.space8),
        AppButton.primary(
          label: context.l10n.fx_insert,
          onPressed: canInsert
              ? () => Navigator.of(context).pop(buildSnippet())
              : null,
        ),
      ],
    );
  }

  /// aes / hmac 参数表单（加密类，key 支持 {{var}} 引用）
  Widget _buildCryptoForm(BuildContext context) {
    final t = context.appTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fn == 'aes') ...[
          _buildSelectRow(
            context,
            label: 'mode',
            value: _mode,
            entries: const [
              AppPopupSelectEntry(value: 'cbc', label: 'cbc'),
              AppPopupSelectEntry(value: 'ecb', label: 'ecb'),
            ],
            onSelected: (v) => setState(() => _mode = v),
          ),
          _buildInputRow(
            context,
            label: 'key',
            controller: _keyController,
            hint: context.l10n.fx_aesKeyHint('{{aes_key}}'),
          ),
          _buildInputRow(
            context,
            label: 'iv',
            controller: _ivController,
            hint: context.l10n.fx_aesIvHint('{{aes_iv}}'),
          ),
          _buildSelectRow(
            context,
            label: 'format',
            value: _format,
            entries: const [
              AppPopupSelectEntry(value: 'base64', label: 'base64'),
              AppPopupSelectEntry(value: 'hex', label: 'hex'),
            ],
            onSelected: (v) => setState(() => _format = v),
          ),
        ] else ...[
          _buildSelectRow(
            context,
            label: 'algo',
            value: _algo,
            entries: const [
              AppPopupSelectEntry(value: 'md5', label: 'md5'),
              AppPopupSelectEntry(value: 'sha1', label: 'sha1'),
              AppPopupSelectEntry(value: 'sha256', label: 'sha256'),
            ],
            onSelected: (v) => setState(() => _algo = v),
          ),
          _buildInputRow(
            context,
            label: 'key',
            controller: _keyController,
            hint: '{{app_secret}}',
          ),
        ],
        Text(
          context.l10n.fx_paramVariableHint('{{variable}}'),
          style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppMetrics.space12),
        _buildActions(context, canInsert: true),
      ],
    );
  }

  Widget _buildInputRow(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String? hint,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppMetrics.space8),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: AppTextStyles.caption12.copyWith(
                color: context.appTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: AppTextField(
              controller: controller,
              hintText: hint,
              compact: true,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectRow(
    BuildContext context, {
    required String label,
    required String value,
    required List<AppPopupSelectEntry<String>> entries,
    required ValueChanged<String> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppMetrics.space8),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: AppTextStyles.caption12.copyWith(
                color: context.appTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: AppPopupSelect<String>(
              value: value,
              boxed: true,
              compact: true,
              items: entries,
              onSelected: onSelected,
            ),
          ),
        ],
      ),
    );
  }
}
