/// OpenAPI/Swagger 导入面板
///
/// ImportDialog OpenAPI 页签内容，按 [OpenApiImportState.stage] 渲染：
/// idle（文件/URL 输入）→ parsing → preview（分组勾选 + 搜索）→
/// importing → conflict（复用 ConflictResolutionContent）→ success（报告）
/// / error。布局与文案以 docs/design/openapi_import_preview.html 为准。
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/import_export/openapi_import_provider.dart';
import '../../../services/import_export/openapi/openapi_import_service.dart';
import '../../../services/import_export/openapi/openapi_spec.dart';
import '../../../theme/app_metrics.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_theme_data.dart';
import '../../../utils/app_logger.dart';
import '../common/app_badge.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';
import '../common/app_controls.dart';
import '../common/app_text_field.dart';
import 'import_dialog.dart';

/// OpenAPI 导入面板
class OpenApiImportPanel extends ConsumerStatefulWidget {
  const OpenApiImportPanel({
    super.key,
    required this.urlController,
    required this.headerNameController,
    required this.headerValueController,
  });

  /// Spec URL 输入（controller 由对话框持有，Parse 按钮直接读值）
  final TextEditingController urlController;

  /// 自定义请求头名（可选）
  final TextEditingController headerNameController;

  /// 自定义请求头值（可选）
  final TextEditingController headerValueController;

  @override
  ConsumerState<OpenApiImportPanel> createState() => _OpenApiImportPanelState();
}

