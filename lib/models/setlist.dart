import 'score.dart';

class Setlist {
  final String id;
  final String name;
  final String description;
  final List<Score> scores;
  final DateTime dateCreated;

  Setlist({
    required this.id,
    required this.name,
    required this.description,
    required this.scores,
    required this.dateCreated,
  });

  Setlist copyWith({
    String? id,
    String? name,
    String? description,
    List<Score>? scores,
    DateTime? dateCreated,
  }) =>
      Setlist(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        scores: scores ?? this.scores,
        dateCreated: dateCreated ?? this.dateCreated,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'scores': scores.map((s) => s.toJson()).toList(),
        'dateCreated': dateCreated.toIso8601String(),
      };

  factory Setlist.fromJson(Map<String, dynamic> json) => Setlist(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        scores: (json['scores'] as List).map((s) => Score.fromJson(s)).toList(),
        dateCreated: DateTime.parse(json['dateCreated']),
      );
}