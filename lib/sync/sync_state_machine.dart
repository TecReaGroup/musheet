/// Sync State Machine
/// Defines explicit sync states, transitions, and guards
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

// ============================================================================
// Sync State Definitions
// ============================================================================

/// Primary sync states
enum SyncStateType {
  /// No sync activity, ready for sync
  idle,

  /// Sync is in progress
  syncing,

  /// Waiting for network connectivity
  waitingForNetwork,

  /// Conflicts detected requiring resolution
  conflicted,

  /// Error occurred, will retry
  error,

  /// Paused by user
  paused,
}

/// Sub-states for syncing state
enum SyncingPhase {
  /// Initializing sync
  initializing,

  /// Pushing local changes
  pushing,

  /// Pulling remote changes
  pulling,

  /// Merging data
  merging,

  /// Syncing files (PDFs)
  syncingFiles,

  /// Finalizing sync
  finalizing,
}

/// Sync events that trigger state transitions
enum SyncEvent {
  /// User requested sync
  syncRequested,

  /// Network became available
  networkAvailable,

  /// Network became unavailable
  networkLost,

  /// Push phase completed
  pushCompleted,

  /// Pull phase completed
  pullCompleted,

  /// Conflict detected
  conflictDetected,

  /// Conflict resolved
  conflictResolved,

  /// Error occurred
  errorOccurred,

  /// Retry timer triggered
  retryTriggered,

  /// Sync completed successfully
  syncCompleted,

  /// User paused sync
  pauseRequested,

  /// User resumed sync
  resumeRequested,

  /// Cancel sync
  cancelRequested,
}

// ============================================================================
// Sync State
// ============================================================================

/// Immutable sync state with metadata
@immutable
class SyncState {
  final SyncStateType type;
  final SyncingPhase? phase;
  final int pendingOperations;
  final int completedOperations;
  final int totalOperations;
  final int conflictCount;
  final String? errorMessage;
  final int retryCount;
  final DateTime? lastSyncAt;
  final DateTime stateEnteredAt;

  const SyncState({
    required this.type,
    this.phase,
    this.pendingOperations = 0,
    this.completedOperations = 0,
    this.totalOperations = 0,
    this.conflictCount = 0,
    this.errorMessage,
    this.retryCount = 0,
    this.lastSyncAt,
    required this.stateEnteredAt,
  });

  /// Initial idle state
  factory SyncState.initial() => SyncState(
    type: SyncStateType.idle,
    stateEnteredAt: DateTime.now(),
  );

  SyncState copyWith({
    SyncStateType? type,
    SyncingPhase? phase,
    int? pendingOperations,
    int? completedOperations,
    int? totalOperations,
    int? conflictCount,
    String? errorMessage,
    int? retryCount,
    DateTime? lastSyncAt,
    DateTime? stateEnteredAt,
  }) => SyncState(
    type: type ?? this.type,
    phase: phase ?? this.phase,
    pendingOperations: pendingOperations ?? this.pendingOperations,
    completedOperations: completedOperations ?? this.completedOperations,
    totalOperations: totalOperations ?? this.totalOperations,
    conflictCount: conflictCount ?? this.conflictCount,
    errorMessage: errorMessage,
    retryCount: retryCount ?? this.retryCount,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    stateEnteredAt: stateEnteredAt ?? this.stateEnteredAt,
  );

  /// Progress percentage (0.0 - 1.0)
  double get progress {
    if (totalOperations == 0) return 0.0;
    return (completedOperations / totalOperations).clamp(0.0, 1.0);
  }

