import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/htmlbars.dart';
import 'package:highlight/languages/javascript.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_syntax_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_logger.dart';
import 'app_divider.dart';
import 'offset_gutter.dart';

/// Supported language modes for syntax highlighting
enum CodeLanguage {
  json,
  text,
  xml,
  html,
  javascript,
}

/// A code editor widget with syntax highlighting support
class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({
    super.key,
    required this.code,
    this.onChanged,
    this.language = CodeLanguage.json,
    this.readOnly = false,
    this.minLines,
    this.maxLines,
    this.expands = false,
    this.showLineNumbers = true,
    this.controller,
    this.focusNode,
  });

  final String code;
  final ValueChanged<String>? onChanged;
  final CodeLanguage language;
  final bool readOnly;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final bool showLineNumbers;

  /// 外部持有的控制器（如 Body 编辑器的 fx 变量插入需要操作光标）。
  /// 传入后由调用方负责 dispose，[onChanged] 仍会随文本变化回调。
  final CodeController? controller;

  /// 外部焦点节点（配合外部 controller 做插入后回焦）
  final FocusNode? focusNode;

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

/// 语言枚举 → highlight Mode 映射（供外部创建 CodeController 时复用）
Mode? codeLanguageMode(CodeLanguage language) {
  switch (language) {
    case CodeLanguage.json:
      return json;
    case CodeLanguage.xml:
      return xml;
    case CodeLanguage.html:
      return htmlbars;
    case CodeLanguage.javascript:
      return javascript;
    case CodeLanguage.text:
      return null;
  }
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
  static const double _lineNumberWidth = 40.0;
  static const double _lineNumberPadding = 8.0;

  late CodeController _controller;
  late final bool _ownsController;

  /// 代码区垂直滚动 offset（由包在 CodeField 外的 ScrollNotification 喂入，
  /// 驱动行号栏当帧直绘；CodeField 的滚动控制器在其内部，无法直接持有）
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);

  /// 行号栏几何基准（直接从 RenderEditable 实测，见 _scheduleGutterMeasure）。
  /// 未实测前用常量兜底：首行 top 16（包内 contentPadding）+ painter 行高
  final GlobalKey _gutterKey = GlobalKey();
  double? _gutterTopPad;
  double? _gutterRowHeight;
  bool _gutterMeasureScheduled = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        CodeController(
          text: widget.code,
          language: codeLanguageMode(widget.language),
        );
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text if code changes from outside
    if (widget.code != _controller.text && !widget.readOnly) {
      _controller.text = widget.code;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _scrollOffset.dispose();
    // 外部传入的 controller 由调用方持有dispose
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.showLineNumbers) _scheduleGutterMeasure();

    return widget.showLineNumbers
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLineNumberArea(theme),
              const AppDivider.vertical(subtle: true),
              Expanded(child: _buildCodeField(theme)),
            ],
          )
        : _buildCodeField(theme);
  }

  /// 后帧从 CodeField 内的 RenderEditable 实测行号栏几何基准：
  /// 首行在滚动内容坐标系中的 top（caret rect + 滚动 offset）与行高
  /// （次行 caret top 差）。padding/字体度量的任何假设都不需要——
  /// 实测值与屏幕所见构造性一致（用户截图反馈：uiScale 80/90% 下行号
  /// 与内容恒定错位 2-4 逻辑像素，常量假设在低缩放档位失效）
  void _scheduleGutterMeasure() {
    if (_gutterMeasureScheduled) return;
    _gutterMeasureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gutterMeasureScheduled = false;
      if (!mounted) return;
      final measured = _measureGutterBase();
      if (measured == null) return;
      final (topPad, rowHeight) = measured;
      if (topPad == _gutterTopPad && rowHeight == _gutterRowHeight) return;
      setState(() {
        _gutterTopPad = topPad;
        _gutterRowHeight = rowHeight;
      });
    });
  }

  /// 实测首行 top（gutter 坐标系、未滚动内容坐标）与行高；失败返回 null
  (double, double)? _measureGutterBase() {
    RenderEditable? editable;
    void visit(RenderObject o) {
      if (editable != null) return;
      if (o is RenderEditable) {
        editable = o;
        return;
      }
      o.visitChildren(visit);
    }

    final root = context.findRenderObject();
    final gutterBox =
        _gutterKey.currentContext?.findRenderObject() as RenderBox?;
    if (root == null || gutterBox == null || !gutterBox.hasSize) return null;
    visit(root);
    final ro = editable;
    if (ro == null || ro.text == null) return null;
    final plain = ro.text!.toPlainText();
    if (plain.isEmpty) return null;

    // caret rect 处于 RenderEditable 本地坐标（随内部滚动平移）；
    // 加回滚动 offset 得到未滚动内容坐标，再换算到 gutter 坐标系
    final r0 = ro.getLocalRectForCaret(const TextPosition(offset: 0));
    final contentTopInGutter = ro.localToGlobal(Offset(0, r0.top)).dy +
        _scrollOffset.value -
        gutterBox.localToGlobal(Offset.zero).dy;

    var rowHeight = _measureCodeLineHeight(MediaQuery.textScalerOf(context));
    final firstNewline = plain.indexOf('\n');
    if (firstNewline >= 0 && firstNewline + 1 < plain.length) {
      final r1 =
          ro.getLocalRectForCaret(TextPosition(offset: firstNewline + 1));
      final h = r1.top - r0.top;
      if (h > 1) rowHeight = h;
    }
    return (contentTopInGutter, rowHeight);
  }

  /// 行号栏：视口高小层，按代码区滚动 offset 当帧直绘可见行号。
  ///
  /// 旧实现是 NeverScrollableScrollPhysics 的静态行号列——内容滚动后
  /// 行号冻结在顶部（Issue #4）；超高校正层还会命中 Windows 分数 DPI
  /// 的引擎合成异常。改为与响应查看器同一套 OffsetGutter：滚动位置由
  /// 包在 CodeField 外的 ScrollNotification 当帧喂入，同步无延迟。
  Widget _buildLineNumberArea(ThemeData theme) {
    final lineCount = widget.code.split('\n').length;
    final scaler = MediaQuery.textScalerOf(context);

    return OffsetGutter(
      key: _gutterKey,
      theme: theme,
      rowDocLines: [for (var i = 1; i <= lineCount; i++) i],
      rowHeight: _gutterRowHeight ?? _measureCodeLineHeight(scaler),
      // 兜底 16 = 包内 InputDecoration contentPadding；实测后由
      // RenderEditable caret 位置取代（见 _measureGutterBase）
      topPadding: _gutterTopPad ?? 16,
      listenable: _scrollOffset,
      readOffset: () => _scrollOffset.value,
      width: _lineNumberWidth,
      rightPadding: _lineNumberPadding,
    );
  }

  /// 与 CodeField 文本同参的行高实测
  double _measureCodeLineHeight(TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'A',
        style: AppTextStyles.code12.copyWith(height: 1.5),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      strutStyle: const StrutStyle(),
    )..layout();
    return painter.height;
  }

  Widget _buildCodeField(ThemeData theme) {
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      child: CodeTheme(
        data: _buildCodeTheme(theme),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical) {
              _scrollOffset.value = notification.metrics.pixels;
            }
            return false;
          },
          child: CodeField(
            controller: _controller,
            focusNode: widget.focusNode,
            readOnly: widget.readOnly,
            expands: widget.expands,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            gutterStyle: GutterStyle.none,
            textStyle: AppTextStyles.code12.copyWith(height: 1.5),
          ),
        ),
      ),
    );
  }

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

    return CodeThemeData(styles: isDark ? darkTheme : lightTheme);
  }
}

