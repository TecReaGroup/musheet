/// Score Command Provider - Unified mutation entry point for score domain
///
/// This provider centralizes score write actions and separates them from
/// query/list state. Query state remains in stream/list providers backed by
/// the database. Command state only tracks execution metadata.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../models/annotation.dart';
import '../models/score.dart';
import 'scores_state_provider.dart';

@immutable
class ScoreCommandState {
  final bool isSubmitting;
  final String? error;
  final String? lastAction;

  const ScoreCommandState({
    this.isSubmitting = false,
    this.error,
    this.lastAction,
  });

  ScoreCommandState copyWith({
    bool? isSubmitting,
    String? error,
    String? lastAction,
    bool clearError = false,
  }) {
    return ScoreCommandState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      lastAction: lastAction ?? this.lastAction,
    );
  }
}

class ScopedScoreCommandsNotifier extends Notifier<ScoreCommandState> {
  ScopedScoreCommandsNotifier(this.scope);

  final DataScope scope;

  @override
  ScoreCommandState build() => const ScoreCommandState();

  ScoreRepository get _repo => ref.read(scopedScoreRepositoryProvider(scope));

  List<Score> get _currentScores => ref.read(scopedScoresListProvider(scope));

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

  Future<void> addScore(Score score) {
    return _run('addScore', () => _repo.addScore(score));
  }

  Future<void> updateScore(Score score) {
    return _run('updateScore', () => _repo.updateScore(score));
  }

  Future<void> updateBpm(String scoreId, int bpm) {
    return _run('updateBpm', () async {
      final score = _currentScores.firstWhere(
        (s) => s.id == scoreId,
        orElse: () => throw Exception('Score not found'),
      );
      await _repo.updateScore(score.copyWith(bpm: bpm));
    });
  }

  Future<void> deleteScore(String scoreId) {
    return _run('deleteScore', () => _repo.deleteScore(scoreId));
  }

  Future<void> addInstrumentScore(
    String scoreId,
    InstrumentScore instrumentScore,
  ) {
    return _run(
      'addInstrumentScore',
      () => _repo.addInstrumentScore(scoreId, instrumentScore),
    );
  }

  Future<void> deleteInstrumentScore(
    String scoreId,
    String instrumentScoreId,
  ) {
    return _run(
      'deleteInstrumentScore',
      () => _repo.deleteInstrumentScore(instrumentScoreId),
    );
  }

  Future<void> updateAnnotations(
    String scoreId,
    String instrumentScoreId,
    List<Annotation> annotations,
  ) {
    return _run(
      'updateAnnotations',
      () => _repo.updateAnnotations(instrumentScoreId, annotations),
    );
  }

  Future<void> duplicateScore(String sourceScoreId) {
    return _run('duplicateScore', () => _repo.duplicateScore(sourceScoreId));
  }

  Future<void> reorderInstrumentScores(
    String scoreId,
    List<String> instrumentScoreIds,
  ) {
    return _run('reorderInstrumentScores', () async {
      final score = _currentScores.firstWhere(
        (s) => s.id == scoreId,
        orElse: () => throw Exception('Score not found'),
      );
      final reordered = instrumentScoreIds
          .map((id) => score.instrumentScores.firstWhere((item) => item.id == id))
          .toList();
      await _repo.updateScore(score.copyWith(instrumentScores: reordered));
    });
  }
}

final scopedScoreCommandsProvider =
    NotifierProvider.family<
      ScopedScoreCommandsNotifier,
      ScoreCommandState,
      DataScope
    >((scope) {
      return ScopedScoreCommandsNotifier(scope);
    });
