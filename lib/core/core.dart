/// Core Module - Barrel Export
/// 
/// This module contains the core architecture components:
/// - Services: NetworkService, SessionService
/// - Data: ApiClient, LocalDataSource
/// - Repositories: AuthRepository, ScoreRepository, SetlistRepository, TeamRepository
/// - Sync: SyncCoordinator, TeamSyncManager
library;

export 'services/services.dart';
export 'data/data.dart';
export 'repositories/repositories.dart';
export 'sync/sync.dart';
