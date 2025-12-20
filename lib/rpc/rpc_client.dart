/// Type-safe RPC Client Layer
/// Wraps Serverpod client with unified error handling, interceptors, and connection management
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:musheet_client/musheet_client.dart' as server;
import 'package:serverpod_client/serverpod_client.dart' show ClientAuthKeyProvider, wrapAsBearerAuthHeaderValue;

import 'rpc_protocol.dart';
import 'rpc_interceptors.dart';

// ============================================================================
// Connection State
// ============================================================================

/// Connection state enumeration
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Connection state with metadata
class ConnectionStatus {
  final ConnectionState state;
  final DateTime? connectedAt;
  final DateTime? lastPingAt;
  final Duration? latency;
  final String? errorMessage;
  final int reconnectAttempts;

  const ConnectionStatus({
    this.state = ConnectionState.disconnected,
    this.connectedAt,
    this.lastPingAt,
    this.latency,
    this.errorMessage,
    this.reconnectAttempts = 0,
  });

  ConnectionStatus copyWith({
    ConnectionState? state,
    DateTime? connectedAt,
    DateTime? lastPingAt,
    Duration? latency,
    String? errorMessage,
    int? reconnectAttempts,
  }) => ConnectionStatus(
    state: state ?? this.state,
    connectedAt: connectedAt ?? this.connectedAt,
    lastPingAt: lastPingAt ?? this.lastPingAt,
    latency: latency ?? this.latency,
    errorMessage: errorMessage,
    reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
  );

  bool get isConnected => state == ConnectionState.connected;
  bool get isConnecting => state == ConnectionState.connecting || state == ConnectionState.reconnecting;
}

// ============================================================================
// Auth Provider
// ============================================================================

/// Custom auth provider for Serverpod
class _RpcAuthProvider implements ClientAuthKeyProvider {
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  @override
  Future<String?> get authHeaderValue async {
    if (_token == null) return null;
    return wrapAsBearerAuthHeaderValue(_token!);
  }
}

// ============================================================================
// RPC Client Configuration
// ============================================================================

/// Configuration for RPC client
class RpcClientConfig {
  final String baseUrl;
  final Duration connectionTimeout;
  final Duration requestTimeout;
  final Duration heartbeatInterval;
  final int maxRetries;
  final bool enableLogging;
  final bool enableMetrics;
  final bool enableCache;

  const RpcClientConfig({
    required this.baseUrl,
    this.connectionTimeout = const Duration(seconds: 10),
    this.requestTimeout = const Duration(seconds: 30),
    this.heartbeatInterval = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableLogging = true,
    this.enableMetrics = true,
    this.enableCache = true,
  });
}

// ============================================================================
// RPC Client
// ============================================================================

/// Type-safe RPC client with interceptor support
class RpcClient {
  static RpcClient? _instance;

  final RpcClientConfig config;
  late final server.Client _client;
  late final _RpcAuthProvider _authProvider;
  final InterceptorChain _interceptorChain = InterceptorChain();

  // Connection management
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _connectionStatus = const ConnectionStatus();
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  // Auth state
  String? _authToken;
  int? _userId;

  // Metrics interceptor reference for querying
  MetricsInterceptor? _metricsInterceptor;

  RpcClient._({required this.config}) {
    _authProvider = _RpcAuthProvider();

    final baseUrl = config.baseUrl.endsWith('/')
      ? config.baseUrl.substring(0, config.baseUrl.length - 1)
      : config.baseUrl;

    _client = server.Client(
      baseUrl,
      connectionTimeout: config.connectionTimeout,
    );
    _client.authKeyProvider = _authProvider;

    _setupInterceptors();
  }

  /// Initialize singleton
  static void initialize(RpcClientConfig config) {
    _instance?.dispose();
    _instance = RpcClient._(config: config);
    if (kDebugMode) {
      debugPrint('[RpcClient] Initialized: ${config.baseUrl}');
    }
  }

