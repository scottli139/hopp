import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_method.dart';
import '../../models/http_request.dart';
import '../../models/key_value_pair.dart';
import '../../providers/providers.dart';
import '../../utils/app_logger.dart';
import '../../utils/constants.dart';
import '../../utils/testing/ui_test_mode.dart';
import '../common/code_editor.dart';

class RequestEditor extends ConsumerStatefulWidget {
  const RequestEditor({super.key});

  @override
  ConsumerState<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends ConsumerState<RequestEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _urlFocusNode = FocusNode();
  String? _lastTabId;

  // 常见 HTTP Headers 用于自动完成和提示
  static const Map<String, String> _commonHeaders = {
    'Accept': 'Media types that are acceptable for the response',
    'Accept-Charset': 'Character sets that are acceptable',
    'Accept-Encoding': 'List of acceptable encodings (gzip, deflate, br)',
    'Accept-Language': 'List of acceptable human languages',
    'Authorization': 'Authentication credentials (Bearer token, Basic auth)',
    'Cache-Control': 'Directives for caching mechanisms',
    'Connection': 'Control options for the current connection (keep-alive)',
    'Content-Length': 'The length of the request body in octets',
    'Content-Type': 'The MIME type of the body (application/json)',
    'Cookie': 'An HTTP cookie previously sent by the server',
    'Host': 'The domain name of the server (and optional port)',
    'Origin': 'Indicates where a fetch originates from',
    'Referer': 'The address of the previous web page',
    'User-Agent': 'The user agent string of the client',
    'X-Requested-With': 'Used to identify AJAX requests',
  };

