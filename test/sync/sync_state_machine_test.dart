import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/sync/sync_state_machine.dart';

void main() {
  group('SyncState', () {
    test('initial state is idle', () {
      final state = SyncState.initial();
      expect(state.type, SyncStateType.idle);
      expect(state.phase, isNull);
      expect(state.isIdle, isTrue);
    });

    test('progress calculation', () {
      final state = SyncState(
        type: SyncStateType.syncing,
        phase: SyncingPhase.pushing,
        completedOperations: 5,
        totalOperations: 10,
        stateEnteredAt: DateTime.now(),
      );

      expect(state.progress, 0.5);
    });

    test('progress is zero when no operations', () {
      final state = SyncState(
        type: SyncStateType.idle,
        stateEnteredAt: DateTime.now(),
      );

      expect(state.progress, 0.0);
    });

    test('status message for idle state', () {
      final state = SyncState(
        type: SyncStateType.idle,
        pendingOperations: 3,
        stateEnteredAt: DateTime.now(),
      );

      expect(state.statusMessage, contains('3 changes pending'));
    });

    test('status message for syncing state', () {
      final state = SyncState(
        type: SyncStateType.syncing,
        phase: SyncingPhase.pushing,
        completedOperations: 5,
        totalOperations: 10,
        stateEnteredAt: DateTime.now(),
      );

      expect(state.statusMessage, contains('Uploading'));
      expect(state.statusMessage, contains('5/10'));
    });

    test('status message for error state', () {
      final state = SyncState(
        type: SyncStateType.error,
        errorMessage: 'Network failed',
        stateEnteredAt: DateTime.now(),
      );

      expect(state.statusMessage, 'Network failed');
    });

    test('canStartSync is true for idle', () {
      final state = SyncState(
        type: SyncStateType.idle,
        stateEnteredAt: DateTime.now(),
      );

      expect(state.canStartSync, isTrue);
    });

    test('canStartSync is true for error', () {
      final state = SyncState(
        type: SyncStateType.error,
        stateEnteredAt: DateTime.now(),
      );

      expect(state.canStartSync, isTrue);
    });

    test('canStartSync is false for syncing', () {
      final state = SyncState(
        type: SyncStateType.syncing,
        stateEnteredAt: DateTime.now(),
      );

      expect(state.canStartSync, isFalse);
    });

    test('toJson includes all fields', () {
      final now = DateTime.now();
      final state = SyncState(
        type: SyncStateType.syncing,
        phase: SyncingPhase.pulling,
        pendingOperations: 5,
        completedOperations: 3,
        totalOperations: 10,
        conflictCount: 1,
        retryCount: 2,
        stateEnteredAt: now,
      );

      final json = state.toJson();
      expect(json['type'], 'syncing');
      expect(json['phase'], 'pulling');
      expect(json['pendingOperations'], 5);
      expect(json['completedOperations'], 3);
      expect(json['totalOperations'], 10);
      expect(json['conflictCount'], 1);
      expect(json['retryCount'], 2);
    });
  });

  group('SyncStateMachine', () {
    late SyncStateMachine machine;

    setUp(() {
      machine = SyncStateMachine();
    });

    tearDown(() {
      machine.dispose();
    });

    test('starts in idle state', () {
      expect(machine.currentState.type, SyncStateType.idle);
    });

    test('transitions to syncing on syncRequested', () {
      machine.processEvent(SyncEvent.syncRequested);
      expect(machine.currentState.type, SyncStateType.syncing);
      expect(machine.currentState.phase, SyncingPhase.initializing);
    });

    test('transitions through push/pull phases', () {
      machine.processEvent(SyncEvent.syncRequested);
      expect(machine.currentState.phase, SyncingPhase.initializing);

      machine.updatePhase(SyncingPhase.pushing);
      expect(machine.currentState.phase, SyncingPhase.pushing);

      machine.processEvent(SyncEvent.pushCompleted);
      expect(machine.currentState.phase, SyncingPhase.pulling);

      machine.processEvent(SyncEvent.pullCompleted);
      expect(machine.currentState.phase, SyncingPhase.merging);
    });

    test('transitions to idle on syncCompleted', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.syncCompleted);

      expect(machine.currentState.type, SyncStateType.idle);
      expect(machine.currentState.lastSyncAt, isNotNull);
    });

    test('transitions to error on errorOccurred', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.errorOccurred, data: {
        'errorMessage': 'Network error',
      });

      expect(machine.currentState.type, SyncStateType.error);
      expect(machine.currentState.errorMessage, 'Network error');
      expect(machine.currentState.retryCount, 1);
    });

    test('transitions from error to syncing on retryTriggered', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.errorOccurred);
      machine.processEvent(SyncEvent.retryTriggered);

      expect(machine.currentState.type, SyncStateType.syncing);
    });

    test('transitions to conflicted on conflictDetected', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.conflictDetected, data: {
        'conflictCount': 2,
      });

      expect(machine.currentState.type, SyncStateType.conflicted);
      expect(machine.currentState.conflictCount, 2);
    });

    test('decrements conflict count on conflictResolved', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.conflictDetected, data: {
        'conflictCount': 2,
      });
      machine.processEvent(SyncEvent.conflictResolved);

      expect(machine.currentState.conflictCount, 1);
    });

    test('transitions to syncing when all conflicts resolved', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.conflictDetected, data: {
        'conflictCount': 1,
      });
      machine.processEvent(SyncEvent.conflictResolved);

      expect(machine.currentState.type, SyncStateType.syncing);
      expect(machine.currentState.phase, SyncingPhase.finalizing);
    });

    test('transitions to waitingForNetwork on networkLost during sync', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.networkLost);

      expect(machine.currentState.type, SyncStateType.waitingForNetwork);
    });

    test('transitions back to syncing on networkAvailable', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.networkLost);
      machine.processEvent(SyncEvent.networkAvailable);

      expect(machine.currentState.type, SyncStateType.syncing);
    });

    test('pause and resume work correctly', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.pauseRequested);

      expect(machine.currentState.type, SyncStateType.paused);

      machine.processEvent(SyncEvent.resumeRequested);
      expect(machine.currentState.type, SyncStateType.syncing);
    });

    test('cancelRequested returns to idle', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.cancelRequested);

      expect(machine.currentState.type, SyncStateType.idle);
    });

    test('ignores syncRequested when already syncing', () {
      machine.processEvent(SyncEvent.syncRequested);
      final stateAfterFirst = machine.currentState;

      machine.processEvent(SyncEvent.syncRequested);
      expect(machine.currentState.stateEnteredAt, stateAfterFirst.stateEnteredAt);
    });

    test('state stream emits on transitions', () async {
      final states = <SyncState>[];
      machine.stateStream.listen(states.add);

      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.syncCompleted);

      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].type, SyncStateType.syncing);
      expect(states[1].type, SyncStateType.idle);
    });

    test('transition history is recorded', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.processEvent(SyncEvent.syncCompleted);

      final history = machine.transitionHistory;
      expect(history.length, 2);
      expect(history[0].event, SyncEvent.syncRequested);
      expect(history[1].event, SyncEvent.syncCompleted);
    });

    test('updatePendingOperations updates count', () {
      machine.updatePendingOperations(5);
      expect(machine.currentState.pendingOperations, 5);
    });

    test('incrementCompleted increments count', () {
      machine.processEvent(SyncEvent.syncRequested, data: {
        'totalOperations': 10,
      });

      machine.incrementCompleted();
      expect(machine.currentState.completedOperations, 1);

      machine.incrementCompleted();
      expect(machine.currentState.completedOperations, 2);
    });

    test('reset returns to initial state', () {
      machine.processEvent(SyncEvent.syncRequested);
      machine.reset();

      expect(machine.currentState.type, SyncStateType.idle);
    });
  });
}
