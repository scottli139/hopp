import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/certificate_info.dart';
import '../../models/http_response.dart';
import '../../models/key_value_pair.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../common/code_editor.dart';

class ResponseViewer extends ConsumerStatefulWidget {
  const ResponseViewer({super.key});

  @override
  ConsumerState<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends ConsumerState<ResponseViewer>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isErrorExpanded = false;
  String? _lastResponseId;

  @override
  void initState() {
    super.initState();
    // Initialize with default length, will be updated on first build
    _tabController = TabController(length: 3, vsync: this);
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
    return response?.certificateInfo != null ? 4 : 3;
  }

  /// 更新 TabController 以匹配当前响应
  void _updateTabController(HttpResponse? response) {
    final newLength = _getTabLength(response);
    if (_tabController == null || _tabController!.length != newLength) {
      _tabController?.dispose();
      _tabController = TabController(length: newLength, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final response = ref.watch(currentResponseProvider);
    final theme = Theme.of(context);

    // Ensure TabController is synchronized with current response
    _updateTabController(response);

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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: _buildTabs(response),
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
            ),
            child: Text(
              '${response.statusCode} ${response.statusText ?? ''}',
              style: TextStyle(
                fontSize: infoFontSize,
                fontWeight: FontWeight.w700,
                color: statusColor,
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

    // Detect content type and use appropriate language
    final language = _detectLanguage(response!);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(12),
      child: CodeEditor(
        code: response.body!,
        language: language,
        readOnly: true,
        expands: true,
      ),
    );
  }

  CodeLanguage _detectLanguage(HttpResponse response) {
    final contentType = response.headers
        .firstWhere(
          (h) => h.key.toLowerCase() == 'content-type',
          orElse: () => KeyValuePair.empty(),
        )
        .value
        .toLowerCase();

    if (contentType.contains('json')) return CodeLanguage.json;
    if (contentType.contains('xml')) return CodeLanguage.xml;
    if (contentType.contains('html')) return CodeLanguage.html;

    // Try to detect JSON by content
    final body = response.body?.trim() ?? '';
    if ((body.startsWith('{') && body.endsWith('}')) ||
        (body.startsWith('[') && body.endsWith(']'))) {
      return CodeLanguage.json;
    }

    return CodeLanguage.text;
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
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    'Name',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Value',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          header.value,
                          style: AppTextStyles.bodySmall.copyWith(
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

  /// 构建 Tab 列表
  List<Widget> _buildTabs(HttpResponse? response) {
    const tabFontSize = 13.0;
    const tabHeight = 36.0;

    final tabs = <Widget>[
      const Tab(
        height: tabHeight,
        child: Text(
          'Body',
          style: TextStyle(fontSize: tabFontSize),
        ),
      ),
      const Tab(
        height: tabHeight,
        child: Text(
          'Headers',
          style: TextStyle(fontSize: tabFontSize),
        ),
      ),
      const Tab(
        height: tabHeight,
        child: Text(
          'Cookies',
          style: TextStyle(fontSize: tabFontSize),
        ),
      ),
    ];
    if (response?.certificateInfo != null) {
      tabs.add(
        Tab(
          height: tabHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Certificate',
                style: TextStyle(fontSize: tabFontSize),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.verified,
                size: 14,
                color: response!.certificateInfo!.isValid
                    ? AppColors.success
                    : AppColors.warning,
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
      _buildBodyTab(context, response),
      _buildHeadersTab(context, response),
      _buildCookiesTab(context),
    ];
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 证书状态卡片
            _buildCertificateStatusCard(context, cert, isValid, validityColor),
            const SizedBox(height: 16),
            // 详细信息
            _buildCertificateDetailSection(context, cert),
            if (cert.chain.isNotEmpty) ...[
              const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: validityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: validityColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: validityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Icon(
              isValid ? Icons.verified_user : Icons.warning_amber,
              size: 24,
              color: validityColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Certificate is valid' : 'Certificate expired',
                  style: AppTextStyles.body.copyWith(
                    color: validityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isValid
                      ? '${cert.remainingDays} days remaining'
                      : 'Expired on ${cert.validTo}',
                  style: AppTextStyles.caption.copyWith(
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
    return _buildInfoSection(
      context: context,
      title: 'Certificate Details',
      children: [
        _buildInfoRow(context, 'Subject', cert.subject),
        _buildInfoRow(context, 'Issuer', cert.issuer),
        _buildInfoRow(context, 'Valid From', cert.validFrom.toString()),
        _buildInfoRow(context, 'Valid To', cert.validTo.toString()),
        _buildInfoRow(context, 'Signature Algorithm', cert.signatureAlgorithm),
        _buildInfoRow(context, 'Serial Number', cert.serialNumber),
        _buildInfoRow(context, 'SHA-256 Fingerprint', cert.sha256Fingerprint),
        if (cert.publicKeyAlgorithm != null)
          _buildInfoRow(
              context, 'Public Key Algorithm', cert.publicKeyAlgorithm!),
        if (cert.publicKeyLength != null)
          _buildInfoRow(
            context,
            'Public Key Length',
            '${cert.publicKeyLength} bits',
          ),
        if (cert.subjectAlternativeNames.isNotEmpty)
          _buildInfoRow(
            context,
            'Subject Alternative Names',
            cert.subjectAlternativeNames.join(', '),
          ),
      ],
    );
  }

  Widget _buildCertificateChainSection(
      BuildContext context, CertificateInfo cert) {
    return _buildInfoSection(
      context: context,
      title: 'Certificate Chain',
      children: cert.chain.asMap().entries.map((entry) {
        final index = entry.key;
        final chainCert = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: chainCert.isValid
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Icon(
                  chainCert.isValid ? Icons.check : Icons.error,
                  size: 16,
                  color:
                      chainCert.isValid ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chainCert.subject,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Issued by: ${chainCert.issuer}',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  '#${index + 1}',
                  style: AppTextStyles.tiny.copyWith(
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

  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.tiny.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.caption.copyWith(
                fontFamily: 'monospace',
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
