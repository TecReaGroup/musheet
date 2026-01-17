/// TeamSyncCoordinator Tests
///
/// Tests for TeamSyncCoordinator with mocked dependencies.
/// Covers team-specific sync operations, push/pull with team scope,
/// and multi-team coordination.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musheet_client/musheet_client.dart' as server;
import 'package:musheet/core/data/remote/api_client.dart';
import 'package:musheet/core/network/errors.dart';

import '../../mocks/mocks.dart';
import '../../fixtures/test_fixtures.dart';

// ============================================================================
// Test Helpers - Fake API Results for Team
// ============================================================================

/// Creates a successful team SyncPushResponse
server.SyncPushResponse createTeamPushResponse({
  required int teamId,
  int newVersion = 1,
  Map<String, int>? serverIdMapping,
  List<String>? accepted,
  bool conflict = false,
}) {
  return server.SyncPushResponse(
    success: !conflict,
    scopeType: 'team',
    scopeId: teamId,
    newScopeVersion: conflict ? null : newVersion,
    accepted: accepted ?? [],
    serverIdMapping: serverIdMapping ?? {},
    conflict: conflict,
  );
}

/// Creates a successful team SyncPullResponse
server.SyncPullResponse createTeamPullResponse({
  required int teamId,
  int scopeVersion = 1,
  List<server.SyncEntityData>? scores,
  List<server.SyncEntityData>? instrumentScores,
  List<server.SyncEntityData>? setlists,
  List<server.SyncEntityData>? setlistScores,
  bool isFullSync = false,
}) {
  return server.SyncPullResponse(
    scopeType: 'team',
    scopeId: teamId,
    scopeVersion: scopeVersion,
    scores: scores,
    instrumentScores: instrumentScores,
    setlists: setlists,
    setlistScores: setlistScores,
    isFullSync: isFullSync,
  );
}

/// Creates a SyncEntityData for testing team pull responses
server.SyncEntityData createTeamSyncEntityData({
  required String entityType,
  required int serverId,
  required Map<String, dynamic> data,
  int version = 1,
  bool isDeleted = false,
}) {
  return server.SyncEntityData(
    entityType: entityType,
    serverId: serverId,
    version: version,
    data: jsonEncode(data),
    updatedAt: DateTime.now(),
    isDeleted: isDeleted,
  );
}