  // Header key 输入框的 FocusNode 和 Overlay 控制
  final Map<int, FocusNode> _keyFocusNodes = {};
  final Map<int, LayerLink> _keyLayerLinks = {};
  OverlayEntry? _autocompleteOverlay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _nameController.dispose();
    _urlFocusNode.dispose();
    _removeAutocompleteOverlay();
    for (final node in _keyFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// 移除自动完成下拉框
  void _removeAutocompleteOverlay() {
    _autocompleteOverlay?.remove();
    _autocompleteOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeTabProvider);

    if (activeTab == null) {
      return const Center(child: Text('Select a request'));
    }

    // Only update controllers when tab changes, not on every build
    if (_lastTabId != activeTab.id) {
      _lastTabId = activeTab.id;
      _urlController.text = activeTab.request.url;
      _nameController.text = activeTab.request.name;
    }

    // 监听测试模式的 URL 输入框 focus 指令
    ref.listen(uiTestFocusUrlInputProvider, (previous, current) {
      if (current != null && current != previous) {
        _urlFocusNode.requestFocus();
      }
    });

    // 监听测试模式的 Request Tab 切换指令
    ref.listen(uiTestRequestTabProvider, (previous, current) {
      if (current != null && current != previous) {
        final index = ['params', 'headers', 'body', 'auth'].indexOf(current);
        if (index != -1 && _tabController.index != index) {
          _tabController.animateTo(index);
        }
      }
    });

    return Column(
      children: [
        // URL bar
        _buildUrlBar(context, ref, activeTab.request),
        // Tabs
        _buildCustomTabs(context, activeTab.request),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildParamsTab(context, ref, activeTab.request),
              _buildHeadersTab(context, ref, activeTab.request),
              _buildBodyTab(context, ref, activeTab.request),
              _buildAuthTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUrlBar(
      BuildContext context, WidgetRef ref, HttpRequest request) {
    final theme = Theme.of(context);
    const fontSize = 13.0;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Method dropdown - 使用固定高度 36px
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                left: BorderSide(color: theme.colorScheme.outlineVariant),
                top: BorderSide(color: theme.colorScheme.outlineVariant),
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppConstants.radiusM),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<HttpMethod>(
                value: request.method,
                isDense: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.outline,
                  size: 18,
                ),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.0,
                ),
                items: HttpMethod.values.map((method) {
                  final color = _getMethodColor(method.value);
                  return DropdownMenuItem<HttpMethod>(
                    value: method,
                    child: _buildMethodMenuItem(method.value, color),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateRequest(ref, request.copyWith(method: value));
                  }
                },
                dropdownColor: theme.colorScheme.surface,
                menuMaxHeight: 280,
                alignment: AlignmentDirectional.centerStart,
              ),
            ),
          ),
          // URL input - 使用固定高度 36px（包含边框和背景）
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _urlController,
                focusNode: _urlFocusNode,
                decoration: InputDecoration(
                  hintText: 'Enter URL',
                  hintStyle: TextStyle(
                    fontSize: fontSize,
                    color: theme.colorScheme.outline,
                    height: 1.0,
                  ),
                  // 背景色设置
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  // 调整 padding 使内容垂直居中（36px 高度 - 14px 字体）/ 2 ≈ 11px
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 11,
                  ),
                  // 非 focus 状态的边框（灰色）
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(AppConstants.radiusM),
                    ),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1.0,
                    ),
                  ),
                  // Focus 状态的紫色边框
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(AppConstants.radiusM),
                    ),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: fontSize,
                  color: theme.colorScheme.onSurface,
                  height: 1.0,
                ),
                onChanged: (value) {
                  _updateRequest(ref, request.copyWith(url: value));
                },
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spaceM),
          // Save button
          SizedBox(
            height: 36,
            width: 36,
            child: _buildIconButton(
              context: context,
              icon: Icons.save,
              tooltip: 'Save to collection',
              onPressed: () {
                final isDirty = ref.read(activeTabProvider)?.isDirty ?? false;
                if (isDirty) _saveRequest(ref, request);
              },
              isActive: ref.watch(activeTabProvider)?.isDirty ?? false,
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppConstants.spaceS),
          // Send button
          SizedBox(
            height: 36,
            child: _buildSendButton(context, ref, request),
          ),
        ],
      ),
    );
  }

  /// 构建 Method 下拉菜单项
  Widget _buildMethodMenuItem(String method, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              method,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isActive = false,
    Color? activeColor,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? (activeColor ?? theme.colorScheme.primary)
                      .withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: isActive
                    ? (activeColor ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.3)
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? activeColor ?? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        onTap: () => _sendRequest(ref, request),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.send,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Send',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建自定义 Tab 栏（参考 Postman 样式）
  Widget _buildCustomTabs(BuildContext context, HttpRequest request) {
    final theme = Theme.of(context);
    const tabHeight = 32.0;

    // 计算 enabled 且非空的 params 和 headers 数量
    final paramsCount =
        request.params.where((p) => p.enabled && p.key.isNotEmpty).length;
    final headersCount =
        request.headers.where((h) => h.enabled && h.key.isNotEmpty).length;
    final hasBodyContent =
        request.body.isNotEmpty && request.bodyType != 'none';

    return Container(
      height: tabHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return Row(
            children: [
              // Params Tab
              _buildTabItem(
                context: context,
                icon: Icons.tune,
                label: 'Params',
                badge: paramsCount > 0 ? paramsCount.toString() : null,
                isActive: _tabController.index == 0,
                onTap: () => _tabController.animateTo(0),
              ),
              // Headers Tab
              _buildTabItem(
                context: context,
                icon: Icons.http,
                label: 'Headers',
                badge: headersCount > 0 ? headersCount.toString() : null,
                isActive: _tabController.index == 1,
                onTap: () => _tabController.animateTo(1),
              ),
              // Body Tab (with dot indicator)
              _buildTabItem(
                context: context,
                icon: Icons.code,
                label: 'Body',
                hasDot: hasBodyContent,
                isActive: _tabController.index == 2,
                onTap: () => _tabController.animateTo(2),
              ),
              // Auth Tab
              _buildTabItem(
                context: context,
                icon: Icons.lock_outline,
                label: 'Auth',
                isActive: _tabController.index == 3,
                onTap: () => _tabController.animateTo(3),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建单个 Tab 项
  Widget _buildTabItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? badge,
    bool hasDot = false,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: isActive
                    ? AppColors.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // Badge (count)
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.15)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              // Dot indicator (for Body tab)
              if (hasDot)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParamsTab(
      BuildContext context, WidgetRef ref, HttpRequest request) {
    return _buildKeyValueEditor(
      context,
      ref,
      request,
      request.params,
      (params) => request.copyWith(params: params),
    );
  }

  Widget _buildHeadersTab(
      BuildContext context, WidgetRef ref, HttpRequest request) {
    return _buildKeyValueEditor(
      context,
      ref,
      request,
      request.headers,
      (headers) => request.copyWith(headers: headers),
    );
  }

  Widget _buildKeyValueEditor(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
    List<KeyValuePair> items,
    HttpRequest Function(List<KeyValuePair>) updateFn,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header row - 参考 Postman 的表头样式
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              // Checkbox 列
              const SizedBox(width: 32),
              const SizedBox(width: 12),
              // Key 列
              Expanded(
                flex: 2,
                child: Text(
                  'Key',
                  style: AppTextStyles.tiny.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Value 列
              Expanded(
                flex: 3,
                child: Text(
                  'Value',
                  style: AppTextStyles.tiny.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Description 列（可选）
              Expanded(
                flex: 2,
                child: Text(
                  'Description',
                  style: AppTextStyles.tiny.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
        // Items list
        Expanded(
          child: ListView.builder(
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
                // Add new row
                return _buildAddNewRow(context, ref, items, updateFn);
              }
              return _buildKeyValueRow(
                context: context,
                ref: ref,
                request: request,
                items: items,
                index: index,
                updateFn: updateFn,
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建 "Add new" 行
  Widget _buildAddNewRow(
    BuildContext context,
    WidgetRef ref,
    List<KeyValuePair> items,
    HttpRequest Function(List<KeyValuePair>) updateFn,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final newItems = [...items, _createEmptyKeyValue()];
          _updateRequest(ref, updateFn(newItems));
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const SizedBox(width: 32),
              const SizedBox(width: 12),
              Icon(
                Icons.add,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Add new',
                style: AppTextStyles.caption.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建 Key-Value 行（参考 Postman 样式）
  Widget _buildKeyValueRow({
    required BuildContext context,
    required WidgetRef ref,
    required HttpRequest request,
    required List<KeyValuePair> items,
    required int index,
    required HttpRequest Function(List<KeyValuePair>) updateFn,
  }) {
    final theme = Theme.of(context);
    final item = items[index];
    final keyController = TextEditingController(text: item.key);
    final valueController = TextEditingController(text: item.value);

    // 获取或创建 FocusNode 和 LayerLink
    final keyFocusNode = _keyFocusNodes.putIfAbsent(index, () => FocusNode());
    final keyLayerLink = _keyLayerLinks.putIfAbsent(index, () => LayerLink());

    // 检查是否是常见 header
    final headerDescription = _commonHeaders[item.key];
    final isCommonHeader = headerDescription != null;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Checkbox - 更紧凑
          SizedBox(
            width: 32,
            child: Checkbox(
              value: item.enabled,
              onChanged: (value) {
                final newItems = [...items];
                newItems[index] = item.copyWith(enabled: value ?? true);
                _updateRequest(ref, updateFn(newItems));
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 12),
          // Key input with autocomplete
          Expanded(
            flex: 2,
            child: CompositedTransformTarget(
              link: keyLayerLink,
              child: TextField(
                controller: keyController,
                focusNode: keyFocusNode,
                decoration: InputDecoration(
                  hintText: 'Key',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: isCommonHeader
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface,
                ),
                onChanged: (value) {
                  final newItems = [...items];
                  newItems[index] = item.copyWith(key: value);
                  _updateRequest(ref, updateFn(newItems));
                  _showAutocompleteOverlay(context, keyLayerLink, keyFocusNode,
                      index, value, items, updateFn, ref);
                },
              ),
            ),
          ),
          // Info icon for common headers
          if (isCommonHeader)
            Tooltip(
              message: headerDescription,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          const SizedBox(width: 4),
          // Value input
          Expanded(
            flex: 3,
            child: TextField(
              controller: valueController,
              decoration: InputDecoration(
                hintText: _getValueHint(item.key),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
              ),
              style: TextStyle(
                fontSize: 12,
                color: _isCalculatedValue(item.key)
                    ? theme.colorScheme.outline
                    : theme.colorScheme.onSurface,
              ),
              onChanged: (value) {
                final newItems = [...items];
                newItems[index] = item.copyWith(value: value);
                _updateRequest(ref, updateFn(newItems));
              },
            ),
          ),
          const SizedBox(width: 12),
          // Description（显示 header 说明，如果是常见 header）
          Expanded(
            flex: 2,
            child: isCommonHeader
                ? Tooltip(
                    message: headerDescription,
                    child: Text(
                      headerDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tiny.copyWith(
                        color: theme.colorScheme.outline.withOpacity(0.7),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Delete button
          SizedBox(
            width: 32,
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 16,
                color: theme.colorScheme.outline,
              ),
              onPressed: () {
                final newItems = [...items]..removeAt(index);
                _updateRequest(ref, updateFn(newItems));
              },
              tooltip: 'Delete',
              splashRadius: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示自动完成下拉框
  void _showAutocompleteOverlay(
    BuildContext context,
    LayerLink layerLink,
    FocusNode focusNode,
    int index,
    String query,
    List<KeyValuePair> items,
    HttpRequest Function(List<KeyValuePair>) updateFn,
    WidgetRef ref,
  ) {
    // 移除之前的 overlay
    _removeAutocompleteOverlay();

    if (query.isEmpty) {
      return;
    }

    // 过滤匹配的 headers
    final matches = _commonHeaders.keys
        .where((header) => header.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    if (matches.isEmpty) {
      return;
    }

    final overlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 200,
          child: CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 32),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: matches.map((header) {
                    return InkWell(
                      onTap: () {
                        final newItems = [...items];
                        newItems[index] = items[index].copyWith(key: header);
                        _updateRequest(ref, updateFn(newItems));
                        _removeAutocompleteOverlay();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                header,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );

    _autocompleteOverlay = overlay;
    Overlay.of(context).insert(overlay);

    // 当失去焦点时移除 overlay
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _removeAutocompleteOverlay();
        });
      }
    });
  }

  /// 获取 value 的提示文本
  String _getValueHint(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey == 'content-type') {
      return 'application/json';
    } else if (lowerKey == 'authorization') {
      return 'Bearer token';
    } else if (lowerKey == 'accept') {
      return 'application/json';
    }
    return 'Value';
  }

  /// 检查是否是自动计算的值
  bool _isCalculatedValue(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey == 'content-length' || lowerKey == 'host';
  }

  Widget _buildBodyTab(
      BuildContext context, WidgetRef ref, HttpRequest request) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Body type selector - 使用 Tab 风格设计
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceL,
            vertical: AppConstants.spaceS,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Content Type',
                style: AppTextStyles.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppConstants.spaceM),
              Expanded(
                child: _buildContentTypeSelector(context, ref, request),
              ),
            ],
          ),
        ),
        // Body editor with syntax highlighting
        if (request.bodyType != 'none')
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spaceL),
              child: _buildBodyEditor(context, ref, request),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    ),
                    child: Icon(
                      Icons.block,
                      size: 32,
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No body content',
                    style: AppTextStyles.body.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a content type to add body',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.outline.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 构建 Content Type 选择器 - 使用统一的 Tab 风格
  Widget _buildContentTypeSelector(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final theme = Theme.of(context);
    final options = [
      _ContentTypeOption('none', 'None', Icons.block),
      _ContentTypeOption('json', 'JSON', Icons.data_object),
      _ContentTypeOption('text', 'Text', Icons.text_fields),
      _ContentTypeOption('form', 'Form', Icons.format_list_bulleted),
    ];

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = request.bodyType == option.value;
          return _buildContentTypeButton(
            context: context,
            option: option,
            isSelected: isSelected,
            onTap: () {
              _updateRequest(ref, request.copyWith(bodyType: option.value));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentTypeButton({
    required BuildContext context,
    required _ContentTypeOption option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radiusS - 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusS - 2),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusS - 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                option.label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyEditor(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final language = _getLanguageForBodyType(request.bodyType);

    // Use CodeEditor for JSON with syntax highlighting
    if (language == CodeLanguage.json) {
      return CodeEditor(
        code: request.body,
        language: CodeLanguage.json,
        expands: true,
        onChanged: (value) {
          _updateRequest(ref, request.copyWith(body: value));
        },
      );
    }

    // Fallback to SimpleCodeEditor for other types
    return SimpleCodeEditor(
      code: request.body,
      language: language,
      expands: true,
      onChanged: (value) {
        _updateRequest(ref, request.copyWith(body: value));
      },
    );
  }

  CodeLanguage _getLanguageForBodyType(String bodyType) {
    switch (bodyType) {
      case 'json':
        return CodeLanguage.json;
      case 'xml':
        return CodeLanguage.xml;
      case 'html':
        return CodeLanguage.html;
      case 'text':
      case 'form':
      default:
        return CodeLanguage.text;
    }
  }

  Widget _buildAuthTab(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  void _updateRequest(WidgetRef ref, HttpRequest updatedRequest) {
    final activeTabId = ref.read(activeTabIdProvider);
    if (activeTabId != null) {
      ref.read(requestTabProvider.notifier).updateRequest(
            activeTabId,
            updatedRequest,
          );
      // Mark as dirty in the provider
      ref.read(dirtyRequestsProvider.notifier).update((set) {
        return {...set, activeTabId};
      });
    }
  }

  void _saveRequest(WidgetRef ref, HttpRequest request) {
    AppLogger.info('[RequestEditor] Saving request: ${request.id}');
    ref.read(collectionProvider.notifier).updateRequestInCollection(request);
    ref.read(requestTabProvider.notifier).markAsSaved(request.id);

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request saved to collection'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sendRequest(WidgetRef ref, HttpRequest request) {
    final activeTabId = ref.read(activeTabIdProvider);
    if (activeTabId != null) {
      ref.read(requestResponseProvider.notifier).sendRequest(
            activeTabId,
            request,
          );
    }
  }

  KeyValuePair _createEmptyKeyValue() {
    return KeyValuePair.empty();
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

/// Content Type 选项数据类
class _ContentTypeOption {
  final String value;
  final String label;
  final IconData icon;

  const _ContentTypeOption(this.value, this.label, this.icon);
}
