/// Conflict Resolution Dialog
///
/// Displayed when importing a collection with a name that already exists.
library;

import 'package:flutter/material.dart';

import '../../../services/import_export/import_export_exception.dart';
import '../../../theme/app_metrics.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';

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
    final t = context.appTheme;

    return AppDialog(
      title: 'Duplicate Collection Name',
      width: 440,
      actions: [
        AppButton.ghost(
          label: 'Skip',
          onPressed: () => Navigator.of(context).pop(ConflictResolution.skip),
        ),
        AppButton.primary(
          label: 'Confirm',
          onPressed: () => Navigator.of(context).pop(_selectedResolution),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${widget.collectionName}" already exists. Please choose how to handle this:',
            style: AppTextStyles.body13.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: AppMetrics.space16),
          RadioListTile<ConflictResolution>(
            title: Text(
              'Rename Import',
              style: AppTextStyles.body13.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              'Rename imported collection to "${widget.collectionName} (1)"',
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
              'Skip This Collection',
              style: AppTextStyles.body13.copyWith(color: t.textPrimary),
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
          const SizedBox(height: AppMetrics.space8),
          CheckboxListTile(
            title: Text(
              'Apply to all conflicts',
              style: AppTextStyles.body13.copyWith(color: t.textPrimary),
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
    );
  }
}
