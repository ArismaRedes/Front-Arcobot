import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/auth/logto_service.dart';
import 'package:front_arcobot/features/auth/data/auth_repository.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';

final logtoServiceProvider = Provider<LogtoService>((ref) {
  return LogtoService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(logtoService: ref.watch(logtoServiceProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, {bool autoRestore = true})
    : super(const AuthState.unknown()) {
    if (autoRestore) {
      unawaited(restoreSession());
    }
  }

  final AuthRepository _repository;

  void _setFailure(Object error, {required _AuthFlow flow}) {
    debugPrint('Auth error [$flow]: $error');
    state = AuthState(
      status: AuthStatus.failure,
      errorMessage: _toFriendlyError(error, flow: flow),
    );
  }

  String _toFriendlyError(Object error, {required _AuthFlow flow}) {
    final normalized = error.toString().toLowerCase();

    if (normalized.contains('guard.invalid_input')) {
      return 'No pudimos validar los datos. Revisa el correo y la contrasena.';
    }

    if (normalized.contains('invalid credentials') ||
        normalized.contains('invalid_password') ||
        normalized.contains('invalid_grant') ||
        normalized.contains('wrong password')) {
      return 'Correo o contrasena incorrectos.';
    }

    if (normalized.contains('account_not_found') ||
        normalized.contains('user_not_found')) {
      return 'No encontramos una cuenta con ese correo.';
    }

    if (normalized.contains('access_denied') ||
        normalized.contains('cancel') ||
        normalized.contains('canceled') ||
        normalized.contains('user_cancelled')) {
      return 'Inicio de sesion cancelado.';
    }

    if (normalized.contains('network') ||
        normalized.contains('socketexception') ||
        normalized.contains('timed out') ||
        normalized.contains('timeout') ||
        normalized.contains('connection')) {
      return 'Sin conexion. Revisa internet e intenta de nuevo.';
    }

    if (normalized.contains('/api/experience/submit') ||
        normalized.contains('callback') ||
        normalized.contains('redirect')) {
      return 'No se pudo completar el inicio de sesion. Intenta nuevamente.';
    }

    if (flow == _AuthFlow.signInWithFacebook) {
      return 'No se pudo iniciar con Facebook. Intenta nuevamente.';
    }
    if (flow == _AuthFlow.signOut) {
      return 'No se pudo cerrar sesion. Intenta nuevamente.';
    }
    if (flow == _AuthFlow.restoreSession) {
      return 'No pudimos restaurar tu sesion. Inicia sesion nuevamente.';
    }
    return 'No se pudo iniciar sesion. Intenta nuevamente.';
  }

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final hasSession = await _repository.hasSession();
      state = hasSession
          ? const AuthState(status: AuthStatus.authenticated)
          : const AuthState(status: AuthStatus.unauthenticated);
    } catch (error) {
      _setFailure(error, flow: _AuthFlow.restoreSession);
    }
  }

  Future<void> signIn() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.signIn();
      state = const AuthState(status: AuthStatus.authenticated);
    } catch (error) {
      _setFailure(error, flow: _AuthFlow.signIn);
    }
  }

  Future<void> signInWithFacebook() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.signInWithFacebook();
      state = const AuthState(status: AuthStatus.authenticated);
    } catch (error) {
      _setFailure(error, flow: _AuthFlow.signInWithFacebook);
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AuthState(status: AuthStatus.authenticated);
    } catch (error) {
      _setFailure(error, flow: _AuthFlow.signInWithEmailAndPassword);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (error) {
      _setFailure(error, flow: _AuthFlow.signOut);
    }
  }

  void invalidateSession({String? errorMessage}) {
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: errorMessage,
    );
  }
}

enum _AuthFlow {
  restoreSession,
  signIn,
  signInWithFacebook,
  signInWithEmailAndPassword,
  signOut,
}
