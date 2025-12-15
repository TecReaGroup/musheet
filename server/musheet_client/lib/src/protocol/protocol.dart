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
import 'annotation.dart' as _i2;
import 'application.dart' as _i3;
import 'dto/auth_result.dart' as _i4;
import 'dto/avatar_upload_result.dart' as _i5;
import 'dto/dashboard_stats.dart' as _i6;
import 'dto/delete_user_data_result.dart' as _i7;
import 'dto/file_upload_result.dart' as _i8;
import 'dto/public_user_profile.dart' as _i9;
import 'dto/score_sync_result.dart' as _i10;
import 'dto/team_info.dart' as _i11;
import 'dto/team_member_info.dart' as _i12;
import 'dto/team_summary.dart' as _i13;
import 'dto/team_with_role.dart' as _i14;
import 'dto/user_info.dart' as _i15;
import 'dto/user_profile.dart' as _i16;
import 'instrument_score.dart' as _i17;
import 'score.dart' as _i18;
import 'setlist.dart' as _i19;
import 'setlist_score.dart' as _i20;
import 'team.dart' as _i21;
import 'team_annotation.dart' as _i22;
import 'team_member.dart' as _i23;
import 'team_score.dart' as _i24;
import 'team_setlist.dart' as _i25;
import 'user.dart' as _i26;
import 'user_app_data.dart' as _i27;
import 'user_storage.dart' as _i28;
import 'package:musheet_client/src/protocol/dto/user_info.dart' as _i29;
import 'package:musheet_client/src/protocol/dto/team_summary.dart' as _i30;
import 'package:musheet_client/src/protocol/application.dart' as _i31;
import 'package:musheet_client/src/protocol/score.dart' as _i32;
import 'package:musheet_client/src/protocol/instrument_score.dart' as _i33;
import 'package:musheet_client/src/protocol/annotation.dart' as _i34;
import 'package:musheet_client/src/protocol/setlist.dart' as _i35;
import 'package:musheet_client/src/protocol/setlist_score.dart' as _i36;
import 'package:musheet_client/src/protocol/team_annotation.dart' as _i37;
import 'package:musheet_client/src/protocol/team.dart' as _i38;
import 'package:musheet_client/src/protocol/dto/team_member_info.dart' as _i39;
import 'package:musheet_client/src/protocol/dto/team_with_role.dart' as _i40;
export 'annotation.dart';
export 'application.dart';
export 'dto/auth_result.dart';
export 'dto/avatar_upload_result.dart';
export 'dto/dashboard_stats.dart';
export 'dto/delete_user_data_result.dart';
export 'dto/file_upload_result.dart';
export 'dto/public_user_profile.dart';
export 'dto/score_sync_result.dart';
export 'dto/team_info.dart';
export 'dto/team_member_info.dart';
export 'dto/team_summary.dart';
export 'dto/team_with_role.dart';
export 'dto/user_info.dart';
export 'dto/user_profile.dart';
export 'instrument_score.dart';
export 'score.dart';
export 'setlist.dart';
export 'setlist_score.dart';
export 'team.dart';
export 'team_annotation.dart';
export 'team_member.dart';
export 'team_score.dart';
export 'team_setlist.dart';
export 'user.dart';
export 'user_app_data.dart';
export 'user_storage.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.Annotation) {
      return _i2.Annotation.fromJson(data) as T;
    }
    if (t == _i3.Application) {
      return _i3.Application.fromJson(data) as T;
    }
    if (t == _i4.AuthResult) {
      return _i4.AuthResult.fromJson(data) as T;
    }
    if (t == _i5.AvatarUploadResult) {
      return _i5.AvatarUploadResult.fromJson(data) as T;
    }
    if (t == _i6.DashboardStats) {
      return _i6.DashboardStats.fromJson(data) as T;
    }
    if (t == _i7.DeleteUserDataResult) {
      return _i7.DeleteUserDataResult.fromJson(data) as T;
    }
    if (t == _i8.FileUploadResult) {
      return _i8.FileUploadResult.fromJson(data) as T;
    }
    if (t == _i9.PublicUserProfile) {
      return _i9.PublicUserProfile.fromJson(data) as T;
    }
    if (t == _i10.ScoreSyncResult) {
      return _i10.ScoreSyncResult.fromJson(data) as T;
    }
    if (t == _i11.TeamInfo) {
      return _i11.TeamInfo.fromJson(data) as T;
    }
    if (t == _i12.TeamMemberInfo) {
      return _i12.TeamMemberInfo.fromJson(data) as T;
    }
    if (t == _i13.TeamSummary) {
      return _i13.TeamSummary.fromJson(data) as T;
    }
    if (t == _i14.TeamWithRole) {
      return _i14.TeamWithRole.fromJson(data) as T;
    }
    if (t == _i15.UserInfo) {
      return _i15.UserInfo.fromJson(data) as T;
    }
    if (t == _i16.UserProfile) {
      return _i16.UserProfile.fromJson(data) as T;
    }
    if (t == _i17.InstrumentScore) {
      return _i17.InstrumentScore.fromJson(data) as T;
    }
    if (t == _i18.Score) {
      return _i18.Score.fromJson(data) as T;
    }
    if (t == _i19.Setlist) {
      return _i19.Setlist.fromJson(data) as T;
    }
    if (t == _i20.SetlistScore) {
      return _i20.SetlistScore.fromJson(data) as T;
    }
    if (t == _i21.Team) {
      return _i21.Team.fromJson(data) as T;
    }
    if (t == _i22.TeamAnnotation) {
      return _i22.TeamAnnotation.fromJson(data) as T;
    }
    if (t == _i23.TeamMember) {
      return _i23.TeamMember.fromJson(data) as T;
    }
    if (t == _i24.TeamScore) {
      return _i24.TeamScore.fromJson(data) as T;
    }
    if (t == _i25.TeamSetlist) {
      return _i25.TeamSetlist.fromJson(data) as T;
    }
    if (t == _i26.User) {
      return _i26.User.fromJson(data) as T;
    }
    if (t == _i27.UserAppData) {
      return _i27.UserAppData.fromJson(data) as T;
    }
    if (t == _i28.UserStorage) {
      return _i28.UserStorage.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Annotation?>()) {
      return (data != null ? _i2.Annotation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Application?>()) {
      return (data != null ? _i3.Application.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AuthResult?>()) {
      return (data != null ? _i4.AuthResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AvatarUploadResult?>()) {
      return (data != null ? _i5.AvatarUploadResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.DashboardStats?>()) {
      return (data != null ? _i6.DashboardStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.DeleteUserDataResult?>()) {
      return (data != null ? _i7.DeleteUserDataResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.FileUploadResult?>()) {
      return (data != null ? _i8.FileUploadResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.PublicUserProfile?>()) {
      return (data != null ? _i9.PublicUserProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ScoreSyncResult?>()) {
      return (data != null ? _i10.ScoreSyncResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.TeamInfo?>()) {
      return (data != null ? _i11.TeamInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.TeamMemberInfo?>()) {
      return (data != null ? _i12.TeamMemberInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.TeamSummary?>()) {
      return (data != null ? _i13.TeamSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.TeamWithRole?>()) {
      return (data != null ? _i14.TeamWithRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.UserInfo?>()) {
      return (data != null ? _i15.UserInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.UserProfile?>()) {
      return (data != null ? _i16.UserProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.InstrumentScore?>()) {
      return (data != null ? _i17.InstrumentScore.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.Score?>()) {
      return (data != null ? _i18.Score.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.Setlist?>()) {
      return (data != null ? _i19.Setlist.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.SetlistScore?>()) {
      return (data != null ? _i20.SetlistScore.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.Team?>()) {
      return (data != null ? _i21.Team.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.TeamAnnotation?>()) {
      return (data != null ? _i22.TeamAnnotation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.TeamMember?>()) {
      return (data != null ? _i23.TeamMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.TeamScore?>()) {
      return (data != null ? _i24.TeamScore.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.TeamSetlist?>()) {
      return (data != null ? _i25.TeamSetlist.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.User?>()) {
      return (data != null ? _i26.User.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.UserAppData?>()) {
      return (data != null ? _i27.UserAppData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.UserStorage?>()) {
      return (data != null ? _i28.UserStorage.fromJson(data) : null) as T;
    }
    if (t == List<_i13.TeamSummary>) {
      return (data as List)
              .map((e) => deserialize<_i13.TeamSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i11.TeamInfo>) {
      return (data as List).map((e) => deserialize<_i11.TeamInfo>(e)).toList()
          as T;
    }
    if (t == List<_i29.UserInfo>) {
      return (data as List).map((e) => deserialize<_i29.UserInfo>(e)).toList()
          as T;
    }
    if (t == List<_i30.TeamSummary>) {
      return (data as List)
              .map((e) => deserialize<_i30.TeamSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i31.Application>) {
      return (data as List)
              .map((e) => deserialize<_i31.Application>(e))
              .toList()
          as T;
    }
    if (t == List<_i32.Score>) {
      return (data as List).map((e) => deserialize<_i32.Score>(e)).toList()
          as T;
    }
    if (t == List<_i33.InstrumentScore>) {
      return (data as List)
              .map((e) => deserialize<_i33.InstrumentScore>(e))
              .toList()
          as T;
    }
    if (t == List<_i34.Annotation>) {
      return (data as List).map((e) => deserialize<_i34.Annotation>(e)).toList()
          as T;
    }
    if (t == List<_i35.Setlist>) {
      return (data as List).map((e) => deserialize<_i35.Setlist>(e)).toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i36.SetlistScore>) {
      return (data as List)
              .map((e) => deserialize<_i36.SetlistScore>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == List<_i37.TeamAnnotation>) {
      return (data as List)
              .map((e) => deserialize<_i37.TeamAnnotation>(e))
              .toList()
          as T;
    }
    if (t == List<_i38.Team>) {
      return (data as List).map((e) => deserialize<_i38.Team>(e)).toList() as T;
    }
    if (t == List<_i39.TeamMemberInfo>) {
      return (data as List)
              .map((e) => deserialize<_i39.TeamMemberInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i40.TeamWithRole>) {
      return (data as List)
              .map((e) => deserialize<_i40.TeamWithRole>(e))
              .toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Annotation => 'Annotation',
      _i3.Application => 'Application',
      _i4.AuthResult => 'AuthResult',
      _i5.AvatarUploadResult => 'AvatarUploadResult',
      _i6.DashboardStats => 'DashboardStats',
      _i7.DeleteUserDataResult => 'DeleteUserDataResult',
      _i8.FileUploadResult => 'FileUploadResult',
      _i9.PublicUserProfile => 'PublicUserProfile',
      _i10.ScoreSyncResult => 'ScoreSyncResult',
      _i11.TeamInfo => 'TeamInfo',
      _i12.TeamMemberInfo => 'TeamMemberInfo',
      _i13.TeamSummary => 'TeamSummary',
      _i14.TeamWithRole => 'TeamWithRole',
      _i15.UserInfo => 'UserInfo',
      _i16.UserProfile => 'UserProfile',
      _i17.InstrumentScore => 'InstrumentScore',
      _i18.Score => 'Score',
      _i19.Setlist => 'Setlist',
      _i20.SetlistScore => 'SetlistScore',
      _i21.Team => 'Team',
      _i22.TeamAnnotation => 'TeamAnnotation',
      _i23.TeamMember => 'TeamMember',
      _i24.TeamScore => 'TeamScore',
      _i25.TeamSetlist => 'TeamSetlist',
      _i26.User => 'User',
      _i27.UserAppData => 'UserAppData',
      _i28.UserStorage => 'UserStorage',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('musheet.', '');
    }

    switch (data) {
      case _i2.Annotation():
        return 'Annotation';
      case _i3.Application():
        return 'Application';
      case _i4.AuthResult():
        return 'AuthResult';
      case _i5.AvatarUploadResult():
        return 'AvatarUploadResult';
      case _i6.DashboardStats():
        return 'DashboardStats';
      case _i7.DeleteUserDataResult():
        return 'DeleteUserDataResult';
      case _i8.FileUploadResult():
        return 'FileUploadResult';
      case _i9.PublicUserProfile():
        return 'PublicUserProfile';
      case _i10.ScoreSyncResult():
        return 'ScoreSyncResult';
      case _i11.TeamInfo():
        return 'TeamInfo';
      case _i12.TeamMemberInfo():
        return 'TeamMemberInfo';
      case _i13.TeamSummary():
        return 'TeamSummary';
      case _i14.TeamWithRole():
        return 'TeamWithRole';
      case _i15.UserInfo():
        return 'UserInfo';
      case _i16.UserProfile():
        return 'UserProfile';
      case _i17.InstrumentScore():
        return 'InstrumentScore';
      case _i18.Score():
        return 'Score';
      case _i19.Setlist():
        return 'Setlist';
      case _i20.SetlistScore():
        return 'SetlistScore';
      case _i21.Team():
        return 'Team';
      case _i22.TeamAnnotation():
        return 'TeamAnnotation';
      case _i23.TeamMember():
        return 'TeamMember';
      case _i24.TeamScore():
        return 'TeamScore';
      case _i25.TeamSetlist():
        return 'TeamSetlist';
      case _i26.User():
        return 'User';
      case _i27.UserAppData():
        return 'UserAppData';
      case _i28.UserStorage():
        return 'UserStorage';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Annotation') {
      return deserialize<_i2.Annotation>(data['data']);
    }
    if (dataClassName == 'Application') {
      return deserialize<_i3.Application>(data['data']);
    }
    if (dataClassName == 'AuthResult') {
      return deserialize<_i4.AuthResult>(data['data']);
    }
    if (dataClassName == 'AvatarUploadResult') {
      return deserialize<_i5.AvatarUploadResult>(data['data']);
    }
    if (dataClassName == 'DashboardStats') {
      return deserialize<_i6.DashboardStats>(data['data']);
    }
    if (dataClassName == 'DeleteUserDataResult') {
      return deserialize<_i7.DeleteUserDataResult>(data['data']);
    }
    if (dataClassName == 'FileUploadResult') {
      return deserialize<_i8.FileUploadResult>(data['data']);
    }
    if (dataClassName == 'PublicUserProfile') {
      return deserialize<_i9.PublicUserProfile>(data['data']);
    }
    if (dataClassName == 'ScoreSyncResult') {
      return deserialize<_i10.ScoreSyncResult>(data['data']);
    }
    if (dataClassName == 'TeamInfo') {
      return deserialize<_i11.TeamInfo>(data['data']);
    }
    if (dataClassName == 'TeamMemberInfo') {
      return deserialize<_i12.TeamMemberInfo>(data['data']);
    }
    if (dataClassName == 'TeamSummary') {
      return deserialize<_i13.TeamSummary>(data['data']);
    }
    if (dataClassName == 'TeamWithRole') {
      return deserialize<_i14.TeamWithRole>(data['data']);
    }
    if (dataClassName == 'UserInfo') {
      return deserialize<_i15.UserInfo>(data['data']);
    }
    if (dataClassName == 'UserProfile') {
      return deserialize<_i16.UserProfile>(data['data']);
    }
    if (dataClassName == 'InstrumentScore') {
      return deserialize<_i17.InstrumentScore>(data['data']);
    }
    if (dataClassName == 'Score') {
      return deserialize<_i18.Score>(data['data']);
    }
    if (dataClassName == 'Setlist') {
      return deserialize<_i19.Setlist>(data['data']);
    }
    if (dataClassName == 'SetlistScore') {
      return deserialize<_i20.SetlistScore>(data['data']);
    }
    if (dataClassName == 'Team') {
      return deserialize<_i21.Team>(data['data']);
    }
    if (dataClassName == 'TeamAnnotation') {
      return deserialize<_i22.TeamAnnotation>(data['data']);
    }
    if (dataClassName == 'TeamMember') {
      return deserialize<_i23.TeamMember>(data['data']);
    }
    if (dataClassName == 'TeamScore') {
      return deserialize<_i24.TeamScore>(data['data']);
    }
    if (dataClassName == 'TeamSetlist') {
      return deserialize<_i25.TeamSetlist>(data['data']);
    }
    if (dataClassName == 'User') {
      return deserialize<_i26.User>(data['data']);
    }
    if (dataClassName == 'UserAppData') {
      return deserialize<_i27.UserAppData>(data['data']);
    }
    if (dataClassName == 'UserStorage') {
      return deserialize<_i28.UserStorage>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
