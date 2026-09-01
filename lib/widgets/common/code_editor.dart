import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/htmlbars.dart';
import 'package:highlight/languages/javascript.dart';

import '../../theme/app_metrics.dart';
import '../../theme/app_syntax_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_logger.dart';
import 'app_divider.dart';

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

  Widget _buildLineNumberArea(ThemeData theme) {
    final lineCount = widget.code.split('\n').length;

    return Container(
      width: _lineNumberWidth,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.only(
        right: _lineNumberPadding,
        top: 12,
        bottom: 12,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: List.generate(lineCount, (index) {
            return Text(
              '${index + 1}',
              textAlign: TextAlign.right,
              style: AppTextStyles.code11.copyWith(
                height: 1.5,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            );
          }),
        ),
      ),
    );
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
          hintText: _getHintText(),
          contentPadding: const EdgeInsets.all(12),
          border: InputBorder.none,
        ),
        style: AppTextStyles.code12.copyWith(height: 1.5),
        onChanged: onChanged,
      ),
    );
  }

  String _getHintText() {
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
        return 'Enter text...';
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
