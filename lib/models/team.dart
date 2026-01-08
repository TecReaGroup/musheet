import 'score.dart';
import 'setlist.dart';

// Re-export from score.dart
export 'score.dart' show InstrumentType, InstrumentScore, Score;
export 'setlist.dart' show Setlist;

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
  // Scores and setlists for this team (populated by providers)
  final List<Score> sharedScores;
  final List<Setlist> sharedSetlists;

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
    List<Score>? sharedScores,
    List<Setlist>? sharedSetlists,
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
                .map((s) => Score.fromJson(s))
                .toList()
            : [],
        sharedSetlists: json['sharedSetlists'] != null
            ? (json['sharedSetlists'] as List)
                .map((s) => Setlist.fromJson(s))
                .toList()
            : [],
      );
}
