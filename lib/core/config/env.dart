class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String logtoEndpoint = String.fromEnvironment(
    'LOGTO_ENDPOINT',
    defaultValue: '',
  );

  static const String logtoAppId = String.fromEnvironment(
    'LOGTO_APP_ID',
    defaultValue: '',
  );

  static const String logtoClientId = String.fromEnvironment(
    'LOGTO_CLIENT_ID',
    defaultValue: '',
  );

  static String get logtoEffectiveAppId =>
      logtoAppId.isNotEmpty ? logtoAppId : logtoClientId;

  static const String logtoAudience = String.fromEnvironment(
    'LOGTO_AUDIENCE',
    defaultValue: '',
  );

  static const String logtoRedirectUri = String.fromEnvironment(
    'LOGTO_REDIRECT_URI',
    defaultValue: 'io.arcobot.app://callback',
  );

  static const String logtoPostLogoutRedirectUri = String.fromEnvironment(
    'LOGTO_POST_LOGOUT_REDIRECT_URI',
    defaultValue: 'io.arcobot.app://logout-callback',
  );

  static const String logtoScopesRaw = String.fromEnvironment(
    'LOGTO_SCOPES',
    defaultValue: 'openid profile email offline_access',
  );

  static const String logtoFacebookConnectorTarget = String.fromEnvironment(
    'LOGTO_FACEBOOK_CONNECTOR_TARGET',
    defaultValue: 'facebook',
  );

  static const String logtoOrganizationId = String.fromEnvironment(
    'LOGTO_ORGANIZATION_ID',
    defaultValue: '',
  );

  static List<String> get logtoScopes => logtoScopesRaw
      .split(' ')
      .map((scope) => scope.trim())
      .where((scope) => scope.isNotEmpty)
      .toList(growable: false);

  static void validate() {
    final missing = <String>[];

    if (logtoEndpoint.isEmpty) {
      missing.add('LOGTO_ENDPOINT');
    }
    if (logtoEffectiveAppId.isEmpty) {
      missing.add('LOGTO_APP_ID (or LOGTO_CLIENT_ID)');
    }
    if (logtoAudience.isEmpty) {
      missing.add('LOGTO_AUDIENCE');
    }
    if (logtoOrganizationId.isEmpty) {
      missing.add('LOGTO_ORGANIZATION_ID');
    }

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required dart-defines: ${missing.join(', ')}',
      );
    }
  }
}
