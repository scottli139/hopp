import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/json.dart';

import '../../theme/app_metrics.dart';
import '../../theme/app_syntax_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../../utils/app_logger.dart';
import 'app_button.dart';
import 'app_divider.dart';

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

  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();

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
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
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
          const SnackBar(
            content: Text('Code beautified'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stack) {
      logError('[OptimizedResponseViewer] Beautify failed', e, stack);

      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to beautify code'),
            duration: Duration(seconds: 2),
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
            '$sizeText • ${_lines.length} lines',
            style: AppTextStyles.tiny11.copyWith(
              color: context.appTheme.textSecondary,
            ),
          ),
          const Spacer(),
          // 显示模式选择（始终显示，方便用户切换）
          _buildModeSelector(theme),
          const SizedBox(width: 8),
          // Beautify 按钮
          if (widget.showBeautifyButton && _isJson)
            _buildToolbarButton(
              icon: Icons.format_align_left,
              tooltip: 'Beautify',
              onPressed: _beautifyCode,
              theme: theme,
            ),
          if (widget.showBeautifyButton && _isJson) const SizedBox(width: 8),
          // 复制按钮
          _buildToolbarButton(
            icon: Icons.copy,
            tooltip: 'Copy',
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
            label: 'Performance',
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
            label: 'Full',
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : null,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: AppMetrics.br4,
              border: Border.all(
                color: context.appTheme.border.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              icon,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
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

  /// 性能模式视图（虚拟化列表）
  Widget _buildPerformanceView(ThemeData theme) {
    final displayLines =
        _showAllLines ? _lines : _lines.sublist(0, _displayedLines);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 行号区域
              if (widget.showLineNumbers)
                _buildLineNumberArea(theme, displayLines.length),
              // 分割线
              if (widget.showLineNumbers)
                const AppDivider.vertical(subtle: true),
              // 代码区域
              Expanded(
                child: Scrollbar(
                  controller: _effectiveScrollController,
                  child: ListView.builder(
                    controller: _effectiveScrollController,
                    itemCount: displayLines.length,
                    itemBuilder: (context, index) {
                      return _buildLineItem(
                        displayLines[index],
                        index,
                        theme,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // 加载更多按钮
        if (!_showAllLines && _lines.length > _displayedLines)
          _buildLoadMoreBar(theme),
      ],
    );
  }

  /// 构建行号区域
  Widget _buildLineNumberArea(ThemeData theme, int lineCount) {
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
            children: List.generate(lineCount, (index) {
              return Text(
                '${index + 1}',
                textAlign: TextAlign.right,
                style: AppTextStyles.code12.copyWith(
                  fontSize: 11,
                  height: 1.5,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// 构建单行显示
  Widget _buildLineItem(String line, int index, ThemeData theme) {
    // 简单的 JSON 语法高亮（性能模式下轻量级实现）
    final isJsonLine = _isJson && _shouldHighlightLine(line);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: SelectableText(line.isEmpty ? ' ' : line, // 保持空行高度
          style: AppTextStyles.code12.copyWith(
            height: 1.5,
            color: isJsonLine ? _getJsonLineColor(line, theme) : null,
          )),
    );
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
            'Showing $_displayedLines of ${_lines.length} lines',
            style: AppTextStyles.caption12.copyWith(
              color: context.appTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          AppButton.secondary(
            onPressed: _showMoreLines,
            label: 'Load $remaining more',
          ),
          const SizedBox(width: 8),
          AppButton.ghost(
            onPressed: _showAllLinesNow,
            label: 'Load all',
          ),
        ],
      ),
    );
  }

  /// 完整模式视图（使用 CodeEditor 提供语法高亮）
  Widget _buildFullView(ThemeData theme) {
    // 使用 CodeField 提供 JSON 语法高亮
    final controller = CodeController(
      text: _formatContent(),
      language: _isJson ? json : null,
    );
    final content = _formatContent();
    final lines = content.split('\n');

    return widget.showLineNumbers
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 行号区域
              _buildLineNumberArea(theme, lines.length),
              // 分割线
              const AppDivider.vertical(subtle: true),
              // 代码区域
              Expanded(
                child: SingleChildScrollView(
                  controller: _effectiveScrollController,
                  child: Theme(
                    data: theme.copyWith(
                      inputDecorationTheme: const InputDecorationTheme(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    child: CodeTheme(
                      data: _buildCodeTheme(theme),
                      child: CodeField(
                        controller: controller,
                        readOnly: true,
                        gutterStyle: GutterStyle.none,
                        textStyle: AppTextStyles.code12.copyWith(height: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : SingleChildScrollView(
            controller: _effectiveScrollController,
            padding: const EdgeInsets.all(12),
            child: Theme(
              data: theme.copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              child: CodeTheme(
                data: _buildCodeTheme(theme),
                child: CodeField(
                  controller: controller,
                  readOnly: true,
                  textStyle: AppTextStyles.code12.copyWith(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          );
  }

  /// 构建代码主题
  CodeThemeData _buildCodeTheme(ThemeData theme) {
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
        color: Colors.grey.shade500,
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
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    };

    return CodeThemeData(styles: isDark ? darkTheme : lightTheme);
  }

  /// 原始文本视图
  Widget _buildRawView(ThemeData theme) {
    return widget.showLineNumbers
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 行号区域
              _buildLineNumberArea(theme, _lines.length),
              // 分割线
              const AppDivider.vertical(subtle: true),
              // 代码区域
              Expanded(
                child: SingleChildScrollView(
                  controller: _effectiveScrollController,
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    widget.content,
                    style: AppTextStyles.code12.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
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
                fontSize: 13,
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
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Large Response',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This response is $sizeText which may cause performance issues. '
              'Would you like to view it in performance mode?',
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
                  label: 'View Full',
                ),
                const SizedBox(width: 12),
                AppButton.primary(
                  onPressed: onContinue,
                  label: 'Performance Mode',
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
