/// Postman Export Dialog
///
/// Export Hopp Collection to Postman format.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/collection.dart';
import '../../../providers/collection/collection_provider.dart';
import '../../../providers/import_export/import_export_provider.dart';
import '../../../services/import_export/postman_schema.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/constants.dart';
import '../common/app_popup_menu.dart';

/// Show export dialog
Future<void> showExportDialog(
  BuildContext context, {
  String? collectionId,
}) async {
  return showDialog(
    context: context,
    builder: (context) => ExportDialog(initialCollectionId: collectionId),
  );
}

/// Export dialog
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
        title: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Export',
              style: AppTextStyles.title.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Unable to load collection list',
          style: AppTextStyles.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppComponentStyles.ghostButton(context),
            child: const Text('OK'),
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
        title: Row(
          children: [
            Icon(Icons.upload, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Exporting...',
              style: AppTextStyles.title.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Exporting collection...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppComponentStyles.ghostButton(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    }

    if (state.exportPath != null) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle,
                color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Export Successful',
              style: AppTextStyles.title.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File saved to:',
              style: AppTextStyles.body.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: SelectableText(
                state.exportPath!,
                style: AppTextStyles.bodySmall.copyWith(
                  fontFamily: AppTextStyles.monoFontFamily,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppComponentStyles.primaryButton(context),
            child: const Text('Done'),
          ),
        ],
      );
    }

    if (state.error != null) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Export Failed',
              style: AppTextStyles.title.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          state.error!,
          style: AppTextStyles.body.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppComponentStyles.ghostButton(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.upload, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Export Postman Collection',
            style: AppTextStyles.title.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collection selection
            Text(
              'Select Collection',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            AppPopupSelect<String>(
              value: _selectedCollectionId,
              hint: 'Select Collection',
              boxed: true,
              fontSize: 13,
              items: [
                for (final collection in collections)
                  AppPopupSelectEntry(
                    value: collection.id,
                    label: collection.name,
                  ),
              ],
              onSelected: (value) {
                setState(() {
                  _selectedCollectionId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Format version
            Text(
              'Format Version',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            AppPopupSelect<PostmanVersion>(
              value: _version,
              boxed: true,
              fontSize: 13,
              items: [
                for (final version in PostmanVersion.values)
                  AppPopupSelectEntry(
                    value: version,
                    label: version.value,
                  ),
              ],
              onSelected: (value) {
                setState(() {
                  _version = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Prettify output
            CheckboxListTile(
              title: Text(
                'Prettify JSON Output',
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Format with indentation for readability',
                style: AppTextStyles.tiny.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: _prettyPrint,
              onChanged: (value) {
                setState(() {
                  _prettyPrint = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppComponentStyles.ghostButton(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedCollectionId == null ? null : _export,
          style: AppComponentStyles.primaryButton(context),
          child: const Text('Export'),
        ),
      ],
    );
  }

  Future<void> _export() async {
    if (_selectedCollectionId == null) return;

    try {
      // Select save path
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Postman Collection',
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
