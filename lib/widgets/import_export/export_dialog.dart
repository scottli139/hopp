/// Export Dialog
///
/// Export Hopp Collection to Postman format or Hopp CLI native format.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../models/collection.dart';
import '../../../providers/collection/collection_provider.dart';
import '../../../providers/import_export/import_export_provider.dart';
import '../../../services/import_export/postman_schema.dart';
import '../../../theme/app_colors.dart';
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

/// 导出格式（F4.4）
enum _ExportFormat {
  /// Postman Collection v2.1（不含断言与预请求链）
  postman,

  /// Hopp CLI 原生格式 .hopp.json（全保真）
  hoppCli,
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
  _ExportFormat _format = _ExportFormat.postman;
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
        title: context.l10n.sidebar_export,
        actions: [
          AppButton.primary(
            label: context.l10n.common_ok,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: Text(
          context.l10n.export_loadFailed,
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
        title: context.l10n.export_exporting,
        actions: [
          AppButton.ghost(
            label: context.l10n.common_cancel,
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
                  context.l10n.export_exportingCollection,
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
        title: context.l10n.export_successTitle,
        width: 480,
        actions: [
          AppButton.primary(
            label: context.l10n.import_done,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.export_savedTo,
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
        title: context.l10n.export_failedTitle,
        actions: [
          AppButton.primary(
            label: context.l10n.common_ok,
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
      title: context.l10n.export_dialogTitle,
      width: 480,
      actions: [
        AppButton.ghost(
          label: context.l10n.common_cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: context.l10n.sidebar_export,
          onPressed: _selectedCollectionId == null ? null : _export,
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection (F4.4)
            Text(
              context.l10n.export_formatHeader,
              style: AppTextStyles.micro10.copyWith(color: t.textTertiary),
            ),
            const SizedBox(height: AppMetrics.space8),
            _buildFormatOption(
              context,
              format: _ExportFormat.postman,
              title: context.l10n.export_formatPostman,
              ext: 'v2.1 .json',
              description: TextSpan(
                text: context.l10n.export_formatPostmanDesc1,
                children: [
                  TextSpan(
                    text: context.l10n.export_formatPostmanDescNot,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: context.l10n.export_formatPostmanDesc2),
                ],
              ),
            ),
            const SizedBox(height: AppMetrics.space8),
            _buildFormatOption(
              context,
              format: _ExportFormat.hoppCli,
              title: 'Hopp CLI',
              ext: '.hopp.json',
              description: TextSpan(
                text: context.l10n.export_formatHoppDesc1,
                style: AppTextStyles.tiny11.copyWith(color: t.textSecondary),
                children: [
                  TextSpan(
                    text: 'hopp run',
                    style:
                        AppTextStyles.code11.copyWith(color: t.textSecondary),
                  ),
                  TextSpan(text: context.l10n.export_formatHoppDesc2),
                ],
              ),
            ),
            const SizedBox(height: AppMetrics.space12),

            // Secret 提示条（F4.4：secret 置空，CI 注入）
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppMetrics.space12,
                vertical: AppMetrics.space8,
              ),
              decoration: BoxDecoration(
                color: t.infoSoft,
                borderRadius: AppMetrics.br6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.info_outline,
                      size: 14,
                      color: t.info,
                    ),
                  ),
                  const SizedBox(width: AppMetrics.space8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: context.l10n.export_secretNotice1,
                        style: AppTextStyles.tiny11.copyWith(
                          color: t.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: '--env-var KEY=VALUE',
                            style: AppTextStyles.code11.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: context.l10n.export_secretNotice2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppMetrics.space16),

            // Collection selection
            Text(
              context.l10n.import_selectCollection,
              style: AppTextStyles.tiny11.copyWith(
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: AppMetrics.space4),
            AppPopupSelect<String>(
              value: _selectedCollectionId,
              hint: context.l10n.import_selectCollection,
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

            // Format version (仅 Postman 格式)
            if (_format == _ExportFormat.postman) ...[
              Text(
                context.l10n.export_formatVersion,
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
            ],

            // Prettify output
            CheckboxListTile(
              title: Text(
                context.l10n.export_prettify,
                style: AppTextStyles.body13.copyWith(color: t.textPrimary),
              ),
              subtitle: Text(
                context.l10n.export_prettifyHint,
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
      ),
    );
  }

  /// 格式 radio 卡片（画板 C：选中态品牌色边框 + soft 底）
  Widget _buildFormatOption(
    BuildContext context, {
    required _ExportFormat format,
    required String title,
    required String ext,
    required TextSpan description,
  }) {
    final t = context.appTheme;
    final selected = _format == format;

    return GestureDetector(
      onTap: () => setState(() => _format = format),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppMetrics.space12,
          vertical: AppMetrics.space8,
        ),
        decoration: BoxDecoration(
          color: selected ? t.brandSoft : AppColors.transparent,
          borderRadius: AppMetrics.br8,
          border: Border.all(
            color: selected ? t.brand : t.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? t.brand : t.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.brand,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppMetrics.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: title,
                      style: AppTextStyles.body13.copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: ' $ext',
                          style: AppTextStyles.code11.copyWith(
                            color: t.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppMetrics.space4),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.tiny11.copyWith(
                        color: t.textSecondary,
                      ),
                      children: [description],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    if (_selectedCollectionId == null) return;

    final isHoppCli = _format == _ExportFormat.hoppCli;

    try {
      // Select save path
      final result = await FilePicker.platform.saveFile(
        dialogTitle: isHoppCli
            ? context.l10n.export_saveHoppTitle
            : context.l10n.export_savePostmanTitle,
        fileName: _generateFileName(),
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      if (result != null) {
        logInfo('Exporting to: $result');
        final notifier = ref.read(importExportProvider.notifier);
        if (isHoppCli) {
          await notifier.exportCollectionForCli(
            collectionId: _selectedCollectionId!,
            savePath: result,
            prettyPrint: _prettyPrint,
          );
        } else {
          await notifier.exportCollection(
            collectionId: _selectedCollectionId!,
            savePath: result,
            prettyPrint: _prettyPrint,
          );
        }
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
    if (_format == _ExportFormat.hoppCli) {
      return '$sanitized.hopp.json';
    }
    final versionSuffix = _version == PostmanVersion.v2_1 ? 'v2.1' : 'v2.0';
    return '${sanitized}_$versionSuffix.postman_collection.json';
  }
}
