import 'dart:typed_data';

import 'package:musheet_client/musheet_client.dart' as server;
import 'package:serverpod_client/serverpod_client.dart'
    show ClientAuthKeyProvider, wrapAsBearerAuthHeaderValue;

class MusheetAuthKeyProvider implements ClientAuthKeyProvider {
  String? _token;

  void setToken(String? token) => _token = token;

  String? get token => _token;

  @override
  Future<String?> get authHeaderValue async {
    if (_token == null) return null;
    return wrapAsBearerAuthHeaderValue(_token!);
  }
}

class MusheetClientFacade {
  MusheetClientFacade({
    required String baseUrl,
    Duration connectionTimeout = const Duration(seconds: 15),
  }) : baseUrl = _normalizeBaseUrl(baseUrl),
       authKeyProvider = MusheetAuthKeyProvider(),
       client = server.Client(
         _normalizeBaseUrl(baseUrl),
         connectionTimeout: connectionTimeout,
       ) {
    client.authKeyProvider = authKeyProvider;
  }

  final String baseUrl;
  final server.Client client;
  final MusheetAuthKeyProvider authKeyProvider;

  int? _currentUserId;

  int? get currentUserId => _currentUserId;
  String? get token => authKeyProvider.token;
  bool get isAuthenticated => token != null;

  void setAuth(String token, {int? userId}) {
    authKeyProvider.setToken(token);
    _currentUserId = userId ?? _currentUserId;
  }

  void clearAuth() {
    authKeyProvider.setToken(null);
    _currentUserId = null;
  }

