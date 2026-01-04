import 'annotation.dart';
import 'base_models.dart';

enum InstrumentType { vocal, keyboard, drums, bass, guitar, other }

/// Represents a single instrument part/sheet within a Score
class InstrumentScore with InstrumentScoreBase {
  @override
  final String id;
  final String pdfUrl; // For personal library, this is the local path
  @override
  final String? pdfHash; // MD5 hash for PDF deduplication (per TEAM_SYNC_LOGIC.md)
  @override
  final String? thumbnail;
  @override
  final InstrumentType instrumentType;
  @override
  final String? customInstrument;
  @override
  final List<Annotation>? annotations;
  final DateTime dateAdded;

  InstrumentScore({
    required this.id,
    required this.pdfUrl,
    this.pdfHash,
    this.thumbnail,
    required this.instrumentType,
    this.customInstrument,
    this.annotations,
    required this.dateAdded,
  });

  // Implement base interface requirements
  @override
  String? get pdfPath => pdfUrl;
  @override
  int get orderIndex => 0; // Personal library doesn't use orderIndex currently
  @override
  DateTime get createdAt => dateAdded;

  InstrumentScore copyWith({
    String? id,
    String? pdfUrl,
    String? pdfHash,
    String? thumbnail,
    InstrumentType? instrumentType,
    String? customInstrument,
    List<Annotation>? annotations,
    DateTime? dateAdded,
  }) =>
      InstrumentScore(
        id: id ?? this.id,
        pdfUrl: pdfUrl ?? this.pdfUrl,
        pdfHash: pdfHash ?? this.pdfHash,
        thumbnail: thumbnail ?? this.thumbnail,
        instrumentType: instrumentType ?? this.instrumentType,
        customInstrument: customInstrument ?? this.customInstrument,
        annotations: annotations ?? this.annotations,
        dateAdded: dateAdded ?? this.dateAdded,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pdfUrl': pdfUrl,
        'pdfHash': pdfHash,
        'thumbnail': thumbnail,
        'instrumentType': instrumentType.name,
        'customInstrument': customInstrument,
        'annotations': annotations?.map((a) => a.toJson()).toList(),
        'dateAdded': dateAdded.toIso8601String(),
      };

  factory InstrumentScore.fromJson(Map<String, dynamic> json) => InstrumentScore(
        id: json['id'],
        pdfUrl: json['pdfUrl'],
        pdfHash: json['pdfHash'],
        thumbnail: json['thumbnail'],
        instrumentType: json['instrumentType'] != null
            ? InstrumentType.values.firstWhere(
                (e) => e.name == json['instrumentType'],
                orElse: () => InstrumentType.vocal,
              )
            : InstrumentType.vocal,
        customInstrument: json['customInstrument'],
        annotations: json['annotations'] != null
            ? (json['annotations'] as List).map((a) => Annotation.fromJson(a)).toList()
            : null,
        dateAdded: DateTime.parse(json['dateAdded']),
      );
}
