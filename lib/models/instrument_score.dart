import 'annotation.dart';
import 'base_models.dart';

enum InstrumentType { vocal, keyboard, drums, bass, guitar, other }

/// Unified InstrumentScore model for both user and team scopes
/// Inherits scope from parent Score via foreign key
class InstrumentScore with InstrumentScoreBase {
  @override
  final String id;
  final String? scoreId; // Parent score ID (for team context)
  @override
  final String? pdfPath;
  @override
  final String? pdfHash; // MD5 hash for PDF deduplication
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
  @override
  final int orderIndex;

  // Team-specific fields (nullable for user scope)
  final int? sourceInstrumentScoreId; // Original IS if copied

  InstrumentScore({
    required this.id,
    this.scoreId,
    required this.pdfPath,
    this.pdfHash,
    this.thumbnail,
    required this.instrumentType,
    this.customInstrument,
    this.annotations,
    required this.createdAt,
    this.orderIndex = 0,
    this.sourceInstrumentScoreId,
  });

  /// Alias for scoreId (backward compatibility with TeamInstrumentScore)
  String? get teamScoreId => scoreId;

  InstrumentScore copyWith({
    String? id,
    String? scoreId,
    String? pdfPath,
    String? pdfHash,
    String? thumbnail,
    InstrumentType? instrumentType,
    String? customInstrument,
    List<Annotation>? annotations,
    DateTime? createdAt,
    int? orderIndex,
    int? sourceInstrumentScoreId,
    // Alias for backward compatibility
    String? teamScoreId,
  }) =>
      InstrumentScore(
        id: id ?? this.id,
        scoreId: scoreId ?? teamScoreId ?? this.scoreId,
        pdfPath: pdfPath ?? this.pdfPath,
        pdfHash: pdfHash ?? this.pdfHash,
        thumbnail: thumbnail ?? this.thumbnail,
        instrumentType: instrumentType ?? this.instrumentType,
        customInstrument: customInstrument ?? this.customInstrument,
        annotations: annotations ?? this.annotations,
        createdAt: createdAt ?? this.createdAt,
        orderIndex: orderIndex ?? this.orderIndex,
        sourceInstrumentScoreId:
            sourceInstrumentScoreId ?? this.sourceInstrumentScoreId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'scoreId': scoreId,
        'pdfPath': pdfPath,
        'pdfHash': pdfHash,
        'thumbnail': thumbnail,
        'instrumentType': instrumentType.name,
        'customInstrument': customInstrument,
        'annotations': annotations?.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'orderIndex': orderIndex,
        'sourceInstrumentScoreId': sourceInstrumentScoreId,
      };

  factory InstrumentScore.fromJson(Map<String, dynamic> json) =>
      InstrumentScore(
        id: json['id'],
        scoreId: json['scoreId'] ?? json['teamScoreId'],
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
            ? (json['annotations'] as List)
                .map((a) => Annotation.fromJson(a))
                .toList()
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        orderIndex: json['orderIndex'] ?? 0,
        sourceInstrumentScoreId: json['sourceInstrumentScoreId'],
      );
}
