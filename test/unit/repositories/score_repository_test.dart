/// ScoreRepository Tests
///
/// Tests for ScoreRepository with mocked LocalDataSource.
/// Covers CRUD operations, sync triggers, and edge cases.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musheet/core/repositories/score_repository.dart';
import 'package:musheet/core/data/local/local_data_source.dart';

import '../../mocks/mocks.dart';
import '../../fixtures/test_fixtures.dart';

void main() {
  late MockLocalDataSource mockLocalDataSource;
  late ScoreRepository scoreRepository;
  late bool onDataChangedCalled;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    mockLocalDataSource.setupDefaultBehaviors();

    onDataChangedCalled = false;

    scoreRepository = ScoreRepository(local: mockLocalDataSource);
    scoreRepository.onDataChanged = () {
      onDataChangedCalled = true;
    };
  });

  group('ScoreRepository Read Operations', () {
    test('getAllScores returns scores from local data source', () async {
      // Arrange
      final expectedScores = TestFixtures.sampleScoreList;
      when(() => mockLocalDataSource.getAllScores())
          .thenAnswer((_) async => expectedScores);

      // Act
      final result = await scoreRepository.getAllScores();

      // Assert
      expect(result, equals(expectedScores));
      expect(result.length, equals(3));
      verify(() => mockLocalDataSource.getAllScores()).called(1);
    });

    test('getAllScores returns empty list when no scores', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllScores())
          .thenAnswer((_) async => []);

      // Act
      final result = await scoreRepository.getAllScores();

      // Assert
      expect(result, isEmpty);
    });

    test('getScoreById returns score when found', () async {
      // Arrange
      final expectedScore = TestFixtures.sampleScore;
      when(() => mockLocalDataSource.getScoreById('score_1'))
          .thenAnswer((_) async => expectedScore);

      // Act
      final result = await scoreRepository.getScoreById('score_1');

      // Assert
      expect(result, equals(expectedScore));
      expect(result?.title, equals('Symphony No. 5'));
    });

    test('getScoreById returns null when not found', () async {
      // Arrange
      when(() => mockLocalDataSource.getScoreById('nonexistent'))
          .thenAnswer((_) async => null);

      // Act
      final result = await scoreRepository.getScoreById('nonexistent');

      // Assert
      expect(result, isNull);
    });

    test('watchAllScores returns stream from local data source', () async {
      // Arrange
      final expectedScores = TestFixtures.sampleScoreList;
      when(() => mockLocalDataSource.watchAllScores())
          .thenAnswer((_) => Stream.value(expectedScores));

      // Act
      final stream = scoreRepository.watchAllScores();
      final result = await stream.first;

      // Assert
      expect(result, equals(expectedScores));
    });

    test('findByTitleAndComposer returns matching score', () async {
      // Arrange
      final scores = [
        TestFixtures.createScore(
          id: 'score_1',
          title: 'Symphony No. 5',
          composer: 'Beethoven',
        ),
        TestFixtures.createScore(
          id: 'score_2',
          title: 'Moonlight Sonata',
          composer: 'Beethoven',
        ),
      ];
      when(() => mockLocalDataSource.getAllScores())
          .thenAnswer((_) async => scores);

      // Act
      final result = await scoreRepository.findByTitleAndComposer(
        'Symphony No. 5',
        'Beethoven',
      );

      // Assert
      expect(result, isNotNull);
      expect(result?.id, equals('score_1'));
    });

    test('findByTitleAndComposer returns null when not found', () async {
      // Arrange
      when(() => mockLocalDataSource.getAllScores())
          .thenAnswer((_) async => []);

      // Act
      final result = await scoreRepository.findByTitleAndComposer(
        'Nonexistent',
        'Unknown',
      );

      // Assert
      expect(result, isNull);
    });

    test('getSuggestionsByTitle returns matching scores', () async {
      // Arrange
      final scores = [
        TestFixtures.createScore(id: 's1', title: 'Symphony No. 5'),
        TestFixtures.createScore(id: 's2', title: 'Symphony No. 9'),
        TestFixtures.createScore(id: 's3', title: 'Moonlight Sonata'),
        TestFixtures.createScore(id: 's4', title: 'Spring Symphony'),
      ];
      when(() => mockLocalDataSource.getAllScores())
          .thenAnswer((_) async => scores);

      // Act
      final result = await scoreRepository.getSuggestionsByTitle('Symphony');

      // Assert
      expect(result.length, equals(3)); // Limited to 3
      expect(result.every((s) => s.title.toLowerCase().contains('symphony')),
          isTrue);
    });

    test('getSuggestionsByTitle returns empty for empty query', () async {
      // Act
      final result = await scoreRepository.getSuggestionsByTitle('');

      // Assert
      expect(result, isEmpty);
      verifyNever(() => mockLocalDataSource.getAllScores());
    });
  });

  group('ScoreRepository Write Operations', () {
    test('addScore inserts score with pending status', () async {
      // Arrange
      final score = TestFixtures.sampleScore;

      // Act
      await scoreRepository.addScore(score);

      // Assert
      verify(() => mockLocalDataSource.insertScore(
            score,
            status: LocalSyncStatus.pending,
          )).called(1);
    });

    test('addScore triggers onDataChanged callback', () async {
      // Arrange
      final score = TestFixtures.sampleScore;

      // Act
      await scoreRepository.addScore(score);

      // Assert
      expect(onDataChangedCalled, isTrue);
    });

    test('updateScore updates score with pending status', () async {
      // Arrange
      final score = TestFixtures.sampleScore;

      // Act
      await scoreRepository.updateScore(score);

      // Assert
      verify(() => mockLocalDataSource.updateScore(
            score,
            status: LocalSyncStatus.pending,
          )).called(1);
    });

    test('updateScore triggers onDataChanged callback', () async {
      // Arrange
      final score = TestFixtures.sampleScore;

      // Act
      await scoreRepository.updateScore(score);

      // Assert
      expect(onDataChangedCalled, isTrue);
    });

    test('deleteScore deletes score from local data source', () async {
      // Act
      await scoreRepository.deleteScore('score_1');

      // Assert
      verify(() => mockLocalDataSource.deleteScore('score_1')).called(1);
    });

    test('deleteScore triggers onDataChanged callback', () async {
      // Act
      await scoreRepository.deleteScore('score_1');

      // Assert
      expect(onDataChangedCalled, isTrue);
    });
  });

  group('ScoreRepository InstrumentScore Operations', () {
    test('addInstrumentScore inserts instrument score', () async {
      // Arrange
      final instrumentScore = TestFixtures.sampleInstrumentScore;

      // Act
      await scoreRepository.addInstrumentScore('score_1', instrumentScore);

      // Assert
      verify(() => mockLocalDataSource.insertInstrumentScore(
            'score_1',
            instrumentScore,
          )).called(1);
    });

    test('addInstrumentScore triggers onDataChanged callback', () async {
      // Arrange
      final instrumentScore = TestFixtures.sampleInstrumentScore;

      // Act
      await scoreRepository.addInstrumentScore('score_1', instrumentScore);

      // Assert
      expect(onDataChangedCalled, isTrue);
    });

    test('updateInstrumentScore updates with pending status', () async {
      // Arrange
      final instrumentScore = TestFixtures.sampleInstrumentScore;

      // Act
      await scoreRepository.updateInstrumentScore(instrumentScore);

      // Assert
      verify(() => mockLocalDataSource.updateInstrumentScore(
            instrumentScore,
            status: LocalSyncStatus.pending,
          )).called(1);
    });

    test('deleteInstrumentScore deletes instrument score', () async {
      // Act
      await scoreRepository.deleteInstrumentScore('is_1');

      // Assert
      verify(() => mockLocalDataSource.deleteInstrumentScore('is_1')).called(1);
    });

    test('deleteInstrumentScore triggers onDataChanged callback', () async {
      // Act
      await scoreRepository.deleteInstrumentScore('is_1');

      // Assert
      expect(onDataChangedCalled, isTrue);
    });
  });

  group('ScoreRepository Annotation Operations', () {
    test('updateAnnotations updates annotations for instrument score', () async {
      // Arrange
      final annotations = TestFixtures.sampleAnnotations;

      // Act
      await scoreRepository.updateAnnotations('is_1', annotations);

      // Assert
      verify(() => mockLocalDataSource.updateAnnotations('is_1', annotations))
          .called(1);
    });

    test('updateAnnotations triggers onDataChanged callback', () async {
      // Arrange
      final annotations = TestFixtures.sampleAnnotations;

      // Act
      await scoreRepository.updateAnnotations('is_1', annotations);

      // Assert
      expect(onDataChangedCalled, isTrue);
    });

    test('updateAnnotations works with empty annotations list', () async {
      // Act
      await scoreRepository.updateAnnotations('is_1', []);

      // Assert
      verify(() => mockLocalDataSource.updateAnnotations('is_1', []))
          .called(1);
    });
  });

  group('ScoreRepository Duplicate Operations', () {
    test('duplicateScore creates new score with new id', () async {
      // Arrange
      final originalScore = TestFixtures.createScore(
        id: 'original_1',
        title: 'Original',
        composer: 'Composer',
      );
      when(() => mockLocalDataSource.getAllScores())
          .thenAnswer((_) async => [originalScore]);

      // Act
      final duplicatedScore = await scoreRepository.duplicateScore('original_1');

      // Assert
      expect(duplicatedScore.id, isNot(equals('original_1')));
      expect(duplicatedScore.title, equals('Original'));
      expect(duplicatedScore.composer, equals('Composer'));
      expect(duplicatedScore.serverId, isNull); // New score has no serverId
    });

    test('duplicateScore triggers onDataChanged callback', () async {
      // Arrange
      final originalScore = TestFixtures.sampleScore;
      when(() => mockLocalDataSource.getAllScores())
          .thenAnswer((_) async => [originalScore]);

      // Act
      await scoreRepository.duplicateScore('score_1');

      // Assert
      expect(onDataChangedCalled, isTrue);
    });
  });

  group('ScoreRepository Edge Cases', () {
    test('onDataChanged is not called when callback is null', () async {
      // Arrange
      final repo = ScoreRepository(local: mockLocalDataSource);
      // Don't set onDataChanged callback

      // Act & Assert - should not throw
      await repo.addScore(TestFixtures.sampleScore);
    });

    test('multiple operations trigger onDataChanged for each', () async {
      // Arrange
      int callCount = 0;
      scoreRepository.onDataChanged = () {
        callCount++;
      };

      // Act
      await scoreRepository.addScore(TestFixtures.sampleScore);
      await scoreRepository.updateScore(TestFixtures.sampleScore);
      await scoreRepository.deleteScore('score_1');

      // Assert
      expect(callCount, equals(3));
    });
  });
}
