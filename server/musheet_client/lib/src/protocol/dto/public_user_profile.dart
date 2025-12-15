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

abstract class PublicUserProfile implements _i1.SerializableModel {
  PublicUserProfile._({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.preferredInstrument,
  });

  factory PublicUserProfile({
    required int id,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredInstrument,
  }) = _PublicUserProfileImpl;

  factory PublicUserProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicUserProfile(
      id: jsonSerialization['id'] as int,
      username: jsonSerialization['username'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      bio: jsonSerialization['bio'] as String?,
      preferredInstrument: jsonSerialization['preferredInstrument'] as String?,
    );
  }

  int id;

  String username;

  String? displayName;

  String? avatarUrl;

  String? bio;

  String? preferredInstrument;

  /// Returns a shallow copy of this [PublicUserProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PublicUserProfile copyWith({
    int? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredInstrument,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicUserProfile',
      'id': id,
      'username': username,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (bio != null) 'bio': bio,
      if (preferredInstrument != null)
        'preferredInstrument': preferredInstrument,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicUserProfileImpl extends PublicUserProfile {
  _PublicUserProfileImpl({
    required int id,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? preferredInstrument,
  }) : super._(
         id: id,
         username: username,
         displayName: displayName,
         avatarUrl: avatarUrl,
         bio: bio,
         preferredInstrument: preferredInstrument,
       );

  /// Returns a shallow copy of this [PublicUserProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PublicUserProfile copyWith({
    int? id,
    String? username,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    Object? bio = _Undefined,
    Object? preferredInstrument = _Undefined,
  }) {
    return PublicUserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      bio: bio is String? ? bio : this.bio,
      preferredInstrument: preferredInstrument is String?
          ? preferredInstrument
          : this.preferredInstrument,
    );
  }
}
