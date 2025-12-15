/// RPC Interceptor Chain for request/response processing
/// Provides middleware capabilities for auth, logging, retry, and caching
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'rpc_protocol.dart';

// ============================================================================
// Interceptor Interface
// ============================================================================

/// Base interface for RPC interceptors
abstract class RpcInterceptor {
  /// Priority for ordering interceptors (lower = earlier)
  int get priority => 100;

  /// Called before request is sent
  /// Return modified request or throw to abort
  Future<RpcRequest<T>> onRequest<T>(RpcRequest<T> request);

  /// Called after response is received
  /// Return modified response or throw to abort
  Future<RpcResponse<T>> onResponse<T>(RpcResponse<T> response);

  /// Called when error occurs
  /// Return modified response to recover, or throw to propagate error
  Future<RpcResponse<T>> onError<T>(RpcError error, RpcRequest<T> request);
}

/// Mixin for interceptors that only care about requests
mixin RequestOnlyInterceptor on RpcInterceptor {
  @override
  Future<RpcResponse<T>> onResponse<T>(RpcResponse<T> response) async => response;

  @override
  Future<RpcResponse<T>> onError<T>(RpcError error, RpcRequest<T> request) async {
    throw error;
  }
}

/// Mixin for interceptors that only care about responses
mixin ResponseOnlyInterceptor on RpcInterceptor {
  @override
  Future<RpcRequest<T>> onRequest<T>(RpcRequest<T> request) async => request;
}

// ============================================================================
// Interceptor Chain
// ============================================================================

/// Manages ordered chain of interceptors
class InterceptorChain {
  final List<RpcInterceptor> _interceptors = [];
  bool _isSorted = true;

  /// Add interceptor to chain
  void add(RpcInterceptor interceptor) {
    _interceptors.add(interceptor);
    _isSorted = false;
  }

  /// Remove interceptor from chain
  bool remove(RpcInterceptor interceptor) {
    return _interceptors.remove(interceptor);
  }

  /// Clear all interceptors
  void clear() {
    _interceptors.clear();
    _isSorted = true;
  }

  /// Get sorted interceptors
  List<RpcInterceptor> get interceptors {
    if (!_isSorted) {
      _interceptors.sort((a, b) => a.priority.compareTo(b.priority));
      _isSorted = true;
    }
    return List.unmodifiable(_interceptors);
  }

  /// Process request through interceptor chain
  Future<RpcRequest<T>> processRequest<T>(RpcRequest<T> request) async {
    var current = request;
    for (final interceptor in interceptors) {
      current = await interceptor.onRequest(current);
    }
    return current;
  }

  /// Process response through interceptor chain (reverse order)
  Future<RpcResponse<T>> processResponse<T>(RpcResponse<T> response) async {
    var current = response;
    for (final interceptor in interceptors.reversed) {
      current = await interceptor.onResponse(current);
    }
    return current;
  }

  /// Process error through interceptor chain
  Future<RpcResponse<T>> processError<T>(RpcError error, RpcRequest<T> request) async {
    for (final interceptor in interceptors.reversed) {
      try {
        return await interceptor.onError(error, request);
      } catch (e) {
        // Continue to next interceptor if current one re-throws
        if (e is! RpcError) {
          error = RpcError.fromException(e);
        } else {
          error = e;
        }
      }
    }
    throw error;
  }
}

// ============================================================================
// Built-in Interceptors
// ============================================================================

/// Logging interceptor for debugging
class LoggingInterceptor extends RpcInterceptor {
  final bool logRequests;
  final bool logResponses;
  final bool logErrors;
  final void Function(String)? customLogger;

  LoggingInterceptor({
    this.logRequests = true,
    this.logResponses = true,
    this.logErrors = true,
    this.customLogger,
  });

  @override
  int get priority => 10; // Run early

  void _log(String message) {
    if (customLogger != null) {
      customLogger!(message);
    } else if (kDebugMode) {
      debugPrint('[RPC] $message');
    }
  }

  @override
  Future<RpcRequest<T>> onRequest<T>(RpcRequest<T> request) async {
    if (logRequests) {
      _log('→ ${request.endpoint}.${request.method} [${request.requestId}]');
    }
    return request;
  }

