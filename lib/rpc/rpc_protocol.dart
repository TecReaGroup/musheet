/// MuSheet RPC Protocol Specification
/// Defines unified request/response formats, error codes, and protocol versioning
library;

import 'package:flutter/foundation.dart';

// ============================================================================
// RPC Protocol Version
// ============================================================================

/// Current RPC protocol version for compatibility checking
class RpcProtocolVersion {
  static const int major = 2;
  static const int minor = 0;
  static const int patch = 0;

  static String get version => '$major.$minor.$patch';

  /// Check if server version is compatible with client
  static bool isCompatible(String serverVersion) {
    final parts = serverVersion.split('.');
    if (parts.length < 2) return false;
    final serverMajor = int.tryParse(parts[0]) ?? 0;
    // Major version must match for compatibility
    return serverMajor == major;
  }
}

// ============================================================================
// RPC Error Codes
// ============================================================================

/// Standardized error codes for RPC communication
enum RpcErrorCode {
  // Network errors (1xxx)
  networkUnavailable(1001, 'Network unavailable'),
  connectionTimeout(1002, 'Connection timeout'),
  connectionRefused(1003, 'Connection refused'),
  serverUnreachable(1004, 'Server unreachable'),

  // Authentication errors (2xxx)
  authenticationRequired(2001, 'Authentication required'),
  tokenExpired(2002, 'Token expired'),
  tokenInvalid(2003, 'Token invalid'),
  insufficientPermissions(2004, 'Insufficient permissions'),
  accountDisabled(2005, 'Account disabled'),

  // Validation errors (3xxx)
  invalidRequest(3001, 'Invalid request'),
  invalidParameter(3002, 'Invalid parameter'),
  missingParameter(3003, 'Missing required parameter'),
  dataValidationFailed(3004, 'Data validation failed'),

  // Resource errors (4xxx)
  resourceNotFound(4001, 'Resource not found'),
  resourceConflict(4002, 'Resource conflict'),
  resourceAlreadyExists(4003, 'Resource already exists'),
  resourceDeleted(4004, 'Resource has been deleted'),

  // Sync errors (5xxx)
  syncConflict(5001, 'Sync conflict detected'),
  versionMismatch(5002, 'Version mismatch'),
  mergeRequired(5003, 'Manual merge required'),
  syncInProgress(5004, 'Sync already in progress'),

  // Server errors (6xxx)
  internalServerError(6001, 'Internal server error'),
  serviceUnavailable(6002, 'Service temporarily unavailable'),
  quotaExceeded(6003, 'Storage quota exceeded'),
  rateLimited(6004, 'Rate limit exceeded'),

  // Unknown error
  unknown(9999, 'Unknown error');

  final int code;
  final String defaultMessage;

  const RpcErrorCode(this.code, this.defaultMessage);

  /// Check if error is retryable
  bool get isRetryable => switch (this) {
    networkUnavailable => true,
    connectionTimeout => true,
    connectionRefused => true,
    serverUnreachable => true,
    tokenExpired => true, // Can retry after token refresh
    serviceUnavailable => true,
    rateLimited => true,
    _ => false,
  };

  /// Get error code from integer
  static RpcErrorCode fromCode(int code) {
    return RpcErrorCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => RpcErrorCode.unknown,
    );
  }
}

// ============================================================================
// RPC Error
// ============================================================================

/// Structured RPC error with code, message, and metadata
class RpcError implements Exception {
  final RpcErrorCode code;
  final String message;
  final String? details;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? requestId;
  final StackTrace? stackTrace;

  RpcError({
    required this.code,
    String? message,
    this.details,
    this.metadata,
    DateTime? timestamp,
    this.requestId,
    this.stackTrace,
  }) : message = message ?? code.defaultMessage,
       timestamp = timestamp ?? DateTime.now();

  /// Create from exception
  factory RpcError.fromException(Object error, [StackTrace? stack]) {
    if (error is RpcError) return error;

    final errorStr = error.toString().toLowerCase();

    RpcErrorCode code;
    if (errorStr.contains('socket') || errorStr.contains('connection')) {
      code = RpcErrorCode.networkUnavailable;
    } else if (errorStr.contains('timeout')) {
      code = RpcErrorCode.connectionTimeout;
    } else if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      code = RpcErrorCode.authenticationRequired;
    } else if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      code = RpcErrorCode.insufficientPermissions;
    } else if (errorStr.contains('not found') || errorStr.contains('404')) {
      code = RpcErrorCode.resourceNotFound;
    } else if (errorStr.contains('conflict') || errorStr.contains('409')) {
      code = RpcErrorCode.resourceConflict;
    } else if (errorStr.contains('rate limit') || errorStr.contains('429')) {
      code = RpcErrorCode.rateLimited;
    } else if (errorStr.contains('server error') || errorStr.contains('500')) {
      code = RpcErrorCode.internalServerError;
    } else {
      code = RpcErrorCode.unknown;
    }

    return RpcError(
      code: code,
      message: error.toString(),
      stackTrace: stack,
    );
  }

  bool get isRetryable => code.isRetryable;

  @override
  String toString() => 'RpcError(${code.code}): $message';

  Map<String, dynamic> toJson() => {
    'code': code.code,
    'codeName': code.name,
    'message': message,
    'details': details,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'requestId': requestId,
  };
}

// ============================================================================
// RPC Request
// ============================================================================

/// Unified RPC request wrapper with metadata
class RpcRequest<T> {
  final String endpoint;
  final String method;
  final T? payload;  // Made nullable - payload is optional for RPC calls
  final String requestId;
  final DateTime timestamp;
  final Map<String, String> headers;
  final Duration? timeout;
  final int retryCount;
  final bool requiresAuth;

