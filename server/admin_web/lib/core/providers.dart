import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musheet_client/musheet_client.dart' as server;
import '../core/admin_api_client.dart';

// ============================================================================
// Auth State
// ============================================================================

class AdminAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final int? userId;
  final String? username;
  final String? displayName;
  final String? token;

  const AdminAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.userId,
    this.username,
    this.displayName,
    this.token,
  });

  AdminAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    int? userId,
    String? username,
    String? displayName,
    String? token,
  }) {
    return AdminAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      token: token ?? this.token,
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  AdminAuthNotifier() : super(const AdminAuthState());

  static const _tokenKey = 'admin_token';
  static const _userIdKey = 'admin_user_id';
  static const _usernameKey = 'admin_username';
  static const _displayNameKey = 'admin_display_name';

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userId = prefs.getInt(_userIdKey);
      final username = prefs.getString(_usernameKey);
      final displayName = prefs.getString(_displayNameKey);

      if (token != null && userId != null) {
        AdminApiClient.instance.setAuth(token, userId);
        state = AdminAuthState(
          isAuthenticated: true,
          userId: userId,
          username: username,
          displayName: displayName,
          token: token,
        );
      } else {
        state = const AdminAuthState();
      }
    } catch (e) {
      state = AdminAuthState(error: e.toString());
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AdminApiClient.instance.login(
        username: username,
        password: password,
      );

      if (result.isFailure) {
        state = state.copyWith(isLoading: false, error: result.error);
        return false;
      }

      final authResult = result.data!;
      if (!authResult.success) {
        state = state.copyWith(
          isLoading: false,
          error: authResult.errorMessage ?? 'Login failed',
        );
        return false;
      }

      final user = authResult.user!;

      // Check if user is admin
      if (!user.isAdmin) {
        state = state.copyWith(
          isLoading: false,
          error: 'Admin access required',
        );
        return false;
      }

      // Save credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, authResult.token!);
      await prefs.setInt(_userIdKey, user.id!);
      await prefs.setString(_usernameKey, user.username);
      if (user.displayName != null) {
        await prefs.setString(_displayNameKey, user.displayName!);
      }

      AdminApiClient.instance.setAuth(authResult.token!, user.id!);

      state = AdminAuthState(
        isAuthenticated: true,
        userId: user.id,
        username: user.username,
        displayName: user.displayName,
        token: authResult.token,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String username, String password, String? displayName) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AdminApiClient.instance.register(
        username: username,
        password: password,
        displayName: displayName,
      );

      if (result.isFailure) {
        state = state.copyWith(isLoading: false, error: result.error);
        return false;
      }

      final authResult = result.data!;
      if (!authResult.success) {
        state = state.copyWith(
          isLoading: false,
          error: authResult.errorMessage ?? 'Registration failed',
        );
        return false;
      }

      final user = authResult.user!;

      // Check if user is admin (first user becomes admin)
      if (!user.isAdmin) {
        state = state.copyWith(
          isLoading: false,
          error: 'Only admins can access this console',
        );
        return false;
      }

      // Save credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, authResult.token!);
      await prefs.setInt(_userIdKey, user.id!);
      await prefs.setString(_usernameKey, user.username);
      if (user.displayName != null) {
        await prefs.setString(_displayNameKey, user.displayName!);
      }

      AdminApiClient.instance.setAuth(authResult.token!, user.id!);

      state = AdminAuthState(
        isAuthenticated: true,
        userId: user.id,
        username: user.username,
        displayName: user.displayName,
        token: authResult.token,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await AdminApiClient.instance.logout();
    AdminApiClient.instance.clearAuth();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_displayNameKey);

    state = const AdminAuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier();
});

// ============================================================================
// Dashboard State
// ============================================================================

final dashboardStatsProvider =
    FutureProvider.autoDispose<server.DashboardStats?>((ref) async {
  final authState = ref.watch(adminAuthProvider);
  if (!authState.isAuthenticated) return null;

  final result = await AdminApiClient.instance.getDashboardStats();
  if (result.isFailure) throw Exception(result.error);
  return result.data;
});

// ============================================================================
// Users State
// ============================================================================

class UsersState {
  final List<server.UserInfo> users;
  final bool isLoading;
  final String? error;
  final int page;
  final int pageSize;
  final bool hasMore;

