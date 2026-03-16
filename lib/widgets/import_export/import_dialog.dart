/// Postman 导入对话框
///
/// 支持拖放和文件选择导入 Postman Collection/Environment。
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/import_export/import_export_provider.dart';
import '../../../services/import_export/import_export_exception.dart';
import '../../../utils/app_logger.dart';

/// 显示导入对话框
Future<void> showImportDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const ImportDialog(),
  );
}

/// 导入对话框
class ImportDialog extends ConsumerStatefulWidget {
  const ImportDialog({super.key});

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> with LogMixin {
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // 重置状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importExportProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importExportProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('导入 Postman 数据'),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 320,
        child: _buildContent(state),
      ),
      actions: _buildActions(state),
    );
  }

  Widget _buildContent(ImportExportState state) {
    if (state.isLoading) {
      return _buildLoading();
    }

    if (state.error != null) {
      return _buildError(state.error!);
    }

    if (state.importResult != null && state.importResult!.success) {
      return _buildSuccess(state.importResult!);
    }

    if (state.conflict != null) {
      return _buildConflict(state);
    }

    return _buildDropZone();
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在导入...'),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            '导入失败',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(dynamic result) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            '导入成功',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (result.renamed)
            Text(
              '集合已重命名为: ${result.newName}',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            )
          else if (result.merged)
            const Text(
              '集合已合并到现有集合',
              textAlign: TextAlign.center,
            )
          else
            Text(
              '成功导入 ${result.importedRequestCount} 个请求',
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildConflict(ImportExportState state) {
    return ConflictResolutionContent(
      collectionName: state.conflict!.collection.name,
      onResolve: (resolution) {
        ref.read(importExportProvider.notifier).resolveConflict(resolution);
      },
    );
  }

  Widget _buildDropZone() {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragging
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: _isDragging ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _isDragging
              ? theme.colorScheme.primary.withOpacity(0.05)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                '点击选择文件或拖放到此处',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '支持 Postman Collection v2.0/v2.1 和 Environment',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('选择文件'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(ImportExportState state) {
    // 成功状态 - 显示完成按钮
    if (state.importResult != null && state.importResult!.success) {
      return [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('完成'),
        ),
      ];
    }

    // 错误状态 - 显示重试和取消
    if (state.error != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(importExportProvider.notifier).reset();
          },
          child: const Text('重试'),
        ),
      ];
    }

    // 冲突状态 - 冲突对话框自己处理按钮
    if (state.conflict != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ];
    }

    // 加载状态 - 只显示取消
    if (state.isLoading) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ];
    }

    // 默认状态
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
    ];
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          logInfo('File selected: $path');
          await ref.read(importExportProvider.notifier).importFile(path);
        }
      }
    } catch (e, stack) {
      logError('File picker error', e, stack);
    }
  }
}

/// 冲突解决内容
class ConflictResolutionContent extends StatefulWidget {
  final String collectionName;
  final ValueChanged<ConflictResolution> onResolve;

  const ConflictResolutionContent({
    super.key,
    required this.collectionName,
    required this.onResolve,
  });

  @override
  State<ConflictResolutionContent> createState() =>
      _ConflictResolutionContentState();
}

class _ConflictResolutionContentState extends State<ConflictResolutionContent> {
  ConflictResolution _selectedResolution = ConflictResolution.rename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${widget.collectionName}" 已存在',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '请选择处理方式:',
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
        ),
        RadioListTile<ConflictResolution>(
          title: const Text('跳过'),
          subtitle: const Text('取消导入'),
          value: ConflictResolution.skip,
          groupValue: _selectedResolution,
          onChanged: (value) {
            setState(() {
              _selectedResolution = value!;
            });
          },
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => widget.onResolve(ConflictResolution.skip),
              child: const Text('跳过'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => widget.onResolve(_selectedResolution),
              child: const Text('确认'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 扩展主题颜色
extension ThemeColorExtension on ColorScheme {
  Color get warning => const Color(0xFFF59E0B);
}
