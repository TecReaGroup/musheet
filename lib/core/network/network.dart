/// Network Module - Barrel Export
///
/// This module contains the network layer components:
/// - ConnectionManager: Service availability state machine
/// - NetworkError: Unified error types
/// - TokenRefresher: Concurrent-safe token refresh
library;

export 'connection_manager.dart';
export 'errors.dart';
export 'token_refresher.dart';