class _OpenApiImportPanelState extends ConsumerState<OpenApiImportPanel>
    with LogMixin {
  OpenApiImportNotifier get _notifier =>
      ref.read(openApiImportProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openApiImportProvider);

    switch (state.stage) {
      case OpenApiImportStage.idle:
        return _buildIdle();
      case OpenApiImportStage.parsing:
        return _buildProgress('Parsing spec…');
      case OpenApiImportStage.importing:
        return _buildProgress('Importing…');
      case OpenApiImportStage.preview:
        return _buildPreview(state);
      case OpenApiImportStage.conflict:
        return ConflictResolutionContent(
          collectionName: state.conflictCollection?.name ?? '',
          onResolve: _notifier.resolveConflict,
        );
      case OpenApiImportStage.success:
        return _buildSuccess(state);
      case OpenApiImportStage.error:
        return _buildError(state);
    }
  }

  // ==================== S1 输入 ====================

  Widget _buildIdle() {
    final t = context.appTheme;

    // 可滚动：窄窗口/小高度下不溢出
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 拖放区
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppMetrics.space20,
                horizontal: AppMetrics.space16,
              ),
              decoration: BoxDecoration(
                color: t.surfaceVariant,
                border: Border.all(color: t.border),
                borderRadius: AppMetrics.br8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload, size: 32, color: t.brand),
                  const SizedBox(height: AppMetrics.space8),
                  Text(
                    'Click to select a spec file',
                    style: AppTextStyles.body13.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: AppMetrics.space4),
                  Text(
                    'Supports .json / .yaml / .yml · OpenAPI 3.x · Swagger 2.0',
                    style: AppTextStyles.caption12
                        .copyWith(color: t.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppMetrics.space12),
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
          const SizedBox(height: AppMetrics.space16),
          // 分隔线
          Row(
            children: [
              Expanded(child: Container(height: 1, color: t.border)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppMetrics.space12,
                ),
                child: Text(
                  'Or import from URL',
                  style: AppTextStyles.tiny11.copyWith(color: t.textTertiary),
                ),
              ),
              Expanded(child: Container(height: 1, color: t.border)),
            ],
          ),
          const SizedBox(height: AppMetrics.space12),
          // Spec URL
          _buildFormRow(
            label: 'Spec URL',
            field: AppTextField(
              controller: widget.urlController,
              hintText: 'https://petstore3.swagger.io/api/v3/openapi.json',
              style: AppTextStyles.code12,
            ),
            hint:
                'Machine-readable address (openapi.json / swagger.yaml), parsed '
                'locally — data never leaves your machine.',
          ),
          const SizedBox(height: AppMetrics.space12),
          // 自定义请求头
          _buildFormRow(
            label: 'Header',
            field: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: widget.headerNameController,
                    hintText: 'Authorization',
                    compact: true,
                  ),
                ),
                const SizedBox(width: AppMetrics.space8),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: widget.headerValueController,
                    hintText: 'Bearer <token>',
                    compact: true,
                  ),
                ),
              ],
            ),
            hint:
                'Optional. One custom header used only for this fetch (private '
                'specs). Not saved.',
          ),
        ],
      ),
    );
  }

  /// 表单行：左标签（76px 对齐原型）+ 右侧输入与提示
  Widget _buildFormRow({
    required String label,
    required Widget field,
    required String hint,
  }) {
    final t = context.appTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              label,
              style: AppTextStyles.caption12.copyWith(
                fontWeight: FontWeight.w500,
                color: t.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field,
              const SizedBox(height: AppMetrics.space4),
              Text(
                hint,
                style: AppTextStyles.tiny11.copyWith(
                  fontWeight: FontWeight.w400,
                  color: t.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'yaml', 'yml'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          logInfo('OpenAPI spec file selected: $path');
          await _notifier.parseFile(path);
        }
      }
    } catch (e, stack) {
      logError('File picker error', e, stack);
    }
  }

  // ==================== 解析 / 导入中 ====================

  Widget _buildProgress(String label) {
    final t = context.appTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: t.brand),
          const SizedBox(height: AppMetrics.space16),
          Text(
            label,
            style: AppTextStyles.body13.copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
  }

  // ==================== S2 解析预览 ====================

  Widget _buildPreview(OpenApiImportState state) {
    final spec = state.spec;
    if (spec == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSpecBar(spec),
        const SizedBox(height: AppMetrics.space12),
        _buildToolbar(),
        const SizedBox(height: AppMetrics.space8),
        Expanded(child: _buildOperationList(state, spec)),
      ],
    );
  }

  /// spec 信息条：标题 / 版本 / tag 数 / 接口数 / 服务器 → {{baseUrl}}
  Widget _buildSpecBar(OpenApiSpec spec) {
    final t = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.space12,
        vertical: AppMetrics.space12 - 2,
      ),
      decoration: BoxDecoration(
        color: t.infoSoft,
        borderRadius: AppMetrics.br6,
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 16, color: t.info),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: spec.title,
                    style: AppTextStyles.caption12.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' · OpenAPI ${spec.specVersion}'
                        ' · ${spec.tagOrder.length} tags'
                        ' · ${spec.operations.length} operations',
                    style: AppTextStyles.caption12
                        .copyWith(color: t.textSecondary),
                  ),
                  if (spec.serverUrl != null) ...[
                    TextSpan(
                      text: ' · Server ',
                      style: AppTextStyles.caption12
                          .copyWith(color: t.textSecondary),
                    ),
                    TextSpan(
                      text: spec.serverUrl,
                      style:
                          AppTextStyles.code11.copyWith(color: t.textPrimary),
                    ),
                    TextSpan(
                      text: ' → {{baseUrl}}',
                      style: AppTextStyles.code11.copyWith(color: t.brand),
                    ),
                  ],
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 工具栏：搜索 + 全选 / 全不选
  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            compact: true,
            hintText: 'Search path or name…',
            onChanged: _notifier.setSearchQuery,
          ),
        ),
        const SizedBox(width: AppMetrics.space8),
        AppButton.ghost(
          label: 'Select all',
          size: AppButtonSize.small,
          onPressed: () => _notifier.selectAll(true),
        ),
        AppButton.ghost(
          label: 'Select none',
          size: AppButtonSize.small,
          onPressed: () => _notifier.selectAll(false),
        ),
      ],
    );
  }

  /// 按 tag 分组的接口清单（搜索过滤，空组隐藏）
  Widget _buildOperationList(OpenApiImportState state, OpenApiSpec spec) {
    final t = context.appTheme;
    final filtered = _notifier.filteredOperations;

    if (filtered.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: t.border),
          borderRadius: AppMetrics.br8,
        ),
        child: Center(
          child: Text(
            'No operations match your search',
            style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
          ),
        ),
      );
    }

    // 分组：按 tagOrder 序，无 tag 组（''）最后
    final byTag = <String, List<OpenApiOperation>>{};
    for (final op in filtered) {
      byTag.putIfAbsent(op.tag ?? '', () => []).add(op);
    }
    final groups = <MapEntry<String, List<OpenApiOperation>>>[
      for (final tag in spec.tagOrder)
        if (byTag.containsKey(tag)) MapEntry(tag, byTag.remove(tag)!),
      // 兜底：tagOrder 未覆盖的 tag（解析层保证不出现，防御性处理）
      for (final entry in byTag.entries)
        if (entry.key.isNotEmpty) entry,
      if (byTag.containsKey('')) MapEntry('', byTag['']!),
    ];

    final children = <Widget>[];
    for (final group in groups) {
      if (children.isNotEmpty) {
        children.add(Container(height: 1, color: t.border));
      }
      children.add(_buildGroupHeader(state, group.key, group.value));
      for (final op in group.value) {
        children.add(Container(height: 1, color: t.border));
        children.add(_buildOperationRow(state, op));
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: AppMetrics.br8,
      ),
      child: ClipRRect(
        borderRadius: AppMetrics.br8,
        child: ListView(
          padding: EdgeInsets.zero,
          children: children,
        ),
      ),
    );
  }

  /// 组头：整组勾选 + tag 名 + 数量徽章 + 右侧已选/总数
  Widget _buildGroupHeader(
    OpenApiImportState state,
    String tag,
    List<OpenApiOperation> ops,
  ) {
    final t = context.appTheme;
    final selectedCount =
        ops.where((op) => state.selectedIds.contains(op.id)).length;
    final allSelected = selectedCount == ops.length;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space12 - 2),
      color: t.surfaceVariant,
      child: Row(
        children: [
          AppCheckbox(
            value: allSelected,
            onChanged: (value) => _notifier.toggleTag(tag, value),
          ),
          const SizedBox(width: AppMetrics.space8),
          Flexible(
            child: Text(
              tag.isEmpty ? 'No tag' : tag,
              style: AppTextStyles.caption12.copyWith(
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: t.background,
              borderRadius: AppMetrics.br8,
            ),
            child: Text(
              '${ops.length}',
              style: AppTextStyles.micro10.copyWith(color: t.textSecondary),
            ),
          ),
          const SizedBox(width: AppMetrics.space8),
          Text(
            '$selectedCount/${ops.length}',
            style: AppTextStyles.tiny11.copyWith(
              fontWeight: FontWeight.w400,
              color: t.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 接口行：勾选 + 方法徽章 + path + 名称
  Widget _buildOperationRow(OpenApiImportState state, OpenApiOperation op) {
    final t = context.appTheme;
    final selected = state.selectedIds.contains(op.id);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _notifier.toggleOp(op.id),
        child: Container(
          height: AppMetrics.height32,
          padding: const EdgeInsets.only(
            left: AppMetrics.space32,
            right: AppMetrics.space12 - 2,
          ),
          color: t.background,
          child: Row(
            children: [
              AppCheckbox(
                value: selected,
                onChanged: (_) => _notifier.toggleOp(op.id),
              ),
              const SizedBox(width: AppMetrics.space8),
              MethodBadge(op.method),
              const SizedBox(width: AppMetrics.space8),
              Expanded(
                child: Text(
                  op.path,
                  style: AppTextStyles.code11.copyWith(color: t.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppMetrics.space8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  op.name,
                  style: AppTextStyles.tiny11.copyWith(
                    fontWeight: FontWeight.w400,
                    color: t.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== S4 结果报告 ====================

  Widget _buildSuccess(OpenApiImportState state) {
    final t = context.appTheme;
    final report = state.report;
    if (report == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 统计卡
        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '${report.requestCount}',
                label: 'Requests imported',
                color: t.success,
              ),
            ),
            const SizedBox(width: AppMetrics.space8),
            Expanded(
              child: _StatCard(
                value: '${report.collectionCount + 1}',
                label: 'Collections',
                color: t.info,
              ),
            ),
            const SizedBox(width: AppMetrics.space8),
            Expanded(
              child: _StatCard(
                value: '${report.placeholders.length}',
                label: 'Placeholders',
                color: t.warning,
              ),
            ),
          ],
        ),
        if (report.renamed || report.merged) ...[
          const SizedBox(height: AppMetrics.space8),
          Text(
            report.renamed
                ? 'Imported as "${report.newName ?? report.collectionName}"'
                : 'Merged into existing collection '
                    '"${report.collectionName}"',
            style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
          ),
        ],
        if (report.oauthNotices.isNotEmpty ||
            report.authDescription != null) ...[
          const SizedBox(height: AppMetrics.space12),
          _buildAuthNotice(report),
        ],
        if (report.placeholders.isNotEmpty) ...[
          const SizedBox(height: AppMetrics.space12),
          Text(
            'PLACEHOLDERS (VALUES FROM SCHEMA SKELETON, NOT SPEC EXAMPLES)',
            style: AppTextStyles.micro10.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppMetrics.space4),
          Expanded(child: _buildPlaceholderList(report)),
        ],
      ],
    );
  }

  /// OAuth 未自动配置 + 集合级 Auth 配置说明
  Widget _buildAuthNotice(OpenApiReport report) {
    final t = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.space12,
        vertical: AppMetrics.space12 - 2,
      ),
      decoration: BoxDecoration(
        color: t.warningSoft,
        borderRadius: AppMetrics.br6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, size: 16, color: t.warning),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.oauthNotices.isNotEmpty)
                  Text(
                    'OAuth2 / OpenID Connect scheme(s) '
                    '${report.oauthNotices.join(', ')} were not configured '
                    'automatically. Go to Collection settings → Auth to '
                    'complete the authorization flow.',
                    style: AppTextStyles.caption12
                        .copyWith(color: t.textSecondary),
                  ),
                if (report.authDescription != null) ...[
                  if (report.oauthNotices.isNotEmpty)
                    const SizedBox(height: AppMetrics.space4),
                  Text(
                    'Configured collection-level Auth: '
                    '${report.authDescription}.',
                    style: AppTextStyles.caption12
                        .copyWith(color: t.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 占位清单：kind 徽章 + 方法 + path — detail
  Widget _buildPlaceholderList(OpenApiReport report) {
    final t = context.appTheme;

    final children = <Widget>[];
    for (final placeholder in report.placeholders) {
      if (children.isNotEmpty) {
        children.add(Container(height: 1, color: t.border));
      }
      children.add(
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.space12 - 2,
          ),
          color: t.background,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: t.warningSoft,
                  borderRadius: AppMetrics.br4,
                ),
                child: Text(
                  placeholder.kind,
                  style: AppTextStyles.micro10.copyWith(color: t.warning),
                ),
              ),
              const SizedBox(width: AppMetrics.space8),
              MethodBadge(placeholder.method),
              const SizedBox(width: AppMetrics.space8),
              Expanded(
                child: Text(
                  '${placeholder.path} — ${placeholder.detail}',
                  style: AppTextStyles.code11.copyWith(color: t.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: AppMetrics.br6,
      ),
      child: ClipRRect(
        borderRadius: AppMetrics.br6,
        child: ListView(
          padding: EdgeInsets.zero,
          children: children,
        ),
      ),
    );
  }

  // ==================== 错误 ====================

  Widget _buildError(OpenApiImportState state) {
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
            state.error ?? 'Unknown error',
            style: AppTextStyles.body13.copyWith(color: t.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 结果统计卡
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppMetrics.space12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.display20.copyWith(color: color),
          ),
          const SizedBox(height: AppMetrics.space4 - 2),
          Text(
            label,
            style: AppTextStyles.tiny11.copyWith(
              fontWeight: FontWeight.w400,
              color: t.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
