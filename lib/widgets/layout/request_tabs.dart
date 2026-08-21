import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/http_request.dart';
import '../../models/request_tab.dart';
import '../../providers/providers.dart';
import '../../utils/app_logger.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart' hide AppColors;

/// 请求标签栏组件
///
/// 显示所有打开的请求标签，支持切换和关闭
class RequestTabs extends ConsumerWidget with LogMixin {
  const RequestTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(requestTabProvider);
    final activeTabId = ref.watch(activeTabIdProvider);

    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 32,
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
        hoverColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.brand : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Method badge with improved styling
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: methodColor.withValues(alpha: isActive ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  tab.request.method.value,
                  style: TextStyle(
                    fontSize: 9,
                    color: methodColor,
                    fontWeight: FontWeight.w700,
                    height: 1,
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
                    color: AppColors.brand,
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
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 10,
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
        onTap: () => _createNewRequest(ref),
        hoverColor: theme.colorScheme.surfaceContainerHighest,
        child: Container(
          width: 36,
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Icon(
            Icons.add,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// 创建新请求
  void _createNewRequest(WidgetRef ref) {
    logInfo('Creating new request from tab bar');
    final newRequest = HttpRequest.empty();
    ref.read(requestTabProvider.notifier).openTab(newRequest);
    ref.read(activeTabIdProvider.notifier).state = newRequest.id;
    logInfo('New request created: ${newRequest.id}');
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
    return AppColors.method(method);
  }
}
