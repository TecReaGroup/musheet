/// Data Scope Tests
///
/// Tests for DataScope class which handles user/team data separation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/data/data_scope.dart';

void main() {
  group('DataScope', () {
    group('User Scope', () {
      test('user scope has correct scopeType', () {
        expect(DataScope.user.scopeType, equals('user'));
      });

      test('user scope has scopeId of 0', () {
        expect(DataScope.user.scopeId, equals(0));
      });

      test('user scope isTeam is false', () {
        expect(DataScope.user.isTeam, isFalse);
      });

      test('user scope isUser is true', () {
        expect(DataScope.user.isUser, isTrue);
      });

      test('user scope singleton is same instance', () {
        expect(identical(DataScope.user, DataScope.user), isTrue);
      });
    });

    group('Team Scope', () {
      test('team scope has correct scopeType', () {
        final teamScope = DataScope.team(42);
        expect(teamScope.scopeType, equals('team'));
      });

      test('team scope has correct scopeId', () {
        final teamScope = DataScope.team(42);
        expect(teamScope.scopeId, equals(42));
      });

      test('team scope isTeam is true', () {
        final teamScope = DataScope.team(42);
        expect(teamScope.isTeam, isTrue);
      });

      test('team scope isUser is false', () {
        final teamScope = DataScope.team(42);
        expect(teamScope.isUser, isFalse);
      });

      test('different team IDs create different scopes', () {
        final team1 = DataScope.team(10);
        final team2 = DataScope.team(20);

        expect(team1.scopeId, isNot(equals(team2.scopeId)));
      });

      test('same team ID creates equal scope values', () {
        final team1 = DataScope.team(42);
        final team2 = DataScope.team(42);

        expect(team1.scopeId, equals(team2.scopeId));
        expect(team1.scopeType, equals(team2.scopeType));
      });
    });

    group('Scope Comparison', () {
      test('user scope is different from team scope', () {
        final userScope = DataScope.user;
        final teamScope = DataScope.team(42);

        expect(userScope.scopeType, isNot(equals(teamScope.scopeType)));
      });

      test('team scopes with different IDs are different', () {
        final team1 = DataScope.team(10);
        final team2 = DataScope.team(20);

        expect(team1.scopeId, isNot(equals(team2.scopeId)));
      });
    });

    group('Equality', () {
      test('user scopes are equal', () {
        expect(DataScope.user == DataScope.user, isTrue);
      });

      test('team scopes with same ID are equal', () {
        final team1 = DataScope.team(42);
        final team2 = DataScope.team(42);

        expect(team1 == team2, isTrue);
      });

      test('team scopes with different IDs are not equal', () {
        final team1 = DataScope.team(10);
        final team2 = DataScope.team(20);

        expect(team1 == team2, isFalse);
      });

      test('user scope and team scope are not equal', () {
        final user = DataScope.user;
        final team = DataScope.team(1);

        expect(user == team, isFalse);
      });

      test('hashCode is consistent for equal scopes', () {
        final team1 = DataScope.team(42);
        final team2 = DataScope.team(42);

        expect(team1.hashCode, equals(team2.hashCode));
      });
    });

    group('JSON Serialization', () {
      test('user scope toJson', () {
        final json = DataScope.user.toJson();

        expect(json['type'], equals('user'));
        expect(json['id'], equals(0));
      });

      test('team scope toJson', () {
        final json = DataScope.team(42).toJson();

        expect(json['type'], equals('team'));
        expect(json['id'], equals(42));
      });

      test('user scope fromJson', () {
        final json = {'type': 'user', 'id': 0};
        final scope = DataScope.fromJson(json);

        expect(scope.isUser, isTrue);
        expect(scope.scopeId, equals(0));
      });

      test('team scope fromJson', () {
        final json = {'type': 'team', 'id': 42};
        final scope = DataScope.fromJson(json);

        expect(scope.isTeam, isTrue);
        expect(scope.scopeId, equals(42));
      });

      test('toJson and fromJson are symmetric for user scope', () {
        final original = DataScope.user;
        final json = original.toJson();
        final restored = DataScope.fromJson(json);

        expect(restored, equals(original));
      });

      test('toJson and fromJson are symmetric for team scope', () {
        final original = DataScope.team(42);
        final json = original.toJson();
        final restored = DataScope.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('toString', () {
      test('user scope toString', () {
        expect(DataScope.user.toString(), equals('DataScope(user, 0)'));
      });

      test('team scope toString', () {
        expect(DataScope.team(42).toString(), equals('DataScope(team, 42)'));
      });
    });

    group('Edge Cases', () {
      test('team scope with minimum positive ID', () {
        final teamScope = DataScope.team(1);
        expect(teamScope.scopeId, equals(1));
      });

      test('team scope with large ID', () {
        final teamScope = DataScope.team(999999);
        expect(teamScope.scopeId, equals(999999));
      });
    });
  });
}