  const UsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.page = 0,
    this.pageSize = 20,
    this.hasMore = true,
  });

  UsersState copyWith({
    List<server.UserInfo>? users,
    bool? isLoading,
    String? error,
    int? page,
    int? pageSize,
    bool? hasMore,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  UsersNotifier() : super(const UsersState());

  Future<void> loadUsers({int page = 0}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AdminApiClient.instance.getAllUsers(
        page: page,
        pageSize: state.pageSize,
      );

      if (result.isFailure) {
        state = state.copyWith(isLoading: false, error: result.error);
        return;
      }

      final users = result.data!;
      state = state.copyWith(
        users: users,
        isLoading: false,
        page: page,
        hasMore: users.length >= state.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createUser({
    required String username,
    required String password,
    String? displayName,
    bool isAdmin = false,
  }) async {
    final result = await AdminApiClient.instance.createUser(
      username: username,
      password: password,
      displayName: displayName,
      isAdmin: isAdmin,
    );

    if (result.isSuccess) {
      await loadUsers(page: state.page);
      return true;
    }
    return false;
  }

  Future<bool> deactivateUser(int userId) async {
    final result = await AdminApiClient.instance.deactivateUser(userId);
    if (result.isSuccess) {
      await loadUsers(page: state.page);
      return true;
    }
    return false;
  }

  Future<bool> reactivateUser(int userId) async {
    final result = await AdminApiClient.instance.reactivateUser(userId);
    if (result.isSuccess) {
      await loadUsers(page: state.page);
      return true;
    }
    return false;
  }

  Future<bool> deleteUser(int userId) async {
    final result = await AdminApiClient.instance.deleteUser(userId);
    if (result.isSuccess) {
      await loadUsers(page: state.page);
      return true;
    }
    return false;
  }

  Future<bool> promoteToAdmin(int userId) async {
    final result = await AdminApiClient.instance.promoteToAdmin(userId);
    if (result.isSuccess) {
      await loadUsers(page: state.page);
      return true;
    }
    return false;
  }

  Future<bool> demoteFromAdmin(int userId) async {
    final result = await AdminApiClient.instance.demoteFromAdmin(userId);
    if (result.isSuccess) {
      await loadUsers(page: state.page);
      return true;
    }
    return false;
  }

  Future<String?> resetPassword(int userId) async {
    final result = await AdminApiClient.instance.resetUserPassword(userId);
    if (result.isSuccess) {
      return result.data;
    }
    return null;
  }

  void nextPage() {
    if (state.hasMore && !state.isLoading) {
      loadUsers(page: state.page + 1);
    }
  }

  void previousPage() {
    if (state.page > 0 && !state.isLoading) {
      loadUsers(page: state.page - 1);
    }
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  return UsersNotifier();
});

// ============================================================================
// Teams State
// ============================================================================

class TeamsState {
  final List<server.TeamSummary> teams;
  final bool isLoading;
  final String? error;
  final int page;
  final int pageSize;
  final bool hasMore;

  const TeamsState({
    this.teams = const [],
    this.isLoading = false,
    this.error,
    this.page = 0,
    this.pageSize = 20,
    this.hasMore = true,
  });

  TeamsState copyWith({
    List<server.TeamSummary>? teams,
    bool? isLoading,
    String? error,
    int? page,
    int? pageSize,
    bool? hasMore,
  }) {
    return TeamsState(
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class TeamsNotifier extends StateNotifier<TeamsState> {
  TeamsNotifier() : super(const TeamsState());

  Future<void> loadTeams({int page = 0}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AdminApiClient.instance.getAllTeams(
        page: page,
        pageSize: state.pageSize,
      );

      if (result.isFailure) {
        state = state.copyWith(isLoading: false, error: result.error);
        return;
      }

      final teams = result.data!;
      state = state.copyWith(
        teams: teams,
        isLoading: false,
        page: page,
        hasMore: teams.length >= state.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTeam({
    required String name,
    String? description,
  }) async {
    final result = await AdminApiClient.instance.createTeam(
      name: name,
      description: description,
    );

    if (result.isSuccess) {
      await loadTeams(page: state.page);
      return true;
    }
    return false;
  }

  Future<bool> deleteTeam(int teamId) async {
    final result = await AdminApiClient.instance.deleteTeam(teamId);
    if (result.isSuccess) {
      await loadTeams(page: state.page);
      return true;
    }
    return false;
  }

  void nextPage() {
    if (state.hasMore && !state.isLoading) {
      loadTeams(page: state.page + 1);
    }
  }

  void previousPage() {
    if (state.page > 0 && !state.isLoading) {
      loadTeams(page: state.page - 1);
    }
  }
}

final teamsProvider = StateNotifierProvider<TeamsNotifier, TeamsState>((ref) {
  return TeamsNotifier();
});

// ============================================================================
// Team Members State
// ============================================================================

final teamMembersProvider =
    FutureProvider.autoDispose.family<List<server.TeamMemberInfo>, int>((ref, teamId) async {
  final result = await AdminApiClient.instance.getTeamMembers(teamId);
  if (result.isFailure) throw Exception(result.error);
  return result.data ?? [];
});

// ============================================================================
// Needs Registration Check
// ============================================================================

final needsRegistrationProvider = FutureProvider.autoDispose<bool>((ref) async {
  final result = await AdminApiClient.instance.needsAdminRegistration();
  return result.data ?? false;
});
