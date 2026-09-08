import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/auth_config.dart';
import 'package:hopp/widgets/request/auth_config_editor.dart';

import '../../helpers/test_app.dart';

void main() {
  group('AuthConfigEditor', () {
    testWidgets('矮面板下左侧类型列表可滚动不溢出', (tester) async {
      // 回归：左侧认证类型列表是固定高度 Column，分栏拖矮后曾
      // BOTTOM OVERFLOWED 82px；已改为可滚动
      await tester.pumpWidget(
        hoppTestApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: AuthConfigEditor(
                    auth: const AuthConfig(),
                    allowInherit: true,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('AUTH TYPE'), findsOneWidget);
    });

    testWidgets('类型列表项点击切换选中类型', (tester) async {
      final captured = <AuthConfig>[];
      await tester.pumpWidget(
        hoppTestApp(
          home: Scaffold(
            body: AuthConfigEditor(
              auth: const AuthConfig(),
              allowInherit: true,
              onChanged: captured.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bearer Token'));
      await tester.pump();

      expect(captured.single.type, AuthType.bearer);
    });
  });
}