  /// Get singleton instance
  static RpcClient get instance {
    if (_instance == null) {
      throw StateError('RpcClient not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Setup default interceptors
  void _setupInterceptors() {
    if (config.enableLogging) {
      _interceptorChain.add(LoggingInterceptor());
    }

    if (config.enableMetrics) {
      _metricsInterceptor = MetricsInterceptor();
      _interceptorChain.add(_metricsInterceptor!);
    }

    _interceptorChain.add(TimeoutInterceptor(
      defaultTimeout: config.requestTimeout,
    ));

    _interceptorChain.add(AuthInterceptor(
      getToken: () async => _authToken,
      onAuthFailure: () {
        _authToken = null;
        _userId = null;
        _authProvider.setToken(null);
      },
    ));

    _interceptorChain.add(RetryInterceptor(
      maxRetries: config.maxRetries,
    ));

    if (config.enableCache) {
      _interceptorChain.add(CacheInterceptor());
    }
  }

  /// Add custom interceptor
  void addInterceptor(RpcInterceptor interceptor) {
    _interceptorChain.add(interceptor);
  }

  /// Connection status stream
  Stream<ConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;

  /// Current connection status
  ConnectionStatus get connectionStatus => _connectionStatus;

  /// Check if connected
  bool get isConnected => _connectionStatus.isConnected;

  /// Check if logged in
  bool get isLoggedIn => _authToken != null && _userId != null;

  /// Current user ID
  int? get userId => _userId;

  /// Get metrics
  Map<String, Map<String, dynamic>>? get metrics => _metricsInterceptor?.getMetrics();

  // ============================================================================
  // Connection Management
  // ============================================================================

  /// Update connection status
  void _updateConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    _connectionStatusController.add(status);
  }

  /// Check server health and establish connection
  Future<RpcResponse<bool>> connect() async {
    _updateConnectionStatus(_connectionStatus.copyWith(
      state: ConnectionState.connecting,
    ));

    try {
      final startTime = DateTime.now();
      await _client.status.health();
      final latency = DateTime.now().difference(startTime);

      _updateConnectionStatus(ConnectionStatus(
        state: ConnectionState.connected,
        connectedAt: DateTime.now(),
        lastPingAt: DateTime.now(),
        latency: latency,
      ));

      _startHeartbeat();

      return RpcResponse.success(
        true,
        requestId: 'connect',
        latency: latency,
      );
    } catch (e) {
      final error = RpcError.fromException(e);
      _updateConnectionStatus(ConnectionStatus(
        state: ConnectionState.error,
        errorMessage: error.message,
      ));

      return RpcResponse.failure(error, requestId: 'connect');
    }
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(config.heartbeatInterval, (_) async {
      await _ping();
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Ping server
  Future<void> _ping() async {
    try {
      final startTime = DateTime.now();
      await _client.status.ping();
      final latency = DateTime.now().difference(startTime);

      _updateConnectionStatus(_connectionStatus.copyWith(
        state: ConnectionState.connected,
        lastPingAt: DateTime.now(),
        latency: latency,
        reconnectAttempts: 0,
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RpcClient] Heartbeat failed: $e');
      }
      _handleDisconnection();
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _updateConnectionStatus(_connectionStatus.copyWith(
      state: ConnectionState.reconnecting,
      reconnectAttempts: _connectionStatus.reconnectAttempts + 1,
    ));

    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    final delay = Duration(
      seconds: (2 * _connectionStatus.reconnectAttempts).clamp(1, 60),
    );

    _reconnectTimer = Timer(delay, () async {
      if (_connectionStatus.state == ConnectionState.reconnecting) {
        await connect();
      }
    });
  }

  // ============================================================================
  // Auth Operations
  // ============================================================================

  /// Set auth credentials
  void setAuthCredentials(String token, int userId) {
    _authToken = token;
    _userId = userId;
    _authProvider.setToken(token);
    if (kDebugMode) {
      debugPrint('[RpcClient] Auth set for user: $userId');
    }
  }

  /// Clear auth credentials
  void clearAuth() {
    _authToken = null;
    _userId = null;
    _authProvider.setToken(null);
    if (kDebugMode) {
      debugPrint('[RpcClient] Auth cleared');
    }
  }

  /// Register new user
  Future<RpcResponse<AuthResultData>> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    return _executeCall(
      endpoint: 'auth',
      method: 'register',
      requiresAuth: false,
      call: () => _client.auth.register(username, password, displayName: displayName),
      transform: (result) {
        final data = AuthResultData.fromServerpod(result);
        if (data.success && data.token != null) {
          setAuthCredentials(data.token!, data.userId!);
        }
        return data;
      },
    );
  }

  /// Login user
  Future<RpcResponse<AuthResultData>> login({
    required String username,
    required String password,
  }) async {
    return _executeCall(
      endpoint: 'auth',
      method: 'login',
      requiresAuth: false,
      call: () => _client.auth.login(username, password),
      transform: (result) {
        final data = AuthResultData.fromServerpod(result);
        if (data.success && data.token != null) {
          setAuthCredentials(data.token!, data.userId!);
        }
        return data;
      },
    );
  }

  /// Logout user
  Future<RpcResponse<bool>> logout() async {
    return _executeCall(
      endpoint: 'auth',
      method: 'logout',
      call: () async {
        await _client.auth.logout();
        clearAuth();
        return true;
      },
      transform: (result) => result,
    );
  }

  /// Validate token
  Future<RpcResponse<bool>> validateToken() async {
    if (_authToken == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'validateToken',
      );
    }

    return _executeCall(
      endpoint: 'auth',
      method: 'validateToken',
      call: () => _client.auth.validateToken(_authToken!),
      transform: (result) => result != null,
    );
  }

  // ============================================================================
  // Score Operations
  // ============================================================================

  /// Get all scores
  Future<RpcResponse<List<server.Score>>> getScores({DateTime? since}) async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'getScores',
      );
    }

    return _executeCall(
      endpoint: 'score',
      method: 'getScores',
      call: () => _client.score.getScores(_userId!, since: since),
      transform: (result) => result,
    );
  }

  // NOTE: Individual score/instrument mutations (upsertScore, deleteScore,
  // getInstrumentScores, upsertInstrumentScore, deleteInstrumentScore) have been
  // removed. These operations are now handled by LibrarySyncService via batch
  // sync (libraryPush/libraryPull).

  // ============================================================================
  // Setlist Operations (getSetlists kept for debug purposes)
  // ============================================================================

  /// Get all setlists (for debug purposes)
  Future<RpcResponse<List<server.Setlist>>> getSetlists() async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'getSetlists',
      );
    }

    return _executeCall(
      endpoint: 'setlist',
      method: 'getSetlists',
      call: () => _client.setlist.getSetlists(_userId!),
      transform: (result) => result,
    );
  }

  // NOTE: upsertSetlist has been removed. Setlist mutations are now handled
  // by LibrarySyncService via batch sync (libraryPush/libraryPull).

  // ============================================================================
  // File Operations
  // ============================================================================

  /// Upload PDF
  Future<RpcResponse<server.FileUploadResult>> uploadPdf({
    required int instrumentScoreId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'uploadPdf',
      );
    }

    return _executeCall(
      endpoint: 'file',
      method: 'uploadPdf',
      call: () {
        final byteData = ByteData.view(fileBytes.buffer);
        return _client.file.uploadPdf(_userId!, instrumentScoreId, byteData, fileName);
      },
      transform: (result) => result,
    );
  }

  /// Download PDF
  Future<RpcResponse<Uint8List>> downloadPdf(int instrumentScoreId) async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'downloadPdf',
      );
    }

    return _executeCall(
      endpoint: 'file',
      method: 'downloadPdf',
      call: () => _client.file.downloadPdf(_userId!, instrumentScoreId),
      transform: (result) {
        if (result == null) {
          throw RpcError(code: RpcErrorCode.resourceNotFound, message: 'PDF not found');
        }
        return result.buffer.asUint8List();
      },
    );
  }

  /// Check if PDF with given hash exists on server (for instant upload/秒传)
  Future<RpcResponse<bool>> checkPdfHash(String hash) async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'checkPdfHash',
      );
    }

    return _executeCall(
      endpoint: 'file',
      method: 'checkPdfHash',
      call: () => _client.file.checkPdfHash(_userId!, hash),
      transform: (result) => result,
    );
  }

  /// Download PDF by hash (for global deduplication)
  /// Per APP_SYNC_LOGIC.md §3.4: Download by hash instead of serverId
  Future<RpcResponse<Uint8List>> downloadPdfByHash(String hash) async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'downloadPdfByHash',
      );
    }

    return _executeCall(
      endpoint: 'file',
      method: 'downloadPdfByHash',
      call: () => _client.file.downloadPdfByHash(_userId!, hash),
      transform: (result) {
        if (result == null) {
          throw RpcError(code: RpcErrorCode.resourceNotFound, message: 'PDF not found');
        }
        return result.buffer.asUint8List();
      },
    );
  }

  /// Upload PDF by hash directly (independent of metadata sync)
  /// Per APP_SYNC_LOGIC.md §3.3: PDF uploads don't require serverId
  Future<RpcResponse<server.FileUploadResult>> uploadPdfByHash({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'uploadPdfByHash',
      );
    }

    return _executeCall(
      endpoint: 'file',
      method: 'uploadPdfByHash',
      call: () {
        final byteData = ByteData.view(fileBytes.buffer);
        return _client.file.uploadPdfByHash(_userId!, byteData, fileName);
      },
      transform: (result) => result,
    );
  }

  // ============================================================================
  // Library Sync Operations (Zotero-style batch sync)
  // NOTE: Legacy syncAll/getSyncStatus methods have been removed.
  // All sync operations now use libraryPush/libraryPull.
  // ============================================================================

  /// Pull changes since a given library version
  /// This implements the Zotero-style pull where client specifies the last known version
  Future<RpcResponse<LibrarySyncPullResult>> libraryPull({int since = 0}) async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'libraryPull',
      );
    }

    if (kDebugMode) {
      debugPrint('[RpcClient] libraryPull: userId=$_userId, since=$since');
    }

    return _executeCallNullable(
      endpoint: 'librarySync',
      method: 'pull',
      call: () => _client.librarySync.pull(_userId!, since: since),
      transform: (result) {
        if (result == null) {
          if (kDebugMode) {
            debugPrint('[RpcClient] libraryPull: server returned null, using empty result');
          }
          return LibrarySyncPullResult(libraryVersion: since);
        }
        if (kDebugMode) {
          debugPrint('[RpcClient] libraryPull: received response with libraryVersion=${result.libraryVersion}');
        }
        return LibrarySyncPullResult.fromServerpod(result);
      },
    );
  }

  /// Push local changes to server
  /// Returns conflict=true if client's version is behind server (needs pull first)
  Future<RpcResponse<LibrarySyncPushResult>> libraryPush({
    required int clientLibraryVersion,
    required List<Map<String, dynamic>> scores,
    List<Map<String, dynamic>> instrumentScores = const [],
    List<Map<String, dynamic>> annotations = const [],
    required List<Map<String, dynamic>> setlists,
    List<Map<String, dynamic>> setlistScores = const [],
    required List<String> deletes,
  }) async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'libraryPush',
      );
    }

    // Build push request with null-safe type conversions
    if (kDebugMode) {
      debugPrint('[RpcClient] Building SyncPushRequest: scores=${scores.length}, instrumentScores=${instrumentScores.length}, annotations=${annotations.length}, setlists=${setlists.length}, setlistScores=${setlistScores.length}, deletes=${deletes.length}');
    }
    
    try {
      final request = server.SyncPushRequest(
        clientLibraryVersion: clientLibraryVersion,
        scores: scores.map((s) => server.SyncEntityChange(
          entityType: s['entityType'] as String,
          entityId: s['entityId'] as String,
          serverId: s['serverId'] as int?,
          operation: s['operation'] as String,
          version: (s['version'] as int?) ?? 1,  // Default to 1 if null
          data: s['data'] as String,
          localUpdatedAt: DateTime.parse(s['localUpdatedAt'] as String),
        )).toList(),
        instrumentScores: instrumentScores.map((s) => server.SyncEntityChange(
          entityType: s['entityType'] as String,
          entityId: s['entityId'] as String,
          serverId: s['serverId'] as int?,
          operation: s['operation'] as String,
          version: (s['version'] as int?) ?? 1,  // Default to 1 if null
          data: s['data'] as String,
          localUpdatedAt: DateTime.parse(s['localUpdatedAt'] as String),
        )).toList(),
        annotations: annotations.map((s) => server.SyncEntityChange(
          entityType: s['entityType'] as String,
          entityId: s['entityId'] as String,
          serverId: s['serverId'] as int?,
          operation: s['operation'] as String,
          version: (s['version'] as int?) ?? 1,  // Default to 1 if null
          data: s['data'] as String,
          localUpdatedAt: DateTime.parse(s['localUpdatedAt'] as String),
        )).toList(),
        setlists: setlists.map((s) => server.SyncEntityChange(
          entityType: s['entityType'] as String,
          entityId: s['entityId'] as String,
          serverId: s['serverId'] as int?,
          operation: s['operation'] as String,
          version: (s['version'] as int?) ?? 1,  // Default to 1 if null
          data: s['data'] as String,
          localUpdatedAt: DateTime.parse(s['localUpdatedAt'] as String),
        )).toList(),
        setlistScores: setlistScores.map((s) => server.SyncEntityChange(
          entityType: s['entityType'] as String,
          entityId: s['entityId'] as String,
          serverId: s['serverId'] as int?,
          operation: s['operation'] as String,
          version: (s['version'] as int?) ?? 1,  // Default to 1 if null
          data: s['data'] as String,
          localUpdatedAt: DateTime.parse(s['localUpdatedAt'] as String),
        )).toList(),
        deletes: deletes,
      );
      
      if (kDebugMode) {
        debugPrint('[RpcClient] SyncPushRequest built successfully');
      }

      return _executeCall(
        endpoint: 'librarySync',
        method: 'push',
        call: () => _client.librarySync.push(_userId!, request),
        transform: (result) {
          return LibrarySyncPushResult.fromServerpod(result);
        },
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[RpcClient] Error building SyncPushRequest: $e');
        debugPrint('[RpcClient] Stack: $stack');
      }
      return RpcResponse.failure(
        RpcError.fromException(e, stack),
        requestId: 'libraryPush',
      );
    }
  }

  /// Get current library version for a user
  Future<RpcResponse<int>> getLibraryVersion() async {
    if (_userId == null) {
      return RpcResponse.failure(
        RpcError(code: RpcErrorCode.authenticationRequired),
        requestId: 'getLibraryVersion',
      );
    }

    return _executeCall(
      endpoint: 'librarySync',
      method: 'getLibraryVersion',
      call: () => _client.librarySync.getLibraryVersion(_userId!),
      transform: (result) => result,
    );
  }

  // ============================================================================
  // Internal Execution
  // ============================================================================

  /// Execute RPC call with interceptor chain (for nullable results)
  Future<RpcResponse<R>> _executeCallNullable<T, R>({
    required String endpoint,
    required String method,
    required Future<T?> Function() call,
    required R Function(T?) transform,
    bool requiresAuth = true,
  }) async {
    final request = RpcRequest<R>(
      endpoint: endpoint,
      method: method,
      // payload is now optional, no need to cast null
      requiresAuth: requiresAuth,
    );

    try {
      // Process request through interceptors
      final processedRequest = await _interceptorChain.processRequest(request);

      // Execute actual call
      final startTime = DateTime.now();
      final result = await call().timeout(
        processedRequest.timeout ?? config.requestTimeout,
        onTimeout: () => throw RpcError(code: RpcErrorCode.connectionTimeout),
      );
      final latency = DateTime.now().difference(startTime);

      // Transform and wrap response (null is allowed)
      final response = RpcResponse.success(
        transform(result),
        requestId: request.requestId,
        latency: latency,
      );

      // Process response through interceptors
      return await _interceptorChain.processResponse(response);
    } catch (e, stack) {
      final error = e is RpcError ? e : RpcError.fromException(e, stack);

      try {
        // Try to recover through interceptors
        return await _interceptorChain.processError(error, request);
      } catch (finalError) {
        return RpcResponse.failure(
          finalError is RpcError ? finalError : RpcError.fromException(finalError),
          requestId: request.requestId,
        );
      }
    }
  }

  /// Execute RPC call with interceptor chain
  Future<RpcResponse<R>> _executeCall<T, R>({
    required String endpoint,
    required String method,
    required Future<T> Function() call,
    required R Function(T) transform,
    bool requiresAuth = true,
  }) async {
    final request = RpcRequest<R>(
      endpoint: endpoint,
      method: method,
      // payload is now optional, no need to cast null
      requiresAuth: requiresAuth,
    );

    try {
      // Process request through interceptors
      final processedRequest = await _interceptorChain.processRequest(request);

      // Execute actual call
      final startTime = DateTime.now();
      final result = await call().timeout(
        processedRequest.timeout ?? config.requestTimeout,
        onTimeout: () => throw RpcError(code: RpcErrorCode.connectionTimeout),
      );
      final latency = DateTime.now().difference(startTime);

      // Transform and wrap response
      final response = RpcResponse.success(
        transform(result),
        requestId: request.requestId,
        latency: latency,
      );

      // Process response through interceptors
      return await _interceptorChain.processResponse(response);
    } catch (e, stack) {
      final error = e is RpcError ? e : RpcError.fromException(e, stack);

      try {
        // Try to recover through interceptors
        return await _interceptorChain.processError(error, request);
      } catch (finalError) {
        return RpcResponse.failure(
          finalError is RpcError ? finalError : RpcError.fromException(finalError),
          requestId: request.requestId,
        );
      }
    }
  }

  // ============================================================================
  // Lifecycle
  // ============================================================================

  /// Dispose resources
  void dispose() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _connectionStatusController.close();
    _interceptorChain.clear();
  }
}

