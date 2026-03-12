/// UI 测试辅助工具
///
/// 提供语义标签、Key 和其他辅助功能，使 UI 测试更加容易。
/// 这些工具在生产代码中无运行时开销（仅在测试模式下使用）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 测试 Keys 集合
///
/// 使用这些 Keys 可以在测试中精确定位 Widget
class TestKeys {
  TestKeys._();

  // Sidebar Keys
  static const String sidebar = 'sidebar';
  static const String sidebarHeader = 'sidebar_header';
  static const String sidebarSearch = 'sidebar_search';
  static const String sidebarCollectionList = 'sidebar_collection_list';
  static const String sidebarNewCollectionButton = 'sidebar_new_collection_btn';

  // Request Editor Keys
  static const String requestEditor = 'request_editor';
  static const String urlInputField = 'url_input_field';
  static const String methodDropdown = 'method_dropdown';
  static const String sendButton = 'send_button';
  static const String saveButton = 'save_button';

  // Request Tabs Keys
  static const String requestTabs = 'request_tabs';
  static const String paramsTab = 'params_tab';
  static const String headersTab = 'headers_tab';
  static const String bodyTab = 'body_tab';
  static const String authTab = 'auth_tab';

  // Body Type Keys
  static const String bodyTypeNone = 'body_type_none';
  static const String bodyTypeJson = 'body_type_json';
  static const String bodyTypeText = 'body_type_text';
  static const String bodyTypeForm = 'body_type_form';

  // Response Viewer Keys
  static const String responseViewer = 'response_viewer';
  static const String responseStatusCode = 'response_status_code';
  static const String responseTime = 'response_time';
  static const String responseSize = 'response_size';
  static const String responseBodyTab = 'response_body_tab';
  static const String responseHeadersTab = 'response_headers_tab';
  static const String responseCopyButton = 'response_copy_btn';
  static const String responseSaveButton = 'response_save_btn';

  // Dialog Keys
  static const String newCollectionDialog = 'new_collection_dialog';
  static const String newCollectionNameField = 'new_collection_name_field';
  static const String newCollectionCreateButton = 'new_collection_create_btn';
  static const String newCollectionCancelButton = 'new_collection_cancel_btn';

  // Splitter/Resizer Keys
  static const String sidebarResizer = 'sidebar_resizer';
}

/// 语义标签集合
///
/// 用于辅助功能和 UI 自动化测试
class SemanticLabels {
  SemanticLabels._();

  // Sidebar Labels
  static const String sidebar = 'Collections sidebar';
  static const String searchCollections = 'Search collections';
  static const String newCollection = 'Create new collection';
  static const String collectionMenu = 'Collection actions';

  // Request Editor Labels
  static const String urlInput = 'URL input field';
  static const String httpMethodSelector = 'HTTP method selector';
  static const String sendRequest = 'Send HTTP request';
  static const String saveRequest = 'Save request to collection';

  // Tab Labels
  static const String paramsTab = 'Query parameters tab';
  static const String headersTab = 'Request headers tab';
  static const String bodyTab = 'Request body tab';
  static const String authTab = 'Authentication tab';

  // Body Type Labels
  static const String noBody = 'No request body';
  static const String jsonBody = 'JSON body content';
  static const String textBody = 'Plain text body';
  static const String formBody = 'Form data body';

  // Response Labels
  static const String responsePanel = 'HTTP response panel';
  static const String responseStatus = 'Response status code';
  static const String responseDuration = 'Response time';
  static const String responseContentSize = 'Response size';
  static const String copyResponse = 'Copy response to clipboard';
  static const String saveResponse = 'Save response to file';

  // Key-Value Editor Labels
  static const String addKeyValuePair = 'Add new key-value pair';
  static const String removeKeyValuePair = 'Remove key-value pair';
  static const String keyInput = 'Key input';
  static const String valueInput = 'Value input';
  static const String enableKeyValue = 'Enable this key-value pair';
}

/// 为 Widget 添加测试标识的便捷方法
///
/// 使用方式：
/// ```dart
/// TextField(
///   decoration: InputDecoration(...),
///   ...testHelpers.urlInput,
/// )
/// ```
class TestProperties {
  TestProperties._();

  /// URL 输入框属性
  static Map<String, dynamic> get urlInput => {
        'key': Key(TestKeys.urlInputField),
        'semanticsLabel': SemanticLabels.urlInput,
      };

  /// 发送按钮属性
  static Map<String, dynamic> get sendButton => {
        'key': Key(TestKeys.sendButton),
        'tooltip': SemanticLabels.sendRequest,
      };

  /// 保存按钮属性
  static Map<String, dynamic> get saveButton => {
        'key': Key(TestKeys.saveButton),
        'tooltip': SemanticLabels.saveRequest,
      };
}

