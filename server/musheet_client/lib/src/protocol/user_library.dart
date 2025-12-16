/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// User Library
/// Tracks the global library version for each user (Zotero-style)
abstract class UserLibrary implements _i1.SerializableModel {
  UserLibrary._({
    this.id,
    required this.userId,
    required this.libraryVersion,
    required this.lastSyncAt,
    required this.lastModifiedAt,
  });

  factory UserLibrary({
    int? id,
    required int userId,
    required int libraryVersion,
    required DateTime lastSyncAt,
    required DateTime lastModifiedAt,
  }) = _UserLibraryImpl;

  factory UserLibrary.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserLibrary(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      libraryVersion: jsonSerialization['libraryVersion'] as int,
      lastSyncAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSyncAt'],
      ),
      lastModifiedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastModifiedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// User ID (foreign key to users)
  int userId;

  /// Current library version (increments on any change)
  int libraryVersion;

  /// Last sync timestamp
  DateTime lastSyncAt;

  /// Last modification timestamp
  DateTime lastModifiedAt;

  /// Returns a shallow copy of this [UserLibrary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserLibrary copyWith({
    int? id,
    int? userId,
    int? libraryVersion,
    DateTime? lastSyncAt,
    DateTime? lastModifiedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserLibrary',
      if (id != null) 'id': id,
      'userId': userId,
      'libraryVersion': libraryVersion,
      'lastSyncAt': lastSyncAt.toJson(),
      'lastModifiedAt': lastModifiedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserLibraryImpl extends UserLibrary {
  _UserLibraryImpl({
    int? id,
    required int userId,
    required int libraryVersion,
    required DateTime lastSyncAt,
    required DateTime lastModifiedAt,
  }) : super._(
         id: id,
         userId: userId,
         libraryVersion: libraryVersion,
         lastSyncAt: lastSyncAt,
         lastModifiedAt: lastModifiedAt,
       );

  /// Returns a shallow copy of this [UserLibrary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserLibrary copyWith({
    Object? id = _Undefined,
    int? userId,
    int? libraryVersion,
    DateTime? lastSyncAt,
    DateTime? lastModifiedAt,
  }) {
    return UserLibrary(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      libraryVersion: libraryVersion ?? this.libraryVersion,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }
}
