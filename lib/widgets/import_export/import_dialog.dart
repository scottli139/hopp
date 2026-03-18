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
import '../../../utils/app_logger.dart';
import '../../../utils/constants.dart';

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
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Import Postman Data',
            style: AppTextStyles.title.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Importing...',
            style: AppTextStyles.body.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
            'Import Failed',
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(ImportResult result) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Import Successful',
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (result.renamed)
            Text(
              'Collection renamed to: ${result.newName}',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
          else if (result.merged)
            Text(
              'Collection merged with existing collection',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              'Successfully imported ${result.importedRequestCount} requests',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
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
                'Click to select file or drag and drop here',
                style: AppTextStyles.body.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Supports Postman Collection v2.0/v2.1 and Environment',
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Select File'),
                style: AppComponentStyles.primaryButton(context),
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
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppComponentStyles.primaryButton(context),
          child: const Text('Done'),
        ),
      ];
    }

    // Error state - show Retry and Cancel
    if (state.error != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppComponentStyles.ghostButton(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(importExportProvider.notifier).reset();
          },
          style: AppComponentStyles.primaryButton(context),
          child: const Text('Retry'),
        ),
      ];
    }

    // Conflict state - conflict dialog handles its own buttons
    if (state.conflict != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppComponentStyles.ghostButton(context),
          child: const Text('Cancel'),
        ),
      ];
    }

    // Loading state - only show Cancel
    if (state.isLoading) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppComponentStyles.ghostButton(context),
          child: const Text('Cancel'),
        ),
      ];
    }

    // Default state
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: AppComponentStyles.ghostButton(context),
        child: const Text('Cancel'),
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber,
                color: theme.colorScheme.warning, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${widget.collectionName}" Already Exists',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Please choose how to handle this:',
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        RadioListTile<ConflictResolution>(
          title: Text(
            'Rename Import',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Rename imported collection to "Collection Name (1)"',
            style: AppTextStyles.tiny.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Replace existing collection with imported content',
            style: AppTextStyles.tiny.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Keep existing requests and add new ones',
            style: AppTextStyles.tiny.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Cancel import for this collection',
            style: AppTextStyles.tiny.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
            TextButton(
              onPressed: () => widget.onResolve(ConflictResolution.skip),
              style: AppComponentStyles.ghostButton(context),
              child: const Text('Skip'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => widget.onResolve(_selectedResolution),
              style: AppComponentStyles.primaryButton(context),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Theme color extension
extension ThemeColorExtension on ColorScheme {
  Color get warning => const Color(0xFFF59E0B);
}