  int requireCurrentUserId() {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('Authentication required. Current user ID is not set.');
    }
    return userId;
  }

  Future<void> health() => client.status.health();

  Future<String> ping() => client.status.ping();

  Future<server.AuthResult> register({
    required String username,
    required String password,
    String? displayName,
  }) => client.auth.register(username, password, displayName: displayName);

  Future<server.AuthResult> login({
    required String username,
    required String password,
  }) => client.auth.login(username, password);

  Future<void> logout() => client.auth.logout();

  Future<int?> validateToken(String token) => client.auth.validateToken(token);

  Future<bool> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) => client.auth.changePassword(userId, oldPassword, newPassword);

  Future<server.AuthResult> refreshToken(String refreshToken) =>
      client.auth.refreshToken(refreshToken);

  Future<bool> needsAdminRegistration() =>
      client.adminUser.needsAdminRegistration();

  Future<server.UserProfile> getProfile(int userId) =>
      client.profile.getProfile(userId);

  Future<server.UserProfile> updateProfile({
    required int userId,
    String? displayName,
    String? preferredInstrument,
  }) => client.profile.updateProfile(
    userId,
    displayName: displayName,
    preferredInstrument: preferredInstrument,
  );

  Future<server.AvatarUploadResult> uploadAvatar({
    required int userId,
    required Uint8List imageBytes,
    required String fileName,
  }) => client.profile.uploadAvatar(
    userId,
    ByteData.view(imageBytes.buffer),
    fileName,
  );

  Future<Uint8List?> getAvatar(int userId) async {
    final result = await client.profile.getAvatar(userId);
    return result?.buffer.asUint8List();
  }

  Future<server.DeleteUserDataResult> deleteAllUserData(int userId) =>
      client.profile.deleteAllUserData(userId);

  Future<server.SyncPullResponse> libraryPull({
    required int userId,
    int since = 0,
  }) => client.librarySync.pull(userId, since: since);

  Future<server.SyncPushResponse> libraryPush({
    required int userId,
    required server.SyncPushRequest request,
  }) => client.librarySync.push(userId, request);

  Future<bool> checkPdfHash({
    required int userId,
    required String hash,
  }) => client.file.checkPdfHash(userId, hash);

  Future<server.FileUploadResult> uploadPdfByHash({
    required int userId,
    required Uint8List fileBytes,
    required String fileName,
  }) => client.file.uploadPdfByHash(
    userId,
    ByteData.view(fileBytes.buffer),
    fileName,
  );

  Future<Uint8List?> downloadPdfByHash({
    required int userId,
    required String hash,
  }) async {
    final result = await client.file.downloadPdfByHash(userId, hash);
    return result?.buffer.asUint8List();
  }

  Future<List<server.TeamWithRole>> getMyTeams(int userId) =>
      client.team.getMyTeams(userId);

  Future<List<server.TeamMemberInfo>> getTeamMembers({
    required int userId,
    required int teamId,
  }) => client.team.getMyTeamMembers(userId, teamId);

  Future<server.Team> createTeam({
    String? name,
    String? description,
    int? userId,
  }) => client.team.createTeam(
    userId ?? requireCurrentUserId(),
    name ?? (throw ArgumentError.notNull('name')),
    description,
  );

  Future<server.TeamMember> addMemberToTeam({
    required int teamId,
    required int userId,
    int? actorUserId,
  }) => client.team.addMemberToTeam(
    actorUserId ?? requireCurrentUserId(),
    teamId,
    userId,
  );

  Future<bool> removeMemberFromTeam({
    required int teamId,
    required int userId,
    int? actorUserId,
  }) => client.team.removeMemberFromTeam(
    actorUserId ?? requireCurrentUserId(),
    teamId,
    userId,
  );

  Future<server.SyncPullResponse> teamPull({
    required int userId,
    required int teamId,
    int since = 0,
  }) => client.teamSync.pull(userId, teamId, since: since);

  Future<server.SyncPushResponse> teamPush({
    required int userId,
    required int teamId,
    required server.SyncPushRequest request,
  }) => client.teamSync.push(userId, teamId, request);

  Future<server.DashboardStats> getDashboardStats({int? userId}) =>
      client.admin.getDashboardStats(userId ?? requireCurrentUserId());

  Future<List<server.UserInfo>> getAllUsers({
    int? userId,
    int page = 0,
    int pageSize = 20,
  }) => client.admin.getAllUsers(
    userId ?? requireCurrentUserId(),
    page: page,
    pageSize: pageSize,
  );

  Future<server.User> createUser({
    required String username,
    required String password,
    String? displayName,
    bool isAdmin = false,
    int? userId,
  }) => client.adminUser.createUser(
    userId ?? requireCurrentUserId(),
    username,
    password,
    displayName,
    isAdmin,
  );

  Future<bool> deactivateUser(int targetUserId, {int? userId}) =>
      client.admin.deactivateUser(userId ?? requireCurrentUserId(), targetUserId);

  Future<bool> reactivateUser(int targetUserId, {int? userId}) =>
      client.admin.reactivateUser(userId ?? requireCurrentUserId(), targetUserId);

  Future<bool> deleteUser(int targetUserId, {int? userId}) =>
      client.admin.deleteUser(userId ?? requireCurrentUserId(), targetUserId);

  Future<bool> promoteToAdmin(int targetUserId, {int? userId}) =>
      client.admin.promoteToAdmin(userId ?? requireCurrentUserId(), targetUserId);

  Future<bool> demoteFromAdmin(int targetUserId, {int? userId}) =>
      client.admin.demoteFromAdmin(userId ?? requireCurrentUserId(), targetUserId);

  Future<String> resetUserPassword(int targetUserId, {int? userId}) =>
      client.adminUser.resetUserPassword(
        userId ?? requireCurrentUserId(),
        targetUserId,
      );

  Future<List<server.TeamSummary>> getAllTeams({
    int? userId,
    int page = 0,
    int pageSize = 20,
  }) => client.admin.getAllTeams(
    userId ?? requireCurrentUserId(),
    page: page,
    pageSize: pageSize,
  );

  Future<bool> deleteTeam(int teamId, {int? userId}) =>
      client.admin.deleteTeam(userId ?? requireCurrentUserId(), teamId);

  static String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }
}