// ============================================================================
// Auth Result Data (moved from backend_service.dart)
// ============================================================================

/// Local user profile wrapper
class LocalUserProfile {
  final int id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final String? preferredInstrument;
  final String? bio;

  LocalUserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.preferredInstrument,
    this.bio,
  });

  factory LocalUserProfile.fromServerpod(server.UserProfile profile) {
    return LocalUserProfile(
      id: profile.id,
      username: profile.username,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      createdAt: profile.createdAt,
      preferredInstrument: profile.preferredInstrument,
      bio: profile.bio,
    );
  }
}

/// Auth result from login/register
class AuthResultData {
  final bool success;
  final String? token;
  final int? userId;
  final String? error;
  final LocalUserProfile? user;
  final bool mustChangePassword;

  AuthResultData({
    required this.success,
    this.token,
    this.userId,
    this.error,
    this.user,
    this.mustChangePassword = false,
  });

  factory AuthResultData.fromServerpod(server.AuthResult result) {
    LocalUserProfile? userProfile;
    if (result.user != null) {
      final user = result.user!;
      userProfile = LocalUserProfile(
        id: user.id!,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarPath,
        createdAt: user.createdAt,
        preferredInstrument: null,
        bio: null,
      );
    }

    return AuthResultData(
      success: result.success,
      token: result.token,
      userId: result.user?.id,
      error: result.errorMessage,
      user: userProfile,
      mustChangePassword: result.mustChangePassword,
    );
  }
}

