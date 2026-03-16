/// 冲突解决对话框
///
/// 当导入的集合名称已存在时显示此对话框。
library;

import 'package:flutter/material.dart';

import '../../../services/import_export/import_export_exception.dart';

/// 显示冲突解决对话框
Future<ConflictResolution?> showConflictResolutionDialog(
  BuildContext context, {
  required String collectionName,
}) async {
  return showDialog<ConflictResolution>(
    context: context,
    builder: (context) => ConflictResolutionDialog(
      collectionName: collectionName,
    ),
  );
}

/// 冲突解决对话框
class ConflictResolutionDialog extends StatefulWidget {
  final String collectionName;

  const ConflictResolutionDialog({
    super.key,
    required this.collectionName,
  });

  @override
  State<ConflictResolutionDialog> createState() =>
      _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  ConflictResolution _selectedResolution = ConflictResolution.rename;
  bool _applyToAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: theme.colorScheme.warning),
          const SizedBox(width: 8),
          const Text('发现同名集合'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${widget.collectionName}" 已存在，请选择处理方式:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            RadioListTile<ConflictResolution>(
              title: const Text('重命名导入'),
              subtitle: const Text('将导入的集合重命名为 "集合名 (1)"'),
              value: ConflictResolution.rename,
              groupValue: _selectedResolution,
              onChanged: (value) {
                setState(() {
                  _selectedResolution = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<ConflictResolution>(
              title: const Text('覆盖现有集合'),
              subtitle: const Text('用导入的内容替换现有集合'),
              value: ConflictResolution.overwrite,
              groupValue: _selectedResolution,
              onChanged: (value) {
                setState(() {
                  _selectedResolution = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<ConflictResolution>(
              title: const Text('合并集合'),
              subtitle: const Text('保留现有请求，添加新请求'),
              value: ConflictResolution.merge,
              groupValue: _selectedResolution,
              onChanged: (value) {
                setState(() {
                  _selectedResolution = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<ConflictResolution>(
              title: const Text('跳过此集合'),
              value: ConflictResolution.skip,
              groupValue: _selectedResolution,
              onChanged: (value) {
                setState(() {
                  _selectedResolution = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('对所有冲突应用相同选择'),
              value: _applyToAll,
              onChanged: (value) {
                setState(() {
                  _applyToAll = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.skip),
          child: const Text('跳过'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedResolution),
          child: const Text('确认'),
        ),
      ],
    );
  }
}

/// 扩展主题颜色
extension ConflictThemeExtension on ColorScheme {
  Color get warning => const Color(0xFFF59E0B);
}
