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

  @override
  void dispose() {
    _splitController.dispose();
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
          Icon(
            Icons.api_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
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
            'Click "+" to create a new request',
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
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Hopp v0.1.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
          ),
          const Spacer(),
          Text(
            'Ready',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
