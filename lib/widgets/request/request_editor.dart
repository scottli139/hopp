import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_method.dart';
import '../../models/http_request.dart';
import '../../models/key_value_pair.dart';
import '../../providers/providers.dart';
import '../../utils/app_logger.dart';
import '../../utils/constants.dart';
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
  String? _lastTabId;

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

    // Only update controllers when tab changes, not on every build
    if (_lastTabId != activeTab.id) {
      _lastTabId = activeTab.id;
      _urlController.text = activeTab.request.url;
      _nameController.text = activeTab.request.name;
    }

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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Method dropdown with improved styling
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.spaceS),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<HttpMethod>(
                value: request.method,
                isDense: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.outline,
                  size: 20,
                ),
                items: HttpMethod.values.map((method) {
                  final color = _getMethodColor(method.value);
                  return DropdownMenuItem(
                    value: method,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spaceXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusS),
                      ),
                      child: Text(
                        method.value,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
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
          const SizedBox(width: AppConstants.spaceM),
          // URL input with improved styling
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'Enter URL',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceM,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                onChanged: (value) {
                  _updateRequest(ref, request.copyWith(url: value));
                },
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spaceM),
          // Save button with hover effect
          _buildIconButton(
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
          const SizedBox(width: AppConstants.spaceS),
          // Send button with improved styling
          _buildSendButton(context, ref, request),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? (activeColor ?? theme.colorScheme.primary).withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(
                color: isActive
                    ? (activeColor ?? theme.colorScheme.primary)
                        .withOpacity(0.3)
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
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
            horizontal: AppConstants.spaceM,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.send,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Send',
                style: AppTextStyles.caption.copyWith(
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

  Widget _buildTabs(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
        labelStyle: AppTextStyles.tiny.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.tiny.copyWith(
          fontWeight: FontWeight.w500,
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        tabs: const [
          Tab(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, size: 14),
                SizedBox(width: 4),
                Text('Params'),
              ],
            ),
          ),
          Tab(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.http, size: 14),
                SizedBox(width: 4),
                Text('Headers'),
              ],
            ),
          ),
          Tab(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code, size: 14),
                SizedBox(width: 4),
                Text('Body'),
              ],
            ),
          ),
          Tab(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 14),
                SizedBox(width: 4),
                Text('Auth'),
              ],
            ),
          ),
        ],
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
    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.5),
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 40,
                  child: Text('',
                      style: AppTextStyles.tiny.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant))),
              const SizedBox(width: 16),
              Expanded(
                  flex: 2,
                  child: Text('Key',
                      style: AppTextStyles.tiny.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant))),
              const SizedBox(width: 16),
              Expanded(
                  flex: 3,
                  child: Text('Value',
                      style: AppTextStyles.tiny.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant))),
              const SizedBox(width: 40),
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
    final theme = Theme.of(context);

    return Column(
      children: [
        // Body type selector with improved styling
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceL,
            vertical: AppConstants.spaceM,
          ),
          decoration: BoxDecoration(
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
              const SizedBox(width: AppConstants.spaceL),
              Expanded(
                child: SegmentedButton<String>(
                  segments: [
                    _buildSegment('none', 'None', Icons.block),
                    _buildSegment('json', 'JSON', Icons.data_object),
                    _buildSegment('text', 'Text', Icons.text_fields),
                    _buildSegment('form', 'Form', Icons.format_list_bulleted),
                  ],
                  selected: {request.bodyType},
                  onSelectionChanged: (value) {
                    if (value.isNotEmpty) {
                      _updateRequest(
                          ref, request.copyWith(bodyType: value.first));
                    }
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                ),
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

  ButtonSegment<String> _buildSegment(
      String value, String label, IconData icon) {
    return ButtonSegment(
      value: value,
      label: Text(
        label,
        style: AppTextStyles.tiny,
      ),
      icon: Icon(icon, size: 14),
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
