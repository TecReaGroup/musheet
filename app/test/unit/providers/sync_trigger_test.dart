/// Sync Trigger Tests
///
/// Tests to verify that data changes trigger sync correctly.
///
/// BUG: After adding setlist or score, sync is not triggered
/// Root cause: onDataChanged callback checks isInitialized at provider creation time
/// If repository is created before SyncCoordinator is initialized, callback is never set
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BUG: Sync not triggered after data changes [Source Analysis]', () {
    late String setlistsProviderSource;
    late String scoresProviderSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      setlistsProviderSource = File(
        '$projectRoot/lib/providers/setlists_state_provider.dart',
      ).readAsStringSync();
      scoresProviderSource = File(
        '$projectRoot/lib/providers/scores_state_provider.dart',
      ).readAsStringSync();
    });

    test('BUG DETECTION: Repository provider should NOT use autoDispose', () {
      // Repository should persist to maintain consistent instance
      final setlistRepoNoAutoDispose = !setlistsProviderSource.contains(
          'Provider.autoDispose.family<SetlistRepository');

      final scoreRepoNoAutoDispose = !scoresProviderSource.contains(
          'Provider.autoDispose.family<ScoreRepository');

      expect(
        setlistRepoNoAutoDispose,
        isTrue,
        reason: 'SetlistRepository provider should NOT use autoDispose.',
      );

      expect(
        scoreRepoNoAutoDispose,
        isTrue,
        reason: 'ScoreRepository provider should NOT use autoDispose.',
      );
    });

    test('BUG DETECTION: onDataChanged must check isInitialized at CALL time, not creation time', () {
      // The bug: callback is set like this:
      //   if (SyncCoordinator.isInitialized) {
      //     repo.onDataChanged = () => SyncCoordinator.instance.onLocalDataChanged();
      //   }
      //
      // This checks isInitialized when provider is CREATED.
      // If provider is created before SyncCoordinator, callback is never set!
      //
      // The fix: callback should check isInitialized when CALLED:
      //   repo.onDataChanged = () {
      //     if (SyncCoordinator.isInitialized) {
      //       SyncCoordinator.instance.onLocalDataChanged();
      //     }
      //   };

      // Check if the callback is set unconditionally (checks at call time)
      // Good pattern: repo.onDataChanged = () { if (isInitialized) ... }
      // Bad pattern: if (isInitialized) { repo.onDataChanged = () => ... }

      // For setlist provider - check if onDataChanged is ALWAYS set
      final setlistAlwaysSetsCallback = setlistsProviderSource.contains(
          'repo.onDataChanged = ()') &&
          !setlistsProviderSource.contains(
              'if (SyncCoordinator.isInitialized) {\n      repo.onDataChanged');

      expect(
        setlistAlwaysSetsCallback,
        isTrue,
        reason: 'BUG DETECTED: onDataChanged callback should be set unconditionally. '
            'The isInitialized check should be INSIDE the callback, not outside. '
            'Current pattern checks at creation time, but SyncCoordinator may not be ready yet.',
      );
    });

    test('FIX VERIFICATION: Callback checks isInitialized inside the lambda', () {
      // The fix should look like:
      // repo.onDataChanged = () {
      //   if (SyncCoordinator.isInitialized) {
      //     SyncCoordinator.instance.onLocalDataChanged();
      //   }
      // };

      // Check for the correct pattern
      final setlistHasCorrectPattern = setlistsProviderSource.contains(
          'if (SyncCoordinator.isInitialized)') &&
          setlistsProviderSource.contains('SyncCoordinator.instance.onLocalDataChanged()');

      final scoresHasCorrectPattern = scoresProviderSource.contains(
          'if (SyncCoordinator.isInitialized)') &&
          scoresProviderSource.contains('SyncCoordinator.instance.onLocalDataChanged()');

      expect(
        setlistHasCorrectPattern,
        isTrue,
        reason: 'Setlist provider should check SyncCoordinator.isInitialized inside callback.',
      );

      expect(
        scoresHasCorrectPattern,
        isTrue,
        reason: 'Scores provider should check SyncCoordinator.isInitialized inside callback.',
      );
    });
  });
}
