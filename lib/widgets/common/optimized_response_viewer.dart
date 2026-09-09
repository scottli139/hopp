import 'dart:convert';

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

/// JSON 语法高亮注册（highlight 全局单例只需注册一次）
bool _jsonHighlightRegistered = false;
void _ensureJsonHighlightRegistered() {
  if (_jsonHighlightRegistered) return;
  highlight.registerLanguage('json', json);
  _jsonHighlightRegistered = true;
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
  final ScrollController _lineNumberScrollController = ScrollController();

  // 完整模式语法高亮 span 缓存（随内容/主题变化重建）
  String _spanCacheKey = '';
  List<InlineSpan>? _cachedSpans;

  /// 主内容滚动控制器：外部传入优先，否则用内部控制器
  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _scrollController;

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
    _scrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  /// 初始化内容
  void _initializeContent() {
    _lines = widget.content.split('\n');
    _isJson = _detectJson();

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
  }

  /// 显示所有行
  void _showAllLinesNow() {
    setState(() {
      _displayedLines = _lines.length;
      _showAllLines = true;
    });
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
        return _buildFullView(theme);
      case ResponseDisplayMode.raw:
        return _buildRawView(theme);
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
              // 等宽字体：ASCII 占 1 单元，CJK 等宽字符占 2 单元
              final maxUnits = ((constraints.maxWidth - gutterWidth - 24) / 7.2)
                  .floor()
                  .clamp(20, 100000);
              final chunks = <({String text, int? docLine})>[
                for (var i = 0; i < displayLines.length; i++)
                  ..._chunkLine(displayLines[i], i, maxUnits),
              ];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 行号区域
                  if (widget.showLineNumbers)
                    _buildLineNumberArea(
                      theme,
                      chunks.map((c) => c.docLine).toList(),
                      rowHeight: 22,
                    ),
                  // 分割线
                  if (widget.showLineNumbers)
                    const AppDivider.vertical(subtle: true),
                  // 代码区域
                  Expanded(
                    child: Scrollbar(
                      controller: _effectiveScrollController,
                      child: ListView.builder(
                        controller: _effectiveScrollController,
                        // 与行号栏 top/bottom padding 对齐，保证行号与条目同一起点
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  /// 构建行号区域（docLine 为 null 的行是续行，不显示行号）
  ///
  /// [rowHeight] 必须与内容区的行高完全一致（性能模式条目 = 18 文本 +
  /// 上下各 2 padding = 22；原始模式 = 18），否则行号逐行漂移
  Widget _buildLineNumberArea(
    ThemeData theme,
    List<int?> docLines, {
    required double rowHeight,
  }) {
    return Container(
      width: _lineNumberWidth,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.only(
        right: _lineNumberPadding,
        top: 12,
        bottom: 12,
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
        ),
        child: SingleChildScrollView(
          controller: _lineNumberScrollController,
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              for (final n in docLines)
                Text(
                  n == null ? '' : '$n',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.code11.copyWith(
                    height: rowHeight / 11,
                    inherit: false,
                    letterSpacing: 0,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建单行显示
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
          child: SelectableText.rich(
            TextSpan(children: spans),
            style: _viewerCodeStyle(theme),
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
      // 软换行：行宽超过视口的大文本层会命中 Windows 高分屏滚动光栅化异常
      child: SelectableText(line.isEmpty ? ' ' : line, // 保持空行高度
          style: _viewerCodeStyle(
            theme,
            color: isJsonLine ? _getJsonLineColor(line, theme) : null,
          )),
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

  /// 完整模式视图（highlight 语法高亮 + SelectableText 渲染 + 软换行）
  ///
  /// 约束：文本宽度必须 ≤ 视口宽（软换行），不能有横向溢出。实测（用户
  /// 三段录屏 + 本机复现）：Windows 150% 缩放下，宽度超过视口的大文本层
  /// 在滚动重绘后会被引擎按错误比例光栅化（字形放大约 1.5–2 倍、行距变大、
  /// 行内容横向错位），点击强制重建图片后恢复、再次滚动又复发；行号栏等
  /// 窄层不受影响。软换行后文本层宽度恒等于视口宽，免疫该引擎异常。
  Widget _buildFullView(ThemeData theme) {
    // 注解仅注入显示文本，原始报文与 Copy 不受影响（F8.5）
    var content = _formatContent();
    if (_isJson && _annotateEpoch) {
      content =
          content.split('\n').map(EpochAnnotation.annotateLine).join('\n');
    }
    final baseStyle = _viewerCodeStyle(theme);
    final lines = content.split('\n');

    final cacheKey = '${theme.brightness}|$content';
    if (_cachedSpans == null || _spanCacheKey != cacheKey) {
      _cachedSpans = _computeSpans(content, theme, baseStyle);
      _spanCacheKey = cacheKey;
    }

    const contentPadding = 12.0;
    final gutterWidth = widget.showLineNumbers ? _lineNumberWidth : 0.0;
    const dividerWidth = 1.0;

    return Container(
      color: theme.colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textWidth = constraints.maxWidth -
              gutterWidth -
              (widget.showLineNumbers ? dividerWidth : 0.0) -
              contentPadding * 2;
          // 用与渲染一致的 TextPainter 计算各文档行首条可视行的位置，
          // 行号才能与软换行后的正文逐行对齐
          final gutterLayout = widget.showLineNumbers
              ? _computeDocLineLayout(content, baseStyle, textWidth,
                  MediaQuery.textScalerOf(context), DefaultTextStyle.of(context))
              : null;

          // 行号与正文放在同一个垂直滚动视图里，保证二者始终同步滚动
          return SingleChildScrollView(
            controller: _effectiveScrollController,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showLineNumbers) ...[
                  _buildWrapAwareGutter(
                      theme, lines.length, gutterLayout!, contentPadding),
                  const AppDivider.vertical(subtle: true),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(contentPadding),
                    child: SelectableText.rich(
                      TextSpan(style: baseStyle, children: _cachedSpans),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

  /// 计算每个文档行首条可视行相对段落顶部的 top 及段落总高（与渲染同一份
  /// span/宽度）
  ({List<double> tops, double height}) _computeDocLineLayout(
    String content,
    TextStyle baseStyle,
    double maxWidth,
    TextScaler scaler,
    DefaultTextStyle defaultTextStyle,
  ) {
    // 与 SelectableText → EditableText 的实际排版参数逐项对齐：
    // strutStyle 是 SelectableText 的固定默认值，textHeightBehavior /
    // textWidthBasis 继承自 DefaultTextStyle
    final painter = TextPainter(
      text: TextSpan(style: baseStyle, children: _cachedSpans),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      strutStyle: const StrutStyle(),
      textHeightBehavior: defaultTextStyle.textHeightBehavior,
      textWidthBasis: defaultTextStyle.textWidthBasis,
    )..layout(maxWidth: maxWidth);

    final tops = <double>[];
    var charOffset = 0;
    for (final line in content.split('\n')) {
      // caret 偏移的 dy 即该字符所在可视行的 top
      tops.add(
        painter
            .getOffsetForCaret(TextPosition(offset: charOffset), Rect.zero)
            .dy,
      );
      charOffset += line.length + 1;
    }
    return (tops: tops, height: painter.height);
  }

  /// 软换行感知行号栏：每个行号按文档行首条可视行的 top 精确定位
  Widget _buildWrapAwareGutter(
    ThemeData theme,
    int docLineCount,
    ({List<double> tops, double height}) layout,
    double contentPadding,
  ) {
    final gutterStyle = AppTextStyles.code11.copyWith(
      height: 1.5 * 12 / 11,
      inherit: false,
      letterSpacing: 0,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );
    // 行号行高与正文行高一致（18），小号字形取行高差的一半做垂直居中
    const lineHeight = 12 * 1.5;
    final numberOffset = (lineHeight - 11 * (1.5 * 12 / 11)) / 2;

    return Container(
      width: _lineNumberWidth,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.only(right: _lineNumberPadding),
      child: SizedBox(
        height: layout.height + contentPadding * 2,
        child: Stack(
          children: [
            for (var i = 1; i <= docLineCount; i++)
              Positioned(
                top: layout.tops[i - 1] + contentPadding + numberOffset,
                right: 0,
                child: Text('$i', style: gutterStyle),
              ),
          ],
        ),
      ),
    );
  }

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

  /// 原始文本视图
  Widget _buildRawView(ThemeData theme) {
    return widget.showLineNumbers
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 行号区域
              _buildLineNumberArea(
                theme,
                [for (var i = 1; i <= _lines.length; i++) i],
                rowHeight: 18,
              ),
              // 分割线
              const AppDivider.vertical(subtle: true),
              // 代码区域
              Expanded(
                child: SingleChildScrollView(
                  controller: _effectiveScrollController,
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    widget.content,
                    style: _viewerCodeStyle(theme),
                  ),
                ),
              ),
            ],
          )
        : SingleChildScrollView(
            controller: _effectiveScrollController,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.content,
              style: AppTextStyles.code12.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
          );
  }

  /// 格式化大小
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
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
