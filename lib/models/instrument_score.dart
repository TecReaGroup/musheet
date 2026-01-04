import 'annotation.dart';

enum InstrumentType { vocal, keyboard, drums, bass, guitar, other }

/// Represents a single instrument part/sheet within a Score
class InstrumentScore {
  final String id;
  final String pdfUrl;
  final String? pdfHash; // MD5 hash for PDF deduplication (per TEAM_SYNC_LOGIC.md)
  final String? thumbnail;
  final InstrumentType instrumentType;
  final String? customInstrument;
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

  /// Get display name for the instrument
  String get instrumentDisplayName {
    if (instrumentType == InstrumentType.other &&
        customInstrument != null &&
        customInstrument!.isNotEmpty) {
      return customInstrument!;
    }
    return instrumentType.name[0].toUpperCase() + instrumentType.name.substring(1);
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
