import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/network/api_client.dart';
import 'package:front_arcobot/features/sessions/data/session_repository.dart';
import 'package:front_arcobot/features/sessions/domain/session_models.dart';

final teacherSessionRepositoryProvider =
    Provider<TeacherSessionRepository>((ref) {
  // Usa el Dio autenticado: estos endpoints requieren JWT de Logto.
  return TeacherSessionRepository(ref.watch(apiClientProvider));
});

class TeacherSessionRepository {
  TeacherSessionRepository(this._dio);

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

  Future<ClassSessionInfo> createSession({required String name}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sessions',
        data: {'name': name},
      );
      return ClassSessionInfo.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  Future<List<SessionStudentInfo>> listStudents(String pin) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/sessions/$pin/students',
      );
      final items = response.data!['data'] as List<dynamic>;
      return items
          .map((item) =>
              SessionStudentInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  Future<void> endSession(String pin) async {
    try {
      await _dio.delete<void>('/api/v1/sessions/$pin');
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }
}
