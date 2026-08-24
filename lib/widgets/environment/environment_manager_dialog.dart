import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/environment.dart';
import '../../providers/providers.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_controls.dart';
import '../common/app_dialog.dart';
import '../common/app_divider.dart';
import '../common/app_popup_menu.dart';
import '../common/app_text_field.dart';

/// 打开环境管理对话框
Future<void> showEnvironmentManagerDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const EnvironmentManagerDialog(),
  );
}

/// 环境管理对话框
///
/// 管理 Environments 和全局变量（Globals）：
/// - 左侧：环境列表（当前激活环境带绿点）+ 底部固定的 Globals 入口
/// - 右侧：行内可编辑名称 + 变量表格（启用开关、key、value、类型徽章、删除）
///
/// 布局与视觉规格见 docs/design/environment_manager_preview.html。
/// 编辑在本地工作副本上进行，点击 Save 后一次性持久化。
class EnvironmentManagerDialog extends ConsumerStatefulWidget {
  const EnvironmentManagerDialog({super.key});

  @override
  ConsumerState<EnvironmentManagerDialog> createState() =>
      _EnvironmentManagerDialogState();
}

class _EnvironmentManagerDialogState
    extends ConsumerState<EnvironmentManagerDialog> {
  static const String _globalsId = '__globals__';

  /// 工作副本
  List<Environment> _environments = [];
  List<EnvironmentVariable> _globals = [];
  final Set<String> _deletedIds = {};

  String _selectedId = _globalsId;

  final _nameController = TextEditingController();
  final Map<String, TextEditingController> _keyControllers = {};
  final Map<String, TextEditingController> _valueControllers = {};

  /// 已取消掩码显示的 secret 变量 ID
  final Set<String> _revealedSecretIds = {};

  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// 环境数据到达后初始化工作副本（只执行一次）
  void _tryInitialize(AsyncValue<List<Environment>> environmentsAsync) {
    if (_initialized) return;
    final environments = environmentsAsync.valueOrNull;
    if (environments == null) return;
    _initialized = true;

    _environments = List.of(environments);
    _globals = List.of(ref.read(globalVariablesProvider));

    if (_environments.isNotEmpty) {
      _selectedId = _environments.first.id;
    }
    _syncNameController();
  }

  Environment? get _selectedEnvironment {
    for (final env in _environments) {
      if (env.id == _selectedId) return env;
    }
    return null;
  }

  List<EnvironmentVariable> get _selectedVariables =>
      _selectedEnvironment?.variables ?? _globals;

  void _syncNameController() {
    _nameController.text = _selectedEnvironment?.name ?? 'Globals';
  }

  TextEditingController _keyController(EnvironmentVariable variable) {
    return _keyControllers.putIfAbsent(
      variable.id,
      () => TextEditingController(text: variable.key),
    );
  }

  TextEditingController _valueController(EnvironmentVariable variable) {
    return _valueControllers.putIfAbsent(
      variable.id,
      () => TextEditingController(text: variable.value),
    );
  }

  /// 更新选中作用域中的某个变量
  void _updateVariable(EnvironmentVariable updated) {
    setState(() {
      final env = _selectedEnvironment;
      if (env != null) {
        final index = env.variables.indexWhere((v) => v.id == updated.id);
        if (index != -1) {
          final variables = List<EnvironmentVariable>.of(env.variables);
          variables[index] = updated;
          _environments = [
            for (final e in _environments)
              if (e.id == env.id) e.copyWith(variables: variables) else e,
          ];
        }
      } else {
        final index = _globals.indexWhere((v) => v.id == updated.id);
        if (index != -1) {
          _globals = List.of(_globals)..[index] = updated;
        }
      }
    });
  }

  void _addVariable() {
    final variable = EnvironmentVariable.empty();
    setState(() {
      final env = _selectedEnvironment;
      if (env != null) {
        _environments = [
          for (final e in _environments)
            if (e.id == env.id)
              e.copyWith(variables: [...e.variables, variable])
            else
              e,
        ];
      } else {
        _globals = [..._globals, variable];
      }
    });
  }

  void _removeVariable(String id) {
    setState(() {
      _keyControllers.remove(id)?.dispose();
      _valueControllers.remove(id)?.dispose();
      _revealedSecretIds.remove(id);

      final env = _selectedEnvironment;
      if (env != null) {
        _environments = [
          for (final e in _environments)
            if (e.id == env.id)
              e.copyWith(
                variables: e.variables.where((v) => v.id != id).toList(),
              )
            else
              e,
        ];
      } else {
        _globals = _globals.where((v) => v.id != id).toList();
      }
    });
  }

  void _addEnvironment() {
    final environment = Environment.empty();
    setState(() {
      _environments = [..._environments, environment];
      _selectedId = environment.id;
      _syncNameController();
    });
  }

  void _deleteSelectedEnvironment() {
    final env = _selectedEnvironment;
    if (env == null) return;

    setState(() {
      _deletedIds.add(env.id);
      _environments = _environments.where((e) => e.id != env.id).toList();
      _selectedId =
          _environments.isNotEmpty ? _environments.first.id : _globalsId;
      _syncNameController();
    });
  }

  void _toggleSecretRevealed(String id) {
    setState(() {
      if (_revealedSecretIds.contains(id)) {
        _revealedSecretIds.remove(id);
      } else {
        _revealedSecretIds.add(id);
      }
    });
  }

  Future<void> _save() async {
    // 名称可能尚未触发 onChanged（例如直接点 Save），这里兜底同步
    final env = _selectedEnvironment;
    if (env != null && _nameController.text.trim().isNotEmpty) {
      _environments = [
        for (final e in _environments)
          if (e.id == env.id)
            e.copyWith(name: _nameController.text.trim())
          else
            e,
      ];
    }

    final notifier = ref.read(environmentProvider.notifier);
    for (final id in _deletedIds) {
      await notifier.deleteEnvironment(id);
    }
    for (final environment in _environments) {
      // 过滤掉 key 为空的变量行
      final cleaned = environment.copyWith(
        variables: environment.variables
            .where((v) => v.key.trim().isNotEmpty)
            .toList(),
      );
      await notifier.saveEnvironment(cleaned);
    }
    await ref.read(globalVariablesProvider.notifier).setVariables(
          _globals.where((v) => v.key.trim().isNotEmpty).toList(),
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final environmentsAsync = ref.watch(environmentProvider);
    _tryInitialize(environmentsAsync);

    final t = context.appTheme;

    if (!_initialized) {
      return const Dialog(
        child: SizedBox(
          width: 840,
          height: 560,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return AppDialog(
      key: const Key('environment_manager_dialog'),
      title: 'Manage Environments',
      width: 840,
      height: 560,
      contentPadding: EdgeInsets.zero,
      showDividers: true,
      footerLeading: Text(
        'Reference variables as {{key}} in URL, headers and body · secret values are write-only',
        style: AppTextStyles.tiny11.copyWith(
          color: t.textTertiary,
          fontWeight: FontWeight.w400,
        ),
      ),
      actions: [
        AppButton.ghost(
          key: const Key('environment_dialog_cancel_button'),
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          key: const Key('environment_dialog_save_button'),
          label: 'Save',
          onPressed: _save,
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidePanel(t),
          const AppDivider.vertical(),
          Expanded(child: _buildEditor(t)),
        ],
      ),
    );
  }

  /// 左侧环境列表
  Widget _buildSidePanel(AppThemeData t) {
    final activeId = ref.watch(activeEnvironmentIdProvider);

    return Container(
      width: 224,
      color: t.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppMetrics.space8,
                AppMetrics.space12,
                AppMetrics.space8,
                AppMetrics.space8,
              ),
              children: [
                const _SideLabel('ENVIRONMENTS'),
                for (final env in _environments)
                  _SideItem(
                    key: Key('environment_entry_${env.id}'),
                    icon: Icons.layers_outlined,
                    label: env.name,
                    selected: _selectedId == env.id,
                    showActiveDot: env.id == activeId,
                    onTap: () {
                      setState(() {
                        _selectedId = env.id;
                        _syncNameController();
                      });
                    },
                  ),
                _SideItem(
                  key: const Key('new_environment_button'),
                  icon: Icons.add,
                  label: 'New Environment',
                  ghost: true,
                  onTap: _addEnvironment,
                ),
              ],
            ),
          ),
          const AppDivider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppMetrics.space8,
              AppMetrics.space8,
              AppMetrics.space8,
              0,
            ),
            child: _SideLabel('SHARED'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppMetrics.space8,
              0,
              AppMetrics.space8,
              AppMetrics.space8,
            ),
            child: _SideItem(
              key: const Key('globals_entry'),
              icon: Icons.public,
              label: 'Globals',
              selected: _selectedId == _globalsId,
              onTap: () {
                setState(() {
                  _selectedId = _globalsId;
                  _syncNameController();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 右侧编辑器
  Widget _buildEditor(AppThemeData t) {
    final env = _selectedEnvironment;
    final variables = _selectedVariables;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 名称行：行内可编辑标题（Globals 只读）+ 删除环境
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppMetrics.space24,
            AppMetrics.space16,
            AppMetrics.space16,
            AppMetrics.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: env != null
                        ? AppTextField(
                            fieldKey: const Key('environment_name_field'),
                            controller: _nameController,
                            borderless: true,
                            hintText: 'Name',
                            style: AppTextStyles.title16,
                            onChanged: (value) {
                              setState(() {
                                _environments = [
                                  for (final e in _environments)
                                    if (e.id == env.id)
                                      e.copyWith(name: value)
                                    else
                                      e,
                                ];
                              });
                            },
                          )
                        : SizedBox(
                            height: AppMetrics.height32,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppMetrics.space12 - 2,
                                ),
                                child: Text(
                                  'Globals',
                                  style: AppTextStyles.title16
                                      .copyWith(color: t.textPrimary),
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (env != null) ...[
                    const SizedBox(width: AppMetrics.space8),
                    AppIconButton(
                      key: const Key('delete_environment_button'),
                      icon: Icons.delete_outline,
                      tooltip: 'Delete environment',
                      danger: true,
                      onPressed: _deleteSelectedEnvironment,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppMetrics.space4),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppMetrics.space12 - 2,
                ),
                child: Text(
                  env != null
                      ? '${variables.length} variables · referenced as {{key}}'
                      : 'Shared across all environments · overridden by environment variables',
                  style: AppTextStyles.caption12.copyWith(
                    color: t.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 变量表格 / 空状态
        Expanded(
          child: variables.isEmpty
              ? _buildEmptyState(t, isGlobals: env == null)
              : _buildVariableTable(t, variables),
        ),
      ],
    );
  }

  /// 空状态：居中引导 + 主按钮
  Widget _buildEmptyState(AppThemeData t, {required bool isGlobals}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGlobals ? Icons.public : Icons.layers_outlined,
              size: 19,
              color: t.textTertiary,
            ),
          ),
          const SizedBox(height: AppMetrics.space12),
          Text(
            'No variables yet',
            style: AppTextStyles.body13.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppMetrics.space4),
          Text(
            'Add one and reference it as {{key}}',
            style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppMetrics.space16),
          AppButton.primary(
            key: const Key('add_variable_button'),
            label: 'Add Variable',
            icon: Icons.add,
            size: AppButtonSize.small,
            onPressed: _addVariable,
          ),
        ],
      ),
    );
  }

  /// 变量表格：表头 + 行列表 + 虚线添加行
  Widget _buildVariableTable(
      AppThemeData t, List<EnvironmentVariable> variables) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space24),
      children: [
        // 表头
        Container(
          height: AppMetrics.height28,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.border)),
          ),
          child: Row(
            children: [
              const SizedBox(width: AppMetrics.height28),
              _buildHeaderCell(t, 'KEY', flex: 3),
              _buildHeaderCell(t, 'VALUE', flex: 4),
              _buildHeaderCell(t, 'TYPE', width: 108),
              const SizedBox(width: AppMetrics.height28),
            ],
          ),
        ),
        for (final variable in variables)
          VariableRow(
            key: Key('variable_row_${variable.id}'),
            variable: variable,
            keyController: _keyController(variable),
            valueController: _valueController(variable),
            secretRevealed: _revealedSecretIds.contains(variable.id),
            onChanged: _updateVariable,
            onRemove: () => _removeVariable(variable.id),
            onToggleSecretRevealed: () => _toggleSecretRevealed(variable.id),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppMetrics.space8),
          child: _AddVariableRow(
            key: const Key('add_variable_button'),
            onTap: _addVariable,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(
    AppThemeData t,
    String text, {
    int flex = 1,
    double? width,
  }) {
    // 与行内单元格文字左缘对齐（cell padding 4 + 输入框内 padding 10）
    final label = Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Text(
        text,
        style: AppTextStyles.micro10.copyWith(
          color: t.textTertiary,
          letterSpacing: 0.6,
        ),
      ),
    );
    if (width != null) {
      return SizedBox(width: width, child: label);
    }
    return Expanded(flex: flex, child: label);
  }
}

