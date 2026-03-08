library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_flow_provider.dart';
import 'auth_runtime_provider.dart';

@immutable
class AppBootstrapState {
  final bool isBootstrapping;
  final Object? error;
  final StackTrace? stackTrace;

  const AppBootstrapState({
    required this.isBootstrapping,
    this.error,
    this.stackTrace,
  });

  const AppBootstrapState.bootstrapping()
      : isBootstrapping = true,
        error = null,
        stackTrace = null;

  const AppBootstrapState.ready()
      : isBootstrapping = false,
        error = null,
        stackTrace = null;

  const AppBootstrapState.failure(this.error, this.stackTrace)
      : isBootstrapping = false;

  bool get hasError => error != null;
}

class AppBootstrapNotifier extends Notifier<AppBootstrapState> {
  bool _started = false;

  @override
  AppBootstrapState build() {
    return const AppBootstrapState.bootstrapping();
  }

  Future<void> ensureStarted() async {
    if (_started) return;
    _started = true;

    try {
      await ref.read(authFlowCoordinatorProvider).restoreSession();
      await postAuthWarmup();
      state = const AppBootstrapState.ready();
    } catch (error, stackTrace) {
      state = AppBootstrapState.failure(error, stackTrace);
    }
  }

  Future<void> postAuthWarmup() async {
    await ref.read(authRuntimeCoordinatorProvider).postAuthWarmup();
  }
}

final appBootstrapProvider =
    NotifierProvider<AppBootstrapNotifier, AppBootstrapState>(
      AppBootstrapNotifier.new,
    );