// ============================================================================
// Library Sync Result Types
// ============================================================================

/// Result from library pull operation
class LibrarySyncPullResult {
  final int libraryVersion;
  final List<SyncEntityData> scores;
  final List<SyncEntityData> instrumentScores;
  final List<SyncEntityData> annotations;
  final List<SyncEntityData> setlists;
  final List<SyncEntityData> setlistScores;
  final List<String> deleted;
  final bool isFullSync;

  LibrarySyncPullResult({
    required this.libraryVersion,
    this.scores = const [],
    this.instrumentScores = const [],
    this.annotations = const [],
    this.setlists = const [],
    this.setlistScores = const [],
    this.deleted = const [],
    this.isFullSync = false,
  });

  factory LibrarySyncPullResult.fromServerpod(dynamic result) {
    return LibrarySyncPullResult(
      libraryVersion: (result.libraryVersion as int?) ?? 0,
      scores: _parseEntityList(result.scores),
      instrumentScores: _parseEntityList(result.instrumentScores),
      annotations: _parseEntityList(result.annotations),
      setlists: _parseEntityList(result.setlists),
      setlistScores: _parseEntityList(result.setlistScores),
      deleted: (result.deleted as List?)?.cast<String>() ?? [],
      isFullSync: (result.isFullSync as bool?) ?? false,
    );
  }

