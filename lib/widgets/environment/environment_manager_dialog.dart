import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/environment.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';

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

    final theme = Theme.of(context);

    if (!_initialized) {
      return const Dialog(
        child: SizedBox(
          width: 760,
          height: 520,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Dialog(
      key: const Key('environment_manager_dialog'),
      child: SizedBox(
        width: 760,
        height: 520,
        child: Column(
          children: [
            // 标题栏
            Container(
              height: 48,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  Text(
                    'Manage Environments',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 主体
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSidePanel(theme),
                  VerticalDivider(width: 1, color: theme.dividerColor),
                  Expanded(child: _buildEditor(theme)),
                ],
              ),
            ),
            // 底部按钮
            Container(
              height: 52,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('environment_dialog_cancel_button'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppConstants.spaceS),
                  FilledButton(
                    key: const Key('environment_dialog_save_button'),
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 左侧环境列表
  Widget _buildSidePanel(ThemeData theme) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (final env in _environments) _buildEnvTile(theme, env),
                const Divider(height: 1),
                ListTile(
                  key: const Key('globals_entry'),
                  dense: true,
                  selected: _selectedId == _globalsId,
                  leading: const Icon(Icons.public, size: 16),
                  title: const Text('Globals', style: TextStyle(fontSize: 13)),
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spaceS),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('new_environment_button'),
                onPressed: _addEnvironment,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvTile(ThemeData theme, Environment env) {
    return ListTile(
      key: Key('environment_entry_${env.id}'),
      dense: true,
      selected: _selectedId == env.id,
      leading: Icon(Icons.layers_outlined,
          size: 16, color: theme.colorScheme.outline),
      title: Text(
        env.name,
        style: const TextStyle(fontSize: 13),
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
  Widget _buildEditor(ThemeData theme) {
    final env = _selectedEnvironment;
    final variables = _selectedVariables;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 名称行
        Padding(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('environment_name_field'),
                  controller: _nameController,
                  enabled: env != null,
                  style: const TextStyle(fontSize: 13),
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
                const SizedBox(width: AppConstants.spaceS),
                IconButton(
                  key: const Key('delete_environment_button'),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete environment',
                  color: theme.colorScheme.error,
                  onPressed: _deleteSelectedEnvironment,
                ),
              ],
            ],
          ),
        ),
        // 变量表头
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
          child: Row(
            children: [
              const SizedBox(width: 32),
              _buildHeaderCell(theme, 'Key', flex: 3),
              _buildHeaderCell(theme, 'Value', flex: 4),
              _buildHeaderCell(theme, 'Type', flex: 2),
              const SizedBox(width: 64),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 变量列表
        Expanded(
          child: variables.isEmpty
              ? Center(
                  child: Text(
                    'No variables yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: variables.length,
                  itemBuilder: (context, index) =>
                      _buildVariableRow(theme, variables[index]),
                ),
        ),
        // 添加变量按钮
        Padding(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          child: OutlinedButton.icon(
            key: const Key('add_variable_button'),
            onPressed: _addVariable,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Variable', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(ThemeData theme, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildVariableRow(ThemeData theme, EnvironmentVariable variable) {
    final isSecret = variable.isSecret;
    final revealed = _revealedSecretIds.contains(variable.id);

    return Padding(
      key: Key('variable_row_${variable.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceL,
        vertical: 2,
      ),
      child: Row(
        children: [
          // 启用开关
          SizedBox(
            width: 32,
            height: 32,
            child: Checkbox(
              value: variable.enabled,
              onChanged: (value) =>
                  _updateVariable(variable.copyWith(enabled: value ?? true)),
            ),
          ),
          // Key
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _keyController(variable),
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Key',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) =>
                    _updateVariable(variable.copyWith(key: value)),
              ),
            ),
          ),
          // Value
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _valueController(variable),
                obscureText: isSecret && !revealed,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Value',
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixIcon: isSecret
                      ? IconButton(
                          icon: Icon(
                            revealed ? Icons.visibility_off : Icons.visibility,
                            size: 14,
                          ),
                          onPressed: () {
                            setState(() {
                              if (revealed) {
                                _revealedSecretIds.remove(variable.id);
                              } else {
                                _revealedSecretIds.add(variable.id);
                              }
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) =>
                    _updateVariable(variable.copyWith(value: value)),
              ),
            ),
          ),
          // Type
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VariableType>(
                  value: variable.type,
                  isExpanded: true,
                  isDense: true,
                  // 显式指定文字颜色：未指定时在部分主题下解析为浅色，
                  // 导致亮色模式下几乎不可读
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: VariableType.string,
                      child: Text(
                        'string',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: VariableType.secret,
                      child: Text(
                        'secret',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (type) {
                    if (type != null) {
                      _updateVariable(variable.copyWith(type: type));
                    }
                  },
                ),
              ),
            ),
          ),
          // 删除按钮
          SizedBox(
            width: 64,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              tooltip: 'Remove variable',
              onPressed: () => _removeVariable(variable.id),
            ),
          ),
        ],
      ),
    );
  }
}
