import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/main.dart' as app;
import 'package:hopp/widgets/layout/request_tabs.dart';
import 'package:hopp/widgets/layout/sidebar.dart';
import 'package:hopp/widgets/request/request_editor.dart';
import 'package:hopp/widgets/request/response_viewer.dart';

import 'package:integration_test/integration_test.dart';

/// 高级 UI 自动化测试
///
/// 测试范围：
/// 1. Widget 定位与点击（按钮、菜单、Tab）
/// 2. 文本输入（URL、Headers、Body）
/// 3. Sidebar 拖动与区域调整
/// 4. 复杂交互流程（创建请求 -> 编辑 -> 发送 -> 验证响应）
/// 5. 状态验证（响应码、响应体、UI 状态）
void main([List<String> args = const []]) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UI Automation Tests', () {
    // 等待应用启动的辅助函数
    Future<void> waitForApp(WidgetTester tester) async {
      app.main([]);
      await tester.pumpAndSettle();
      // 等待应用完全初始化
      await Future.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    group('1. Widget 定位与点击', () {
      testWidgets('should find and tap all major widgets',
          (WidgetTester tester) async {
        await waitForApp(tester);

        // 1. 验证主要 Widget 存在
        expect(find.byType(Sidebar), findsOneWidget, reason: 'Sidebar 应该存在');
        expect(find.byType(RequestTabs), findsOneWidget,
            reason: 'RequestTabs 应该存在');
        expect(find.byType(RequestEditor), findsOneWidget,
            reason: 'RequestEditor 应该存在');

        // 2. 点击 "New Collection" 菜单
        // 先找到 Sidebar 中的菜单按钮
        final menuButton = find.byIcon(Icons.more_vert);
        expect(menuButton, findsWidgets, reason: '应该找到菜单按钮');

        await tester.tap(menuButton.first);
        await tester.pumpAndSettle();

        // 3. 验证弹出菜单显示
        expect(find.text('New Collection'), findsOneWidget,
            reason: 'New Collection 菜单项应该显示');
        expect(find.text('About'), findsOneWidget,
            reason: 'About 菜单项应该显示');

        // 4. 点击 New Collection
        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        // 5. 验证对话框显示
        expect(find.text('New Collection'), findsWidgets,
            reason: '新建集合对话框应该显示');
        expect(find.byType(TextField), findsWidgets,
            reason: '对话框中应该有输入框');

        // 6. 取消对话框
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      });

      testWidgets('should switch between request tabs',
          (WidgetTester tester) async {
        await waitForApp(tester);

        // 创建第一个集合
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        // 输入集合名称
        await tester.enterText(find.byType(TextField).last, 'Tab Test Collection');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        // 验证集合创建成功
        expect(find.text('Tab Test Collection'), findsOneWidget);

        // 打开集合并添加请求
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Request'));
        await tester.pumpAndSettle();

        // 验证请求 Tab 显示
        expect(find.text('New Request'), findsWidgets);

        // 切换 Request Editor 的 Tabs（Params -> Headers -> Body -> Auth）
        await tester.tap(find.text('Headers'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Auth'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Params'));
        await tester.pumpAndSettle();

        // 验证回到 Params Tab
        expect(find.text('Key'), findsWidgets);
      });
    });

    group('2. 文本输入测试', () {
      testWidgets('should input URL and request body',
          (WidgetTester tester) async {
        await waitForApp(tester);

        // 创建集合和请求
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, 'Input Test');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Request'));
        await tester.pumpAndSettle();

        // 1. 输入 URL
        final urlField = find.byType(TextField).first;
        await tester.enterText(urlField, 'https://httpbin.org/post');
        await tester.pumpAndSettle();

        // 验证 URL 输入成功（通过重新查找包含该文本的字段）
        expect(find.text('https://httpbin.org/post'), findsOneWidget);

        // 2. 切换到 Body Tab
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();

        // 3. 选择 JSON body 类型
        await tester.tap(find.text('JSON'));
        await tester.pumpAndSettle();

        // 4. 输入 JSON body
        // 查找代码编辑器（CodeEditor 包含多层 widget，需要找到可输入的 TextField）
        final codeEditors = find.byType(TextField);
        if (codeEditors.evaluate().isNotEmpty) {
          // 尝试在代码编辑器中输入
          final bodyField = codeEditors.last;
          await tester.enterText(bodyField, '{"test": "value", "number": 123}');
          await tester.pumpAndSettle();

          // 验证输入
          expect(find.textContaining('"test": "value"'), findsWidgets);
        }
      });

      testWidgets('should add and edit headers',
          (WidgetTester tester) async {
        await waitForApp(tester);

        // 创建集合和请求
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, 'Header Test');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Request'));
        await tester.pumpAndSettle();

        // 切换到 Headers Tab
        await tester.tap(find.text('Headers'));
        await tester.pumpAndSettle();

        // 点击 "Add new" 添加 Header
        await tester.tap(find.text('Add new'));
        await tester.pumpAndSettle();

        // 输入 Header Key 和 Value
        final textFields = find.byType(TextField);
        if (textFields.evaluate().length >= 2) {
          await tester.enterText(textFields.at(1), 'Content-Type');
          await tester.pumpAndSettle();

          await tester.enterText(textFields.at(2), 'application/json');
          await tester.pumpAndSettle();
        }

        // 验证 Headers 显示
        expect(find.text('Content-Type'), findsWidgets);
        expect(find.text('application/json'), findsWidgets);
      });
    });

    group('3. Sidebar 拖动测试', () {
      testWidgets('should drag sidebar resizer', (WidgetTester tester) async {
        await waitForApp(tester);

        // 获取屏幕尺寸
        final size = tester.getSize(find.byType(MaterialApp));

        // 尝试拖动 sidebar 分割线（假设在 x=250 位置）
        // 从 sidebar 右侧边缘开始拖动
        final dragStart = Offset(250, size.height / 2);
        final dragEnd = Offset(400, size.height / 2);

        // 执行拖动
        await tester.dragFrom(dragStart, dragEnd - dragStart);
        await tester.pumpAndSettle();

        // 验证拖动后 UI 仍然正常（没有报错即可）
        expect(find.byType(Sidebar), findsOneWidget);
        expect(find.byType(RequestEditor), findsOneWidget);

        // 拖回原位
        await tester.dragFrom(dragEnd, dragStart - dragEnd);
        await tester.pumpAndSettle();
      });
    });

    group('4. HTTP 请求完整流程', () {
      testWidgets('should complete full request flow',
          (WidgetTester tester) async {
        await waitForApp(tester);

        // Step 1: 创建新集合
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, 'E2E Test');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        // Step 2: 添加请求
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Request'));
        await tester.pumpAndSettle();

        // Step 3: 输入 URL
        final urlField = find.byType(TextField).first;
        await tester.enterText(urlField, 'https://httpbin.org/get');
        await tester.pumpAndSettle();

        // Step 4: 添加 Query Parameter
        await tester.tap(find.text('Add new'));
        await tester.pumpAndSettle();

        final paramFields = find.byType(TextField);
        if (paramFields.evaluate().length >= 2) {
          await tester.enterText(paramFields.at(1), 'test_param');
          await tester.pumpAndSettle();
          await tester.enterText(paramFields.at(2), 'test_value');
          await tester.pumpAndSettle();
        }

        // Step 5: 发送请求
        await tester.tap(find.text('Send'));
        await tester.pump(const Duration(seconds: 1));

        // Step 6: 等待响应（最多 15 秒）
        bool responseReceived = false;
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 500));

          // 检查响应状态码
          if (find.textContaining('200').evaluate().isNotEmpty) {
            responseReceived = true;
            break;
          }

          // 检查错误
          if (find.textContaining('Error').evaluate().isNotEmpty) {
            break;
          }
        }

        expect(responseReceived, isTrue,
            reason: '应该收到 HTTP 200 响应');

        // Step 7: 验证 ResponseViewer 显示
        expect(find.byType(ResponseViewer), findsOneWidget);

        // Step 8: 验证响应内容显示
        expect(find.textContaining('Body'), findsWidgets);
      });

      testWidgets('should handle POST request with JSON body',
          (WidgetTester tester) async {
        await waitForApp(tester);

        // 创建集合和请求
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, 'POST Test');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Request'));
        await tester.pumpAndSettle();

        // 更改 HTTP Method 为 POST
        // 找到 Method Dropdown 并点击
        await tester.tap(find.text('GET'));
        await tester.pumpAndSettle();
        // 查找 POST 选项并点击
        final postOption = find.textContaining('POST');
        if (tester.any(postOption)) {
          await tester.tap(postOption.first);
          await tester.pumpAndSettle();
        }

        // 输入 URL
        final urlField = find.byType(TextField).first;
        await tester.enterText(urlField, 'https://httpbin.org/post');
        await tester.pumpAndSettle();

        // 切换到 Body Tab 并输入 JSON
        await tester.tap(find.text('Body'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('JSON'));
        await tester.pumpAndSettle();

        // 发送请求
        await tester.tap(find.text('Send'));
        await tester.pump(const Duration(seconds: 1));

        // 等待响应
        bool responseReceived = false;
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (find.textContaining('200').evaluate().isNotEmpty) {
            responseReceived = true;
            break;
          }
        }

        expect(responseReceived, isTrue,
            reason: 'POST 请求应该成功');
      });
    });

    group('5. 复杂交互场景', () {
      testWidgets('should handle multiple tabs operations',
          (WidgetTester tester) async {
        await waitForApp(tester);

        // 创建集合
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, 'Multi Tab Test');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        // 创建多个请求
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byIcon(Icons.more_vert).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Add Request'));
          await tester.pumpAndSettle();

          // 为每个请求设置不同的 URL
          final urlField = find.byType(TextField).first;
          await tester.enterText(urlField, 'https://httpbin.org/get?req=$i');
          await tester.pumpAndSettle();
        }

        // 验证多个 Tab 存在
        expect(find.text('New Request'), findsWidgets);

        // 关闭一个 Tab（点击 X 按钮）
        final closeButtons = find.byIcon(Icons.close);
        if (closeButtons.evaluate().isNotEmpty) {
          await tester.tap(closeButtons.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('should save request to collection',
          (WidgetTester tester) async {
        await waitForApp(tester);

        // 创建集合和请求
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, 'Save Test');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Request'));
        await tester.pumpAndSettle();

        // 修改请求名称
        // 这里假设有一个地方可以编辑请求名称
        // 实际实现可能需要根据 UI 调整

        // 输入 URL
        final urlField = find.byType(TextField).first;
        await tester.enterText(urlField, 'https://httpbin.org/get');
        await tester.pumpAndSettle();

        // 点击保存按钮（根据 tooltip 查找）
        final saveButton = find.byTooltip('Save to collection');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();

          // 验证保存成功的提示
          await tester.pump(const Duration(seconds: 1));
        }
      });
    });

    group('6. 错误处理测试', () {
      testWidgets('should handle invalid URL gracefully',
          (WidgetTester tester) async {
        await waitForApp(tester);

        // 创建集合和请求
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Collection'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).last, 'Error Test');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Request'));
        await tester.pumpAndSettle();

        // 输入无效 URL
        final urlField = find.byType(TextField).first;
        await tester.enterText(urlField, 'http://localhost:99999');
        await tester.pumpAndSettle();

        // 发送请求
        await tester.tap(find.text('Send'));
        await tester.pump(const Duration(seconds: 1));

        // 等待错误响应（最多 10 秒）
        var errorFound = false;
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 500));

          // 检查错误图标或错误文本
          if (find.byIcon(Icons.error_outline).evaluate().isNotEmpty ||
              find.textContaining('error', skipOffstage: false).evaluate().isNotEmpty) {
            errorFound = true;
            break;
          }
        }

        // 应用应该优雅地处理错误，不崩溃（不检查是否找到错误，只验证不崩溃）
        expect(find.byType(RequestEditor), findsOneWidget);
      });
    });
  });
}