  static List<SyncEntityData> _parseEntityList(dynamic list) {
    if (list == null) return [];
    return (list as List).map((s) => SyncEntityData.fromServerpod(s)).toList();
  }
}

/// Result from library push operation
class LibrarySyncPushResult {
  final bool success;
  final bool conflict;
  final int? newLibraryVersion;
  final int? serverLibraryVersion;
  final List<String> accepted;
  final Map<String, int> serverIdMapping;
  final String? errorMessage;

  LibrarySyncPushResult({
    required this.success,
    this.conflict = false,
    this.newLibraryVersion,
    this.serverLibraryVersion,
    this.accepted = const [],
    this.serverIdMapping = const {},
    this.errorMessage,
  });

  factory LibrarySyncPushResult.fromServerpod(dynamic result) {
    return LibrarySyncPushResult(
      success: (result.success as bool?) ?? false,
      conflict: (result.conflict as bool?) ?? false,
      newLibraryVersion: result.newLibraryVersion as int?,
      serverLibraryVersion: result.serverLibraryVersion as int?,
      accepted: (result.accepted as List?)?.cast<String>() ?? [],
      serverIdMapping: (result.serverIdMapping as Map?)?.cast<String, int>() ?? {},
      errorMessage: result.errorMessage as String?,
    );
  }
}

/// Entity data from sync pull
class SyncEntityData {
  final String entityType;
  final int serverId;
  final int version;
  final String data;
  final DateTime? updatedAt;
  final bool isDeleted;

  SyncEntityData({
    required this.entityType,
    required this.serverId,
    required this.version,
    required this.data,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory SyncEntityData.fromServerpod(dynamic entity) {
    return SyncEntityData(
      entityType: entity.entityType as String,
      serverId: entity.serverId as int,
      version: entity.version as int,
      data: entity.data as String,
      updatedAt: entity.updatedAt as DateTime?,
      isDeleted: (entity.isDeleted as bool?) ?? false,
    );
  }

  /// Parse the JSON data
  Map<String, dynamic> get parsedData {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(data) as Map,
      );
    } catch (_) {
      return {};
    }
  }
}
