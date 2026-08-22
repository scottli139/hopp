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
import '../../../theme/app_metrics.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_theme_data.dart';
import '../../../utils/app_logger.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
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
      error: (_, __) => AppDialog(
        title: 'Export',
        actions: [
          AppButton.primary(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: Text(
          'Unable to load collection list',
          style: AppTextStyles.body13.copyWith(
            color: context.appTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(
    BuildContext context,
    ImportExportState state,
    List<Collection> collections,
  ) {
    final t = context.appTheme;

    if (state.isLoading) {
      return AppDialog(
        title: 'Exporting...',
        actions: [
          AppButton.ghost(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppMetrics.space16),
                Text(
                  'Exporting collection...',
                  style: AppTextStyles.body13.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.exportPath != null) {
      return AppDialog(
        title: 'Export Successful',
        width: 480,
        actions: [
          AppButton.primary(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File saved to:',
              style: AppTextStyles.body13.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: AppMetrics.space8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppMetrics.space12),
              decoration: BoxDecoration(
                color: t.surfaceVariant,
                borderRadius: AppMetrics.br6,
              ),
              child: SelectableText(
                state.exportPath!,
                style: AppTextStyles.code12.copyWith(color: t.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return AppDialog(
        title: 'Export Failed',
        actions: [
          AppButton.primary(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: Text(
          state.error!,
          style: AppTextStyles.body13.copyWith(color: t.error),
        ),
      );
    }

    return AppDialog(
      title: 'Export Postman Collection',
      width: 440,
      actions: [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: 'Export',
          onPressed: _selectedCollectionId == null ? null : _export,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collection selection
          Text(
            'Select Collection',
            style: AppTextStyles.tiny11.copyWith(
              fontWeight: FontWeight.w600,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: AppMetrics.space4),
          AppPopupSelect<String>(
            value: _selectedCollectionId,
            hint: 'Select Collection',
            boxed: true,
            textStyle: AppTextStyles.body13,
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
          const SizedBox(height: AppMetrics.space16),

          // Format version
          Text(
            'Format Version',
            style: AppTextStyles.tiny11.copyWith(
              fontWeight: FontWeight.w600,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: AppMetrics.space4),
          AppPopupSelect<PostmanVersion>(
            value: _version,
            boxed: true,
            textStyle: AppTextStyles.body13,
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
          const SizedBox(height: AppMetrics.space16),

          // Prettify output
          CheckboxListTile(
            title: Text(
              'Prettify JSON Output',
              style: AppTextStyles.body13.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              'Format with indentation for readability',
              style: AppTextStyles.tiny11.copyWith(color: t.textSecondary),
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
