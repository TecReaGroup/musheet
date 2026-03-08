library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AppIdentityContext {
  final String? accountKey;

  const AppIdentityContext._({this.accountKey});

  const AppIdentityContext.local() : this._();

  const AppIdentityContext.account(String accountKey)
      : this._(accountKey: accountKey);

  bool get isLocal => accountKey == null;
  bool get isAccount => accountKey != null;

  Map<String, dynamic> toJson() => {
    'type': isLocal ? 'local' : 'account',
    'accountKey': accountKey,
  };

  factory AppIdentityContext.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'local';
    if (type == 'account') {
      final key = json['accountKey'] as String?;
      if (key != null && key.isNotEmpty) {
        return AppIdentityContext.account(key);
      }
    }
    return const AppIdentityContext.local();
  }

  @override
  bool operator ==(Object other) {
    return other is AppIdentityContext && other.accountKey == accountKey;
  }

  @override
  int get hashCode => accountKey.hashCode;
}

@immutable
class SavedAccount {
  final String accountKey;
  final String serverUrl;
  final int userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? refreshToken;
  final DateTime? lastAuthenticatedAt;
  final DateTime? lastActivatedAt;
  final bool reauthRequired;

  const SavedAccount({
    required this.accountKey,
    required this.serverUrl,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.refreshToken,
    this.lastAuthenticatedAt,
    this.lastActivatedAt,
    this.reauthRequired = false,
  });

  String get effectiveDisplayName =>
      displayName != null && displayName!.trim().isNotEmpty
          ? displayName!.trim()
          : username;

  bool get hasRefreshToken =>
      refreshToken != null && refreshToken!.trim().isNotEmpty;

  SavedAccount copyWith({
    String? accountKey,
    String? serverUrl,
    int? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? refreshToken,
    DateTime? lastAuthenticatedAt,
    DateTime? lastActivatedAt,
    bool? reauthRequired,
    bool clearDisplayName = false,
    bool clearAvatarUrl = false,
    bool clearRefreshToken = false,
  }) => SavedAccount(
    accountKey: accountKey ?? this.accountKey,
    serverUrl: serverUrl ?? this.serverUrl,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    displayName: clearDisplayName ? null : (displayName ?? this.displayName),
    avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
    refreshToken: clearRefreshToken ? null : (refreshToken ?? this.refreshToken),
    lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
    lastActivatedAt: lastActivatedAt ?? this.lastActivatedAt,
    reauthRequired: reauthRequired ?? this.reauthRequired,
  );

  Map<String, dynamic> toJson() => {
    'accountKey': accountKey,
    'serverUrl': serverUrl,
    'userId': userId,
    'username': username,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'refreshToken': refreshToken,
    'lastAuthenticatedAt': lastAuthenticatedAt?.toIso8601String(),
    'lastActivatedAt': lastActivatedAt?.toIso8601String(),
    'reauthRequired': reauthRequired,
  };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
    accountKey: json['accountKey'] as String,
    serverUrl: json['serverUrl'] as String,
    userId: json['userId'] as int,
    username: json['username'] as String,
    displayName: json['displayName'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    refreshToken: json['refreshToken'] as String?,
    lastAuthenticatedAt: _parseDateTime(json['lastAuthenticatedAt'] as String?),
    lastActivatedAt: _parseDateTime(json['lastActivatedAt'] as String?),
    reauthRequired: json['reauthRequired'] as bool? ?? false,
  );

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

@immutable
class AccountRegistryState {
  final List<SavedAccount> savedAccounts;
  final AppIdentityContext activeContext;

  const AccountRegistryState({
    required this.savedAccounts,
    required this.activeContext,
  });

  const AccountRegistryState.initial()
      : savedAccounts = const [],
        activeContext = const AppIdentityContext.local();

  AccountRegistryState copyWith({
    List<SavedAccount>? savedAccounts,
    AppIdentityContext? activeContext,
  }) => AccountRegistryState(
    savedAccounts: savedAccounts ?? this.savedAccounts,
    activeContext: activeContext ?? this.activeContext,
  );

  SavedAccount? get activeAccount {
    final key = activeContext.accountKey;
    if (key == null) return null;
    for (final account in savedAccounts) {
      if (account.accountKey == key) return account;
    }
    return null;
  }
}

class _RegistryKeys {
  static const String savedAccounts = 'saved_accounts_registry_v1';
  static const String activeContext = 'active_identity_context_v1';
}

class AccountRegistryService {
  static AccountRegistryService? _instance;

  final SharedPreferences _prefs;
  final StreamController<AccountRegistryState> _stateController =
      StreamController<AccountRegistryState>.broadcast();

