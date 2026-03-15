import 'package:dio/dio.dart';
import 'package:front_arcobot/core/auth/auth_exceptions.dart';
import 'package:front_arcobot/core/auth/logto_service.dart';
import 'package:front_arcobot/core/config/env.dart';

class BackendSession {
  const BackendSession({
    required this.subject,
    required this.roles,
  });

  final String subject;
  final List<String> roles;
}

class AuthRepository {
  const AuthRepository({required LogtoService logtoService})
      : _logtoService = logtoService;

  final LogtoService _logtoService;

  Future<void> signIn() async {
    await _logtoService.signIn();
  }

  Future<void> signInWithFacebook() async {
    await _logtoService.signInWithFacebook();
  }

  Future<void> signInWithGoogle() async {
    await _logtoService.signInWithGoogle();
  }

  Future<void> signInWithEmail(String email) async {
    await _logtoService.signInWithEmail(email);
  }

  Future<void> signOut() async {
    await _logtoService.signOut();
  }

  Future<void> clearSession({bool revokeRefreshToken = false}) {
    return _logtoService.clearSession(
      revokeRefreshToken: revokeRefreshToken,
    );
  }

  Future<bool> hasSession() {
    return _logtoService.isAuthenticated();
  }

  Future<String?> getAccessToken() {
    return _logtoService.getAccessToken();
  }

  Future<BackendSession> verifyBackendSession() async {
    final accessToken = await _logtoService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const AppAuthException(AppAuthExceptionCode.sessionExpired);
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/auth/me',
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      return _parseBackendSessionResponse(response.data);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final backendErrorCode = _readBackendErrorCode(error.response?.data);
      if (statusCode == 403 &&
          const {
            'AUTH_ORGANIZATION_REQUIRED',
            'AUTH_ORGANIZATION_FORBIDDEN',
          }.contains(backendErrorCode)) {
        throw const AppAuthException(AppAuthExceptionCode.organizationMismatch);
      }
      if (statusCode == 401 || statusCode == 403) {
        throw const AppAuthException(AppAuthExceptionCode.backendUnauthorized);
      }
      rethrow;
    }
  }

  String? _readBackendErrorCode(Object? payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final error = payload['error'];
    if (error is! Map<String, dynamic>) {
      return null;
    }

    final code = error['code'];
    if (code is! String) {
      return null;
    }

    final normalized = code.trim();
    return normalized.isEmpty ? null : normalized;
  }

  BackendSession _parseBackendSessionResponse(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is! Map<String, dynamic>) {
      throw const AppAuthException(AppAuthExceptionCode.backendInvalidProfile);
    }

    final subject = data['sub'];
    if (subject is! String || subject.trim().isEmpty) {
      throw const AppAuthException(AppAuthExceptionCode.backendInvalidProfile);
    }

    final rawRoles = data['roles'];
    final roles = rawRoles is List
        ? rawRoles
            .whereType<String>()
            .map((role) => role.trim())
            .where((role) => role.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    return BackendSession(
      subject: subject.trim(),
      roles: roles,
    );
  }
}
