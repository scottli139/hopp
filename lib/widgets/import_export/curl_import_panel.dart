/// cURL 导入面板
///
/// 从原独立 CurlImportDialog 抽出的内容区（输入区 + 解析预览区），
/// 作为 Import 对话框的 cURL 页签常驻挂载。底部按钮由外壳对话框通过
/// [CurlImportPanel.buildActions] 构建，导入执行经
/// [CurlImportPanelState.importAndOpen]（外壳以 GlobalKey 取面板 State）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_method.dart';
import '../../models/http_request.dart';
import '../../providers/collection/collection_provider.dart';
import '../../providers/curl/curl_import_provider.dart';
import '../../providers/request/request_tab_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../../utils/app_logger.dart';
import '../common/app_button.dart';
import '../common/app_divider.dart';
import '../common/app_popup_menu.dart';
import '../common/app_text_field.dart';

/// cURL 导入面板（输入 + 解析预览，不含对话框壳）
class CurlImportPanel extends ConsumerStatefulWidget {
  const CurlImportPanel({super.key});

  /// 构建底部操作按钮（供外壳对话框复用）
  ///
  /// 成功态显示 Import / Import & Send，其余状态只显示 Cancel；
  /// [onImport] / [onImportAndSend] 由外壳注入（通常转发到
  /// [CurlImportPanelState.importAndOpen]）。
  static List<Widget> buildActions({
    required BuildContext context,
    required CurlImportState state,
    required VoidCallback onImport,
    required VoidCallback onImportAndSend,
  }) {
    // 成功状态 - 显示导入按钮
    if (state.isSuccess && state.request != null) {
      return [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.secondary(
          label: 'Import & Send',
          onPressed: onImportAndSend,
        ),
        AppButton.primary(
          label: 'Import',
          onPressed: onImport,
        ),
      ];
    }

    // 其他状态 - 只显示取消
    return [
      AppButton.ghost(
        label: 'Cancel',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }

  @override
  ConsumerState<CurlImportPanel> createState() => CurlImportPanelState();
}

class CurlImportPanelState extends ConsumerState<CurlImportPanel>
    with LogMixin {
  final _textController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    // 重置状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(curlImportProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(curlImportProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 输入区域
        Expanded(
          flex: 2,
          child: _buildInputArea(state),
        ),
        const SizedBox(height: AppMetrics.space16),
        // 解析结果预览
        Expanded(
          flex: 3,
          child: _buildPreviewArea(state),
        ),
      ],
    );
  }

  /// 构建输入区域
  Widget _buildInputArea(CurlImportState state) {
    final t = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签和粘贴按钮行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'cURL Command',
              style: AppTextStyles.tiny11.copyWith(
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            AppButton.ghost(
              label: 'Paste',
              icon: Icons.content_paste,
              size: AppButtonSize.small,
              onPressed: _pasteFromClipboard,
            ),
          ],
        ),
        const SizedBox(height: AppMetrics.space4),
        // 文本输入框
        Expanded(
          child: AppTextField(
            controller: _textController,
            expands: true,
            style: AppTextStyles.code12,
            hintText: 'Paste cURL command here...\n\n'
                'Example:\n'
                'curl -X POST https://api.example.com/users \\\n'
                '  -H "Content-Type: application/json" \\\n'
                '  -d \'{"name":"John"}\'',
            onChanged: (value) {
              ref.read(curlImportProvider.notifier).updateInput(value);
            },
          ),
        ),
        // 解析按钮
        if (state.isIdle || state.isError)
          Padding(
            padding: const EdgeInsets.only(top: AppMetrics.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.primary(
                  label: 'Parse',
                  icon: Icons.play_arrow,
                  size: AppButtonSize.small,
                  onPressed: state.isParsing ? null : _parse,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 构建预览区域
  Widget _buildPreviewArea(CurlImportState state) {
    if (state.isParsing) {
      return _buildLoadingPreview();
    }

    if (state.isError) {
      return _buildErrorPreview(state);
    }

    if (state.isSuccess && state.request != null) {
      return _buildSuccessPreview(state.request!, state.warnings);
    }

    return _buildEmptyPreview();
  }

  /// 构建空预览
  Widget _buildEmptyPreview() {
    final t = context.appTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: AppMetrics.br6,
        border: Border.all(color: t.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.code,
              size: 32,
              color: t.textTertiary,
            ),
            const SizedBox(height: AppMetrics.space8),
            Text(
              'Parsed request will appear here',
              style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载预览
  Widget _buildLoadingPreview() {
    final t = context.appTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: AppMetrics.br6,
        border: Border.all(color: t.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: AppMetrics.space12),
            Text(
              'Parsing...',
              style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误预览
  Widget _buildErrorPreview(CurlImportState state) {
    final t = context.appTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.errorSoft,
        borderRadius: AppMetrics.br6,
        border: Border.all(color: t.error),
      ),
      padding: const EdgeInsets.all(AppMetrics.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: t.error,
              ),
              const SizedBox(width: AppMetrics.space8),
              Text(
                'Parse Error',
                style: AppTextStyles.caption12.copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppMetrics.space8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                state.errorMessage ?? 'Unknown error',
                style: AppTextStyles.tiny11.copyWith(
                  fontWeight: FontWeight.w400,
                  color: t.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成功预览
  Widget _buildSuccessPreview(HttpRequest request, List<String> warnings) {
    final t = context.appTheme;

    // 初始化名称控制器
    if (_nameController.text.isEmpty) {
      _nameController.text = request.name;
    }

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: AppMetrics.br6,
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppMetrics.space12,
              vertical: AppMetrics.space8,
            ),
            decoration: BoxDecoration(
              color: t.brandSoft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppMetrics.radius6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: t.brand,
                ),
                const SizedBox(width: 6),
                Text(
                  'Parsed Successfully',
                  style: AppTextStyles.tiny11.copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.brand,
                  ),
                ),
                if (warnings.isNotEmpty) ...[
                  const SizedBox(width: AppMetrics.space8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.warningSoft,
                      borderRadius: AppMetrics.br4,
                    ),
                    child: Text(
                      '${warnings.length} warning${warnings.length > 1 ? 's' : ''}',
                      style: AppTextStyles.micro10.copyWith(
                        fontWeight: FontWeight.w500,
                        color: t.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 请求详情
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppMetrics.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 请求名称编辑
                  _buildNameEditField(),
                  const SizedBox(height: AppMetrics.space12),
                  // 目标 Collection 选择
                  _buildCollectionSelector(),
                  const SizedBox(height: AppMetrics.space12),
                  const AppDivider(),
                  const SizedBox(height: AppMetrics.space12),
                  _buildPreviewRow(
                    'Method',
                    request.method.value.toUpperCase(),
                    valueColor: _getMethodColor(request.method),
                  ),
                  _buildPreviewRow('URL', request.url),
                  if (request.headers.isNotEmpty)
                    _buildPreviewRow(
                      'Headers',
                      '${request.headers.where((h) => h.enabled).length} enabled',
                    ),
                  if (request.bodyType != 'none')
                    _buildPreviewRow(
                      'Body Type',
                      request.bodyType,
                    ),
                  if (request.body.isNotEmpty)
                    _buildPreviewRow(
                      'Body Size',
                      '${request.body.length} bytes',
                    ),
                  // 设置项
                  if (!request.validateCertificates || request.followRedirects)
                    _buildPreviewRow(
                      'Settings',
                      [
                        if (!request.validateCertificates) 'SSL verify: OFF',
                        if (request.followRedirects) 'Follow redirects: ON',
                      ].join(', '),
                      valueColor: t.textSecondary,
                    ),
                  // 警告信息
                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: AppMetrics.space8),
                    Container(
                      padding: const EdgeInsets.all(AppMetrics.space8),
                      decoration: BoxDecoration(
                        color: t.warningSoft,
                        borderRadius: AppMetrics.br4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warnings:',
                            style: AppTextStyles.micro10.copyWith(
                              color: t.warning,
                            ),
                          ),
                          const SizedBox(height: AppMetrics.space4),
                          ...warnings.map(
                            (w) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '• $w',
                                style: AppTextStyles.micro10.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: t.warning,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建预览行
  Widget _buildPreviewRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    final t = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.tiny11.copyWith(
                fontWeight: FontWeight.w400,
                color: t.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.tiny11.copyWith(
                color: valueColor ?? t.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取 HTTP 方法颜色
  Color _getMethodColor(HttpMethod method) => AppColors.method(method.value);

  /// 构建请求名称编辑字段
  Widget _buildNameEditField() {
    final t = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Name',
          style: AppTextStyles.tiny11.copyWith(
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: AppMetrics.space4),
        AppTextField(
          controller: _nameController,
          hintText: 'Enter request name...',
        ),
      ],
    );
  }

  /// 构建 Collection 选择器
  Widget _buildCollectionSelector() {
    final t = context.appTheme;
    final collectionsAsync = ref.watch(collectionProvider);

    return collectionsAsync.when(
      data: (collections) {
        if (collections.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppMetrics.space8),
            decoration: BoxDecoration(
              color: t.errorSoft,
              borderRadius: AppMetrics.br6,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: t.error,
                ),
                const SizedBox(width: AppMetrics.space8),
                Expanded(
                  child: Text(
                    'No collections available. Please create a collection first.',
                    style: AppTextStyles.tiny11.copyWith(
                      fontWeight: FontWeight.w400,
                      color: t.error,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 初始化默认选择
        if (_selectedCollectionId == null && collections.isNotEmpty) {
          _selectedCollectionId = collections.first.id;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save to Collection',
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
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(AppMetrics.space8),
        decoration: BoxDecoration(
          color: t.errorSoft,
          borderRadius: AppMetrics.br6,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: t.error,
            ),
            const SizedBox(width: AppMetrics.space8),
            Expanded(
              child: Text(
                'Failed to load collections',
                style: AppTextStyles.tiny11.copyWith(
                  fontWeight: FontWeight.w400,
                  color: t.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 从剪贴板粘贴
  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null) {
        _textController.text = data!.text!;
        ref.read(curlImportProvider.notifier).updateInput(data.text!);
        logInfo('Pasted from clipboard');
      }
    } catch (e) {
      logError('Failed to paste from clipboard', e);
    }
  }

  /// 解析 cURL 命令
  Future<void> _parse() async {
    await ref.read(curlImportProvider.notifier).parse();
  }

  /// 导入并打开请求（由外壳对话框的 actions 经 GlobalKey 调用）
  void importAndOpen(bool justImport) {
    final state = ref.read(curlImportProvider);
    if (state.request == null) return;

    final request = state.request!;

    // 使用用户编辑的名称
    final editedName = _nameController.text.trim();
    final finalRequest =
        editedName.isNotEmpty ? request.copyWith(name: editedName) : request;

    // 如果有选择 Collection，先保存到 Collection
    final selectedCollectionId = _selectedCollectionId;
    if (selectedCollectionId != null) {
      ref
          .read(collectionProvider.notifier)
          .addRequestToCollection(selectedCollectionId, finalRequest);
    }

    // 打开请求 Tab
    ref.read(requestTabProvider.notifier).openTab(finalRequest);

    if (!justImport) {
      // TODO: 触发发送请求
      // 这里可以添加发送请求的逻辑
    }

    logInfo('Imported cURL request: ${finalRequest.name}');
    Navigator.of(context).pop();
  }
}
