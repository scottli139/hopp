import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/json.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_syntax_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../../utils/app_logger.dart';
import '../../utils/epoch_annotation.dart';
import 'app_button.dart';
import 'app_divider.dart';
import 'offset_gutter.dart';

/// JSON 语法高亮注册（highlight 全局单例只需注册一次）
bool _jsonHighlightRegistered = false;
void _ensureJsonHighlightRegistered() {
  if (_jsonHighlightRegistered) return;
  highlight.registerLanguage('json', json);
  _jsonHighlightRegistered = true;
}

/// 大响应完整模式准备结果（isolate 返回，跨 isolate 可传）
typedef _PreparedFullContent = ({
  String content,
  List<String> styleKeys,
  List<(int, int, int)> spans,
});

/// 大响应完整模式准备（在后台 isolate 执行，保持 UI 线程不阻塞）：
/// JSON 格式化 → epoch 注解 → highlight 解析并拍平为 (start, end, styleKeyIdx)
/// 区间。样式表在 UI 线程持有，区间只传 key 索引（避免重复字符串膨胀消息）。
///
/// 注意：与 UI 线程同步路径行为严格一致——先注解再高亮（注解文本使内容
/// 不再是合法 JSON，但 highlight 按正则宽松分词，未命中片段按纯文本处理）。
_PreparedFullContent _prepareFullContentIsolate(Map<String, Object?> args) {
  final content = args['content'] as String;
  final annotate = args['annotate'] as bool;

  var display = content;
  try {
    final decoded = jsonDecode(content);
    display = const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    // 解析失败沿用原文（与 UI 线程 _formatContent 一致）
  }
  if (annotate) {
    display = display.split('\n').map(EpochAnnotation.annotateLine).join('\n');
  }

  highlight.registerLanguage('json', json);
  final result = highlight.parse(display, language: 'json');

  final styleKeys = <String>[];
  final keyIndex = <String, int>{};
  final spans = <(int, int, int)>[];
  var offset = 0;

  void walk(Node node, String? inherited) {
    // 有效类名 = 最近的带类名祖先（与 _buildHighlightSpans 的 span 树继承一致）
    final className = node.className ?? inherited;
    final value = node.value;
    if (value != null && value.isNotEmpty) {
      // 区间必须全覆盖（含无类名分段，key=-1），否则行切片会丢文本
      var idx = -1;
      if (className != null) {
        idx = keyIndex.putIfAbsent(className, () {
          styleKeys.add(className);
          return styleKeys.length - 1;
        });
      }
      spans.add((offset, offset + value.length, idx));
      offset += value.length;
    }
    for (final child in node.children ?? const <Node>[]) {
      walk(child, className);
    }
  }

  for (final node in result.nodes ?? const <Node>[]) {
    walk(node, null);
  }
  return (content: display, styleKeys: styleKeys, spans: spans);
}

/// 响应显示模式
enum ResponseDisplayMode {
  /// 自动模式（根据大小自动选择）
  auto,

  /// 性能模式（虚拟化显示，无语法高亮）
  performance,

  /// 完整模式（语法高亮，适合小响应）
  full,

  /// 原始文本模式（纯文本，无格式）
  raw,
}

/// 大响应虚拟化显示组件
///
/// 针对大 JSON/文本响应进行优化，使用虚拟化列表避免一次性渲染大量内容
class OptimizedResponseViewer extends StatefulWidget {
  const OptimizedResponseViewer({
    super.key,
    required this.content,
    this.contentType,
    this.initialMode = ResponseDisplayMode.auto,
    this.performanceThreshold = 50000, // 50KB
    this.virtualizationThreshold = 10000, // 10KB
    this.maxInitialLines = 500,
    this.showLineNumbers = true,
    this.showBeautifyButton = true,
    this.scrollController,
  });

  /// 响应内容
  final String content;

  /// 内容类型（用于判断是否为 JSON）
  final String? contentType;

  /// 初始显示模式
  final ResponseDisplayMode initialMode;

  /// 性能模式阈值（字节数），超过此值自动切换到性能模式
  final int performanceThreshold;

  /// 虚拟化阈值（字节数），超过此值使用虚拟化列表
  final int virtualizationThreshold;

  /// 初始显示的最大行数（性能模式下）
  final int maxInitialLines;

  /// 是否显示行号
  final bool showLineNumbers;

  /// 是否显示 Beautify 按钮
  final bool showBeautifyButton;

  /// 外部滚动控制器（可选）
  ///
  /// 传入后替代内部控制器驱动主内容滚动（各显示模式通用），
  /// 用于 UI 测试模式下的程序化滚动。
  final ScrollController? scrollController;

  @override
  State<OptimizedResponseViewer> createState() =>
      _OptimizedResponseViewerState();
}

