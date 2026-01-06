import 'base_models.dart';
import 'instrument_score.dart';

// Re-export InstrumentType and InstrumentScore so existing imports still work
export 'instrument_score.dart' show InstrumentType, InstrumentScore;

class Score with ScoreBase {
  @override
  final String id;
  final int? serverId; // Server-assigned ID for sync (per TEAM_SYNC_LOGIC.md)
  @override
  final String title;
  @override
  final String composer;
  @override
  final DateTime createdAt;
  @override
  final int bpm;
  final List<InstrumentScore> instrumentScores;

  Score({
    required this.id,
    this.serverId,
    required this.title,
    required this.composer,
    required this.createdAt,
    this.bpm = 120,
    this.instrumentScores = const [],
  });

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
    String? title,
    String? composer,
    DateTime? createdAt,
    int? bpm,
    List<InstrumentScore>? instrumentScores,
  }) =>
      Score(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        title: title ?? this.title,
        composer: composer ?? this.composer,
        createdAt: createdAt ?? this.createdAt,
        bpm: bpm ?? this.bpm,
        instrumentScores: instrumentScores ?? this.instrumentScores,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'title': title,
        'composer': composer,
        'createdAt': createdAt.toIso8601String(),
        'bpm': bpm,
        'instrumentScores': instrumentScores.map((s) => s.toJson()).toList(),
      };

  factory Score.fromJson(Map<String, dynamic> json) => Score(
        id: json['id'],
        serverId: json['serverId'],
        title: json['title'],
        composer: json['composer'],
        createdAt: DateTime.parse(json['createdAt']),
        bpm: json['bpm'] ?? 120,
        instrumentScores: json['instrumentScores'] != null
            ? (json['instrumentScores'] as List)
                .map((s) => InstrumentScore.fromJson(s))
                .toList()
            : [],
      );
}