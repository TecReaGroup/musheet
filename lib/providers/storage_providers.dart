import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../services/file_storage_service.dart';

/// Provider for the AppDatabase instance
/// This is a singleton that persists throughout the app lifecycle
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

/// Provider for the DatabaseService
/// Provides CRUD operations for all entities
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return DatabaseService(database);
});

/// Provider for the FileStorageService
/// Handles PDF file storage and management
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

/// FutureProvider for PreferencesService (requires async initialization)
final preferencesServiceProvider = FutureProvider<PreferencesService>((ref) async {
  return PreferencesService.create();
});

/// Provider for accessing PreferencesService synchronously after initialization
/// Use this after the app has finished initializing
final preferencesProvider = Provider<PreferencesService?>((ref) {
  final asyncValue = ref.watch(preferencesServiceProvider);
  return asyncValue.when(
    data: (prefs) => prefs,
    loading: () => null,
    error: (e, s) => null,
  );
});

// ============== App State Notifiers ==============

/// Notifier for the last opened score ID
class LastOpenedScoreIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getLastOpenedScoreId();
  }

  void set(String? scoreId) {
    state = scoreId;
    final prefs = ref.read(preferencesProvider);
    prefs?.setLastOpenedScoreId(scoreId);
  }
}

final lastOpenedScoreIdProvider = NotifierProvider<LastOpenedScoreIdNotifier, String?>(() {
  return LastOpenedScoreIdNotifier();
});

/// Notifier for the last opened instrument ID
class LastOpenedInstrumentIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getLastOpenedInstrumentId();
  }

  void set(String? instrumentId) {
    state = instrumentId;
    final prefs = ref.read(preferencesProvider);
    prefs?.setLastOpenedInstrumentId(instrumentId);
  }
}

final lastOpenedInstrumentIdProvider = NotifierProvider<LastOpenedInstrumentIdNotifier, String?>(() {
  return LastOpenedInstrumentIdNotifier();
});

/// Notifier for the theme mode
class ThemeModeNotifier extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getThemeMode() ?? AppThemeMode.system;
  }

  void set(AppThemeMode mode) {
    state = mode;
    final prefs = ref.read(preferencesProvider);
    prefs?.setThemeMode(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(() {
  return ThemeModeNotifier();
});

/// Notifier for the default BPM
class DefaultBpmNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getDefaultBpm() ?? 120;
  }

  void set(int bpm) {
    state = bpm;
    final prefs = ref.read(preferencesProvider);
    prefs?.setDefaultBpm(bpm);
  }
}

final defaultBpmProvider = NotifierProvider<DefaultBpmNotifier, int>(() {
  return DefaultBpmNotifier();
});

/// Notifier for keep screen awake setting
class KeepScreenAwakeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs?.isKeepScreenAwakeEnabled() ?? true;
  }

  void set(bool enabled) {
    state = enabled;
    final prefs = ref.read(preferencesProvider);
    prefs?.setKeepScreenAwakeEnabled(enabled);
  }
}

final keepScreenAwakeProvider = NotifierProvider<KeepScreenAwakeNotifier, bool>(() {
  return KeepScreenAwakeNotifier();
});

/// Notifier for metronome sound enabled setting
class MetronomeSoundEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs?.isMetronomeSoundEnabled() ?? true;
  }

  void set(bool enabled) {
    state = enabled;
    final prefs = ref.read(preferencesProvider);
    prefs?.setMetronomeSoundEnabled(enabled);
  }
}

final metronomeSoundEnabledProvider = NotifierProvider<MetronomeSoundEnabledNotifier, bool>(() {
  return MetronomeSoundEnabledNotifier();
});

/// Notifier for onboarding completed status
class OnboardingCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs?.isOnboardingCompleted() ?? false;
  }

  void set(bool completed) {
    state = completed;
    final prefs = ref.read(preferencesProvider);
    prefs?.setOnboardingCompleted(completed);
  }
}

final onboardingCompletedProvider = NotifierProvider<OnboardingCompletedNotifier, bool>(() {
  return OnboardingCompletedNotifier();
});

/// Notifier for user name
class UserNameNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getUserName();
  }

  void set(String? name) {
    state = name;
    final prefs = ref.read(preferencesProvider);
    prefs?.setUserName(name);
  }
}