  @override
  Future<RpcResponse<T>> onResponse<T>(RpcResponse<T> response) async {
    if (logResponses) {
      final status = response.isSuccess ? '✓' : '✗';
      _log('← $status [${response.requestId}] (${response.latency.inMilliseconds}ms)');
    }
    return response;
  }

  @override
  Future<RpcResponse<T>> onError<T>(RpcError error, RpcRequest<T> request) async {
    if (logErrors) {
      _log('✗ Error [${request.requestId}]: ${error.code.name} - ${error.message}');
    }
    throw error;
  }
}

/// Authentication interceptor for adding/refreshing tokens
class AuthInterceptor extends RpcInterceptor {
  final Future<String?> Function() getToken;
  final Future<String?> Function()? refreshToken;
  final void Function()? onAuthFailure;

  AuthInterceptor({
    required this.getToken,
    this.refreshToken,
    this.onAuthFailure,
  });

  @override
  int get priority => 20; // Run after logging

  @override
  Future<RpcRequest<T>> onRequest<T>(RpcRequest<T> request) async {
    if (!request.requiresAuth) return request;

    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }

  @override
  Future<RpcResponse<T>> onResponse<T>(RpcResponse<T> response) async => response;

  @override
  Future<RpcResponse<T>> onError<T>(RpcError error, RpcRequest<T> request) async {
    // Handle token expiration
    if (error.code == RpcErrorCode.tokenExpired && refreshToken != null) {
      final newToken = await refreshToken!();
      if (newToken != null) {
        // Token refreshed, can retry
        throw RpcError(
          code: error.code,
          message: 'Token refreshed, retry available',
          metadata: {'canRetry': true},
        );
      }
    }

    // Handle auth failure
    if (error.code == RpcErrorCode.authenticationRequired ||
        error.code == RpcErrorCode.tokenInvalid) {
      onAuthFailure?.call();
    }

    throw error;
  }
}

/// Retry interceptor with exponential backoff
class RetryInterceptor extends RpcInterceptor {
  final int maxRetries;
  final Duration baseDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(RpcError)? shouldRetry;

  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });

  @override
  int get priority => 30;

  @override
  Future<RpcRequest<T>> onRequest<T>(RpcRequest<T> request) async => request;

  @override
  Future<RpcResponse<T>> onResponse<T>(RpcResponse<T> response) async => response;

  @override
  Future<RpcResponse<T>> onError<T>(RpcError error, RpcRequest<T> request) async {
    final canRetry = shouldRetry?.call(error) ?? error.isRetryable;

    if (!canRetry || request.retryCount >= maxRetries) {
      throw error;
    }

    // Calculate delay with exponential backoff
    final delayMs = baseDelay.inMilliseconds *
      (backoffMultiplier * request.retryCount).clamp(1, double.infinity);
    final delay = Duration(
      milliseconds: delayMs.toInt().clamp(0, maxDelay.inMilliseconds),
    );

    if (kDebugMode) {
      debugPrint('[RPC] Retry ${request.retryCount + 1}/$maxRetries after ${delay.inMilliseconds}ms');
    }

    await Future.delayed(delay);

    // Signal that retry is available
    throw RpcError(
      code: error.code,
      message: 'Retryable error',
      metadata: {'shouldRetry': true, 'retryRequest': request.retry()},
    );
  }
}

/// Timeout interceptor
class TimeoutInterceptor extends RpcInterceptor {
  final Duration defaultTimeout;

  TimeoutInterceptor({
    this.defaultTimeout = const Duration(seconds: 30),
  });

  @override
  int get priority => 5; // Run very early

  @override
  Future<RpcRequest<T>> onRequest<T>(RpcRequest<T> request) async {
    // Set default timeout if not specified
    if (request.timeout == null) {
      return RpcRequest(
        endpoint: request.endpoint,
        method: request.method,
        payload: request.payload,
        requestId: request.requestId,
        timestamp: request.timestamp,
        headers: request.headers,
        timeout: defaultTimeout,
        retryCount: request.retryCount,
        requiresAuth: request.requiresAuth,
      );
    }
    return request;
  }

  @override
  Future<RpcResponse<T>> onResponse<T>(RpcResponse<T> response) async => response;

