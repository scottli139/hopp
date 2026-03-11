import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/request_tab.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';

class RequestTabs extends ConsumerWidget {
  const RequestTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(requestTabProvider);
    final activeTabId = ref.watch(activeTabIdProvider);

    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36,
      color: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length + 1,
        itemBuilder: (context, index) {
          if (index == tabs.length) {
            return _buildNewTabButton(context, ref);
          }
          return _buildTab(context, ref, tabs[index], activeTabId);
        },
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref,
    RequestTab tab,
    String? activeTabId,
  ) {
    final isActive = tab.id == activeTabId;
    final theme = Theme.of(context);
    final methodColor = _getMethodColor(tab.request.method.value);

    return Material(
      color: isActive
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: () {
          ref.read(activeTabIdProvider.notifier).state = tab.id;
        },
        hoverColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: theme.dividerColor,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Method badge with improved styling
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: methodColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  tab.request.method.value,
                  style: AppTextStyles.tiny.copyWith(
                    fontSize: 8,
                    color: methodColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tab.request.name,
                  style: AppTextStyles.tiny.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tab.isDirty)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 4),
              // Close button with hover effect
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  onTap: () => _closeTab(ref, tab),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewTabButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () {
          // Create a new empty request
          ref.read(requestTabProvider.notifier).getTab('');
        },
        hoverColor: theme.colorScheme.surfaceContainerHighest,
        child: Container(
          width: 44,
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Icon(
              Icons.add,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _closeTab(WidgetRef ref, RequestTab tab) {
    final tabs = ref.read(requestTabProvider);
    final activeId = ref.read(activeTabIdProvider);

    ref.read(requestTabProvider.notifier).closeTab(tab.id);

    // If we're closing the active tab, activate another one
    if (activeId == tab.id) {
      final remainingTabs = tabs.where((t) => t.id != tab.id).toList();
      if (remainingTabs.isNotEmpty) {
        ref.read(activeTabIdProvider.notifier).state = remainingTabs.last.id;
      } else {
        ref.read(activeTabIdProvider.notifier).state = null;
      }
    }
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
