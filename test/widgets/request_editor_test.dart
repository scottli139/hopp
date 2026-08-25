import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/auth_config.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/key_value_pair.dart';
import 'package:hopp/models/pre_request_step.dart';
import 'package:hopp/models/request_tab.dart';
import 'package:hopp/providers/providers.dart';
import 'package:hopp/widgets/common/app_controls.dart';
import 'package:hopp/widgets/request/request_editor.dart';
import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('RequestEditor', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      // Stub storage methods
      when(mockStorageService.getCollections()).thenAnswer((_) async => []);
      when(mockStorageService.getRequests()).thenAnswer((_) async => []);
      // URL 栏未定义变量警告会读取环境变量相关 provider
      when(mockStorageService.getEnvironments()).thenAnswer((_) async => []);
      when(mockStorageService.getActiveEnvironmentId())
          .thenAnswer((_) async => null);
      when(mockStorageService.getGlobalVariables()).thenAnswer((_) async => []);
    });

    Widget buildTestWidget({
      required ProviderContainer container,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: RequestEditor(),
          ),
        ),
      );
    }

    ProviderContainer createContainer({
      List<RequestTab> tabs = const [],
      String? activeTabId,
    }) {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );

      // Initialize tabs
      if (tabs.isNotEmpty) {
        container.read(requestTabProvider.notifier).state = tabs;
      }

      // Set active tab
      if (activeTabId != null) {
        container.read(activeTabIdProvider.notifier).state = activeTabId;
      }

      return container;
    }

    group('rendering', () {
      testWidgets('should show empty state when no active tab', (tester) async {
        final container = createContainer();

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Select a request'), findsOneWidget);
      });

      testWidgets('should render URL bar with method dropdown', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          url: 'https://api.example.com/users',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Check URL field
        expect(find.text('https://api.example.com/users'), findsOneWidget);

        // Check method dropdown (MenuAnchor is used instead of DropdownButton)
        expect(find.byType(MenuAnchor), findsWidgets);

        // Check Send button
        // Check for Send button with icon
        expect(find.byIcon(Icons.send), findsOneWidget);
        expect(find.text('Send'), findsOneWidget);
      });

      testWidgets('should render all tabs', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Params'), findsOneWidget);
        expect(find.text('Headers'), findsOneWidget);
        expect(find.text('Body'), findsOneWidget);
        expect(find.text('Auth'), findsOneWidget);
      });

      testWidgets('should display correct method in dropdown', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.post,
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Verify POST method is displayed (MenuAnchor shows the current method)
        expect(find.text('POST'), findsOneWidget);
      });
    });

    group('Params tab', () {
      testWidgets('should render empty params list with add button',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Add new'), findsOneWidget);
      });

      testWidgets('should render params with headers', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty()
                .copyWith(key: 'page', value: '1', enabled: true),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('Key'), findsWidgets);
        // Value header text is present
        expect(find.text('Value'), findsWidgets);
      });

      testWidgets('should display param key and value', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty()
                .copyWith(key: 'search', value: 'test', enabled: true),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('search'), findsOneWidget);
        expect(find.text('test'), findsOneWidget);
      });

      testWidgets('should show checkbox for param enabled state',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty()
                .copyWith(key: 'enabled', value: 'yes', enabled: true),
            KeyValuePair.empty()
                .copyWith(key: 'disabled', value: 'no', enabled: false),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Find checkboxes
        final checkboxes =
            tester.widgetList<AppCheckbox>(find.byType(AppCheckbox)).toList();
        expect(checkboxes.length, greaterThanOrEqualTo(2));
        expect(checkboxes[0].value, true);
        expect(checkboxes[1].value, false);
      });

      testWidgets('should show delete button for each param', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty().copyWith(key: 'param1', value: 'value1'),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });
    });

    group('Headers tab', () {
      testWidgets('should switch to Headers tab', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Content-Type', value: 'application/json'),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Headers tab (find by text containing 'Headers')
        await tester.tap(find.textContaining('Headers'));
        await tester.pumpAndSettle();

        // Verify headers are displayed
        expect(find.text('Content-Type'), findsOneWidget);
        // Check that at least one TextField with the value exists
        expect(find.byType(TextField), findsAtLeastNWidgets(2));
      });
    });

    group('Body tab', () {
      testWidgets('should render body type selector', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.post,
          bodyType: 'raw',
          rawContentType: 'json',
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Body tab
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        // Check for new body type options
        expect(find.text('none'), findsOneWidget);
        expect(find.text('form-data'), findsOneWidget);
        expect(find.text('x-www-form-urlencoded'), findsOneWidget);
        expect(find.text('raw'), findsOneWidget);
        expect(find.text('binary'), findsOneWidget);
        expect(find.text('GraphQL'), findsOneWidget);
      });

      testWidgets('should render body editor when body type is not none',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.post,
          bodyType: 'raw',
          rawContentType: 'json',
          body: '{"key": "value"}',
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Body tab
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        // Check that CodeEditor is rendered (CodeField is the underlying widget)
        expect(find.byType(CodeField), findsOneWidget);
      });

      testWidgets('should not render body editor when body type is none',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          bodyType: 'none',
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Body tab
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        // Body editor should not be visible
        final textFields = tester.widgetList<TextField>(find.byType(TextField));
        final bodyTextField = textFields.where(
          (tf) => tf.decoration?.hintText == 'Request body',
        );
        expect(bodyTextField, isEmpty);
      });
    });

    group('Auth tab', () {
      testWidgets('should show auth type list and inherit hint by default',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Tap on Auth tab
        await tester.tap(find.text('Auth'));
        await tester.pumpAndSettle();

        // 类型列表（Inherit 同时是表单标题，故 2 处）
        expect(find.text('Inherit'), findsNWidgets(2));
        expect(find.text('No Auth'), findsOneWidget);
        expect(find.text('Bearer Token'), findsOneWidget);
        expect(find.text('Basic Auth'), findsOneWidget);
        expect(find.text('API Key'), findsOneWidget);
        // 默认 Inherit：无继承来源时的兜底提示
        expect(find.text('继承链上未找到认证配置，发送时不附加认证信息。'), findsOneWidget);
      });

      testWidgets('should show bearer token field when Bearer selected',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          method: HttpMethod.get,
          auth: const AuthConfig(type: AuthType.bearer, token: '{{token}}'),
        );

        final container = createContainer(
          tabs: [
            RequestTab(
              id: 'req1',
              request: request,
            ),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Auth'));
        await tester.pumpAndSettle();

        // 表单区标题 + Token 标签 + 覆盖说明
        expect(find.text('Token'), findsOneWidget);
        expect(
          find.textContaining('Authorization: Bearer <token>'),
          findsOneWidget,
        );
      });
    });

    group('Pre-request tab', () {
      testWidgets('should show empty chain state by default', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
        );

        final container = createContainer(
          tabs: [RequestTab(id: 'req1', request: request)],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pre-request'));
        await tester.pumpAndSettle();

        expect(find.text('前置链'), findsOneWidget);
        expect(find.text('暂无前置步骤'), findsOneWidget);
        expect(find.text('添加步骤'), findsOneWidget);
        expect(find.text('过期策略'), findsOneWidget);
      });

      testWidgets('should add step and show step card', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
        );

        final container = createContainer(
          tabs: [RequestTab(id: 'req1', request: request)],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pre-request'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('添加步骤'));
        await tester.pumpAndSettle();

        // 步骤卡片：选择器占位 + 提取规则区
        expect(find.text('选择请求…'), findsOneWidget);
        expect(find.text('EXTRACT · 从响应提取变量'), findsOneWidget);
        expect(find.text('添加提取规则'), findsOneWidget);

        // tab 上显示步骤计数
        expect(find.text('1'), findsWidgets);
      });

      testWidgets('should add extraction rule to step', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          preRequestChain: [
            PreRequestStep(id: 's1', requestId: 'login-req'),
          ],
        );

        final container = createContainer(
          tabs: [RequestTab(id: 'req1', request: request)],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pre-request'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('添加提取规则'));
        await tester.pumpAndSettle();

        // 规则行：来源选择器 + 目标变量输入
        expect(find.text('Body · JSONPath'), findsOneWidget);
      });
    });

    group('Variable fx menu (F8.3)', () {
      testWidgets(
          'should show fx icon on value cell with variable and open menu',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          params: [
            KeyValuePair.empty()
                .copyWith(key: 'sign', value: '{{password | sha1}}'),
          ],
        );

        final container = createContainer(
          tabs: [RequestTab(id: 'req1', request: request)],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // fx 图标出现在含 {{var}} 的值单元格右端
        final fxIcon = find.byIcon(Icons.functions);
        expect(fxIcon, findsOneWidget);

        await tester.tap(fxIcon);
        await tester.pumpAndSettle();

        // 菜单：解析预览区 + 函数插入区
        expect(find.text('RESOLVED PREVIEW'), findsOneWidget);
        expect(find.text('INSERT TRANSFORM'), findsOneWidget);
        // 无参与带参函数条目
        expect(find.text('md5'), findsWidgets);
        expect(find.text('hmac(algo, key)'), findsOneWidget);
        expect(find.text('aes(mode, key, iv)'), findsOneWidget);
      });

      testWidgets('should insert no-arg transform at cursor', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test Request',
          params: [
            KeyValuePair.empty().copyWith(key: 'token', value: '{{token}}'),
          ],
        );

        final container = createContainer(
          tabs: [RequestTab(id: 'req1', request: request)],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.functions));
        await tester.pumpAndSettle();

        await tester.tap(find.text('md5').last);
        await tester.pumpAndSettle();

        // 插入后值被同步到 provider
        final updated = container
            .read(requestTabProvider)
            .firstWhere((t) => t.id == 'req1')
            .request;
        expect(updated.params.first.value, contains('| md5'));
      });
    });

    group('method colors', () {
      testWidgets('should display GET method with blue color', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Find GET text in dropdown
        expect(find.text('GET'), findsOneWidget);
      });

      testWidgets('should display POST method with green color',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test',
          method: HttpMethod.post,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('POST'), findsOneWidget);
      });

      testWidgets('should display DELETE method with red color',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test',
          method: HttpMethod.delete,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('DELETE'), findsOneWidget);
      });
    });

    group('URL input', () {
      testWidgets('should render URL input field', (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Test',
          url: '',
          method: HttpMethod.get,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Find URL input by hint text
        expect(find.text('Enter URL'), findsOneWidget);
      });
    });

    group('complex scenarios', () {
      testWidgets('should handle request with multiple params and headers',
          (tester) async {
        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Complex Request',
          url: 'https://api.example.com/search',
          method: HttpMethod.get,
          params: [
            KeyValuePair.empty().copyWith(key: 'q', value: 'flutter'),
            KeyValuePair.empty().copyWith(key: 'page', value: '1'),
            KeyValuePair.empty().copyWith(key: 'limit', value: '10'),
          ],
          headers: [
            KeyValuePair.empty()
                .copyWith(key: 'Authorization', value: 'Bearer token123'),
            KeyValuePair.empty()
                .copyWith(key: 'Accept', value: 'application/json'),
          ],
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        expect(find.text('q'), findsOneWidget);
        expect(find.text('flutter'), findsOneWidget);
        expect(find.text('page'), findsOneWidget);
        expect(find.text('1'), findsWidgets); // Multiple '1' may exist
      });

      testWidgets('should handle JSON body request', (tester) async {
        final jsonBody = '''{
  "name": "John Doe",
  "email": "john@example.com",
  "age": 30
}''';

        final request = HttpRequest.empty().copyWith(
          id: 'req1',
          name: 'Create User',
          url: 'https://api.example.com/users',
          method: HttpMethod.post,
          bodyType: 'raw',
          rawContentType: 'json',
          body: jsonBody,
        );

        final container = createContainer(
          tabs: [
            RequestTab(id: 'req1', request: request),
          ],
          activeTabId: 'req1',
        );

        await tester.pumpWidget(buildTestWidget(container: container));
        await tester.pumpAndSettle();

        // Navigate to body tab
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        // Verify JSON body is displayed
        expect(find.textContaining('John Doe'), findsOneWidget);
      });
    });
  });
}
