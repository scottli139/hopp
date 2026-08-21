import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../utils/testing/ui_test_mode.dart';

import '../providers/providers.dart';
import '../widgets/common/app_button.dart';
import '../widgets/layout/sidebar.dart';
import '../widgets/layout/request_tabs.dart';
import '../widgets/request/request_editor.dart';
import '../widgets/request/response_viewer.dart';
import '../models/http_request.dart';

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

  /// 监听 UI 测试命令
  void _listenToUITestCommands() {
    // 监听分隔线位置变化；只在值变化时重新应用，
    // 避免每次 build 都替换 areas 导致子树 State 被销毁（编辑器 Tab 被重置）
    final dividerRatio = ref.watch(uiTestDividerPositionProvider);
    if (dividerRatio != _lastAppliedDividerRatio) {
      _lastAppliedDividerRatio = dividerRatio;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _verticalSplitController.areas = [
            Area(flex: dividerRatio),
            Area(flex: 1.0 - dividerRatio),
          ];
        }
      });
    }
  }

  double _lastAppliedDividerRatio = 0.5;

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(requestTabProvider);
    final activeTab = ref.watch(activeTabProvider);

    final theme = Theme.of(context);

    // 监听 UI 测试模式的分隔线位置控制
    _listenToUITestCommands();

    return Scaffold(
      body: Column(
        children: [
          // Main content with sidebar and request area
          Expanded(
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                dividerThickness: 1,
                dividerPainter: DividerPainters.background(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  highlightedColor:
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
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
          ),
          // Status bar
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          const SizedBox(height: 24),
          Text(
            'No requests yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get started by creating your first request',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          // Create Request button
          AppButton.primary(
            onPressed: () => _createNewRequest(),
            icon: Icons.add,
            label: 'Create Request',
          ),
          const SizedBox(height: 12),
          // Keyboard shortcut hint
          Text(
            'or press Cmd+N',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: colorScheme.outline.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Create a new request and open it in a tab
  void _createNewRequest() {
    final newRequest = HttpRequest.empty();
    ref.read(requestTabProvider.notifier).openTab(newRequest);
    ref.read(activeTabIdProvider.notifier).state = newRequest.id;
  }

  Widget _buildNoActiveTabState() {
    return const Center(
      child: Text('Select a tab to start'),
    );
  }

  Widget _buildRequestResponseArea() {
    final theme = Theme.of(context);

    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 12,
        dividerPainter: DividerPainters.grooved2(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          highlightedColor: theme.colorScheme.primary.withValues(alpha: 0.6),
          thickness: 2,
          count: 3,
          highlightedCount: 5,
          gap: 3,
        ),
      ),
      child: MultiSplitView(
        axis: Axis.vertical,
        controller: _verticalSplitController,
        builder: (context, area) {
          if (area.index == 0) {
            return const RequestEditor();
          } else {
            return const ResponseViewer();
          }
        },
      ),
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
                  colorScheme.primary.withValues(alpha: 0.8),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.8),
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
            'v0.6.0',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
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
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
