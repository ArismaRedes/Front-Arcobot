import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/config/env.dart';
import 'package:front_arcobot/features/sessions/domain/session_models.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  // Dio propio sin interceptor JWT: el estudiante no tiene cuenta Logto.
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  return SessionRepository(dio);
});

class SessionRepositoryException implements Exception {
  const SessionRepositoryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SessionRepositoryException($code): $message';
}

class SessionRepository {
  SessionRepository(this._dio);

  final Dio _dio;

  Never _throwFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorBody = data['error'];
      if (errorBody is Map<String, dynamic>) {
        throw SessionRepositoryException(
          errorBody['code'] as String? ?? 'UNKNOWN',
          errorBody['message'] as String? ?? 'Unknown error',
        );
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      throw const SessionRepositoryException(
        'NETWORK',
        'No hay conexión con el servidor',
      );
    }
    throw SessionRepositoryException('UNKNOWN', error.message ?? 'Error');
  }

  /// Valida que exista una sesión activa con ese PIN.
  Future<ClassSessionInfo> fetchSession(String pin) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/v1/sessions/$pin');
      return ClassSessionInfo.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  /// Une al estudiante con alias + avatar. Devuelve token temporal.
  Future<StudentSession> joinSession({
    required String pin,
    required String alias,
    required String avatar,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sessions/$pin/join',
        data: {'alias': alias, 'avatar': avatar},
      );
      return StudentSession.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }
}
