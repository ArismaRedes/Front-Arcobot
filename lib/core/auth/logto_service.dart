import 'package:logto_dart_sdk/logto_dart_sdk.dart' as logto_core;

import 'package:front_arcobot/core/auth/auth_exceptions.dart';
import 'package:front_arcobot/core/auth/auth_runtime_config.dart';
import 'package:front_arcobot/core/config/env.dart';

class LogtoService {
  LogtoService({required AuthRuntimeConfig config})
      : _config = config,
        _client = logto_core.LogtoClient(
          config: logto_core.LogtoConfig(
            endpoint: config.endpoint,
            appId: config.appId,
            resources: [config.audience],
            scopes: config.scopes,
          ),
        );

  final AuthRuntimeConfig _config;
  final logto_core.LogtoClient _client;

  Future<void> signIn() async {
    await _runInteractiveSignIn(
      () => _client.signIn(
        _redirectUri,
        extraParams: _config.organizationExtraParams,
      ),
    );
  }

  Future<void> signInWithFacebook() async {
    await signInWithSocial(_config.facebookConnectorTarget);
  }

  Future<void> signInWithGoogle() async {
    await signInWithSocial(_config.googleConnectorTarget);
  }

  Future<void> signInWithSocial(String connectorTarget) async {
    final target = connectorTarget.trim();
    if (target.isEmpty) {
      throw const AppAuthException(AppAuthExceptionCode.invalidInput);
    }

    await _runInteractiveSignIn(
      () => _client.signIn(
        _redirectUri,
        directSignIn: 'social:$target',
        extraParams: _config.organizationExtraParams,
      ),
      retryOnInterruptedCallback: true,
    );
  }

  Future<void> signInWithEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const AppAuthException(AppAuthExceptionCode.invalidInput);
    }

    await _runInteractiveSignIn(
      () => _client.signIn(
        _redirectUri,
        firstScreen: logto_core.FirstScreen.identifierSignIn,
        identifiers: const [logto_core.IdentifierType.email],
        loginHint: normalizedEmail,
        extraParams: _config.organizationExtraParams,
      ),
    );
  }

  Future<void> signOut() async {
    final isAuthenticated = await _client.isAuthenticated;
    if (!isAuthenticated) {
      return;
    }
    await _client.signOut(_postLogoutRedirectUri);
  }

  Future<void> clearSession({bool revokeRefreshToken = false}) async {
    try {
      await _client.clearSession(revokeRefreshToken: revokeRefreshToken);
    } on logto_core.LogtoAuthException catch (error) {
      final isNotAuthenticated =
          error.code == logto_core.LogtoAuthExceptions.authenticationError &&
              const {'not_authenticated', 'not authenticated'}
                  .contains(error.error);

      if (!isNotAuthenticated) {
        rethrow;
      }
    }
  }

  Future<bool> isAuthenticated() async {
    return _client.isAuthenticated;
  }

  Future<String?> getAccessToken() async {
    try {
      final accessToken = await _client.getAccessToken(
        resource: _config.audience,
        organizationId: _config.organizationId,
      );
      return accessToken?.token;
    } on logto_core.LogtoAuthException catch (error) {
      if (error.code == logto_core.LogtoAuthExceptions.authenticationError &&
          error.error == 'not_authenticated') {
        return null;
      }
      rethrow;
    }
  }

  String get _redirectUri => Env.logtoEffectiveRedirectUri;

  String get _postLogoutRedirectUri => Env.logtoEffectivePostLogoutRedirectUri;

  Future<void> _runInteractiveSignIn(
    Future<void> Function() action, {
    bool retryOnInterruptedCallback = false,
  }) async {
    try {
      await action();
    } on logto_core.LogtoAuthException catch (error) {
      if (retryOnInterruptedCallback && _isInterruptedCallback(error)) {
        await clearSession();
        try {
          await action();
          return;
        } on logto_core.LogtoAuthException catch (retryError) {
          throw _mapInteractiveAuthException(retryError);
        }
      }

      throw _mapInteractiveAuthException(error);
    }
  }

  bool _isInterruptedCallback(logto_core.LogtoAuthException error) {
    return error.code ==
                logto_core.LogtoAuthExceptions.callbackUriValidationError &&
            const {'missing state', 'invalid state', 'missing code'}
                .contains(error.error) ||
        error.code == logto_core.LogtoAuthExceptions.authenticationError &&
            const {'not_authenticated', 'not authenticated'}
                .contains(error.error);
  }

  AppAuthException _mapInteractiveAuthException(
    logto_core.LogtoAuthException error,
  ) {
    final normalizedError = error.error.trim().toLowerCase();
    final normalizedDescription =
        error.errorDescription?.trim().toLowerCase() ?? '';
    if (normalizedDescription.contains('not a member of the organization')) {
      return AppAuthException(
        AppAuthExceptionCode.organizationMismatch,
        cause: error,
      );
    }

    final cancelledErrors = {
      'access_denied',
      'user_cancelled',
      'user_canceled',
      'cancelled',
      'canceled',
    };

    if (cancelledErrors.contains(normalizedError) ||
        normalizedError.contains('cancel') ||
        normalizedDescription.contains('cancel')) {
      return AppAuthException(
        AppAuthExceptionCode.signInCancelled,
        cause: error,
      );
    }

    if (error.code ==
        logto_core.LogtoAuthExceptions.callbackUriValidationError) {
      return AppAuthException(
        AppAuthExceptionCode.authCallbackFailed,
        cause: error,
      );
    }

    if (error.code == logto_core.LogtoAuthExceptions.authenticationError &&
        const {'not_authenticated', 'not authenticated'}
            .contains(normalizedError)) {
      return AppAuthException(
        AppAuthExceptionCode.authCallbackFailed,
        cause: error,
      );
    }

    return AppAuthException(AppAuthExceptionCode.sessionExpired, cause: error);
  }
}
