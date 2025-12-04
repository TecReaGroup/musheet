import 'annotation.dart';

class Score {
  final String id;
  final String title;
  final String composer;
  final String pdfUrl;
  final String? thumbnail;
  final DateTime dateAdded;
  final List<Annotation>? annotations;
  final int bpm; // Metronome BPM for this score

  Score({
    required this.id,
    required this.title,
    required this.composer,
    required this.pdfUrl,
    this.thumbnail,
    required this.dateAdded,
    this.annotations,
    this.bpm = 120,
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
      );
}