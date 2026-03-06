/// Score Model Tests
///
/// Unit tests for Score model including serialization, copyWith, and computed properties.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/models/score.dart';

import '../../fixtures/test_fixtures.dart';

void main() {
  group('Score Model', () {
    group('Construction', () {
      test('creates score with required fields', () {
        final score = Score(
          id: 'score_1',
          title: 'Test Score',
          composer: 'Test Composer',
          createdAt: DateTime(2024, 1, 15),
        );

        expect(score.id, equals('score_1'));
        expect(score.title, equals('Test Score'));
        expect(score.composer, equals('Test Composer'));
        expect(score.createdAt, equals(DateTime(2024, 1, 15)));
      });

      test('has default values for optional fields', () {
        final score = Score(
          id: 'score_1',
          title: 'Test',
          composer: 'Composer',
          createdAt: DateTime.now(),
        );

        expect(score.serverId, isNull);
        expect(score.scopeType, equals('user'));
        expect(score.scopeId, equals(0));
        expect(score.bpm, equals(120));
        expect(score.createdById, isNull);
        expect(score.sourceScoreId, isNull);
        expect(score.instrumentScores, isEmpty);
      });

      test('creates score with all fields', () {
        final instrumentScore = TestFixtures.sampleInstrumentScore;
        final score = Score(
          id: 'score_1',
          serverId: 100,
          scopeType: 'team',
          scopeId: 5,
          title: 'Full Score',
          composer: 'Full Composer',
          createdAt: DateTime(2024, 1, 15),
          bpm: 140,
          createdById: 1,
          sourceScoreId: 50,
          instrumentScores: [instrumentScore],
        );

        expect(score.serverId, equals(100));
        expect(score.scopeType, equals('team'));
        expect(score.scopeId, equals(5));
        expect(score.bpm, equals(140));
        expect(score.createdById, equals(1));
        expect(score.sourceScoreId, equals(50));
        expect(score.instrumentScores.length, equals(1));
      });
    });

    group('Computed Properties', () {
      test('isTeamScore returns true for team scope', () {
        final teamScore = Score(
          id: 'ts_1',
          title: 'Team',
          composer: 'C',
          createdAt: DateTime.now(),
          scopeType: 'team',
          scopeId: 5,
        );

        expect(teamScore.isTeamScore, isTrue);
      });

      test('isTeamScore returns false for user scope', () {
        final userScore = Score(
          id: 'us_1',
          title: 'User',
          composer: 'C',
          createdAt: DateTime.now(),
          scopeType: 'user',
        );

        expect(userScore.isTeamScore, isFalse);
      });

      test('teamId returns scopeId', () {
        final score = Score(
          id: 's_1',
          title: 'T',
          composer: 'C',
          createdAt: DateTime.now(),
          scopeType: 'team',
          scopeId: 42,
        );

        expect(score.teamId, equals(42));
      });

      test('firstInstrumentScore returns first when available', () {
        final is1 = TestFixtures.createInstrumentScore(id: 'is_1');
        final is2 = TestFixtures.createInstrumentScore(id: 'is_2');
        final score = Score(
          id: 's_1',
          title: 'T',
          composer: 'C',
          createdAt: DateTime.now(),
          instrumentScores: [is1, is2],
        );

        expect(score.firstInstrumentScore, equals(is1));
      });

      test('firstInstrumentScore returns null when empty', () {
        final score = Score(
          id: 's_1',
          title: 'T',
          composer: 'C',
          createdAt: DateTime.now(),
        );

        expect(score.firstInstrumentScore, isNull);
      });

      test('totalAnnotationCount sums annotations across instrument scores', () {
        final isWithAnnotations = TestFixtures.sampleInstrumentScoreWithAnnotations;
        final isWithoutAnnotations = TestFixtures.sampleInstrumentScore;
        final score = Score(
          id: 's_1',
          title: 'T',
          composer: 'C',
          createdAt: DateTime.now(),
          instrumentScores: [isWithAnnotations, isWithoutAnnotations],
        );

        expect(score.totalAnnotationCount, equals(1));
      });

      test('totalAnnotationCount returns 0 when no annotations', () {
        final score = Score(
          id: 's_1',
          title: 'T',
          composer: 'C',
          createdAt: DateTime.now(),
        );

        expect(score.totalAnnotationCount, equals(0));
      });
    });

    group('Instrument Management', () {
      test('existingInstrumentKeys returns all instrument keys', () {
        final is1 = TestFixtures.createInstrumentScore(
          id: 'is_1',
          instrumentType: InstrumentType.keyboard,
        );
        final is2 = TestFixtures.createInstrumentScore(
          id: 'is_2',
          instrumentType: InstrumentType.drums,
        );
        final score = Score(
          id: 's_1',
          title: 'T',
          composer: 'C',
          createdAt: DateTime.now(),
          instrumentScores: [is1, is2],
        );

        final keys = score.existingInstrumentKeys;
        expect(keys.contains('keyboard'), isTrue);
        expect(keys.contains('drums'), isTrue);
      });

      test('hasInstrument returns true for existing instrument', () {
        final is1 = TestFixtures.createInstrumentScore(
          id: 'is_1',
          instrumentType: InstrumentType.keyboard,
        );
        final score = Score(
          id: 's_1',
          title: 'T',
          composer: 'C',
          createdAt: DateTime.now(),
          instrumentScores: [is1],
        );

        expect(score.hasInstrument(InstrumentType.keyboard, null), isTrue);
      });

      test('hasInstrument returns false for non-existing instrument', () {
        final is1 = TestFixtures.createInstrumentScore(
          id: 'is_1',
          instrumentType: InstrumentType.keyboard,
        );
        final score = Score(
          id: 's_1',
          title: 'T',
          composer: 'C',
          createdAt: DateTime.now(),
          instrumentScores: [is1],
        );

        expect(score.hasInstrument(InstrumentType.drums, null), isFalse);
      });

      test('hasInstrument handles custom instruments', () {
        final is1 = TestFixtures.createInstrumentScore(
          id: 'is_1',
          instrumentType: InstrumentType.other,
          customInstrument: 'Saxophone',
        );
        final score = Score(
          id: 's_1',
          title: 'T',
          composer: 'C',
          createdAt: DateTime.now(),
          instrumentScores: [is1],
        );

        expect(score.hasInstrument(InstrumentType.other, 'Saxophone'), isTrue);
        expect(score.hasInstrument(InstrumentType.other, 'Flute'), isFalse);
      });
    });

    group('copyWith', () {
      test('copies all fields when specified', () {
        final original = TestFixtures.sampleScore;
        final copied = original.copyWith(
          id: 'new_id',
          serverId: 999,
          title: 'New Title',
          composer: 'New Composer',
          bpm: 180,
        );

        expect(copied.id, equals('new_id'));
        expect(copied.serverId, equals(999));
        expect(copied.title, equals('New Title'));
        expect(copied.composer, equals('New Composer'));
        expect(copied.bpm, equals(180));
      });

      test('preserves original values when not specified', () {
        final original = Score(
          id: 'score_1',
          serverId: 100,
          title: 'Original',
          composer: 'Original Composer',
          createdAt: DateTime(2024, 1, 15),
          bpm: 120,
        );

        final copied = original.copyWith(title: 'New Title');

        expect(copied.id, equals('score_1'));
        expect(copied.serverId, equals(100));
        expect(copied.composer, equals('Original Composer'));
        expect(copied.bpm, equals(120));
        expect(copied.title, equals('New Title'));
      });

      test('can change scope type and id', () {
        final userScore = TestFixtures.sampleScore;
        final teamScore = userScore.copyWith(
          scopeType: 'team',
          scopeId: 5,
        );

        expect(teamScore.scopeType, equals('team'));
        expect(teamScore.scopeId, equals(5));
        expect(teamScore.isTeamScore, isTrue);
      });
    });

    group('JSON Serialization', () {
      test('toJson produces correct map', () {
        final score = Score(
          id: 'score_1',
          serverId: 100,
          scopeType: 'team',
          scopeId: 5,
          title: 'Test Score',
          composer: 'Composer',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          bpm: 140,
          createdById: 1,
          sourceScoreId: 50,
        );

        final json = score.toJson();

        expect(json['id'], equals('score_1'));
        expect(json['serverId'], equals(100));
        expect(json['scopeType'], equals('team'));
        expect(json['scopeId'], equals(5));
        expect(json['title'], equals('Test Score'));
        expect(json['composer'], equals('Composer'));
        expect(json['bpm'], equals(140));
        expect(json['createdById'], equals(1));
        expect(json['sourceScoreId'], equals(50));
        expect(json['createdAt'], equals('2024-01-15T10:30:00.000'));
      });

      test('toJson includes instrument scores', () {
        final instrumentScore = TestFixtures.sampleInstrumentScore;
        final score = Score(
          id: 'score_1',
          title: 'Test',
          composer: 'C',
          createdAt: DateTime.now(),
          instrumentScores: [instrumentScore],
        );

        final json = score.toJson();

        expect(json['instrumentScores'], isA<List>());
        expect((json['instrumentScores'] as List).length, equals(1));
      });

      test('fromJson creates score from map', () {
        final json = {
          'id': 'score_1',
          'serverId': 100,
          'scopeType': 'team',
          'scopeId': 5,
          'title': 'Test Score',
          'composer': 'Composer',
          'createdAt': '2024-01-15T10:30:00.000',
          'bpm': 140,
          'createdById': 1,
          'sourceScoreId': 50,
          'instrumentScores': [],
        };

        final score = Score.fromJson(json);

        expect(score.id, equals('score_1'));
        expect(score.serverId, equals(100));
        expect(score.scopeType, equals('team'));
        expect(score.scopeId, equals(5));
        expect(score.title, equals('Test Score'));
        expect(score.composer, equals('Composer'));
        expect(score.bpm, equals(140));
        expect(score.createdById, equals(1));
        expect(score.sourceScoreId, equals(50));
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'score_1',
          'title': 'Test',
          'composer': 'C',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final score = Score.fromJson(json);

        expect(score.serverId, isNull);
        expect(score.scopeType, equals('user'));
        expect(score.scopeId, equals(0));
        expect(score.bpm, equals(120));
        expect(score.instrumentScores, isEmpty);
      });

      test('fromJson parses instrument scores', () {
        final json = {
          'id': 'score_1',
          'title': 'Test',
          'composer': 'C',
          'createdAt': '2024-01-15T10:30:00.000',
          'instrumentScores': [
            {
              'id': 'is_1',
              'pdfPath': '/test.pdf',
              'instrumentType': 'keyboard',
              'createdAt': '2024-01-15T10:30:00.000',
            },
          ],
        };

        final score = Score.fromJson(json);

        expect(score.instrumentScores.length, equals(1));
        expect(score.instrumentScores.first.id, equals('is_1'));
      });

      test('toJson and fromJson are symmetric', () {
        final original = Score(
          id: 'score_1',
          serverId: 100,
          scopeType: 'team',
          scopeId: 5,
          title: 'Test Score',
          composer: 'Composer',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          bpm: 140,
        );

        final json = original.toJson();
        final restored = Score.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.serverId, equals(original.serverId));
        expect(restored.scopeType, equals(original.scopeType));
        expect(restored.scopeId, equals(original.scopeId));
        expect(restored.title, equals(original.title));
        expect(restored.composer, equals(original.composer));
        expect(restored.bpm, equals(original.bpm));
      });
    });
  });
}