/// 侧栏分组标签（10px 大写）
class _SideLabel extends StatelessWidget {
  const _SideLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, AppMetrics.space4),
      child: Text(
        text,
        style: AppTextStyles.micro10.copyWith(
          color: t.textTertiary,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

/// 侧栏条目：环境 / Globals / New Environment（32px 行）
///
/// 选中态 brandSoft 底 + brand 文字；[showActiveDot] 显示当前激活绿点；
/// [ghost] 为次级动作样式（New Environment）。
class _SideItem extends StatefulWidget {
  const _SideItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.showActiveDot = false,
    this.ghost = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool showActiveDot;
  final bool ghost;

  @override
  State<_SideItem> createState() => _SideItemState();
}

class _SideItemState extends State<_SideItem> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    final Color background;
    final Color foreground;
    final Color iconColor;
    if (widget.selected) {
      background = t.brandSoft;
      foreground = t.brand;
      iconColor = t.brand;
    } else if (widget.ghost) {
      background = _hovering ? t.surfaceVariant : t.surface;
      foreground = _hovering ? t.textPrimary : t.textSecondary;
      iconColor = _hovering ? t.textPrimary : t.textSecondary;
    } else {
      background = _hovering ? t.surfaceVariant : t.surface;
      foreground = t.textPrimary;
      iconColor = t.textTertiary;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMetrics.animFast,
          height: AppMetrics.height32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppMetrics.br6,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 13, color: iconColor),
              const SizedBox(width: AppMetrics.space8),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTextStyles.body13.copyWith(
                    color: foreground,
                    fontWeight:
                        widget.ghost ? FontWeight.w400 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.showActiveDot)
                Container(
                  key: const Key('active_env_dot'),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: t.success,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 变量表格行：启用勾选 + Key/Value 无边框输入 + 类型徽章 + hover 删除
class VariableRow extends StatefulWidget {
  const VariableRow({
    super.key,
    required this.variable,
    required this.keyController,
    required this.valueController,
    required this.secretRevealed,
    required this.onChanged,
    required this.onRemove,
    required this.onToggleSecretRevealed,
  });

  final EnvironmentVariable variable;
  final TextEditingController keyController;
  final TextEditingController valueController;
  final bool secretRevealed;
  final ValueChanged<EnvironmentVariable> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onToggleSecretRevealed;

  @override
  State<VariableRow> createState() => _VariableRowState();
}

class _VariableRowState extends State<VariableRow> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final variable = widget.variable;
    final isSecret = variable.isSecret;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _hovering ? t.surface : null,
          border: Border(bottom: BorderSide(color: t.border)),
        ),
        child: Row(
          children: [
            // 启用勾选
            SizedBox(
              width: AppMetrics.height28,
              child: Center(
                child: AppCheckbox(
                  value: variable.enabled,
                  onChanged: (value) =>
                      widget.onChanged(variable.copyWith(enabled: value)),
                ),
              ),
            ),
            // Key
            Expanded(
              flex: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppMetrics.space4),
                child: AppTextField(
                  compact: true,
                  borderless: true,
                  controller: widget.keyController,
                  hintText: 'Key',
                  style: AppTextStyles.code12,
                  onChanged: (value) =>
                      widget.onChanged(variable.copyWith(key: value)),
                ),
              ),
            ),
            // Value
            Expanded(
              flex: 4,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppMetrics.space4),
                child: _buildValueField(t, isSecret),
              ),
            ),
            // Type 徽章选择
            SizedBox(
              width: 108,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppMetrics.space4),
                  child: TypePillSelect(
                    key: Key('variable_type_pill_${variable.id}'),
                    value: variable.type,
                    onSelected: (type) =>
                        widget.onChanged(variable.copyWith(type: type)),
                  ),
                ),
              ),
            ),
            // 删除按钮（hover 才显示）
            SizedBox(
              width: AppMetrics.height28,
              child: _hovering
                  ? Center(
                      child: AppIconButton(
                        icon: Icons.close,
                        tooltip: 'Remove variable',
                        size: AppMetrics.height24,
                        iconSize: 14,
                        onPressed: widget.onRemove,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Value 输入框：secret 类型内嵌显隐切换按钮（AppTextField suffix）
  Widget _buildValueField(AppThemeData t, bool isSecret) {
    final variable = widget.variable;
    if (!isSecret) {
      return AppTextField(
        compact: true,
        borderless: true,
        controller: widget.valueController,
        hintText: 'Value',
        style: AppTextStyles.code12,
        onChanged: (value) => widget.onChanged(variable.copyWith(value: value)),
      );
    }
    return AppTextField(
      compact: true,
      borderless: true,
      controller: widget.valueController,
      obscureText: !widget.secretRevealed,
      hintText: 'Value',
      style: AppTextStyles.code12,
      suffix: AppIconButton(
        icon: widget.secretRevealed ? Icons.visibility_off : Icons.visibility,
        tooltip: widget.secretRevealed ? 'Hide value' : 'Show value',
        size: AppMetrics.height24,
        iconSize: 14,
        onPressed: widget.onToggleSecretRevealed,
      ),
      onChanged: (value) => widget.onChanged(variable.copyWith(value: value)),
    );
  }
}

/// 变量类型徽章选择器：string = 中性徽章，secret = 琥珀徽章（warning-soft）
///
/// 触发器为徽章样式，弹出菜单复用 [AppPopupMenu] 统一容器与菜单项。
class TypePillSelect extends StatelessWidget {
  const TypePillSelect({
    super.key,
    required this.value,
    required this.onSelected,
  });

  final VariableType value;
  final ValueChanged<VariableType> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final theme = Theme.of(context);
    final isSecret = value == VariableType.secret;

    final background = isSecret ? t.warningSoft : t.surfaceVariant;
    final foreground = isSecret ? t.warning : t.textSecondary;

    return PopupMenuButton<VariableType>(
      tooltip: '',
      offset: const Offset(0, 26),
      shape: AppPopupMenu.menuShape(theme),
      elevation: AppPopupMenu.menuElevation,
      color: AppPopupMenu.menuColor(theme),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final type in VariableType.values)
          AppPopupMenu.textItem(
            theme: theme,
            value: type,
            label: type == VariableType.secret ? 'secret' : 'string',
            selected: type == value,
          ),
      ],
      child: Container(
        height: AppMetrics.height24,
        padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppMetrics.br4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSecret) ...[
              Icon(Icons.lock_outline, size: 11, color: foreground),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                isSecret ? 'secret' : 'string',
                style: AppTextStyles.code11.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: foreground),
          ],
        ),
      ),
    );
  }
}

/// 虚线边框的「Add Variable」行
class _AddVariableRow extends StatefulWidget {
  const _AddVariableRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AddVariableRow> createState() => _AddVariableRowState();
}

class _AddVariableRowState extends State<_AddVariableRow> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final borderColor = _hovering ? t.brand : t.borderStrong;
    final foreground = _hovering ? t.brand : t.textTertiary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: CustomPaint(
          painter: _DashedRectPainter(color: borderColor),
          child: AnimatedContainer(
            duration: AppMetrics.animFast,
            height: AppMetrics.height36,
            decoration: BoxDecoration(
              color: _hovering ? t.brandSoft : null,
              borderRadius: AppMetrics.br6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 14, color: foreground),
                const SizedBox(width: 6),
                Text(
                  'Add Variable',
                  style: AppTextStyles.caption12.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 圆角虚线矩形描边
class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppMetrics.radius6),
        ),
      );
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dash;
        canvas.drawPath(
          metric.extractPath(
            distance,
            end > metric.length ? metric.length : end,
          ),
          paint,
        );
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