  /// Human-readable status message
  String get statusMessage {
    switch (type) {
      case SyncStateType.idle:
        if (lastSyncAt != null) {
          final ago = DateTime.now().difference(lastSyncAt!);
          if (ago.inMinutes < 1) return 'Synced just now';
          if (ago.inHours < 1) return 'Synced ${ago.inMinutes}m ago';
          if (ago.inDays < 1) return 'Synced ${ago.inHours}h ago';
          return 'Synced ${ago.inDays}d ago';
        }
        return pendingOperations > 0
          ? '$pendingOperations changes pending'
          : 'Up to date';

      case SyncStateType.syncing:
        switch (phase) {
          case SyncingPhase.initializing:
            return 'Preparing sync...';
          case SyncingPhase.pushing:
            return 'Uploading changes ($completedOperations/$totalOperations)...';
          case SyncingPhase.pulling:
            return 'Downloading updates...';
          case SyncingPhase.merging:
            return 'Merging data...';
          case SyncingPhase.syncingFiles:
            return 'Syncing files...';
          case SyncingPhase.finalizing:
            return 'Finishing up...';
          default:
            return 'Syncing...';
        }

      case SyncStateType.waitingForNetwork:
        return 'Waiting for network...';

      case SyncStateType.conflicted:
        return '$conflictCount conflicts need attention';

      case SyncStateType.error:
        return errorMessage ?? 'Sync error occurred';

      case SyncStateType.paused:
        return 'Sync paused';
    }
  }

  bool get isIdle => type == SyncStateType.idle;
  bool get isSyncing => type == SyncStateType.syncing;
  bool get hasConflicts => type == SyncStateType.conflicted;
  bool get hasError => type == SyncStateType.error;
  bool get isPaused => type == SyncStateType.paused;
  bool get isWaitingForNetwork => type == SyncStateType.waitingForNetwork;

  /// Can start new sync?
  bool get canStartSync => type == SyncStateType.idle || type == SyncStateType.error;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'phase': phase?.name,
    'pendingOperations': pendingOperations,
    'completedOperations': completedOperations,
    'totalOperations': totalOperations,
    'conflictCount': conflictCount,
    'errorMessage': errorMessage,
    'retryCount': retryCount,
    'lastSyncAt': lastSyncAt?.toIso8601String(),
    'stateEnteredAt': stateEnteredAt.toIso8601String(),
  };

  @override
  String toString() => 'SyncState(${type.name}${phase != null ? ':${phase!.name}' : ''})';
}

// ============================================================================
// State Machine
// ============================================================================

/// State machine for managing sync state transitions
class SyncStateMachine {
  SyncState _currentState = SyncState.initial();
  final _stateController = StreamController<SyncState>.broadcast();
  final List<SyncStateTransition> _transitionHistory = [];
  static const int _maxHistorySize = 100;

  /// Current state
  SyncState get currentState => _currentState;

  /// State change stream
  Stream<SyncState> get stateStream => _stateController.stream;

  /// Transition history for debugging
  List<SyncStateTransition> get transitionHistory => List.unmodifiable(_transitionHistory);

  /// Process an event and transition to new state
  SyncState processEvent(SyncEvent event, {Map<String, dynamic>? data}) {
    final previousState = _currentState;
    final newState = _calculateNextState(event, data);

    if (newState.type != previousState.type || newState.phase != previousState.phase) {
      _currentState = newState;
      _recordTransition(previousState, newState, event);
      _stateController.add(newState);

      if (kDebugMode) {
        debugPrint('[SyncStateMachine] $previousState -> $newState (event: ${event.name})');
      }
    }

    return _currentState;
  }

