import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences storage
class PreferenceKeys {
  static const String themeMode = 'theme_mode';
  static const String userName = 'user_name';
  static const String authToken = 'auth_token';
  static const String defaultInstrument = 'default_instrument';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String metronomeSoundEnabled = 'metronome_sound_enabled';
  static const String lastOpenedScoreId = 'last_opened_score_id';
  static const String lastOpenedInstrumentId = 'last_opened_instrument_id';
  static const String defaultBpm = 'default_bpm';
  static const String keepScreenAwake = 'keep_screen_awake';
  static const String preferredInstrument = 'preferred_instrument';
  static const String teamEnabled = 'team_enabled';
  static const String recentlyOpenedScores = 'recently_opened_scores';
  static const String recentlyOpenedSetlists = 'recently_opened_setlists';
  static const String lastOpenedScoreInSetlist = 'last_opened_score_in_setlist';
  static const String lastOpenedInstrumentInScore = 'last_opened_instrument_in_score';
}

/// Theme mode options
enum AppThemeMode { light, dark, system }

/// Service for managing user preferences using SharedPreferences
/// Used for lightweight settings like theme, user name, auth tokens, etc.
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  /// Create instance asynchronously
  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // ============== Theme Mode ==============

  /// Get the current theme mode
  AppThemeMode getThemeMode() {
    final value = _prefs.getString(PreferenceKeys.themeMode);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  /// Set the theme mode
  Future<bool> setThemeMode(AppThemeMode mode) {
    return _prefs.setString(PreferenceKeys.themeMode, mode.name);
  }

  // ============== User Name ==============

  /// Get the user name
  String? getUserName() {
    return _prefs.getString(PreferenceKeys.userName);
  }

  /// Set the user name
  Future<bool> setUserName(String? name) {
    if (name == null) {
      return _prefs.remove(PreferenceKeys.userName);
    }
    return _prefs.setString(PreferenceKeys.userName, name);
  }

  // ============== Auth Token ==============

  /// Get the auth token
  String? getAuthToken() {
    return _prefs.getString(PreferenceKeys.authToken);
  }

  /// Set the auth token
  Future<bool> setAuthToken(String? token) {
    if (token == null) {
      return _prefs.remove(PreferenceKeys.authToken);
    }
    return _prefs.setString(PreferenceKeys.authToken, token);
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    final token = getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // ============== Default Instrument ==============

  /// Get the default instrument type
  String? getDefaultInstrument() {
    return _prefs.getString(PreferenceKeys.defaultInstrument);
  }

  /// Set the default instrument type
  Future<bool> setDefaultInstrument(String? instrument) {
    if (instrument == null) {
      return _prefs.remove(PreferenceKeys.defaultInstrument);
    }
    return _prefs.setString(PreferenceKeys.defaultInstrument, instrument);
  }

  // ============== Onboarding ==============

  /// Check if onboarding is completed
  bool isOnboardingCompleted() {
    return _prefs.getBool(PreferenceKeys.onboardingCompleted) ?? false;
  }

  /// Set onboarding completion status
  Future<bool> setOnboardingCompleted(bool completed) {
    return _prefs.setBool(PreferenceKeys.onboardingCompleted, completed);
  }

  // ============== Metronome Sound ==============

  /// Check if metronome sound is enabled
  bool isMetronomeSoundEnabled() {
    return _prefs.getBool(PreferenceKeys.metronomeSoundEnabled) ?? true;
  }

  /// Set metronome sound enabled status
  Future<bool> setMetronomeSoundEnabled(bool enabled) {
    return _prefs.setBool(PreferenceKeys.metronomeSoundEnabled, enabled);
  }

  // ============== Last Opened Score ==============

  /// Get the last opened score ID
  String? getLastOpenedScoreId() {
    return _prefs.getString(PreferenceKeys.lastOpenedScoreId);
  }

  /// Set the last opened score ID
  Future<bool> setLastOpenedScoreId(String? scoreId) {
    if (scoreId == null) {
      return _prefs.remove(PreferenceKeys.lastOpenedScoreId);
    }
    return _prefs.setString(PreferenceKeys.lastOpenedScoreId, scoreId);
  }

  // ============== Last Opened Instrument ==============

  /// Get the last opened instrument ID
  String? getLastOpenedInstrumentId() {
    return _prefs.getString(PreferenceKeys.lastOpenedInstrumentId);
  }

  /// Set the last opened instrument ID
  Future<bool> setLastOpenedInstrumentId(String? instrumentId) {
    if (instrumentId == null) {
      return _prefs.remove(PreferenceKeys.lastOpenedInstrumentId);
    }
    return _prefs.setString(PreferenceKeys.lastOpenedInstrumentId, instrumentId);
  }

  // ============== Default BPM ==============

  /// Get the default BPM
  int getDefaultBpm() {
    return _prefs.getInt(PreferenceKeys.defaultBpm) ?? 120;
  }

  /// Set the default BPM
  Future<bool> setDefaultBpm(int bpm) {
    return _prefs.setInt(PreferenceKeys.defaultBpm, bpm);
  }

  // ============== Keep Screen Awake ==============

  /// Check if keep screen awake is enabled
  bool isKeepScreenAwakeEnabled() {
    return _prefs.getBool(PreferenceKeys.keepScreenAwake) ?? true;
  }

  /// Set keep screen awake status
  Future<bool> setKeepScreenAwakeEnabled(bool enabled) {
    return _prefs.setBool(PreferenceKeys.keepScreenAwake, enabled);
  }

  // ============== Preferred Instrument ==============

  /// Get the user's preferred instrument type key
  String? getPreferredInstrument() {
    return _prefs.getString(PreferenceKeys.preferredInstrument);
  }

  /// Set the user's preferred instrument type key
  Future<bool> setPreferredInstrument(String? instrument) {
    if (instrument == null) {
      return _prefs.remove(PreferenceKeys.preferredInstrument);
    }
    return _prefs.setString(PreferenceKeys.preferredInstrument, instrument);
  }

  // ============== Team Feature ==============

  /// Check if team feature is enabled
  bool isTeamEnabled() {
    return _prefs.getBool(PreferenceKeys.teamEnabled) ?? true;
  }

  /// Set team feature enabled status
  Future<bool> setTeamEnabled(bool enabled) {
    return _prefs.setBool(PreferenceKeys.teamEnabled, enabled);
  }

  // ============== Recently Opened Records ==============

  /// Get the map of recently opened scores (scoreId -> DateTime as ISO string)
  Map<String, DateTime> getRecentlyOpenedScores() {
    final jsonStr = _prefs.getString(PreferenceKeys.recentlyOpenedScores);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return map.map((key, value) => MapEntry(key, DateTime.parse(value as String)));
    } catch (_) {
      return {};
    }
  }

  /// Set the map of recently opened scores
  Future<bool> setRecentlyOpenedScores(Map<String, DateTime> scores) {
    final map = scores.map((key, value) => MapEntry(key, value.toIso8601String()));
    return _prefs.setString(PreferenceKeys.recentlyOpenedScores, jsonEncode(map));
  }

  /// Get the map of recently opened setlists
  Map<String, DateTime> getRecentlyOpenedSetlists() {
    final jsonStr = _prefs.getString(PreferenceKeys.recentlyOpenedSetlists);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return map.map((key, value) => MapEntry(key, DateTime.parse(value as String)));
    } catch (_) {
      return {};
    }
  }

  /// Set the map of recently opened setlists
  Future<bool> setRecentlyOpenedSetlists(Map<String, DateTime> setlists) {
    final map = setlists.map((key, value) => MapEntry(key, value.toIso8601String()));
    return _prefs.setString(PreferenceKeys.recentlyOpenedSetlists, jsonEncode(map));
  }

  // ============== Last Opened Score in Setlist ==============

  /// Get the map of last opened score index per setlist
  Map<String, int> getLastOpenedScoreInSetlist() {
    final jsonStr = _prefs.getString(PreferenceKeys.lastOpenedScoreInSetlist);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return map.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      return {};
    }
  }

  /// Set the map of last opened score index per setlist
  Future<bool> setLastOpenedScoreInSetlist(Map<String, int> data) {
    return _prefs.setString(PreferenceKeys.lastOpenedScoreInSetlist, jsonEncode(data));
  }

  // ============== Last Opened Instrument in Score ==============

  /// Get the map of last opened instrument index per score
  Map<String, int> getLastOpenedInstrumentInScore() {
    final jsonStr = _prefs.getString(PreferenceKeys.lastOpenedInstrumentInScore);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return map.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      return {};
    }
  }

  /// Set the map of last opened instrument index per score
  Future<bool> setLastOpenedInstrumentInScore(Map<String, int> data) {
    return _prefs.setString(PreferenceKeys.lastOpenedInstrumentInScore, jsonEncode(data));
  }

  // ============== Clear All ==============

  /// Clear all preferences (useful for logout/reset)
  Future<bool> clearAll() {
    return _prefs.clear();
  }

  /// Clear auth-related preferences
  Future<void> clearAuth() async {
    await _prefs.remove(PreferenceKeys.authToken);
    await _prefs.remove(PreferenceKeys.userName);
  }
}