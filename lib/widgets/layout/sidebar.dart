import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../providers/providers.dart';
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
          Text(
            'Collections',
            style: AppTextStyles.title.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'New Collection',
            onPressed: () => _showNewCollectionDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh',
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
        InkWell(
          onTap: () {
            ref.read(collectionProvider.notifier).toggleExpanded(collection.id);
          },
          child: Container(
            height: AppConstants.sidebarItemHeight,
            padding: EdgeInsets.only(
              left: AppConstants.spaceM + depth * AppConstants.spaceL,
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
                    color: collection.children.isEmpty
                        ? Colors.transparent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppConstants.spaceXS),
                Icon(
                  isExpanded ? Icons.folder_open : Icons.folder,
                  size: 16,
                  color: AppColors.primary.withOpacity(0.8),
                ),
                const SizedBox(width: AppConstants.spaceS),
                Expanded(
                  child: Text(
                    collection.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildCollectionActions(context, ref, collection),
              ],
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
                (request) => _buildRequestItem(context, ref, request, depth + 1),
              ),
            ],
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
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

    return InkWell(
      onTap: () {
        ref.read(requestTabProvider.notifier).openTab(request);
        ref.read(activeTabIdProvider.notifier).state = request.id;
      },
      child: Container(
        height: AppConstants.sidebarItemHeight,
        padding: EdgeInsets.only(
          left: AppConstants.spaceM + depth * AppConstants.spaceL + 20,
          right: AppConstants.spaceM,
        ),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              )
            : null,
        child: Row(
          children: [
            AppComponentStyles.httpMethodBadge(request.method.value),
            const SizedBox(width: AppConstants.spaceS),
            Expanded(
              child: Text(
                request.name,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isActive
                      ? AppColors.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionActions(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 14),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'add_request',
          child: Row(
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: AppConstants.spaceS),
              Text('Add Request'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add_folder',
          child: Row(
            children: [
              Icon(Icons.create_new_folder, size: 16),
              SizedBox(width: AppConstants.spaceS),
              Text('Add Folder'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: AppConstants.spaceS),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 16, color: AppColors.error),
              const SizedBox(width: AppConstants.spaceS),
              Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'add_request':
            final newRequest = HttpRequest.empty().copyWith(
              parentId: collection.id,
            );
            ref.read(collectionProvider.notifier).addRequestToCollection(
              collection.id,
              newRequest,
            );
            ref.read(requestTabProvider.notifier).openTab(newRequest);
            ref.read(activeTabIdProvider.notifier).state = newRequest.id;
            break;
          case 'delete':
            _showDeleteConfirmation(context, ref, collection);
            break;
        }
      },
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
