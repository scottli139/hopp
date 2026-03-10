import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/request_tab.dart';
import '../../providers/providers.dart';

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
    final methodColor = _getMethodColor(tab.request.method.value);

    return GestureDetector(
      onTap: () {
        ref.read(activeTabIdProvider.notifier).state = tab.id;
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
            right: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: methodColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                tab.request.method.value,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: methodColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                tab.request.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tab.isDirty)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                _closeTab(ref, tab);
              },
              child: Icon(
                Icons.close,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTabButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        // Create a new empty request
        final newRequest = ref.read(requestTabProvider.notifier).getTab('');
      },
      child: Container(
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Icon(
          Icons.add,
          size: 16,
          color: Theme.of(context).colorScheme.outline,
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
