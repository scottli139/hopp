import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/app_settings.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/providers/ai/ai_provider.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/settings/settings_provider.dart';
import 'package:hopp/services/ai/ai_models.dart';
import 'package:hopp/widgets/ai/build_request_dialog.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/test_app.dart';
import '../../mocks/service_mocks.mocks.dart';

const _draft = AiRequestDraft(
  name: '创建用户',
  method: 'POST',
  url: 'https://api.example.com/users',
  params: [],
  headers: [
    AiKeyValueDraft(
      key: 'Content-Type',
      value: 'application/json',
      enabled: true,
    ),
  ],
  bodyType: 'raw',
  rawContentType: 'json',
  body: '{"name":"张三"}',
);

class FakeBuildRequestNotifier extends BuildRequestNotifier {
  FakeBuildRequestNotifier(super.ref);

  @override
  Future<void> build({required String description}) async {
    state = const AiOpState<AiRequestDraft>.loading();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = const AiOpState<AiRequestDraft>.success(_draft);
  }
}

void main() {
  group('NaturalLanguageRequestButton / dialog', () {
    late MockStorageService mockStorageService;
    late AppSettings settings;

    setUp(() {
      mockStorageService = MockStorageService();
      settings = const AppSettings(aiEnabled: true, aiModel: 'qwen2.5:7b');
      when(mockStorageService.getSettings()).thenAnswer((_) async => settings);
      when(mockStorageService.saveSettings(any)).thenAnswer((_) async {});
    });

    ProviderContainer buildContainer() {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
          buildRequestProvider
              .overrideWith((ref) => FakeBuildRequestNotifier(ref)),
        ],
      );
      // 预触发 settings 加载，避免门控读到 loading 态
      container.read(settingsProvider);
      return container;
    }

    Future<void> pumpButton(
      WidgetTester tester,
      ProviderContainer container, {
      required HttpRequest currentRequest,
      void Function(AiRequestDraft)? onApply,
    }) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          // 对话框固定宽 560；测试字体的拉丁字形宽 ≈ 字号（方块），
          // 英文按钮文案比真实字体宽近一倍会溢出底栏，缩 0.8 规避。
          child: hoppTestApp(
            textScaler: const TextScaler.linear(0.8),
            home: Scaffold(
              body: NaturalLanguageRequestButton(
                currentRequest: currentRequest,
                onApply: onApply ?? (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Build Request with Natural Language'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('build_request_dialog')), findsOneWidget);
    }

    Future<void> generateDraft(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key('ai_request_description_field')),
        'POST 创建用户，JSON body 含 name 和 email',
      );
      await tester.pump();
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();
    }

    testWidgets('input → generate → result preview flow', (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await pumpButton(
        tester,
        container,
        currentRequest: HttpRequest(id: 'r1', name: 'req'),
      );
      await openDialog(tester);

      // 输入态
      expect(
        find.text(
            'The result is a draft you can keep editing after applying; field values come only from your description'),
        findsOneWidget,
      );

      await generateDraft(tester);

      // 结果确认态
      expect(find.text('https://api.example.com/users'), findsOneWidget);
      expect(find.text('PARAMS'), findsOneWidget);
      expect(find.text('HEADERS'), findsOneWidget);
      expect(find.text('Content-Type'), findsOneWidget);
      expect(find.text('BODY · JSON'), findsOneWidget);
      expect(find.text('{"name":"张三"}'), findsOneWidget);
      expect(find.text('Regenerate'), findsOneWidget);
      expect(find.text('Apply to Current Request'), findsOneWidget);
    });

    testWidgets('apply without confirmation when current request is empty',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      AiRequestDraft? applied;
      await pumpButton(
        tester,
        container,
        currentRequest: HttpRequest(id: 'r1', name: 'req'),
        onApply: (draft) => applied = draft,
      );
      await openDialog(tester);
      await generateDraft(tester);

      await tester.tap(find.text('Apply to Current Request'));
      await tester.pumpAndSettle();

      // 空请求直接填入，无覆盖确认
      expect(applied, isNotNull);
      expect(applied!.method, 'POST');
      expect(applied!.url, 'https://api.example.com/users');
      expect(find.byKey(const Key('build_request_dialog')), findsNothing);
    });

    testWidgets('apply asks confirmation when current request has content',
        (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      AiRequestDraft? applied;
      await pumpButton(
        tester,
        container,
        currentRequest: HttpRequest(
          id: 'r1',
          name: 'req',
          url: 'https://old.example.com/list',
        ),
        onApply: (draft) => applied = draft,
      );
      await openDialog(tester);
      await generateDraft(tester);

      await tester.tap(find.text('Apply to Current Request'));
      await tester.pumpAndSettle();

      // 覆盖确认对话框
      expect(find.text('Overwrite current request?'), findsOneWidget);

      await tester.tap(find.text('Overwrite'));
      await tester.pumpAndSettle();

      expect(applied, isNotNull);
      expect(applied!.url, 'https://api.example.com/users');
      expect(find.byKey(const Key('build_request_dialog')), findsNothing);
    });

    testWidgets('gate: shows snackbar when AI is not enabled', (tester) async {
      settings = const AppSettings(); // aiEnabled = false
      final container = buildContainer();
      addTearDown(container.dispose);
      await pumpButton(
        tester,
        container,
        currentRequest: HttpRequest(id: 'r1', name: 'req'),
      );

      await tester.tap(find.byTooltip('Build Request with Natural Language'));
      await tester.pumpAndSettle();

      expect(find.text('Local AI is not enabled or no model is configured'),
          findsOneWidget);
      expect(find.byKey(const Key('build_request_dialog')), findsNothing);
    });
  });
}
