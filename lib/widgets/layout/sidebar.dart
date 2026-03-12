import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../providers/providers.dart';
import '../../screens/about/about_screen.dart';
import '../../utils/app_logger.dart';
import '../../utils/constants.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionProvider);
    final theme = Theme.of(context);

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
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceS),
      child: Row(
        children: [
          // Brand Logo
          _buildBrandLogo(context),
          const Spacer(),
          // Actions menu
          _buildActionsMenu(context, ref),
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
      color:
          isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(requestTabProvider.notifier).openTab(request);
          ref.read(activeTabIdProvider.notifier).state = request.id;
        },
        hoverColor: AppColors.primary.withOpacity(0.04),
        splashColor: AppColors.primary.withOpacity(0.08),
        child: Container(
          height: 32, // 统一高度
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
              // Method badge - 增大字体到 10px
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getHttpMethodColor(request.method.value)
                      .withOpacity(isActive ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  request.method.value.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.getHttpMethodColor(request.method.value),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.name,
                  style: TextStyle(
                    fontSize: 11, // 统一字体大小
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

  /// Build brand logo widget
  Widget _buildBrandLogo(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: 24,
      height: 24,
    );
  }

  /// Build actions menu button
  Widget _buildActionsMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onSelected: (value) {
        switch (value) {
          case 'about':
            _showAboutDialog(context);
            break;
          case 'new':
            _showNewCollectionDialog(context, ref);
            break;
          case 'refresh':
            ref.read(collectionProvider.notifier).loadCollections();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'about',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18),
              SizedBox(width: 8),
              Text('About'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'new',
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('New Collection'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 18),
              SizedBox(width: 8),
              Text('Refresh'),
            ],
          ),
        ),
      ],
    );
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
              _buildInfoRow(context, 'Version', '0.1.0 (Beta)'),
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
