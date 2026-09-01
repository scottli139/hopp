import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/auth_config.dart';
import '../../models/http_method.dart';
import '../../models/http_request.dart';
import '../../models/key_value_pair.dart';
import '../../providers/providers.dart';
import '../../services/ai/ai_models.dart';
import '../../services/auth_resolver.dart';
import '../../utils/app_logger.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../../utils/testing/ui_test_mode.dart';
import '../../utils/url_params_sync.dart';
import '../common/app_badge.dart';
import '../common/app_button.dart';
import '../common/app_empty_state.dart';
import '../common/app_controls.dart';
import '../common/app_popup_menu.dart';
import '../common/app_tabs.dart';
import '../common/code_editor.dart';
import '../common/variable_highlight_controller.dart';
import '../ai/build_request_dialog.dart';
import 'assertion_editor.dart';
import 'auth_config_editor.dart';
import 'pre_request_chain_editor.dart';
import 'variable_fx_menu.dart';

class RequestEditor extends ConsumerStatefulWidget {
  const RequestEditor({super.key});

  @override
  ConsumerState<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends ConsumerState<RequestEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = VariableHighlightController();
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

  // Key-Value 输入框的 Controller 缓存（value 列带 {{var}} 管道高亮）
  final Map<int, TextEditingController> _keyControllers = {};
  final Map<int, VariableHighlightController> _valueControllers = {};

  // Body raw 编辑器的 Controller/FocusNode 缓存（fx 变量插入需要操作光标）
  final Map<String, CodeController> _bodyControllers = {};
  final Map<String, FocusNode> _bodyFocusNodes = {};

