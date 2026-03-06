/// SetlistRepository Tests
///
/// Tests for SetlistRepository with mocked LocalDataSource.
/// Covers CRUD operations, score management within setlists, and sync triggers.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musheet/core/repositories/setlist_repository.dart';
import 'package:musheet/core/data/local/local_data_source.dart';

import '../../mocks/mocks.dart';
import '../../fixtures/test_fixtures.dart';

void main() {
  late MockLocalDataSource mockLocalDataSource;
  late SetlistRepository setlistRepository;
  late bool onDataChangedCalled;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    mockLocalDataSource.setupDefaultBehaviors();

    onDataChangedCalled = false;

    setlistRepository = SetlistRepository(local: mockLocalDataSource);
    setlistRepository.onDataChanged = () {
      onDataChangedCalled = true;
    };
  });

  group('SetlistRepository Read Operations', () {
    test('getAllSetlists returns setlists from local data source', () async {
      // Arrange
      final expectedSetlists = TestFixtures.sampleSetlistList;
      when(() => mockLocalDataSource.getAllSetlists())
          .thenAnswer((_) async => expectedSetlists);

      // Act
      final result = await setlistRepository.getAllSetlists();

      // Assert
      expect(result, equals(expectedSetlists));
      expect(result.length, equals(2));
      verify(() => mockLocalDataSource.getAllSetlists()).called(1);
    });

    test('getAllSetlists returns empty list when no setlists', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllSetlists())
          .thenAnswer((_) async => []);

      // Act
      final result = await setlistRepository.getAllSetlists();

      // Assert
      expect(result, isEmpty);
    });

    test('getSetlistById returns setlist when found', () async {
      // Arrange
      final expectedSetlist = TestFixtures.sampleSetlist;
      when(() => mockLocalDataSource.getSetlistById('setlist_1'))
          .thenAnswer((_) async => expectedSetlist);

      // Act
      final result = await setlistRepository.getSetlistById('setlist_1');

      // Assert
      expect(result, equals(expectedSetlist));
      expect(result?.name, equals('Concert Setlist'));
    });

    test('getSetlistById returns null when not found', () async {
      // Arrange
      when(() => mockLocalDataSource.getSetlistById('nonexistent'))
          .thenAnswer((_) async => null);

      // Act
      final result = await setlistRepository.getSetlistById('nonexistent');

      // Assert
      expect(result, isNull);
    });

    test('watchAllSetlists returns stream from local data source', () async {
      // Arrange
      final expectedSetlists = TestFixtures.sampleSetlistList;
      when(() => mockLocalDataSource.watchAllSetlists())
          .thenAnswer((_) => Stream.value(expectedSetlists));

      // Act
      final stream = setlistRepository.watchAllSetlists();
      final result = await stream.first;

      // Assert
      expect(result, equals(expectedSetlists));
    });
  });

  group('SetlistRepository Write Operations', () {
    test('addSetlist inserts setlist with pending status', () async {
      // Arrange
      final setlist = TestFixtures.sampleSetlist;

      // Act
      await setlistRepository.addSetlist(setlist);

      // Assert
      verify(() => mockLocalDataSource.insertSetlist(
            setlist,
            status: LocalSyncStatus.pending,
          )).called(1);
    });

    test('addSetlist triggers onDataChanged callback', () async {
      // Arrange
      final setlist = TestFixtures.sampleSetlist;

      // Act
      await setlistRepository.addSetlist(setlist);

      // Assert
      expect(onDataChangedCalled, isTrue);
    });

    test('updateSetlist updates setlist with pending status', () async {
      // Arrange
      final setlist = TestFixtures.sampleSetlist;

      // Act
      await setlistRepository.updateSetlist(setlist);

      // Assert
      verify(() => mockLocalDataSource.updateSetlist(
            setlist,
            status: LocalSyncStatus.pending,
          )).called(1);
    });

    test('updateSetlist triggers onDataChanged callback', () async {
      // Arrange
      final setlist = TestFixtures.sampleSetlist;

      // Act
      await setlistRepository.updateSetlist(setlist);

      // Assert
      expect(onDataChangedCalled, isTrue);
    });

    test('deleteSetlist deletes setlist from local data source', () async {
      // Act
      await setlistRepository.deleteSetlist('setlist_1');

      // Assert
      verify(() => mockLocalDataSource.deleteSetlist('setlist_1')).called(1);
    });

    test('deleteSetlist triggers onDataChanged callback', () async {
      // Act
      await setlistRepository.deleteSetlist('setlist_1');

      // Assert
      expect(onDataChangedCalled, isTrue);
    });
  });

  group('SetlistRepository Score Management', () {
    test('addScoreToSetlist adds score to existing setlist', () async {
      // Arrange
      final setlist = TestFixtures.createSetlist(
        id: 'setlist_1',
        name: 'Test',
        scoreIds: ['score_1'],
      );
      when(() => mockLocalDataSource.getSetlistById('setlist_1'))
          .thenAnswer((_) async => setlist);

      // Act
      await setlistRepository.addScoreToSetlist('setlist_1', 'score_2');

      // Assert
      verify(() => mockLocalDataSource.updateSetlist(
            any(that: predicate<dynamic>((s) =>
                s.scoreIds.contains('score_1') &&
                s.scoreIds.contains('score_2'))),
            status: LocalSyncStatus.pending,
          )).called(1);
    });

    test('addScoreToSetlist does not add duplicate score', () async {
      // Arrange
      final setlist = TestFixtures.createSetlist(
        id: 'setlist_1',
        name: 'Test',
        scoreIds: ['score_1', 'score_2'],
      );
      when(() => mockLocalDataSource.getSetlistById('setlist_1'))
          .thenAnswer((_) async => setlist);

      // Act
      await setlistRepository.addScoreToSetlist('setlist_1', 'score_1');

      // Assert
      verifyNever(() => mockLocalDataSource.updateSetlist(
            any(),
            status: any(named: 'status'),
          ));
    });

    test('addScoreToSetlist does nothing if setlist not found', () async {
      // Arrange
      when(() => mockLocalDataSource.getSetlistById('nonexistent'))
          .thenAnswer((_) async => null);

      // Act
      await setlistRepository.addScoreToSetlist('nonexistent', 'score_1');

      // Assert
      verifyNever(() => mockLocalDataSource.updateSetlist(
            any(),
            status: any(named: 'status'),
          ));
      expect(onDataChangedCalled, isFalse);
    });

    test('addScoreToSetlist triggers onDataChanged when score added', () async {
      // Arrange
      final setlist = TestFixtures.createSetlist(
        id: 'setlist_1',
        name: 'Test',
        scoreIds: [],
      );
      when(() => mockLocalDataSource.getSetlistById('setlist_1'))
          .thenAnswer((_) async => setlist);

      // Act
      await setlistRepository.addScoreToSetlist('setlist_1', 'score_1');

      // Assert
      expect(onDataChangedCalled, isTrue);
    });

    test('removeScoreFromSetlist removes score from setlist', () async {
      // Arrange
      final setlist = TestFixtures.createSetlist(
        id: 'setlist_1',
        name: 'Test',
        scoreIds: ['score_1', 'score_2', 'score_3'],
      );
      when(() => mockLocalDataSource.getSetlistById('setlist_1'))
          .thenAnswer((_) async => setlist);

      // Act
      await setlistRepository.removeScoreFromSetlist('setlist_1', 'score_2');

      // Assert
      verify(() => mockLocalDataSource.updateSetlist(
            any(that: predicate<dynamic>((s) =>
                s.scoreIds.contains('score_1') &&
                !s.scoreIds.contains('score_2') &&
                s.scoreIds.contains('score_3'))),
            status: LocalSyncStatus.pending,
          )).called(1);
    });

    test('removeScoreFromSetlist does nothing if setlist not found', () async {
      // Arrange
      when(() => mockLocalDataSource.getSetlistById('nonexistent'))
          .thenAnswer((_) async => null);

      // Act
      await setlistRepository.removeScoreFromSetlist('nonexistent', 'score_1');

      // Assert
      verifyNever(() => mockLocalDataSource.updateSetlist(
            any(),
            status: any(named: 'status'),
          ));
    });

    test('removeScoreFromSetlist triggers onDataChanged', () async {
      // Arrange
      final setlist = TestFixtures.createSetlist(
        id: 'setlist_1',
        name: 'Test',
        scoreIds: ['score_1'],
      );
      when(() => mockLocalDataSource.getSetlistById('setlist_1'))
          .thenAnswer((_) async => setlist);

      // Act
      await setlistRepository.removeScoreFromSetlist('setlist_1', 'score_1');

      // Assert
      expect(onDataChangedCalled, isTrue);
    });

    test('reorderScores updates score order in setlist', () async {
      // Arrange
      final setlist = TestFixtures.createSetlist(
        id: 'setlist_1',
        name: 'Test',
        scoreIds: ['score_1', 'score_2', 'score_3'],
      );
      when(() => mockLocalDataSource.getSetlistById('setlist_1'))
          .thenAnswer((_) async => setlist);

      final newOrder = ['score_3', 'score_1', 'score_2'];

      // Act
      await setlistRepository.reorderScores('setlist_1', newOrder);

      // Assert
      verify(() => mockLocalDataSource.updateSetlist(
            any(that: predicate<dynamic>((s) =>
                s.scoreIds[0] == 'score_3' &&
                s.scoreIds[1] == 'score_1' &&
                s.scoreIds[2] == 'score_2')),
            status: LocalSyncStatus.pending,
          )).called(1);
    });

    test('reorderScores does nothing if setlist not found', () async {
      // Arrange
      when(() => mockLocalDataSource.getSetlistById('nonexistent'))
          .thenAnswer((_) async => null);

      // Act
      await setlistRepository.reorderScores(
          'nonexistent', ['score_1', 'score_2']);

      // Assert
      verifyNever(() => mockLocalDataSource.updateSetlist(
            any(),
            status: any(named: 'status'),
          ));
    });

    test('reorderScores triggers onDataChanged', () async {
      // Arrange
      final setlist = TestFixtures.createSetlist(
        id: 'setlist_1',
        name: 'Test',
        scoreIds: ['score_1', 'score_2'],
      );
      when(() => mockLocalDataSource.getSetlistById('setlist_1'))
          .thenAnswer((_) async => setlist);

      // Act
      await setlistRepository.reorderScores(
          'setlist_1', ['score_2', 'score_1']);

      // Assert
      expect(onDataChangedCalled, isTrue);
    });
  });

  group('SetlistRepository Edge Cases', () {
    test('onDataChanged is not called when callback is null', () async {
      // Arrange
      final repo = SetlistRepository(local: mockLocalDataSource);
      // Don't set onDataChanged callback

      // Act & Assert - should not throw
      await repo.addSetlist(TestFixtures.sampleSetlist);
    });

    test('multiple operations trigger onDataChanged for each', () async {
      // Arrange
      int callCount = 0;
      setlistRepository.onDataChanged = () {
        callCount++;
      };

      // Act
      await setlistRepository.addSetlist(TestFixtures.sampleSetlist);
      await setlistRepository.updateSetlist(TestFixtures.sampleSetlist);
      await setlistRepository.deleteSetlist('setlist_1');

      // Assert
      expect(callCount, equals(3));
    });

    test('operations work with empty scoreIds list', () async {
      // Arrange
      final emptySetlist = TestFixtures.createSetlist(
        id: 'empty_setlist',
        name: 'Empty',
        scoreIds: [],
      );

      // Act
      await setlistRepository.addSetlist(emptySetlist);

      // Assert
      verify(() => mockLocalDataSource.insertSetlist(
            emptySetlist,
            status: LocalSyncStatus.pending,
          )).called(1);
    });
  });
}
