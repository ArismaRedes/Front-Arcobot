import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:logto_dart_sdk/logto_dart_sdk.dart' as logto_core;
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _accessTokenKey = 'arcobot.logto.local_access_token';
  static const _refreshTokenKey = 'arcobot.logto.local_refresh_token';
  static const _idTokenKey = 'arcobot.logto.local_id_token';
  static const _accessExpiresAtKey = 'arcobot.logto.local_access_expires_at';

  final logto_core.LogtoClient _client;

  String get _normalizedEndpoint => Env.logtoEndpoint.trim().replaceAll(
        RegExp(r'/$'),
        '',
      );

  Future<void> signIn() {
    return _client.signIn(
      Env.logtoEffectiveRedirectUri,
      extraParams: {'organization_id': Env.logtoOrganizationId},
    );
  }

  Future<void> signInWithSocial(String connectorTarget) {
    final target = connectorTarget.trim();
    if (target.isEmpty) {
      throw StateError('LOGTO_FACEBOOK_CONNECTOR_TARGET no puede estar vacio');
    }

    return _client.signIn(
      Env.logtoEffectiveRedirectUri,
      directSignIn: 'social:$target',
      extraParams: {'organization_id': Env.logtoOrganizationId},
    );
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw StateError('El correo es obligatorio');
    }
    if (password.trim().isEmpty) {
      throw StateError('La contrasena es obligatoria');
    }

    final oidcConfig = await logto_core.fetchOidcConfig(
      http.Client(),
      '$_normalizedEndpoint/oidc/.well-known/openid-configuration',
    );

    final pkce = _Pkce.generate();
    final state = _generateState();

    final signInUri = logto_core.generateSignInUri(
      authorizationEndpoint: oidcConfig.authorizationEndpoint,
      clientId: Env.logtoEffectiveAppId,
      redirectUri: Env.logtoEffectiveRedirectUri,
      codeChallenge: pkce.codeChallenge,
      state: state,
      scopes: Env.logtoScopes,
      resources: [Env.logtoAudience],
      firstScreen: logto_core.FirstScreen.identifierSignIn,
      identifiers: const [logto_core.IdentifierType.email],
      loginHint: normalizedEmail,
      extraParams: {'organization_id': Env.logtoOrganizationId},
    );

    final cookies = _CookieStore();
    final dio = Dio(
      BaseOptions(
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    await _request(
      dio: dio,
      cookies: cookies,
      method: 'GET',
      uri: signInUri,
    );

    await _request(
      dio: dio,
      cookies: cookies,
      method: 'PUT',
      uri: Uri.parse('$_normalizedEndpoint/api/experience'),
      data: {'interactionEvent': 'SignIn'},
    );

    final verificationResponse = await _request(
      dio: dio,
      cookies: cookies,
      method: 'POST',
      uri: Uri.parse(
          '$_normalizedEndpoint/api/experience/verification/password'),
      data: {
        'identifier': {
          'type': 'email',
          'value': normalizedEmail,
        },
        'password': password,
      },
    );

    final verificationId = _extractVerificationId(verificationResponse.data);
    if (verificationId.isEmpty) {
      throw StateError('No se pudo validar la cuenta con Logto');
    }

    await _request(
      dio: dio,
      cookies: cookies,
      method: 'POST',
      uri: Uri.parse('$_normalizedEndpoint/api/experience/identification'),
      data: {'verificationId': verificationId},
    );

    final submitResponse = await _request(
      dio: dio,
      cookies: cookies,
      method: 'POST',
      uri: Uri.parse('$_normalizedEndpoint/api/experience/submit'),
      data: const <String, dynamic>{},
    );

    final redirectTo = _extractRedirectTo(submitResponse.data);
    if (redirectTo.isEmpty) {
      throw StateError('Logto no devolvio redirect de autorizacion');
    }

    final callbackUri = await _resolveCallbackUri(
      dio: dio,
      cookies: cookies,
      startUri: Uri.parse(redirectTo),
      expectedRedirectUriPrefix: Env.logtoEffectiveRedirectUri,
    );

    final code = logto_core.verifyAndParseCodeFromCallbackUri(
      callbackUri,
      Env.logtoEffectiveRedirectUri,
      state,
    );

    final tokenResponse = await logto_core.fetchTokenByAuthorizationCode(
      httpClient: http.Client(),
      tokenEndPoint: oidcConfig.tokenEndpoint,
      code: code,
      codeVerifier: pkce.codeVerifier,
      clientId: Env.logtoEffectiveAppId,
      redirectUri: Env.logtoEffectiveRedirectUri,
      resource: Env.logtoAudience,
    );

    await _saveLocalTokens(
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
      idToken: tokenResponse.idToken,
      expiresIn: tokenResponse.expiresIn,
    );
  }

  Future<void> signOut() async {
    await _clearLocalTokens();

    final isAuthenticated = await _client.isAuthenticated;
    if (!isAuthenticated) {
      return;
    }
    await _client.signOut(Env.logtoEffectivePostLogoutRedirectUri);
  }

  Future<bool> isAuthenticated() async {
    final hasLocalSession = await _hasLocalSession();
    if (hasLocalSession) {
      return true;
    }
    return _client.isAuthenticated;
  }

  Future<String?> getAccessToken() async {
    final localToken = await _getValidLocalAccessToken();
    if (localToken != null) {
      return localToken;
    }

    final refreshedToken = await _refreshLocalAccessToken();
    if (refreshedToken != null) {
      return refreshedToken;
    }

    final accessToken =
        await _client.getAccessToken(resource: Env.logtoAudience);
    return accessToken?.token;
  }

  Future<String?> getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    final localIdToken = prefs.getString(_idTokenKey);
    if (localIdToken != null && localIdToken.isNotEmpty) {
      return localIdToken;
    }
    return _client.idToken;
  }

  Future<Response<dynamic>> _request({
    required Dio dio,
    required _CookieStore cookies,
    required String method,
    required Uri uri,
    Map<String, dynamic>? data,
  }) async {
    final headers = <String, Object?>{};
    final cookieHeader = cookies.asHeader();
    if (cookieHeader.isNotEmpty) {
      headers['cookie'] = cookieHeader;
    }
    if (data != null) {
      headers['content-type'] = Headers.jsonContentType;
    }

    final response = await dio.requestUri<dynamic>(
      uri,
      data: data,
      options: Options(
        method: method,
        headers: headers,
      ),
    );

    cookies.capture(response.headers.map['set-cookie']);
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw StateError(
        '[${method.toUpperCase()} ${uri.path}] ${_extractError(response.data)}',
      );
    }
    return response;
  }

  Future<String> _resolveCallbackUri({
    required Dio dio,
    required _CookieStore cookies,
    required Uri startUri,
    required String expectedRedirectUriPrefix,
  }) async {
    var current = startUri;
    for (var i = 0; i < 12; i++) {
      final currentRaw = current.toString();
      if (currentRaw.startsWith(expectedRedirectUriPrefix)) {
        return currentRaw;
      }

      final response = await _request(
        dio: dio,
        cookies: cookies,
        method: 'GET',
        uri: current,
      );

      final redirectLocation = response.headers.value('location');
      if (redirectLocation == null || redirectLocation.isEmpty) {
        if (response.realUri.toString().startsWith(expectedRedirectUriPrefix)) {
          return response.realUri.toString();
        }
        throw StateError('No se pudo resolver callback de Logto');
      }

      current = current.resolve(redirectLocation);
    }

    throw StateError('Se excedio el numero maximo de redirecciones de Logto');
  }

  String _extractVerificationId(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final value = payload['verificationId'];
      if (value is String) {
        return value;
      }
    }
    return '';
  }

  String _extractRedirectTo(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final value = payload['redirectTo'];
      if (value is String) {
        return value;
      }
    }
    return '';
  }

  String _extractError(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final code = payload['code'];
      final message = payload['message'];
      final details = payload['details'];
      return 'Logto error: ${code ?? 'unknown'} - ${message ?? details ?? 'sin detalle'}';
    }
    return 'Error de autenticacion en Logto';
  }

  Future<void> _saveLocalTokens({
    required String accessToken,
    required String? refreshToken,
    required String idToken,
    required int expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresIn - 10))
        .millisecondsSinceEpoch;

    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_idTokenKey, idToken);
    await prefs.setInt(_accessExpiresAtKey, expiresAt);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(_refreshTokenKey);
    }
  }

  Future<void> _clearLocalTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_idTokenKey);
    await prefs.remove(_accessExpiresAtKey);
  }

  Future<bool> _hasLocalSession() async {
    return (await _getValidLocalAccessToken()) != null ||
        (await _refreshLocalAccessToken()) != null;
  }

  Future<String?> _getValidLocalAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final expiresAt = prefs.getInt(_accessExpiresAtKey);
    if (accessToken == null || expiresAt == null) {
      return null;
    }

    if (DateTime.now().millisecondsSinceEpoch >= expiresAt) {
      return null;
    }
    return accessToken;
  }

  Future<String?> _refreshLocalAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final oidcConfig = await logto_core.fetchOidcConfig(
        http.Client(),
        '$_normalizedEndpoint/oidc/.well-known/openid-configuration',
      );

      final refreshed = await logto_core.fetchTokenByRefreshToken(
        httpClient: http.Client(),
        tokenEndPoint: oidcConfig.tokenEndpoint,
        clientId: Env.logtoEffectiveAppId,
        refreshToken: refreshToken,
        resource: Env.logtoAudience,
        organizationId: Env.logtoOrganizationId,
      );

      await _saveLocalTokens(
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken ?? refreshToken,
        idToken: refreshed.idToken ?? (prefs.getString(_idTokenKey) ?? ''),
        expiresIn: refreshed.expiresIn,
      );
      return refreshed.accessToken;
    } catch (_) {
      await _clearLocalTokens();
      return null;
    }
  }

  String _generateState() {
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }
}

class _CookieStore {
  final Map<String, String> _cookies = {};

  void capture(List<String>? setCookieHeaders) {
    if (setCookieHeaders == null) {
      return;
    }

    for (final rawCookie in setCookieHeaders) {
      final cookiePart = rawCookie.split(';').first.trim();
      final separator = cookiePart.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      final key = cookiePart.substring(0, separator).trim();
      final value = cookiePart.substring(separator + 1).trim();
      if (value.isEmpty) {
        _cookies.remove(key);
      } else {
        _cookies[key] = value;
      }
    }
  }

  String asHeader() {
    if (_cookies.isEmpty) {
      return '';
    }
    return _cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }
}

class _Pkce {
  _Pkce({
    required this.codeVerifier,
    required this.codeChallenge,
  });

  final String codeVerifier;
  final String codeChallenge;

  static _Pkce generate() {
    const charset =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    final verifier = List.generate(
      64,
      (_) => charset[random.nextInt(charset.length)],
    ).join();

    final challengeBytes = sha256.convert(ascii.encode(verifier)).bytes;
    final challenge = base64UrlEncode(challengeBytes).replaceAll('=', '');

    return _Pkce(
      codeVerifier: verifier,
      codeChallenge: challenge,
    );
  }
}