class _OptimizedResponseViewerState extends State<OptimizedResponseViewer>
    with LogMixin {
  // 行号区域常量
  static const double _lineNumberWidth = 40.0;
  static const double _lineNumberPadding = 8.0;

  late ResponseDisplayMode _currentMode;
  late List<String> _lines;
  bool _isJson = false;
  int _displayedLines = 0;
  bool _showAllLines = false;

  /// epoch 时间戳注解开关（F8.5，仅 JSON 生效；仅渲染层，不改原始报文）
  bool _annotateEpoch = true;

  // 滚动控制器
  final ScrollController _scrollController = ScrollController();

  /// 完整/原始模式异步管线阈值（字节）：超过后格式化/高亮进 isolate、
  /// 行计算分块让出事件循环——大响应不再阻塞 UI（9000 行曾卡死 >30s）
  static const int _kAsyncPipelineBytes = 100 * 1024;

  // ---- 完整/原始模式派生数据缓存（key 变化即重建）----
  /// 当前派生数据的身份 key（内容身份/宽度/缩放/主题/模式/注解开关）
  String _layoutKey = '';
  List<({int start, int end, TextStyle? style})> _intervals = const [];
  List<({int? docLine, List<InlineSpan> spans})> _visualRows = [];
  List<int?> _rowDocLines = [];

  /// 同步路径的 format+annotate 缓存（同一份内容不再每次 build 重算）
  String _preparedSyncKey = '';
  String _preparedSyncContent = '';

  /// 异步管线状态：_preparing = isolate 准备中；_rowsComputing = 分块
  /// 行计算进行中（两者期间内容区显示进度指示）
  bool _preparing = false;
  bool _rowsComputing = false;

  /// 取消令牌：内容/宽度/缩放/主题/注解变化时递增，进行中的异步管线
  /// 与分块行计算在每步检查，过期即丢弃
  int _pipelineToken = 0;

  /// 可视行计数通知器：异步分块行计算渐进追加时驱动 ListView 重建。
  /// 不能用 state 的 setState——行数据在 LayoutBuilder 闭包内消费，
  /// setState 只触发 widget 更新，约束未变时 builder 不重跑、子树陈旧
  /// （曾导致渐进加载后 ScrollPosition extent 停在首个分块的行数）
  final ValueNotifier<int> _rowCountNotifier = ValueNotifier(0);

  bool _extentRefreshScheduled = false;

  /// itemCount 增长后强制滚动视口重算 extent。
  ///
  /// 框架已知行为（SliverMultiBoxAdaptorElement.performRebuild 源码注释）：
  /// 列表行数增长时若现有可视子元素未变，布局阶段被跳过，maxScrollExtent
  /// 停在旧值，直到发生真实滚动才自愈（极端表现：渐进加载完成后 extent
  /// 停在首个分块的行数，用户误以为内容被截断）。跨帧 ±1px 微移强制视口
  /// 重算且视觉无痕（同帧双跳会被净零 offset 优化掉，必须分两帧）；
  /// 用户正在滚动时跳过（滚动本身即触发布局、extent 自愈）。
  void _scheduleExtentRefresh() {
    if (_extentRefreshScheduled) return;
    _extentRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _extentRefreshScheduled = false;
        return;
      }
      final positions = _effectiveScrollController.positions;
      if (positions.isEmpty) {
        _extentRefreshScheduled = false;
        return;
      }
      final position = positions.last;
      if (position.isScrollingNotifier.value) {
        // 用户滚动中：不打断；本次滚动的布局会自行刷新 extent
        _extentRefreshScheduled = false;
        return;
      }
      final offset = position.pixels;
      position.jumpTo(offset + 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _extentRefreshScheduled = false;
        if (!mounted) return;
        final ps = _effectiveScrollController.positions;
        if (ps.isEmpty) return;
        final p = ps.last;
        if (p.pixels != offset && !p.isScrollingNotifier.value) {
          p.jumpTo(offset);
        }
      });
    });
  }

  // ---- 性能模式分块缓存（内容/宽度/缩放/显示行数变化时重建）----
  String _perfCacheKey = '';
  List<({String text, int? docLine})> _perfChunks = const [];
  List<int?> _perfRowDocLines = const [];

  /// 实测当前 textScaler 下的可视行高：字体度量取整使 scale() 估算与
  /// 真实渲染存在亚像素偏差并逐行累计（1.25 下 scale(18)=22.5 vs 实测 23.0）
  double _measureViewerLineHeight(TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'A',
        style: _viewerCodeStyle(Theme.of(context)),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      strutStyle: const StrutStyle(),
    )..layout();
    return painter.height;
  }

  /// 主内容滚动控制器：外部传入优先，否则用内部控制器
  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _scrollController;

  /// 当帧滚动 offset。模式切换等重建瞬间，旧 ListView 尚未 dispose、
  /// 新 ListView 已 attach，controller 会短暂挂在两个 ScrollPosition
  /// 上——此时读 .offset 会断言；取最新 attach 的 position
  double _readScrollOffset() {
    final positions = _effectiveScrollController.positions;
    return positions.isEmpty ? 0.0 : positions.last.pixels;
  }

  @override
  void initState() {
    super.initState();
    _initializeContent();
  }

  @override
  void didUpdateWidget(OptimizedResponseViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _initializeContent();
    }
  }

  @override
  void dispose() {
    _rowCountNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化内容
  void _initializeContent() {
    _lines = widget.content.split('\n');
    _isJson = _detectJson();
    // 内容变化：所有派生缓存失效，进行中的异步管线取消
    _pipelineToken++;
    _layoutKey = '';
    _preparedSyncKey = '';
    _perfCacheKey = '';
    _preparing = false;
    _rowsComputing = false;
    _rowCountNotifier.value = 0;

    // 确定初始显示模式
    if (widget.initialMode == ResponseDisplayMode.auto) {
      _currentMode = _determineOptimalMode();
    } else {
      _currentMode = widget.initialMode;
    }

    // 设置初始显示行数
    if (_lines.length > widget.maxInitialLines &&
        _currentMode == ResponseDisplayMode.performance) {
      _displayedLines = widget.maxInitialLines;
      _showAllLines = false;
    } else {
      _displayedLines = _lines.length;
      _showAllLines = true;
    }

    logDebug(
      '[OptimizedResponseViewer] Initialized: ${_lines.length} lines, '
      'mode: $_currentMode, isJson: $_isJson',
    );
  }

  /// 检测是否为 JSON 内容
  bool _detectJson() {
    // 根据 content-type 判断
    if (widget.contentType != null) {
      final ct = widget.contentType!.toLowerCase();
      if (ct.contains('json')) return true;
    }

    // 根据内容判断
    final trimmed = widget.content.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'));
  }

  /// 确定最优显示模式
  ResponseDisplayMode _determineOptimalMode() {
    final contentLength = widget.content.length;

    if (contentLength > widget.performanceThreshold) {
      return ResponseDisplayMode.performance;
    } else if (contentLength > widget.virtualizationThreshold) {
      return ResponseDisplayMode.full;
    }
    return ResponseDisplayMode.full;
  }

  /// 格式化 JSON（如果适用）
  String _formatContent() {
    if (!_isJson) return widget.content;

    try {
      final dynamic decoded = jsonDecode(widget.content);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (e) {
      // 解析失败，返回原始内容
      return widget.content;
    }
  }

  /// 复制到剪贴板
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10nBridge.t.viewer_copied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示更多行
  void _showMoreLines() {
    setState(() {
      _displayedLines =
          (_displayedLines + widget.maxInitialLines).clamp(0, _lines.length);
      if (_displayedLines >= _lines.length) {
        _showAllLines = true;
      }
    });
    _scheduleExtentRefresh();
  }

  /// 显示所有行
  void _showAllLinesNow() {
    setState(() {
      _displayedLines = _lines.length;
      _showAllLines = true;
    });
    _scheduleExtentRefresh();
  }

  /// 切换显示模式
  void _switchMode(ResponseDisplayMode mode) {
    setState(() {
      _currentMode = mode;
      if (mode == ResponseDisplayMode.performance && !_showAllLines) {
        _displayedLines = widget.maxInitialLines.clamp(0, _lines.length);
      } else {
        _displayedLines = _lines.length;
      }
    });
    _scheduleExtentRefresh();
  }

  /// 格式化 JSON 代码
  void _beautifyCode() {
    if (!_isJson) return;

    try {
      final dynamic decoded = jsonDecode(widget.content);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(decoded);

      // 更新内容
      setState(() {
        _lines = formatted.split('\n');
        _displayedLines = _lines.length;
        _showAllLines = true;
      });

      logInfo('[OptimizedResponseViewer] Code beautified');

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10nBridge.t.viewer_beautified),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stack) {
      logError('[OptimizedResponseViewer] Beautify failed', e, stack);

      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10nBridge.t.viewer_beautifyFailed),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 工具栏
        _buildToolbar(theme),
        // 内容区域
        Expanded(
          child: _buildContent(theme),
        ),
      ],
    );
  }

  /// 构建工具栏
  Widget _buildToolbar(ThemeData theme) {
    final contentLength = widget.content.length;
    final sizeText = _formatSize(contentLength);

    return Container(
      height: AppMetrics.height38,
      padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space12),
      decoration: BoxDecoration(
        color: context.appTheme.surface,
        border: Border(
          bottom: BorderSide(color: context.appTheme.border),
        ),
      ),
      child: Row(
        children: [
          // 大小信息
          Icon(
            Icons.data_usage,
            size: 14,
            color: context.appTheme.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            L10nBridge.t.viewer_sizeLines('${_lines.length}', sizeText),
            style: AppTextStyles.tiny11.copyWith(
              color: context.appTheme.textSecondary,
            ),
          ),
          const Spacer(),
          // 时间戳注解开关（仅 JSON）
          if (_isJson)
            _buildToolbarButton(
              icon: Icons.schedule,
              tooltip: _annotateEpoch
                  ? L10nBridge.t.viewer_hideTimestamps
                  : L10nBridge.t.viewer_showTimestamps,
              onPressed: () => setState(() => _annotateEpoch = !_annotateEpoch),
              theme: theme,
              isActive: _annotateEpoch,
            ),
          if (_isJson) const SizedBox(width: 8),
          // 显示模式选择（始终显示，方便用户切换）
          _buildModeSelector(theme),
          const SizedBox(width: 8),
          // Beautify 按钮
          if (widget.showBeautifyButton && _isJson)
            _buildToolbarButton(
              icon: Icons.format_align_left,
              tooltip: L10nBridge.t.viewer_beautify,
              onPressed: _beautifyCode,
              theme: theme,
            ),
          if (widget.showBeautifyButton && _isJson) const SizedBox(width: 8),
          // 复制按钮
          _buildToolbarButton(
            icon: Icons.copy,
            tooltip: L10nBridge.t.response_copy,
            onPressed: _copyToClipboard,
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// 构建显示模式选择器
  Widget _buildModeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.appTheme.surface,
        borderRadius: AppMetrics.br4,
        border: Border.all(color: context.appTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            label: L10nBridge.t.viewer_modePerformance,
            isActive: _currentMode == ResponseDisplayMode.performance,
            onPressed: () => _switchMode(ResponseDisplayMode.performance),
            theme: theme,
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: context.appTheme.border,
          ),
          _buildModeButton(
            label: L10nBridge.t.viewer_modeFull,
            isActive: _currentMode == ResponseDisplayMode.full,
            onPressed: () => _switchMode(ResponseDisplayMode.full),
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// 构建模式按钮
  Widget _buildModeButton({
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppMetrics.br4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : null,
            borderRadius: AppMetrics.br4,
          ),
          child: Text(
            label,
            style: AppTextStyles.tiny11.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ThemeData theme,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppMetrics.br4,
        child: InkWell(
          borderRadius: AppMetrics.br4,
          onTap: onPressed,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: AppMetrics.br4,
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              border: Border.all(
                color: isActive
                    ? theme.colorScheme.primary
                    : context.appTheme.border.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(ThemeData theme) {
    switch (_currentMode) {
      case ResponseDisplayMode.performance:
        return _buildPerformanceView(theme);
      case ResponseDisplayMode.full:
      case ResponseDisplayMode.auto:
        return _buildVirtualizedTextView(theme, beautify: true);
      case ResponseDisplayMode.raw:
        return _buildVirtualizedTextView(theme, beautify: false);
    }
  }

  /// 性能模式视图（虚拟化列表，超宽行按视口宽度分块）
  ///
  /// 分块原因与完整模式一致：宽度超过视口的大文本层在 Windows 150% 缩放
  /// 下滚动重绘后会被引擎按错误比例光栅化（字号翻转）；分块后所有行宽
  /// 恒 ≤ 视口宽。
  Widget _buildPerformanceView(ThemeData theme) {
    final displayLines =
        _showAllLines ? _lines : _lines.sublist(0, _displayedLines);
    final gutterWidth = widget.showLineNumbers ? _lineNumberWidth + 1 : 0.0;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scaler = MediaQuery.textScalerOf(context);
              // 条目行距 = 上下各 2 padding + 实测可视行高（字体度量取整
              // 使 scale() 估算有亚像素偏差并逐行累计）
              final rowPitch = 4 + _measureViewerLineHeight(scaler);
              // 等宽字体：ASCII 占 1 单元，CJK 等宽字符占 2 单元
              // （单元宽 7.2px 未缩放，随 textScaler 同步放大）
              final maxUnits = ((constraints.maxWidth - gutterWidth - 24) /
                      scaler.scale(7.2))
                  .floor()
                  .clamp(20, 100000);
              // 分块结果按（内容/显示行数/宽度/缩放）缓存——不再每次 build
              // 对全部行重切（9000 行 × 每次重建曾是滚动/交互卡顿来源之一）
              final perfKey = '${identityHashCode(widget.content)}|'
                  '${displayLines.length}|$maxUnits|${scaler.scale(1.0)}';
              if (_perfCacheKey != perfKey) {
                _perfChunks = [
                  for (var i = 0; i < displayLines.length; i++)
                    ..._chunkLine(displayLines[i], i, maxUnits),
                ];
                _perfRowDocLines = [for (final c in _perfChunks) c.docLine];
                _perfCacheKey = perfKey;
              }
              final chunks = _perfChunks;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 行号区域：与内容共用同一 ScrollController，当帧直绘可见
                  // 行号（修复旧版独立行号滚动控制器无人驱动、行号冻结的问题）
                  if (widget.showLineNumbers)
                    OffsetGutter(
                      theme: theme,
                      rowDocLines: _perfRowDocLines,
                      rowHeight: rowPitch,
                      topPadding: 12,
                      listenable: _effectiveScrollController,
                      readOffset: _readScrollOffset,
                      width: _lineNumberWidth,
                      rightPadding: _lineNumberPadding,
                    ),
                  // 分割线
                  if (widget.showLineNumbers)
                    const AppDivider.vertical(subtle: true),
                  // 代码区域
                  Expanded(
                    child: Scrollbar(
                      controller: _effectiveScrollController,
                      child: SelectionArea(
                        child: ListView.builder(
                          controller: _effectiveScrollController,
                          // 与行号栏 top/bottom padding 对齐，保证行号与条目同一起点
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          // 行距恒定（maxLines:1 + 固定 padding）——itemExtent 让
                          // 滚动 offset 计算 O(1)，且行号栏与内容构造性对齐
                          // （旧版注解追加文本使行换行撑高、行距漂移的潜伏
                          // 不同步一并根治）
                          itemExtent: rowPitch,
                          itemCount: chunks.length,
                          itemBuilder: (context, index) {
                            return _buildLineItem(
                              chunks[index].text,
                              index,
                              theme,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // 加载更多按钮
        if (!_showAllLines && _lines.length > _displayedLines)
          _buildLoadMoreBar(theme),
      ],
    );
  }

  /// 按显示宽度单元切分一行：首个分块带文档行号，后续分块为续行（无行号）
  List<({String text, int? docLine})> _chunkLine(
    String line,
    int docIndex,
    int maxUnits,
  ) {
    if (line.isEmpty) return [(text: ' ', docLine: docIndex + 1)];
    final chunks = <({String text, int? docLine})>[];
    var start = 0;
    var units = 0;
    var first = true;
    for (var i = 0; i < line.length; i++) {
      final u = line.codeUnitAt(i) > 0xFF ? 2 : 1;
      if (units + u > maxUnits) {
        chunks.add((
          text: line.substring(start, i),
          docLine: first ? docIndex + 1 : null
        ));
        first = false;
        start = i;
        units = 0;
      }
      units += u;
    }
    chunks.add(
        (text: line.substring(start), docLine: first ? docIndex + 1 : null));
    return chunks;
  }

  /// 构建单行显示（固定行距：maxLines:1 + 水平裁剪，行高不随内容波动）
  Widget _buildLineItem(String line, int index, ThemeData theme) {
    // JSON 行 + 注解开启时，用富文本分段渲染 epoch 注释
    if (_isJson && _annotateEpoch) {
      final spans = _buildAnnotatedSpans(line, theme);
      if (spans != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: index.isEven
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
          ),
          child: Text.rich(
            TextSpan(children: spans),
            style: _viewerCodeStyle(theme),
            softWrap: false,
            overflow: TextOverflow.clip,
            maxLines: 1,
          ),
        );
      }
    }

    // 简单的 JSON 语法高亮（性能模式下轻量级实现）
    final isJsonLine = _isJson && _shouldHighlightLine(line);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: index.isEven
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      // 裁剪而非换行：行宽超视口换行会撑高条目、破坏与行号栏的行距对齐
      // （且宽文本层在 Windows 高分屏下有滚动光栅化异常前科）
      child: Text(
        line.isEmpty ? ' ' : line, // 保持空行高度
        style: _viewerCodeStyle(
          theme,
          color: isJsonLine ? _getJsonLineColor(line, theme) : null,
        ),
        softWrap: false,
        overflow: TextOverflow.clip,
        maxLines: 1,
      ),
    );
  }

  /// epoch 注解富文本分段；无命中返回 null（调用方走原渲染）
  ///
  /// 普通文本沿用 [_getJsonLineColor] 的行级颜色；epoch 数字用 number 语法色；
  /// 注释用 tertiary 弱化色。字符串内数字不会被分段为 epoch。
  List<InlineSpan>? _buildAnnotatedSpans(String line, ThemeData theme) {
    final segments = EpochAnnotation.scanLine(line);
    if (!segments.any((s) => s.isEpoch)) {
      return null;
    }

    final isDark = theme.brightness == Brightness.dark;
    final lineColor =
        _shouldHighlightLine(line) ? _getJsonLineColor(line, theme) : null;
    final baseStyle = _viewerCodeStyle(theme, color: lineColor);
    final numberStyle = _viewerCodeStyle(
      theme,
      color: AppSyntaxColors.getNumber(isDark),
    );
    final annoStyle = _viewerCodeStyle(
      theme,
      color: context.appTheme.textTertiary,
    );

    return [
      for (final segment in segments)
        if (segment.isEpoch) ...[
          TextSpan(text: segment.text, style: numberStyle),
          TextSpan(
              text: '  ${EpochAnnotation.format(segment.text)}',
              style: annoStyle),
        ] else
          TextSpan(text: segment.text, style: baseStyle),
    ];
  }

  /// 判断是否应该高亮该行（简单的启发式）
  bool _shouldHighlightLine(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('"') ||
        trimmed.startsWith('{') ||
        trimmed.startsWith('[') ||
        trimmed.startsWith('}') ||
        trimmed.startsWith(']');
  }

  /// 获取 JSON 行颜色
  Color? _getJsonLineColor(String line, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final trimmed = line.trim();

    if (trimmed.startsWith('"')) {
      // 可能是 key 或 string value
      if (trimmed.contains('":')) {
        return AppSyntaxColors.getKey(isDark); // key
      }
      return AppSyntaxColors.getString(isDark); // string
    }
    if (trimmed == '{' ||
        trimmed == '}' ||
        trimmed == '[' ||
        trimmed == ']' ||
        trimmed == ',' ||
        trimmed == ':') {
      return AppSyntaxColors.getPunctuation(isDark);
    }
    if (trimmed == 'true' || trimmed == 'false') {
      return AppSyntaxColors.getKeyword(isDark);
    }
    if (trimmed == 'null') {
      return AppSyntaxColors.getKeyword(isDark);
    }
    // 尝试解析为数字
    if (num.tryParse(trimmed) != null) {
      return AppSyntaxColors.getNumber(isDark);
    }
    return null;
  }

  /// 构建加载更多条
  Widget _buildLoadMoreBar(ThemeData theme) {
    final remaining = _lines.length - _displayedLines;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.space16,
        vertical: AppMetrics.space12,
      ),
      decoration: BoxDecoration(
        color: context.appTheme.surface,
        border: Border(
          top: BorderSide(color: context.appTheme.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n
                .viewer_showingLines('$_displayedLines', '${_lines.length}'),
            style: AppTextStyles.caption12.copyWith(
              color: context.appTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          AppButton.secondary(
            onPressed: _showMoreLines,
            label: L10nBridge.t.viewer_loadMore('$remaining'),
          ),
          const SizedBox(width: 8),
          AppButton.ghost(
            onPressed: _showAllLinesNow,
            label: L10nBridge.t.viewer_loadAll,
          ),
        ],
      ),
    );
  }

  /// 完整/原始模式视图：虚拟化可视行渲染 + 大内容异步管线。
  ///
  /// 设计约束：不得把整份响应渲染为一个超高文本层。实测（用户多段录屏）：
  /// Windows 分数 DPI 下 7000+px 的超高文本层会被引擎按过期偏移合成——
  /// 屏幕显示与框架状态脱节（行号看似错乱/冻结、内容回跳到历史滚动位置，
  /// 点击触发重光栅化后暂时恢复）。ListView 逐可视行渲染：所有层都是视口
  /// 量级小层，从根上免疫该类引擎合成异常；行号按同一 ScrollController
  /// 的 offset 当帧直绘，与内容天然同步。选择能力由 SelectionArea 提供。
  ///
  /// 性能设计（9000 行响应曾卡死 UI >30s 的根治）：
  /// - 真凶是整文 TextPainter + 逐位置 getLineBoundary 的 O(n²) 查询。
  ///   软换行不跨文档行（硬换行必是边界），改为逐文档行探测：短 ASCII 行
  ///   用校准字宽直接判一行（等宽字体，精确），长行/非 ASCII 行用单行
  ///   TextPainter 精确排版（与整文排版等价，但查询只在短文本上进行）。
  /// - 超过 [_kAsyncPipelineBytes] 的内容：格式化/注解/highlight 进后台
  ///   isolate（纯 Dart），行计算分块并让出事件循环、渐进追加渲染，
  ///   UI 全程可交互；格式化结果与 highlight 区间不再每次 build 重算。
  Widget _buildVirtualizedTextView(
    ThemeData theme, {
    required bool beautify,
  }) {
    const contentPadding = 12.0;
    final gutterWidth = widget.showLineNumbers ? _lineNumberWidth : 0.0;
    const dividerWidth = 1.0;
    final baseStyle = _viewerCodeStyle(theme);

    return Container(
      color: theme.colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textWidth = constraints.maxWidth -
              gutterWidth -
              (widget.showLineNumbers ? dividerWidth : 0.0) -
              contentPadding * 2;
          final scaler = MediaQuery.textScalerOf(context);
          // 可视行高为当前缩放下的实测值（字体度量取整使 scale() 估算
          // 与真实渲染存在亚像素偏差并逐行累计）
          final scaledRowHeight = _measureViewerLineHeight(scaler);
          final layoutKey = '${theme.brightness}|$beautify|$_annotateEpoch|'
              '${identityHashCode(widget.content)}|${widget.content.length}|'
              '$textWidth|${scaler.scale(1.0)}';
          if (_layoutKey != layoutKey) {
            _layoutKey = layoutKey;
            if (widget.content.length > _kAsyncPipelineBytes) {
              _startAsyncPipeline(
                theme,
                beautify: beautify,
                baseStyle: baseStyle,
                maxWidth: textWidth,
                scaler: scaler,
                defaultTextStyle: DefaultTextStyle.of(context),
              );
            } else {
              _computeSync(
                theme,
                beautify: beautify,
                baseStyle: baseStyle,
                maxWidth: textWidth,
                scaler: scaler,
                defaultTextStyle: DefaultTextStyle.of(context),
              );
            }
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showLineNumbers) ...[
                OffsetGutter(
                  theme: theme,
                  rowDocLines: _rowDocLines,
                  rowHeight: scaledRowHeight,
                  topPadding: contentPadding,
                  listenable: _effectiveScrollController,
                  readOffset: _readScrollOffset,
                  width: _lineNumberWidth,
                  rightPadding: _lineNumberPadding,
                ),
                const AppDivider.vertical(subtle: true),
              ],
              Expanded(
                child: Scrollbar(
                  controller: _effectiveScrollController,
                  child: Stack(
                    children: [
                      SelectionArea(
                        // 行数经 ValueListenableBuilder 驱动重建：
                        // LayoutBuilder 的 builder 在约束不变时不重跑，
                        // 渐进追加的行数必须走普通 build 路径更新
                        child: ValueListenableBuilder<int>(
                          valueListenable: _rowCountNotifier,
                          builder: (context, rowCount, _) {
                            return ListView.builder(
                              controller: _effectiveScrollController,
                              padding: const EdgeInsets.all(contentPadding),
                              itemExtent: scaledRowHeight,
                              itemCount: rowCount,
                              itemBuilder: (context, index) {
                                return Text.rich(
                                  TextSpan(
                                    style: baseStyle,
                                    children: _visualRows[index].spans,
                                  ),
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // 异步管线进度：准备期（isolate）空内容时居中指示，
                      // 行计算期间顶部细条（已有渐进内容可见）
                      if (_preparing && _visualRows.isEmpty)
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_preparing || _rowsComputing)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 同步管线（≤ 阈值的小内容）：单次 build 内完成全部行计算。
  /// 保持既有行为：widgets 测试与小响应走此路径。
  void _computeSync(
    ThemeData theme, {
    required bool beautify,
    required TextStyle baseStyle,
    required double maxWidth,
    required TextScaler scaler,
    required DefaultTextStyle defaultTextStyle,
  }) {
    _pipelineToken++;
    _preparing = false;
    _rowsComputing = false;

    final prepared = _prepareContentSync(theme, beautify, baseStyle);

    final computer = _VisualRowComputer(
      content: prepared,
      intervals: _intervals,
      baseStyle: baseStyle,
      maxWidth: maxWidth,
      scaler: scaler,
      defaultTextStyle: defaultTextStyle,
    );
    final rows = <({int? docLine, List<InlineSpan> spans})>[];
    final rowDocLines = <int?>[];
    while (computer.hasMore) {
      computer.process(100000, rows, rowDocLines);
    }
    _visualRows = rows;
    _rowDocLines = rowDocLines;
    _rowCountNotifier.value = rows.length;
    _scheduleExtentRefresh();
  }

  /// 同步路径的显示内容 + 高亮区间（结果随 layoutKey 失效而重建，
  /// 同一份内容/注解开关/主题下不再重复 format / highlight）
  String _prepareContentSync(
    ThemeData theme,
    bool beautify,
    TextStyle baseStyle,
  ) {
    if (!beautify || !_isJson) {
      _intervals = [
        (start: 0, end: widget.content.length, style: null),
      ];
      return widget.content;
    }
    final key = '${identityHashCode(widget.content)}|${widget.content.length}|'
        '$_annotateEpoch|${theme.brightness}';
    if (_preparedSyncKey != key) {
      var content = _formatContent();
      if (_annotateEpoch) {
        content =
            content.split('\n').map(EpochAnnotation.annotateLine).join('\n');
      }
      _intervals = _flattenSpans(_computeSpans(content, theme, baseStyle));
      _preparedSyncContent = content;
      _preparedSyncKey = key;
    }
    return _preparedSyncContent;
  }

  /// 异步管线（> 阈值的大内容）：准备阶段进 isolate，行计算分块让出
  /// 事件循环并渐进渲染。token 过期（内容/宽度/缩放/主题再变）即丢弃。
  Future<void> _startAsyncPipeline(
    ThemeData theme, {
    required bool beautify,
    required TextStyle baseStyle,
    required double maxWidth,
    required TextScaler scaler,
    required DefaultTextStyle defaultTextStyle,
  }) async {
    final token = ++_pipelineToken;
    _preparing = true;
    _rowsComputing = false;
    _intervals = const [];
    _visualRows = [];
    _rowDocLines = [];
    _rowCountNotifier.value = 0;

    String prepared;
    List<({int start, int end, TextStyle? style})> intervals;
    if (beautify && _isJson) {
      final res = await compute(_prepareFullContentIsolate, {
        'content': widget.content,
        'annotate': _annotateEpoch,
      });
      if (!mounted || token != _pipelineToken) return;
      prepared = res.content;
      final styles = _codeThemeStyles(theme);
      final rootStyle = styles['root'];
      final styleTable = [
        for (final key in res.styleKeys)
          _resolveIntervalStyle(styles, key, rootStyle),
      ];
      intervals = [
        for (final (s, e, k) in res.spans)
          (start: s, end: e, style: k < 0 ? null : styleTable[k]),
      ];
    } else {
      // 原始模式 / 非 JSON：无格式化与高亮，直接进入行计算
      prepared = widget.content;
      intervals = [(start: 0, end: prepared.length, style: null)];
    }
    if (!mounted || token != _pipelineToken) return;

    setState(() {
      _preparing = false;
      _rowsComputing = true;
      _intervals = intervals;
      _visualRows = [];
      _rowDocLines = [];
    });

    final computer = _VisualRowComputer(
      content: prepared,
      intervals: intervals,
      baseStyle: baseStyle,
      maxWidth: maxWidth,
      scaler: scaler,
      defaultTextStyle: defaultTextStyle,
    );
    // 共享同一增长列表：每块处理后通过 _rowCountNotifier 触发渐进渲染，
    // ListView / 行号栏按当时的行数工作
    final rows = _visualRows;
    final rowDocLines = _rowDocLines;
    const chunkLines = 400;
    while (computer.hasMore) {
      computer.process(chunkLines, rows, rowDocLines);
      if (!mounted || token != _pipelineToken) return;
      _rowCountNotifier.value = rows.length;
      _scheduleExtentRefresh();
      if (computer.hasMore) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    if (!mounted || token != _pipelineToken) return;
    setState(() {
      _rowsComputing = false;
    });
    _scheduleExtentRefresh();
  }

  /// isolate 区间的样式还原：key 映射到主题样式并与 root 样式 merge
  ///（与同步路径 _flattenSpans 沿父链 merge 的有效样式对齐）
  TextStyle? _resolveIntervalStyle(
    Map<String, TextStyle> styles,
    String key,
    TextStyle? rootStyle,
  ) {
    final style = styles[key];
    if (style == null) return null;
    if (key == 'root' || rootStyle == null) return style;
    return rootStyle.merge(style);
  }

  /// 把 span 树拍平成 (start, end, style) 区间；style 为沿父链 merge 后
  /// 的有效样式（不含根部 baseStyle，渲染时由行根 span 再叠加）
  List<({int start, int end, TextStyle? style})> _flattenSpans(
    List<InlineSpan> spans,
  ) {
    final out = <({int start, int end, TextStyle? style})>[];
    var offset = 0;

    void walk(InlineSpan span, TextStyle? inherited) {
      if (span is TextSpan) {
        final resolved = span.style == null
            ? inherited
            : (inherited?.merge(span.style!) ?? span.style);
        if (span.text != null && span.text!.isNotEmpty) {
          out.add((
            start: offset,
            end: offset + span.text!.length,
            style: resolved,
          ));
          offset += span.text!.length;
        }
        if (span.children != null) {
          for (final child in span.children!) {
            walk(child, resolved);
          }
        }
      } else {
        // 本查看器不会产生非 TextSpan；按纯文本长度推进保持偏移一致
        offset += span.toPlainText().length;
      }
    }

    for (final span in spans) {
      walk(span, null);
    }
    return out;
  }

  /// 计算高亮 span：JSON 走 highlight 解析，其余按纯文本
  List<InlineSpan> _computeSpans(
    String content,
    ThemeData theme,
    TextStyle baseStyle,
  ) {
    if (!_isJson) {
      return [TextSpan(text: content, style: baseStyle)];
    }
    _ensureJsonHighlightRegistered();
    final result = highlight.parse(content, language: 'json');
    final styles = _codeThemeStyles(theme);
    return _buildHighlightSpans(result.nodes, styles);
  }

  /// 将 highlight 节点树转换为 TextSpan 树；未命中的类名沿父级样式
  List<InlineSpan> _buildHighlightSpans(
    List<Node>? nodes,
    Map<String, TextStyle> styles,
  ) {
    if (nodes == null) return const [];
    return [
      for (final node in nodes)
        TextSpan(
          text: node.children == null ? node.value : null,
          style: node.className != null ? styles[node.className] : null,
          children: node.children == null
              ? null
              : _buildHighlightSpans(node.children, styles),
        ),
    ];
  }

  /// 代码渲染样式：inherit:false + 显式 letterSpacing:0。
  ///
  /// SelectableText 会把样式 merge 到祖先 DefaultTextStyle（M3 bodyMedium
  /// 带 letterSpacing:0.3）上；inherit:false 让 merge 直接返回本样式，
  /// 保证实际渲染宽度与行号栏 TextPainter / 分块宽度测算完全一致。
  TextStyle _viewerCodeStyle(ThemeData theme, {Color? color}) =>
      AppTextStyles.code12.copyWith(
        height: 1.5,
        inherit: false,
        color: color ?? theme.colorScheme.onSurface,
        letterSpacing: 0,
        leadingDistribution: TextLeadingDistribution.even,
        textBaseline: TextBaseline.alphabetic,
      );

  /// 构建语法高亮样式表（className → 颜色样式；字号字体继承 code12）
  Map<String, TextStyle> _codeThemeStyles(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    // Light theme colors (优化后的配色)
    final lightTheme = {
      'root': TextStyle(
        color: theme.colorScheme.onSurface,
        backgroundColor: theme.colorScheme.surface,
      ),
      'key': TextStyle(
        color: AppSyntaxColors.key,
        fontWeight: FontWeight.w600,
      ),
      'string': TextStyle(color: AppSyntaxColors.string),
      'number': TextStyle(color: AppSyntaxColors.number),
      'literal': TextStyle(color: AppSyntaxColors.number),
      'boolean': TextStyle(color: AppSyntaxColors.keyword),
      'null': TextStyle(color: AppSyntaxColors.keyword),
      'property': TextStyle(
        color: AppSyntaxColors.key,
        fontWeight: FontWeight.w600,
      ),
      'punctuation': TextStyle(color: AppSyntaxColors.punctuation),
      'comment': TextStyle(
        color: AppSyntaxColors.punctuation,
        fontStyle: FontStyle.italic,
      ),
    };

    // Dark theme colors (优化后的配色)
    final darkTheme = {
      'root': TextStyle(
        color: theme.colorScheme.onSurface,
        backgroundColor: theme.colorScheme.surface,
      ),
      'key': TextStyle(
        color: AppSyntaxColors.getKey(true),
        fontWeight: FontWeight.w600,
      ),
      'string': TextStyle(color: AppSyntaxColors.getString(true)),
      'number': TextStyle(color: AppSyntaxColors.getNumber(true)),
      'literal': TextStyle(color: AppSyntaxColors.getNumber(true)),
      'boolean': TextStyle(color: AppSyntaxColors.getKeyword(true)),
      'null': TextStyle(color: AppSyntaxColors.getKeyword(true)),
      'property': TextStyle(
        color: AppSyntaxColors.getKey(true),
        fontWeight: FontWeight.w600,
      ),
      'punctuation': TextStyle(color: AppSyntaxColors.getPunctuation(true)),
      'comment': TextStyle(
        color: AppSyntaxColors.getPunctuation(true),
        fontStyle: FontStyle.italic,
      ),
    };

    return isDark ? darkTheme : lightTheme;
  }

  /// 格式化大小
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// 逐文档行可视行计算器（完整/原始模式共用）。
///
/// 软换行不跨文档行（硬换行必是可视行边界），因此整文排版的逐位置
/// getLineBoundary 查询（O(n²)，9000 行实测 126s）可以等价替换为：
/// - 纯 ASCII 短行：等宽字体下用校准字宽直接判定单行不折行（精确）；
/// - 长行 / 含非 ASCII 字符行：单行 TextPainter 精确排版取折行点——
///   排版参数与渲染同参，单行排版结果与整文中该行段落完全一致，
///   但所有查询都在短文本上进行（O(行长) 而非 O(全文)）。
class _VisualRowComputer {
  _VisualRowComputer({
    required this.content,
    required this.intervals,
    required this.baseStyle,
    required this.maxWidth,
    required this.scaler,
    required this.defaultTextStyle,
  });

  final String content;
  final List<({int start, int end, TextStyle? style})> intervals;
  final TextStyle baseStyle;
  final double maxWidth;
  final TextScaler scaler;
  final DefaultTextStyle defaultTextStyle;

  late final List<String> _docLines = content.split('\n');
  int _nextLine = 0;
  int _lineStart = 0; // _nextLine 在 content 中的起始偏移
  int _cursor = 0; // 全局区间游标（按文档序单调推进）
  double _asciiAdvance = -1;

  bool get hasMore => _nextLine < _docLines.length;

  /// 处理最多 [maxLines] 个文档行，把产生的可视行追加到 [out] / [docOut]
  void process(
    int maxLines,
    List<({int? docLine, List<InlineSpan> spans})> out,
    List<int?> docOut,
  ) {
    final stop = (_nextLine + maxLines).clamp(0, _docLines.length);
    while (_nextLine < stop) {
      final line = _docLines[_nextLine];
      _appendLine(line, _lineStart, out, docOut);
      _lineStart += line.length + 1; // 含 '\n'
      _nextLine++;
    }
  }

  /// 是否纯可打印 ASCII（无 tab 等控制字符）：等宽字体下字宽精确可知
  bool _isSimpleAscii(String line) {
    for (var i = 0; i < line.length; i++) {
      final c = line.codeUnitAt(i);
      if (c < 0x20 || c > 0x7E) return false;
    }
    return true;
  }

  /// 校准 ASCII 字宽（与渲染同参的 TextPainter 实测；等宽字体各字同宽）
  double _advance() {
    if (_asciiAdvance < 0) {
      final painter = TextPainter(
        text: TextSpan(text: '0' * 100, style: baseStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        strutStyle: const StrutStyle(),
        textHeightBehavior: defaultTextStyle.textHeightBehavior,
        textWidthBasis: defaultTextStyle.textWidthBasis,
      )..layout();
      _asciiAdvance = painter.width / 100;
      painter.dispose();
    }
    return _asciiAdvance;
  }

  /// 取 [start, end)（content 全局偏移）覆盖的区间，转为相对 start 的
  /// 局部区间返回；全局游标随之推进（调用必须按文档序单调）
  List<({int start, int end, TextStyle? style})> _takeIntervals(
    int start,
    int end,
  ) {
    final out = <({int start, int end, TextStyle? style})>[];
    while (_cursor < intervals.length && intervals[_cursor].end <= start) {
      _cursor++;
    }
    var j = _cursor;
    while (j < intervals.length && intervals[j].start < end) {
      final iv = intervals[j];
      final s = iv.start > start ? iv.start : start;
      final e = iv.end < end ? iv.end : end;
      out.add((start: s - start, end: e - start, style: iv.style));
      j++;
    }
    return out;
  }

  List<InlineSpan> _spansFromLocal(
    int lineStart,
    List<({int start, int end, TextStyle? style})> local,
    int from,
    int to,
  ) {
    final spans = <InlineSpan>[];
    var j = 0;
    while (j < local.length && local[j].end <= from) {
      j++;
    }
    while (j < local.length && local[j].start < to) {
      final iv = local[j];
      final s = iv.start > from ? iv.start : from;
      final e = iv.end < to ? iv.end : to;
      spans.add(TextSpan(
        text: content.substring(lineStart + s, lineStart + e),
        style: iv.style,
      ));
      j++;
    }
    return spans;
  }

  static final List<InlineSpan> _blankRow = [const TextSpan(text: ' ')];

  void _appendLine(
    String line,
    int lineStart,
    List<({int? docLine, List<InlineSpan> spans})> out,
    List<int?> docOut,
  ) {
    final docNumber = _nextLine + 1;
    if (line.isEmpty) {
      out.add((docLine: docNumber, spans: _blankRow));
      docOut.add(docNumber);
      return;
    }
    // 快路径：纯 ASCII 且按校准字宽必然不折行（留 0.5px 余量，边界情形
    // 一律落到精确路径）
    if (_isSimpleAscii(line) && line.length * _advance() < maxWidth - 0.5) {
      final local = _takeIntervals(lineStart, lineStart + line.length);
      final spans = _spansFromLocal(lineStart, local, 0, line.length);
      out.add((
        docLine: docNumber,
        spans: spans.isEmpty ? [TextSpan(text: line)] : spans,
      ));
      docOut.add(docNumber);
      return;
    }
    // 精确路径：单行 TextPainter 排版取折行点
    final local = _takeIntervals(lineStart, lineStart + line.length);
    final painter = TextPainter(
      text: TextSpan(
        style: baseStyle,
        children: [
          for (final iv in local)
            TextSpan(
              text: content.substring(lineStart + iv.start, lineStart + iv.end),
              style: iv.style,
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      strutStyle: const StrutStyle(),
      textHeightBehavior: defaultTextStyle.textHeightBehavior,
      textWidthBasis: defaultTextStyle.textWidthBasis,
    )..layout(maxWidth: maxWidth);

    var pos = 0;
    var first = true;
    while (pos < line.length) {
      final boundary = painter.getLineBoundary(TextPosition(offset: pos));
      final end = boundary.end.clamp(pos + 1, line.length);
      final spans = _spansFromLocal(lineStart, local, pos, end);
      out.add((
        docLine: first ? docNumber : null,
        spans: spans.isEmpty
            ? [
                TextSpan(
                    text: content.substring(lineStart + pos, lineStart + end))
              ]
            : spans,
      ));
      docOut.add(first ? docNumber : null);
      first = false;
      pos = end;
    }
    painter.dispose();
  }
}

/// 大响应警告组件
class LargeResponseWarning extends StatelessWidget {
  const LargeResponseWarning({
    super.key,
    required this.size,
    required this.onContinue,
    required this.onCancel,
  });

  final int size;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizeText = _formatSize(size);

    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.appTheme.background,
          borderRadius: AppMetrics.br8,
          border: Border.all(color: context.appTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber,
              size: 48,
              color: context.appTheme.warning,
            ),
            const SizedBox(height: 16),
            Text(
              L10nBridge.t.viewer_largeResponseTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L10nBridge.t.viewer_largeResponseBody(sizeText),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton.secondary(
                  onPressed: onCancel,
                  label: L10nBridge.t.viewer_viewFull,
                ),
                const SizedBox(width: 12),
                AppButton.primary(
                  onPressed: onContinue,
                  label: L10nBridge.t.viewer_performanceMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
