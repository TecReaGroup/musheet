import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Application endpoint for multi-app support (admin only)
class ApplicationEndpoint extends Endpoint {
  /// Get all applications (admin only)
  Future<List<Application>> getApplications(Session session, int adminUserId) async {
    await _requireAdmin(session, adminUserId);
    return await Application.db.find(session);
  }

  /// Register new application (admin only)
  Future<Application> registerApplication(
    Session session,
    int adminUserId,
    String appId,
    String name, {
    String? description,
  }) async {
    await _requireAdmin(session, adminUserId);

    // Validate app ID format
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9._-]*$').hasMatch(appId)) {
      throw InvalidAppIdException();
    }

    // Check if app ID already exists
    final existing = await Application.db.find(
      session,
      where: (a) => a.appId.equals(appId),
    );
    if (existing.isNotEmpty) {
      throw AppAlreadyExistsException();
    }

    final app = Application(
      appId: appId,
      name: name,
      description: description,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await Application.db.insertRow(session, app);
  }

  /// Update application (admin only)
  Future<Application> updateApplication(
    Session session,
    int adminUserId,
    int applicationId, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    await _requireAdmin(session, adminUserId);

    final app = await Application.db.findById(session, applicationId);
    if (app == null) throw NotFoundException('Application not found');

    if (name != null) app.name = name;
    if (description != null) app.description = description;
    if (isActive != null) app.isActive = isActive;
    app.updatedAt = DateTime.now();

    return await Application.db.updateRow(session, app);
  }

  /// Delete application (admin only)
  Future<bool> deleteApplication(Session session, int adminUserId, int applicationId) async {
    await _requireAdmin(session, adminUserId);

    final app = await Application.db.findById(session, applicationId);
    if (app == null) return false;

    // Delete related user app data
    await UserAppData.db.deleteWhere(
      session,
      where: (d) => d.applicationId.equals(app.id!),
    );

    await Application.db.deleteRow(session, app);
    return true;
  }

  /// Get application by ID
  Future<Application?> getApplicationById(Session session, int adminUserId, int applicationId) async {
    await _requireAdmin(session, adminUserId);
    return await Application.db.findById(session, applicationId);
  }

  /// Get application by app ID string
  Future<Application?> getApplicationByAppId(Session session, String appId) async {
    final apps = await Application.db.find(
      session,
      where: (a) => a.appId.equals(appId),
    );
    return apps.isEmpty ? null : apps.first;
  }

  /// Activate application (admin only)
  Future<bool> activateApplication(Session session, int adminUserId, int applicationId) async {
    await _requireAdmin(session, adminUserId);

    final app = await Application.db.findById(session, applicationId);
    if (app == null) return false;

    app.isActive = true;
    app.updatedAt = DateTime.now();
    await Application.db.updateRow(session, app);
    return true;
  }

  /// Deactivate application (admin only)
  Future<bool> deactivateApplication(Session session, int adminUserId, int applicationId) async {
    await _requireAdmin(session, adminUserId);

    final app = await Application.db.findById(session, applicationId);
    if (app == null) return false;

    app.isActive = false;
    app.updatedAt = DateTime.now();
    await Application.db.updateRow(session, app);
    return true;
  }

  // === Helper Methods ===

  Future<void> _requireAdmin(Session session, int userId) async {
    final user = await User.db.findById(session, userId);
    if (user == null) {
      throw AuthenticationException();
    }
    if (!user.isAdmin) {
      throw PermissionDeniedException('Admin access required');
    }
  }
}