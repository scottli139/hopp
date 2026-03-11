import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/htmlbars.dart';

import '../../utils/app_logger.dart';

/// Supported language modes for syntax highlighting
enum CodeLanguage {
  json,
  text,
  xml,
  html,
}

/// A code editor widget with syntax highlighting support
class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({
    super.key,
    required this.code,
    required this.onChanged,
    this.language = CodeLanguage.json,
    this.readOnly = false,
    this.minLines,
    this.maxLines,
    this.expands = false,
  });

  final String code;
  final ValueChanged<String> onChanged;
  final CodeLanguage language;
  final bool readOnly;
  final int? minLines;
  final int? maxLines;
  final bool expands;

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
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
    widget.onChanged(_controller.text);
  }

  Mode? _getLanguageMode() {
    switch (widget.language) {
      case CodeLanguage.json:
        return json;
      case CodeLanguage.xml:
        return xml;
      case CodeLanguage.html:
        return htmlbars;
      case CodeLanguage.text:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CodeTheme(
      data: _buildCodeTheme(theme),
      child: CodeField(
        controller: _controller,
        readOnly: widget.readOnly,
        expands: widget.expands,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        textStyle: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 13,
          height: 1.4,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  CodeThemeData _buildCodeTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    // Light theme colors (GitHub-like)
    final lightTheme = {
      'root': TextStyle(
        color: theme.colorScheme.onSurface,
        backgroundColor: theme.colorScheme.surface,
      ),
      'key': TextStyle(
        color: Colors.blue.shade700,
        fontWeight: FontWeight.w600,
      ),
      'string': TextStyle(color: Colors.green.shade700),
      'number': TextStyle(color: Colors.blue.shade600),
      'literal': TextStyle(color: Colors.blue.shade600),
      'boolean': TextStyle(color: Colors.purple.shade700),
      'null': TextStyle(color: Colors.purple.shade700),
      'property': TextStyle(color: Colors.blue.shade700),
      'punctuation': TextStyle(color: Colors.grey.shade600),
      'comment': TextStyle(
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    };

    // Dark theme colors (VS Code-like)
    final darkTheme = {
      'root': TextStyle(
        color: theme.colorScheme.onSurface,
        backgroundColor: theme.colorScheme.surface,
      ),
      'key': TextStyle(
        color: Colors.lightBlue.shade300,
        fontWeight: FontWeight.w600,
      ),
      'string': TextStyle(color: Colors.lightGreen.shade300),
      'number': TextStyle(color: Colors.lightBlue.shade200),
      'literal': TextStyle(color: Colors.lightBlue.shade200),
      'boolean': TextStyle(color: Colors.purple.shade200),
      'null': TextStyle(color: Colors.purple.shade200),
      'property': TextStyle(color: Colors.lightBlue.shade300),
      'punctuation': TextStyle(color: Colors.grey.shade400),
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
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
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
          fontFamily: 'JetBrains Mono',
          fontSize: 13,
          height: 1.4,
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
