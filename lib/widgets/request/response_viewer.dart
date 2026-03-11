import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_response.dart';
import '../../providers/providers.dart';

class ResponseViewer extends ConsumerStatefulWidget {
  const ResponseViewer({super.key});

  @override
  ConsumerState<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends ConsumerState<ResponseViewer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isErrorExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didUpdateWidget(ResponseViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error expansion when response changes
    final currentResponse = ref.read(currentResponseProvider);
    if (currentResponse?.error != null) {
      // Keep expansion state if error is the same
    } else {
      _isErrorExpanded = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final response = ref.watch(currentResponseProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Response info bar
          _buildInfoBar(context, response),
          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Body'),
              Tab(text: 'Headers'),
              Tab(text: 'Cookies'),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBodyTab(context, response),
                _buildHeadersTab(context, response),
                _buildCookiesTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(BuildContext context, HttpResponse? response) {
    if (response == null) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Row(
          children: [
            Text('No response yet', style: TextStyle(fontSize: 12)),
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
            maxHeight: _isErrorExpanded ? 150 : 40,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: Colors.red.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: _isErrorExpanded
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: _isErrorExpanded
                    ? SingleChildScrollView(
                        child: SelectableText(
                          errorText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            height: 1.4,
                          ),
                        ),
                      )
                    : Text(
                        errorText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
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
                  size: 16,
                  color: Colors.red.withOpacity(0.7),
                ),
              if (isLongError) const SizedBox(width: 4),
              // Copy error button
              IconButton(
                icon: const Icon(Icons.copy, size: 14),
                color: Colors.red.withOpacity(0.7),
                tooltip: 'Copy error',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                onPressed: () => _copyToClipboard(errorText),
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
      ),
      child: Row(
        children: [
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${response.statusCode} ${response.statusText ?? ''}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Time
          Icon(Icons.timer_outlined,
              size: 14, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            '${response.durationMs ?? 0} ms',
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(width: 16),
          // Size
          Icon(Icons.storage_outlined,
              size: 14, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            _formatSize(response.sizeBytes),
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.outline),
          ),
          const Spacer(),
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy response',
            onPressed: response.body != null
                ? () => _copyToClipboard(response.body!)
                : null,
          ),
          // Save button
          IconButton(
            icon: const Icon(Icons.save, size: 16),
            tooltip: 'Save response',
            onPressed: response.body != null ? () {} : null,
          ),
        ],
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

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        response!.body!,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHeadersTab(BuildContext context, HttpResponse? response) {
    if (response?.headers.isEmpty ?? true) {
      return Center(
        child: Text(
          'No headers',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        itemCount: response!.headers.length,
        itemBuilder: (context, index) {
          final header = response.headers[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    header.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    header.value,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCookiesTab(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cookie_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Cookies',
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
