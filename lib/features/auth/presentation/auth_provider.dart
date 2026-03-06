import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/auth/logto_service.dart';
import 'package:front_arcobot/features/auth/data/auth_repository.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';

final logtoServiceProvider = Provider<LogtoService>((ref) {
  return LogtoService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    logtoService: ref.watch(logtoServiceProvider),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, {bool autoRestore = true})
      : super(const AuthState.unknown()) {
    if (autoRestore) {
      unawaited(restoreSession());
    }
  }

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final hasSession = await _repository.hasSession();
      state = hasSession
          ? const AuthState(status: AuthStatus.authenticated)
          : const AuthState(status: AuthStatus.unauthenticated);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.failure,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> signIn() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.signIn();
      state = const AuthState(status: AuthStatus.authenticated);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.failure,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> signInWithFacebook() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.signInWithFacebook();
      state = const AuthState(status: AuthStatus.authenticated);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.failure,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> signInWithTeacherCredentials() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.signInWithTeacherCredentials();
      state = const AuthState(status: AuthStatus.authenticated);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.failure,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.failure,
        errorMessage: error.toString(),
      );
    }
  }

  void invalidateSession({String? errorMessage}) {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: errorMessage,
    );
  }
}
