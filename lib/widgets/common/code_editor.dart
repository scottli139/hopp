import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/htmlbars.dart';
import 'package:highlight/languages/javascript.dart';

import '../../utils/app_logger.dart';

/// 语法高亮配色 (与 OptimizedResponseViewer 保持一致)
class _JsonSyntaxColors {
  static const key = Color(0xFF1E40AF);
  static const string = Color(0xFF15803D);
  static const number = Color(0xFF2563EB);
  static const keyword = Color(0xFF7C3AED);
  static const punctuation = Color(0xFF6B7280);

  static Color getKey(bool isDark) => isDark ? const Color(0xFF93C5FD) : key;
  static Color getString(bool isDark) =>
      isDark ? const Color(0xFF86EFAC) : string;
  static Color getNumber(bool isDark) =>
      isDark ? const Color(0xFF60A5FA) : number;
  static Color getKeyword(bool isDark) =>
      isDark ? const Color(0xFFC4B5FD) : keyword;
  static Color getPunctuation(bool isDark) =>
      isDark ? const Color(0xFF9CA3AF) : punctuation;
}

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
  });

  final String code;
  final ValueChanged<String>? onChanged;
  final CodeLanguage language;
  final bool readOnly;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final bool showLineNumbers;

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
  static const double _lineNumberWidth = 40.0;
  static const double _lineNumberPadding = 8.0;

  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.code,
      language: _getLanguageMode(),
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
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
  }

  Mode? _getLanguageMode() {
    switch (widget.language) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return widget.showLineNumbers
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLineNumberArea(theme),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
              Expanded(child: _buildCodeField(theme)),
            ],
          )
        : _buildCodeField(theme);
  }

  Widget _buildLineNumberArea(ThemeData theme) {
    final lineCount = widget.code.split('\n').length;

    return Container(
      width: _lineNumberWidth,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
              style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 11,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
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
          readOnly: widget.readOnly,
          expands: widget.expands,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          gutterStyle: GutterStyle.none,
          textStyle: const TextStyle(
            fontFamily: 'Menlo',
            fontSize: 12,
            height: 1.5,
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
        color: _JsonSyntaxColors.key,
        fontWeight: FontWeight.w600,
      ),
      'string': TextStyle(color: _JsonSyntaxColors.string),
      'number': TextStyle(color: _JsonSyntaxColors.number),
      'literal': TextStyle(color: _JsonSyntaxColors.number),
      'boolean': TextStyle(color: _JsonSyntaxColors.keyword),
      'null': TextStyle(color: _JsonSyntaxColors.keyword),
      'property': TextStyle(
        color: _JsonSyntaxColors.key,
        fontWeight: FontWeight.w600,
      ),
      'punctuation': TextStyle(color: _JsonSyntaxColors.punctuation),
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
        color: _JsonSyntaxColors.getKey(true),
        fontWeight: FontWeight.w600,
      ),
      'string': TextStyle(color: _JsonSyntaxColors.getString(true)),
      'number': TextStyle(color: _JsonSyntaxColors.getNumber(true)),
      'literal': TextStyle(color: _JsonSyntaxColors.getNumber(true)),
      'boolean': TextStyle(color: _JsonSyntaxColors.getKeyword(true)),
      'null': TextStyle(color: _JsonSyntaxColors.getKeyword(true)),
      'property': TextStyle(
        color: _JsonSyntaxColors.getKey(true),
        fontWeight: FontWeight.w600,
      ),
      'punctuation': TextStyle(color: _JsonSyntaxColors.getPunctuation(true)),
      'comment': TextStyle(
        color: Colors.grey.shade500,
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
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          // 左侧不显示边框
          left: BorderSide.none,
        ),
        borderRadius: BorderRadius.circular(4),
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
        style: const TextStyle(
          fontFamily: 'Menlo',
          fontSize: 12,
          height: 1.5,
        ),
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
