import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../providers/providers.dart';
import '../widgets/layout/sidebar.dart';
import '../widgets/layout/request_tabs.dart';
import '../widgets/request/request_editor.dart';
import '../widgets/request/response_viewer.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final MultiSplitViewController _splitController = MultiSplitViewController(
    areas: [
      Area(flex: 0.22, min: 0.15, max: 0.4),
      Area(flex: 0.78),
    ],
  );
  final MultiSplitViewController _verticalSplitController =
      MultiSplitViewController(
    areas: [
      Area(flex: 0.6),
      Area(flex: 0.4),
    ],
  );

  @override
  void dispose() {
    _splitController.dispose();
    _verticalSplitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(requestTabProvider);
    final activeTab = ref.watch(activeTabProvider);

    return Scaffold(
      body: Column(
        children: [
          // Main content with sidebar and request area
          Expanded(
            child: MultiSplitView(
              controller: _splitController,
              builder: (context, area) {
                if (area.index == 0) {
                  return const Sidebar();
                } else {
                  return Column(
                    children: [
                      // Request tabs
                      const RequestTabs(),
                      // Request/Response area
                      Expanded(
                        child: tabs.isEmpty
                            ? _buildEmptyState()
                            : activeTab != null
                                ? _buildRequestResponseArea()
                                : _buildNoActiveTabState(),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          // Status bar
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.svg.png',
            width: 80,
            height: 80,
            opacity: const AlwaysStoppedAnimation(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No requests yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a request from sidebar or create a new tab',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveTabState() {
    return const Center(
      child: Text('Select a tab to start'),
    );
  }

  Widget _buildRequestResponseArea() {
    return MultiSplitView(
      axis: Axis.vertical,
      controller: _verticalSplitController,
      builder: (context, area) {
        if (area.index == 0) {
          return const RequestEditor();
        } else {
          return const ResponseViewer();
        }
      },
    );
  }

  Widget _buildStatusBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Brand indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.8),
                  const Color(0xFF8B5CF6).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(
                    'assets/images/logo.svg.png',
                    width: 12,
                    height: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Hopp',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'v0.1.0',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          // Status indicator
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Ready',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
