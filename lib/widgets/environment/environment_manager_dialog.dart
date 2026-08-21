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
/// - 左侧：环境列表 + Globals 入口，支持新建/删除环境
/// - 右侧：选中环境的名称与变量表格（启用开关、key、value、类型、删除）
///
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
          width: 760,
          height: 520,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return AppDialog(
      key: const Key('environment_manager_dialog'),
      title: 'Manage Environments',
      width: 760,
      height: 520,
      contentPadding: EdgeInsets.zero,
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
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (final env in _environments) _buildEnvTile(t, env),
                const AppDivider(),
                ListTile(
                  key: const Key('globals_entry'),
                  dense: true,
                  selected: _selectedId == _globalsId,
                  leading: const Icon(Icons.public, size: 16),
                  title: const Text('Globals', style: AppTextStyles.body13),
                  onTap: () {
                    setState(() {
                      _selectedId = _globalsId;
                      _syncNameController();
                    });
                  },
                ),
              ],
            ),
          ),
          const AppDivider(),
          Padding(
            padding: const EdgeInsets.all(AppMetrics.space8),
            child: SizedBox(
              width: double.infinity,
              child: AppButton.secondary(
                key: const Key('new_environment_button'),
                label: 'New',
                icon: Icons.add,
                size: AppButtonSize.small,
                onPressed: _addEnvironment,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvTile(AppThemeData t, Environment env) {
    return ListTile(
      key: Key('environment_entry_${env.id}'),
      dense: true,
      selected: _selectedId == env.id,
      leading: Icon(Icons.layers_outlined, size: 16, color: t.textTertiary),
      title: Text(
        env.name,
        style: AppTextStyles.body13,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        setState(() {
          _selectedId = env.id;
          _syncNameController();
        });
      },
    );
  }

  /// 右侧编辑器
  Widget _buildEditor(AppThemeData t) {
    final env = _selectedEnvironment;
    final variables = _selectedVariables;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 名称行
        Padding(
          padding: const EdgeInsets.all(AppMetrics.space16),
          child: Row(
            children: [
              Expanded(
                // 测试按 key 定位 TextField，key 须挂在裸 TextField 上，
                // 且需要 enabled 支持，故不换成 AppTextField
                child: TextField(
                  key: const Key('environment_name_field'),
                  controller: _nameController,
                  enabled: env != null,
                  style: AppTextStyles.body13.copyWith(color: t.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    isDense: true,
                  ),
                  onChanged: (value) {
                    if (env == null) return;
                    setState(() {
                      _environments = [
                        for (final e in _environments)
                          if (e.id == env.id) e.copyWith(name: value) else e,
                      ];
                    });
                  },
                ),
              ),
              if (env != null) ...[
                const SizedBox(width: AppMetrics.space8),
                AppIconButton(
                  key: const Key('delete_environment_button'),
                  icon: Icons.delete_outline,
                  tooltip: 'Delete environment',
                  color: t.error,
                  onPressed: _deleteSelectedEnvironment,
                ),
              ],
            ],
          ),
        ),
        // 变量表头
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space16),
          child: Row(
            children: [
              const SizedBox(width: 32),
              _buildHeaderCell(t, 'Key', flex: 3),
              _buildHeaderCell(t, 'Value', flex: 4),
              _buildHeaderCell(t, 'Type', flex: 2),
              const SizedBox(width: 64),
            ],
          ),
        ),
        const SizedBox(height: AppMetrics.space4),
        // 变量列表
        Expanded(
          child: variables.isEmpty
              ? Center(
                  child: Text(
                    'No variables yet',
                    style:
                        AppTextStyles.caption12.copyWith(color: t.textTertiary),
                  ),
                )
              : ListView.builder(
                  itemCount: variables.length,
                  itemBuilder: (context, index) =>
                      _buildVariableRow(t, variables[index]),
                ),
        ),
        // 添加变量按钮
        Padding(
          padding: const EdgeInsets.all(AppMetrics.space16),
          child: AppButton.secondary(
            key: const Key('add_variable_button'),
            label: 'Add Variable',
            icon: Icons.add,
            size: AppButtonSize.small,
            onPressed: _addVariable,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(AppThemeData t, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTextStyles.tiny11.copyWith(
          fontWeight: FontWeight.w600,
          color: t.textTertiary,
        ),
      ),
    );
  }

  Widget _buildVariableRow(AppThemeData t, EnvironmentVariable variable) {
    final isSecret = variable.isSecret;
    final revealed = _revealedSecretIds.contains(variable.id);

    return Padding(
      key: Key('variable_row_${variable.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.space16,
        vertical: 2,
      ),
      child: Row(
        children: [
          // 启用勾选
          SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: AppCheckbox(
                value: variable.enabled,
                onChanged: (value) =>
                    _updateVariable(variable.copyWith(enabled: value)),
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
                controller: _keyController(variable),
                hintText: 'Key',
                onChanged: (value) =>
                    _updateVariable(variable.copyWith(key: value)),
              ),
            ),
          ),
          // Value
          Expanded(
            flex: 4,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppMetrics.space4),
              child: _buildValueField(t, variable, isSecret, revealed),
            ),
          ),
          // Type（统一样式的弹出选择器）
          Expanded(
            flex: 2,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppMetrics.space4),
              child: AppPopupSelect<VariableType>(
                value: variable.type,
                items: const [
                  AppPopupSelectEntry(
                    value: VariableType.string,
                    label: 'string',
                  ),
                  AppPopupSelectEntry(
                    value: VariableType.secret,
                    label: 'secret',
                  ),
                ],
                onSelected: (type) =>
                    _updateVariable(variable.copyWith(type: type)),
              ),
            ),
          ),
          // 删除按钮
          SizedBox(
            width: 64,
            child: Center(
              child: AppIconButton(
                icon: Icons.close,
                tooltip: 'Remove variable',
                onPressed: () => _removeVariable(variable.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Value 输入框：secret 类型需要内嵌显隐切换按钮，
  /// AppTextField 不支持 suffixIcon，退回裸 TextField + 统一装饰
  Widget _buildValueField(
    AppThemeData t,
    EnvironmentVariable variable,
    bool isSecret,
    bool revealed,
  ) {
    if (!isSecret) {
      return AppTextField(
        compact: true,
        controller: _valueController(variable),
        hintText: 'Value',
        onChanged: (value) => _updateVariable(variable.copyWith(value: value)),
      );
    }
    return SizedBox(
      height: AppMetrics.height28,
      child: TextField(
        controller: _valueController(variable),
        obscureText: !revealed,
        style: AppTextStyles.caption12.copyWith(color: t.textPrimary),
        decoration:
            AppTextField.decoration(context, hintText: 'Value', compact: true)
                .copyWith(
          suffixIconConstraints:
              const BoxConstraints(minWidth: 24, minHeight: 24),
          suffixIcon: AppIconButton(
            icon: revealed ? Icons.visibility_off : Icons.visibility,
            tooltip: revealed ? 'Hide value' : 'Show value',
            size: AppMetrics.height24,
            iconSize: 14,
            onPressed: () {
              setState(() {
                if (revealed) {
                  _revealedSecretIds.remove(variable.id);
                } else {
                  _revealedSecretIds.add(variable.id);
                }
              });
            },
          ),
        ),
        onChanged: (value) => _updateVariable(variable.copyWith(value: value)),
      ),
    );
  }
}
