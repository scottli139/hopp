/// Postman 导出对话框
///
/// 将 Hopp Collection 导出为 Postman 格式。
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/collection.dart';
import '../../../providers/collection/collection_provider.dart';
import '../../../providers/import_export/import_export_provider.dart';
import '../../../services/import_export/postman_schema.dart';
import '../../../utils/app_logger.dart';

/// 显示导出对话框
Future<void> showExportDialog(
  BuildContext context, {
  String? collectionId,
}) async {
  return showDialog(
    context: context,
    builder: (context) => ExportDialog(initialCollectionId: collectionId),
  );
}

/// 导出对话框
class ExportDialog extends ConsumerStatefulWidget {
  final String? initialCollectionId;

  const ExportDialog({
    super.key,
    this.initialCollectionId,
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> with LogMixin {
  String? _selectedCollectionId;
  PostmanVersion _version = PostmanVersion.v2_1;
  bool _prettyPrint = true;

  @override
  void initState() {
    super.initState();
    _selectedCollectionId = widget.initialCollectionId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importExportProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importExportProvider);
    final collectionsAsync = ref.watch(collectionProvider);

    return collectionsAsync.when(
      data: (collections) => _buildDialog(context, state, collections),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => AlertDialog(
        title: const Text('导出'),
        content: const Text('无法加载集合列表'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialog(
    BuildContext context,
    ImportExportState state,
    List<Collection> collections,
  ) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return AlertDialog(
        title: const Text('导出中...'),
        content: const SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导出集合...'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      );
    }

    if (state.exportPath != null) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('导出成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('文件已保存到:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                state.exportPath!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
        ],
      );
    }

    if (state.error != null) {
      return AlertDialog(
        title: const Text('导出失败'),
        content: Text(state.error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('导出 Postman Collection'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 集合选择
            DropdownButtonFormField<String>(
              value: _selectedCollectionId,
              decoration: const InputDecoration(
                labelText: '选择集合',
                border: OutlineInputBorder(),
              ),
              items: collections.map((collection) {
                return DropdownMenuItem(
                  value: collection.id,
                  child: Text(collection.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCollectionId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 格式版本
            DropdownButtonFormField<PostmanVersion>(
              value: _version,
              decoration: const InputDecoration(
                labelText: '格式版本',
                border: OutlineInputBorder(),
              ),
              items: PostmanVersion.values.map((version) {
                return DropdownMenuItem(
                  value: version,
                  child: Text(version.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _version = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // 美化输出
            CheckboxListTile(
              title: const Text('美化 JSON 输出'),
              subtitle: const Text('格式化缩进，便于阅读'),
              value: _prettyPrint,
              onChanged: (value) {
                setState(() {
                  _prettyPrint = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selectedCollectionId == null ? null : _export,
          child: const Text('导出'),
        ),
      ],
    );
  }

  Future<void> _export() async {
    if (_selectedCollectionId == null) return;

    try {
      // 选择保存路径
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '保存 Postman Collection',
        fileName: _generateFileName(),
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      if (result != null) {
        logInfo('Exporting to: $result');
        await ref.read(importExportProvider.notifier).exportCollection(
              collectionId: _selectedCollectionId!,
              savePath: result,
              prettyPrint: _prettyPrint,
            );
      }
    } catch (e, stack) {
      logError('Export error', e, stack);
    }
  }

  String _generateFileName() {
    final collections = ref.read(collectionProvider).valueOrNull ?? [];
    final collection = collections.firstWhere(
      (c) => c.id == _selectedCollectionId,
      orElse: () => Collection.empty(),
    );

    final sanitized =
        collection.name.replaceAll(RegExp(r'[^\w\s-]'), '_').trim();
    final versionSuffix = _version == PostmanVersion.v2_1 ? 'v2.1' : 'v2.0';
    return '${sanitized}_$versionSuffix.postman_collection.json';
  }
}
