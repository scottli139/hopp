/// Conflict Resolution Dialog
///
/// Displayed when importing a collection with a name that already exists.
library;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
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
      title: context.l10n.conflict_dialogTitle,
      width: 440,
      actions: [
        AppButton.ghost(
          label: context.l10n.conflict_skip,
          onPressed: () => Navigator.of(context).pop(ConflictResolution.skip),
        ),
        AppButton.primary(
          label: context.l10n.conflict_confirm,
          onPressed: () => Navigator.of(context).pop(_selectedResolution),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.conflict_dialogMessage(widget.collectionName),
            style: AppTextStyles.body13.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: AppMetrics.space16),
          RadioListTile<ConflictResolution>(
            title: Text(
              context.l10n.conflict_rename,
              style: AppTextStyles.body13.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              context.l10n.conflict_renameSubtitle(widget.collectionName),
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
              context.l10n.conflict_overwrite,
              style: AppTextStyles.body13.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              context.l10n.conflict_overwriteSubtitle,
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
              context.l10n.conflict_merge,
              style: AppTextStyles.body13.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              context.l10n.conflict_mergeSubtitle,
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
              context.l10n.conflict_skipThis,
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
              context.l10n.conflict_applyToAll,
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