  @override
  Future<RpcResponse<T>> onError<T>(RpcError error, RpcRequest<T> request) async {
    throw error;
  }
}

/// Cache interceptor for GET-like operations
class CacheInterceptor extends RpcInterceptor {
  final Duration defaultTtl;
  final Map<String, _CacheEntry> _cache = {};
  final Set<String> _cacheableMethods;

  CacheInterceptor({
    this.defaultTtl = const Duration(minutes: 5),
    Set<String>? cacheableMethods,
  }) : _cacheableMethods = cacheableMethods ?? {'getScores', 'getSetlists', 'getProfile'};

  @override
  int get priority => 15;

  String _getCacheKey(RpcRequest request) {
    return '${request.endpoint}.${request.method}:${request.payload.hashCode}';
  }

  @override
  Future<RpcRequest<T>> onRequest<T>(RpcRequest<T> request) async {
    if (!_cacheableMethods.contains(request.method)) {
      return request;
    }

    final key = _getCacheKey(request);
    final entry = _cache[key];

    if (entry != null && !entry.isExpired) {
      // Return cached response by throwing with cached data
      throw _CacheHitException(entry.response);
    }

    return request;
  }

  @override
  Future<RpcResponse<T>> onResponse<T>(RpcResponse<T> response) async {
    // Cache successful responses
    if (response.isSuccess) {
      // We can't directly cache here without the request context
      // This would need to be handled differently in practice
    }
    return response;
  }

  @override
  Future<RpcResponse<T>> onError<T>(RpcError error, RpcRequest<T> request) async {
    throw error;
  }

  /// Invalidate cache for specific patterns
  void invalidate(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }

  /// Clear all cache
  void clearAll() => _cache.clear();
}

class _CacheEntry {
  final dynamic response;
  final DateTime expiresAt;

  _CacheEntry(this.response, Duration ttl)
    : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class _CacheHitException implements Exception {
  final dynamic cachedResponse;
  _CacheHitException(this.cachedResponse);
}

/// Metrics interceptor for monitoring
class MetricsInterceptor extends RpcInterceptor {
  final Map<String, _EndpointMetrics> _metrics = {};
  final void Function(String endpoint, Duration latency, bool success)? onMetric;

  MetricsInterceptor({this.onMetric});

  @override
  int get priority => 1; // Run first

  @override
  Future<RpcRequest<T>> onRequest<T>(RpcRequest<T> request) async {
    final key = '${request.endpoint}.${request.method}';
    _metrics.putIfAbsent(key, () => _EndpointMetrics());
    _metrics[key]!.recordStart();
    return request;
  }

  @override
  Future<RpcResponse<T>> onResponse<T>(RpcResponse<T> response) async {
    onMetric?.call(
      'response',
      response.latency,
      response.isSuccess,
    );
    return response;
  }

  @override
  Future<RpcResponse<T>> onError<T>(RpcError error, RpcRequest<T> request) async {
    final key = '${request.endpoint}.${request.method}';
    _metrics[key]?.recordError();
    throw error;
  }

  /// Get metrics for all endpoints
  Map<String, Map<String, dynamic>> getMetrics() {
    return _metrics.map((key, value) => MapEntry(key, value.toJson()));
  }
}

class _EndpointMetrics {
  int _totalCalls = 0;
  int _successfulCalls = 0;
  int _failedCalls = 0;
  final List<Duration> _latencies = [];
  DateTime? _lastCallAt;

  void recordStart() {
    _totalCalls++;
    _lastCallAt = DateTime.now();
  }

  void recordSuccess(Duration latency) {
    _successfulCalls++;
    _latencies.add(latency);
    if (_latencies.length > 100) _latencies.removeAt(0);
  }

  void recordError() {
    _failedCalls++;
  }

  Map<String, dynamic> toJson() {
    final avgLatency = _latencies.isEmpty
      ? 0
      : _latencies.fold<int>(0, (sum, d) => sum + d.inMilliseconds) ~/ _latencies.length;

    return {
      'totalCalls': _totalCalls,
      'successfulCalls': _successfulCalls,
      'failedCalls': _failedCalls,
      'averageLatencyMs': avgLatency,
      'lastCallAt': _lastCallAt?.toIso8601String(),
    };
  }
}
