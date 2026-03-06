import 'annotation.dart';
import 'instrument_score.dart';

/// Owner type for scores, setlists, etc.
enum OwnerType { user, team }

/// Base interface for Score-like entities
/// Both [Score] and [TeamScore] share these core properties
mixin ScoreBase {
  String get id;
  String get title;
  String get composer;
  int get bpm;
  DateTime get createdAt;

  /// Get score key for matching (lowercase title + composer)
  String get scoreKey =>
      '${title.toLowerCase().trim()}|${composer.toLowerCase().trim()}';
}

/// Base interface for InstrumentScore-like entities
/// Both [InstrumentScore] and [TeamInstrumentScore] share these properties
mixin InstrumentScoreBase {
  String get id;
  InstrumentType get instrumentType;
  String? get customInstrument;
  String? get pdfPath;
  String? get pdfHash;
  String? get thumbnail;
  int get orderIndex;
  List<Annotation>? get annotations;
  DateTime get createdAt;

  /// Get display name for the instrument
  String get instrumentDisplayName {
    if (instrumentType == InstrumentType.other &&
        customInstrument != null &&
        customInstrument!.isNotEmpty) {
      return customInstrument!;
    }
    return instrumentType.name[0].toUpperCase() +
        instrumentType.name.substring(1);
  }

  /// Get the instrument key for comparison (lowercase)
  String get instrumentKey {
    if (instrumentType == InstrumentType.other &&
        customInstrument != null &&
        customInstrument!.isNotEmpty) {
      return customInstrument!.toLowerCase().trim();
    }
    return instrumentType.name;
  }
}

/// Base interface for Setlist-like entities
/// Both [Setlist] and [TeamSetlist] share these properties
mixin SetlistBase {
  String get id;
  String get name;
  String? get description;
  DateTime get createdAt;

  /// Score IDs in this setlist (abstract to allow different implementations)
  List<String> get scoreIds;
}

/// Helper to check if instrument exists in a collection
bool hasInstrumentInCollection<T extends InstrumentScoreBase>(
  List<T> instrumentScores,
  InstrumentType type,
  String? customInstrument,
) {
  final key = type == InstrumentType.other && customInstrument != null
      ? customInstrument.toLowerCase().trim()
      : type.name;
  return instrumentScores.any((s) => s.instrumentKey == key);
}

/// Get existing instrument keys from a collection
Set<String> getExistingInstrumentKeys<T extends InstrumentScoreBase>(
  List<T> instrumentScores,
) =>
    instrumentScores.map((s) => s.instrumentKey).toSet();
