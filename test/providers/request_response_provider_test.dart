import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/http_response.dart';
import 'package:hopp/providers/core/providers.dart';
import 'package:hopp/providers/request/request_response_provider.dart';
import 'package:hopp/providers/request/request_tab_provider.dart';

import 'package:mockito/mockito.dart';

import '../mocks/service_mocks.mocks.dart';

void main() {
  group('RequestResponseNotifier', () {
    late MockHttpService mockHttpService;
    late RequestResponseNotifier notifier;

    setUp(() {
      mockHttpService = MockHttpService();
      notifier = RequestResponseNotifier(mockHttpService);
    });

    group('sendRequest', () {
      test('should set empty response initially', () async {
        final request = HttpRequest.empty().copyWith(
          id: 'req-1',
          url: 'https://api.example.com',
          method: HttpMethod.get,
        );

        when(mockHttpService.sendRequest(request)).thenAnswer(
          (_) async => HttpResponse(
            statusCode: 200,
            body: 'OK',
          ),
        );

        final future = notifier.sendRequest('tab-1', request);

        expect(notifier.state['tab-1'], equals(HttpResponse.empty()));

        await future;
      });

      test('should update with response after successful request', () async {
        final request = HttpRequest.empty().copyWith(
          id: 'req-1',
          url: 'https://api.example.com',
          method: HttpMethod.get,
        );

        final expectedResponse = HttpResponse(
          statusCode: 200,
          body: '{"data": "test"}',
          durationMs: 100,
        );

        when(mockHttpService.sendRequest(request))
            .thenAnswer((_) async => expectedResponse);

        await notifier.sendRequest('tab-1', request);

        expect(notifier.state['tab-1'], equals(expectedResponse));
      });

      test('should handle multiple tabs independently', () async {
        final request1 = HttpRequest.empty().copyWith(
          id: 'req-1',
          url: 'https://api1.example.com',
          method: HttpMethod.get,
        );
        final request2 = HttpRequest.empty().copyWith(
          id: 'req-2',
          url: 'https://api2.example.com',
          method: HttpMethod.post,
        );

        final response1 = HttpResponse(statusCode: 200, body: 'Response 1');
        final response2 = HttpResponse(statusCode: 201, body: 'Response 2');

        when(mockHttpService.sendRequest(request1))
            .thenAnswer((_) async => response1);
        when(mockHttpService.sendRequest(request2))
            .thenAnswer((_) async => response2);

        await notifier.sendRequest('tab-1', request1);
        await notifier.sendRequest('tab-2', request2);

        expect(notifier.state['tab-1'], equals(response1));
        expect(notifier.state['tab-2'], equals(response2));
      });

      test('should update existing tab response', () async {
        final request = HttpRequest.empty().copyWith(
          id: 'req-1',
          url: 'https://api.example.com',
          method: HttpMethod.get,
        );

        final response1 = HttpResponse(statusCode: 200, body: 'First');
        final response2 = HttpResponse(statusCode: 200, body: 'Second');

        when(mockHttpService.sendRequest(request))
            .thenAnswer((_) async => response1);
        await notifier.sendRequest('tab-1', request);

        when(mockHttpService.sendRequest(request))
            .thenAnswer((_) async => response2);
        await notifier.sendRequest('tab-1', request);

        expect(notifier.state['tab-1'], equals(response2));
      });
    });

    group('getResponse', () {
      test('should return response for existing tab', () async {
        final request = HttpRequest.empty().copyWith(
          id: 'req-1',
          url: 'https://api.example.com',
          method: HttpMethod.get,
        );

        final response = HttpResponse(statusCode: 200, body: 'OK');

        when(mockHttpService.sendRequest(request))
            .thenAnswer((_) async => response);

        await notifier.sendRequest('tab-1', request);

        expect(notifier.getResponse('tab-1'), equals(response));
      });

      test('should return null for non-existent tab', () {
        expect(notifier.getResponse('non-existent'), isNull);
      });
    });

    group('clearResponse', () {
      test('should remove response for specific tab', () async {
        final request1 = HttpRequest.empty().copyWith(id: 'req-1');
        final request2 = HttpRequest.empty().copyWith(id: 'req-2');

        when(mockHttpService.sendRequest(any))
            .thenAnswer((_) async => HttpResponse(statusCode: 200));

        await notifier.sendRequest('tab-1', request1);
        await notifier.sendRequest('tab-2', request2);

        notifier.clearResponse('tab-1');

        expect(notifier.getResponse('tab-1'), isNull);
        expect(notifier.getResponse('tab-2'), isNotNull);
      });

      test('should do nothing for non-existent tab', () async {
        final request = HttpRequest.empty().copyWith(id: 'req-1');

        when(mockHttpService.sendRequest(request))
            .thenAnswer((_) async => HttpResponse(statusCode: 200));

        await notifier.sendRequest('tab-1', request);
        notifier.clearResponse('non-existent');

        expect(notifier.getResponse('tab-1'), isNotNull);
      });
    });

    group('clearAll', () {
      test('should remove all responses', () async {
        final request1 = HttpRequest.empty().copyWith(id: 'req-1');
        final request2 = HttpRequest.empty().copyWith(id: 'req-2');

        when(mockHttpService.sendRequest(any))
            .thenAnswer((_) async => HttpResponse(statusCode: 200));

        await notifier.sendRequest('tab-1', request1);
        await notifier.sendRequest('tab-2', request2);

        notifier.clearAll();

        expect(notifier.state, isEmpty);
        expect(notifier.getResponse('tab-1'), isNull);
        expect(notifier.getResponse('tab-2'), isNull);
      });

      test('should work when no responses exist', () {
        notifier.clearAll();

        expect(notifier.state, isEmpty);
      });
    });
  });

  group('requestResponseProvider', () {
    test('should create notifier with HttpService from provider', () {
      final mockHttpService = MockHttpService();
      final container = ProviderContainer(
        overrides: [
          httpServiceProvider.overrideWithValue(mockHttpService),
        ],
      );

      final notifier = container.read(requestResponseProvider.notifier);

      expect(notifier, isA<RequestResponseNotifier>());
    });
  });

  group('currentResponseProvider', () {
    test('should return null when no active tab', () {
      final mockHttpService = MockHttpService();
      final container = ProviderContainer(
        overrides: [
          httpServiceProvider.overrideWithValue(mockHttpService),
        ],
      );

      expect(container.read(currentResponseProvider), isNull);
    });

    test('should return null when no response for active tab', () {
      final mockHttpService = MockHttpService();
      final container = ProviderContainer(
        overrides: [
          httpServiceProvider.overrideWithValue(mockHttpService),
        ],
      );

      container.read(activeTabIdProvider.notifier).state = 'tab-1';

      expect(container.read(currentResponseProvider), isNull);
    });

    test('should return response for active tab', () async {
      final mockHttpService = MockHttpService();
      final container = ProviderContainer(
        overrides: [
          httpServiceProvider.overrideWithValue(mockHttpService),
        ],
      );

      final request = HttpRequest.empty().copyWith(id: 'req-1');
      final response = HttpResponse(statusCode: 200, body: 'OK');

      when(mockHttpService.sendRequest(request))
          .thenAnswer((_) async => response);

      container.read(requestTabProvider.notifier).openTab(request);
      container.read(activeTabIdProvider.notifier).state = 'req-1';
      await container
          .read(requestResponseProvider.notifier)
          .sendRequest('req-1', request);

      expect(container.read(currentResponseProvider), equals(response));
    });

    test('should update when active tab changes', () async {
      final mockHttpService = MockHttpService();
      final container = ProviderContainer(
        overrides: [
          httpServiceProvider.overrideWithValue(mockHttpService),
        ],
      );

      final request1 = HttpRequest.empty().copyWith(id: 'req-1');
      final request2 = HttpRequest.empty().copyWith(id: 'req-2');
      final response1 = HttpResponse(statusCode: 200, body: 'Response 1');
      final response2 = HttpResponse(statusCode: 201, body: 'Response 2');

      when(mockHttpService.sendRequest(request1))
          .thenAnswer((_) async => response1);
      when(mockHttpService.sendRequest(request2))
          .thenAnswer((_) async => response2);

      container.read(requestTabProvider.notifier).openTab(request1);
      container.read(requestTabProvider.notifier).openTab(request2);

      await container
          .read(requestResponseProvider.notifier)
          .sendRequest('req-1', request1);
      await container
          .read(requestResponseProvider.notifier)
          .sendRequest('req-2', request2);

      container.read(activeTabIdProvider.notifier).state = 'req-1';
      expect(container.read(currentResponseProvider), equals(response1));

      container.read(activeTabIdProvider.notifier).state = 'req-2';
      expect(container.read(currentResponseProvider), equals(response2));
    });
  });
}
