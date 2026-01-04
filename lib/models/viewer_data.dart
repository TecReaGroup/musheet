import 'annotation.dart';
import 'base_models.dart';
import 'score.dart';
import 'setlist.dart';
import 'team.dart';

/// Source type for viewer - personal library or team
enum ViewerSource { library, team }

/// Unified data wrapper for ScoreViewerScreen
/// Supports both personal library scores and team scores
class ViewerScoreData with ScoreBase {
  final ViewerSource source;

  // Underlying data - one of these will be non-null
  final Score? _personalScore;
  final TeamScore? _teamScore;

  ViewerScoreData.fromPersonal(Score score)
      : source = ViewerSource.library,
        _personalScore = score,
        _teamScore = null;

  ViewerScoreData.fromTeam(TeamScore score)
      : source = ViewerSource.team,
        _personalScore = null,
        _teamScore = score;

  bool get isPersonal => source == ViewerSource.library;
  bool get isTeam => source == ViewerSource.team;

  /// Get personal score (throws if this is a team score)
  Score get personalScore {
    if (_personalScore == null) {
      throw StateError('This is a team score, not a personal score');
    }
    return _personalScore;
  }

  /// Get team score (throws if this is a personal score)
  TeamScore get teamScore {
    if (_teamScore == null) {
      throw StateError('This is a personal score, not a team score');
    }
    return _teamScore;
  }

  // ScoreBase implementation
  @override
  String get id => _personalScore?.id ?? _teamScore!.id;

  @override
  String get title => _personalScore?.title ?? _teamScore!.title;

  @override
  String get composer => _personalScore?.composer ?? _teamScore!.composer;

  @override
  int get bpm => _personalScore?.bpm ?? _teamScore!.bpm;

  @override
  DateTime get createdAt => _personalScore?.createdAt ?? _teamScore!.createdAt;

  /// Get instrument scores as unified list
  List<ViewerInstrumentData> get instrumentScores {
    if (_personalScore != null) {
      return _personalScore.instrumentScores
          .map((i) => ViewerInstrumentData.fromPersonal(i))
          .toList();
    }
    return _teamScore!.instrumentScores
        .map((i) => ViewerInstrumentData.fromTeam(i))
        .toList();
  }

  /// Get the first instrument score
  ViewerInstrumentData? get firstInstrumentScore =>
      instrumentScores.isNotEmpty ? instrumentScores.first : null;

  /// Get team ID (only for team scores)
  int? get teamId => _teamScore?.teamId;

  /// Get creator ID (only for team scores)
  int? get createdById => _teamScore?.createdById;

  /// Copy with new BPM
  ViewerScoreData copyWithBpm(int newBpm) {
    if (_personalScore != null) {
      return ViewerScoreData.fromPersonal(_personalScore.copyWith(bpm: newBpm));
    }
    return ViewerScoreData.fromTeam(_teamScore!.copyWith(bpm: newBpm));
  }
}

/// Unified data wrapper for InstrumentScore
/// Supports both personal library and team instrument scores
class ViewerInstrumentData with InstrumentScoreBase {
  final ViewerSource source;

  final InstrumentScore? _personalInstrument;
  final TeamInstrumentScore? _teamInstrument;

  ViewerInstrumentData.fromPersonal(InstrumentScore instrument)
      : source = ViewerSource.library,
        _personalInstrument = instrument,
        _teamInstrument = null;

  ViewerInstrumentData.fromTeam(TeamInstrumentScore instrument)
      : source = ViewerSource.team,
        _personalInstrument = null,
        _teamInstrument = instrument;

  bool get isPersonal => source == ViewerSource.library;
  bool get isTeam => source == ViewerSource.team;

  /// Get personal instrument score (throws if this is a team score)
  InstrumentScore get personalInstrument {
    if (_personalInstrument == null) {
      throw StateError('This is a team instrument, not a personal instrument');
    }
    return _personalInstrument;
  }

  /// Get team instrument score (throws if this is a personal score)
  TeamInstrumentScore get teamInstrument {
    if (_teamInstrument == null) {
      throw StateError('This is a personal instrument, not a team instrument');
    }
    return _teamInstrument;
  }

  // InstrumentScoreBase implementation
  @override
  String get id => _personalInstrument?.id ?? _teamInstrument!.id;

  @override
  InstrumentType get instrumentType =>
      _personalInstrument?.instrumentType ?? _teamInstrument!.instrumentType;

  @override
  String? get customInstrument =>
      _personalInstrument?.customInstrument ?? _teamInstrument?.customInstrument;

  @override
  String? get pdfPath =>
      _personalInstrument?.pdfUrl ?? _teamInstrument?.pdfPath;

  @override
  String? get pdfHash =>
      _personalInstrument?.pdfHash ?? _teamInstrument?.pdfHash;

  @override
  String? get thumbnail =>
      _personalInstrument?.thumbnail ?? _teamInstrument?.thumbnail;

  @override
  int get orderIndex => _personalInstrument?.orderIndex ?? _teamInstrument?.orderIndex ?? 0;

  @override
  List<Annotation>? get annotations =>
      _personalInstrument?.annotations ?? _teamInstrument?.annotations;

  @override
  DateTime get createdAt =>
      _personalInstrument?.createdAt ?? _teamInstrument!.createdAt;

  /// Get team score ID (only for team instruments)
  String? get teamScoreId => _teamInstrument?.teamScoreId;
}

/// Unified setlist data wrapper
class ViewerSetlistData with SetlistBase {
  final ViewerSource source;

  final Setlist? _personalSetlist;
  final TeamSetlist? _teamSetlist;

  ViewerSetlistData.fromPersonal(Setlist setlist)
      : source = ViewerSource.library,
        _personalSetlist = setlist,
        _teamSetlist = null;

  ViewerSetlistData.fromTeam(TeamSetlist setlist)
      : source = ViewerSource.team,
        _personalSetlist = null,
        _teamSetlist = setlist;

  bool get isPersonal => source == ViewerSource.library;
  bool get isTeam => source == ViewerSource.team;

  @override
  String get id => _personalSetlist?.id ?? _teamSetlist!.id;

  @override
  String get name => _personalSetlist?.name ?? _teamSetlist!.name;

  @override
  String? get description =>
      _personalSetlist?.description ?? _teamSetlist?.description;

  @override
  DateTime get createdAt =>
      _personalSetlist?.createdAt ?? _teamSetlist!.createdAt;

  @override
  List<String> get scoreIds =>
      _personalSetlist?.scoreIds ?? _teamSetlist!.teamScoreIds;
}