  RpcRequest({
    required this.endpoint,
    required this.method,
    this.payload,  // Now optional
    String? requestId,
    DateTime? timestamp,
    Map<String, String>? headers,
    this.timeout,
    this.retryCount = 0,
    this.requiresAuth = true,
  }) : requestId = requestId ?? _generateRequestId(),
       timestamp = timestamp ?? DateTime.now(),
       headers = headers ?? {};

  static String _generateRequestId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch.toRadixString(36)}-${now.microsecond.toRadixString(36)}';
  }

  /// Create a retry copy with incremented count
  RpcRequest<T> retry() => RpcRequest(
    endpoint: endpoint,
    method: method,
    payload: payload,
    requestId: requestId,
    timestamp: DateTime.now(),
    headers: headers,
    timeout: timeout,
    retryCount: retryCount + 1,
    requiresAuth: requiresAuth,
  );

  @override
  String toString() => 'RpcRequest[$requestId]: $endpoint.$method';
}

// ============================================================================
// RPC Response
// ============================================================================

/// Unified RPC response wrapper
class RpcResponse<T> {
  final T? data;
  final RpcError? error;
  final String requestId;
  final DateTime timestamp;
  final Duration latency;
  final Map<String, dynamic>? metadata;

  RpcResponse({
    this.data,
    this.error,
    required this.requestId,
    DateTime? timestamp,
    Duration? latency,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now(),
       latency = latency ?? Duration.zero;

  bool get isSuccess => error == null && data != null;
  bool get isError => error != null;
  bool get isRetryable => error?.isRetryable ?? false;

  /// Create success response
  factory RpcResponse.success(
    T data, {
    required String requestId,
    Duration? latency,
    Map<String, dynamic>? metadata,
  }) => RpcResponse(
    data: data,
    requestId: requestId,
    latency: latency,
    metadata: metadata,
  );

  /// Create error response
  factory RpcResponse.failure(
    RpcError error, {
    required String requestId,
    Duration? latency,
  }) => RpcResponse(
    error: error,
    requestId: requestId,
    latency: latency,
  );

  /// Transform successful data
  RpcResponse<R> map<R>(R Function(T) transform) {
    if (isSuccess && data != null) {
      return RpcResponse.success(
        transform(data as T),
        requestId: requestId,
        latency: latency,
        metadata: metadata,
      );
    }
    return RpcResponse.failure(
      error ?? RpcError(code: RpcErrorCode.unknown),
      requestId: requestId,
      latency: latency,
    );
  }

  @override
  String toString() => isSuccess
    ? 'RpcResponse[$requestId]: Success'
    : 'RpcResponse[$requestId]: Error(${error?.code.code})';
}

// ============================================================================
// Sync Protocol Types
// ============================================================================

/// Sync operation types for the offline queue
enum SyncOperationType {
  create,
  update,
  delete,
  merge,
}

/// Entity types that can be synced
enum SyncEntityType {
  score,
  instrumentScore,
  annotation,
  setlist,
  setlistScore,
}

/// Sync operation metadata
@immutable
class SyncOperation {
  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperationType operationType;
  final Map<String, dynamic> data;
  final int version;
  final DateTime createdAt;
  final int retryCount;
  final String? parentOperationId;

  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.data,
    required this.version,
    required this.createdAt,
    this.retryCount = 0,
    this.parentOperationId,
  });

  /// Create retry copy
  SyncOperation retry() => SyncOperation(
    id: id,
    entityType: entityType,
    entityId: entityId,
    operationType: operationType,
    data: data,
    version: version,
    createdAt: createdAt,
    retryCount: retryCount + 1,
    parentOperationId: parentOperationId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType.name,
    'entityId': entityId,
    'operationType': operationType.name,
    'data': data,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'parentOperationId': parentOperationId,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    id: json['id'] as String,
    entityType: SyncEntityType.values.byName(json['entityType'] as String),
    entityId: json['entityId'] as String,
    operationType: SyncOperationType.values.byName(json['operationType'] as String),
    data: Map<String, dynamic>.from(json['data'] as Map),
    version: json['version'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
    parentOperationId: json['parentOperationId'] as String?,
  );
}

/// Conflict information for manual resolution
@immutable
class SyncConflict {
  final String entityId;
  final SyncEntityType entityType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final int localVersion;
  final int serverVersion;
  final DateTime localUpdatedAt;
  final DateTime serverUpdatedAt;
  final ConflictResolutionStrategy? suggestedResolution;

  const SyncConflict({
    required this.entityId,
    required this.entityType,
    required this.localData,
    required this.serverData,
    required this.localVersion,
    required this.serverVersion,
    required this.localUpdatedAt,
    required this.serverUpdatedAt,
    this.suggestedResolution,
  });

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'entityType': entityType.name,
    'localData': localData,
    'serverData': serverData,
    'localVersion': localVersion,
    'serverVersion': serverVersion,
    'localUpdatedAt': localUpdatedAt.toIso8601String(),
    'serverUpdatedAt': serverUpdatedAt.toIso8601String(),
    'suggestedResolution': suggestedResolution?.name,
  };
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  /// Keep local version, overwrite server
  keepLocal,
  /// Keep server version, overwrite local
  keepServer,
  /// Keep both (create duplicate for scores)
  keepBoth,
  /// Merge changes (for annotations with CRDT)
  merge,
  /// Require user decision
  manual,
  /// Use last-write-wins based on timestamp
  lastWriteWins,
}
