/// Team and TeamMember Model Tests
///
/// Unit tests for Team and TeamMember models including serialization and nested structures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/models/team.dart';

void main() {
  group('TeamMember Model', () {
    group('Construction', () {
      test('creates team member with required fields', () {
        final member = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          joinedAt: DateTime(2024, 1, 15),
        );

        expect(member.id, equals('member_1'));
        expect(member.userId, equals(100));
        expect(member.username, equals('testuser'));
        expect(member.joinedAt, equals(DateTime(2024, 1, 15)));
      });

      test('has default role of member', () {
        final member = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          joinedAt: DateTime.now(),
        );

        expect(member.role, equals('member'));
      });

      test('optional fields are null when not provided', () {
        final member = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          joinedAt: DateTime.now(),
        );

        expect(member.displayName, isNull);
        expect(member.avatarUrl, isNull);
      });

      test('creates team member with all fields', () {
        final member = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          displayName: 'Test User',
          avatarUrl: 'https://example.com/avatar.png',
          role: 'admin',
          joinedAt: DateTime(2024, 1, 15),
        );

        expect(member.displayName, equals('Test User'));
        expect(member.avatarUrl, equals('https://example.com/avatar.png'));
        expect(member.role, equals('admin'));
      });
    });

    group('Computed Properties', () {
      test('name returns displayName when available', () {
        final member = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          displayName: 'Display Name',
          joinedAt: DateTime.now(),
        );

        expect(member.name, equals('Display Name'));
      });

      test('name returns username when displayName is null', () {
        final member = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          joinedAt: DateTime.now(),
        );

        expect(member.name, equals('testuser'));
      });
    });

    group('copyWith', () {
      test('copies all fields when specified', () {
        final original = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          displayName: 'Test',
          avatarUrl: 'http://old.com/avatar.png',
          role: 'member',
          joinedAt: DateTime(2024, 1, 15),
        );

        final copied = original.copyWith(
          id: 'member_2',
          userId: 200,
          username: 'newuser',
          displayName: 'New Name',
          avatarUrl: 'http://new.com/avatar.png',
          role: 'admin',
        );

        expect(copied.id, equals('member_2'));
        expect(copied.userId, equals(200));
        expect(copied.username, equals('newuser'));
        expect(copied.displayName, equals('New Name'));
        expect(copied.avatarUrl, equals('http://new.com/avatar.png'));
        expect(copied.role, equals('admin'));
      });

      test('preserves original values when not specified', () {
        final original = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          displayName: 'Test',
          joinedAt: DateTime(2024, 1, 15),
        );

        final copied = original.copyWith(displayName: 'New Name');

        expect(copied.id, equals('member_1'));
        expect(copied.userId, equals(100));
        expect(copied.username, equals('testuser'));
        expect(copied.displayName, equals('New Name'));
      });
    });

    group('JSON Serialization', () {
      test('toJson produces correct map', () {
        final member = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          displayName: 'Test User',
          avatarUrl: 'http://example.com/avatar.png',
          role: 'admin',
          joinedAt: DateTime(2024, 1, 15, 10, 30),
        );

        final json = member.toJson();

        expect(json['id'], equals('member_1'));
        expect(json['userId'], equals(100));
        expect(json['username'], equals('testuser'));
        expect(json['displayName'], equals('Test User'));
        expect(json['avatarUrl'], equals('http://example.com/avatar.png'));
        expect(json['role'], equals('admin'));
        expect(json['joinedAt'], equals('2024-01-15T10:30:00.000'));
      });

      test('fromJson creates team member from map', () {
        final json = {
          'id': 'member_1',
          'userId': 100,
          'username': 'testuser',
          'displayName': 'Test User',
          'avatarUrl': 'http://example.com/avatar.png',
          'role': 'admin',
          'joinedAt': '2024-01-15T10:30:00.000',
        };

        final member = TeamMember.fromJson(json);

        expect(member.id, equals('member_1'));
        expect(member.userId, equals(100));
        expect(member.username, equals('testuser'));
        expect(member.displayName, equals('Test User'));
        expect(member.avatarUrl, equals('http://example.com/avatar.png'));
        expect(member.role, equals('admin'));
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'member_1',
          'userId': 100,
          'username': 'testuser',
          'joinedAt': '2024-01-15T10:30:00.000',
        };

        final member = TeamMember.fromJson(json);

        expect(member.displayName, isNull);
        expect(member.avatarUrl, isNull);
        expect(member.role, equals('member'));
      });

      test('toJson and fromJson are symmetric', () {
        final original = TeamMember(
          id: 'member_1',
          userId: 100,
          username: 'testuser',
          displayName: 'Test',
          avatarUrl: 'http://example.com/avatar.png',
          role: 'member',
          joinedAt: DateTime(2024, 1, 15, 10, 30),
        );

        final json = original.toJson();
        final restored = TeamMember.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.userId, equals(original.userId));
        expect(restored.username, equals(original.username));
        expect(restored.displayName, equals(original.displayName));
        expect(restored.avatarUrl, equals(original.avatarUrl));
        expect(restored.role, equals(original.role));
      });
    });
  });

  group('Team Model', () {
    group('Construction', () {
      test('creates team with required fields', () {
        final team = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Test Team',
          createdAt: DateTime(2024, 1, 15),
        );

        expect(team.id, equals('team_1'));
        expect(team.serverId, equals(42));
        expect(team.name, equals('Test Team'));
        expect(team.createdAt, equals(DateTime(2024, 1, 15)));
      });

      test('has default empty lists for optional collections', () {
        final team = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Test',
          createdAt: DateTime.now(),
        );

        expect(team.members, isEmpty);
        expect(team.sharedScores, isEmpty);
        expect(team.sharedSetlists, isEmpty);
      });

      test('optional description is null when not provided', () {
        final team = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Test',
          createdAt: DateTime.now(),
        );

        expect(team.description, isNull);
      });

      test('creates team with all fields', () {
        final members = [
          TeamMember(
            id: 'member_1',
            userId: 100,
            username: 'user1',
            joinedAt: DateTime.now(),
          ),
        ];
        final scores = [
          Score(
            id: 'score_1',
            title: 'Test',
            composer: 'C',
            createdAt: DateTime.now(),
          ),
        ];
        final setlists = [
          Setlist(
            id: 'setlist_1',
            name: 'Test',
            scoreIds: [],
            createdAt: DateTime.now(),
          ),
        ];

        final team = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Full Team',
          description: 'A full team',
          members: members,
          createdAt: DateTime(2024, 1, 15),
          sharedScores: scores,
          sharedSetlists: setlists,
        );

        expect(team.description, equals('A full team'));
        expect(team.members.length, equals(1));
        expect(team.sharedScores.length, equals(1));
        expect(team.sharedSetlists.length, equals(1));
      });
    });

    group('copyWith', () {
      test('copies all fields when specified', () {
        final original = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Original',
          description: 'Old',
          createdAt: DateTime(2024, 1, 15),
        );

        final copied = original.copyWith(
          id: 'team_2',
          serverId: 100,
          name: 'New Team',
          description: 'New description',
        );

        expect(copied.id, equals('team_2'));
        expect(copied.serverId, equals(100));
        expect(copied.name, equals('New Team'));
        expect(copied.description, equals('New description'));
      });

      test('preserves original values when not specified', () {
        final original = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Original',
          description: 'Description',
          createdAt: DateTime(2024, 1, 15),
        );

        final copied = original.copyWith(name: 'New Name');

        expect(copied.id, equals('team_1'));
        expect(copied.serverId, equals(42));
        expect(copied.description, equals('Description'));
        expect(copied.name, equals('New Name'));
      });

      test('can update members list', () {
        final original = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Team',
          createdAt: DateTime.now(),
        );

        final newMembers = [
          TeamMember(
            id: 'member_1',
            userId: 100,
            username: 'newmember',
            joinedAt: DateTime.now(),
          ),
        ];

        final copied = original.copyWith(members: newMembers);

        expect(copied.members.length, equals(1));
        expect(copied.members.first.username, equals('newmember'));
      });

      test('can update shared scores', () {
        final original = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Team',
          createdAt: DateTime.now(),
        );

        final newScores = [
          Score(
            id: 'score_new',
            title: 'New Score',
            composer: 'C',
            createdAt: DateTime.now(),
          ),
        ];

        final copied = original.copyWith(sharedScores: newScores);

        expect(copied.sharedScores.length, equals(1));
        expect(copied.sharedScores.first.title, equals('New Score'));
      });
    });

    group('JSON Serialization', () {
      test('toJson produces correct map', () {
        final team = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Test Team',
          description: 'A test team',
          members: [],
          createdAt: DateTime(2024, 1, 15, 10, 30),
          sharedScores: [],
          sharedSetlists: [],
        );

        final json = team.toJson();

        expect(json['id'], equals('team_1'));
        expect(json['serverId'], equals(42));
        expect(json['name'], equals('Test Team'));
        expect(json['description'], equals('A test team'));
        expect(json['members'], isEmpty);
        expect(json['sharedScores'], isEmpty);
        expect(json['sharedSetlists'], isEmpty);
        expect(json['createdAt'], equals('2024-01-15T10:30:00.000'));
      });

      test('toJson includes nested members', () {
        final team = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Team',
          createdAt: DateTime.now(),
          members: [
            TeamMember(
              id: 'member_1',
              userId: 100,
              username: 'user1',
              joinedAt: DateTime.now(),
            ),
            TeamMember(
              id: 'member_2',
              userId: 200,
              username: 'user2',
              joinedAt: DateTime.now(),
            ),
          ],
        );

        final json = team.toJson();

        expect(json['members'], isA<List>());
        expect((json['members'] as List).length, equals(2));
      });

      test('fromJson creates team from map', () {
        final json = {
          'id': 'team_1',
          'serverId': 42,
          'name': 'Test Team',
          'description': 'A test team',
          'members': [],
          'createdAt': '2024-01-15T10:30:00.000',
          'sharedScores': [],
          'sharedSetlists': [],
        };

        final team = Team.fromJson(json);

        expect(team.id, equals('team_1'));
        expect(team.serverId, equals(42));
        expect(team.name, equals('Test Team'));
        expect(team.description, equals('A test team'));
        expect(team.members, isEmpty);
      });

      test('fromJson parses nested members', () {
        final json = {
          'id': 'team_1',
          'serverId': 42,
          'name': 'Team',
          'createdAt': '2024-01-15T10:30:00.000',
          'members': [
            {
              'id': 'member_1',
              'userId': 100,
              'username': 'user1',
              'joinedAt': '2024-01-15T10:30:00.000',
            },
          ],
        };

        final team = Team.fromJson(json);

        expect(team.members.length, equals(1));
        expect(team.members.first.username, equals('user1'));
      });

      test('fromJson parses nested scores and setlists', () {
        final json = {
          'id': 'team_1',
          'serverId': 42,
          'name': 'Team',
          'createdAt': '2024-01-15T10:30:00.000',
          'sharedScores': [
            {
              'id': 'score_1',
              'title': 'Score',
              'composer': 'C',
              'createdAt': '2024-01-15T10:30:00.000',
            },
          ],
          'sharedSetlists': [
            {
              'id': 'setlist_1',
              'name': 'Setlist',
              'scoreIds': [],
              'createdAt': '2024-01-15T10:30:00.000',
            },
          ],
        };

        final team = Team.fromJson(json);

        expect(team.sharedScores.length, equals(1));
        expect(team.sharedScores.first.title, equals('Score'));
        expect(team.sharedSetlists.length, equals(1));
        expect(team.sharedSetlists.first.name, equals('Setlist'));
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'team_1',
          'serverId': 42,
          'name': 'Team',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final team = Team.fromJson(json);

        expect(team.description, isNull);
        expect(team.members, isEmpty);
        expect(team.sharedScores, isEmpty);
        expect(team.sharedSetlists, isEmpty);
      });

      test('toJson and fromJson are symmetric', () {
        final original = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Test Team',
          description: 'Description',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          members: [
            TeamMember(
              id: 'member_1',
              userId: 100,
              username: 'user1',
              joinedAt: DateTime(2024, 1, 10),
            ),
          ],
        );

        final json = original.toJson();
        final restored = Team.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.serverId, equals(original.serverId));
        expect(restored.name, equals(original.name));
        expect(restored.description, equals(original.description));
        expect(restored.members.length, equals(original.members.length));
        expect(restored.members.first.username,
            equals(original.members.first.username));
      });
    });

    group('Team with Multiple Members', () {
      test('supports multiple team members', () {
        final members = List.generate(
          10,
          (i) => TeamMember(
            id: 'member_$i',
            userId: i + 100,
            username: 'user$i',
            joinedAt: DateTime.now(),
          ),
        );

        final team = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Large Team',
          createdAt: DateTime.now(),
          members: members,
        );

        expect(team.members.length, equals(10));
        expect(team.members[5].userId, equals(105));
      });

      test('members maintain order', () {
        final members = [
          TeamMember(
            id: 'first',
            userId: 1,
            username: 'first',
            joinedAt: DateTime.now(),
          ),
          TeamMember(
            id: 'second',
            userId: 2,
            username: 'second',
            joinedAt: DateTime.now(),
          ),
          TeamMember(
            id: 'third',
            userId: 3,
            username: 'third',
            joinedAt: DateTime.now(),
          ),
        ];

        final team = Team(
          id: 'team_1',
          serverId: 42,
          name: 'Team',
          createdAt: DateTime.now(),
          members: members,
        );

        expect(team.members[0].id, equals('first'));
        expect(team.members[1].id, equals('second'));
        expect(team.members[2].id, equals('third'));
      });
    });
  });
}
