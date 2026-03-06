/// Setlist Command Provider - Unified mutation entry point for setlist domain
///
/// Query/list state remains in `setlists_state_provider.dart` and is backed by
/// database streams. This provider only coordinates write actions.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../models/setlist.dart';
import 'setlists_state_provider.dart';

@immutable
class SetlistCommandState {
  final bool isSubmitting;
  final String? error;
  final String? lastAction;

  const SetlistCommandState({
    this.isSubmitting = false,
    this.error,
    this.lastAction,
  });

  SetlistCommandState copyWith({
    bool? isSubmitting,
    String? error,
    String? lastAction,
    bool clearError = false,
  }) {
    return SetlistCommandState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

class ScopedSetlistCommandsNotifier extends Notifier<SetlistCommandState> {
  ScopedSetlistCommandsNotifier(this.scope);

  final DataScope scope;

  @override
  SetlistCommandState build() => const SetlistCommandState();

  SetlistRepository get _repo => ref.read(scopedSetlistRepositoryProvider(scope));

  Future<T> _run<T>(String action, Future<T> Function() operation) async {
    state = state.copyWith(
      isSubmitting: true,
      lastAction: action,
      clearError: true,
    );

    try {
      final result = await operation();
      state = state.copyWith(
        isSubmitting: false,
        lastAction: action,
        clearError: true,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
        lastAction: action,
      );
      rethrow;
    }
  }

  Future<void> createSetlist(String name, String description) {
    return _run('createSetlist', () async {
      final newSetlist = Setlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        scopeType: scope.isUser ? 'user' : 'team',
        scopeId: scope.id,
        name: name,
        description: description,
        scoreIds: const [],
        createdAt: DateTime.now(),
      );
      await _repo.addSetlist(newSetlist);
    });
  }

  Future<void> addSetlist(Setlist setlist) {
    return _run('addSetlist', () => _repo.addSetlist(setlist));
  }

  Future<void> updateSetlist(Setlist setlist) {
    return _run('updateSetlist', () => _repo.updateSetlist(setlist));
  }

  Future<void> deleteSetlist(String setlistId) {
    return _run('deleteSetlist', () => _repo.deleteSetlist(setlistId));
  }

  Future<void> addScoreToSetlist(String setlistId, String scoreId) {
    return _run(
      'addScoreToSetlist',
      () => _repo.addScoreToSetlist(setlistId, scoreId),
    );
  }

  Future<void> removeScoreFromSetlist(String setlistId, String scoreId) {
    return _run(
      'removeScoreFromSetlist',
      () => _repo.removeScoreFromSetlist(setlistId, scoreId),
    );
  }

  Future<void> reorderScores(String setlistId, List<String> newOrder) {
    return _run('reorderScores', () => _repo.reorderScores(setlistId, newOrder));
  }
}

final scopedSetlistCommandsProvider =
    NotifierProvider.family<
      ScopedSetlistCommandsNotifier,
      SetlistCommandState,
      DataScope
    >((scope) {
      return ScopedSetlistCommandsNotifier(scope);
    });
