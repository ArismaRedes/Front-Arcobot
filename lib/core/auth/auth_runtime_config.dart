class AuthRuntimeConfig {
  const AuthRuntimeConfig({
    required this.endpoint,
    required this.appId,
    required this.audience,
    required this.scopes,
    required this.facebookConnectorTarget,
    required this.googleConnectorTarget,
    this.organizationId,
  });

  final String endpoint;
  final String appId;
  final String audience;
  final List<String> scopes;
  final String facebookConnectorTarget;
  final String googleConnectorTarget;
  final String? organizationId;

  factory AuthRuntimeConfig.fromApiPayload(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    final source = data is Map<String, dynamic>
        ? data
        : payload ?? const <String, dynamic>{};

    return AuthRuntimeConfig(
      endpoint: _readString(source, 'endpoint') ?? '',
      appId: _readString(source, 'appId') ?? '',
      audience: _readString(source, 'audience') ?? '',
      scopes: _readScopes(source['scopes']),
      facebookConnectorTarget:
          _readString(source, 'facebookConnectorTarget') ?? 'facebook',
      googleConnectorTarget:
          _readString(source, 'googleConnectorTarget') ?? 'google',
      organizationId: _normalizeOptional(_readString(source, 'organizationId')),
    );
  }

  Map<String, String>? get organizationExtraParams {
    final organizationId = this.organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      return null;
    }

    return {'organization_id': organizationId};
  }

  void validate() {
    final missing = <String>[];
    if (endpoint.isEmpty) {
      missing.add('LOGTO_ENDPOINT');
    }
    if (appId.isEmpty) {
      missing.add('LOGTO_APP_ID (or LOGTO_CLIENT_ID)');
    }
    if (audience.isEmpty) {
      missing.add('LOGTO_AUDIENCE');
    }
    if (missing.isNotEmpty) {
      throw StateError('Missing auth configuration: ${missing.join(', ')}');
    }

    final endpointUri = Uri.tryParse(endpoint);
    if (endpointUri == null ||
        !endpointUri.hasScheme ||
        !endpointUri.hasAuthority) {
      throw StateError('LOGTO_ENDPOINT debe ser una URL absoluta valida.');
    }

    final audienceUri = Uri.tryParse(audience);
    if (audienceUri == null || !audienceUri.hasScheme) {
      throw StateError('LOGTO_AUDIENCE debe ser un identificador URI valido.');
    }
  }

  static String? _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _readScopes(Object? rawScopes) {
    if (rawScopes is List) {
      return rawScopes
          .whereType<String>()
          .map((scope) => scope.trim())
          .where((scope) => scope.isNotEmpty)
          .toList(growable: false);
    }

    if (rawScopes is String) {
      return rawScopes
          .split(RegExp(r'\s+'))
          .map((scope) => scope.trim())
          .where((scope) => scope.isNotEmpty)
          .toList(growable: false);
    }

    return const <String>[];
  }

  static String? _normalizeOptional(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
