import 'annotation.dart';
import 'base_models.dart';
import 'score.dart';

// Re-export from score.dart
export 'score.dart' show InstrumentType;

/// Team member data
class TeamMember {
  final String id;
  final int userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String role; // Always 'member' per TEAM_SYNC_LOGIC.md
  final DateTime joinedAt;

  TeamMember({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.role = 'member',
    required this.joinedAt,
  });

  String get name => displayName ?? username;

  TeamMember copyWith({
    String? id,
    int? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? role,
    DateTime? joinedAt,
  }) =>
      TeamMember(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role ?? this.role,
        joinedAt: joinedAt ?? this.joinedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'role': role,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        id: json['id'],
        userId: json['userId'],
        username: json['username'],
        displayName: json['displayName'],
        avatarUrl: json['avatarUrl'],
        role: json['role'] ?? 'member',
        joinedAt: DateTime.parse(json['joinedAt']),
      );
}

/// Team data
class Team {
  final String id;
  final int serverId;
  final String name;
  final String? description;
  final List<TeamMember> members;
  final DateTime createdAt;
  // Backwards compatibility - these are populated by providers
  final List<TeamScore> sharedScores;
  final List<TeamSetlist> sharedSetlists;

  Team({
    required this.id,
    required this.serverId,
    required this.name,
    this.description,
    this.members = const [],
    required this.createdAt,
    this.sharedScores = const [],
    this.sharedSetlists = const [],
  });

  Team copyWith({
    String? id,
    int? serverId,
    String? name,
    String? description,
    List<TeamMember>? members,
    DateTime? createdAt,
    List<TeamScore>? sharedScores,
    List<TeamSetlist>? sharedSetlists,
  }) =>
      Team(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        name: name ?? this.name,
        description: description ?? this.description,
        members: members ?? this.members,
        createdAt: createdAt ?? this.createdAt,
        sharedScores: sharedScores ?? this.sharedScores,
        sharedSetlists: sharedSetlists ?? this.sharedSetlists,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'name': name,
        'description': description,
        'members': members.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'sharedScores': sharedScores.map((s) => s.toJson()).toList(),
        'sharedSetlists': sharedSetlists.map((s) => s.toJson()).toList(),
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'],
        serverId: json['serverId'],
        name: json['name'],
        description: json['description'],
        members: json['members'] != null
            ? (json['members'] as List)
                .map((m) => TeamMember.fromJson(m))
                .toList()
            : [],
        createdAt: DateTime.parse(json['createdAt']),
        sharedScores: json['sharedScores'] != null
            ? (json['sharedScores'] as List)
                .map((s) => TeamScore.fromJson(s))
                .toList()
            : [],
        sharedSetlists: json['sharedSetlists'] != null
            ? (json['sharedSetlists'] as List)
                .map((s) => TeamSetlist.fromJson(s))
                .toList()
            : [],
      );
}

/// TeamInstrumentScore - represents an instrument part within a TeamScore
class TeamInstrumentScore with InstrumentScoreBase {
  @override
  final String id;
  final String teamScoreId;
  @override
  final InstrumentType instrumentType;
  @override
  final String? customInstrument;
  @override
  final String? pdfPath;
  @override
  final String? pdfHash;
  @override
  final String? thumbnail;
  @override
  final int orderIndex;
  @override
  final List<Annotation>? annotations;
  @override
  final DateTime createdAt;

  TeamInstrumentScore({
    required this.id,
    required this.teamScoreId,
    required this.instrumentType,
    this.customInstrument,
    this.pdfPath,
    this.pdfHash,
    this.thumbnail,
    this.orderIndex = 0,
    this.annotations,
    required this.createdAt,
  });

  // instrumentDisplayName and instrumentKey are provided by InstrumentScoreBase mixin

