import 'score.dart';
import 'setlist.dart';

class TeamMember {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' | 'member'
  final String? avatar;

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatar': avatar,
      };

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        role: json['role'],
        avatar: json['avatar'],
      );
}

class TeamData {
  final String id;
  final String name;
  final List<TeamMember> members;
  final List<Score> sharedScores;
  final List<Setlist> sharedSetlists;

  TeamData({
    required this.id,
    required this.name,
    required this.members,
    required this.sharedScores,
    required this.sharedSetlists,
  });

  TeamData copyWith({
    String? id,
    String? name,
    List<TeamMember>? members,
    List<Score>? sharedScores,
    List<Setlist>? sharedSetlists,
  }) =>
      TeamData(
        id: id ?? this.id,
        name: name ?? this.name,
        members: members ?? this.members,
        sharedScores: sharedScores ?? this.sharedScores,
        sharedSetlists: sharedSetlists ?? this.sharedSetlists,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members.map((m) => m.toJson()).toList(),
        'sharedScores': sharedScores.map((s) => s.toJson()).toList(),
        'sharedSetlists': sharedSetlists.map((s) => s.toJson()).toList(),
      };

  factory TeamData.fromJson(Map<String, dynamic> json) => TeamData(
        id: json['id'],
        name: json['name'],
        members: (json['members'] as List).map((m) => TeamMember.fromJson(m)).toList(),
        sharedScores: (json['sharedScores'] as List).map((s) => Score.fromJson(s)).toList(),
        sharedSetlists: (json['sharedSetlists'] as List).map((s) => Setlist.fromJson(s)).toList(),
      );
}