/// A simpler fallback editor that uses TextField with basic formatting
class SimpleCodeEditor extends StatelessWidget {
  const SimpleCodeEditor({
    super.key,
    required this.code,
    required this.onChanged,
    this.language = CodeLanguage.json,
    this.readOnly = false,
    this.expands = false,
  });

  final String code;
  final ValueChanged<String> onChanged;
  final CodeLanguage language;
  final bool readOnly;
  final bool expands;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          // 左侧不显示边框
          left: BorderSide.none,
        ),
        borderRadius: AppMetrics.br4,
      ),
      child: TextField(
        controller: TextEditingController(text: code),
        readOnly: readOnly,
        maxLines: expands ? null : 10,
        expands: expands,
        decoration: InputDecoration(
          hintText: _getHintText(context),
          contentPadding: const EdgeInsets.all(12),
          border: InputBorder.none,
        ),
        style: AppTextStyles.code12.copyWith(height: 1.5),
        onChanged: onChanged,
      ),
    );
  }

  String _getHintText(BuildContext context) {
    switch (language) {
      case CodeLanguage.json:
        return '{\n  "key": "value"\n}';
      case CodeLanguage.xml:
        return '<?xml version="1.0"?>\n<root></root>';
      case CodeLanguage.html:
        return '<html>\n  <body></body>\n</html>';
      case CodeLanguage.javascript:
        return 'function example() {\n  return "Hello";\n}';
      case CodeLanguage.text:
        return context.l10n.editor_enterText;
    }
  }
}

/// Extension to format JSON with proper indentation
extension JsonFormatter on String {
  String formatJson() {
    try {
      // This is a placeholder - in a real app you'd use dart:convert
      // to parse and re-serialize with indentation
      return this;
    } catch (e) {
      AppLogger.debug('[JsonFormatter] Failed to format JSON: $e');
      return this;
    }
  }
}
