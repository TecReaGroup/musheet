import 'annotation.dart';
import 'base_models.dart';

enum InstrumentType { vocal, keyboard, drums, bass, guitar, other }

/// Represents a single instrument part/sheet within a Score
class InstrumentScore with InstrumentScoreBase {
  @override
  final String id;
  @override
  final String? pdfPath;
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
  @override
  final DateTime createdAt;

  InstrumentScore({
    required this.id,
    required this.pdfPath,
    this.pdfHash,
    this.thumbnail,
    required this.instrumentType,
    this.customInstrument,
    this.annotations,
    required this.createdAt,
  });

  // Implement base interface requirements
  @override
  int get orderIndex => 0; // Personal library doesn't use orderIndex currently

  InstrumentScore copyWith({
    String? id,
    String? pdfPath,
    String? pdfHash,
    String? thumbnail,
    InstrumentType? instrumentType,
    String? customInstrument,
    List<Annotation>? annotations,
    DateTime? createdAt,
  }) =>
      InstrumentScore(
        id: id ?? this.id,
        pdfPath: pdfPath ?? this.pdfPath,
        pdfHash: pdfHash ?? this.pdfHash,
        thumbnail: thumbnail ?? this.thumbnail,
        instrumentType: instrumentType ?? this.instrumentType,
        customInstrument: customInstrument ?? this.customInstrument,
        annotations: annotations ?? this.annotations,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pdfPath': pdfPath,
        'pdfHash': pdfHash,
        'thumbnail': thumbnail,
        'instrumentType': instrumentType.name,
        'customInstrument': customInstrument,
        'annotations': annotations?.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory InstrumentScore.fromJson(Map<String, dynamic> json) => InstrumentScore(
        id: json['id'],
        pdfPath: json['pdfPath'],
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
        createdAt: DateTime.parse(json['createdAt']),
      );
}
