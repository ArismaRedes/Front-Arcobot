import 'package:front_arcobot/core/config/env.dart';
import 'package:logto_dart_sdk/logto_dart_sdk.dart';

class LogtoService {
  LogtoService()
      : _client = LogtoClient(
          config: LogtoConfig(
            endpoint: Env.logtoEndpoint,
            appId: Env.logtoEffectiveAppId,
            resources: [Env.logtoAudience],
            scopes: Env.logtoScopes,
          ),
        );

  final LogtoClient _client;

  Future<void> signIn() {
    return _client.signIn(
      Env.logtoRedirectUri,
      extraParams: {'organization_id': Env.logtoOrganizationId},
    );
  }

  Future<void> signInWithSocial(String connectorTarget) {
    final target = connectorTarget.trim();
    if (target.isEmpty) {
      throw StateError('LOGTO_FACEBOOK_CONNECTOR_TARGET no puede estar vacio');
    }

    return _client.signIn(
      Env.logtoRedirectUri,
      directSignIn: 'social:$target',
      extraParams: {'organization_id': Env.logtoOrganizationId},
    );
  }

  Future<void> signOut() async {
    final isAuthenticated = await _client.isAuthenticated;
    if (!isAuthenticated) {
      return;
    }

    await _client.signOut(Env.logtoPostLogoutRedirectUri);
  }

  Future<bool> isAuthenticated() {
    return _client.isAuthenticated;
  }

  Future<String?> getAccessToken() async {
    final accessToken =
        await _client.getAccessToken(resource: Env.logtoAudience);
    return accessToken?.token;
  }

  Future<String?> getIdToken() {
    return _client.idToken;
  }
}
