import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../providers/providers.dart';
import '../../utils/app_logger.dart';
import '../../utils/constants.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionProvider);
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Header
          _buildHeader(context, ref),
          const Divider(height: 1),
          // Search
          _buildSearch(context),
          // Collection tree
          Expanded(
            child: collections.when(
              data: (data) => _buildCollectionTree(context, ref, data),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      height: AppConstants.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Collections',
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            tooltip: 'New Collection',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _showNewCollectionDialog(context, ref),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            tooltip: 'Refresh',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              ref.read(collectionProvider.notifier).loadCollections();
            },
          ),
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
    WidgetRef ref,
    List<Collection> collections,
  ) {
    if (collections.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: collections.length,
      itemBuilder: (context, index) {
        return _buildCollectionItem(context, ref, collections[index], 0);
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
    WidgetRef ref,
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
              ref.read(collectionProvider.notifier).toggleExpanded(collection.id);
            },
            hoverColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                      color: collection.children.isEmpty && collection.requests.isEmpty
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
                        fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildCollectionActions(context, ref, collection),
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
                (child) => _buildCollectionItem(context, ref, child, depth + 1),
              ),
              ...collection.requests.map(
                (request) =>
                    _buildRequestItem(context, ref, request, depth + 1),
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
    WidgetRef ref,
    HttpRequest request,
    int depth,
  ) {
    final theme = Theme.of(context);
    final isActive = ref.watch(activeTabIdProvider) == request.id;

    return Material(
      color: isActive
          ? AppColors.primary.withOpacity(0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(requestTabProvider.notifier).openTab(request);
          ref.read(activeTabIdProvider.notifier).state = request.id;
        },
        hoverColor: AppColors.primary.withOpacity(0.04),
        splashColor: AppColors.primary.withOpacity(0.08),
        child: Container(
          height: AppConstants.sidebarItemHeight,
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
              // Method badge with improved contrast
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getHttpMethodColor(request.method.value)
                      .withOpacity(isActive ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  request.method.value.toUpperCase(),
                  style: AppTextStyles.tiny.copyWith(
                    fontSize: 8,
                    color: AppColors.getHttpMethodColor(request.method.value),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.name,
                  style: AppTextStyles.caption.copyWith(
                    color: isActive
                        ? AppColors.primaryDark
                        : theme.colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionActions(
    BuildContext context,
    WidgetRef ref,
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
          offset: const Offset(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          color: theme.colorScheme.surface,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'add_request',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  Text(
                    'Add Request',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'add_folder',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Icon(
                      Icons.create_new_folder,
                      size: 16,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  Text(
                    'Add Folder',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'rename',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  Text(
                    'Rename',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: const Icon(
                      Icons.delete,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceM),
                  Text(
                    'Delete',
                    style: AppTextStyles.bodySmall.copyWith(
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
              case 'delete':
                _showDeleteConfirmation(context, ref, collection);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showNewCollectionDialog(BuildContext context, WidgetRef ref) {
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
    WidgetRef ref,
    Collection collection,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text(
          'Are you sure you want to delete "${collection.name}"? This action cannot be undone.',
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
}
