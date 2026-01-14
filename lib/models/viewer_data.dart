import 'annotation.dart';
import 'base_models.dart';
import 'score.dart';
import 'setlist.dart';

/// Source type for viewer - personal library or team
enum ViewerSource { library, team }

/// Unified data wrapper for ScoreViewerScreen
/// Now directly uses the unified Score model (which has scopeType field)
class ViewerScoreData with ScoreBase {
  /// The underlying unified score (works for both personal and team)
  final Score score;

  ViewerScoreData(this.score);

  /// Get source type based on scopeType
  ViewerSource get source =>
      score.isTeamScore ? ViewerSource.team : ViewerSource.library;

  bool get isPersonal => source == ViewerSource.library;
  bool get isTeam => source == ViewerSource.team;

  // ScoreBase implementation - delegate to underlying score
  @override
  String get id => score.id;

  @override
  String get title => score.title;

  @override
  String get composer => score.composer;

  @override
  int get bpm => score.bpm;

  @override
  DateTime get createdAt => score.createdAt;

  /// Get instrument scores as unified list
  List<ViewerInstrumentData> get instrumentScores =>
      score.instrumentScores.map((i) => ViewerInstrumentData(i)).toList();

  /// Get the first instrument score
  ViewerInstrumentData? get firstInstrumentScore =>
      instrumentScores.isNotEmpty ? instrumentScores.first : null;

  /// Get team ID (only for team scores)
  int? get teamId => score.isTeamScore ? score.scopeId : null;

  /// Get creator ID (only for team scores)
  int? get createdById => score.createdById;

  /// Copy with new BPM
  ViewerScoreData copyWithBpm(int newBpm) =>
      ViewerScoreData(score.copyWith(bpm: newBpm));
}

/// Unified data wrapper for InstrumentScore
/// Now directly uses the unified InstrumentScore model
class ViewerInstrumentData with InstrumentScoreBase {
  /// The underlying unified instrument score
  final InstrumentScore instrument;

  ViewerInstrumentData(this.instrument);

  // InstrumentScoreBase implementation - delegate to underlying instrument
  @override
  String get id => instrument.id;

  @override
  InstrumentType get instrumentType => instrument.instrumentType;

  @override
  String? get customInstrument => instrument.customInstrument;

  @override
  String? get pdfPath => instrument.pdfPath;

  @override
  String? get pdfHash => instrument.pdfHash;

  @override
  String? get thumbnail => instrument.thumbnail;

  @override
  int get orderIndex => instrument.orderIndex;

  @override
  List<Annotation>? get annotations => instrument.annotations;

  @override
  DateTime get createdAt => instrument.createdAt;

  /// Get parent score ID
  String? get teamScoreId => instrument.scoreId;
}

/// Unified setlist data wrapper
/// Now directly uses the unified Setlist model
class ViewerSetlistData with SetlistBase {
  /// The underlying unified setlist
  final Setlist setlist;

  ViewerSetlistData(this.setlist);

  /// Get source type based on scopeType
  ViewerSource get source =>
      setlist.isTeamSetlist ? ViewerSource.team : ViewerSource.library;

  bool get isPersonal => source == ViewerSource.library;
  bool get isTeam => source == ViewerSource.team;

  @override
  String get id => setlist.id;

  @override
  String get name => setlist.name;

  @override
  String? get description => setlist.description;

  @override
  DateTime get createdAt => setlist.createdAt;

  @override
  List<String> get scoreIds => setlist.scoreIds;
}
