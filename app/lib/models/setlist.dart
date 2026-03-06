import 'base_models.dart';

/// Unified Setlist model for both user and team scopes
/// Per sync_logic.md: scopeType + scopeId distinguishes user vs team data
class Setlist with SetlistBase {
  @override
  final String id;
  final int? serverId; // Server-assigned ID for sync

  // Scope fields - determines if this is user or team data
  final String scopeType; // 'user' or 'team'
  final int scopeId; // userId for 'user' scope, teamId for 'team' scope

  @override
  final String name;
  @override
  final String? description;
  @override
  final List<String> scoreIds; // Store only score IDs as references
  @override
  final DateTime createdAt;

  // Team-specific fields (nullable for user scope)
  final int? createdById; // Who created this (for team setlists)
  final int? sourceSetlistId; // Original setlist if copied

  Setlist({
    required this.id,
    this.serverId,
    this.scopeType = 'user',
    this.scopeId = 0,
    required this.name,
    this.description,
    required this.scoreIds,
    required this.createdAt,
    this.createdById,
    this.sourceSetlistId,
  });

  /// Check if this is a team setlist
  bool get isTeamSetlist => scopeType == 'team';

  /// Get teamId (alias for scopeId when scopeType is 'team')
  int get teamId => scopeId;

  /// Alias for scoreIds (backward compatibility with TeamSetlist)
  List<String> get teamScoreIds => scoreIds;

  Setlist copyWith({
    String? id,
    int? serverId,
    String? scopeType,
    int? scopeId,
    String? name,
    String? description,
    List<String>? scoreIds,
    DateTime? createdAt,
    int? createdById,
    int? sourceSetlistId,
    // Alias for backward compatibility
    List<String>? teamScoreIds,
  }) =>
      Setlist(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        scopeType: scopeType ?? this.scopeType,
        scopeId: scopeId ?? this.scopeId,
        name: name ?? this.name,
        description: description ?? this.description,
        scoreIds: scoreIds ?? teamScoreIds ?? this.scoreIds,
        createdAt: createdAt ?? this.createdAt,
        createdById: createdById ?? this.createdById,
        sourceSetlistId: sourceSetlistId ?? this.sourceSetlistId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'scopeType': scopeType,
        'scopeId': scopeId,
        'name': name,
        'description': description,
        'scoreIds': scoreIds,
        'createdAt': createdAt.toIso8601String(),
        'createdById': createdById,
        'sourceSetlistId': sourceSetlistId,
      };

  factory Setlist.fromJson(Map<String, dynamic> json) => Setlist(
        id: json['id'],
        serverId: json['serverId'],
        scopeType: json['scopeType'] ?? 'user',
        scopeId: json['scopeId'] ?? json['teamId'] ?? 0,
        name: json['name'],
        description: json['description'],
        scoreIds: json['scoreIds'] != null
            ? (json['scoreIds'] as List).cast<String>()
            : json['teamScoreIds'] != null
                ? (json['teamScoreIds'] as List).cast<String>()
                : [],
        createdAt: DateTime.parse(json['createdAt']),
        createdById: json['createdById'],
        sourceSetlistId: json['sourceSetlistId'],
      );
}
