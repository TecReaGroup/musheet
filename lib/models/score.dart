import 'instrument_score.dart';

// Re-export InstrumentType and InstrumentScore so existing imports still work
export 'instrument_score.dart' show InstrumentType, InstrumentScore;

class Score {
  final String id;
  final int? serverId; // Server-assigned ID for sync (per TEAM_SYNC_LOGIC.md)
  final String title;
  final String composer;
  final DateTime dateAdded;
  final int bpm;
  final List<InstrumentScore> instrumentScores;

  Score({
    required this.id,
    this.serverId,
    required this.title,
    required this.composer,
    required this.dateAdded,
    this.bpm = 120,
    this.instrumentScores = const [],
  });

  /// Get score key for matching (lowercase title + composer)
  String get scoreKey => '${title.toLowerCase().trim()}|${composer.toLowerCase().trim()}';

  /// Get all existing instrument keys in this score
  Set<String> get existingInstrumentKeys =>
      instrumentScores.map((s) => s.instrumentKey).toSet();

  /// Check if an instrument already exists in this score
  bool hasInstrument(InstrumentType type, String? customInstrument) {
    final key = type == InstrumentType.other && customInstrument != null
        ? customInstrument.toLowerCase().trim()
        : type.name;
    return existingInstrumentKeys.contains(key);
  }

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
    DateTime? dateAdded,
    int? bpm,
    List<InstrumentScore>? instrumentScores,
  }) =>
      Score(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        title: title ?? this.title,
        composer: composer ?? this.composer,
        dateAdded: dateAdded ?? this.dateAdded,
        bpm: bpm ?? this.bpm,
        instrumentScores: instrumentScores ?? this.instrumentScores,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverId': serverId,
        'title': title,
        'composer': composer,
        'dateAdded': dateAdded.toIso8601String(),
        'bpm': bpm,
        'instrumentScores': instrumentScores.map((s) => s.toJson()).toList(),
      };

  factory Score.fromJson(Map<String, dynamic> json) => Score(
        id: json['id'],
        serverId: json['serverId'],
        title: json['title'],
        composer: json['composer'],
        dateAdded: DateTime.parse(json['dateAdded']),
        bpm: json['bpm'] ?? 120,
        instrumentScores: json['instrumentScores'] != null
            ? (json['instrumentScores'] as List)
                .map((s) => InstrumentScore.fromJson(s))
                .toList()
            : [],
      );
}