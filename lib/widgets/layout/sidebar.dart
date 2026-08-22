import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../providers/providers.dart';
import '../../screens/about/about_screen.dart';
import '../../screens/design_gallery/design_gallery_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../../utils/app_logger.dart';
import '../../utils/testing/ui_test_mode.dart';
import '../../widgets/import/curl_import_dialog.dart';
import '../../widgets/import_export/export_dialog.dart';
import '../../widgets/import_export/import_dialog.dart';
import '../common/app_badge.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_divider.dart';
import '../common/app_empty_state.dart';
import '../common/app_popup_menu.dart';
import '../common/app_segmented_control.dart';
import '../common/app_text_field.dart';
import '../environment/environment_manager_dialog.dart';
import '../environment/environment_switcher.dart';

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

  // 行 hover 状态（控制 ⋮ 菜单按钮 hover 才显现，设计规范）
  String? _hoveredCollectionId;
  String? _hoveredRequestId;

  // 菜单打开状态（菜单打开期间保持 ⋮ 按钮挂载——否则指针移入菜单
  // 触发行 onExit 导致按钮卸载，PopupMenuButton 的 !mounted 检查
  // 会吞掉 onSelected）
  String? _openCollectionMenuId;
  String? _openRequestMenuId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionProvider);
    final requestsAsync = ref.watch(requestsProvider);

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

    // Listen to new collection dialog trigger
    ref.listen<int?>(uiTestNewCollectionDialogProvider, (previous, current) {
      if (current != null && current != previous) {
        _showNewCollectionDialog(context);
      }
    });

    // Listen to add folder dialog trigger（以第一个 Collection 为父级）
    ref.listen<int?>(uiTestAddFolderDialogProvider, (previous, current) {
      if (current != null && current != previous) {
        ref.read(collectionProvider).whenData((collections) {
          if (collections.isNotEmpty) {
            _showAddFolderDialog(context, collections.first);
          }
        });
      }
    });

    // Listen to open about screen trigger
    ref.listen<int?>(uiTestOpenAboutScreenProvider, (previous, current) {
      if (current != null && current != previous) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
      }
    });

    // Listen to open design gallery trigger
    ref.listen<int?>(uiTestDesignGalleryProvider, (previous, current) {
      if (current != null && current != previous) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DesignGalleryScreen(),
          ),
        );
      }
    });

    // Listen to environment manager dialog trigger
    ref.listen<int?>(uiTestEnvironmentDialogProvider, (previous, current) {
      if (current != null && current != previous) {
        showEnvironmentManagerDialog(context);
      }
    });

    // Listen to cURL import dialog trigger
    ref.listen<int?>(uiTestCurlImportDialogProvider, (previous, current) {
      if (current != null && current != previous) {
        _showCurlImportDialog(context);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: context.appTheme.surface,
        border: Border(
          right: BorderSide(
            color: context.appTheme.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),
          const AppDivider(),
          // Environment switcher
          const EnvironmentSwitcher(),
          // Search
          _buildSearch(context),
          // Collection tree
          Expanded(
            child: collections.when(
              data: (data) {
                return requestsAsync.when(
                  data: (requests) =>
                      _buildCollectionTree(context, data, requests),
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Error: $err',
                      style: AppTextStyles.body13.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: AppTextStyles.body13.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
          // Footer：主题模式切换
          const AppDivider(),
          _buildFooter(context),
        ],
      ),
    );
  }

  /// 底栏：主题模式切换（跟随系统 / 浅色 / 深色），持久化到 AppSettings
  Widget _buildFooter(BuildContext context) {
    final themeMode =
        ref.watch(settingsProvider).valueOrNull?.themeMode ?? 'system';

    return Container(
      height: AppMetrics.height36,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space8),
      alignment: Alignment.centerLeft,
      child: AppSegmentedControl<String>(
        value: themeMode,
        items: const [
          AppSegmentedItem(
            value: 'system',
            icon: Icons.brightness_auto_outlined,
            tooltip: 'System theme',
          ),
          AppSegmentedItem(
            value: 'light',
            icon: Icons.light_mode_outlined,
            tooltip: 'Light theme',
          ),
          AppSegmentedItem(
            value: 'dark',
            icon: Icons.dark_mode_outlined,
            tooltip: 'Dark theme',
          ),
        ],
        onChanged: (mode) =>
            ref.read(settingsProvider.notifier).updateThemeMode(mode),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: AppMetrics.height48,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space8),
      child: Row(
        children: [
          // Brand Logo
          _buildBrandLogo(context),
          const Spacer(),
          // Quick add button
          _buildQuickAddButton(context),
          const SizedBox(width: AppMetrics.space4),
          // Actions menu
          _buildActionsMenu(context),
        ],
      ),
    );
  }

  /// Build quick add button for creating new collection
  Widget _buildQuickAddButton(BuildContext context) {
    return AppIconButton(
      icon: Icons.add,
      tooltip: 'New Collection',
      iconSize: 18,
      onPressed: () => _showNewCollectionDialog(context),
    );
  }

  Widget _buildSearch(BuildContext context) {
    // 与环境选择器左缘对齐（8px 水平边距 + 8px 底距，设计原型规格）；
    // 高度 30px 与上方环境选择器齐平
    return const Padding(
      padding: EdgeInsets.only(
        left: AppMetrics.space8,
        right: AppMetrics.space8,
        bottom: AppMetrics.space8,
      ),
      child: AppTextField(
        compact: true,
        height: 30,
        hintText: 'Filter...',
      ),
    );
  }

  Widget _buildCollectionTree(
    BuildContext context,
    List<Collection> collections,
    List<HttpRequest> requests,
  ) {
    if (collections.isEmpty) {
      return _buildEmptyState(context);
    }

    // 构建树形结构：将扁平化的 parentId 关联转换为嵌套结构
    final rootCollections = _buildHierarchy(collections, requests);

    return ListView.builder(
      // 树区域 6px 水平内边距（配合行 4px 圆角选中底，设计原型规格）
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      itemCount: rootCollections.length,
      itemBuilder: (context, index) {
        return _buildCollectionItem(
          context,
          rootCollections[index],
          0,
          collections,
          requests,
        );
      },
    );
  }

  /// 将扁平化的集合列表构建为层级结构，并关联请求
  List<Collection> _buildHierarchy(
    List<Collection> collections,
    List<HttpRequest> requests,
  ) {
    // 创建集合映射（ID -> 集合）
    final collectionMap = {
      for (final c in collections) c.id: c,
    };

    // 找出所有子集合 ID（通过 parentId 关联的）
    final childIdsViaParentId = <String>{};
    for (final c in collections) {
      if (c.parentId != null && collectionMap.containsKey(c.parentId)) {
        childIdsViaParentId.add(c.id);
      }
    }

    // 找出所有出现在其他集合 children 列表中的子集合 ID
    final childIdsViaNested = <String>{};
    for (final c in collections) {
      for (final child in c.children) {
        if (collectionMap.containsKey(child.id)) {
          childIdsViaNested.add(child.id);
        }
      }
    }

    // 所有子集合的 ID（两种来源的并集）
    final allChildIds = {...childIdsViaParentId, ...childIdsViaNested};

    // 递归构建树形结构
    Collection buildTree(String collectionId, Set<String> visited) {
      if (visited.contains(collectionId)) {
        // 避免循环引用
        return collectionMap[collectionId]!.copyWith(id: '__circular__');
      }
      visited.add(collectionId);

      final collection = collectionMap[collectionId]!;

      // 收集通过 parentId 关联的子集合
      final childrenViaParentId = collections
          .where((c) => c.parentId == collectionId)
          .map((c) => buildTree(c.id, {...visited}))
          .where((c) => c.id != '__circular__')
          .toList();

      // 收集嵌套在 children 中的子集合（但只在扁平列表中存在的）
      final childrenViaNested = collection.children
          .where((c) =>
              collectionMap.containsKey(c.id) &&
              !childIdsViaParentId.contains(c.id)) // 避免重复添加
          .map((c) => buildTree(c.id, {...visited}))
          .where((c) => c.id != '__circular__')
          .toList();

      // 合并两种来源的子集合
      final allChildren = [...childrenViaParentId, ...childrenViaNested];

      // 收集与该集合关联的请求（通过 parentId）
      final collectionRequests =
          requests.where((r) => r.parentId == collectionId).toList();

      // 合并请求：集合原有的请求 + 通过 parentId 关联的请求
      final allRequests = [...collection.requests, ...collectionRequests];

      return collection.copyWith(
        children: allChildren,
        requests: allRequests,
      );
    }

    // 找到所有根集合并构建树
    final roots = collections.where((c) => !allChildIds.contains(c.id));
    final result = <Collection>[];

    for (final root in roots) {
      final tree = buildTree(root.id, {});
      if (tree.id != '__circular__') {
        result.add(tree);
      }
    }

    return result;
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppEmptyState(
      icon: Icons.folder_open_outlined,
      title: 'No collections yet',
      subtitle: 'Collections group your API requests',
      action: AppButton.primary(
        label: 'Create Collection',
        icon: Icons.add,
        size: AppButtonSize.small,
        onPressed: () => _showNewCollectionDialog(context),
      ),
    );
  }

  Widget _buildCollectionItem(
    BuildContext context,
    Collection collection,
    int depth,
    List<Collection> allCollections,
    List<HttpRequest> allRequests,
  ) {
    final isExpanded = collection.isExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.transparent,
          borderRadius: AppMetrics.br4,
          child: MouseRegion(
            onEnter: (_) =>
                setState(() => _hoveredCollectionId = collection.id),
            onExit: (_) {
              if (_hoveredCollectionId == collection.id) {
                setState(() => _hoveredCollectionId = null);
              }
            },
            child: InkWell(
              borderRadius: AppMetrics.br4,
              onTap: () {
                ref
                    .read(collectionProvider.notifier)
                    .toggleExpanded(collection.id);
              },
              hoverColor: context.appTheme.surfaceVariant,
              child: Container(
                height: AppMetrics.height28,
                padding: EdgeInsets.only(
                  left: AppMetrics.space8 + depth * AppMetrics.space12,
                  right: AppMetrics.space8,
                ),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: AppMetrics.animFast,
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: collection.children.isEmpty &&
                                collection.requests.isEmpty
                            ? AppColors.transparent
                            : context.appTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppMetrics.space4),
                    Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      size: 16,
                      color: isExpanded
                          ? context.appTheme.brand
                          : context.appTheme.brand.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: AppMetrics.space4),
                    Expanded(
                      child: Text(
                        collection.name,
                        style: AppTextStyles.caption12.copyWith(
                          color: context.appTheme.textPrimary,
                          fontWeight:
                              isExpanded ? FontWeight.w600 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 菜单按钮 hover 才显现（设计规范）。
                    // 注意必须用 Visibility 保持 State 常驻：菜单打开期间
                    // 指针移入菜单会触发行 onExit，若按钮被卸载，
                    // PopupMenuButton 内部 !mounted 检查会吞掉 onSelected。
                    if (_hoveredCollectionId == collection.id ||
                        _openCollectionMenuId == collection.id)
                      _buildCollectionActions(context, collection)
                    else
                      const SizedBox(width: 28), // 占位，保持行宽稳定
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              ...collection.children.map(
                (child) => _buildCollectionItem(
                    context, child, depth + 1, allCollections, allRequests),
              ),
              ...collection.requests.map(
                (request) => _buildRequestItem(context, request, depth + 1),
              ),
            ],
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AppMetrics.animFast,
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
          color: isActive ? context.appTheme.brandSoft : AppColors.transparent,
          borderRadius: AppMetrics.br4,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredRequestId = request.id),
            onExit: (_) {
              if (_hoveredRequestId == request.id) {
                setState(() => _hoveredRequestId = null);
              }
            },
            child: InkWell(
              borderRadius: AppMetrics.br4,
              onTap: _isEditingName && _editingRequestId == request.id
                  ? null
                  : () {
                      ref.read(requestTabProvider.notifier).openTab(request);
                      ref.read(activeTabIdProvider.notifier).state = request.id;
                    },
              onSecondaryTapDown: (details) => _showRequestContextMenu(
                  context, request, details.globalPosition, setState),
              hoverColor: context.appTheme.surfaceVariant,
              child: Container(
                height: AppMetrics.height28,
                padding: EdgeInsets.only(
                  left: AppMetrics.space8 + depth * AppMetrics.space12 + 12,
                  right: AppMetrics.space8,
                ),
                child: Row(
                  children: [
                    // Method badge
                    MethodBadge(request.method.value),
                    const SizedBox(width: 6),
                    // 名称显示或编辑
                    Expanded(
                      child: _isEditingName && _editingRequestId == request.id
                          ? _buildNameEditor(context, request, setState)
                          : _buildNameDisplay(context, request, isActive),
                    ),
                    // 编辑时显示操作按钮，选中/悬停/菜单打开时显示菜单按钮
                    //（菜单打开期间必须保持挂载，否则 onSelected 会被吞掉）
                    if (_isEditingName && _editingRequestId == request.id) ...[
                      _buildEditActions(context, request, setState),
                    ] else if (isActive ||
                        _hoveredRequestId == request.id ||
                        _openRequestMenuId == request.id)
                      _buildRequestMenuButton(context, request)
                    else
                      const SizedBox(width: 28), // 保持间距一致
                  ],
                ),
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
    return Text(
      request.name,
      style: AppTextStyles.caption12.copyWith(
        color: isActive ? context.appTheme.brand : context.appTheme.textPrimary,
        fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
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
        style: AppTextStyles.caption12.copyWith(
          color: context.appTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          border: OutlineInputBorder(
            borderRadius: AppMetrics.br4,
            borderSide:
                BorderSide(color: AppColors.brand.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppMetrics.br4,
            borderSide:
                BorderSide(color: AppColors.brand.withValues(alpha: 0.3)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppMetrics.br4,
            borderSide: BorderSide(color: AppColors.brand),
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
        AppIconButton(
          icon: Icons.check,
          tooltip: 'Save',
          color: AppColors.success,
          size: 20,
          iconSize: 14,
          onPressed: () => _saveRequestName(context, request, setState),
        ),
        const SizedBox(width: 4),
        AppIconButton(
          icon: Icons.close,
          tooltip: 'Cancel',
          color: AppColors.error,
          size: 20,
          iconSize: 14,
          onPressed: () => _cancelEdit(setState),
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
      color: AppColors.transparent,
      borderRadius: AppMetrics.br4,
      child: InkWell(
        borderRadius: AppMetrics.br4,
        onTap: () {},
        child: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 14,
            color: context.appTheme.textTertiary,
          ),
          offset: const Offset(0, 24),
          constraints: const BoxConstraints(minWidth: 140),
          shape: AppPopupMenu.menuShape(theme),
          elevation: AppPopupMenu.menuElevation,
          color: AppPopupMenu.menuColor(theme),
          onOpened: () => setState(() => _openRequestMenuId = request.id),
          onCanceled: () => setState(() => _openRequestMenuId = null),
          itemBuilder: (context) => [
            AppPopupMenu.iconItem(
              theme: theme,
              value: 'rename',
              icon: Icons.edit_outlined,
              label: 'Rename',
            ),
            AppPopupMenu.iconItem(
              theme: theme,
              value: 'delete',
              icon: Icons.delete_outline,
              label: 'Delete',
              iconColor: AppColors.error,
              labelColor: AppColors.error,
            ),
          ],
          onSelected: (value) {
            setState(() => _openRequestMenuId = null);
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

  /// 显示请求右键菜单（在指针位置弹出，样式与 ⋮ 菜单统一）
  void _showRequestContextMenu(
    BuildContext context,
    HttpRequest request,
    Offset position,
    StateSetter setState,
  ) {
    final theme = Theme.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      shape: AppPopupMenu.menuShape(theme),
      elevation: AppPopupMenu.menuElevation,
      color: AppPopupMenu.menuColor(theme),
      items: [
        AppPopupMenu.iconItem(
          theme: theme,
          value: 'rename',
          icon: Icons.edit_outlined,
          label: 'Rename',
        ),
        AppPopupMenu.iconItem(
          theme: theme,
          value: 'delete',
          icon: Icons.delete_outline,
          label: 'Delete',
          iconColor: AppColors.error,
          labelColor: AppColors.error,
        ),
      ],
    ).then((value) {
      if (value == 'rename') {
        _startEditingName(request.id, request.name, setState);
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
    showAppDialog(
      context: context,
      title: 'Delete Request',
      child: Text(
        'Are you sure you want to delete "${request.name}"? This action cannot be undone.',
        style: AppTextStyles.body13.copyWith(
          color: context.appTheme.textSecondary,
        ),
      ),
      actions: [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.danger(
          label: 'Delete',
          onPressed: () {
            // 删除请求
            _deleteRequest(request);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  /// 删除请求
  void _deleteRequest(HttpRequest request) {
    // 关闭相关 Tab
    final tab = ref.read(requestTabProvider.notifier).getTab(request.id);
    if (tab != null) {
      ref.read(requestTabProvider.notifier).closeTab(request.id);
    }

    // 从 Collection 中删除（扁平化存储：直接删除请求）
    ref.read(collectionProvider.notifier).deleteRequestFromCollection(
          '', // collectionId 在扁平化存储下不再需要
          request.id,
        );
  }

  Widget _buildCollectionActions(
    BuildContext context,
    Collection collection,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.transparent,
      borderRadius: AppMetrics.br4,
      child: InkWell(
        borderRadius: AppMetrics.br4,
        onTap: () {}, // PopupMenuButton will handle the tap
        child: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 16,
            color: context.appTheme.textTertiary,
          ),
          offset: const Offset(0, 28),
          constraints: const BoxConstraints(minWidth: 160),
          shape: AppPopupMenu.menuShape(theme),
          elevation: AppPopupMenu.menuElevation,
          color: AppPopupMenu.menuColor(theme),
          onOpened: () => setState(() => _openCollectionMenuId = collection.id),
          onCanceled: () => setState(() => _openCollectionMenuId = null),
          itemBuilder: (context) => [
            AppPopupMenu.iconItem(
              theme: theme,
              value: 'add_request',
              icon: Icons.add,
              label: 'Add Request',
              iconColor: AppColors.brand,
            ),
            AppPopupMenu.iconItem(
              theme: theme,
              value: 'add_folder',
              icon: Icons.create_new_folder_outlined,
              label: 'Add Folder',
              iconColor: AppColors.info,
            ),
            const PopupMenuDivider(height: 1),
            AppPopupMenu.iconItem(
              theme: theme,
              value: 'export',
              icon: Icons.upload,
              label: 'Export',
            ),
            AppPopupMenu.iconItem(
              theme: theme,
              value: 'rename',
              icon: Icons.edit_outlined,
              label: 'Rename',
            ),
            AppPopupMenu.iconItem(
              theme: theme,
              value: 'delete',
              icon: Icons.delete_outline,
              label: 'Delete',
              iconColor: AppColors.error,
              labelColor: AppColors.error,
            ),
          ],
          onSelected: (value) {
            setState(() => _openCollectionMenuId = null);
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
              case 'add_folder':
                AppLogger.info(
                    '[Sidebar] Adding new folder to collection: ${collection.name}');
                _showAddFolderDialog(context, collection);
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

  void _showAddFolderDialog(BuildContext context, Collection parentCollection) {
    _showNameInputDialog(
      context,
      title: 'New Folder',
      hintText: 'Enter folder name',
      onCreate: (name) {
        final newFolder = Collection.empty().copyWith(
          name: name,
          parentId: parentCollection.id,
        );
        ref.read(collectionProvider.notifier).addCollection(newFolder);
      },
    );
  }

  void _showNewCollectionDialog(BuildContext context) {
    _showNameInputDialog(
      context,
      title: 'New Collection',
      hintText: 'Enter collection name',
      onCreate: (name) {
        ref.read(collectionProvider.notifier).addCollection(
              Collection.empty().copyWith(name: name),
            );
      },
    );
  }

  /// 规范样式的命名输入对话框（New Collection / New Folder 共用）
  ///
  /// 统一组件：AppDialog + AppTextField；Cancel 用 AppButton.ghost，
  /// Create 用 AppButton.primary。
  void _showNameInputDialog(
    BuildContext context, {
    required String title,
    required String hintText,
    required void Function(String name) onCreate,
  }) {
    final controller = TextEditingController();

    void submit() {
      if (controller.text.isNotEmpty) {
        onCreate(controller.text);
        Navigator.pop(context);
      }
    }

    showAppDialog(
      context: context,
      title: title,
      child: AppTextField(
        controller: controller,
        autofocus: true,
        hintText: hintText,
        onSubmitted: (_) => submit(),
      ),
      actions: [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'Create',
          onPressed: submit,
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Collection collection,
  ) {
    showAppDialog(
      context: context,
      title: 'Delete Collection',
      child: Text(
        'Are you sure you want to delete "${collection.name}"? This action cannot be undone.',
        style: AppTextStyles.body13.copyWith(
          color: context.appTheme.textSecondary,
        ),
      ),
      actions: [
        AppButton.ghost(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.danger(
          label: 'Delete',
          onPressed: () {
            ref.read(collectionProvider.notifier).deleteCollection(
                  collection.id,
                );
            Navigator.pop(context);
          },
        ),
      ],
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
      icon:
          Icon(Icons.more_vert, size: 18, color: context.appTheme.textTertiary),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      offset: const Offset(0, 28),
      shape: AppPopupMenu.menuShape(theme),
      elevation: AppPopupMenu.menuElevation,
      color: AppPopupMenu.menuColor(theme),
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
        AppPopupMenu.iconItem(
          theme: theme,
          value: 'new',
          icon: Icons.add,
          label: 'New Collection',
          iconColor: AppColors.brand,
        ),
        AppPopupMenu.iconItem(
          theme: theme,
          value: 'import',
          icon: Icons.download,
          label: 'Import Postman',
        ),
        AppPopupMenu.iconItem(
          theme: theme,
          value: 'import_curl',
          icon: Icons.terminal,
          label: 'Import from cURL',
        ),
        AppPopupMenu.iconItem(
          theme: theme,
          value: 'refresh',
          icon: Icons.refresh,
          label: 'Refresh',
        ),
        const PopupMenuDivider(height: 1),
        AppPopupMenu.iconItem(
          theme: theme,
          value: 'about',
          icon: Icons.info_outline,
          label: 'About',
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

    showAppDialog(
      context: context,
      title: 'About',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: AppMetrics.br10,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppMetrics.br10,
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // App name
          Text(
            'Hopp',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [
                    colorScheme.primary,
                    AppColors.accentPink,
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
              color: context.appTheme.textPrimary.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          const AppDivider(height: 16),
          const SizedBox(height: 16),
          // Version
          _buildInfoRow(
            context,
            'Version',
            ref.watch(appVersionProvider).valueOrNull ?? kFallbackAppVersion,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Platform', 'macOS'),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Flutter', '3.27.x'),
          const SizedBox(height: 16),
          const AppDivider(height: 16),
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
            style: AppTextStyles.tiny11.copyWith(
              color: context.appTheme.textPrimary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
      actions: [
        AppButton.ghost(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'More Info',
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AboutScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.appTheme.textPrimary.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
