/// Setlist Model Tests
///
/// Unit tests for Setlist model including serialization, copyWith, and computed properties.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/models/setlist.dart';

import '../../fixtures/test_fixtures.dart';

void main() {
  group('Setlist Model', () {
    group('Construction', () {
      test('creates setlist with required fields', () {
        final setlist = Setlist(
          id: 'setlist_1',
          name: 'Test Setlist',
          scoreIds: ['score_1', 'score_2'],
          createdAt: DateTime(2024, 1, 15),
        );

        expect(setlist.id, equals('setlist_1'));
        expect(setlist.name, equals('Test Setlist'));
        expect(setlist.scoreIds, equals(['score_1', 'score_2']));
        expect(setlist.createdAt, equals(DateTime(2024, 1, 15)));
      });

      test('has default values for optional fields', () {
        final setlist = Setlist(
          id: 'setlist_1',
          name: 'Test',
          scoreIds: [],
          createdAt: DateTime.now(),
        );

        expect(setlist.serverId, isNull);
        expect(setlist.scopeType, equals('user'));
        expect(setlist.scopeId, equals(0));
        expect(setlist.description, isNull);
        expect(setlist.createdById, isNull);
        expect(setlist.sourceSetlistId, isNull);
      });

      test('creates setlist with all fields', () {
        final setlist = Setlist(
          id: 'setlist_1',
          serverId: 200,
          scopeType: 'team',
          scopeId: 5,
          name: 'Full Setlist',
          description: 'Full description',
          scoreIds: ['s1', 's2', 's3'],
          createdAt: DateTime(2024, 1, 15),
          createdById: 1,
          sourceSetlistId: 100,
        );

        expect(setlist.serverId, equals(200));
        expect(setlist.scopeType, equals('team'));
        expect(setlist.scopeId, equals(5));
        expect(setlist.description, equals('Full description'));
        expect(setlist.createdById, equals(1));
        expect(setlist.sourceSetlistId, equals(100));
        expect(setlist.scoreIds.length, equals(3));
      });
    });

    group('Computed Properties', () {
      test('isTeamSetlist returns true for team scope', () {
        final teamSetlist = Setlist(
          id: 'ts_1',
          name: 'Team',
          scoreIds: [],
          createdAt: DateTime.now(),
          scopeType: 'team',
          scopeId: 5,
        );

        expect(teamSetlist.isTeamSetlist, isTrue);
      });

      test('isTeamSetlist returns false for user scope', () {
        final userSetlist = Setlist(
          id: 'us_1',
          name: 'User',
          scoreIds: [],
          createdAt: DateTime.now(),
          scopeType: 'user',
        );

        expect(userSetlist.isTeamSetlist, isFalse);
      });

      test('teamId returns scopeId', () {
        final setlist = Setlist(
          id: 's_1',
          name: 'T',
          scoreIds: [],
          createdAt: DateTime.now(),
          scopeType: 'team',
          scopeId: 42,
        );

        expect(setlist.teamId, equals(42));
      });

      test('teamScoreIds is alias for scoreIds', () {
        final scoreIds = ['s1', 's2', 's3'];
        final setlist = Setlist(
          id: 's_1',
          name: 'T',
          scoreIds: scoreIds,
          createdAt: DateTime.now(),
        );

        expect(setlist.teamScoreIds, equals(scoreIds));
      });
    });

    group('copyWith', () {
      test('copies all fields when specified', () {
        final original = TestFixtures.sampleSetlist;
        final copied = original.copyWith(
          id: 'new_id',
          serverId: 999,
          name: 'New Name',
          description: 'New Description',
        );

        expect(copied.id, equals('new_id'));
        expect(copied.serverId, equals(999));
        expect(copied.name, equals('New Name'));
        expect(copied.description, equals('New Description'));
      });

      test('preserves original values when not specified', () {
        final original = Setlist(
          id: 'setlist_1',
          serverId: 200,
          name: 'Original',
          description: 'Original description',
          scoreIds: ['s1', 's2'],
          createdAt: DateTime(2024, 1, 15),
        );

        final copied = original.copyWith(name: 'New Name');

        expect(copied.id, equals('setlist_1'));
        expect(copied.serverId, equals(200));
        expect(copied.description, equals('Original description'));
        expect(copied.scoreIds, equals(['s1', 's2']));
        expect(copied.name, equals('New Name'));
      });

      test('can change scope type and id', () {
        final userSetlist = TestFixtures.sampleSetlist;
        final teamSetlist = userSetlist.copyWith(
          scopeType: 'team',
          scopeId: 5,
        );

        expect(teamSetlist.scopeType, equals('team'));
        expect(teamSetlist.scopeId, equals(5));
        expect(teamSetlist.isTeamSetlist, isTrue);
      });

      test('can update scoreIds', () {
        final original = Setlist(
          id: 's_1',
          name: 'T',
          scoreIds: ['s1'],
          createdAt: DateTime.now(),
        );

        final updated = original.copyWith(scoreIds: ['s1', 's2', 's3']);

        expect(updated.scoreIds, equals(['s1', 's2', 's3']));
      });

      test('teamScoreIds parameter works as alias', () {
        final original = Setlist(
          id: 's_1',
          name: 'T',
          scoreIds: ['s1'],
          createdAt: DateTime.now(),
        );

        final updated = original.copyWith(teamScoreIds: ['s1', 's2']);

        expect(updated.scoreIds, equals(['s1', 's2']));
      });
    });

    group('JSON Serialization', () {
      test('toJson produces correct map', () {
        final setlist = Setlist(
          id: 'setlist_1',
          serverId: 200,
          scopeType: 'team',
          scopeId: 5,
          name: 'Test Setlist',
          description: 'Test description',
          scoreIds: ['s1', 's2'],
          createdAt: DateTime(2024, 1, 15, 10, 30),
          createdById: 1,
          sourceSetlistId: 100,
        );

        final json = setlist.toJson();

        expect(json['id'], equals('setlist_1'));
        expect(json['serverId'], equals(200));
        expect(json['scopeType'], equals('team'));
        expect(json['scopeId'], equals(5));
        expect(json['name'], equals('Test Setlist'));
        expect(json['description'], equals('Test description'));
        expect(json['scoreIds'], equals(['s1', 's2']));
        expect(json['createdById'], equals(1));
        expect(json['sourceSetlistId'], equals(100));
        expect(json['createdAt'], equals('2024-01-15T10:30:00.000'));
      });

      test('fromJson creates setlist from map', () {
        final json = {
          'id': 'setlist_1',
          'serverId': 200,
          'scopeType': 'team',
          'scopeId': 5,
          'name': 'Test Setlist',
          'description': 'Test description',
          'scoreIds': ['s1', 's2'],
          'createdAt': '2024-01-15T10:30:00.000',
          'createdById': 1,
          'sourceSetlistId': 100,
        };

        final setlist = Setlist.fromJson(json);

        expect(setlist.id, equals('setlist_1'));
        expect(setlist.serverId, equals(200));
        expect(setlist.scopeType, equals('team'));
        expect(setlist.scopeId, equals(5));
        expect(setlist.name, equals('Test Setlist'));
        expect(setlist.description, equals('Test description'));
        expect(setlist.scoreIds, equals(['s1', 's2']));
        expect(setlist.createdById, equals(1));
        expect(setlist.sourceSetlistId, equals(100));
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'setlist_1',
          'name': 'Test',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final setlist = Setlist.fromJson(json);

        expect(setlist.serverId, isNull);
        expect(setlist.scopeType, equals('user'));
        expect(setlist.scopeId, equals(0));
        expect(setlist.description, isNull);
        expect(setlist.scoreIds, isEmpty);
      });

      test('fromJson handles teamScoreIds as alias', () {
        final json = {
          'id': 'setlist_1',
          'name': 'Test',
          'teamScoreIds': ['s1', 's2'],
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final setlist = Setlist.fromJson(json);

        expect(setlist.scoreIds, equals(['s1', 's2']));
      });

      test('fromJson prefers scoreIds over teamScoreIds', () {
        final json = {
          'id': 'setlist_1',
          'name': 'Test',
          'scoreIds': ['s1', 's2'],
          'teamScoreIds': ['s3', 's4'],
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final setlist = Setlist.fromJson(json);

        expect(setlist.scoreIds, equals(['s1', 's2']));
      });

      test('fromJson handles teamId as alias for scopeId', () {
        final json = {
          'id': 'setlist_1',
          'name': 'Test',
          'scopeType': 'team',
          'teamId': 42,
          'scoreIds': [],
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final setlist = Setlist.fromJson(json);

        expect(setlist.scopeId, equals(42));
      });

      test('toJson and fromJson are symmetric', () {
        final original = Setlist(
          id: 'setlist_1',
          serverId: 200,
          scopeType: 'team',
          scopeId: 5,
          name: 'Test Setlist',
          description: 'Description',
          scoreIds: ['s1', 's2'],
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        final json = original.toJson();
        final restored = Setlist.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.serverId, equals(original.serverId));
        expect(restored.scopeType, equals(original.scopeType));
        expect(restored.scopeId, equals(original.scopeId));
        expect(restored.name, equals(original.name));
        expect(restored.description, equals(original.description));
        expect(restored.scoreIds, equals(original.scoreIds));
      });
    });

    group('Score Management', () {
      test('scoreIds maintains order', () {
        final setlist = Setlist(
          id: 's_1',
          name: 'Ordered',
          scoreIds: ['first', 'second', 'third'],
          createdAt: DateTime.now(),
        );

        expect(setlist.scoreIds[0], equals('first'));
        expect(setlist.scoreIds[1], equals('second'));
        expect(setlist.scoreIds[2], equals('third'));
      });

      test('empty scoreIds is valid', () {
        final setlist = Setlist(
          id: 's_1',
          name: 'Empty',
          scoreIds: [],
          createdAt: DateTime.now(),
        );

        expect(setlist.scoreIds, isEmpty);
      });

      test('scoreIds can contain duplicates', () {
        // While not ideal, the model allows this - validation is done elsewhere
        final setlist = Setlist(
          id: 's_1',
          name: 'Dupes',
          scoreIds: ['s1', 's1', 's2'],
          createdAt: DateTime.now(),
        );

        expect(setlist.scoreIds.length, equals(3));
      });
    });
  });
}
