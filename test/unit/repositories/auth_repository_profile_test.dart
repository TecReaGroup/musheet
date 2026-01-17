/// AuthRepository Profile Tests
///
/// Tests to verify that user profile fields (especially preferredInstrument)
/// are correctly synced during login and registration.
///
/// Bug Description (FIXED):
/// - Before fix: login() and register() methods did not include preferredInstrument
///   when creating UserProfile from server response
/// - After fix: All user profile fields are correctly mapped
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepository - PreferredInstrument Sync', () {
    late String authRepoSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authRepoSource = File(
        '$projectRoot/lib/core/repositories/auth_repository.dart',
      ).readAsStringSync();
    });

    test(
        'FIX VERIFICATION: login() should include preferredInstrument in UserProfile',
        () {
      // The login() method should map preferredInstrument from server response
      // to the UserProfile

      // Find the login method section
      final loginStart = authRepoSource.indexOf('Future<AuthResult> login(');
      expect(loginStart, greaterThan(-1), reason: 'login() method should exist');

      // Find the next method after login (logout)
      final logoutStart = authRepoSource.indexOf('Future<void> logout()');
      expect(logoutStart, greaterThan(loginStart), reason: 'logout() should come after login()');

      // Extract the login method body
      final loginMethodBody = authRepoSource.substring(loginStart, logoutStart);

      expect(
        loginMethodBody.contains('preferredInstrument: authResult.user!.preferredInstrument'),
        isTrue,
        reason:
            'FIXED: login() should map preferredInstrument from server response',
      );

      expect(
        loginMethodBody.contains('bio: authResult.user!.bio'),
        isTrue,
        reason: 'FIXED: login() should map bio from server response',
      );
    });

    test(
        'FIX VERIFICATION: register() should include preferredInstrument in UserProfile',
        () {
      // Find the register method section
      final registerStart = authRepoSource.indexOf('Future<AuthResult> register(');
      expect(registerStart, greaterThan(-1), reason: 'register() method should exist');

      // Find the login method (comes after register)
      final loginStart = authRepoSource.indexOf('Future<AuthResult> login(');
      expect(loginStart, greaterThan(registerStart), reason: 'login() should come after register()');

      // Extract the register method body
      final registerMethodBody = authRepoSource.substring(registerStart, loginStart);

      expect(
        registerMethodBody.contains('preferredInstrument: authResult.user!.preferredInstrument'),
        isTrue,
        reason:
            'FIXED: register() should map preferredInstrument from server response',
      );

      expect(
        registerMethodBody.contains('bio: authResult.user!.bio'),
        isTrue,
        reason: 'FIXED: register() should map bio from server response',
      );
    });

    test('All UserProfile fields should be mapped consistently in all auth methods', () {
      // Count occurrences of UserProfile creation patterns
      // login(), register(), and fetchProfile() should all map the same fields

      // Check that preferredInstrument appears in all methods
      final preferredInstrumentCount =
          'preferredInstrument:'.allMatches(authRepoSource).length;

      // Should appear at least 4 times: login, register, fetchProfile, updateProfile
      expect(
        preferredInstrumentCount,
        greaterThanOrEqualTo(4),
        reason:
            'preferredInstrument should be mapped in login(), register(), fetchProfile(), and updateProfile()',
      );

      final bioCount = 'bio:'.allMatches(authRepoSource).length;

      // bio should also appear at least 4 times
      expect(
        bioCount,
        greaterThanOrEqualTo(4),
        reason:
            'bio should be mapped in login(), register(), fetchProfile(), and updateProfile()',
      );
    });

    test('BUG DETECTION: Would have failed before the fix', () {
      // This test documents what the bug was:
      // Before the fix, the login() method would create UserProfile like:
      //
      // final user = UserProfile(
      //   id: authResult.user!.id!,
      //   username: authResult.user!.username,
      //   displayName: authResult.user!.displayName,
      //   avatarUrl: authResult.user!.avatarPath,
      //   createdAt: authResult.user!.createdAt,
      //   // MISSING: preferredInstrument  <-- THIS WAS THE BUG
      //   // MISSING: bio                   <-- THIS WAS ALSO MISSING
      // );
      //
      // After the fix, both fields are correctly mapped:
      //   preferredInstrument: authResult.user!.preferredInstrument,
      //   bio: authResult.user!.bio,

      // Verify the fix is in place
      expect(
        authRepoSource.contains('authResult.user!.preferredInstrument'),
        isTrue,
        reason: 'Fix should map preferredInstrument from authResult',
      );
    });
  });
}
