import 'package:flutter/foundation.dart';

class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String logtoRedirectUri = String.fromEnvironment(
    'LOGTO_REDIRECT_URI',
    defaultValue: '',
  );

  static const String logtoPostLogoutRedirectUri = String.fromEnvironment(
    'LOGTO_POST_LOGOUT_REDIRECT_URI',
    defaultValue: '',
  );

  static String get _defaultRedirectUri {
    if (kIsWeb) {
      return _resolveWebCallbackUri();
    }
    return 'io.arcobot.app://callback';
  }

  static String get _defaultPostLogoutRedirectUri {
    if (kIsWeb) {
      return _resolveWebCallbackUri();
    }
    return 'io.arcobot.app://logout-callback';
  }

  static String _resolveWebCallbackUri() {
    final callbackUri = Uri.base.resolve('callback.html').replace(
          queryParameters: null,
          fragment: null,
        );
    return callbackUri.toString();
  }

  static bool _isWebCompatibleRedirectUri(String value) {
    final parsed = Uri.tryParse(value);
    if (parsed == null || !parsed.hasScheme) {
      return false;
    }
    final scheme = parsed.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  static bool _isNativeCompatibleRedirectUri(String value) {
    final parsed = Uri.tryParse(value);
    if (parsed == null || !parsed.hasScheme) {
      return false;
    }
    final scheme = parsed.scheme.toLowerCase();
    return scheme.isNotEmpty && scheme != 'http' && scheme != 'https';
  }

  static String get logtoEffectiveRedirectUri {
    final configured = logtoRedirectUri.trim();
    if (configured.isEmpty) {
      return _defaultRedirectUri;
    }
    if (kIsWeb && !_isWebCompatibleRedirectUri(configured)) {
      return _defaultRedirectUri;
    }
    return configured;
  }

  static String get logtoEffectivePostLogoutRedirectUri {
    final configured = logtoPostLogoutRedirectUri.trim();
    if (configured.isEmpty) {
      return _defaultPostLogoutRedirectUri;
    }
    if (kIsWeb && !_isWebCompatibleRedirectUri(configured)) {
      return _defaultPostLogoutRedirectUri;
    }
    return configured;
  }

  static void validate() {
    final apiBaseUri = Uri.tryParse(apiBaseUrl);
    if (apiBaseUri == null ||
        !apiBaseUri.hasScheme ||
        !apiBaseUri.hasAuthority) {
      throw StateError('API_BASE_URL debe ser una URL absoluta valida.');
    }

    final redirectUri = logtoEffectiveRedirectUri;
    final postLogoutRedirectUri = logtoEffectivePostLogoutRedirectUri;
    if (kIsWeb) {
      if (!_isWebCompatibleRedirectUri(redirectUri)) {
        throw StateError(
          'LOGTO_REDIRECT_URI debe usar http/https en Web: $redirectUri',
        );
      }
      if (!_isWebCompatibleRedirectUri(postLogoutRedirectUri)) {
        throw StateError(
          'LOGTO_POST_LOGOUT_REDIRECT_URI debe usar http/https en Web: '
          '$postLogoutRedirectUri',
        );
      }
      return;
    }

    if (!_isNativeCompatibleRedirectUri(redirectUri)) {
      throw StateError(
        'LOGTO_REDIRECT_URI debe usar esquema personalizado en mobile: '
        '$redirectUri',
      );
    }
    if (!_isNativeCompatibleRedirectUri(postLogoutRedirectUri)) {
      throw StateError(
        'LOGTO_POST_LOGOUT_REDIRECT_URI debe usar esquema personalizado en '
        'mobile: $postLogoutRedirectUri',
      );
    }
  }
}
