import 'package:flutter/foundation.dart';

import '../providers/auth_state_provider.dart';
import 'app_router.dart';

@immutable
class RouteGuardDecision {
  final String? redirectLocation;

  const RouteGuardDecision.allow() : redirectLocation = null;

  const RouteGuardDecision.redirect(String location)
      : redirectLocation = location;

  bool get shouldRedirect => redirectLocation != null;
}

class RouteCapabilityPolicy {
  const RouteCapabilityPolicy();

  RouteGuardDecision evaluate({
    required String path,
    required Map<String, String> queryParameters,
    required AuthState authState,
  }) {
    final authMode = queryParameters['mode'];
    final allowsAuthenticatedAccess =
        authMode == 'addAccount' || authMode == 'reauthenticate';

    if (_isProfileRoute(path) && !authState.isAuthenticated) {
      return const RouteGuardDecision.redirect(AppRoutes.login);
    }

    if (_isTeamRoute(path) && !authState.isAuthenticated) {
      return const RouteGuardDecision.redirect(AppRoutes.login);
    }

    if (_isLoginRoute(path) && authState.isAuthenticated && !allowsAuthenticatedAccess) {
      return const RouteGuardDecision.redirect(AppRoutes.settings);
    }

    return const RouteGuardDecision.allow();
  }

  bool _isProfileRoute(String path) => path == AppRoutes.profile;

  bool _isTeamRoute(String path) => path == AppRoutes.team;

  bool _isLoginRoute(String path) => path == AppRoutes.login;
}
