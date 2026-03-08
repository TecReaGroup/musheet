library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('login submit regression', () {
    late String loginScreenSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      loginScreenSource = File(
        '$projectRoot/lib/screens/settings/login_screen.dart',
      ).readAsStringSync();
    });

    test('successful login flow must not trigger a second sync from login screen', () {
      expect(
        loginScreenSource.contains('authFlowCoordinatorProvider'),
        isTrue,
        reason:
            'Login screen should delegate authentication flow to the auth flow '
            'coordinator instead of talking to auth state directly.',
      );

      final submitStart = loginScreenSource.indexOf('Future<void> _handleSubmit() async {');
      final buildStart = loginScreenSource.indexOf('@override', submitStart);
      final submitBody = loginScreenSource.substring(submitStart, buildStart);

      expect(
        submitBody.contains('.login(') || submitBody.contains('.register('),
        isTrue,
        reason: 'Login screen submit handler should perform authentication.',
      );

      expect(
        submitBody.contains('syncCoordinator.syncNow()'),
        isFalse,
        reason:
            'BUG DETECTED: LoginScreen triggers syncCoordinator.syncNow() after '
            'successful login even though AuthStateNotifier.login()/register() '
            'already initializes sync and requests an immediate sync. This '
            'duplicates heavy startup work during route/provider switching and '
            'contributes to the post-login freeze.',
      );
    });
  });
}
