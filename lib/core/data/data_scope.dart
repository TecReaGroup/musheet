/// Data Scope - Distinguishes between Library (user) and Team data
///
/// This is the core abstraction that allows the same code to operate
/// on different data scopes without duplication.
library;

import 'package:flutter/foundation.dart';

/// Data scope - distinguishes Library and Team data
@immutable
class DataScope {
  final String type; // 'user' | 'team'
  final int id; // 0 for user, teamServerId for team

  const DataScope._({required this.type, required this.id});

  /// User library scope (personal data)
  static const DataScope user = DataScope._(type: 'user', id: 0);

  /// Team scope
  factory DataScope.team(int teamServerId) {
    assert(teamServerId > 0, 'teamServerId must be positive');
    return DataScope._(type: 'team', id: teamServerId);
  }

  /// Check if this is user scope
  bool get isUser => type == 'user';

  /// Check if this is team scope
  bool get isTeam => type == 'team';

  /// Get the scope ID (0 for user, teamServerId for team)
  int get scopeId => id;

  /// Get the scope type string
  String get scopeType => type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataScope && type == other.type && id == other.id;

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => 'DataScope($type, $id)';

  // ============================================================================
  // JSON Serialization (for route parameters)
  // ============================================================================

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
  };

  /// Create from JSON map
  factory DataScope.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as int;
    return type == 'user' ? DataScope.user : DataScope.team(id);
  }
}
