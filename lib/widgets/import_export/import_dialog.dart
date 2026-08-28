/// Import Dialog
///
/// 统一导入入口：顶部格式页签（Postman / cURL / OpenAPI-Swagger）。
/// Postman 页签支持拖放/选择文件导入 Collection/Environment；cURL 页签
/// 粘贴命令解析导入单个请求（见 curl_import_panel.dart）；OpenAPI 页签
/// 实现「输入 → 解析预览 → 冲突解决 → 结果报告」四屏
/// （见 openapi_import_panel.dart）。
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/collection.dart';
import '../../../providers/collection/collection_provider.dart';
import '../../../providers/curl/curl_import_provider.dart';
import '../../../providers/import_export/import_export_provider.dart';
import '../../../providers/import_export/openapi_import_provider.dart';
import '../../../services/import_export/import_export_exception.dart';
import '../../../services/import_export/postman_import_service.dart';
import '../../../theme/app_metrics.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_theme_data.dart';
import '../../../utils/app_logger.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_tabs.dart';
import 'curl_import_panel.dart';
import 'openapi_import_panel.dart';

/// 导入格式页签
enum ImportFormat { postman, curl, openApi }

/// Show import dialog
Future<void> showImportDialog(
  BuildContext context, {
  ImportFormat initialFormat = ImportFormat.postman,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ImportDialog(initialFormat: initialFormat),
  );
}

/// Import dialog
class ImportDialog extends ConsumerStatefulWidget {
  const ImportDialog({super.key, this.initialFormat = ImportFormat.postman});

  /// 初始格式页签（默认 Postman）
  final ImportFormat initialFormat;

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> with LogMixin {
  late ImportFormat _format = widget.initialFormat;
  bool _isDragging = false;

  // OpenAPI 页签输入（按钮回调直接读 controller.text，不依赖 onSubmitted）
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _headerNameController = TextEditingController();
  final TextEditingController _headerValueController = TextEditingController();

  // cURL 页签：actions 经 GlobalKey 调面板的 importAndOpen
  final GlobalKey<CurlImportPanelState> _curlPanelKey =
      GlobalKey<CurlImportPanelState>();

  @override
  void initState() {
    super.initState();
    // Reset state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importExportProvider.notifier).reset();
      ref.read(openApiImportProvider.notifier).reset();
    });
    // URL 变化时刷新 Parse 按钮可用态
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _headerNameController.dispose();
    _headerValueController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final postmanState = ref.watch(importExportProvider);
    final openApiState = ref.watch(openApiImportProvider);
    final curlState = ref.watch(curlImportProvider);

