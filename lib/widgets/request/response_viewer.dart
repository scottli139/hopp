import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/certificate_info.dart';
import '../../models/http_request.dart';
import '../../models/http_request_info.dart';
import '../../models/http_response.dart';
import '../../models/key_value_pair.dart';
import '../../models/timing_info.dart';
import '../../providers/request/request_tab_provider.dart';
import '../../providers/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../../utils/testing/ui_test_mode.dart';

import '../common/app_badge.dart';
import '../common/app_divider.dart';
import '../common/app_empty_state.dart';
import '../common/app_tabs.dart';
import '../common/optimized_response_viewer.dart';

// 全局 ScrollController 用于 UI 测试控制滚动
final _certificateScrollController = ScrollController();
final _responseBodyScrollController = ScrollController();

class ResponseViewer extends ConsumerStatefulWidget {
  const ResponseViewer({super.key});

  @override
  ConsumerState<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends ConsumerState<ResponseViewer>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isErrorExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default length, will be updated on first build
    // Default index is 1 (Body tab) for backward compatibility
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
  }

  @override
  void didUpdateWidget(ResponseViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentResponse = ref.read(currentResponseProvider);

    // Reset error expansion when response changes
    if (currentResponse?.error != null) {
      // Keep expansion state if error is the same
    } else {
      _isErrorExpanded = false;
    }

    // Update TabController when certificate info changes
    _updateTabController(currentResponse);
  }

  /// 根据响应获取 Tab 长度
  int _getTabLength(HttpResponse? response) {
    if (response == null) return 4; // Body, Headers, Cookies, Request
    var length = 4; // Base tabs including Request
    if (response.timingInfo != null) length++;
    if (response.certificateInfo != null) length++;
    return length;
  }

  /// 更新 TabController 以匹配当前响应
  void _updateTabController(HttpResponse? response) {
    final newLength = _getTabLength(response);
    if (_tabController == null || _tabController!.length != newLength) {
      _tabController?.dispose();
      // Keep current index if possible, otherwise default to 1 (Body tab)
      final currentIndex = _tabController?.index ?? 1;
      final newIndex = currentIndex < newLength ? currentIndex : 1;
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: newIndex,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// 处理 UI 测试模式的滚动控制
  void _handleUITestScroll() {
    final scrollCommand = ref.watch(uiTestScrollResponseProvider);
    if (scrollCommand != null) {
      final direction = scrollCommand['direction'] as String;
      final amount = scrollCommand['amount'] as int;
      final target = scrollCommand['target'] as String? ?? 'body';
      final timestamp = scrollCommand['timestamp'] as int?;

      final controller = target == 'certificate'
          ? _certificateScrollController
          : _responseBodyScrollController;

      // 使用 timestamp 确保每次都能触发
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !controller.hasClients) return;

        final before = controller.offset;
        double newOffset;

        switch (direction) {
          case 'down':
            newOffset = before + amount;
            break;
          case 'up':
            newOffset = before - amount;
            break;
          default:
            return;
        }

        await controller.animateTo(
          newOffset.clamp(0.0, controller.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );

        // 回写实际滚动结果，供指令回读验证
        if (mounted && controller.hasClients) {
          ref.read(uiTestScrollResponseResultProvider.notifier).state = {
            'target': target,
            'before': before,
            'after': controller.offset,
            'timestamp': timestamp,
          };
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final response = ref.watch(currentResponseProvider);

    // Ensure TabController is synchronized with current response
    _updateTabController(response);

    // Handle UI test mode tab switching
    final targetTab = ref.watch(uiTestTargetTabProvider);

    // Handle UI test mode scroll control
    _handleUITestScroll();
    if (targetTab != null && _tabController != null) {
      // Map tab name to index (动态计算，考虑 Timing Tab)
      final tabIndexMap = <String, int>{};
      var currentIndex = 0;
      tabIndexMap['request'] = currentIndex++;
      tabIndexMap['body'] = currentIndex++;
      tabIndexMap['headers'] = currentIndex++;
      tabIndexMap['cookies'] = currentIndex++;
      if (response?.timingInfo != null) {
        tabIndexMap['timing'] = currentIndex++;
      }
      if (response?.certificateInfo != null) {
        tabIndexMap['certificate'] = currentIndex++;
      }
      final targetIndex = tabIndexMap[targetTab.toLowerCase()];
      if (targetIndex != null && targetIndex < _tabController!.length) {
        if (_tabController!.index != targetIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _tabController!.animateTo(targetIndex);
              // Clear the target after switching
              ref.read(uiTestTargetTabProvider.notifier).state = null;
            }
          });
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.appTheme.border),
        ),
      ),
      child: Column(
        children: [
          // Response info bar
          _buildInfoBar(context, response),
          // Tabs
          if (_tabController != null)
            AnimatedBuilder(
              animation: _tabController!,
              builder: (context, child) {
                return AppTabs(
                  tabs: _buildTabItems(response),
                  selectedIndex: _tabController!.index
                      .clamp(0, _tabController!.length - 1),
                  onChanged: (index) => _tabController!.animateTo(index),
                );
              },
            ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _buildTabContents(context, response),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(BuildContext context, HttpResponse? response) {
    final appTheme = context.appTheme;

    if (response == null) {
      return Container(
        height: AppMetrics.height38,
        padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space12),
        decoration: BoxDecoration(
          color: appTheme.surface,
          border: Border(
            bottom: BorderSide(color: appTheme.border),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 12,
              color: appTheme.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              'No response yet',
              style: AppTextStyles.tiny11.copyWith(
                color: appTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    if (response.error != null) {
      final errorText = response.error!;
      final isLongError = errorText.length > 80;

      return GestureDetector(
        onTap: isLongError
            ? () {
                setState(() {
                  _isErrorExpanded = !_isErrorExpanded;
                });
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            maxHeight: _isErrorExpanded ? 150 : AppMetrics.height38,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.space12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: context.appTheme.errorSoft,
            border: Border(
              bottom: BorderSide(
                color: AppColors.error.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: _isErrorExpanded
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: AppMetrics.br4,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isErrorExpanded
                    ? SingleChildScrollView(
                        child: SelectableText(
                          errorText,
                          style: AppTextStyles.tiny11.copyWith(
                            color: AppColors.error,
                            height: 1.4,
                          ),
                        ),
                      )
                    : Text(
                        errorText,
                        style: AppTextStyles.tiny11.copyWith(
                          color: AppColors.error,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
              ),
              if (isLongError)
                Icon(
                  _isErrorExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
              if (isLongError) const SizedBox(width: 8),
              // Copy error button
              Material(
                color: AppColors.transparent,
                borderRadius: AppMetrics.br4,
                child: InkWell(
                  borderRadius: AppMetrics.br4,
                  onTap: () => _copyToClipboard(errorText),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: AppMetrics.br4,
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.copy,
                      size: 14,
                      color: AppColors.error.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: AppMetrics.height38,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space12),
      decoration: BoxDecoration(
        color: appTheme.background,
        border: Border(
          bottom: BorderSide(
            color: appTheme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status
          StatusChip(
            response.statusCode,
            label: '${response.statusCode} ${response.statusText ?? ''}'.trim(),
          ),
          const SizedBox(width: 14),
          // Time
          Icon(
            Icons.timer_outlined,
            size: 12,
            color: appTheme.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            '${response.durationMs ?? 0} ms',
            style: AppTextStyles.tiny11.copyWith(
              color: appTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          // Size
          Icon(
            Icons.storage_outlined,
            size: 12,
            color: appTheme.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            _formatSize(response.sizeBytes),
            style: AppTextStyles.tiny11.copyWith(
              color: appTheme.textSecondary,
            ),
          ),
          const Spacer(),
          // Copy button
          _buildActionButton(
            context: context,
            icon: Icons.copy,
            tooltip: 'Copy response',
            onPressed: response.body != null
                ? () => _copyToClipboard(response.body!)
                : null,
          ),
          const SizedBox(width: 8),
          // Save button
          _buildActionButton(
            context: context,
            icon: Icons.save,
            tooltip: 'Save response',
            onPressed: response.body != null ? () {} : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: AppColors.transparent,
      borderRadius: AppMetrics.br6,
      child: InkWell(
        borderRadius: AppMetrics.br6,
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: AppMetrics.br6,
              border: Border.all(
                color: onPressed != null
                    ? context.appTheme.textTertiary.withValues(alpha: 0.3)
                    : AppColors.transparent,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: onPressed != null
                  ? context.appTheme.textSecondary
                  : context.appTheme.textTertiary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyTab(BuildContext context, HttpResponse? response) {
    if (response?.body == null) {
      return const AppEmptyState(
        icon: Icons.code_off,
        title: 'No response',
        subtitle: 'Send a request to see the response',
      );
    }

    // Get content type for optimized display
    final contentType = response!.headers
        .firstWhere(
          (h) => h.key.toLowerCase() == 'content-type',
          orElse: () => KeyValuePair.empty(),
        )
        .value;

    // Use optimized response viewer for better performance
    return OptimizedResponseViewer(
      content: response.body!,
      contentType: contentType.isNotEmpty ? contentType : null,
      scrollController: _responseBodyScrollController,
    );
  }

  Widget _buildHeadersTab(BuildContext context, HttpResponse? response) {
    if (response?.headers.isEmpty ?? true) {
      return const AppEmptyState(
        icon: Icons.list_alt_outlined,
        title: 'No headers',
        subtitle: 'Send a request to see response headers',
      );
    }

    final appTheme = context.appTheme;
    return Container(
      color: appTheme.background,
      child: Column(
        children: [
          // Header row - 中性色表头（设计规范 kv-head 样式）
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppMetrics.space16,
              vertical: AppMetrics.space8,
            ),
            decoration: BoxDecoration(
              color: appTheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: appTheme.border),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    'Header Name',
                    style: AppTextStyles.micro10.copyWith(
                      color: appTheme.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Value',
                    style: AppTextStyles.micro10.copyWith(
                      color: appTheme.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Headers list
          Expanded(
            child: ListView.builder(
              itemCount: response!.headers.length,
              itemBuilder: (context, index) {
                final header = response.headers[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppMetrics.space16,
                    vertical: AppMetrics.space8 + 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: appTheme.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 200,
                        child: SelectableText(
                          header.key,
                          style: AppTextStyles.tiny11.copyWith(
                            fontWeight: FontWeight.w600,
                            color: appTheme.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          header.value,
                          style: AppTextStyles.tiny11.copyWith(
                            color: appTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookiesTab(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.cookie_outlined,
      title: 'Cookies',
      subtitle: 'Cookie management coming soon',
    );
  }

  /// 构建完整 URL（包含查询参数）
  String _buildFullUrl(HttpRequest request) {
    final baseUrl = request.url;
    final enabledParams =
        request.params.where((p) => p.enabled && p.key.isNotEmpty).toList();

    if (enabledParams.isEmpty) return baseUrl;

    final queryString = enabledParams
        .map((p) =>
            '${Uri.encodeComponent(p.key)}=${Uri.encodeComponent(p.value)}')
        .join('&');

    final separator = baseUrl.contains('?') ? '&' : '?';
    return '$baseUrl$separator$queryString';
  }

  Widget _buildRequestTab(BuildContext context) {
    final response = ref.watch(currentResponseProvider);

    // 优先使用 response 中的 requestInfo（实际发送的请求信息）
    if (response?.requestInfo != null) {
      return _buildRequestInfoTab(context, response!.requestInfo!);
    }

    // 如果没有 requestInfo，回退到使用当前编辑的请求信息
    final activeTab = ref.watch(activeTabProvider);

    if (activeTab == null) {
      return const AppEmptyState(
        icon: Icons.upload_outlined,
        title: 'No Request',
        subtitle: 'Create a request to see details',
      );
    }

    final request = activeTab.request;
    final fullUrl = _buildFullUrl(request);
    final methodColor = AppColors.method(request.method.value);
    final enabledHeaders =
        request.headers.where((h) => h.enabled && h.key.isNotEmpty).toList();
    final hasBody = request.body.isNotEmpty && request.bodyType != 'none';

    return Container(
      color: context.appTheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 请求概览卡片
            _buildRequestOverviewCard(
              context,
              request,
              fullUrl,
              methodColor,
            ),
            const SizedBox(height: 16),
            // Headers 区域
            if (enabledHeaders.isNotEmpty) ...[
              _buildRequestHeadersSection(context, enabledHeaders),
              const SizedBox(height: 16),
            ],
            // Body 区域
            if (hasBody) ...[
              _buildRequestBodySection(context, request),
            ],
          ],
        ),
      ),
    );
  }

  /// 使用 HttpRequestInfo 构建 Request Tab
  Widget _buildRequestInfoTab(
      BuildContext context, HttpRequestInfo requestInfo) {
    final methodColor = AppColors.method(requestInfo.method);

    return Container(
      color: context.appTheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 请求概览卡片
            _buildRequestInfoOverviewCard(
              context,
              requestInfo,
              methodColor,
            ),
            const SizedBox(height: 16),
            // Headers 区域
            if (requestInfo.headers.isNotEmpty) ...[
              _buildRequestInfoHeadersSection(
                context,
                requestInfo.headers,
                requestInfo.autoHeaderKeys,
              ),
              const SizedBox(height: 16),
            ],
            // Body 区域
            if (requestInfo.hasBody) ...[
              _buildRequestInfoBodySection(context, requestInfo),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestOverviewCard(
    BuildContext context,
    HttpRequest request,
    String fullUrl,
    Color methodColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            methodColor.withValues(alpha: 0.1),
            methodColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppMetrics.br8,
        border: Border.all(color: methodColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HTTP 方法标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: methodColor.withValues(alpha: 0.15),
              borderRadius: AppMetrics.br4,
            ),
            child: Text(
              request.method.value.toUpperCase(),
              style: AppTextStyles.tiny11.copyWith(
                fontWeight: FontWeight.w700,
                color: methodColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 完整 URL
          SelectableText(
            fullUrl,
            style: AppTextStyles.code12.copyWith(
              color: context.appTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestHeadersSection(
    BuildContext context,
    List<KeyValuePair> headers,
  ) {
    return _buildCompactInfoSection(
      context: context,
      title: 'Headers (${headers.length})',
      children: headers.map((header) {
        return _buildCompactInfoRow(
          context,
          header.key,
          header.value,
        );
      }).toList(),
    );
  }

  Widget _buildRequestBodySection(BuildContext context, HttpRequest request) {
    return _buildCompactInfoSection(
      context: context,
      title: 'Body (${request.bodyType})',
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.appTheme.surfaceVariant,
            borderRadius: AppMetrics.br4,
          ),
          child: SelectableText(
            request.body,
            style: AppTextStyles.code11,
          ),
        ),
      ],
    );
  }

  /// 使用 HttpRequestInfo 构建请求概览卡片
  Widget _buildRequestInfoOverviewCard(
    BuildContext context,
    HttpRequestInfo requestInfo,
    Color methodColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            methodColor.withValues(alpha: 0.1),
            methodColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppMetrics.br8,
        border: Border.all(color: methodColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HTTP 方法标签和时间戳
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: 0.15),
                  borderRadius: AppMetrics.br4,
                ),
                child: Text(
                  requestInfo.method.toUpperCase(),
                  style: AppTextStyles.tiny11.copyWith(
                    fontWeight: FontWeight.w700,
                    color: methodColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(requestInfo.timestamp),
                style: AppTextStyles.micro10.copyWith(
                  color: context.appTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 完整 URL
          SelectableText(
            requestInfo.fullUrl,
            style: AppTextStyles.code12.copyWith(
              color: context.appTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // URL 分解信息
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _buildUrlInfoChip(context, 'Scheme', requestInfo.scheme),
              _buildUrlInfoChip(context, 'Host', requestInfo.host),
              if (requestInfo.port != null)
                _buildUrlInfoChip(context, 'Port', '${requestInfo.port}'),
              _buildUrlInfoChip(context, 'Path', requestInfo.path),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建 URL 信息 chip
  Widget _buildUrlInfoChip(BuildContext context, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTextStyles.micro10.copyWith(
            color: context.appTheme.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.code11.copyWith(
            color: context.appTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    final millisecond = timestamp.millisecond.toString().padLeft(3, '0');
    return '$hour:$minute:$second.$millisecond';
  }

  /// 使用 HttpRequestInfo 构建 Headers 区域
  Widget _buildRequestInfoHeadersSection(
    BuildContext context,
    List<KeyValuePair> headers,
    List<String> autoHeaderKeys,
  ) {
    // 将 headers 分为用户添加的和自动添加的（按构建时记录的来源，而非 key 名猜测）
    final autoKeySet = autoHeaderKeys.map((k) => k.toLowerCase()).toSet();
    final userHeaders = <KeyValuePair>[];
    final autoHeaders = <KeyValuePair>[];

    for (final header in headers) {
      if (autoKeySet.contains(header.key.toLowerCase())) {
        autoHeaders.add(header);
      } else {
        userHeaders.add(header);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headers 标题
        Row(
          children: [
            Text(
              'Headers (${headers.length})',
              style: AppTextStyles.micro10.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (userHeaders.isNotEmpty)
              Text(
                '${userHeaders.length} custom',
                style: AppTextStyles.micro10.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.appTheme.textTertiary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Headers 列表
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.appTheme.surfaceVariant,
            borderRadius: AppMetrics.br6,
            border: Border.all(
              color: context.appTheme.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              // 用户添加的 headers
              ...userHeaders.map((header) => _buildRequestInfoHeaderRow(
                    context,
                    header,
                    isAuto: false,
                  )),
              // 自动添加的 headers（如果有用户添加的，显示分隔线）
              if (userHeaders.isNotEmpty && autoHeaders.isNotEmpty) ...[
                const AppDivider(height: 16),
                Text(
                  'Auto-added Headers',
                  style: AppTextStyles.micro10.copyWith(
                    color: context.appTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // 自动添加的 headers
              ...autoHeaders.map((header) => _buildRequestInfoHeaderRow(
                    context,
                    header,
                    isAuto: true,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建单个 header 行
  Widget _buildRequestInfoHeaderRow(
    BuildContext context,
    KeyValuePair header, {
    required bool isAuto,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    header.key,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.micro10.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isAuto
                          ? context.appTheme.textTertiary
                          : AppColors.brand,
                    ),
                  ),
                ),
                if (isAuto) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: context.appTheme.surfaceVariant,
                      borderRadius: AppMetrics.br2,
                    ),
                    child: Text(
                      'auto',
                      style: AppTextStyles.micro10.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.appTheme.textTertiary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SelectableText(
              header.value,
              style: AppTextStyles.code11.copyWith(
                color: context.appTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 使用 HttpRequestInfo 构建 Body 区域
  Widget _buildRequestInfoBodySection(
    BuildContext context,
    HttpRequestInfo requestInfo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Body',
              style: AppTextStyles.micro10.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (requestInfo.bodyType != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: AppMetrics.br4,
                ),
                child: Text(
                  requestInfo.bodyType!.toUpperCase(),
                  style: AppTextStyles.micro10.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
            if (requestInfo.bodySize != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatSize(requestInfo.bodySize),
                style: AppTextStyles.micro10.copyWith(
                  color: context.appTheme.textTertiary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.appTheme.surfaceVariant,
            borderRadius: AppMetrics.br4,
          ),
          child: SelectableText(
            requestInfo.body ?? '',
            style: AppTextStyles.code11,
          ),
        ),
      ],
    );
  }

  Widget _buildTimingTab(BuildContext context, TimingInfo timing) {
    final percentages = timing.getPhasePercentages();

    return Container(
      color: context.appTheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 总时间卡片
            _buildTimingTotalCard(context, timing),
            const SizedBox(height: 16),
            // 各阶段时间详情
            _buildTimingDetailSection(context, timing, percentages),
            const SizedBox(height: 16),
            // 时间线可视化
            _buildTimelineVisualization(context, timing, percentages),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingTotalCard(BuildContext context, TimingInfo timing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brand.withValues(alpha: 0.1),
            AppColors.brand.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppMetrics.br8,
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: AppMetrics.br6,
            ),
            child: const Icon(
              Icons.timer,
              size: 24,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Request Time',
                  style: AppTextStyles.tiny11.copyWith(
                    color: context.appTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timing.totalFormatted,
                  style: AppTextStyles.display20.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingDetailSection(
    BuildContext context,
    TimingInfo timing,
    Map<String, double> percentages,
  ) {
    return _buildCompactInfoSection(
      context: context,
      title: 'Phase Breakdown',
      children: [
        if (timing.dnsMs != null)
          _buildTimingRow(
            context: context,
            label: 'DNS Lookup',
            value: timing.dnsFormatted,
            percentage: percentages['dns'] ?? 0,
            color: AppColors.info,
          ),
        if (timing.tcpMs != null)
          _buildTimingRow(
            context: context,
            label: 'TCP Connect',
            value: timing.tcpFormatted,
            percentage: percentages['tcp'] ?? 0,
            color: AppColors.warning,
          ),
        if (timing.tlsMs != null)
          _buildTimingRow(
            context: context,
            label: 'TLS Handshake',
            value: timing.tlsFormatted,
            percentage: percentages['tls'] ?? 0,
            color: AppColors.success,
          ),
        if (timing.ttfbMs != null)
          _buildTimingRow(
            context: context,
            label: 'TTFB (Time to First Byte)',
            value: timing.ttfbFormatted,
            percentage: percentages['ttfb'] ?? 0,
            color: AppColors.methodPatch,
          ),
        if (timing.downloadMs != null && timing.downloadMs! > 0)
          _buildTimingRow(
            context: context,
            label: 'Download',
            value: timing.downloadFormatted,
            percentage: percentages['download'] ?? 0,
            color: AppColors.methodGet,
          ),
      ],
    );
  }

  Widget _buildTimingRow({
    required BuildContext context,
    required String label,
    required String value,
    required double percentage,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: AppTextStyles.micro10.copyWith(
                    color: context.appTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppMetrics.br2,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: context.appTheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Text(
                  value,
                  style: AppTextStyles.micro10.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appTheme.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 140),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTextStyles.micro10.copyWith(
                fontWeight: FontWeight.w400,
                color: context.appTheme.textTertiary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineVisualization(
    BuildContext context,
    TimingInfo timing,
    Map<String, double> percentages,
  ) {
    return _buildCompactInfoSection(
      context: context,
      title: 'Timeline',
      children: [
        const SizedBox(height: 8),
        // 时间线条形图
        ClipRRect(
          borderRadius: AppMetrics.br4,
          child: Row(
            children: [
              if (timing.dnsMs != null && timing.dnsMs! > 0)
                _buildTimelineSegment(
                  color: AppColors.info,
                  flex: (percentages['dns'] ?? 0).round(),
                ),
              if (timing.tcpMs != null && timing.tcpMs! > 0)
                _buildTimelineSegment(
                  color: AppColors.warning,
                  flex: (percentages['tcp'] ?? 0).round(),
                ),
              if (timing.tlsMs != null && timing.tlsMs! > 0)
                _buildTimelineSegment(
                  color: AppColors.success,
                  flex: (percentages['tls'] ?? 0).round(),
                ),
              if (timing.ttfbMs != null && timing.ttfbMs! > 0)
                _buildTimelineSegment(
                  color: AppColors.methodPatch,
                  flex: (percentages['ttfb'] ?? 0).round(),
                ),
              if (timing.downloadMs != null && timing.downloadMs! > 0)
                _buildTimelineSegment(
                  color: AppColors.methodGet,
                  flex: (percentages['download'] ?? 0).round(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 图例
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (timing.dnsMs != null) _buildLegendItem('DNS', AppColors.info),
            if (timing.tcpMs != null)
              _buildLegendItem('TCP', AppColors.warning),
            if (timing.tlsMs != null)
              _buildLegendItem('TLS', AppColors.success),
            if (timing.ttfbMs != null)
              _buildLegendItem('TTFB', AppColors.methodPatch),
            if (timing.downloadMs != null && timing.downloadMs! > 0)
              _buildLegendItem('Download', AppColors.methodGet),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineSegment({
    required Color color,
    required int flex,
  }) {
    if (flex <= 0) return const SizedBox.shrink();

    return Expanded(
      flex: flex,
      child: Container(
        height: 16,
        color: color,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppMetrics.br2,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.micro10.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建 Tab 列表
  List<AppTabItem> _buildTabItems(HttpResponse? response) {
    final items = <AppTabItem>[
      const AppTabItem(icon: Icons.upload_outlined, label: 'Request'),
      const AppTabItem(icon: Icons.code, label: 'Body'),
      const AppTabItem(icon: Icons.list, label: 'Headers'),
      const AppTabItem(icon: Icons.cookie_outlined, label: 'Cookies'),
    ];

    // Timing Tab（固定标签，总耗时在内容区展示，避免标签宽度随响应时间跳动）
    if (response?.timingInfo != null) {
      items.add(
        const AppTabItem(icon: Icons.timer, label: 'Timing'),
      );
    }

    // Certificate Tab
    if (response?.certificateInfo != null) {
      items.add(
        const AppTabItem(icon: Icons.verified_user, label: 'Certificate'),
      );
    }
    return items;
  }

  /// 构建 Tab 内容列表
  List<Widget> _buildTabContents(BuildContext context, HttpResponse? response) {
    final contents = <Widget>[
      _buildRequestTab(context),
      _buildBodyTab(context, response),
      _buildHeadersTab(context, response),
      _buildCookiesTab(context),
    ];

    // Timing Tab Content
    if (response?.timingInfo != null) {
      contents.add(_buildTimingTab(context, response!.timingInfo!));
    }

    // Certificate Tab Content
    if (response?.certificateInfo != null) {
      contents.add(_buildCertificateTab(context, response!.certificateInfo!));
    }
    return contents;
  }

  Widget _buildCertificateTab(BuildContext context, CertificateInfo cert) {
    final isValid = cert.isValid;
    final validityColor = isValid ? AppColors.success : AppColors.error;

    return Container(
      color: context.appTheme.surface,
      child: SingleChildScrollView(
        controller: _certificateScrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 证书状态卡片
            _buildCertificateStatusCard(context, cert, isValid, validityColor),
            const SizedBox(height: 12),
            // 详细信息
            _buildCertificateDetailSection(context, cert),
            if (cert.chain.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCertificateChainSection(context, cert),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateStatusCard(
    BuildContext context,
    CertificateInfo cert,
    bool isValid,
    Color validityColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: validityColor.withValues(alpha: 0.05),
        borderRadius: AppMetrics.br6,
        border: Border.all(color: validityColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: validityColor.withValues(alpha: 0.1),
              borderRadius: AppMetrics.br4,
            ),
            child: Icon(
              isValid ? Icons.verified_user : Icons.warning_amber,
              size: 20,
              color: validityColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Certificate is valid' : 'Certificate expired',
                  style: AppTextStyles.caption12.copyWith(
                    fontWeight: FontWeight.w600,
                    color: validityColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isValid
                      ? '${cert.remainingDays} days remaining'
                      : 'Expired on ${cert.validTo}',
                  style: AppTextStyles.micro10.copyWith(
                    color: context.appTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateDetailSection(
      BuildContext context, CertificateInfo cert) {
    return _buildCompactInfoSection(
      context: context,
      title: 'Certificate Details',
      children: [
        _buildCompactInfoRow(context, 'Subject', cert.subject),
        _buildCompactInfoRow(context, 'Issuer', cert.issuer),
        _buildCompactInfoRow(context, 'Valid From', cert.validFrom.toString()),
        _buildCompactInfoRow(context, 'Valid To', cert.validTo.toString()),
        _buildCompactInfoRow(
            context, 'Signature Algorithm', cert.signatureAlgorithm),
        _buildCompactInfoRow(context, 'Serial Number', cert.serialNumber),
        _buildCompactInfoRow(
            context, 'SHA-256 Fingerprint', cert.sha256Fingerprint),
        if (cert.publicKeyAlgorithm != null)
          _buildCompactInfoRow(
              context, 'Public Key Algorithm', cert.publicKeyAlgorithm!),
        if (cert.publicKeyLength != null)
          _buildCompactInfoRow(
            context,
            'Public Key Length',
            '${cert.publicKeyLength} bits',
          ),
        if (cert.subjectAlternativeNames.isNotEmpty)
          _buildCompactInfoRow(
            context,
            'Subject Alternative Names',
            cert.subjectAlternativeNames.join(', '),
          ),
      ],
    );
  }

  Widget _buildCertificateChainSection(
      BuildContext context, CertificateInfo cert) {
    return _buildCompactInfoSection(
      context: context,
      title: 'Certificate Chain',
      children: cert.chain.asMap().entries.map((entry) {
        final index = entry.key;
        final chainCert = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.appTheme.surfaceVariant,
            borderRadius: AppMetrics.br4,
            border: Border.all(
              color: context.appTheme.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: chainCert.isValid
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppMetrics.br4,
                ),
                child: Icon(
                  chainCert.isValid ? Icons.check : Icons.error,
                  size: 14,
                  color:
                      chainCert.isValid ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chainCert.subject,
                      style: AppTextStyles.micro10.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.appTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Issued by: ${chainCert.issuer}',
                      style: AppTextStyles.micro10.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.appTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: context.appTheme.surfaceVariant,
                  borderRadius: AppMetrics.br4,
                ),
                child: Text(
                  '#${index + 1}',
                  style: AppTextStyles.micro10.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.appTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 紧凑型 info section，用于 Certificate 展示
  Widget _buildCompactInfoSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appTheme.surfaceVariant,
        borderRadius: AppMetrics.br6,
        border: Border.all(
          color: context.appTheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.micro10.copyWith(
              fontWeight: FontWeight.w600,
              color: context.appTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const AppDivider(),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  // 紧凑型 info row，字体更小
  Widget _buildCompactInfoRow(
      BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.micro10.copyWith(
                color: context.appTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.code11.copyWith(
                color: context.appTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