  AccountRegistryState _state = const AccountRegistryState.initial();

  AccountRegistryService._(this._prefs);

  static Future<AccountRegistryService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = AccountRegistryService._(prefs);
    await _instance!._init();
    return _instance!;
  }

  static AccountRegistryService get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'AccountRegistryService not initialized. Call initialize() first.',
      );
    }
    return instance;
  }

  static bool get isInitialized => _instance != null;

  Stream<AccountRegistryState> get stateStream => _stateController.stream;

  AccountRegistryState get state => _state;

  List<SavedAccount> get savedAccounts => _state.savedAccounts;

  AppIdentityContext get activeContext => _state.activeContext;

  SavedAccount? get activeAccount => _state.activeAccount;

  Future<void> _init() async {
    final accountsJson = _prefs.getString(_RegistryKeys.savedAccounts);
    final activeContextJson = _prefs.getString(_RegistryKeys.activeContext);

    final accounts = <SavedAccount>[];
    if (accountsJson != null && accountsJson.isNotEmpty) {
      final decoded = jsonDecode(accountsJson);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            accounts.add(
              SavedAccount.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
    }

    AppIdentityContext activeContext = const AppIdentityContext.local();
    if (activeContextJson != null && activeContextJson.isNotEmpty) {
      final decoded = jsonDecode(activeContextJson);
      if (decoded is Map) {
        activeContext = AppIdentityContext.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    }

    if (activeContext.isAccount &&
        !accounts.any((a) => a.accountKey == activeContext.accountKey)) {
      activeContext = const AppIdentityContext.local();
    }

    _updateState(
      AccountRegistryState(
        savedAccounts: List.unmodifiable(accounts),
        activeContext: activeContext,
      ),
      persist: false,
    );
  }

  Future<void> saveAccount(SavedAccount account, {bool makeActive = false}) async {
    final accounts = [..._state.savedAccounts];
    final index = accounts.indexWhere((item) => item.accountKey == account.accountKey);
    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }

    final nextContext = makeActive
        ? AppIdentityContext.account(account.accountKey)
        : _state.activeContext;

    await _updateState(
      _state.copyWith(
        savedAccounts: List.unmodifiable(accounts),
        activeContext: nextContext,
      ),
    );
  }

  Future<void> removeAccount(String accountKey) async {
    final accounts = _state.savedAccounts
        .where((item) => item.accountKey != accountKey)
        .toList(growable: false);

    final nextContext = _state.activeContext.accountKey == accountKey
        ? const AppIdentityContext.local()
        : _state.activeContext;

    await _updateState(
      _state.copyWith(
        savedAccounts: List.unmodifiable(accounts),
        activeContext: nextContext,
      ),
    );
  }

  Future<void> setActiveContext(AppIdentityContext context) async {
    if (context.isAccount &&
        !_state.savedAccounts.any((a) => a.accountKey == context.accountKey)) {
      throw StateError('Cannot activate unknown account: ${context.accountKey}');
    }

    await _updateState(_state.copyWith(activeContext: context));
  }

  Future<void> markAccountReauthRequired(
    String accountKey, {
    required bool reauthRequired,
  }) async {
    final accounts = _state.savedAccounts.map((account) {
      if (account.accountKey != accountKey) return account;
      return account.copyWith(reauthRequired: reauthRequired);
    }).toList(growable: false);

    await _updateState(_state.copyWith(savedAccounts: List.unmodifiable(accounts)));
  }

  Future<void> updateLastActivated(String accountKey) async {
    final now = DateTime.now();
    final accounts = _state.savedAccounts.map((account) {
      if (account.accountKey != accountKey) return account;
      return account.copyWith(lastActivatedAt: now);
    }).toList(growable: false);

    await _updateState(_state.copyWith(savedAccounts: List.unmodifiable(accounts)));
  }

  String buildAccountKey({required String serverUrl, required int userId}) {
    final normalizedServer = serverUrl.trim().toLowerCase();
    final raw = '$normalizedServer:$userId';
    return raw.hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  }

  Future<void> _updateState(
    AccountRegistryState nextState, {
    bool persist = true,
  }) async {
    _state = nextState;

    if (persist) {
      await _prefs.setString(
        _RegistryKeys.savedAccounts,
        jsonEncode(_state.savedAccounts.map((a) => a.toJson()).toList()),
      );
      await _prefs.setString(
        _RegistryKeys.activeContext,
        jsonEncode(_state.activeContext.toJson()),
      );
    }

    _stateController.add(_state);
  }
}