  TeamInstrumentScore copyWith({
    String? id,
    String? teamScoreId,
    InstrumentType? instrumentType,
    String? customInstrument,
    String? pdfPath,
    String? pdfHash,
    String? thumbnail,
    int? orderIndex,
    List<Annotation>? annotations,
    DateTime? createdAt,
  }) =>
      TeamInstrumentScore(
        id: id ?? this.id,
        teamScoreId: teamScoreId ?? this.teamScoreId,
        instrumentType: instrumentType ?? this.instrumentType,
        customInstrument: customInstrument ?? this.customInstrument,
        pdfPath: pdfPath ?? this.pdfPath,
        pdfHash: pdfHash ?? this.pdfHash,
        thumbnail: thumbnail ?? this.thumbnail,
        orderIndex: orderIndex ?? this.orderIndex,
        annotations: annotations ?? this.annotations,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamScoreId': teamScoreId,
        'instrumentType': instrumentType.name,
        'customInstrument': customInstrument,
        'pdfPath': pdfPath,
        'pdfHash': pdfHash,
        'thumbnail': thumbnail,
        'orderIndex': orderIndex,
        'annotations': annotations?.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TeamInstrumentScore.fromJson(Map<String, dynamic> json) =>
      TeamInstrumentScore(
        id: json['id'],
        teamScoreId: json['teamScoreId'],
        instrumentType: json['instrumentType'] != null
            ? InstrumentType.values.firstWhere(
                (e) => e.name == json['instrumentType'],
                orElse: () => InstrumentType.vocal,
              )
            : InstrumentType.vocal,
        customInstrument: json['customInstrument'],
        pdfPath: json['pdfPath'],
        pdfHash: json['pdfHash'],
        thumbnail: json['thumbnail'],
        orderIndex: json['orderIndex'] ?? 0,
        annotations: json['annotations'] != null
            ? (json['annotations'] as List)
                .map((a) => Annotation.fromJson(a))
                .toList()
            : null,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

/// TeamScore - represents a score in a team (independent from personal Score)
class TeamScore with ScoreBase {
  @override
  final String id;
  final int teamId;
  @override
  final String title;
  @override
  final String composer;
  @override
  final int bpm;
  final int createdById;
  final int? sourceScoreId;
  final List<TeamInstrumentScore> instrumentScores;
  @override
  final DateTime createdAt;

  TeamScore({
    required this.id,
    required this.teamId,
    required this.title,
    required this.composer,
    this.bpm = 120,
    required this.createdById,
    this.sourceScoreId,
    this.instrumentScores = const [],
    required this.createdAt,
  });

  // scoreKey is provided by ScoreBase mixin

  /// Get all existing instrument keys in this score
  Set<String> get existingInstrumentKeys =>
      getExistingInstrumentKeys(instrumentScores);

  /// Check if an instrument already exists in this score
  bool hasInstrument(InstrumentType type, String? customInstrument) =>
      hasInstrumentInCollection(instrumentScores, type, customInstrument);

  /// Get the first instrument score
  TeamInstrumentScore? get firstInstrumentScore =>
      instrumentScores.isNotEmpty ? instrumentScores.first : null;

  TeamScore copyWith({
    String? id,
    int? teamId,
    String? title,
    String? composer,
    int? bpm,
    int? createdById,
    int? sourceScoreId,
    List<TeamInstrumentScore>? instrumentScores,
    DateTime? createdAt,
  }) =>
      TeamScore(
        id: id ?? this.id,
        teamId: teamId ?? this.teamId,
        title: title ?? this.title,
        composer: composer ?? this.composer,
        bpm: bpm ?? this.bpm,
        createdById: createdById ?? this.createdById,
        sourceScoreId: sourceScoreId ?? this.sourceScoreId,
        instrumentScores: instrumentScores ?? this.instrumentScores,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamId': teamId,
        'title': title,
        'composer': composer,
        'bpm': bpm,
        'createdById': createdById,
        'sourceScoreId': sourceScoreId,
        'instrumentScores': instrumentScores.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TeamScore.fromJson(Map<String, dynamic> json) => TeamScore(
        id: json['id'],
        teamId: json['teamId'],
        title: json['title'],
        composer: json['composer'],
        bpm: json['bpm'] ?? 120,
        createdById: json['createdById'],
        sourceScoreId: json['sourceScoreId'],
        instrumentScores: json['instrumentScores'] != null
            ? (json['instrumentScores'] as List)
                .map((s) => TeamInstrumentScore.fromJson(s))
                .toList()
            : [],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

/// TeamSetlist - represents a setlist in a team (independent from personal Setlist)
class TeamSetlist with SetlistBase {
  @override
  final String id;
  final int teamId;
  @override
  final String name;
  @override
  final String? description;
  final int createdById;
  final int? sourceSetlistId;
  final List<String> teamScoreIds;
  @override
  final DateTime createdAt;

  TeamSetlist({
    required this.id,
    required this.teamId,
    required this.name,
    this.description,
    required this.createdById,
    this.sourceSetlistId,
    this.teamScoreIds = const [],
    required this.createdAt,
  });

  // scoreIds provided by SetlistBase interface, maps to teamScoreIds
  @override
  List<String> get scoreIds => teamScoreIds;

  TeamSetlist copyWith({
    String? id,
    int? teamId,
    String? name,
    String? description,
    int? createdById,
    int? sourceSetlistId,
    List<String>? teamScoreIds,
    DateTime? createdAt,
  }) =>
      TeamSetlist(
        id: id ?? this.id,
        teamId: teamId ?? this.teamId,
        name: name ?? this.name,
        description: description ?? this.description,
        createdById: createdById ?? this.createdById,
        sourceSetlistId: sourceSetlistId ?? this.sourceSetlistId,
        teamScoreIds: teamScoreIds ?? this.teamScoreIds,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamId': teamId,
        'name': name,
        'description': description,
        'createdById': createdById,
        'sourceSetlistId': sourceSetlistId,
        'teamScoreIds': teamScoreIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TeamSetlist.fromJson(Map<String, dynamic> json) => TeamSetlist(
        id: json['id'],
        teamId: json['teamId'],
        name: json['name'],
        description: json['description'],
        createdById: json['createdById'],
        sourceSetlistId: json['sourceSetlistId'],
        teamScoreIds: json['teamScoreIds'] != null
            ? List<String>.from(json['teamScoreIds'])
            : [],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// Backwards compatibility - keep old TeamData for now
// This will be deprecated in favor of Team
class TeamData {
  final String id;
  final String name;
  final List<TeamMember> members;
  final List<Score> sharedScores;
  final List<dynamic> sharedSetlists;

  TeamData({
    required this.id,
    required this.name,
    required this.members,
    required this.sharedScores,
    required this.sharedSetlists,
  });

  TeamData copyWith({
    String? id,
    String? name,
    List<TeamMember>? members,
    List<Score>? sharedScores,
    List<dynamic>? sharedSetlists,
  }) =>
      TeamData(
        id: id ?? this.id,
        name: name ?? this.name,
        members: members ?? this.members,
        sharedScores: sharedScores ?? this.sharedScores,
        sharedSetlists: sharedSetlists ?? this.sharedSetlists,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members.map((m) => m.toJson()).toList(),
        'sharedScores': sharedScores.map((s) => s.toJson()).toList(),
        'sharedSetlists': sharedSetlists,
      };

  factory TeamData.fromJson(Map<String, dynamic> json) => TeamData(
        id: json['id'],
        name: json['name'],
        members: (json['members'] as List)
            .map((m) => TeamMember.fromJson(m))
            .toList(),
        sharedScores: (json['sharedScores'] as List)
            .map((s) => Score.fromJson(s))
            .toList(),
        sharedSetlists: json['sharedSetlists'] ?? [],
      );
}
