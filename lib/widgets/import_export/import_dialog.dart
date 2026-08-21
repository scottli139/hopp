/// Postman Import Dialog
///
/// Supports drag-and-drop and file selection for importing Postman Collection/Environment.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/import_export/import_export_provider.dart';
import '../../../services/import_export/import_export_exception.dart';
import '../../../services/import_export/postman_import_service.dart';
import '../../../theme/app_metrics.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_theme_data.dart';
import '../../../utils/app_logger.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';

/// Show import dialog
Future<void> showImportDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const ImportDialog(),
  );
}

/// Import dialog
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
    // Reset state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importExportProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importExportProvider);

    return AppDialog(
      title: 'Import Postman Data',
      width: 520,
      actions: _buildActions(state),
      child: SizedBox(
        height: 320,
        child: _buildContent(state),
      ),
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
    final t = context.appTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppMetrics.space16),
          Text(
            'Importing...',
            style: AppTextStyles.body13.copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    final t = context.appTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: t.error),
          const SizedBox(height: AppMetrics.space16),
          Text(
            'Import Failed',
            style: AppTextStyles.body13.copyWith(
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: AppMetrics.space8),
          Text(
            error,
            style: AppTextStyles.body13.copyWith(color: t.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(ImportResult result) {
    final t = context.appTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 48, color: t.brand),
          const SizedBox(height: AppMetrics.space16),
          Text(
            'Import Successful',
            style: AppTextStyles.body13.copyWith(
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: AppMetrics.space8),
          if (result.renamed)
            Text(
              'Collection renamed to: ${result.newName}',
              style: AppTextStyles.body13.copyWith(color: t.textSecondary),
              textAlign: TextAlign.center,
            )
          else if (result.merged)
            Text(
              'Collection merged with existing collection',
              style: AppTextStyles.body13.copyWith(color: t.textSecondary),
              textAlign: TextAlign.center,
            )
          else
            Text(
              result.successMessage ??
                  'Successfully imported ${result.importedRequestCount} requests',
              style: AppTextStyles.body13.copyWith(color: t.textSecondary),
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
    final t = context.appTheme;

    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDragging ? t.brand : t.border,
            width: _isDragging ? 2 : 1,
          ),
          borderRadius: AppMetrics.br8,
          color: _isDragging ? t.brandSoft : t.surfaceVariant,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload,
                size: 48,
                color: t.brand,
              ),
              const SizedBox(height: AppMetrics.space16),
              Text(
                'Click to select file or drag and drop here',
                style: AppTextStyles.body13.copyWith(color: t.textPrimary),
              ),
              const SizedBox(height: AppMetrics.space8),
              Text(
                'Supports Postman Collection v2.0/v2.1 and Environment',
                style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppMetrics.space16),
              AppButton.secondary(
                label: 'Select File',
                icon: Icons.folder_open,
                size: AppButtonSize.small,
                onPressed: _pickFile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(ImportExportState state) {
    // Success state - show Done button
    if (state.importResult != null && state.importResult!.success) {
      return [
        AppButton.primary(
          label: 'Done',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];
    }

    // Error state - show Retry and Cancel
    if (state.error != null) {
      return [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: 'Retry',
          onPressed: () {
            ref.read(importExportProvider.notifier).reset();
          },
        ),
      ];
    }

    // Conflict state - conflict dialog handles its own buttons
    if (state.conflict != null) {
      return [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];
    }

    // Loading state - only show Cancel
    if (state.isLoading) {
      return [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];
    }

    // Default state
    return [
      AppButton.ghost(
        label: 'Cancel',
        onPressed: () => Navigator.of(context).pop(),
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

/// Conflict resolution content
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
    final t = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, color: t.warning, size: 20),
            const SizedBox(width: AppMetrics.space8),
            Expanded(
              child: Text(
                '"${widget.collectionName}" Already Exists',
                style: AppTextStyles.body13.copyWith(
                  fontWeight: FontWeight.w500,
                  color: t.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppMetrics.space8),
        Text(
          'Please choose how to handle this:',
          style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: AppMetrics.space16),
        RadioListTile<ConflictResolution>(
          title: Text(
            'Rename Import',
            style: AppTextStyles.body13.copyWith(color: t.textPrimary),
          ),
          subtitle: Text(
            'Rename imported collection to "Collection Name (1)"',
            style: AppTextStyles.tiny11.copyWith(color: t.textSecondary),
          ),
          value: ConflictResolution.rename,
          groupValue: _selectedResolution,
          onChanged: (value) {
            setState(() {
              _selectedResolution = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<ConflictResolution>(
          title: Text(
            'Overwrite Existing',
            style: AppTextStyles.body13.copyWith(color: t.textPrimary),
          ),
          subtitle: Text(
            'Replace existing collection with imported content',
            style: AppTextStyles.tiny11.copyWith(color: t.textSecondary),
          ),
          value: ConflictResolution.overwrite,
          groupValue: _selectedResolution,
          onChanged: (value) {
            setState(() {
              _selectedResolution = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<ConflictResolution>(
          title: Text(
            'Merge Collections',
            style: AppTextStyles.body13.copyWith(color: t.textPrimary),
          ),
          subtitle: Text(
            'Keep existing requests and add new ones',
            style: AppTextStyles.tiny11.copyWith(color: t.textSecondary),
          ),
          value: ConflictResolution.merge,
          groupValue: _selectedResolution,
          onChanged: (value) {
            setState(() {
              _selectedResolution = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<ConflictResolution>(
          title: Text(
            'Skip',
            style: AppTextStyles.body13.copyWith(color: t.textPrimary),
          ),
          subtitle: Text(
            'Cancel import for this collection',
            style: AppTextStyles.tiny11.copyWith(color: t.textSecondary),
          ),
          value: ConflictResolution.skip,
          groupValue: _selectedResolution,
          onChanged: (value) {
            setState(() {
              _selectedResolution = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton.ghost(
              label: 'Skip',
              onPressed: () => widget.onResolve(ConflictResolution.skip),
            ),
            const SizedBox(width: AppMetrics.space8),
            AppButton.primary(
              label: 'Confirm',
              onPressed: () => widget.onResolve(_selectedResolution),
            ),
          ],
        ),
      ],
    );
  }
}
