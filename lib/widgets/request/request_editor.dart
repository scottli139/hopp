import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_method.dart';
import '../../models/http_request.dart';
import '../../models/key_value_pair.dart';
import '../../providers/providers.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeTabProvider);

    if (activeTab == null) {
      return const Center(child: Text('Select a request'));
    }

    // Update controllers when tab changes
    _urlController.text = activeTab.request.url;
    _nameController.text = activeTab.request.name;

    return Column(
      children: [
        // URL bar
        _buildUrlBar(context, ref, activeTab.request),
        // Tabs
        _buildTabs(context),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Method dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<HttpMethod>(
                value: request.method,
                isDense: true,
                items: HttpMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(
                      method.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getMethodColor(method.value),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateRequest(ref, request.copyWith(method: value));
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // URL input
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'Enter URL',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                _updateRequest(ref, request.copyWith(url: value));
              },
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          FilledButton.icon(
            onPressed: () => _sendRequest(ref, request),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: const [
        Tab(text: 'Params'),
        Tab(text: 'Headers'),
        Tab(text: 'Body'),
        Tab(text: 'Auth'),
      ],
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
    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(
                  width: 40,
                  child: Text('Enable',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600))),
              SizedBox(width: 16),
              Expanded(
                  flex: 2,
                  child: Text('Key',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600))),
              SizedBox(width: 16),
              Expanded(
                  flex: 3,
                  child: Text('Value',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600))),
              SizedBox(width: 40),
            ],
          ),
        ),
        // Items list
        Expanded(
          child: ListView.builder(
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
                return ListTile(
                  leading: const SizedBox(width: 40),
                  title: const Text('Add new',
                      style: TextStyle(color: Colors.grey)),
                  onTap: () {
                    final newItems = [...items, _createEmptyKeyValue()];
                    _updateRequest(ref, updateFn(newItems));
                  },
                );
              }
              return _buildKeyValueRow(
                  context, ref, request, items, index, updateFn);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeyValueRow(
    BuildContext context,
    WidgetRef ref,
    HttpRequest request,
    List<KeyValuePair> items,
    int index,
    HttpRequest Function(List<KeyValuePair>) updateFn,
  ) {
    final item = items[index];
    final keyController = TextEditingController(text: item.key);
    final valueController = TextEditingController(text: item.value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: item.enabled,
              onChanged: (value) {
                final newItems = [...items];
                newItems[index] = item.copyWith(enabled: value ?? true);
                _updateRequest(ref, updateFn(newItems));
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TextField(
              controller: keyController,
              decoration: const InputDecoration(
                hintText: 'Key',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                final newItems = [...items];
                newItems[index] = item.copyWith(key: value);
                _updateRequest(ref, updateFn(newItems));
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: TextField(
              controller: valueController,
              decoration: const InputDecoration(
                hintText: 'Value',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                final newItems = [...items];
                newItems[index] = item.copyWith(value: value);
                _updateRequest(ref, updateFn(newItems));
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () {
                final newItems = [...items]..removeAt(index);
                _updateRequest(ref, updateFn(newItems));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTab(
      BuildContext context, WidgetRef ref, HttpRequest request) {
    return Column(
      children: [
        // Body type selector
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'none', label: Text('None')),
              ButtonSegment(value: 'json', label: Text('JSON')),
              ButtonSegment(value: 'text', label: Text('Text')),
              ButtonSegment(value: 'form', label: Text('Form')),
            ],
            selected: {request.bodyType},
            onSelectionChanged: (value) {
              if (value.isNotEmpty) {
                _updateRequest(ref, request.copyWith(bodyType: value.first));
              }
            },
          ),
        ),
        // Body editor
        if (request.bodyType != 'none')
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: TextEditingController(text: request.body),
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Request body',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                onChanged: (value) {
                  _updateRequest(ref, request.copyWith(body: value));
                },
              ),
            ),
          ),
      ],
    );
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