    return AppDialog(
      title: 'Import',
      width: _dialogWidth(openApiState),
      actions: _buildActions(postmanState, openApiState, curlState),
      footerLeading: _buildFooterLeading(openApiState),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTabs(
            tabs: const [
              AppTabItem(label: 'Postman'),
              AppTabItem(label: 'cURL'),
              AppTabItem(label: 'OpenAPI / Swagger'),
            ],
            selectedIndex: _format.index,
            onChanged: (index) {
              setState(() => _format = ImportFormat.values[index]);
            },
          ),
          const SizedBox(height: AppMetrics.space12),
          // 三页签常驻挂载，切换互不丢状态；Flexible 让内容在窗口
          // 高度不足时收缩（内部列表滚动）而不是溢出
          Flexible(
            child: SizedBox(
              height: _contentHeight(openApiState),
              child: IndexedStack(
                index: _format.index,
                children: [
                  _buildPostmanContent(postmanState),
                  CurlImportPanel(key: _curlPanelKey),
                  OpenApiImportPanel(
                    urlController: _urlController,
                    headerNameController: _headerNameController,
                    headerValueController: _headerValueController,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 对话框宽度：Postman 固定 520；cURL 固定 560；
  /// OpenAPI 预览 680、结果 560、其余 520
  double _dialogWidth(OpenApiImportState openApiState) {
    if (_format == ImportFormat.postman) {
      return 520;
    }
    if (_format == ImportFormat.curl) {
      return 560;
    }
    switch (openApiState.stage) {
      case OpenApiImportStage.preview:
        return 680;
      case OpenApiImportStage.success:
        return 560;
      default:
        return 520;
    }
  }

  /// 内容区高度（页签条另占 32 + 12；cURL 对齐原独立对话框总高 480）
  double _contentHeight(OpenApiImportState openApiState) {
    if (_format == ImportFormat.postman) {
      return 320;
    }
    if (_format == ImportFormat.curl) {
      return 436;
    }
    switch (openApiState.stage) {
      case OpenApiImportStage.idle:
        return 340;
      case OpenApiImportStage.parsing:
      case OpenApiImportStage.importing:
      case OpenApiImportStage.error:
        return 280;
      case OpenApiImportStage.preview:
        return 460;
      case OpenApiImportStage.conflict:
        return 320;
      case OpenApiImportStage.success:
        final report = openApiState.report;
        final hasDetails = report != null &&
            (report.placeholders.isNotEmpty || report.oauthNotices.isNotEmpty);
        return hasDetails ? 420 : 240;
    }
  }

  // ==================== Postman 页签 ====================

  Widget _buildPostmanContent(ImportExportState state) {
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

  // ==================== 底部按钮 ====================

  List<Widget> _buildActions(
    ImportExportState postmanState,
    OpenApiImportState openApiState,
    CurlImportState curlState,
  ) {
    if (_format == ImportFormat.curl) {
      // 按钮组与原独立 cURL 对话框一致；导入执行转发给面板
      return CurlImportPanel.buildActions(
        context: context,
        state: curlState,
        onImport: () => _curlPanelKey.currentState?.importAndOpen(true),
        onImportAndSend: () => _curlPanelKey.currentState?.importAndOpen(false),
      );
    }
    if (_format == ImportFormat.openApi) {
      return _buildOpenApiActions(openApiState);
    }
    return _buildPostmanActions(postmanState);
  }

  List<Widget> _buildPostmanActions(ImportExportState state) {
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

  List<Widget> _buildOpenApiActions(OpenApiImportState state) {
    final notifier = ref.read(openApiImportProvider.notifier);

    switch (state.stage) {
      case OpenApiImportStage.idle:
        final url = _urlController.text.trim();
        final headerName = _headerNameController.text.trim();
        final headerValue = _headerValueController.text.trim();
        return [
          AppButton.ghost(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppButton.primary(
            label: 'Parse',
            onPressed: url.isEmpty
                ? null
                : () => notifier.parseUrl(
                      url,
                      headerName: headerName.isEmpty ? null : headerName,
                      headerValue: headerValue.isEmpty ? null : headerValue,
                    ),
          ),
        ];
      case OpenApiImportStage.parsing:
      case OpenApiImportStage.importing:
      case OpenApiImportStage.conflict:
        return [
          AppButton.ghost(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ];
      case OpenApiImportStage.preview:
        final count = state.selectedIds.length;
        return [
          AppButton.ghost(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppButton.primary(
            label: 'Import $count ${count == 1 ? 'request' : 'requests'}',
            onPressed: count == 0 ? null : notifier.importSelected,
          ),
        ];
      case OpenApiImportStage.success:
        return [
          AppButton.ghost(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppButton.primary(
            label: 'Open collection',
            onPressed: _openImportedCollection,
          ),
        ];
      case OpenApiImportStage.error:
        return [
          AppButton.ghost(
            label: 'Back',
            onPressed: notifier.reset,
          ),
          AppButton.ghost(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ];
    }
  }

  /// 预览阶段底部左侧统计：已选 X / Y · 1 collection + N sub-collections
  Widget? _buildFooterLeading(OpenApiImportState state) {
    if (_format != ImportFormat.openApi ||
        state.stage != OpenApiImportStage.preview) {
      return null;
    }
    final spec = state.spec;
    if (spec == null) {
      return null;
    }
    final t = context.appTheme;
    final subCollections = <String>{
      for (final op in spec.operations)
        if (op.tag != null && state.selectedIds.contains(op.id)) op.tag!,
    };
    return Text(
      'Selected ${state.selectedIds.length} / ${spec.operations.length}'
      ' · 1 collection + ${subCollections.length} sub-collections',
      style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 打开导入的集合：侧栏无「选中集合」概念，这里展开该集合并关闭对话框
  void _openImportedCollection() {
    final report = ref.read(openApiImportProvider).report;
    if (report != null) {
      final collections =
          ref.read(collectionProvider).valueOrNull ?? const <Collection>[];
      for (final collection in collections) {
        if (collection.id == report.collectionId) {
          if (!collection.isExpanded) {
            ref.read(collectionProvider.notifier).toggleExpanded(collection.id);
          }
          break;
        }
      }
    }
    Navigator.of(context).pop();
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
