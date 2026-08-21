/// cURL 导入对话框
///
/// 支持粘贴和编辑 cURL 命令，解析后导入为 Hopp 请求。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/http_method.dart';
import '../../../models/http_request.dart';
import '../../../providers/collection/collection_provider.dart';
import '../../../providers/curl/curl_import_provider.dart';
import '../../../providers/request/request_tab_provider.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/constants.dart';
import '../common/app_popup_menu.dart';

/// 显示 cURL 导入对话框
Future<void> showCurlImportDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CurlImportDialog(),
  );
}

/// cURL 导入对话框
class CurlImportDialog extends ConsumerStatefulWidget {
  const CurlImportDialog({super.key});

  @override
  ConsumerState<CurlImportDialog> createState() => _CurlImportDialogState();
}

class _CurlImportDialogState extends ConsumerState<CurlImportDialog>
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.terminal, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Import from cURL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 输入区域
            Expanded(
              flex: 2,
              child: _buildInputArea(state, theme),
            ),
            const SizedBox(height: 16),
            // 解析结果预览
            Expanded(
              flex: 3,
              child: _buildPreviewArea(state, theme),
            ),
          ],
        ),
      ),
      actions: _buildActions(state),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea(CurlImportState state, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签和粘贴按钮行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'cURL Command',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton.icon(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste, size: 14),
              label: const Text(
                'Paste',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 文本输入框
        Expanded(
          child: TextField(
            controller: _textController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              fontFamily: 'Menlo',
              fontSize: 11,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: 'Paste cURL command here...\n\n'
                  'Example:\n'
                  'curl -X POST https://api.example.com/users \\\n'
                  '  -H "Content-Type: application/json" \\\n'
                  '  -d \'{"name":"John"}\'',
              hintStyle: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 11,
                color: theme.colorScheme.outline.withOpacity(0.7),
                height: 1.4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              ref.read(curlImportProvider.notifier).updateInput(value);
            },
          ),
        ),
        // 解析按钮
        if (state.isIdle || state.isError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: state.isParsing ? null : _parse,
                  icon: state.isParsing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Parse'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 构建预览区域
  Widget _buildPreviewArea(CurlImportState state, ThemeData theme) {
    if (state.isParsing) {
      return _buildLoadingPreview(theme);
    }

    if (state.isError) {
      return _buildErrorPreview(state, theme);
    }

    if (state.isSuccess && state.request != null) {
      return _buildSuccessPreview(state.request!, state.warnings, theme);
    }

    return _buildEmptyPreview(theme);
  }

  /// 构建空预览
  Widget _buildEmptyPreview(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.code,
              size: 32,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Parsed request will appear here',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载预览
  Widget _buildLoadingPreview(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text(
              'Parsing...',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误预览
  Widget _buildErrorPreview(CurlImportState state, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Parse Error',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                state.errorMessage ?? 'Unknown error',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成功预览
  Widget _buildSuccessPreview(
    HttpRequest request,
    List<String> warnings,
    ThemeData theme,
  ) {
    // 初始化名称控制器
    if (_nameController.text.isEmpty) {
      _nameController.text = request.name;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusM),
                topRight: Radius.circular(AppConstants.radiusM),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Parsed Successfully',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (warnings.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${warnings.length} warning${warnings.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.orange,
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 请求名称编辑
                  _buildNameEditField(theme),
                  const SizedBox(height: 12),
                  // 目标 Collection 选择
                  _buildCollectionSelector(theme),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildPreviewRow(
                      'Method', request.method.value.toUpperCase(), theme,
                      valueColor: _getMethodColor(request.method)),
                  _buildPreviewRow('URL', request.url, theme),
                  if (request.headers.isNotEmpty)
                    _buildPreviewRow(
                      'Headers',
                      '${request.headers.where((h) => h.enabled).length} enabled',
                      theme,
                    ),
                  if (request.bodyType != 'none')
                    _buildPreviewRow(
                      'Body Type',
                      request.bodyType,
                      theme,
                    ),
                  if (request.body.isNotEmpty)
                    _buildPreviewRow(
                      'Body Size',
                      '${request.body.length} bytes',
                      theme,
                    ),
                  // 设置项
                  if (!request.validateCertificates || request.followRedirects)
                    _buildPreviewRow(
                      'Settings',
                      [
                        if (!request.validateCertificates) 'SSL verify: OFF',
                        if (request.followRedirects) 'Follow redirects: ON',
                      ].join(', '),
                      theme,
                      valueColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  // 警告信息
                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warnings:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...warnings.map((w) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '• $w',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              )),
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
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取 HTTP 方法颜色
  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return const Color(0xFF3B82F6);
      case HttpMethod.post:
        return const Color(0xFF10B981);
      case HttpMethod.put:
        return const Color(0xFFF59E0B);
      case HttpMethod.delete:
        return const Color(0xFFEF4444);
      case HttpMethod.patch:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  /// 构建请求名称编辑字段
  Widget _buildNameEditField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Name',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _nameController,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Enter request name...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.outline.withOpacity(0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  /// 构建 Collection 选择器
  Widget _buildCollectionSelector(ThemeData theme) {
    final collectionsAsync = ref.watch(collectionProvider);

    return collectionsAsync.when(
      data: (collections) {
        if (collections.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No collections available. Please create a collection first.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.error,
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            AppPopupSelect<String>(
              value: _selectedCollectionId,
              hint: 'Select Collection',
              boxed: true,
              fontSize: 13,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load collections',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  List<Widget> _buildActions(CurlImportState state) {
    // 成功状态 - 显示导入按钮
    if (state.isSuccess && state.request != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _importAndOpen(false),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          child: const Text('Import & Send'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => _importAndOpen(true),
          child: const Text('Import'),
        ),
      ];
    }

    // 其他状态 - 只显示取消
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    ];
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

  /// 导入并打开请求
  void _importAndOpen(bool justImport) {
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
