import 'annotation.dart';

enum InstrumentType { vocal, keyboard, bass, drums, guitar, other }

class Score {
  final String id;
  final String title;
  final String composer;
  final String pdfUrl;
  final String? thumbnail;
  final DateTime dateAdded;
  final List<Annotation>? annotations;
  final int bpm;
  final InstrumentType instrumentType;
  final String? customInstrument;

  Score({
    required this.id,
    required this.title,
    required this.composer,
    required this.pdfUrl,
    this.thumbnail,
    required this.dateAdded,
    this.annotations,
    this.bpm = 120,
    this.instrumentType = InstrumentType.vocal,
    this.customInstrument,
  });

  Score copyWith({
    String? id,
    String? title,
    String? composer,
    String? pdfUrl,
    String? thumbnail,
    DateTime? dateAdded,
    List<Annotation>? annotations,
    int? bpm,
    InstrumentType? instrumentType,
    String? customInstrument,
  }) =>
      Score(
        id: id ?? this.id,
        title: title ?? this.title,
        composer: composer ?? this.composer,
        pdfUrl: pdfUrl ?? this.pdfUrl,
        thumbnail: thumbnail ?? this.thumbnail,
        dateAdded: dateAdded ?? this.dateAdded,
        annotations: annotations ?? this.annotations,
        bpm: bpm ?? this.bpm,
        instrumentType: instrumentType ?? this.instrumentType,
        customInstrument: customInstrument ?? this.customInstrument,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'composer': composer,
        'pdfUrl': pdfUrl,
        'thumbnail': thumbnail,
        'dateAdded': dateAdded.toIso8601String(),
        'annotations': annotations?.map((a) => a.toJson()).toList(),
        'bpm': bpm,
        'instrumentType': instrumentType.name,
        'customInstrument': customInstrument,
      };

  factory Score.fromJson(Map<String, dynamic> json) => Score(
        id: json['id'],
        title: json['title'],
        composer: json['composer'],
        pdfUrl: json['pdfUrl'],
        thumbnail: json['thumbnail'],
        dateAdded: DateTime.parse(json['dateAdded']),
        annotations: json['annotations'] != null
            ? (json['annotations'] as List).map((a) => Annotation.fromJson(a)).toList()
            : null,
        bpm: json['bpm'] ?? 120,
        instrumentType: json['instrumentType'] != null
            ? InstrumentType.values.firstWhere((e) => e.name == json['instrumentType'], orElse: () => InstrumentType.vocal)
            : InstrumentType.vocal,
        customInstrument: json['customInstrument'],
      );
}