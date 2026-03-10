import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hopp/models/http_request.dart';

import 'package:hopp/providers/request/request_tab_provider.dart';

void main() {
  group('RequestTabNotifier', () {
    late ProviderContainer container;
    late RequestTabNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(requestTabProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('openTab', () {
      test('should open a new tab when request is not in tabs', () {
        final request = HttpRequest.empty().copyWith(id: 'req-1');

        notifier.openTab(request);

        final tabs = container.read(requestTabProvider);
        expect(tabs.length, equals(1));
        expect(tabs.first.id, equals('req-1'));
        expect(tabs.first.isDirty, isFalse);
      });

      test('should not duplicate tab when request already exists', () {
        final request = HttpRequest.empty().copyWith(id: 'req-1');

        notifier.openTab(request);
        notifier.openTab(request);

        final tabs = container.read(requestTabProvider);
        expect(tabs.length, equals(1));
      });

      test('should update lastAccessed when reopening existing tab', () async {
        final request = HttpRequest.empty().copyWith(id: 'req-1');

        notifier.openTab(request);
        final firstAccessed =
            container.read(requestTabProvider).first.lastAccessed;

        await Future<void>.delayed(const Duration(milliseconds: 10));
        notifier.openTab(request);
        final secondAccessed =
            container.read(requestTabProvider).first.lastAccessed;

        expect(secondAccessed, isNot(equals(firstAccessed)));
      });
    });

    group('closeTab', () {
      test('should close specific tab', () {
        final request1 = HttpRequest.empty().copyWith(id: 'req-1');
        final request2 = HttpRequest.empty().copyWith(id: 'req-2');

        notifier.openTab(request1);
        notifier.openTab(request2);
        notifier.closeTab('req-1');

        final tabs = container.read(requestTabProvider);
        expect(tabs.length, equals(1));
        expect(tabs.first.id, equals('req-2'));
      });

      test('should do nothing when tab id does not exist', () {
        final request = HttpRequest.empty().copyWith(id: 'req-1');

        notifier.openTab(request);
        notifier.closeTab('non-existent');

        final tabs = container.read(requestTabProvider);
        expect(tabs.length, equals(1));
      });
    });

    group('closeAllTabs', () {
      test('should close all tabs', () {
        final request1 = HttpRequest.empty().copyWith(id: 'req-1');
        final request2 = HttpRequest.empty().copyWith(id: 'req-2');
        final request3 = HttpRequest.empty().copyWith(id: 'req-3');

        notifier.openTab(request1);
        notifier.openTab(request2);
        notifier.openTab(request3);
        notifier.closeAllTabs();

        final tabs = container.read(requestTabProvider);
        expect(tabs.length, equals(0));
      });

      test('should work when no tabs are open', () {
        notifier.closeAllTabs();

        final tabs = container.read(requestTabProvider);
        expect(tabs.length, equals(0));
      });
    });

    group('closeOtherTabs', () {
      test('should close all tabs except specified one', () {
        final request1 = HttpRequest.empty().copyWith(id: 'req-1');
        final request2 = HttpRequest.empty().copyWith(id: 'req-2');
        final request3 = HttpRequest.empty().copyWith(id: 'req-3');

        notifier.openTab(request1);
        notifier.openTab(request2);
        notifier.openTab(request3);
        notifier.closeOtherTabs('req-2');

        final tabs = container.read(requestTabProvider);
        expect(tabs.length, equals(1));
        expect(tabs.first.id, equals('req-2'));
      });

      test('should close all tabs when specified tab does not exist', () {
        final request1 = HttpRequest.empty().copyWith(id: 'req-1');
        final request2 = HttpRequest.empty().copyWith(id: 'req-2');

        notifier.openTab(request1);
        notifier.openTab(request2);
        notifier.closeOtherTabs('non-existent');

        final tabs = container.read(requestTabProvider);
        expect(tabs.length, equals(0));
      });
    });

    group('updateRequest', () {
      test('should update request and mark as dirty', () {
        final request = HttpRequest.empty().copyWith(
          id: 'req-1',
          name: 'Original Name',
          url: 'https://original.com',
        );

        notifier.openTab(request);

        final updatedRequest = request.copyWith(
          name: 'Updated Name',
          url: 'https://updated.com',
        );

        notifier.updateRequest('req-1', updatedRequest);

        final tabs = container.read(requestTabProvider);
        expect(tabs.first.request.name, equals('Updated Name'));
        expect(tabs.first.request.url, equals('https://updated.com'));
        expect(tabs.first.isDirty, isTrue);
      });

      test('should not update other tabs', () {
        final request1 = HttpRequest.empty().copyWith(id: 'req-1');
        final request2 = HttpRequest.empty().copyWith(id: 'req-2');

        notifier.openTab(request1);
        notifier.openTab(request2);

        final updatedRequest = request1.copyWith(name: 'Updated');
        notifier.updateRequest('req-1', updatedRequest);

        final tabs = container.read(requestTabProvider);
        final tab2 = tabs.firstWhere((t) => t.id == 'req-2');
        expect(tab2.request.name, equals('New Request'));
        expect(tab2.isDirty, isFalse);
      });
    });

    group('markAsSaved', () {
      test('should mark tab as not dirty', () {
        final request = HttpRequest.empty().copyWith(id: 'req-1');

        notifier.openTab(request);
        notifier.updateRequest('req-1', request.copyWith(name: 'Updated'));

        expect(container.read(requestTabProvider).first.isDirty, isTrue);

        notifier.markAsSaved('req-1');

        expect(container.read(requestTabProvider).first.isDirty, isFalse);
      });

      test('should not affect other tabs', () {
        final request1 = HttpRequest.empty().copyWith(id: 'req-1');
        final request2 = HttpRequest.empty().copyWith(id: 'req-2');

        notifier.openTab(request1);
        notifier.openTab(request2);
        notifier.updateRequest('req-1', request1.copyWith(name: 'Updated'));
        notifier.updateRequest('req-2', request2.copyWith(name: 'Updated'));

        notifier.markAsSaved('req-1');

        final tabs = container.read(requestTabProvider);
        final tab1 = tabs.firstWhere((t) => t.id == 'req-1');
        final tab2 = tabs.firstWhere((t) => t.id == 'req-2');

        expect(tab1.isDirty, isFalse);
        expect(tab2.isDirty, isTrue);
      });
    });

    group('getTab', () {
      test('should return tab by id', () {
        final request = HttpRequest.empty().copyWith(id: 'req-1');

        notifier.openTab(request);

        final tab = notifier.getTab('req-1');
        expect(tab, isNotNull);
        expect(tab!.id, equals('req-1'));
      });

      test('should return null when tab does not exist', () {
        final tab = notifier.getTab('non-existent');
        expect(tab, isNull);
      });
    });

    group('tabCount', () {
      test('should return 0 when no tabs are open', () {
        expect(notifier.tabCount, equals(0));
      });

      test('should return correct count of open tabs', () {
        final request1 = HttpRequest.empty().copyWith(id: 'req-1');
        final request2 = HttpRequest.empty().copyWith(id: 'req-2');

        expect(notifier.tabCount, equals(0));

        notifier.openTab(request1);
        expect(notifier.tabCount, equals(1));

        notifier.openTab(request2);
        expect(notifier.tabCount, equals(2));

        notifier.closeTab('req-1');
        expect(notifier.tabCount, equals(1));
      });
    });
  });

  group('activeTabIdProvider', () {
    test('should be null initially', () {
      final container = ProviderContainer();

      expect(container.read(activeTabIdProvider), isNull);
    });

    test('should update active tab id', () {
      final container = ProviderContainer();

      container.read(activeTabIdProvider.notifier).state = 'tab-1';

      expect(container.read(activeTabIdProvider), equals('tab-1'));
    });
  });

  group('activeTabProvider', () {
    test('should return null when no active tab id', () {
      final container = ProviderContainer();

      expect(container.read(activeTabProvider), isNull);
    });

    test('should return null when active tab id does not exist in tabs', () {
      final container = ProviderContainer();
      container.read(requestTabProvider.notifier);

      container.read(activeTabIdProvider.notifier).state = 'non-existent';

      expect(container.read(activeTabProvider), isNull);
    });

    test('should return active tab', () {
      final container = ProviderContainer();
      final notifier = container.read(requestTabProvider.notifier);
      final request = HttpRequest.empty().copyWith(id: 'req-1');

      notifier.openTab(request);
      container.read(activeTabIdProvider.notifier).state = 'req-1';

      final activeTab = container.read(activeTabProvider);
      expect(activeTab, isNotNull);
      expect(activeTab!.id, equals('req-1'));
    });

    test('should update when active tab id changes', () {
      final container = ProviderContainer();
      final notifier = container.read(requestTabProvider.notifier);
      final request1 = HttpRequest.empty().copyWith(id: 'req-1');
      final request2 = HttpRequest.empty().copyWith(id: 'req-2');

      notifier.openTab(request1);
      notifier.openTab(request2);

      container.read(activeTabIdProvider.notifier).state = 'req-1';
      expect(container.read(activeTabProvider)!.id, equals('req-1'));

      container.read(activeTabIdProvider.notifier).state = 'req-2';
      expect(container.read(activeTabProvider)!.id, equals('req-2'));
    });
  });
}
