/// Network layer error types
///
/// Centralized error definitions for the network layer.
/// All API errors are categorized into these types for consistent handling.
library;

import 'package:flutter/foundation.dart';

/// Error categories
enum NetworkErrorType {
  /// Network-level errors (socket, DNS, timeout)
  network,

  /// Server returned 401 - token expired or invalid
  unauthorized,

  /// Server returned 403 - permission denied
  forbidden,

  /// Server returned 404 - resource not found
  notFound,

  /// Server returned 409/412 - conflict
  conflict,

  /// Server returned 4xx - client error
  badRequest,

  /// Server returned 5xx - server error
  serverError,

  /// Unknown error
  unknown,
}

/// Base class for all network errors
@immutable
class NetworkError implements Exception {
  final NetworkErrorType type;
  final String message;
  final dynamic originalError;
  final int? statusCode;

  const NetworkError({
    required this.type,
    required this.message,
    this.originalError,
    this.statusCode,
  });

  /// Check if this error should trigger service disconnection
  bool get shouldMarkDisconnected =>
      type == NetworkErrorType.network || type == NetworkErrorType.serverError;

  /// Check if this is an auth error that needs re-login
  bool get isAuthError => type == NetworkErrorType.unauthorized;

  /// Create from exception
  factory NetworkError.fromException(dynamic e) {
    final message = e.toString();

    // Network errors
    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Network is unreachable') ||
        message.contains('Connection reset') ||
        message.contains('Connection closed')) {
      return NetworkError(
        type: NetworkErrorType.network,
        message: 'Network connection failed',
        originalError: e,
      );
    }

    // Timeout
    if (message.contains('TimeoutException') ||
        message.contains('timed out') ||
        message.contains('Timeout')) {
      return NetworkError(
        type: NetworkErrorType.network,
        message: 'Request timed out',
        originalError: e,
      );
    }

    // DNS errors
    if (message.contains('Failed host lookup') ||
        message.contains('getaddrinfo') ||
        message.contains('DNS')) {
      return NetworkError(
        type: NetworkErrorType.network,
        message: 'Unable to resolve server address',
        originalError: e,
      );
    }

    // SSL/TLS errors
    if (message.contains('CERTIFICATE') ||
        message.contains('SSL') ||
        message.contains('TLS') ||
        message.contains('Handshake')) {
      return NetworkError(
        type: NetworkErrorType.network,
        message: 'Secure connection failed',
        originalError: e,
      );
    }

    // HTTP status code based errors
    if (message.contains('401') || message.contains('Unauthorized')) {
      return NetworkError(
        type: NetworkErrorType.unauthorized,
        message: 'Authentication required',
        originalError: e,
        statusCode: 401,
      );
    }

    if (message.contains('403') ||
        message.contains('Forbidden') ||
        message.contains('Permission denied') ||
        message.contains('Not a team member') ||
        message.contains('NOT_MEMBER') ||
        message.contains('PERMISSION_DENIED')) {
      return NetworkError(
        type: NetworkErrorType.forbidden,
        message: 'Permission denied',
        originalError: e,
        statusCode: 403,
      );
    }

    if (message.contains('404') || message.contains('Not found')) {
      return NetworkError(
        type: NetworkErrorType.notFound,
        message: 'Resource not found',
        originalError: e,
        statusCode: 404,
      );
    }

    if (message.contains('409') ||
        message.contains('412') ||
        message.contains('conflict') ||
        message.contains('Conflict')) {
      return NetworkError(
        type: NetworkErrorType.conflict,
        message: 'Data conflict',
        originalError: e,
        statusCode: 409,
      );
    }

    if (message.contains('400') || message.contains('Bad request')) {
      return NetworkError(
        type: NetworkErrorType.badRequest,
        message: 'Invalid request',
        originalError: e,
        statusCode: 400,
      );
    }

    if (message.contains('422') || message.contains('Unprocessable')) {
      return NetworkError(
        type: NetworkErrorType.badRequest,
        message: 'Validation failed',
        originalError: e,
        statusCode: 422,
      );
    }

    if (message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('504') ||
        message.contains('Internal server error') ||
        message.contains('Bad Gateway') ||
        message.contains('Service Unavailable')) {
      return NetworkError(
        type: NetworkErrorType.serverError,
        message: 'Server error',
        originalError: e,
        statusCode: 500,
      );
    }

    // Unknown error
    return NetworkError(
      type: NetworkErrorType.unknown,
      message: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      originalError: e,
    );
  }

  @override
  String toString() => 'NetworkError($type): $message';
}