  /// Calculate next state based on current state and event
  SyncState _calculateNextState(SyncEvent event, Map<String, dynamic>? data) {
    final current = _currentState;

    switch (event) {
      case SyncEvent.syncRequested:
        if (current.canStartSync) {
          return current.copyWith(
            type: SyncStateType.syncing,
            phase: SyncingPhase.initializing,
            totalOperations: data?['totalOperations'] as int? ?? 0,
            completedOperations: 0,
            stateEnteredAt: DateTime.now(),
          );
        }
        return current;

      case SyncEvent.networkAvailable:
        if (current.isWaitingForNetwork) {
          return current.copyWith(
            type: SyncStateType.syncing,
            phase: SyncingPhase.initializing,
            stateEnteredAt: DateTime.now(),
          );
        }
        return current;

      case SyncEvent.networkLost:
        if (current.isSyncing) {
          return current.copyWith(
            type: SyncStateType.waitingForNetwork,
            stateEnteredAt: DateTime.now(),
          );
        }
        return current;

      case SyncEvent.pushCompleted:
        if (current.isSyncing && current.phase == SyncingPhase.pushing) {
          return current.copyWith(
            phase: SyncingPhase.pulling,
            completedOperations: data?['completedOperations'] as int?,
          );
        }
        return current;

      case SyncEvent.pullCompleted:
        if (current.isSyncing && current.phase == SyncingPhase.pulling) {
          return current.copyWith(
            phase: SyncingPhase.merging,
          );
        }
        return current;

      case SyncEvent.conflictDetected:
        return current.copyWith(
          type: SyncStateType.conflicted,
          conflictCount: data?['conflictCount'] as int? ?? 1,
          stateEnteredAt: DateTime.now(),
        );

      case SyncEvent.conflictResolved:
        final remaining = (current.conflictCount - 1).clamp(0, current.conflictCount);
        if (remaining == 0) {
          return current.copyWith(
            type: SyncStateType.syncing,
            phase: SyncingPhase.finalizing,
            conflictCount: 0,
            stateEnteredAt: DateTime.now(),
          );
        }
        return current.copyWith(conflictCount: remaining);

      case SyncEvent.errorOccurred:
        return current.copyWith(
          type: SyncStateType.error,
          errorMessage: data?['errorMessage'] as String?,
          retryCount: current.retryCount + 1,
          stateEnteredAt: DateTime.now(),
        );

      case SyncEvent.retryTriggered:
        if (current.hasError) {
          return current.copyWith(
            type: SyncStateType.syncing,
            phase: SyncingPhase.initializing,
            stateEnteredAt: DateTime.now(),
          );
        }
        return current;

      case SyncEvent.syncCompleted:
        return current.copyWith(
          type: SyncStateType.idle,
          phase: null,
          pendingOperations: 0,
          completedOperations: current.totalOperations,
          conflictCount: 0,
          retryCount: 0,
          lastSyncAt: DateTime.now(),
          stateEnteredAt: DateTime.now(),
        );

      case SyncEvent.pauseRequested:
        if (current.isSyncing) {
          return current.copyWith(
            type: SyncStateType.paused,
            stateEnteredAt: DateTime.now(),
          );
        }
        return current;

      case SyncEvent.resumeRequested:
        if (current.isPaused) {
          return current.copyWith(
            type: SyncStateType.syncing,
            stateEnteredAt: DateTime.now(),
          );
        }
        return current;

      case SyncEvent.cancelRequested:
        return current.copyWith(
          type: SyncStateType.idle,
          phase: null,
          stateEnteredAt: DateTime.now(),
        );
    }
  }

  /// Update phase within syncing state
  void updatePhase(SyncingPhase phase, {int? completedOperations, int? totalOperations}) {
    if (_currentState.isSyncing) {
      _currentState = _currentState.copyWith(
        phase: phase,
        completedOperations: completedOperations,
        totalOperations: totalOperations,
      );
      _stateController.add(_currentState);
    }
  }

  /// Update pending operations count
  void updatePendingOperations(int count) {
    _currentState = _currentState.copyWith(pendingOperations: count);
    _stateController.add(_currentState);
  }

  /// Increment completed operations
  void incrementCompleted() {
    _currentState = _currentState.copyWith(
      completedOperations: _currentState.completedOperations + 1,
    );
    _stateController.add(_currentState);
  }

  /// Record transition for history
  void _recordTransition(SyncState from, SyncState to, SyncEvent event) {
    _transitionHistory.add(SyncStateTransition(
      fromState: from,
      toState: to,
      event: event,
      timestamp: DateTime.now(),
    ));

    // Trim history if too large
    while (_transitionHistory.length > _maxHistorySize) {
      _transitionHistory.removeAt(0);
    }
  }

  /// Reset to initial state
  void reset() {
    _currentState = SyncState.initial();
    _stateController.add(_currentState);
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}

/// Record of a state transition
@immutable
class SyncStateTransition {
  final SyncState fromState;
  final SyncState toState;
  final SyncEvent event;
  final DateTime timestamp;

  const SyncStateTransition({
    required this.fromState,
    required this.toState,
    required this.event,
    required this.timestamp,
  });

  @override
  String toString() => '${fromState.type.name} -> ${toState.type.name} (${event.name})';
}
