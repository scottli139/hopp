import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_method.dart';
import '../../models/http_request.dart';
import '../../models/key_value_pair.dart';
import '../../providers/providers.dart';
import '../../utils/app_logger.dart';
import '../../utils/constants.dart';
import '../../utils/testing/ui_test_mode.dart';
import '../../utils/url_params_sync.dart';
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
  final _methodMenuController = MenuController();
  final _rawContentTypeMenuController = MenuController();
  final _settingsScrollController = ScrollController();
  String? _lastTabId;

  // 防止 URL 和 Params 循环更新的标志位
  bool _isSyncingFromUrl = false;
  bool _isSyncingFromParams = false;

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

  // Key-Value 输入框的 Controller 缓存
  final Map<int, TextEditingController> _keyControllers = {};
  final Map<int, TextEditingController> _valueControllers = {};

  // 防抖定时器
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // 恢复上次选中的编辑器 Tab，避免布局重建后被重置回 Params
    final savedIndex = ref.read(requestEditorTabIndexProvider).clamp(0, 4);
    _tabController =
        TabController(length: 5, vsync: this, initialIndex: savedIndex);
    _tabController.addListener(_persistTabIndex);
  }

  /// 将当前编辑器 Tab 索引持久化到 provider（动画结束后才写入）
  void _persistTabIndex() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (ref.read(requestEditorTabIndexProvider) != index) {
      ref.read(requestEditorTabIndexProvider.notifier).state = index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_persistTabIndex);
    _tabController.dispose();
    _urlController.dispose();
    _nameController.dispose();
    _urlFocusNode.dispose();
    _settingsScrollController.dispose();
    // _methodMenuController doesn't need dispose
    _removeAutocompleteOverlay();
    for (final node in _keyFocusNodes.values) {
      node.dispose();
    }
    for (final controller in _keyControllers.values) {
      controller.dispose();
    }
    for (final controller in _valueControllers.values) {
      controller.dispose();
    }
    _updateTimer?.cancel();
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
      // 构建完整的 URL（包含查询参数）
      final fullUrl = syncParamsToUrl(
        activeTab.request.url,
        activeTab.request.params,
      );
      _urlController.text = fullUrl;
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
        final index =
            ['params', 'headers', 'body', 'auth', 'settings'].indexOf(current);
        if (index != -1 && _tabController.index != index) {
          _tabController.animateTo(index);
          AppLogger.info(
              '[RequestEditor] Tab switched to: $current (index: $index)');
        }
      }
    });

    // 监听展开 Method 下拉菜单指令
    ref.listen(uiTestExpandMethodDropdownProvider, (previous, current) {
      if (current != null && current != previous) {
        _methodMenuController.open();
        AppLogger.info('[RequestEditor] Method dropdown expanded');
      }
    });

    // 监听展开 Raw Content Type 下拉菜单指令
    ref.listen(uiTestExpandRawContentTypeDropdownProvider, (previous, current) {
      if (current != null && current != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_rawContentTypeMenuController.isOpen) {
            _rawContentTypeMenuController.open();
            AppLogger.info(
                '[RequestEditor] Raw content type dropdown expanded');
          }
        });
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
              _buildSettingsTab(context, ref, activeTab.request),
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
            child: MenuAnchor(
              controller: _methodMenuController,
              menuChildren: HttpMethod.values.map((method) {
                final color = _getMethodColor(method.value);
                return MenuItemButton(
                  onPressed: () {
                    _updateRequest(ref, request.copyWith(method: method));
                  },
                  style: MenuItemButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      method.value,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
              builder: (context, controller, child) {
                return GestureDetector(
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMethodMenuItem(request.method.value,
                            _getMethodColor(request.method.value)),
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.outline,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                  // URL → Params 同步
                  if (!_isSyncingFromParams) {
                    _isSyncingFromUrl = true;
                    try {
                      final params = parseQueryParamsFromUrl(value);
                      final baseUrl = extractBaseUrl(value);
                      _updateRequest(
                        ref,
                        request.copyWith(
                          url: baseUrl,
                          params: params,
                        ),
                      );
                      // 注意：不更新 _urlController.text，保持用户输入的完整 URL
                      // 查询参数会同步显示在 Params Tab 中
                    } finally {
                      _isSyncingFromUrl = false;
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spaceM),
          // Save button - always clickable
          SizedBox(
            height: 36,
            width: 36,
            child: _buildSaveButton(context, ref, request),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.2,
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

  /// 构建保存按钮 - 确保总是可点击
  Widget _buildSaveButton(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final theme = Theme.of(context);
    final isDirty = ref.watch(activeTabProvider)?.isDirty ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppLogger.info('[RequestEditor] Save button tapped, isDirty: $isDirty');
        _handleSaveButtonPress(ref, request);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDirty
              ? AppColors.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: isDirty
                ? AppColors.primary.withOpacity(0.3)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.save,
            size: 18,
            color: isDirty ? AppColors.primary : theme.colorScheme.outline,
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
              // Settings Tab
              _buildTabItem(
                context: context,
                icon: Icons.settings_outlined,
                label: 'Settings',
                isActive: _tabController.index == 4,
                onTap: () => _tabController.animateTo(4),
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
    // Params → URL 同步的更新函数
    HttpRequest updateRequestWithParams(List<KeyValuePair> params) {
      // 同步 Params 到 URL
      if (!_isSyncingFromUrl) {
        _isSyncingFromParams = true;
        try {
          // 从 provider 读取最新的 request，避免使用捕获的旧 request
          final currentRequest = ref.read(activeTabProvider)?.request;
          final effectiveRequest = currentRequest ?? request;
          final baseUrl = extractBaseUrl(effectiveRequest.url);
          final newUrl = syncParamsToUrl(baseUrl, params);
          // Sync params to URL
          _urlController.text = newUrl;
          return effectiveRequest.copyWith(
            url: baseUrl,
            params: params,
          );
        } finally {
          _isSyncingFromParams = false;
        }
      }
      // Skipped sync because _isSyncingFromUrl=true
      return request.copyWith(params: params);
    }

    return _buildKeyValueEditor(
      context,
      ref,
      request,
      request.params,
      updateRequestWithParams,
      showAutocomplete: false,
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
      showAutocomplete: true,
    );
  }

  Widget _buildKeyValueEditor(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
    List<KeyValuePair> items,
    HttpRequest Function(List<KeyValuePair>) updateFn, {
    bool showAutocomplete = false,
  }) {
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
                showAutocomplete: showAutocomplete,
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
          // 先把当前 controller 中的值同步到 items
          final updatedItems = <KeyValuePair>[];
          for (var i = 0; i < items.length; i++) {
            final keyController = _keyControllers[i];
            final valueController = _valueControllers[i];
            updatedItems.add(
              items[i].copyWith(
                key: keyController?.text ?? items[i].key,
                value: valueController?.text ?? items[i].value,
              ),
            );
          }
          // 然后添加新行
          final newItems = [...updatedItems, _createEmptyKeyValue()];
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
    bool showAutocomplete = false,
  }) {
    final theme = Theme.of(context);
    final item = items[index];

    // 使用缓存的 Controller，避免每次重建都创建新的
    final keyController = _keyControllers.putIfAbsent(
      index,
      () => TextEditingController(text: item.key),
    );
    final valueController = _valueControllers.putIfAbsent(
      index,
      () => TextEditingController(text: item.value),
    );

    // 如果 item 的值变化了，更新 controller
    if (keyController.text != item.key) {
      keyController.text = item.key;
    }
    if (valueController.text != item.value) {
      valueController.text = item.value;
    }

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
                onChanged: showAutocomplete
                    ? (value) {
                        // 只显示自动完成，不更新 provider
                        _showAutocompleteOverlay(context, keyLayerLink,
                            keyFocusNode, index, value, items, updateFn, ref);
                      }
                    : null,
                onSubmitted: (_) {
                  // 回车时更新 provider（从 controller 读取最新值）
                  final newItems = [...items];
                  newItems[index] = item.copyWith(
                    key: keyController.text,
                    value: valueController.text,
                  );
                  _updateRequest(ref, updateFn(newItems));
                },
                onEditingComplete: () {
                  // 编辑完成时更新 provider（从 controller 读取最新值）
                  final newItems = [...items];
                  newItems[index] = item.copyWith(
                    key: keyController.text,
                    value: valueController.text,
                  );
                  _updateRequest(ref, updateFn(newItems));
                },
              ),
            ),
          ),
          // Info icon for common headers (只在 Headers tab 显示)
          if (showAutocomplete && isCommonHeader)
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
              onSubmitted: (_) {
                // 回车时更新 provider（从 controller 读取最新值）
                final newItems = [...items];
                newItems[index] = item.copyWith(
                  key: keyController.text,
                  value: valueController.text,
                );
                _updateRequest(ref, updateFn(newItems));
              },
              onEditingComplete: () {
                // 编辑完成时更新 provider（从 controller 读取最新值）
                final newItems = [...items];
                newItems[index] = item.copyWith(
                  key: keyController.text,
                  value: valueController.text,
                );
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
                // 清理被删除行的 controller
                _cleanupControllers(newItems.length);
              },
              tooltip: 'Delete',
              splashRadius: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 清理多余的 controller
  void _cleanupControllers(int itemCount) {
    // 清理超出 itemCount 的 controller
    _keyControllers.removeWhere((index, controller) {
      if (index >= itemCount) {
        controller.dispose();
        return true;
      }
      return false;
    });
    _valueControllers.removeWhere((index, controller) {
      if (index >= itemCount) {
        controller.dispose();
        return true;
      }
      return false;
    });
    // 清理对应的 FocusNode 和 LayerLink
    _keyFocusNodes.removeWhere((index, node) {
      if (index >= itemCount) {
        node.dispose();
        return true;
      }
      return false;
    });
    _keyLayerLinks.removeWhere((index, link) => index >= itemCount);
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
        // Body type selector - Postman 风格 Radio 组
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
          child: _buildBodyTypeSelector(context, ref, request),
        ),
        // Body content area
        Expanded(
          child: _buildBodyContent(context, ref, request),
        ),
      ],
    );
  }

  /// 构建 Body 内容区域（根据类型显示不同内容）
  Widget _buildBodyContent(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    switch (request.bodyType) {
      case 'none':
        return _buildNoneBodyView(context);
      case 'form-data':
        return _buildFormDataView(context, ref, request);
      case 'x-www-form-urlencoded':
        return _buildUrlEncodedView(context, ref, request);
      case 'raw':
        return _buildRawBodyView(context, ref, request);
      case 'binary':
        return _buildBinaryBodyView(context, ref, request);
      case 'graphql':
        return _buildGraphQLView(context, ref, request);
      default:
        return _buildNoneBodyView(context);
    }
  }

  /// 构建 "none" 类型的 Body 视图
  Widget _buildNoneBodyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
            'Select a body type to add content',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.outline.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 form-data 视图
  Widget _buildFormDataView(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    // TODO: 实现 form-data Key-Value 编辑器（含文件上传）
    return Center(
      child: Text(
        'form-data editor (coming soon)',
        style: AppTextStyles.body.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  /// 构建 x-www-form-urlencoded 视图
  Widget _buildUrlEncodedView(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    // TODO: 实现 x-www-form-urlencoded Key-Value 编辑器
    return Center(
      child: Text(
        'x-www-form-urlencoded editor (coming soon)',
        style: AppTextStyles.body.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  /// 构建 raw 类型的 Body 视图
  Widget _buildRawBodyView(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final language = _getLanguageForRawContentType(request.rawContentType);

    return CodeEditor(
      key: ValueKey('code_editor_${request.id}'),
      code: request.body,
      language: language,
      expands: true,
      onChanged: (value) {
        _updateRequest(ref, request.copyWith(body: value));
      },
    );
  }

  /// 构建 binary 类型的 Body 视图
  Widget _buildBinaryBodyView(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    // TODO: 实现文件选择器
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_file,
            size: 48,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select file',
            style: AppTextStyles.body.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // TODO: 打开文件选择器
            },
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  /// 构建 GraphQL 视图
  Widget _buildGraphQLView(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    // TODO: 实现 GraphQL 双栏编辑器
    return Center(
      child: Text(
        'GraphQL editor (coming soon)',
        style: AppTextStyles.body.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  /// 构建 Body 类型选择器 - Postman 风格 Radio 组
  Widget _buildBodyTypeSelector(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final options = [
      _BodyTypeOption('none', 'none'),
      _BodyTypeOption('form-data', 'form-data'),
      _BodyTypeOption('x-www-form-urlencoded', 'x-www-form-urlencoded'),
      _BodyTypeOption('raw', 'raw'),
      _BodyTypeOption('binary', 'binary'),
      _BodyTypeOption('graphql', 'GraphQL'),
    ];

    return Row(
      children: [
        // Radio 组
        Expanded(
          child: Wrap(
            spacing: 0,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = request.bodyType == option.value;
              return _buildBodyTypeRadio(
                context: context,
                option: option,
                isSelected: isSelected,
                onTap: () {
                  _updateRequest(
                    ref,
                    request.copyWith(bodyType: option.value),
                  );
                },
              );
            }).toList(),
          ),
        ),
        // Raw 子类型下拉菜单
        if (request.bodyType == 'raw')
          _buildRawContentTypeDropdown(context, ref, request),
      ],
    );
  }

  /// 构建单个 Radio 选项
  Widget _buildBodyTypeRadio({
    required BuildContext context,
    required _BodyTypeOption option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Radio 圆圈
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.outline,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              // 标签文字
              Text(
                option.label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onSurface
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

  /// 构建 Raw 子类型下拉菜单
  Widget _buildRawContentTypeDropdown(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final theme = Theme.of(context);
    final contentTypes = ['Text', 'JavaScript', 'JSON', 'HTML', 'XML'];

    return Container(
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: MenuAnchor(
        controller: _rawContentTypeMenuController,
        menuChildren: contentTypes.map((type) {
          return MenuItemButton(
            style: MenuItemButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              _updateRequest(
                ref,
                request.copyWith(rawContentType: type.toLowerCase()),
              );
            },
            child: Text(
              type,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        builder: (context, controller, child) {
          return GestureDetector(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    request.rawContentType.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 根据 raw content type 获取代码语言
  CodeLanguage _getLanguageForRawContentType(String rawContentType) {
    switch (rawContentType.toLowerCase()) {
      case 'json':
        return CodeLanguage.json;
      case 'javascript':
      case 'js':
        return CodeLanguage.javascript;
      case 'html':
        return CodeLanguage.html;
      case 'xml':
        return CodeLanguage.xml;
      case 'text':
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

  /// 构建 Settings Tab（Request Settings）
  Widget _buildSettingsTab(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final theme = Theme.of(context);

    return Scrollbar(
      controller: _settingsScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _settingsScrollController,
        padding: const EdgeInsets.all(AppConstants.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SSL 证书验证设置
            _buildSettingsSection(
              context: context,
              title: 'SSL/TLS',
              children: [
                _buildSwitchTile(
                  context: context,
                  title: 'Enable SSL certificate verification',
                  subtitle: 'Verify the server\'s SSL certificate chain',
                  value: request.validateCertificates,
                  onChanged: (value) {
                    final updatedRequest = request.copyWith(
                      validateCertificates: value,
                    );
                    _updateRequest(ref, updatedRequest);
                  },
                ),
                const SizedBox(height: AppConstants.spaceM),
                // 提示信息
                Container(
                  padding: const EdgeInsets.all(AppConstants.spaceM),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: AppConstants.spaceS),
                      Expanded(
                        child: Text(
                          'Disable this option to allow self-signed certificates or bypass certificate errors for testing purposes.',
                          style: AppTextStyles.tiny.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceXL),
            // 重定向设置
            _buildSettingsSection(
              context: context,
              title: 'Redirects',
              children: [
                _buildSwitchTile(
                  context: context,
                  title: 'Follow redirects',
                  subtitle: 'Automatically follow HTTP 3xx redirects',
                  value: request.followRedirects,
                  onChanged: (value) {
                    final updatedRequest = request.copyWith(
                      followRedirects: value,
                    );
                    _updateRequest(ref, updatedRequest);
                  },
                ),
                const SizedBox(height: AppConstants.spaceM),
                // Max redirects (only show when followRedirects is enabled)
                if (request.followRedirects)
                  _buildNumberInputTile(
                    context: context,
                    title: 'Maximum redirects',
                    subtitle:
                        'Limit the number of redirects to follow (0 = unlimited)',
                    value: request.maxRedirects,
                    min: 0,
                    max: 50,
                    onChanged: (value) {
                      final updatedRequest = request.copyWith(
                        maxRedirects: value,
                      );
                      _updateRequest(ref, updatedRequest);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceXL),
            // 更多设置将在未来版本中实现
            _buildSettingsSection(
              context: context,
              title: 'Coming Soon',
              children: [
                _buildDisabledTile(
                  context: context,
                  title: 'Request timeout',
                  subtitle: 'Set the request timeout duration',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建设置分组
  Widget _buildSettingsSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.tiny.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppConstants.spaceM),
        Container(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// 构建开关设置项
  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.tiny.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Switch with custom size and colors (Small: 28x16px)
            Transform.scale(
              scale: 0.6, // Material Switch 默认约 40x24，缩小到 60% = 24x14
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: theme.colorScheme.outlineVariant,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            // Status text
            Text(
              value ? 'ON' : 'OFF',
              style: AppTextStyles.caption.copyWith(
                color: value ? AppColors.primary : theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建禁用的设置项（未来功能）
  Widget _buildDisabledTile({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.tiny.copyWith(
                  color: theme.colorScheme.outline.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.lock_outline,
          size: 16,
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ],
    );
  }

  /// 构建数字输入设置项
  Widget _buildNumberInputTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.tiny.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.spaceM),
        // Number input with +/- buttons
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement button
              InkWell(
                onTap: value > min ? () => onChanged(value - 1) : null,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: value > min
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
              // Value display
              Container(
                width: 40,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: theme.colorScheme.outlineVariant),
                    right: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Text(
                  value.toString(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Increment button
              InkWell(
                onTap: value < max ? () => onChanged(value + 1) : null,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: value < max
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  /// Handle save button press - always allow save
  void _handleSaveButtonPress(WidgetRef ref, HttpRequest request) {
    // Always allow save - if no changes, just save current state
    // This allows saving newly created requests immediately
    _saveRequest(ref, request);
  }

  void _saveRequest(WidgetRef ref, HttpRequest request) async {
    AppLogger.info('[RequestEditor] Saving request: ${request.id}');

    try {
      // Use the new saveRequest method that handles both new and existing requests
      // This will auto-create a default collection if none exists
      await ref.read(collectionProvider.notifier).saveRequest(request);
      ref.read(requestTabProvider.notifier).markAsSaved(request.id);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request saved to collection'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('[RequestEditor] Failed to save request', e);

      // Show user-friendly error feedback
      String errorMessage = 'Failed to save request';
      if (e.toString().contains('collection')) {
        errorMessage = 'Unable to save: Collection error. Please try again.';
      }

      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveRequest(ref, request),
            ),
          ),
        );
      }
    }
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
    return AppColors.getHttpMethodColor(method);
  }
}

/// Body 类型选项数据类
class _BodyTypeOption {
  final String value;
  final String label;

  const _BodyTypeOption(this.value, this.label);
}
