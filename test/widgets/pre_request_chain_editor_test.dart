import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/pre_request_step.dart';
import 'package:hopp/providers/collection/collection_provider.dart';
import 'package:hopp/widgets/common/app_text_field.dart';
import 'package:hopp/widgets/request/pre_request_chain_editor.dart';

import '../helpers/test_app.dart';

void main() {
  group('PreRequestChainEditor 提取规则编辑', () {
    PreRequestStep buildStep() => PreRequestStep(
          id: 'step-1',
          requestId: 'req-login',
          extractions: [
            ExtractionRule(
              id: 'rule-1',
              path: r'$.data.token',
              targetVariable: 'token',
            ),
          ],
        );

    /// 模拟真实宿主（request_editor / collection 设置对话框）：
    /// onChainChanged 立即把新链写回状态并触发重建。
    Widget buildHarness(
      List<PreRequestStep> chain,
      void Function(List<PreRequestStep>) onChanged,
    ) {
      return ProviderScope(
        overrides: [
          requestsProvider.overrideWith((ref) async => <HttpRequest>[]),
        ],
        child: hoppTestApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PreRequestChainEditor(
                  chain: chain,
                  retryOn401: true,
                  onChainChanged: (updated) {
                    onChanged(updated);
                    setState(() => chain = updated);
                  },
                  onRetryChanged: (_) {},
                  ownerId: 'owner-1',
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('输入即提交：路径与目标变量无需回车生效', (tester) async {
      final captured = <List<PreRequestStep>>[];
      await tester.pumpWidget(buildHarness([buildStep()], captured.add));
      await tester.pumpAndSettle();

      // 第一个输入框 = 提取路径，第二个 = 目标变量
      await tester.enterText(find.byType(AppTextField).at(0), r'$.token');
      await tester.pump();
      expect(captured.last.single.extractions.single.path, r'$.token');

      await tester.enterText(find.byType(AppTextField).at(1), 'haishen_token');
      await tester.pump();
      expect(captured.last.single.extractions.single.targetVariable,
          'haishen_token');
    });

    testWidgets('回归：宿主应用提交后重建，输入内容不被回写清空', (tester) async {
      await tester.pumpWidget(buildHarness([buildStep()], (_) {}));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(AppTextField).at(0), r'$.token');
      await tester.enterText(find.byType(AppTextField).at(1), 'haishen_token');
      // 宿主 onChainChanged → setState → 重建（同试运行结果到达的路径）
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppTextField, r'$.token'), findsOneWidget);
      expect(
          find.widgetWithText(AppTextField, 'haishen_token'), findsOneWidget);
    });
  });
}
