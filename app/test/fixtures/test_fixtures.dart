/// Test fixtures for unit tests
///
/// Provides reusable test data for Score, Setlist, InstrumentScore, etc.
library;

import 'package:musheet/models/team.dart';
import 'package:musheet/models/annotation.dart';

/// Test fixtures factory
class TestFixtures {
  TestFixtures._();

  // ============================================================================
  // Score Fixtures
  // ============================================================================

  static Score createScore({
    String? id,
    int? serverId,
    String title = 'Test Score',
    String composer = 'Test Composer',
    DateTime? createdAt,
    int bpm = 120,
    String scopeType = 'user',
    int scopeId = 0,
    List<InstrumentScore>? instrumentScores,
  }) {
    return Score(
      id: id ?? 'score_${DateTime.now().millisecondsSinceEpoch}',
      serverId: serverId,
      title: title,
      composer: composer,
      createdAt: createdAt ?? DateTime.now(),
      bpm: bpm,
      scopeType: scopeType,
      scopeId: scopeId,
      instrumentScores: instrumentScores ?? [],
    );
  }

  static Score get sampleScore => createScore(
        id: 'score_1',
        title: 'Symphony No. 5',
        composer: 'Beethoven',
        bpm: 108,
      );

  static Score get sampleScoreWithServerId => createScore(
        id: 'score_1',
        serverId: 100,
        title: 'Symphony No. 5',
        composer: 'Beethoven',
        bpm: 108,
      );

  static Score get sampleTeamScore => createScore(
        id: 'team_score_1',
        title: 'Team Song',
        composer: 'Team Composer',
        scopeType: 'team',
        scopeId: 1,
      );

  static List<Score> get sampleScoreList => [
        createScore(id: 'score_1', title: 'Score 1', composer: 'Composer A'),
        createScore(id: 'score_2', title: 'Score 2', composer: 'Composer B'),
        createScore(id: 'score_3', title: 'Score 3', composer: 'Composer C'),
      ];

  // ============================================================================
  // InstrumentScore Fixtures
  // ============================================================================

