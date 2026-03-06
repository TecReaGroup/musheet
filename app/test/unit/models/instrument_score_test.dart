/// InstrumentScore Model Tests
///
/// Unit tests for InstrumentScore model including serialization, copyWith, and enums.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/models/score.dart';
import 'package:musheet/models/annotation.dart';

import '../../fixtures/test_fixtures.dart';

void main() {
  group('InstrumentType Enum', () {
    test('has all expected values', () {
      expect(InstrumentType.values, contains(InstrumentType.vocal));
      expect(InstrumentType.values, contains(InstrumentType.keyboard));
      expect(InstrumentType.values, contains(InstrumentType.drums));
      expect(InstrumentType.values, contains(InstrumentType.bass));
      expect(InstrumentType.values, contains(InstrumentType.guitar));
      expect(InstrumentType.values, contains(InstrumentType.other));
    });

    test('has correct number of values', () {
      expect(InstrumentType.values.length, equals(6));
    });

    test('name property returns lowercase string', () {
      expect(InstrumentType.keyboard.name, equals('keyboard'));
      expect(InstrumentType.vocal.name, equals('vocal'));
    });
  });

  group('InstrumentScore Model', () {
    group('Construction', () {
      test('creates instrument score with required fields', () {
        final is1 = InstrumentScore(
          id: 'is_1',
          pdfPath: '/path/to/score.pdf',
          instrumentType: InstrumentType.keyboard,
          createdAt: DateTime(2024, 1, 15),
        );

        expect(is1.id, equals('is_1'));
        expect(is1.pdfPath, equals('/path/to/score.pdf'));
        expect(is1.instrumentType, equals(InstrumentType.keyboard));
        expect(is1.createdAt, equals(DateTime(2024, 1, 15)));
      });

      test('has default values for optional fields', () {
        final is1 = InstrumentScore(
          id: 'is_1',
          pdfPath: '/test.pdf',
          instrumentType: InstrumentType.vocal,
          createdAt: DateTime.now(),
        );

        expect(is1.scoreId, isNull);
        expect(is1.pdfHash, isNull);
        expect(is1.thumbnail, isNull);
        expect(is1.customInstrument, isNull);
        expect(is1.annotations, isNull);
        expect(is1.orderIndex, equals(0));
        expect(is1.sourceInstrumentScoreId, isNull);
      });

      test('creates instrument score with all fields', () {
        final annotations = TestFixtures.sampleAnnotations;
        final is1 = InstrumentScore(
          id: 'is_1',
          scoreId: 'score_1',
          pdfPath: '/test.pdf',
          pdfHash: 'abc123hash',
          thumbnail: '/thumbnails/is_1.png',
          instrumentType: InstrumentType.other,
          customInstrument: 'Saxophone',
          annotations: annotations,
          createdAt: DateTime(2024, 1, 15),
          orderIndex: 2,
          sourceInstrumentScoreId: 50,
        );

        expect(is1.scoreId, equals('score_1'));
        expect(is1.pdfHash, equals('abc123hash'));
        expect(is1.thumbnail, equals('/thumbnails/is_1.png'));
        expect(is1.customInstrument, equals('Saxophone'));
        expect(is1.annotations, equals(annotations));
        expect(is1.orderIndex, equals(2));
        expect(is1.sourceInstrumentScoreId, equals(50));
      });
    });

    group('Computed Properties', () {
      test('teamScoreId is alias for scoreId', () {
        final is1 = InstrumentScore(
          id: 'is_1',
          scoreId: 'score_123',
          pdfPath: '/test.pdf',
          instrumentType: InstrumentType.keyboard,
          createdAt: DateTime.now(),
        );

        expect(is1.teamScoreId, equals('score_123'));
      });

      test('teamScoreId is null when scoreId is null', () {
        final is1 = InstrumentScore(
          id: 'is_1',
          pdfPath: '/test.pdf',
          instrumentType: InstrumentType.keyboard,
          createdAt: DateTime.now(),
        );

        expect(is1.teamScoreId, isNull);
      });
    });

    group('copyWith', () {
      test('copies all fields when specified', () {
        final original = TestFixtures.sampleInstrumentScore;
        final copied = original.copyWith(
          id: 'new_id',
          scoreId: 'new_score',
          pdfPath: '/new/path.pdf',
          pdfHash: 'newhash',
          instrumentType: InstrumentType.drums,
          orderIndex: 5,
        );

        expect(copied.id, equals('new_id'));
        expect(copied.scoreId, equals('new_score'));
        expect(copied.pdfPath, equals('/new/path.pdf'));
        expect(copied.pdfHash, equals('newhash'));
        expect(copied.instrumentType, equals(InstrumentType.drums));
        expect(copied.orderIndex, equals(5));
      });

      test('preserves original values when not specified', () {
        final original = InstrumentScore(
          id: 'is_1',
          scoreId: 'score_1',
          pdfPath: '/original.pdf',
          pdfHash: 'originalhash',
          instrumentType: InstrumentType.keyboard,
          createdAt: DateTime(2024, 1, 15),
          orderIndex: 2,
        );

        final copied = original.copyWith(orderIndex: 3);

        expect(copied.id, equals('is_1'));
        expect(copied.scoreId, equals('score_1'));
        expect(copied.pdfPath, equals('/original.pdf'));
        expect(copied.pdfHash, equals('originalhash'));
        expect(copied.instrumentType, equals(InstrumentType.keyboard));
        expect(copied.orderIndex, equals(3));
      });

      test('teamScoreId parameter works as alias', () {
        final original = InstrumentScore(
          id: 'is_1',
          scoreId: 'score_1',
          pdfPath: '/test.pdf',
          instrumentType: InstrumentType.keyboard,
          createdAt: DateTime.now(),
        );

        final copied = original.copyWith(teamScoreId: 'new_score');

        expect(copied.scoreId, equals('new_score'));
      });

      test('can update annotations', () {
        final original = TestFixtures.sampleInstrumentScore;
        final newAnnotations = [
          Annotation(
            id: 'new_ann',
            type: 'draw',
            color: '#FF0000',
            width: 3.0,
            points: [0.1, 0.1, 0.5, 0.5],
            page: 1,
          ),
        ];

        final copied = original.copyWith(annotations: newAnnotations);

        expect(copied.annotations, equals(newAnnotations));
        expect(copied.annotations!.length, equals(1));
      });
    });

    group('JSON Serialization', () {
      test('toJson produces correct map', () {
        final is1 = InstrumentScore(
          id: 'is_1',
          scoreId: 'score_1',
          pdfPath: '/test.pdf',
          pdfHash: 'abc123',
          thumbnail: '/thumb.png',
          instrumentType: InstrumentType.keyboard,
          customInstrument: null,
          createdAt: DateTime(2024, 1, 15, 10, 30),
          orderIndex: 2,
          sourceInstrumentScoreId: 50,
        );

        final json = is1.toJson();

        expect(json['id'], equals('is_1'));
        expect(json['scoreId'], equals('score_1'));
        expect(json['pdfPath'], equals('/test.pdf'));
        expect(json['pdfHash'], equals('abc123'));
        expect(json['thumbnail'], equals('/thumb.png'));
        expect(json['instrumentType'], equals('keyboard'));
        expect(json['orderIndex'], equals(2));
        expect(json['sourceInstrumentScoreId'], equals(50));
        expect(json['createdAt'], equals('2024-01-15T10:30:00.000'));
      });

      test('toJson includes annotations when present', () {
        final is1 = TestFixtures.sampleInstrumentScoreWithAnnotations;
        final json = is1.toJson();

        expect(json['annotations'], isA<List>());
        expect((json['annotations'] as List).length, equals(1));
      });

      test('toJson handles null annotations', () {
        final is1 = InstrumentScore(
          id: 'is_1',
          pdfPath: '/test.pdf',
          instrumentType: InstrumentType.keyboard,
          createdAt: DateTime.now(),
        );

        final json = is1.toJson();

        expect(json['annotations'], isNull);
      });

      test('fromJson creates instrument score from map', () {
        final json = {
          'id': 'is_1',
          'scoreId': 'score_1',
          'pdfPath': '/test.pdf',
          'pdfHash': 'abc123',
          'thumbnail': '/thumb.png',
          'instrumentType': 'keyboard',
          'customInstrument': 'Custom Instrument',
          'createdAt': '2024-01-15T10:30:00.000',
          'orderIndex': 2,
          'sourceInstrumentScoreId': 50,
        };

        final is1 = InstrumentScore.fromJson(json);

        expect(is1.id, equals('is_1'));
        expect(is1.scoreId, equals('score_1'));
        expect(is1.pdfPath, equals('/test.pdf'));
        expect(is1.pdfHash, equals('abc123'));
        expect(is1.instrumentType, equals(InstrumentType.keyboard));
        expect(is1.customInstrument, equals('Custom Instrument'));
        expect(is1.orderIndex, equals(2));
        expect(is1.sourceInstrumentScoreId, equals(50));
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'is_1',
          'pdfPath': '/test.pdf',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final is1 = InstrumentScore.fromJson(json);

        expect(is1.scoreId, isNull);
        expect(is1.pdfHash, isNull);
        expect(is1.thumbnail, isNull);
        expect(is1.instrumentType, equals(InstrumentType.vocal)); // Default
        expect(is1.customInstrument, isNull);
        expect(is1.annotations, isNull);
        expect(is1.orderIndex, equals(0));
      });

      test('fromJson handles teamScoreId as alias', () {
        final json = {
          'id': 'is_1',
          'teamScoreId': 'team_score_1',
          'pdfPath': '/test.pdf',
          'instrumentType': 'drums',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final is1 = InstrumentScore.fromJson(json);

        expect(is1.scoreId, equals('team_score_1'));
      });

      test('fromJson parses annotations', () {
        final json = {
          'id': 'is_1',
          'pdfPath': '/test.pdf',
          'instrumentType': 'keyboard',
          'createdAt': '2024-01-15T10:30:00.000',
          'annotations': [
            {
              'id': 'ann_1',
              'type': 'draw',
              'color': '#000000',
              'width': 2.0,
              'points': [0.1, 0.2, 0.3, 0.4],
              'page': 1,
            },
          ],
        };

        final is1 = InstrumentScore.fromJson(json);

        expect(is1.annotations, isNotNull);
        expect(is1.annotations!.length, equals(1));
        expect(is1.annotations!.first.id, equals('ann_1'));
      });

      test('fromJson handles unknown instrument type gracefully', () {
        final json = {
          'id': 'is_1',
          'pdfPath': '/test.pdf',
          'instrumentType': 'unknown_instrument',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final is1 = InstrumentScore.fromJson(json);

        // Falls back to vocal when unknown
        expect(is1.instrumentType, equals(InstrumentType.vocal));
      });

      test('toJson and fromJson are symmetric', () {
        final original = InstrumentScore(
          id: 'is_1',
          scoreId: 'score_1',
          pdfPath: '/test.pdf',
          pdfHash: 'abc123',
          instrumentType: InstrumentType.drums,
          createdAt: DateTime(2024, 1, 15, 10, 30),
          orderIndex: 3,
        );

        final json = original.toJson();
        final restored = InstrumentScore.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.scoreId, equals(original.scoreId));
        expect(restored.pdfPath, equals(original.pdfPath));
        expect(restored.pdfHash, equals(original.pdfHash));
        expect(restored.instrumentType, equals(original.instrumentType));
        expect(restored.orderIndex, equals(original.orderIndex));
      });
    });

    group('All Instrument Types', () {
      test('can create instrument score for each type', () {
        for (final type in InstrumentType.values) {
          final is1 = InstrumentScore(
            id: 'is_${type.name}',
            pdfPath: '/test.pdf',
            instrumentType: type,
            createdAt: DateTime.now(),
          );

          expect(is1.instrumentType, equals(type));
        }
      });

      test('serializes and deserializes all instrument types', () {
        for (final type in InstrumentType.values) {
          final original = InstrumentScore(
            id: 'is_${type.name}',
            pdfPath: '/test.pdf',
            instrumentType: type,
            createdAt: DateTime(2024, 1, 15),
          );

          final json = original.toJson();
          final restored = InstrumentScore.fromJson(json);

          expect(restored.instrumentType, equals(type),
              reason: 'Failed for instrument type: ${type.name}');
        }
      });
    });

    group('Custom Instrument', () {
      test('other type with custom instrument', () {
        final is1 = InstrumentScore(
          id: 'is_1',
          pdfPath: '/test.pdf',
          instrumentType: InstrumentType.other,
          customInstrument: 'Saxophone',
          createdAt: DateTime.now(),
        );

        expect(is1.instrumentType, equals(InstrumentType.other));
        expect(is1.customInstrument, equals('Saxophone'));
      });

      test('non-other type ignores custom instrument', () {
        // While the model allows it, logically custom is for "other"
        final is1 = InstrumentScore(
          id: 'is_1',
          pdfPath: '/test.pdf',
          instrumentType: InstrumentType.keyboard,
          customInstrument: 'Should be ignored',
          createdAt: DateTime.now(),
        );

        expect(is1.instrumentType, equals(InstrumentType.keyboard));
        expect(is1.customInstrument, equals('Should be ignored'));
      });
    });
  });
}