final userNameProvider = NotifierProvider<UserNameNotifier, String?>(() {
  return UserNameNotifier();
});

/// Notifier for default instrument
class DefaultInstrumentNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getDefaultInstrument();
  }

  void set(String? instrument) {
    state = instrument;
    final prefs = ref.read(preferencesProvider);
    prefs?.setDefaultInstrument(instrument);
  }
}

final defaultInstrumentProvider = NotifierProvider<DefaultInstrumentNotifier, String?>(() {
  return DefaultInstrumentNotifier();
});

// ============== Storage Stats Providers ==============

/// Provider for total storage used by PDFs
final totalStorageUsedProvider = FutureProvider<int>((ref) async {
  final fileService = ref.watch(fileStorageServiceProvider);
  return fileService.getTotalStorageUsed();
});

/// Provider for storage used by a specific score
final scoreStorageUsedProvider = FutureProvider.family<int, String>((ref, scoreId) async {
  final fileService = ref.watch(fileStorageServiceProvider);
  return fileService.getScoreStorageUsed(scoreId);
});

// ============== Initialization Provider ==============

/// Provider that initializes all storage services
/// Call this at app startup to ensure all services are ready
final storageInitializerProvider = FutureProvider<void>((ref) async {
  // Initialize database (reading the provider ensures it's created)
  ref.read(appDatabaseProvider);
  
  // Initialize file storage directories
  final fileService = ref.read(fileStorageServiceProvider);
  await fileService.ensureDirectoriesExist();
  
  // Initialize preferences
  await ref.read(preferencesServiceProvider.future);
  
  // Force refresh the state providers after preferences are loaded
  ref.invalidate(lastOpenedScoreIdProvider);
  ref.invalidate(lastOpenedInstrumentIdProvider);
  ref.invalidate(themeModeProvider);
  ref.invalidate(defaultBpmProvider);
  ref.invalidate(keepScreenAwakeProvider);
  ref.invalidate(metronomeSoundEnabledProvider);
  ref.invalidate(onboardingCompletedProvider);
  ref.invalidate(userNameProvider);
  ref.invalidate(defaultInstrumentProvider);
  
  // Note: The following providers from library_screen.dart are also persisted
  // and will be invalidated when they are first accessed after preferences load:
  // - recentlyOpenedSetlistsProvider
  // - recentlyOpenedScoresProvider
  // - lastOpenedScoreInSetlistProvider
  // - lastOpenedInstrumentInScoreProvider
  // - preferredInstrumentProvider
  // - teamEnabledProvider
});

// ============== Helper Extensions ==============

/// Extension methods for saving preferences using the notifier's set method
extension PreferencesSaver on WidgetRef {
  /// Save the last opened score ID
  void saveLastOpenedScoreId(String? scoreId) {
    read(lastOpenedScoreIdProvider.notifier).set(scoreId);
  }

  /// Save the last opened instrument ID
  void saveLastOpenedInstrumentId(String? instrumentId) {
    read(lastOpenedInstrumentIdProvider.notifier).set(instrumentId);
  }

  /// Save the theme mode
  void saveThemeMode(AppThemeMode mode) {
    read(themeModeProvider.notifier).set(mode);
  }

  /// Save the default BPM
  void saveDefaultBpm(int bpm) {
    read(defaultBpmProvider.notifier).set(bpm);
  }

  /// Save the keep screen awake setting
  void saveKeepScreenAwake(bool enabled) {
    read(keepScreenAwakeProvider.notifier).set(enabled);
  }

  /// Save the metronome sound enabled setting
  void saveMetronomeSoundEnabled(bool enabled) {
    read(metronomeSoundEnabledProvider.notifier).set(enabled);
  }

  /// Save the onboarding completed status
  void saveOnboardingCompleted(bool completed) {
    read(onboardingCompletedProvider.notifier).set(completed);
  }

  /// Save the user name
  void saveUserName(String? name) {
    read(userNameProvider.notifier).set(name);
  }

  /// Save the default instrument
  void saveDefaultInstrument(String? instrument) {
    read(defaultInstrumentProvider.notifier).set(instrument);
  }
}