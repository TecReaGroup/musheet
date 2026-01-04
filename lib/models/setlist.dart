import 'base_models.dart';

class Setlist with SetlistBase {
  @override
  final String id;
  @override
  final String name;
  @override
  final String description; // Non-nullable for personal setlists
  @override
  final List<String> scoreIds; // Store only score IDs as references
  final DateTime dateCreated;

  Setlist({
    required this.id,
    required this.name,
    required this.description,
    required this.scoreIds,
    required this.dateCreated,
  });

  // Implement base interface
  @override
  DateTime get createdAt => dateCreated;

  Setlist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? scoreIds,
    DateTime? dateCreated,
  }) =>
      Setlist(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        scoreIds: scoreIds ?? this.scoreIds,
        dateCreated: dateCreated ?? this.dateCreated,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'scoreIds': scoreIds,
        'dateCreated': dateCreated.toIso8601String(),
      };

  factory Setlist.fromJson(Map<String, dynamic> json) => Setlist(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        scoreIds: (json['scoreIds'] as List).cast<String>(),
        dateCreated: DateTime.parse(json['dateCreated']),
      );
}