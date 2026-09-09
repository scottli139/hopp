import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/widgets/common/app_badge.dart';
import 'package:hopp/widgets/common/app_popup_menu.dart';

import '../../helpers/test_app.dart';

void main() {
  group('AppPopupSelect leading', () {
    testWidgets('触发器与菜单项显示 leading 组件（MethodBadge + 名称）', (tester) async {
      // 回归（2026-09-08 用户截图反馈）：预请求链请求选择器菜单项曾是
      // 纯文本 "POST xxx"，与侧栏 MethodBadge 风格不一致；leading 支持后
      // 触发器与菜单项都应渲染徽章
      await tester.pumpWidget(
        hoppTestApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                child: AppPopupSelect<String>(
                  value: 'post',
                  boxed: true,
                  compact: true,
                  items: [
                    AppPopupSelectEntry(
                      value: 'get',
                      label: 'endpoints',
                      leading: const MethodBadge('GET'),
                    ),
                    AppPopupSelectEntry(
                      value: 'post',
                      label: 'login post',
                      leading: const MethodBadge('POST'),
                    ),
                  ],
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 触发器：badge + 名称
      expect(find.text('login post'), findsOneWidget);
      expect(find.byType(MethodBadge), findsOneWidget);

      // 打开菜单：触发器 1 枚 + 菜单两项各 1 枚 badge
      await tester.tap(find.byType(AppPopupSelect<String>));
      await tester.pumpAndSettle();
      expect(find.byType(MethodBadge), findsNWidgets(3));
      expect(find.text('endpoints'), findsOneWidget);
      // 触发器 + 菜单选中项各一处
      expect(find.text('login post'), findsNWidgets(2));
    });
  });
}
