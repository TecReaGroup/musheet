import 'dart:convert';
import 'package:serverpod/serverpod.dart';

/// Status endpoint for health checks and server info
class StatusEndpoint extends Endpoint {
  /// Health check endpoint - returns JSON string for compatibility
  Future<String> health(Session session) async {
    return jsonEncode({
      'status': 'ok',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    });
  }

  /// Get server info - returns JSON string for compatibility
  Future<String> info(Session session) async {
    return jsonEncode({
      'name': 'MuSheet Server',
      'version': '1.0.0',
      'platform': 'Serverpod',
      'dartVersion': '3.0+',
    });
  }

  /// Ping endpoint for connection testing
  Future<String> ping(Session session) async {
    return 'pong';
  }
}