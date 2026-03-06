class Annotation {
  final String id;
  final String type; // 'draw' | 'text'
  final String color;
  final double width;
  final List<double>? points;
  final String? text;
  final double? x;
  final double? y;
  final int page; // Page number this annotation belongs to

  Annotation({
    required this.id,
    required this.type,
    required this.color,
    required this.width,
    this.points,
    this.text,
    this.x,
    this.y,
    this.page = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'color': color,
        'width': width,
        'points': points,
        'text': text,
        'x': x,
        'y': y,
        'page': page,
      };

  factory Annotation.fromJson(Map<String, dynamic> json) => Annotation(
        id: json['id'],
        type: json['type'],
        color: json['color'],
        width: json['width'],
        points: json['points'] != null ? List<double>.from(json['points']) : null,
        text: json['text'],
        x: json['x'],
        y: json['y'],
        page: json['page'] ?? 1,
      );
}