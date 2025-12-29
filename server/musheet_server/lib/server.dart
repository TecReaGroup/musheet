import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';

/// Custom authentication handler that validates our token format
/// Token format: userId.timestamp.randomBytes
Future<AuthenticationInfo?> customAuthHandler(Session session, String token) async {
  try {
    final parts = token.split('.');

    if (parts.length >= 2) {
      final userId = int.tryParse(parts[0]);

      if (userId != null && userId > 0) {
        // Verify user exists in database
        final user = await User.db.findById(session, userId);

        if (user != null && !user.isDisabled) {
          return AuthenticationInfo(
            userId.toString(),
            <Scope>{},
            authId: token,
          );
        } else {
          session.log('[AUTH] User not found or disabled: userId=$userId', level: LogLevel.warning);
        }
      }
    }
  } catch (e) {
    session.log('[AUTH] Token validation error: $e', level: LogLevel.warning);
  }

  return null;
}

/// Health check route for REST API compatibility
class HealthRoute extends Route {
  HealthRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    return Response.ok(
      body: Body.fromString(
        jsonEncode({
          'status': 'ok',
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0.0',
        }),
        mimeType: MimeType.json,
      ),
    );
  }
}

/// Server info route for REST API compatibility
class InfoRoute extends Route {
  InfoRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    return Response.ok(
      body: Body.fromString(
        jsonEncode({
          'name': 'MuSheet Server',
          'version': '1.0.0',
          'platform': 'Serverpod',
          'dartVersion': '3.0+',
        }),
        mimeType: MimeType.json,
      ),
    );
  }
}

/// MuSheet Serverpod server
class Server {
  static late Serverpod pod;

  static Future<void> start(List<String> args) async {
    pod = Serverpod(
      args,
      Protocol(),
      Endpoints(),
      authenticationHandler: customAuthHandler,
    );

    // Add REST API routes for health checks (accessible without Serverpod client)
    pod.webServer.addRoute(HealthRoute(), '/api/status/health');
    pod.webServer.addRoute(InfoRoute(), '/api/status/info');

    // Add admin web UI routes
    // Determine the web directory path based on the server's location
    final serverDir = Directory.current.path;
    final webAdminDir = Directory('$serverDir/web/admin');
    final indexFile = File('$serverDir/web/admin/index.html');

    // Serve admin UI at /admin/* using SpaRoute for SPA support
    if (webAdminDir.existsSync() && indexFile.existsSync()) {
      pod.webServer.addRoute(
        SpaRoute(
          webAdminDir,
          fallback: indexFile,
          cacheControlFactory: StaticRoute.privateNoCache(),
        ),
        '/admin',
      );

      // Also serve at root
      pod.webServer.addRoute(
        SpaRoute(
          webAdminDir,
          fallback: indexFile,
          cacheControlFactory: StaticRoute.privateNoCache(),
        ),
        '/',
      );

      print('[SERVER] Admin Web UI mounted at /admin and /');
    } else {
      print('[SERVER] Admin Web UI directory not found: $webAdminDir');
    }

    await pod.start();
  }
}
