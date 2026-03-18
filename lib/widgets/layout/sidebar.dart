import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../providers/providers.dart';
import '../../screens/about/about_screen.dart';
import '../../utils/app_logger.dart';
import '../../utils/constants.dart';
import '../../utils/testing/ui_test_mode.dart';
import '../../widgets/import/curl_import_dialog.dart';
import '../../widgets/import_export/export_dialog.dart';
import '../../widgets/import_export/import_dialog.dart';

class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  // 编辑状态变量
  bool _isEditingName = false;
  String? _editingRequestId;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionProvider);
    final theme = Theme.of(context);

    // Listen to UI test dialog triggers
    ref.listen<int?>(uiTestImportDialogProvider, (previous, current) {
      if (current != null && current != previous) {
        _showImportDialog(context);
      }
    });

    ref.listen<int?>(uiTestExportDialogProvider, (previous, current) {
      if (current != null && current != previous) {
        _showExportDialog(context);
      }
    });

    // Listen to delete collection dialog trigger
    ref.listen<int?>(uiTestDeleteCollectionDialogProvider, (previous, current) {
      if (current != null && current != previous) {
        _triggerDeleteCollection(context);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),
          const Divider(height: 1),
          // Search
          _buildSearch(context),
          // Collection tree
          Expanded(
            child: collections.when(
              data: (data) => _buildCollectionTree(context, data),
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: AppConstants.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceS),
      child: Row(
        children: [
          // Brand Logo
          _buildBrandLogo(context),
          const Spacer(),
          // Actions menu
          _buildActionsMenu(context),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spaceM),
      child: TextField(
        decoration: AppComponentStyles.outlineInputDecoration(
          hintText: 'Filter...',
        ),
        style: AppTextStyles.bodySmall,
      ),
    );
  }

  Widget _buildCollectionTree(
    BuildContext context,
    List<Collection> collections,
  ) {
    if (collections.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: collections.length,
      itemBuilder: (context, index) {
        return _buildCollectionItem(context, collections[index], 0);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.spaceM),
          Text(
            'No collections yet',
            style: AppTextStyles.body.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionItem(
    BuildContext context,
    Collection collection,
    int depth,
  ) {
    final isExpanded = collection.isExpanded;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref
                  .read(collectionProvider.notifier)
                  .toggleExpanded(collection.id);
            },
            hoverColor:
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: Container(
              height: AppConstants.sidebarItemHeight,
              padding: EdgeInsets.only(
                left: AppConstants.spaceS + depth * AppConstants.spaceM,
                right: AppConstants.spaceS,
              ),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: AppConstants.animFast,
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: collection.children.isEmpty &&
                              collection.requests.isEmpty
                          ? Colors.transparent
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceXS),
                  Icon(
                    isExpanded ? Icons.folder_open : Icons.folder,
                    size: 16,
                    color: isExpanded
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: AppConstants.spaceXS),
                  Expanded(
                    child: Text(
                      collection.name,
                      style: AppTextStyles.caption.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight:
                            isExpanded ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildCollectionActions(context, collection),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              ...collection.children.map(
                (child) => _buildCollectionItem(context, child, depth + 1),
              ),
              ...collection.requests.map(
                (request) => _buildRequestItem(context, request, depth + 1),
              ),
            ],
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AppConstants.animFast,
        ),
      ],
    );
  }

  Widget _buildRequestItem(
    BuildContext context,
    HttpRequest request,
    int depth,
  ) {
    final isActive = ref.watch(activeTabIdProvider) == request.id;

    // 使用 StatefulBuilder 管理编辑状态
    return StatefulBuilder(
      builder: (context, setState) {
        // 检查是否正在编辑此请求
        final editingRequestId = ref.watch(uiTestEditingRequestIdProvider);
        final isEditing = editingRequestId == request.id;

        // 如果是测试模式触发的编辑，自动进入编辑状态
        if (isEditing && !_isEditingName) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isEditingName = true;
              _editingRequestId = request.id;
              _nameController.text = request.name;
            });
          });
        }

        return Material(
          color: isActive
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
          child: InkWell(
            onTap: _isEditingName && _editingRequestId == request.id
                ? null
                : () {
                    ref.read(requestTabProvider.notifier).openTab(request);
                    ref.read(activeTabIdProvider.notifier).state = request.id;
                  },
            onSecondaryTap: () => _showRequestContextMenu(context, request),
            hoverColor: AppColors.primary.withOpacity(0.04),
            splashColor: AppColors.primary.withOpacity(0.08),
            child: Container(
              height: 28,
              padding: EdgeInsets.only(
                left: AppConstants.spaceS + depth * AppConstants.spaceM + 12,
                right: AppConstants.spaceS,
              ),
              decoration: isActive
                  ? BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  // Method badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getHttpMethodColor(request.method.value)
                          .withOpacity(isActive ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      request.method.value.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        color:
                            AppColors.getHttpMethodColor(request.method.value),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 名称显示或编辑
                  Expanded(
                    child: _isEditingName && _editingRequestId == request.id
                        ? _buildNameEditor(context, request, setState)
                        : _buildNameDisplay(context, request, isActive),
                  ),
                  // 编辑时显示操作按钮，或选中/悬停时显示菜单按钮
                  if (_isEditingName && _editingRequestId == request.id) ...[
                    _buildEditActions(context, request, setState),
                  ] else if (isActive)
                    _buildRequestMenuButton(context, request)
                  else
                    const SizedBox(width: 28), // 保持间距一致
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建名称显示
  Widget _buildNameDisplay(
      BuildContext context, HttpRequest request, bool isActive) {
    final theme = Theme.of(context);
    return Text(
      request.name,
      style: TextStyle(
        fontSize: 11,
        color: isActive ? AppColors.primaryDark : theme.colorScheme.onSurface,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建名称编辑器
  Widget _buildNameEditor(
    BuildContext context,
    HttpRequest request,
    StateSetter setState,
  ) {
    final theme = Theme.of(context);

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _saveRequestName(context, request, setState);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            _cancelEdit(setState);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _nameController,
        autofocus: true,
        style: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        onSubmitted: (_) => _saveRequestName(context, request, setState),
      ),
    );
  }

  /// 构建编辑操作按钮
  Widget _buildEditActions(
    BuildContext context,
    HttpRequest request,
    StateSetter setState,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _saveRequestName(context, request, setState),
          child: Icon(
            Icons.check,
            size: 14,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () => _cancelEdit(setState),
          child: Icon(
            Icons.close,
            size: 14,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  /// 构建请求菜单按钮
  Widget _buildRequestMenuButton(
    BuildContext context,
    HttpRequest request,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        onTap: () {},
        child: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 14,
            color: theme.colorScheme.outline,
          ),
          offset: const Offset(0, 24),
          constraints: const BoxConstraints(minWidth: 140),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          elevation: 4,
          color: theme.colorScheme.surface,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'rename',
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rename',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _startEditingName(request.id, request.name, setState);
                break;
              case 'delete':
                _showDeleteRequestConfirmation(context, request);
                break;
            }
          },
        ),
      ),
    );
  }

  /// 开始编辑名称
  void _startEditingName(
      String requestId, String currentName, StateSetter setState) {
    setState(() {
      _isEditingName = true;
      _editingRequestId = requestId;
      _nameController.text = currentName;
    });
  }

  /// 保存请求名称
  Future<void> _saveRequestName(
    BuildContext context,
    HttpRequest request,
    StateSetter setState,
  ) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == request.name) {
      _cancelEdit(setState);
      return;
    }

    // 更新请求
    final updatedRequest = request.copyWith(name: newName);

    // 更新 Collection
    await ref
        .read(collectionProvider.notifier)
        .updateRequestInCollection(updatedRequest);

    // 更新 Tab（如果打开）
    final tab = ref.read(requestTabProvider.notifier).getTab(request.id);
    if (tab != null) {
      ref
          .read(requestTabProvider.notifier)
          .updateRequest(request.id, updatedRequest);
    }

    // 通知 UI 测试模式编辑完成
    if (ref.read(uiTestEditCompleteProvider) != null) {
      ref.read(uiTestEditCompleteProvider.notifier).state = {
        'request_id': request.id,
        'old_name': request.name,
        'new_name': newName,
        'confirmed': true,
      };
    }

    _cancelEdit(setState);
  }

  /// 取消编辑
  void _cancelEdit(StateSetter setState) {
    setState(() {
      _isEditingName = false;
      _editingRequestId = null;
      _nameController.clear();
    });
  }

  /// 显示请求右键菜单
  void _showRequestContextMenu(
    BuildContext context,
    HttpRequest request,
  ) {
    final theme = Theme.of(context);

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(
                Icons.edit,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              const Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              const Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'rename') {
        // 触发编辑状态
      } else if (value == 'delete') {
        _showDeleteRequestConfirmation(context, request);
      }
    });
  }

  /// 显示删除确认对话框
  void _showDeleteRequestConfirmation(
    BuildContext context,
    HttpRequest request,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text(
          'Are you sure you want to delete "${request.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              // 删除请求
              _deleteRequest(request);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// 删除请求
  void _deleteRequest(HttpRequest request) {
    // 关闭相关 Tab
    final tab = ref.read(requestTabProvider.notifier).getTab(request.id);
    if (tab != null) {
      ref.read(requestTabProvider.notifier).closeTab(request.id);
    }

    // 从 Collection 中删除
    final collectionId = ref
        .read(collectionProvider.notifier)
        .findRequestCollectionId(request.id);
    if (collectionId != null) {
      ref.read(collectionProvider.notifier).deleteRequestFromCollection(
            collectionId,
            request.id,
          );
    }
  }

  Widget _buildCollectionActions(
    BuildContext context,
    Collection collection,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        onTap: () {}, // PopupMenuButton will handle the tap
        child: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 16,
            color: theme.colorScheme.outline,
          ),
          offset: const Offset(0, 28),
          constraints: const BoxConstraints(minWidth: 160),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          elevation: 4,
          color: theme.colorScheme.surface,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'add_request',
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Request',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'add_folder',
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.create_new_folder_outlined,
                    size: 14,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Folder',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem(
              value: 'export',
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.upload,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Export',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'rename',
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rename',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'add_request':
                AppLogger.info(
                    '[Sidebar] Adding new request to collection: ${collection.name}');
                final newRequest = HttpRequest.empty().copyWith(
                  parentId: collection.id,
                );
                ref.read(collectionProvider.notifier).addRequestToCollection(
                      collection.id,
                      newRequest,
                    );
                // Set active tab ID first, then open tab to ensure proper state sync
                ref.read(activeTabIdProvider.notifier).state = newRequest.id;
                ref.read(requestTabProvider.notifier).openTab(newRequest);
                AppLogger.info(
                    '[Sidebar] New request created and tab opened: ${newRequest.name}');
                break;
              case 'export':
                AppLogger.info(
                    '[Sidebar] Exporting collection: ${collection.name}');
                showExportDialog(context, collectionId: collection.id);
                break;
              case 'delete':
                _showDeleteConfirmation(context, collection);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showNewCollectionDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: controller,
          decoration: AppComponentStyles.outlineInputDecoration(
            hintText: 'Enter collection name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(collectionProvider.notifier).addCollection(
                      Collection.empty().copyWith(name: controller.text),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Collection collection,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Delete Collection',
              style: AppTextStyles.title.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${collection.name}"? This action cannot be undone.',
          style: AppTextStyles.body.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppComponentStyles.ghostButton(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceL,
                vertical: 10,
              ),
              minimumSize: const Size(0, AppConstants.buttonHeightM),
            ),
            onPressed: () {
              ref.read(collectionProvider.notifier).deleteCollection(
                    collection.id,
                  );
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Build brand logo widget
  Widget _buildBrandLogo(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: 24,
      height: 24,
    );
  }

  /// Build actions menu button
  Widget _buildActionsMenu(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: theme.colorScheme.outline),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      elevation: 4,
      color: theme.colorScheme.surface,
      onSelected: (value) {
        switch (value) {
          case 'about':
            _showAboutDialog(context);
            break;
          case 'new':
            _showNewCollectionDialog(context);
            break;
          case 'refresh':
            ref.read(collectionProvider.notifier).loadCollections();
            break;
          case 'import':
            _showImportDialog(context);
            break;
          case 'import_curl':
            _showCurlImportDialog(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'new',
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.add, size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'New Collection',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'import',
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.download,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Import Postman',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'import_curl',
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.terminal,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Import from cURL',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'refresh',
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.refresh,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Refresh',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'about',
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'About',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show import dialog
  void _showImportDialog(BuildContext context) {
    showImportDialog(context);
  }

  /// Show cURL import dialog
  void _showCurlImportDialog(BuildContext context) {
    showCurlImportDialog(context);
  }

  /// Show export dialog
  void _showExportDialog(BuildContext context) {
    showExportDialog(context);
  }

  /// Trigger delete collection dialog for UI testing
  void _triggerDeleteCollection(BuildContext context) {
    final collectionsAsync = ref.read(collectionProvider);
    collectionsAsync.whenData((collections) {
      if (collections.isNotEmpty) {
        _showDeleteConfirmation(context, collections.first);
      }
    });
  }

  /// Show about dialog
  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(24),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      const Color(0xFF8B5CF6),
                      const Color(0xFFEC4899),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.svg.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // App name
              Text(
                'Hopp',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        colorScheme.primary,
                        const Color(0xFFEC4899),
                      ],
                    ).createShader(
                      const Rect.fromLTWH(0, 0, 100, 30),
                    ),
                ),
              ),
              const SizedBox(height: 4),
              // Tagline
              Text(
                'Hop to your APIs',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Version
              _buildInfoRow(context, 'Version', '0.6.0'),
              const SizedBox(height: 8),
              _buildInfoRow(context, 'Platform', 'macOS'),
              const SizedBox(height: 8),
              _buildInfoRow(context, 'Flutter', '3.27.x'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Powered by AI · Built with Flutter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '© 2026 Hopp. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
            child: const Text('More Info'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
