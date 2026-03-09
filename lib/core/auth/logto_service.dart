import 'package:logto_dart_sdk/logto_dart_sdk.dart' as logto_core;

import 'package:front_arcobot/core/config/env.dart';

class LogtoService {
  LogtoService()
      : _client = logto_core.LogtoClient(
          config: logto_core.LogtoConfig(
            endpoint: Env.logtoEndpoint,
            appId: Env.logtoEffectiveAppId,
            resources: [Env.logtoAudience],
            scopes: Env.logtoScopes,
          ),
        );

  final logto_core.LogtoClient _client;

  Future<void> signIn() async {
    await _client.signIn(
      Env.logtoEffectiveRedirectUri,
      extraParams: {'organization_id': Env.logtoOrganizationId},
    );
    await _assertExpectedOrganizationMembership();
  }

  Future<void> signInWithSocial(String connectorTarget) async {
    final target = connectorTarget.trim();
    if (target.isEmpty) {
      throw StateError('LOGTO_FACEBOOK_CONNECTOR_TARGET no puede estar vacio');
    }

    try {
      await _client.signIn(
        Env.logtoEffectiveRedirectUri,
        directSignIn: 'social:$target',
        extraParams: {'organization_id': Env.logtoOrganizationId},
      );
    } on logto_core.LogtoAuthException catch (error) {
      final isRecoverableCallbackIssue = error.code ==
              logto_core.LogtoAuthExceptions.callbackUriValidationError &&
          const {
            'missing state',
            'invalid state',
            'missing code',
            'invalid redirect uri',
          }.contains(error.error);
      final isRecoverableAuthIssue =
          error.code == logto_core.LogtoAuthExceptions.authenticationError &&
              error.error == 'not_authenticated';

      if (!isRecoverableCallbackIssue && !isRecoverableAuthIssue) {
        rethrow;
      }

      await _client.signIn(
        Env.logtoEffectiveRedirectUri,
        extraParams: {'organization_id': Env.logtoOrganizationId},
      );
    }

    await _assertExpectedOrganizationMembership();
  }

  Future<void> signInWithEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw StateError('El correo es obligatorio');
    }

    await _client.signIn(
      Env.logtoEffectiveRedirectUri,
      firstScreen: logto_core.FirstScreen.identifierSignIn,
      identifiers: const [logto_core.IdentifierType.email],
      loginHint: normalizedEmail,
      extraParams: {'organization_id': Env.logtoOrganizationId},
    );
    await _assertExpectedOrganizationMembership();
  }

  Future<void> signOut() async {
    final isAuthenticated = await _client.isAuthenticated;
    if (!isAuthenticated) {
      return;
    }
    await _client.signOut(Env.logtoEffectivePostLogoutRedirectUri);
  }

  Future<bool> isAuthenticated() async {
    return _client.isAuthenticated;
  }

  Future<String?> getAccessToken() async {
    try {
      final accessToken = await _client.getAccessToken(
        resource: Env.logtoAudience,
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

  Future<String?> getIdToken() {
    return _client.idToken;
  }

  Future<void> _assertExpectedOrganizationMembership() async {
    final claims = await _client.idTokenClaims;
    if (claims == null) {
      return;
    }

    final expectedOrganizationId = Env.logtoOrganizationId.trim();
    if (_hasExpectedOrganization(claims, expectedOrganizationId)) {
      return;
    }

    if (!_containsAnyOrganizationClaim(claims)) {
      // Some social sign-in callbacks do not include organization claims
      // even when authentication succeeded. Do not fail closed on
      // unverifiable claims; API authorization still enforces tenant access.
      return;
    }

    await _trySignOutSilently();
    throw StateError('Tu cuenta no pertenece a la organizacion configurada.');
  }

  bool _containsAnyOrganizationClaim(dynamic claims) {
    final activeOrganization = _claimValue(claims, 'organization_id');
    if (activeOrganization is String && activeOrganization.trim().isNotEmpty) {
      return true;
    }

    final organizationsFromClaim = _claimValue(claims, 'organizations');
    if (_asStringList(organizationsFromClaim).isNotEmpty) {
      return true;
    }

    final organizationClaim =
        _claimValue(claims, 'urn:logto:claim:organizations');
    if (organizationClaim is Map && organizationClaim.isNotEmpty) {
      return true;
    }

    final organizationsGetter = _claimProperty(claims, 'organizations');
    return _asStringList(organizationsGetter).isNotEmpty;
  }

  bool _hasExpectedOrganization(dynamic claims, String expectedOrganizationId) {
    final activeOrganization = _claimValue(claims, 'organization_id');
    if (activeOrganization is String &&
        activeOrganization == expectedOrganizationId) {
      return true;
    }

    final organizationsFromClaim = _claimValue(claims, 'organizations');
    if (_asStringList(
      organizationsFromClaim,
    ).contains(expectedOrganizationId)) {
      return true;
    }

    final organizationClaim = _claimValue(
      claims,
      'urn:logto:claim:organizations',
    );
    if (organizationClaim is Map) {
      final normalizedMap = organizationClaim.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      if (normalizedMap.containsKey(expectedOrganizationId)) {
        return true;
      }
    }

    final organizationsGetter = _claimProperty(claims, 'organizations');
    return _asStringList(organizationsGetter).contains(expectedOrganizationId);
  }

  List<String> _asStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  dynamic _claimValue(dynamic claims, String key) {
    if (claims is Map) {
      return claims[key];
    }

    try {
      return claims[key];
    } catch (_) {
      return null;
    }
  }

  dynamic _claimProperty(dynamic claims, String propertyName) {
    if (propertyName == 'organizations') {
      try {
        return claims.organizations;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _trySignOutSilently() async {
    try {
      final isAuthenticated = await _client.isAuthenticated;
      if (!isAuthenticated) {
        return;
      }
      await _client.signOut(Env.logtoEffectivePostLogoutRedirectUri);
    } catch (_) {
      // No-op: this path is best-effort and should not hide the original error.
    }
  }
}
