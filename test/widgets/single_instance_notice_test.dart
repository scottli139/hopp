import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/widgets/single_instance_notice_app.dart';

void main() {
  group('SingleInstanceNoticeApp', () {
    testWidgets('展示提示文案并触发退出回调', (tester) async {
      var quit = false;
      await tester.pumpWidget(
        SingleInstanceNoticeApp(onQuit: () => quit = true),
      );
      await tester.pumpAndSettle();

      // 默认 locale 为 en
      expect(find.text('Hopp Is Already Running'), findsOneWidget);
      expect(
        find.textContaining('only one instance can run at a time'),
        findsOneWidget,
      );

      await tester.tap(find.text('Quit'));
      await tester.pumpAndSettle();
      expect(quit, isTrue);
    });
  });
}
