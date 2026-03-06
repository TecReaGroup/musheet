library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/data/data_scope.dart';
import 'package:musheet/providers/ui_state_providers.dart';

void main() {
  group('ui_state_providers', () {
    test('scoped sort provider keeps independent state per scope and entity', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final userScores = scopedSortProvider((DataScope.user, 'scores'));
      final teamScores = scopedSortProvider((DataScope.team(1), 'scores'));
      final userSetlists = scopedSortProvider((DataScope.user, 'setlists'));

      expect(container.read(userScores), const SortState());
      expect(container.read(teamScores), const SortState());
      expect(container.read(userSetlists), const SortState());

      container.read(userScores.notifier).setSort(SortType.alphabetical);

      expect(
        container.read(userScores),
        const SortState(type: SortType.alphabetical, ascending: true),
      );
      expect(container.read(teamScores), const SortState());
      expect(container.read(userSetlists), const SortState());
    });

    test('bool state notifier supports show hide and toggle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = boolStateProvider('test_modal');

      expect(container.read(provider), isFalse);

      container.read(provider.notifier).show();
      expect(container.read(provider), isTrue);

      container.read(provider.notifier).toggle();
      expect(container.read(provider), isFalse);

      container.read(provider.notifier).hide();
      expect(container.read(provider), isFalse);
    });

    test('tab providers update through setTab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(libraryTabProvider), LibraryTab.setlists);
      expect(container.read(teamTabProvider), TeamTab.setlists);

      container.read(libraryTabProvider.notifier).setTab(LibraryTab.scores);
      container.read(teamTabProvider.notifier).setTab(TeamTab.members);

      expect(container.read(libraryTabProvider), LibraryTab.scores);
      expect(container.read(teamTabProvider), TeamTab.members);
    });

    test('search and transient ui providers expose shared mutable state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(searchQueryProvider), '');
      expect(container.read(searchScopeProvider), SearchScope.library);
      expect(container.read(hasUnreadNotificationsProvider), isFalse);
      expect(container.read(clearSearchRequestProvider), 0);
      expect(container.read(sharedFilePathProvider), isNull);

      container.read(searchQueryProvider.notifier).setQuery('hallelujah');
      container.read(searchScopeProvider.notifier).setScope(SearchScope.team);
      container
          .read(hasUnreadNotificationsProvider.notifier)
          .setHasUnreadNotifications(true);
      container.read(clearSearchRequestProvider.notifier).trigger();
      container
          .read(sharedFilePathProvider.notifier)
          .setPath('/tmp/import.pdf');

      expect(container.read(searchQueryProvider), 'hallelujah');
      expect(container.read(searchScopeProvider), SearchScope.team);
      expect(container.read(hasUnreadNotificationsProvider), isTrue);
      expect(container.read(clearSearchRequestProvider), 1);
      expect(container.read(sharedFilePathProvider), '/tmp/import.pdf');

      container.read(searchQueryProvider.notifier).clear();
      container.read(sharedFilePathProvider.notifier).clear();

      expect(container.read(searchQueryProvider), '');
      expect(container.read(sharedFilePathProvider), isNull);
    });

    test('user-facing recent aliases map to scoped providers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final scopedSetlists = scopedRecentlyOpenedProvider((
        DataScope.user,
        'setlists',
      ));
      final scopedScores = scopedRecentlyOpenedProvider((
        DataScope.user,
        'scores',
      ));
      final scopedLastOpened = scopedLastOpenedIndexProvider((
        DataScope.user,
        'scoreInSetlist',
      ));

      container.read(recentlyOpenedSetlistsProvider.notifier).recordOpen('set-1');
      container.read(recentlyOpenedScoresProvider.notifier).recordOpen('score-1');
      container
          .read(lastOpenedScoreInSetlistProvider.notifier)
          .recordLastOpened('set-1', 2);

      expect(
        container.read(scopedSetlists).containsKey('set-1'),
        isTrue,
      );
      expect(
        container.read(scopedScores).containsKey('score-1'),
        isTrue,
      );
      expect(container.read(scopedLastOpened)['set-1'], 2);

      container.read(scopedSetlists.notifier).recordOpen('set-2');
      container.read(scopedScores.notifier).recordOpen('score-2');
      container.read(scopedLastOpened.notifier).recordLastOpened('set-2', 4);

      expect(
        container.read(recentlyOpenedSetlistsProvider).containsKey('set-2'),
        isTrue,
      );
      expect(
        container.read(recentlyOpenedScoresProvider).containsKey('score-2'),
        isTrue,
      );
      expect(container.read(lastOpenedScoreInSetlistProvider)['set-2'], 4);
    });

    test('scoped recent and last-opened providers remain isolated per scope', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final userRecent = scopedRecentlyOpenedProvider((DataScope.user, 'scores'));
      final teamRecent = scopedRecentlyOpenedProvider((DataScope.team(7), 'scores'));
      final userIndex = scopedLastOpenedIndexProvider((
        DataScope.user,
        'scoreInSetlist',
      ));
      final teamIndex = scopedLastOpenedIndexProvider((
        DataScope.team(7),
        'scoreInSetlist',
      ));

      container.read(userRecent.notifier).recordOpen('score-user');
      container.read(teamRecent.notifier).recordOpen('score-team');
      container.read(userIndex.notifier).recordLastOpened('set-user', 1);
      container.read(teamIndex.notifier).recordLastOpened('set-team', 3);

      expect(container.read(userRecent).containsKey('score-user'), isTrue);
      expect(container.read(userRecent).containsKey('score-team'), isFalse);
      expect(container.read(teamRecent).containsKey('score-team'), isTrue);
      expect(container.read(userIndex)['set-user'], 1);
      expect(container.read(userIndex)['set-team'], isNull);
      expect(container.read(teamIndex)['set-team'], 3);
    });
  });
}
