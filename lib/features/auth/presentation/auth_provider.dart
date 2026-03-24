import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/auth/auth_runtime_config.dart';
import 'package:front_arcobot/core/auth/auth_exceptions.dart';
import 'package:front_arcobot/core/auth/logto_service.dart';
import 'package:front_arcobot/features/auth/data/auth_repository.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';

final authRuntimeConfigProvider = Provider<AuthRuntimeConfig>((ref) {
  throw UnimplementedError('authRuntimeConfigProvider must be overridden');
});

final logtoServiceProvider = Provider<LogtoService>((ref) {
  return LogtoService(config: ref.watch(authRuntimeConfigProvider));
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

  Future<void> _clearSessionSilently() async {
    try {
      await _repository.clearSession();
    } catch (error) {
      debugPrint('No se pudo limpiar la sesion local: $error');
    }
  }

  Future<void> _handleControlledError(
    AppAuthException error, {
    required _AuthFlow flow,
  }) async {
    final shouldResetSession = switch (error.code) {
      AppAuthExceptionCode.sessionExpired ||
      AppAuthExceptionCode.backendUnauthorized ||
      AppAuthExceptionCode.backendInvalidProfile ||
      AppAuthExceptionCode.organizationMismatch =>
        true,
      AppAuthExceptionCode.invalidInput ||
      AppAuthExceptionCode.signInCancelled ||
      AppAuthExceptionCode.authCallbackFailed =>
        false,
    };

    if (shouldResetSession) {
      await _clearSessionSilently();
    }

    final shouldBecomeUnauthenticated = flow == _AuthFlow.restoreSession ||
        flow == _AuthFlow.unauthorizedResponse;

    state = AuthState(
      status: shouldBecomeUnauthenticated
          ? AuthStatus.unauthenticated
          : AuthStatus.failure,
      errorMessage: _toFriendlyError(error, flow: flow),
    );
  }

  String _toFriendlyError(Object error, {required _AuthFlow flow}) {
    if (error is AppAuthException) {
      switch (error.code) {
        case AppAuthExceptionCode.invalidInput:
          return 'No pudimos validar los datos. Revisa el correo y la contrasena.';
        case AppAuthExceptionCode.signInCancelled:
          return 'Inicio de sesion cancelado.';
        case AppAuthExceptionCode.authCallbackFailed:
          return 'No pudimos completar el regreso a la app. Intenta nuevamente.';
        case AppAuthExceptionCode.sessionExpired:
          return 'Tu sesion expiro. Inicia sesion nuevamente.';
        case AppAuthExceptionCode.backendUnauthorized:
          return 'Sesion invalida o sin permisos en backend.';
        case AppAuthExceptionCode.backendInvalidProfile:
          return 'No pudimos leer el perfil del usuario desde backend.';
        case AppAuthExceptionCode.organizationMismatch:
          return 'Tu cuenta no pertenece a la organizacion autorizada.';
      }
    }

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

    if (normalized.contains('organizacion configurada') ||
        normalized.contains('organization')) {
      return 'Tu cuenta no pertenece a la organizacion autorizada.';
    }

    if (flow == _AuthFlow.signInWithFacebook) {
      return 'No se pudo iniciar con Facebook. Intenta nuevamente.';
    }
    if (flow == _AuthFlow.signInWithGoogle) {
      return 'No se pudo iniciar con Google. Intenta nuevamente.';
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
      if (!hasSession) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      await _setAuthenticatedFromBackend();
    } on AppAuthException catch (error) {
      debugPrint('No se pudo restaurar la sesion: $error');
      await _clearSessionSilently();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (error) {
      debugPrint('Fallo inesperado restaurando la sesion: $error');
      await _clearSessionSilently();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _setAuthenticatedFromBackend() async {
    final backendSession = await _repository.verifyBackendSession();
    state = AuthState(
      status: AuthStatus.authenticated,
      subject: backendSession.subject,
      roles: backendSession.roles,
    );
  }

  Future<void> _runInteractiveAuth(
    Future<void> Function() action, {
    required _AuthFlow flow,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await action();
      await _setAuthenticatedFromBackend();
    } on AppAuthException catch (error) {
      await _handleControlledError(error, flow: flow);
    } catch (error) {
      _setFailure(error, flow: flow);
    }
  }

  Future<void> signIn() async {
    await _runInteractiveAuth(
      _repository.signIn,
      flow: _AuthFlow.signIn,
    );
  }

  Future<void> signInWithFacebook() async {
    await _runInteractiveAuth(
      _repository.signInWithFacebook,
      flow: _AuthFlow.signInWithFacebook,
    );
  }

  Future<void> signInWithGoogle() async {
    await _runInteractiveAuth(
      _repository.signInWithGoogle,
      flow: _AuthFlow.signInWithGoogle,
    );
  }

  Future<void> signInWithEmail(String email) async {
    await _runInteractiveAuth(
      () => _repository.signInWithEmail(email),
      flow: _AuthFlow.signInWithEmail,
    );
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

  Future<void> handleUnauthorizedResponse({String? errorMessage}) async {
    await _clearSessionSilently();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage:
          errorMessage ?? 'Tu sesion expiro. Inicia sesion nuevamente.',
    );
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
  signInWithGoogle,
  signInWithEmail,
  signOut,
  unauthorizedResponse,
}