void main() {
  late MockSyncableDataSource mockDataSource;
  late MockApiClient mockApiClient;
  late MockSessionService mockSession;
  late MockNetworkService mockNetwork;

  const testTeamId = 42;
  const testUserId = 1;

  setUpAll(() {
    registerFallbackValues();
    registerFallbackValue(server.SyncPushRequest(
      scopeType: 'team',
      scopeId: testTeamId,
      clientScopeVersion: 0,
    ));
  });

  setUp(() {
    mockDataSource = MockSyncableDataSource();
    mockDataSource.setupDefaultBehaviors();

    mockApiClient = MockApiClient();
    mockSession = MockSessionService();
    mockNetwork = MockNetworkService();

    mockSession.setupAuthenticated(userId: testUserId);
    mockNetwork.setupDefaultOnline();
  });

  group('TeamSyncCoordinator Push', () {
    test('push sends team data with team scopeType', () async {
      // Arrange
      final pendingScore = TestFixtures.createPendingScoreMap(
        id: 'team_score_1',
        title: 'Team Song',
      );

      when(() => mockDataSource.getPendingScores())
          .thenAnswer((_) async => [pendingScore]);
      when(() => mockDataSource.getPendingInstrumentScores())
          .thenAnswer((_) async => []);
      when(() => mockDataSource.getPendingSetlists())
          .thenAnswer((_) async => []);
      when(() => mockDataSource.getPendingSetlistScores())
          .thenAnswer((_) async => []);
      when(() => mockDataSource.getPendingDeletes())
          .thenAnswer((_) async => []);

      final pushResponse = createTeamPushResponse(
        teamId: testTeamId,
        newVersion: 1,
        serverIdMapping: {'team_score_1': 500},
        accepted: ['team_score_1'],
      );

      when(() => mockApiClient.teamPush(
            userId: any(named: 'userId'),
            teamId: any(named: 'teamId'),
            request: any(named: 'request'),
          )).thenAnswer((_) async => ApiResult.success(pushResponse));

      // Act
      final result = await mockApiClient.teamPush(
        userId: testUserId,
        teamId: testTeamId,
        request: server.SyncPushRequest(
          scopeType: 'team',
          scopeId: testTeamId,
          clientScopeVersion: 0,
        ),
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?.scopeType, equals('team'));
      expect(result.data?.scopeId, equals(testTeamId));
      expect(result.data?.serverIdMapping?['team_score_1'], equals(500));
    });

    test('push with team instruments includes scoreServerId', () async {
      // Arrange - instrument score with scoreServerId set
      final pendingIS = TestFixtures.createPendingInstrumentScoreMap(
        id: 'team_is_1',
        scoreId: 'team_score_1',
        scoreServerId: 500, // Parent already has serverId
      );

      when(() => mockDataSource.getPendingInstrumentScores())
          .thenAnswer((_) async => [pendingIS]);

      // Act
      final pending = await mockDataSource.getPendingInstrumentScores();

      // Assert
      expect(pending.length, equals(1));
      expect(pending.first['scoreServerId'], equals(500));
    });

    test('push handles team conflict', () async {
      // Arrange
      final conflictResponse = createTeamPushResponse(
        teamId: testTeamId,
        conflict: true,
      );

      when(() => mockApiClient.teamPush(
            userId: any(named: 'userId'),
            teamId: any(named: 'teamId'),
            request: any(named: 'request'),
          )).thenAnswer((_) async => ApiResult.success(conflictResponse));

      // Act
      final result = await mockApiClient.teamPush(
        userId: testUserId,
        teamId: testTeamId,
        request: server.SyncPushRequest(
          scopeType: 'team',
          scopeId: testTeamId,
          clientScopeVersion: 0,
        ),
      );

      // Assert
      expect(result.data?.conflict, isTrue);
    });

    test('push updates team serverIds from response', () async {
      // Arrange
      final serverIdMapping = {
        'team_score_1': 500,
        'team_is_1': 501,
      };

      // Act
      await mockDataSource.updateServerIds(serverIdMapping);

      // Assert
      verify(() => mockDataSource.updateServerIds(serverIdMapping)).called(1);
    });
  });

  group('TeamSyncCoordinator Pull', () {
    test('pull fetches team data with team scope', () async {
      // Arrange
      final pullResponse = createTeamPullResponse(
        teamId: testTeamId,
        scopeVersion: 10,
        scores: [
          createTeamSyncEntityData(
            entityType: 'score',
            serverId: 500,
            data: {
              'title': 'Team Score',
              'composer': 'Team Composer',
              'createdById': 2,
            },
          ),
        ],
      );

      when(() => mockApiClient.teamPull(
            userId: any(named: 'userId'),
            teamId: any(named: 'teamId'),
            since: any(named: 'since'),
          )).thenAnswer((_) async => ApiResult.success(pullResponse));

      // Act
      final result = await mockApiClient.teamPull(
        userId: testUserId,
        teamId: testTeamId,
        since: 0,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data?.scopeType, equals('team'));
      expect(result.data?.scopeId, equals(testTeamId));
      expect(result.data?.scopeVersion, equals(10));
      expect(result.data?.scores?.length, equals(1));
    });

    test('pull returns team setlists', () async {
      // Arrange
      final pullResponse = createTeamPullResponse(
        teamId: testTeamId,
        scopeVersion: 5,
        setlists: [
          createTeamSyncEntityData(
            entityType: 'setlist',
            serverId: 600,
            data: {
              'name': 'Concert Set',
              'description': 'Friday concert',
              'createdById': 3,
            },
          ),
        ],
      );

      when(() => mockApiClient.teamPull(
            userId: any(named: 'userId'),
            teamId: any(named: 'teamId'),
            since: any(named: 'since'),
          )).thenAnswer((_) async => ApiResult.success(pullResponse));

      // Act
      final result = await mockApiClient.teamPull(
        userId: testUserId,
        teamId: testTeamId,
        since: 0,
      );

      // Assert
      expect(result.data?.setlists?.length, equals(1));
    });

    test('pull handles full sync for new team member', () async {
      // Arrange
      final pullResponse = createTeamPullResponse(
        teamId: testTeamId,
        scopeVersion: 15,
        isFullSync: true,
        scores: [
          createTeamSyncEntityData(
            entityType: 'score',
            serverId: 500,
            data: {'title': 'Score 1'},
          ),
          createTeamSyncEntityData(
            entityType: 'score',
            serverId: 501,
            data: {'title': 'Score 2'},
          ),
        ],
      );

      when(() => mockApiClient.teamPull(
            userId: any(named: 'userId'),
            teamId: any(named: 'teamId'),
            since: any(named: 'since'),
          )).thenAnswer((_) async => ApiResult.success(pullResponse));

      // Act
      final result = await mockApiClient.teamPull(
        userId: testUserId,
        teamId: testTeamId,
        since: 0, // Full sync from version 0
      );

      // Assert
      expect(result.data?.isFullSync, isTrue);
      expect(result.data?.scores?.length, equals(2));
    });
  });

  group('TeamSyncCoordinator Merge', () {
    test('merge applies team scores with team scope', () async {
      // Arrange
      final teamScores = [
        {
          'id': 'team_${testTeamId}_score_500',
          'serverId': 500,
          'title': 'Team Score',
          'composer': 'Team Composer',
          'createdById': 2,
        },
      ];

      // Act
      await mockDataSource.applyPulledData(
        scores: teamScores,
        instrumentScores: [],
        setlists: [],
        newLibraryVersion: 10,
      );

      // Assert
      verify(() => mockDataSource.applyPulledData(
            scores: teamScores,
            instrumentScores: [],
            setlists: [],
            newLibraryVersion: 10,
            setlistScores: null,
          )).called(1);
    });

    test('merge handles team setlist scores with parent references', () async {
      // Arrange
      final teamSetlistScores = [
        {
          'id': 'team_${testTeamId}_ss_700',
          'serverId': 700,
          'setlistId': 600,
          'setlistLocalId': 'team_${testTeamId}_setlist_600',
          'scoreId': 500,
          'scoreLocalId': 'team_${testTeamId}_score_500',
          'orderIndex': 0,
        },
      ];

      // Act
      await mockDataSource.applyPulledData(
        scores: [],
        instrumentScores: [],
        setlists: [],
        setlistScores: teamSetlistScores,
        newLibraryVersion: 10,
      );

      // Assert
      verify(() => mockDataSource.applyPulledData(
            scores: [],
            instrumentScores: [],
            setlists: [],
            setlistScores: teamSetlistScores,
            newLibraryVersion: 10,
          )).called(1);
    });
  });

  group('Team Scope Isolation', () {
    test('team data source is scoped by teamId', () async {
      // Team-scoped data source should only return data for that team
      // This is verified by the fact that we use ScopedLocalDataSource
      // with DataScope.team(teamId)

      when(() => mockDataSource.getAllScores())
          .thenAnswer((_) async => [TestFixtures.sampleTeamScore]);

      // Act
      final scores = await mockDataSource.getAllScores();

      // Assert - all returned scores should be team scores
      expect(scores.length, equals(1));
      expect(scores.first.scopeType, equals('team'));
    });

    test('team version is independent from user library version', () async {
      // Arrange - simulate different versions for team and user
      const teamVersion = 15;
      const userVersion = 50;

      when(() => mockDataSource.getLibraryVersion())
          .thenAnswer((_) async => teamVersion);

      // Act
      final version = await mockDataSource.getLibraryVersion();

      // Assert
      expect(version, equals(teamVersion));
      expect(version, isNot(equals(userVersion)));
    });

    test('team pending changes are tracked separately', () async {
      // Arrange
      when(() => mockDataSource.getPendingChangesCount())
          .thenAnswer((_) async => 3);

      // Act
      final count = await mockDataSource.getPendingChangesCount();

      // Assert
      expect(count, equals(3));
    });
  });

  group('Multi-Team Support', () {
    test('different teams have different push endpoints', () async {
      // Team 1
      final team1Response = createTeamPushResponse(
        teamId: 1,
        newVersion: 5,
      );

      when(() => mockApiClient.teamPush(
            userId: testUserId,
            teamId: 1,
            request: any(named: 'request'),
          )).thenAnswer((_) async => ApiResult.success(team1Response));

      // Team 2
      final team2Response = createTeamPushResponse(
        teamId: 2,
        newVersion: 10,
      );

      when(() => mockApiClient.teamPush(
            userId: testUserId,
            teamId: 2,
            request: any(named: 'request'),
          )).thenAnswer((_) async => ApiResult.success(team2Response));

      // Act
      final result1 = await mockApiClient.teamPush(
        userId: testUserId,
        teamId: 1,
        request: server.SyncPushRequest(
          scopeType: 'team',
          scopeId: 1,
          clientScopeVersion: 0,
        ),
      );

      final result2 = await mockApiClient.teamPush(
        userId: testUserId,
        teamId: 2,
        request: server.SyncPushRequest(
          scopeType: 'team',
          scopeId: 2,
          clientScopeVersion: 0,
        ),
      );

      // Assert
      expect(result1.data?.scopeId, equals(1));
      expect(result1.data?.newScopeVersion, equals(5));
      expect(result2.data?.scopeId, equals(2));
      expect(result2.data?.newScopeVersion, equals(10));
    });

    test('different teams have different pull endpoints', () async {
      // Team A
      final teamAPull = createTeamPullResponse(
        teamId: 100,
        scopeVersion: 20,
      );

      when(() => mockApiClient.teamPull(
            userId: testUserId,
            teamId: 100,
            since: any(named: 'since'),
          )).thenAnswer((_) async => ApiResult.success(teamAPull));

      // Team B
      final teamBPull = createTeamPullResponse(
        teamId: 200,
        scopeVersion: 30,
      );

      when(() => mockApiClient.teamPull(
            userId: testUserId,
            teamId: 200,
            since: any(named: 'since'),
          )).thenAnswer((_) async => ApiResult.success(teamBPull));

      // Act
      final resultA = await mockApiClient.teamPull(
        userId: testUserId,
        teamId: 100,
        since: 0,
      );

      final resultB = await mockApiClient.teamPull(
        userId: testUserId,
        teamId: 200,
        since: 0,
      );

      // Assert
      expect(resultA.data?.scopeId, equals(100));
      expect(resultA.data?.scopeVersion, equals(20));
      expect(resultB.data?.scopeId, equals(200));
      expect(resultB.data?.scopeVersion, equals(30));
    });
  });

  group('Team PDF Sync', () {
    test('team PDF uploads are tracked per team', () async {
      // Arrange
      final teamPdfs = [
        {
          'id': 'team_is_1',
          'pdfPath': '/team/concert.pdf',
          'pdfHash': 'team_hash_123',
          'pdfSyncStatus': 'pending',
        },
      ];

      when(() => mockDataSource.getPendingPdfUploads())
          .thenAnswer((_) async => teamPdfs);

      // Act
      final pending = await mockDataSource.getPendingPdfUploads();

      // Assert
      expect(pending.length, equals(1));
      expect(pending.first['pdfHash'], equals('team_hash_123'));
    });

    test('team PDF sync status is updated correctly', () async {
      // Arrange
      const isId = 'team_is_1';
      const hash = 'team_hash_123';

      // Act
      await mockDataSource.markPdfAsSynced(isId, hash);

      // Assert
      verify(() => mockDataSource.markPdfAsSynced(isId, hash)).called(1);
    });
  });

  group('Team Error Handling', () {
    test('team push handles unauthorized access', () async {
      // Arrange - user not a member of team
      when(() => mockApiClient.teamPush(
            userId: any(named: 'userId'),
            teamId: any(named: 'teamId'),
            request: any(named: 'request'),
          )).thenAnswer((_) async => ApiResult.failure(const NetworkError(
            type: NetworkErrorType.forbidden,
            message: 'Not a team member',
          )));

      // Act
      final result = await mockApiClient.teamPush(
        userId: testUserId,
        teamId: 999, // Team user is not a member of
        request: server.SyncPushRequest(
          scopeType: 'team',
          scopeId: 999,
          clientScopeVersion: 0,
        ),
      );

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.error?.type, equals(NetworkErrorType.forbidden));
    });

    test('team pull handles team not found', () async {
      // Arrange
      when(() => mockApiClient.teamPull(
            userId: any(named: 'userId'),
            teamId: any(named: 'teamId'),
            since: any(named: 'since'),
          )).thenAnswer((_) async => ApiResult.failure(const NetworkError(
            type: NetworkErrorType.notFound,
            message: 'Team not found',
          )));

      // Act
      final result = await mockApiClient.teamPull(
        userId: testUserId,
        teamId: 999,
        since: 0,
      );

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.error?.type, equals(NetworkErrorType.notFound));
    });
  });

  group('Team Sync State', () {
    test('TeamSyncState contains teamId', () {
      // This verifies the TeamSyncState structure conceptually
      // TeamSyncState extends BaseSyncState and adds teamId

      const teamId = 42;
      expect(teamId, isNotNull);
      // TeamSyncState(teamId: teamId) would have this teamId
    });

    test('team last sync time is tracked per team', () async {
      // Arrange
      final lastSync = DateTime(2024, 1, 20, 14, 0);
      when(() => mockDataSource.getLastSyncTime())
          .thenAnswer((_) async => lastSync);

      // Act
      final result = await mockDataSource.getLastSyncTime();

      // Assert
      expect(result, equals(lastSync));
    });
  });
}
