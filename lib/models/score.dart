import 'base_models.dart';
import 'instrument_score.dart';

// Re-export InstrumentType and InstrumentScore so existing imports still work
export 'instrument_score.dart' show InstrumentType, InstrumentScore;

/// Unified Score model for both user and team scopes
/// Per sync_logic.md: scopeType + scopeId distinguishes user vs team data
class Score with ScoreBase {
  @override
  final String id;
  final int? serverId; // Server-assigned ID for sync

  // Scope fields - determines if this is user or team data
  final String scopeType; // 'user' or 'team'
  final int scopeId; // userId for 'user' scope, teamId for 'team' scope

  @override
  final String title;
  @override
  final String composer;
  @override
  final DateTime createdAt;
  @override
  final int bpm;

  // Team-specific fields (nullable for user scope)
  final int? createdById; // Who created this (for team scores)
  final int? sourceScoreId; // Original score if copied

  final List<InstrumentScore> instrumentScores;

  Score({
    required this.id,
    this.serverId,
    this.scopeType = 'user',
    this.scopeId = 0,
    required this.title,
    required this.composer,
    required this.createdAt,
    this.bpm = 120,
    this.createdById,
    this.sourceScoreId,
    this.instrumentScores = const [],
  });

  /// Check if this is a team score
  bool get isTeamScore => scopeType == 'team';

  /// Get teamId (alias for scopeId when scopeType is 'team')
  int get teamId => scopeId;

  // scoreKey is provided by ScoreBase mixin

  /// Get all existing instrument keys in this score
  Set<String> get existingInstrumentKeys =>
      getExistingInstrumentKeys(instrumentScores);

  /// Check if an instrument already exists in this score
  bool hasInstrument(InstrumentType type, String? customInstrument) =>
      hasInstrumentInCollection(instrumentScores, type, customInstrument);

  /// Get the first instrument score (for backward compatibility)
  InstrumentScore? get firstInstrumentScore =>
      instrumentScores.isNotEmpty ? instrumentScores.first : null;

  /// Get total annotation count across all instrument scores
  int get totalAnnotationCount => instrumentScores.fold(
        0,
        (sum, s) => sum + (s.annotations?.length ?? 0),
      );

  Score copyWith({
    String? id,
    int? serverId,
    String? scopeType,
    int? scopeId,
    String? title,
    String? composer,
    DateTime? createdAt,
    int? bpm,
    int? createdById,
    int? sourceScoreId,
    List<InstrumentScore>? instrumentScores,
  }) =>
      Score(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        scopeType: scopeType ?? this.scopeType,
        scopeId: scopeId ?? this.scopeId,
        title: title ?? this.title,
        composer: composer ?? this.composer,
        createdAt: createdAt ?? this.createdAt,
        bpm: bpm ?? this.bpm,
        createdById: createdById ?? this.createdById,
        sourceScoreId: sourceScoreId ?? this.sourceScoreId,
        instrumentScores: instrumentScores ?? this.instrumentScores,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'scopeType': scopeType,
        'scopeId': scopeId,
        'title': title,
        'composer': composer,
        'createdAt': createdAt.toIso8601String(),
        'bpm': bpm,
        'createdById': createdById,
        'sourceScoreId': sourceScoreId,
        'instrumentScores': instrumentScores.map((s) => s.toJson()).toList(),
      };

  factory Score.fromJson(Map<String, dynamic> json) => Score(
        id: json['id'],
        serverId: json['serverId'],
        scopeType: json['scopeType'] ?? 'user',
        scopeId: json['scopeId'] ?? 0,
        title: json['title'],
        composer: json['composer'],
        createdAt: DateTime.parse(json['createdAt']),
        bpm: json['bpm'] ?? 120,
        createdById: json['createdById'],
        sourceScoreId: json['sourceScoreId'],
        instrumentScores: json['instrumentScores'] != null
            ? (json['instrumentScores'] as List)
                .map((s) => InstrumentScore.fromJson(s))
                .toList()
            : [],
      );
}
