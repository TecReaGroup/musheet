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
import 'package:serverpod/serverpod.dart' as _i1;

/// Result of deleteAllUserData operation (DEBUG only)
abstract class DeleteUserDataResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  DeleteUserDataResult._({
    required this.success,
    required this.deletedScores,
    required this.deletedInstrumentScores,
    required this.deletedAnnotations,
    required this.deletedSetlists,
    required this.deletedSetlistScores,
  });

  factory DeleteUserDataResult({
    required bool success,
    required int deletedScores,
    required int deletedInstrumentScores,
    required int deletedAnnotations,
    required int deletedSetlists,
    required int deletedSetlistScores,
  }) = _DeleteUserDataResultImpl;

  factory DeleteUserDataResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeleteUserDataResult(
      success: jsonSerialization['success'] as bool,
      deletedScores: jsonSerialization['deletedScores'] as int,
      deletedInstrumentScores:
          jsonSerialization['deletedInstrumentScores'] as int,
      deletedAnnotations: jsonSerialization['deletedAnnotations'] as int,
      deletedSetlists: jsonSerialization['deletedSetlists'] as int,
      deletedSetlistScores: jsonSerialization['deletedSetlistScores'] as int,
    );
  }

  bool success;

  int deletedScores;

  int deletedInstrumentScores;

  int deletedAnnotations;

  int deletedSetlists;

  int deletedSetlistScores;

  /// Returns a shallow copy of this [DeleteUserDataResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeleteUserDataResult copyWith({
    bool? success,
    int? deletedScores,
    int? deletedInstrumentScores,
    int? deletedAnnotations,
    int? deletedSetlists,
    int? deletedSetlistScores,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeleteUserDataResult',
      'success': success,
      'deletedScores': deletedScores,
      'deletedInstrumentScores': deletedInstrumentScores,
      'deletedAnnotations': deletedAnnotations,
      'deletedSetlists': deletedSetlists,
      'deletedSetlistScores': deletedSetlistScores,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeleteUserDataResult',
      'success': success,
      'deletedScores': deletedScores,
      'deletedInstrumentScores': deletedInstrumentScores,
      'deletedAnnotations': deletedAnnotations,
      'deletedSetlists': deletedSetlists,
      'deletedSetlistScores': deletedSetlistScores,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _DeleteUserDataResultImpl extends DeleteUserDataResult {
  _DeleteUserDataResultImpl({
    required bool success,
    required int deletedScores,
    required int deletedInstrumentScores,
    required int deletedAnnotations,
    required int deletedSetlists,
    required int deletedSetlistScores,
  }) : super._(
         success: success,
         deletedScores: deletedScores,
         deletedInstrumentScores: deletedInstrumentScores,
         deletedAnnotations: deletedAnnotations,
         deletedSetlists: deletedSetlists,
         deletedSetlistScores: deletedSetlistScores,
       );

  /// Returns a shallow copy of this [DeleteUserDataResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeleteUserDataResult copyWith({
    bool? success,
    int? deletedScores,
    int? deletedInstrumentScores,
    int? deletedAnnotations,
    int? deletedSetlists,
    int? deletedSetlistScores,
  }) {
    return DeleteUserDataResult(
      success: success ?? this.success,
      deletedScores: deletedScores ?? this.deletedScores,
      deletedInstrumentScores:
          deletedInstrumentScores ?? this.deletedInstrumentScores,
      deletedAnnotations: deletedAnnotations ?? this.deletedAnnotations,
      deletedSetlists: deletedSetlists ?? this.deletedSetlists,
      deletedSetlistScores: deletedSetlistScores ?? this.deletedSetlistScores,
    );
  }
}