  static InstrumentScore createInstrumentScore({
    String? id,
    String? scoreId,
    InstrumentType instrumentType = InstrumentType.keyboard,
    String? customInstrument,
    String pdfPath = '/path/to/test.pdf',
    String? pdfHash,
    String? thumbnail,
    int orderIndex = 0,
    List<Annotation>? annotations,
    DateTime? createdAt,
  }) {
    return InstrumentScore(
      id: id ?? 'is_${DateTime.now().millisecondsSinceEpoch}',
      scoreId: scoreId ?? 'score_1',
      instrumentType: instrumentType,
      customInstrument: customInstrument,
      pdfPath: pdfPath,
      pdfHash: pdfHash,
      thumbnail: thumbnail,
      orderIndex: orderIndex,
      annotations: annotations,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static InstrumentScore get sampleInstrumentScore => createInstrumentScore(
        id: 'is_1',
        scoreId: 'score_1',
        instrumentType: InstrumentType.keyboard,
        pdfPath: '/test/piano.pdf',
        pdfHash: 'abc123hash',
      );

  static InstrumentScore get sampleInstrumentScoreWithAnnotations =>
      createInstrumentScore(
        id: 'is_2',
        scoreId: 'score_1',
        instrumentType: InstrumentType.vocal,
        annotations: [
          Annotation(
            id: 'ann_1',
            type: 'draw',
            color: '#000000',
            width: 2.0,
            points: [0.1, 0.1, 0.2, 0.2],
            page: 1,
          ),
        ],
      );

  // ============================================================================
  // Setlist Fixtures
  // ============================================================================

  static Setlist createSetlist({
    String? id,
    int? serverId,
    String name = 'Test Setlist',
    String? description,
    List<String>? scoreIds,
    DateTime? createdAt,
    String scopeType = 'user',
    int scopeId = 0,
  }) {
    return Setlist(
      id: id ?? 'setlist_${DateTime.now().millisecondsSinceEpoch}',
      serverId: serverId,
      name: name,
      description: description,
      scoreIds: scoreIds ?? [],
      createdAt: createdAt ?? DateTime.now(),
      scopeType: scopeType,
      scopeId: scopeId,
    );
  }

  static Setlist get sampleSetlist => createSetlist(
        id: 'setlist_1',
        name: 'Concert Setlist',
        description: 'Songs for the concert',
        scoreIds: ['score_1', 'score_2'],
      );

  static Setlist get sampleSetlistWithServerId => createSetlist(
        id: 'setlist_1',
        serverId: 200,
        name: 'Concert Setlist',
        description: 'Songs for the concert',
        scoreIds: ['score_1', 'score_2'],
      );

  static List<Setlist> get sampleSetlistList => [
        createSetlist(id: 'setlist_1', name: 'Setlist 1'),
        createSetlist(id: 'setlist_2', name: 'Setlist 2'),
      ];

  // ============================================================================
  // Annotation Fixtures
  // ============================================================================

  static Annotation createAnnotation({
    String? id,
    int page = 1,
    String type = 'draw',
    List<double>? points,
    String color = '#000000',
    double width = 2.0,
  }) {
    return Annotation(
      id: id ?? 'ann_${DateTime.now().millisecondsSinceEpoch}',
      page: page,
      type: type,
      points: points ?? [0.5, 0.5, 0.6, 0.6],
      color: color,
      width: width,
    );
  }

  static List<Annotation> get sampleAnnotations => [
        createAnnotation(id: 'ann_1', page: 1),
        createAnnotation(id: 'ann_2', page: 2),
      ];

  // ============================================================================
  // Sync Related Fixtures (Maps for pending data)
  // ============================================================================

  static Map<String, dynamic> createPendingScoreMap({
    String id = 'score_1',
    int? serverId,
    String title = 'Test Score',
    String composer = 'Test Composer',
  }) {
    return {
      'id': id,
      'serverId': serverId,
      'title': title,
      'composer': composer,
      'bpm': 120,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createPendingInstrumentScoreMap({
    String id = 'is_1',
    int? serverId,
    String scoreId = 'score_1',
    int? scoreServerId,
    String instrumentType = 'keyboard',
    String? pdfHash,
  }) {
    return {
      'id': id,
      'serverId': serverId,
      'scoreId': scoreId,
      'scoreServerId': scoreServerId,
      'instrumentType': instrumentType,
      'pdfPath': '/test/test.pdf',
      'pdfHash': pdfHash,
      'orderIndex': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createPendingSetlistMap({
    String id = 'setlist_1',
    int? serverId,
    String name = 'Test Setlist',
  }) {
    return {
      'id': id,
      'serverId': serverId,
      'name': name,
      'description': 'Test description',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createPendingSetlistScoreMap({
    String id = 'setlist_1:score_1',
    int? serverId,
    String setlistId = 'setlist_1',
    int? setlistServerId,
    String scoreId = 'score_1',
    int? scoreServerId,
    int orderIndex = 0,
  }) {
    return {
      'id': id,
      'serverId': serverId,
      'setlistId': setlistId,
      'setlistServerId': setlistServerId,
      'scoreId': scoreId,
      'scoreServerId': scoreServerId,
      'orderIndex': orderIndex,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // ============================================================================
  // Team Fixtures
  // ============================================================================

  static Team createTeam({
    String? id,
    int serverId = 1,
    String name = 'Test Team',
    String? description,
    List<TeamMember>? members,
    DateTime? createdAt,
    List<Score>? sharedScores,
    List<Setlist>? sharedSetlists,
  }) {
    return Team(
      id: id ?? 'team_${DateTime.now().millisecondsSinceEpoch}',
      serverId: serverId,
      name: name,
      description: description,
      members: members ?? [],
      createdAt: createdAt ?? DateTime.now(),
      sharedScores: sharedScores ?? [],
      sharedSetlists: sharedSetlists ?? [],
    );
  }

  static Team get sampleTeam => createTeam(
        id: 'team_1',
        serverId: 42,
        name: 'Sample Band',
        description: 'A sample music band',
      );

  static Team get sampleTeamWithMembers => createTeam(
        id: 'team_2',
        serverId: 100,
        name: 'Band with Members',
        members: sampleTeamMembers,
      );

  // ============================================================================
  // TeamMember Fixtures
  // ============================================================================

  static TeamMember createTeamMember({
    String? id,
    int userId = 1,
    String username = 'testuser',
    String? displayName,
    String? avatarUrl,
    String role = 'member',
    DateTime? joinedAt,
  }) {
    return TeamMember(
      id: id ?? 'member_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: role,
      joinedAt: joinedAt ?? DateTime.now(),
    );
  }

  static TeamMember get sampleTeamMember => createTeamMember(
        id: 'member_1',
        userId: 100,
        username: 'johnsmith',
        displayName: 'John Smith',
      );

  static List<TeamMember> get sampleTeamMembers => [
        createTeamMember(
          id: 'member_1',
          userId: 100,
          username: 'john',
          displayName: 'John',
        ),
        createTeamMember(
          id: 'member_2',
          userId: 101,
          username: 'jane',
          displayName: 'Jane',
        ),
        createTeamMember(
          id: 'member_3',
          userId: 102,
          username: 'bob',
          displayName: 'Bob',
        ),
      ];
}
