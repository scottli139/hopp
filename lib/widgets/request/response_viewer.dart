import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/certificate_info.dart';
import '../../models/http_method.dart';
import '../../models/http_request.dart';
import '../../models/http_request_info.dart';
import '../../models/http_response.dart';
import '../../models/key_value_pair.dart';
import '../../models/timing_info.dart';
import '../../providers/request/request_tab_provider.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/testing/ui_test_mode.dart';

import '../common/optimized_response_viewer.dart';

// 全局 ScrollController 用于 UI 测试控制滚动
final _certificateScrollController = ScrollController();

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
      // 使用 timestamp 确保每次都能触发
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _certificateScrollController.hasClients) {
          final currentOffset = _certificateScrollController.offset;
          double newOffset;

          switch (direction) {
            case 'down':
              newOffset = currentOffset + amount;
              break;
            case 'up':
              newOffset = currentOffset - amount;
              break;
            default:
              return;
          }

          _certificateScrollController.animateTo(
            newOffset.clamp(
                0.0, _certificateScrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final response = ref.watch(currentResponseProvider);
    final theme = Theme.of(context);

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
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Response info bar
          _buildInfoBar(context, response),
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 2,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: _buildTabs(context, response),
            ),
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
    const infoFontSize = 11.0;
    final theme = Theme.of(context);

    if (response == null) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 12,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 6),
            Text(
              'No response yet',
              style: TextStyle(
                fontSize: infoFontSize,
                color: theme.colorScheme.outline,
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
            maxHeight: _isErrorExpanded ? 150 : 44,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            border: Border(
              bottom: BorderSide(
                color: AppColors.error.withOpacity(0.2),
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
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
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
                          style: TextStyle(
                            fontSize: infoFontSize,
                            color: AppColors.error,
                            height: 1.4,
                          ),
                        ),
                      )
                    : Text(
                        errorText,
                        style: TextStyle(
                          fontSize: infoFontSize,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
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
                  color: AppColors.error.withOpacity(0.7),
                ),
              if (isLongError) const SizedBox(width: 8),
              // Copy error button
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  onTap: () => _copyToClipboard(errorText),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.copy,
                      size: 14,
                      color: AppColors.error.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(response.statusCode);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status - 缩小字号
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
            ),
            child: Text(
              '${response.statusCode} ${response.statusText ?? ''}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Time
          Icon(
            Icons.timer_outlined,
            size: 12,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            '${response.durationMs ?? 0} ms',
            style: TextStyle(
              fontSize: infoFontSize,
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          // Size
          Icon(
            Icons.storage_outlined,
            size: 12,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            _formatSize(response.sizeBytes),
            style: TextStyle(
              fontSize: infoFontSize,
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w500,
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
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: onPressed != null
                    ? theme.colorScheme.outline.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: onPressed != null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyTab(BuildContext context, HttpResponse? response) {
    if (response?.body == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Send a request to see the response',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
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
    );
  }

  Widget _buildHeadersTab(BuildContext context, HttpResponse? response) {
    if (response?.headers.isEmpty ?? true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No headers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header row - 使用更明显的样式区分
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    'Header Name',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Value',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
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
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          header.value,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface,
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
    return _buildEmptyState(
      context: context,
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

  /// 获取 HTTP 方法颜色
  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return AppColors.httpGet;
      case HttpMethod.post:
        return AppColors.httpPost;
      case HttpMethod.put:
        return AppColors.httpPut;
      case HttpMethod.delete:
        return AppColors.httpDelete;
      case HttpMethod.patch:
        return AppColors.httpPatch;
      case HttpMethod.head:
      case HttpMethod.options:
        return Colors.grey;
    }
  }

  /// 根据字符串获取 HTTP 方法颜色
  Color _getMethodColorFromString(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return AppColors.httpGet;
      case 'POST':
        return AppColors.httpPost;
      case 'PUT':
        return AppColors.httpPut;
      case 'DELETE':
        return AppColors.httpDelete;
      case 'PATCH':
        return AppColors.httpPatch;
      case 'HEAD':
      case 'OPTIONS':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRequestTab(BuildContext context) {
    final theme = Theme.of(context);
    final response = ref.watch(currentResponseProvider);

    // 优先使用 response 中的 requestInfo（实际发送的请求信息）
    if (response?.requestInfo != null) {
      return _buildRequestInfoTab(context, response!.requestInfo!);
    }

    // 如果没有 requestInfo，回退到使用当前编辑的请求信息
    final activeTab = ref.watch(activeTabProvider);

    if (activeTab == null) {
      return _buildEmptyState(
        context: context,
        icon: Icons.upload_outlined,
        title: 'No Request',
        subtitle: 'Create a request to see details',
      );
    }

    final request = activeTab.request;
    final fullUrl = _buildFullUrl(request);
    final methodColor = _getMethodColor(request.method);
    final enabledHeaders =
        request.headers.where((h) => h.enabled && h.key.isNotEmpty).toList();
    final hasBody = request.body.isNotEmpty && request.bodyType != 'none';

    return Container(
      color: theme.colorScheme.surface,
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
    final theme = Theme.of(context);
    final methodColor = _getMethodColorFromString(requestInfo.method);

    return Container(
      color: theme.colorScheme.surface,
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
              _buildRequestInfoHeadersSection(context, requestInfo.headers),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            methodColor.withOpacity(0.1),
            methodColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: methodColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HTTP 方法标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: methodColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Text(
              request.method.value.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: methodColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 完整 URL
          SelectableText(
            fullUrl,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);

    return _buildCompactInfoSection(
      context: context,
      title: 'Body (${request.bodyType})',
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: SelectableText(
            request.body,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
            ),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            methodColor.withOpacity(0.1),
            methodColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: methodColor.withOpacity(0.2)),
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
                  color: methodColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  requestInfo.method.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: methodColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(requestInfo.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 完整 URL
          SelectableText(
            requestInfo.fullUrl,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurfaceVariant,
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
  ) {
    final theme = Theme.of(context);

    // 将 headers 分为用户添加的和自动添加的
    final userHeaders = <KeyValuePair>[];
    final autoHeaders = <KeyValuePair>[];

    for (final header in headers) {
      if (_isAutoHeader(header.key)) {
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
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (userHeaders.isNotEmpty)
              Text(
                '${userHeaders.length} custom',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Headers 列表
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.5),
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
                const Divider(height: 16),
                Text(
                  'Auto-added Headers',
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.outline,
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

  /// 判断是否为自动添加的 header
  bool _isAutoHeader(String key) {
    final autoHeaders = {
      'user-agent',
      'accept-encoding',
      'connection',
      'host',
    };
    return autoHeaders.contains(key.toLowerCase());
  }

  /// 构建单个 header 行
  Widget _buildRequestInfoHeaderRow(
    BuildContext context,
    KeyValuePair header, {
    required bool isAuto,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Text(
                  header.key,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isAuto
                        ? theme.colorScheme.outline
                        : theme.colorScheme.primary,
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
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'auto',
                      style: TextStyle(
                        fontSize: 8,
                        color: theme.colorScheme.outline,
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
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Body',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  requestInfo.bodyType!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (requestInfo.bodySize != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatSize(requestInfo.bodySize),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.outline,
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
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          child: SelectableText(
            requestInfo.body ?? '',
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingTab(BuildContext context, TimingInfo timing) {
    final theme = Theme.of(context);
    final percentages = timing.getPhasePercentages();

    return Container(
      color: theme.colorScheme.surface,
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: const Icon(
              Icons.timer,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Request Time',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timing.totalFormatted,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
            color: AppColors.secondary,
          ),
        if (timing.downloadMs != null && timing.downloadMs! > 0)
          _buildTimingRow(
            context: context,
            label: 'Download',
            value: timing.downloadFormatted,
            percentage: percentages['download'] ?? 0,
            color: AppColors.httpGet,
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
    final theme = Theme.of(context);

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
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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
              style: TextStyle(
                fontSize: 8,
                color: theme.colorScheme.outline.withOpacity(0.7),
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
          borderRadius: BorderRadius.circular(4),
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
                  color: AppColors.secondary,
                  flex: (percentages['ttfb'] ?? 0).round(),
                ),
              if (timing.downloadMs != null && timing.downloadMs! > 0)
                _buildTimelineSegment(
                  color: AppColors.httpGet,
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
              _buildLegendItem('TTFB', AppColors.secondary),
            if (timing.downloadMs != null && timing.downloadMs! > 0)
              _buildLegendItem('Download', AppColors.httpGet),
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
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建 Tab 列表
  List<Widget> _buildTabs(BuildContext context, HttpResponse? response) {
    const tabFontSize = 10.0;
    const tabHeight = 28.0;
    final theme = Theme.of(context);

    final tabs = <Widget>[
      // Request Tab - always first
      Tab(
        height: tabHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_outlined,
              size: 10,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 3),
            const Text(
              'Request',
              style: TextStyle(fontSize: tabFontSize),
            ),
          ],
        ),
      ),
      Tab(
        height: tabHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.code,
              size: 10,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 3),
            const Text(
              'Body',
              style: TextStyle(fontSize: tabFontSize),
            ),
          ],
        ),
      ),
      Tab(
        height: tabHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list,
              size: 10,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 3),
            const Text(
              'Headers',
              style: TextStyle(fontSize: tabFontSize),
            ),
          ],
        ),
      ),
      Tab(
        height: tabHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cookie_outlined,
              size: 10,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 3),
            const Text(
              'Cookies',
              style: TextStyle(fontSize: tabFontSize),
            ),
          ],
        ),
      ),
    ];

    // Timing Tab
    if (response?.timingInfo != null) {
      final timing = response!.timingInfo!;
      tabs.add(
        Tab(
          height: tabHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 10,
                color: AppColors.info,
              ),
              const SizedBox(width: 3),
              Text(
                'Time: ${timing.totalMs}ms',
                style: const TextStyle(fontSize: tabFontSize),
              ),
            ],
          ),
        ),
      );
    }

    // Certificate Tab
    if (response?.certificateInfo != null) {
      tabs.add(
        Tab(
          height: tabHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user,
                size: 10,
                color: response!.certificateInfo!.isValid
                    ? AppColors.success
                    : AppColors.warning,
              ),
              const SizedBox(width: 3),
              const Text(
                'Certificate',
                style: TextStyle(fontSize: tabFontSize),
              ),
            ],
          ),
        ),
      );
    }
    return tabs;
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
    final theme = Theme.of(context);
    final isValid = cert.isValid;
    final validityColor = isValid ? AppColors.success : AppColors.error;

    return Container(
      color: theme.colorScheme.surface,
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
        color: validityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: validityColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: validityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: validityColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isValid
                      ? '${cert.remainingDays} days remaining'
                      : 'Expired on ${cert.validTo}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.outline,
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: chainCert.isValid
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
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
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Issued by: ${chainCert.issuer}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.outline,
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
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
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
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.title.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) return Colors.grey;
    if (statusCode >= 200 && statusCode < 300) return Colors.green;
    if (statusCode >= 300 && statusCode < 400) return Colors.orange;
    if (statusCode >= 400 && statusCode < 500) return Colors.red;
    if (statusCode >= 500) return Colors.red.shade700;
    return Colors.grey;
  }
}
