/// Conflict Resolution Dialog
///
/// Displayed when importing a collection with a name that already exists.
library;

import 'package:flutter/material.dart';

import '../../../services/import_export/import_export_exception.dart';
import '../../../utils/constants.dart';

/// Show conflict resolution dialog
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

/// Conflict resolution dialog
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
          Icon(Icons.warning_amber, color: theme.colorScheme.warning, size: 20),
          const SizedBox(width: 8),
          Text(
            'Duplicate Collection Name',
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
            Text(
              '"${widget.collectionName}" already exists. Please choose how to handle this:',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurface,
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
                'Rename imported collection to "${widget.collectionName} (1)"',
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
                'Skip This Collection',
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface,
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
            const SizedBox(height: 8),
            CheckboxListTile(
              title: Text(
                'Apply to all conflicts',
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              value: _applyToAll,
              onChanged: (value) {
                setState(() {
                  _applyToAll = value ?? false;
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
          onPressed: () => Navigator.of(context).pop(ConflictResolution.skip),
          style: AppComponentStyles.ghostButton(context),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedResolution),
          style: AppComponentStyles.primaryButton(context),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

/// Theme color extension
extension ConflictThemeExtension on ColorScheme {
  Color get warning => const Color(0xFFF59E0B);
}