  // 防抖定时器
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // 恢复上次选中的编辑器 Tab，避免布局重建后被重置回 Params
    final savedIndex = ref.read(requestEditorTabIndexProvider).clamp(0, 6);
    _tabController =
        TabController(length: 7, vsync: this, initialIndex: savedIndex);
    _tabController.addListener(_persistTabIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 刷新 URL / KV 高亮的主题色（主题切换时重建会重新取色）
    _urlController.appTheme = context.appTheme;
    for (final controller in _valueControllers.values) {
      controller.appTheme = context.appTheme;
    }
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
    for (final node in _bodyFocusNodes.values) {
      node.dispose();
    }
    for (final controller in _bodyControllers.values) {
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
      return const AppEmptyState(
        icon: Icons.tab_outlined,
        title: 'Select a request',
        subtitle: 'Select a request from the sidebar or create a new one',
      );
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
    } else if (!_urlFocusNode.hasFocus) {
      // 同一 Tab 下模型被外部更新（test-mode set_url、导入等）时同步回 URL 栏，
      // 避免输入框显示过期值（输入即提交保证常态下 controller 与模型一致）
      final fullUrl = syncParamsToUrl(
        activeTab.request.url,
        activeTab.request.params,
      );
      if (_urlController.text != fullUrl) {
        _urlController.text = fullUrl;
      }
    }

    // 监听测试模式的 URL 输入框 focus 指令
    ref.listen(uiTestFocusUrlInputProvider, (previous, current) {
      if (current != null && current != previous) {
        _urlFocusNode.requestFocus();
      }
    });

    // 监听测试模式的 Request Tab 切换指令（payload 带时间戳，同值重设也触发）
    ref.listen(uiTestRequestTabProvider, (previous, current) {
      if (current != null && current != previous) {
        final tab = current['tab'] as String?;
        final index = [
          'params',
          'headers',
          'body',
          'auth',
          'prerequest',
          'assertions',
          'settings'
        ].indexOf(tab ?? '');
        if (index != -1 && _tabController.index != index) {
          _tabController.animateTo(index);
          AppLogger.info(
              '[RequestEditor] Tab switched to: $tab (index: $index)');
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
              _buildAuthTab(context, ref, activeTab.request),
              _buildPreRequestTab(context, ref, activeTab.request),
              _buildAssertionsTab(context, ref, activeTab.request),
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
    final appTheme = context.appTheme;

    return Container(
      padding: const EdgeInsets.all(AppMetrics.space12),
      decoration: BoxDecoration(
        color: appTheme.background,
        border: Border(
          bottom: BorderSide(color: appTheme.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // F9.5：自然语言建请求（AI）入口，Method 下拉左侧
          NaturalLanguageRequestButton(
            currentRequest: request,
            onApply: (draft) => _applyAiRequestDraft(ref, request, draft),
          ),
          const SizedBox(width: AppMetrics.space8),
          // Method dropdown - 统一 32px 高（设计规范）
          Container(
            height: AppMetrics.height32,
            decoration: BoxDecoration(
              color: appTheme.background,
              border: Border(
                left: BorderSide(color: appTheme.borderStrong),
                top: BorderSide(color: appTheme.borderStrong),
                bottom: BorderSide(color: appTheme.borderStrong),
              ),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppMetrics.radius6),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MenuAnchor(
              controller: _methodMenuController,
              style: AppPopupMenu.menuStyle(theme),
              menuChildren: HttpMethod.values.map((method) {
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
                  child: MethodBadge(method.value),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MethodBadge(request.method.value),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        color: appTheme.textTertiary,
                        size: 18,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // URL input - 统一 32px 高（设计规范），白底 + borderStrong 描边
          Expanded(
            child: SizedBox(
              height: AppMetrics.height32,
              child: TextField(
                controller: _urlController,
                focusNode: _urlFocusNode,
                decoration: InputDecoration(
                  hintText: 'Enter URL',
                  hintStyle: AppTextStyles.code12.copyWith(
                    color: appTheme.textTertiary,
                    height: 1.0,
                  ),
                  // 背景色设置
                  filled: true,
                  fillColor: appTheme.background,
                  // 调整 padding 使内容垂直居中
                  // （32px 高度 - 边框 - 12px 字体）/ 2 ≈ 9px
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  // 非 focus 状态的边框
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(AppMetrics.radius6),
                    ),
                    borderSide: BorderSide(
                      color: appTheme.borderStrong,
                      width: 1.0,
                    ),
                  ),
                  // Focus 状态的品牌色边框
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(AppMetrics.radius6),
                    ),
                    borderSide: BorderSide(
                      color: appTheme.brand,
                      width: 1.5,
                    ),
                  ),
                ),
                style: AppTextStyles.code12.copyWith(
                  color: appTheme.textPrimary,
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
          const SizedBox(width: AppMetrics.space12),
          // 未定义变量警告（存在 {{var}} 无法解析时显示）
          ..._buildUnresolvedWarning(context, ref),
          // Save button - always clickable
          _buildSaveButton(context, ref, request),
          const SizedBox(width: AppMetrics.space8),
          // Send button
          _buildSendButton(context, ref, request),
        ],
      ),
    );
  }

  /// 构建未定义变量警告图标
  ///
  /// 当请求的 URL/Params/Headers/Body 中存在无法解析的 {{variable}} 时，
  /// 在 Send 按钮前显示警告标记，提示用户检查环境变量配置。
  List<Widget> _buildUnresolvedWarning(BuildContext context, WidgetRef ref) {
    final unresolved = ref.watch(unresolvedVariablesProvider);
    if (unresolved.isEmpty) return const [];

    final theme = Theme.of(context);
    return [
      Tooltip(
        message: 'Unresolved variables: ${unresolved.join(', ')}',
        child: Icon(
          key: const Key('url_bar_unresolved_warning'),
          Icons.warning_amber_rounded,
          size: 18,
          color: theme.colorScheme.error,
        ),
      ),
      const SizedBox(width: AppMetrics.space8),
    ];
  }

  Widget _buildSendButton(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    return AppButton.primary(
      label: 'Send',
      icon: Icons.send,
      onPressed: () => _sendRequest(ref, request),
    );
  }

  /// 构建保存按钮 - 确保总是可点击
  Widget _buildSaveButton(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final isDirty = ref.watch(activeTabProvider)?.isDirty ?? false;

    return AppIconButton(
      icon: Icons.save,
      tooltip: 'Save',
      bordered: true,
      color: isDirty ? context.appTheme.brand : null,
      onPressed: () {
        AppLogger.info('[RequestEditor] Save button tapped, isDirty: $isDirty');
        _handleSaveButtonPress(ref, request);
      },
    );
  }

  /// 构建自定义 Tab 栏（AppTabs 统一组件）
  Widget _buildCustomTabs(BuildContext context, HttpRequest request) {
    // 计算 enabled 且非空的 params 和 headers 数量
    final paramsCount =
        request.params.where((p) => p.enabled && p.key.isNotEmpty).length;
    final headersCount =
        request.headers.where((h) => h.enabled && h.key.isNotEmpty).length;
    final hasBodyContent =
        request.body.isNotEmpty && request.bodyType != 'none';

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return AppTabs(
          tabs: [
            AppTabItem(
              icon: Icons.tune,
              label: 'Params',
              count: paramsCount > 0 ? paramsCount : null,
            ),
            AppTabItem(
              icon: Icons.http,
              label: 'Headers',
              count: headersCount > 0 ? headersCount : null,
            ),
            AppTabItem(
              icon: Icons.code,
              label: 'Body',
              dot: hasBodyContent,
            ),
            const AppTabItem(icon: Icons.lock_outline, label: 'Auth'),
            AppTabItem(
              icon: Icons.account_tree_outlined,
              label: 'Pre-request',
              count: request.preRequestChain.isNotEmpty
                  ? request.preRequestChain.length
                  : null,
            ),
            AppTabItem(
              icon: Icons.fact_check_outlined,
              label: 'Assertions',
              count: request.assertions.isNotEmpty
                  ? request.assertions.length
                  : null,
            ),
            const AppTabItem(icon: Icons.settings_outlined, label: 'Settings'),
          ],
          selectedIndex: _tabController.index,
          onChanged: (index) => _tabController.animateTo(index),
        );
      },
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
    final appTheme = context.appTheme;

    return Column(
      children: [
        // Header row - 中性色表头（设计规范 kv-head 样式）
        Container(
          height: AppMetrics.height32,
          padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space12),
          decoration: BoxDecoration(
            color: appTheme.surfaceVariant,
            border: Border(
              bottom: BorderSide(color: appTheme.border),
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
                  style: AppTextStyles.tiny11.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appTheme.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Value 列
              Expanded(
                flex: 3,
                child: Text(
                  'Value',
                  style: AppTextStyles.tiny11.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appTheme.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Description 列（可选）
              Expanded(
                flex: 2,
                child: Text(
                  'Description',
                  style: AppTextStyles.tiny11.copyWith(
                    fontWeight: FontWeight.w600,
                    color: appTheme.textTertiary,
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
      color: AppColors.transparent,
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
                style: AppTextStyles.caption12.copyWith(
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
      () => VariableHighlightController()
        ..text = item.value
        ..appTheme = context.appTheme,
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

    // 提交当前行到 provider（controller 为唯一实时输入源）。
    // 输入即提交：仅靠回车提交时，直接点 Send 或任意重建都会
    // 触发上方同步回写，把未提交的输入抹掉。
    void commitRow() {
      final newItems = [...items];
      newItems[index] = item.copyWith(
        key: keyController.text,
        value: valueController.text,
      );
      _updateRequest(ref, updateFn(newItems));
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Checkbox - 更紧凑
          SizedBox(
            width: 32,
            child: Center(
              child: AppCheckbox(
                value: item.enabled,
                onChanged: (value) {
                  final newItems = [...items];
                  newItems[index] = item.copyWith(enabled: value);
                  _updateRequest(ref, updateFn(newItems));
                },
              ),
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
                  hintStyle: AppTextStyles.caption12.copyWith(
                    color: theme.colorScheme.outline.withValues(alpha: 0.7),
                  ),
                ),
                style: AppTextStyles.caption12.copyWith(
                  color: isCommonHeader
                      ? context.appTheme.textPrimary
                      : context.appTheme.textPrimary,
                ),
                onChanged: (value) {
                  commitRow();
                  if (showAutocomplete) {
                    // 自动完成只读输入，不另行提交
                    _showAutocompleteOverlay(context, keyLayerLink,
                        keyFocusNode, index, value, items, updateFn, ref);
                  }
                },
                onSubmitted: (_) => commitRow(),
                onEditingComplete: commitRow,
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
          // Value input（右端常驻 fx 菜单：动态变量插入 + 解析预览 + 函数插入，F8.5 起无需先输入 {{）
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    hintText: _getValueHint(item.key),
                    isDense: true,
                    contentPadding: const EdgeInsets.only(
                      left: 8,
                      right: 26,
                      top: 8,
                      bottom: 8,
                    ),
                    border: InputBorder.none,
                    hintStyle: AppTextStyles.caption12.copyWith(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  style: AppTextStyles.caption12.copyWith(
                    color: _isCalculatedValue(item.key)
                        ? theme.colorScheme.outline
                        : context.appTheme.textPrimary,
                  ),
                  onChanged: (_) => commitRow(),
                  onSubmitted: (_) => commitRow(),
                  onEditingComplete: commitRow,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: VariableFxMenu(
                    controller: valueController,
                    onInserted: commitRow,
                  ),
                ),
              ],
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
                      style: AppTextStyles.tiny11.copyWith(
                        color: theme.colorScheme.outline.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Delete button
          SizedBox(
            width: 32,
            child: Center(
              child: AppIconButton(
                icon: Icons.delete_outline,
                tooltip: 'Delete',
                onPressed: () {
                  final newItems = [...items]..removeAt(index);
                  _updateRequest(ref, updateFn(newItems));
                  // 清理被删除行的 controller
                  _cleanupControllers(newItems.length);
                },
              ),
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
              borderRadius: AppMetrics.br6,
              child: Container(
                decoration: BoxDecoration(
                  color: context.appTheme.background,
                  borderRadius: AppMetrics.br6,
                  border: Border.all(
                    color: context.appTheme.border.withValues(alpha: 0.5),
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
                                style: AppTextStyles.caption12,
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
    return Column(
      children: [
        // Body type selector - Postman 风格 Radio 组
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.space16,
            vertical: AppMetrics.space8,
          ),
          decoration: BoxDecoration(
            color: context.appTheme.background,
            border: Border(
              bottom: BorderSide(color: context.appTheme.border),
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
              color: context.appTheme.surfaceVariant,
              borderRadius: AppMetrics.br8,
            ),
            child: Icon(
              Icons.block,
              size: 32,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No body content',
            style: AppTextStyles.body13.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a body type to add content',
            style: AppTextStyles.body13.copyWith(
              color: theme.colorScheme.outline.withValues(alpha: 0.7),
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
        style: AppTextStyles.body13.copyWith(
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
        style: AppTextStyles.body13.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  /// 构建 raw 类型的 Body 视图
  ///
  /// 顶部带变量辅助工具条（F8.5 方案 A）：fx 菜单在光标处插入
  /// `{{$timestampMs}}` / 管道函数片段（body 发送前统一做变量替换，
  /// 见 VariableResolver.resolveRequest）。
  Widget _buildRawBodyView(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final language = _getLanguageForRawContentType(request.rawContentType);
    final controller = _bodyControllers.putIfAbsent(
      request.id,
      () => CodeController(
        text: request.body,
        language: codeLanguageMode(language),
      ),
    );
    final focusNode =
        _bodyFocusNodes.putIfAbsent(request.id, () => FocusNode());

    return Column(
      children: [
        _buildBodyAssistBar(context, controller, focusNode),
        Expanded(
          child: CodeEditor(
            key: ValueKey('code_editor_${request.id}'),
            code: request.body,
            controller: controller,
            focusNode: focusNode,
            language: language,
            expands: true,
            onChanged: (value) {
              _updateRequest(ref, request.copyWith(body: value));
            },
          ),
        ),
      ],
    );
  }

  /// Body 辅助工具条：右侧 fx 菜单（插入后回焦编辑器）
  Widget _buildBodyAssistBar(
    BuildContext context,
    CodeController controller,
    FocusNode focusNode,
  ) {
    final t = context.appTheme;
    return Container(
      height: AppMetrics.height32,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space8),
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Text(
            'BODY',
            style: AppTextStyles.micro10.copyWith(
              color: t.textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const Spacer(),
          VariableFxMenu(
            controller: controller,
            onInserted: focusNode.requestFocus,
          ),
        ],
      ),
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
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select file',
            style: AppTextStyles.body13.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          AppButton.secondary(
            label: 'Choose File',
            icon: Icons.upload_file,
            onPressed: () {
              // TODO: 打开文件选择器
            },
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
        style: AppTextStyles.body13.copyWith(
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
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppMetrics.br4,
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
                        ? AppColors.brand
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
                            color: AppColors.brand,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              // 标签文字
              Text(
                option.label,
                style: AppTextStyles.caption12.copyWith(
                  color: isSelected
                      ? context.appTheme.textPrimary
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
        color: context.appTheme.surfaceVariant,
        borderRadius: AppMetrics.br4,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: MenuAnchor(
        controller: _rawContentTypeMenuController,
        style: AppPopupMenu.menuStyle(theme),
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
              style: AppTextStyles.caption12.copyWith(
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
                    style: AppTextStyles.caption12.copyWith(
                      color: context.appTheme.textPrimary,
                      fontWeight: FontWeight.w500,
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

  /// 构建 Auth Tab（F8.1 认证配置）
  ///
  /// 请求级配置，支持 Inherit（继承集合）/ No Auth / Bearer / Basic /
  /// API Key；Inherit 态展示继承链解析结果。
  Widget _buildAuthTab(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final collectionsById = ref.watch(collectionsByIdProvider);

    String? inheritedSummary;
    if (request.auth.type == AuthType.inherit) {
      final source = AuthResolver.inheritedFrom(request, collectionsById);
      if (source != null) {
        if (source.auth.type == AuthType.none) {
          inheritedSummary = '继承自集合「${source.name}」：No Auth，发送时不附加认证信息。';
        } else {
          inheritedSummary =
              '当前继承自集合「${source.name}」：${_authTypeLabel(source.auth.type)}。修改请到集合设置。';
        }
      }
    }

    return AuthConfigEditor(
      auth: request.auth,
      allowInherit: true,
      inheritedSummary: inheritedSummary,
      onChanged: (auth) {
        _updateRequest(ref, request.copyWith(auth: auth));
      },
    );
  }

  /// Auth 类型的展示名（与 AuthConfigEditor 类型列表一致）
  static String _authTypeLabel(AuthType type) {
    switch (type) {
      case AuthType.inherit:
        return 'Inherit';
      case AuthType.none:
        return 'No Auth';
      case AuthType.bearer:
        return 'Bearer Token';
      case AuthType.basic:
        return 'Basic Auth';
      case AuthType.apiKey:
        return 'API Key';
    }
  }

  /// 构建 Pre-request Tab（F8.2 预请求链）
  ///
  /// 步骤引用集合中已保存请求；链为空 = 未配置（发送时继承集合默认链）。
  /// 试运行就地执行链，不发目标请求。
  Widget _buildPreRequestTab(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    return PreRequestChainEditor(
      chain: request.preRequestChain,
      retryOn401: request.preRequestRetryOn401,
      ownerId: request.id,
      excludeRequestId: request.id,
      onChainChanged: (chain) {
        _updateRequest(ref, request.copyWith(preRequestChain: chain));
      },
      onRetryChanged: (v) {
        _updateRequest(ref, request.copyWith(preRequestRetryOn401: v));
      },
      onTestRun: () {
        ref
            .read(requestResponseProvider.notifier)
            .testRunPreRequestChain(request.id, request.preRequestChain);
      },
    );
  }

  /// 构建 Assertions Tab（F4.1 断言规则）
  ///
  /// 请求级配置，随请求持久化；每次 Send 后由引擎求值，结果在响应区
  /// Tests 页签展示。
  Widget _buildAssertionsTab(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    return AssertionEditor(
      assertions: request.assertions,
      onChanged: (assertions) {
        _updateRequest(ref, request.copyWith(assertions: assertions));
      },
    );
  }

  /// 构建 Settings Tab（Request Settings）
  Widget _buildSettingsTab(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
  ) {
    final t = context.appTheme;

    return Scrollbar(
      controller: _settingsScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _settingsScrollController,
        padding: const EdgeInsets.all(AppMetrics.space16),
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
                const SizedBox(height: AppMetrics.space12),
                // 提示信息
                Container(
                  padding: const EdgeInsets.all(AppMetrics.space12),
                  decoration: BoxDecoration(
                    color: t.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: AppMetrics.br6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: t.textTertiary,
                      ),
                      const SizedBox(width: AppMetrics.space8),
                      Expanded(
                        child: Text(
                          'Disable this option to allow self-signed certificates or bypass certificate errors for testing purposes.',
                          style: AppTextStyles.tiny11.copyWith(
                            color: t.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppMetrics.space24),
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
                const SizedBox(height: AppMetrics.space12),
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
            const SizedBox(height: AppMetrics.space24),
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
    final t = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.tiny11.copyWith(
            fontWeight: FontWeight.w600,
            color: t.textTertiary,
          ),
        ),
        const SizedBox(height: AppMetrics.space12),
        Container(
          padding: const EdgeInsets.all(AppMetrics.space16),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(
              color: t.border.withValues(alpha: 0.5),
            ),
            borderRadius: AppMetrics.br6,
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
    final t = context.appTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption12.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.tiny11.copyWith(
                  color: t.textTertiary,
                ),
              ),
            ],
          ),
        ),
        AppSwitch(value: value, onChanged: onChanged),
      ],
    );
  }

  /// 构建禁用的设置项（未来功能）
  Widget _buildDisabledTile({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    final t = context.appTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption12.copyWith(
                  fontWeight: FontWeight.w500,
                  color: t.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.tiny11.copyWith(
                  color: t.textTertiary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.lock_outline,
          size: 16,
          color: t.textTertiary.withValues(alpha: 0.5),
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
    final t = context.appTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption12.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.tiny11.copyWith(
                  color: t.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppMetrics.space12),
        // Number input with +/- buttons
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: t.border),
            borderRadius: AppMetrics.br4,
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
                        ? t.textPrimary
                        : t.textTertiary.withValues(alpha: 0.3),
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
                    left: BorderSide(color: t.border),
                    right: BorderSide(color: t.border),
                  ),
                ),
                child: Text(
                  value.toString(),
                  style: AppTextStyles.caption12.copyWith(
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
                        ? t.textPrimary
                        : t.textTertiary.withValues(alpha: 0.3),
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

  /// 应用 AI 生成的请求草稿（F9.5 自然语言建请求）。
  ///
  /// 仅写入当前 tab（保持编辑器未保存态，不强制落库）；URL 栏由
  /// build 期的 controller 同步逻辑自动刷新。
  void _applyAiRequestDraft(
    WidgetRef ref,
    HttpRequest request,
    AiRequestDraft draft,
  ) {
    KeyValuePair toKeyValue(AiKeyValueDraft kv) => KeyValuePair(
          id: const Uuid().v4(),
          key: kv.key,
          value: kv.value,
          enabled: kv.enabled,
        );
    _updateRequest(
      ref,
      request.copyWith(
        method: HttpMethod.fromString(draft.method),
        url: draft.url,
        params: [for (final kv in draft.params) toKeyValue(kv)],
        headers: [for (final kv in draft.headers) toKeyValue(kv)],
        bodyType: draft.bodyType,
        rawContentType: draft.rawContentType ?? request.rawContentType,
        body: draft.body ?? '',
        name: draft.name.isNotEmpty ? draft.name : request.name,
      ),
    );
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
              textColor: AppColors.onBrand,
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
}

/// Body 类型选项数据类
class _BodyTypeOption {
  final String value;
  final String label;

  const _BodyTypeOption(this.value, this.label);
}