/// 测试辅助 Widget 包装器
///
/// 为子 Widget 添加语义标签和 Key，使其更容易在测试中被找到
class TestableWidget extends StatelessWidget {
  final Widget child;
  final String? testKey;
  final String? semanticsLabel;
  final String? tooltip;
  final bool excludeSemantics;

  const TestableWidget({
    super.key,
    required this.child,
    this.testKey,
    this.semanticsLabel,
    this.tooltip,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = child;

    // 添加 Tooltip
    if (tooltip != null) {
      result = Tooltip(
        message: tooltip!,
        child: result,
      );
    }

    // 添加语义标签
    if (semanticsLabel != null && !excludeSemantics) {
      result = Semantics(
        label: semanticsLabel,
        child: result,
      );
    }

    // 添加 Key
    if (testKey != null) {
      result = KeyedSubtree(
        key: Key(testKey!),
        child: result,
      );
    }

    return result;
  }
}

/// 可测试的 TextField
///
/// 预配置好语义标签和 Key 的 TextField
class TestableTextField extends StatelessWidget {
  final String testKey;
  final String semanticsLabel;
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final bool autofocus;

  const TestableTextField({
    super.key,
    required this.testKey,
    required this.semanticsLabel,
    this.controller,
    this.hintText,
    this.onChanged,
    this.decoration,
    this.keyboardType,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      textField: true,
      child: TextField(
        key: Key(testKey),
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        autofocus: autofocus,
        decoration: decoration ??
            InputDecoration(
              hintText: hintText,
            ),
      ),
    );
  }
}

/// 可测试的按钮
///
/// 预配置好语义标签、Key 和 Tooltip 的按钮
class TestableButton extends StatelessWidget {
  final String testKey;
  final String semanticsLabel;
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final ButtonStyle? style;

  const TestableButton({
    super.key,
    required this.testKey,
    required this.semanticsLabel,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Semantics(
      label: semanticsLabel,
      button: true,
      enabled: onPressed != null,
      child: ElevatedButton(
        key: Key(testKey),
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// 可测试的 IconButton
class TestableIconButton extends StatelessWidget {
  final String testKey;
  final String semanticsLabel;
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color? color;

  const TestableIconButton({
    super.key,
    required this.testKey,
    required this.semanticsLabel,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        key: Key(testKey),
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        color: color,
      ),
    );
  }
}

/// 可调整大小的 Sidebar
///
/// 支持拖动调整宽度，并带有测试标识
class TestableResizableSidebar extends StatefulWidget {
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  final Widget child;
  final ValueChanged<double>? onWidthChanged;

  const TestableResizableSidebar({
    super.key,
    required this.initialWidth,
    this.minWidth = 200,
    this.maxWidth = 500,
    required this.child,
    this.onWidthChanged,
  });

  @override
  State<TestableResizableSidebar> createState() =>
      _TestableResizableSidebarState();
}

class _TestableResizableSidebarState extends State<TestableResizableSidebar> {
  late double _width;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar 内容
        SizedBox(
          width: _width,
          child: Semantics(
            label: SemanticLabels.sidebar,
            child: KeyedSubtree(
              key: Key(TestKeys.sidebar),
              child: widget.child,
            ),
          ),
        ),

        // 拖动调整条
        GestureDetector(
          key: Key(TestKeys.sidebarResizer),
          onHorizontalDragStart: (_) {
            setState(() => _isDragging = true);
          },
          onHorizontalDragEnd: (_) {
            setState(() => _isDragging = false);
          },
          onHorizontalDragUpdate: (details) {
            final newWidth = _width + details.delta.dx;
            if (newWidth >= widget.minWidth && newWidth <= widget.maxWidth) {
              setState(() => _width = newWidth);
              widget.onWidthChanged?.call(_width);
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: Container(
              width: 4,
              color: _isDragging
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// 测试模式检测
///
/// 检测当前是否在测试环境中运行
bool get isInTestMode {
  // 检查是否在 Flutter 测试环境中
  if (WidgetsBinding.instance is! WidgetsFlutterBinding) {
    return true;
  }

  // 检查是否有测试相关的环境变量
  const isTest = bool.fromEnvironment('FLUTTER_TEST');
  return isTest;
}

/// Widget 测试辅助扩展
extension WidgetTestHelper on Widget {
  /// 包装为可测试 Widget
  Widget withTestId({
    String? key,
    String? semanticsLabel,
    String? tooltip,
  }) {
    return TestableWidget(
      testKey: key,
      semanticsLabel: semanticsLabel,
      tooltip: tooltip,
      child: this,
    );
  }
}
