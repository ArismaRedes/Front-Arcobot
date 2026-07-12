import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/network/api_client.dart';
import 'package:front_arcobot/features/sessions/data/session_repository.dart';
import 'package:front_arcobot/features/sessions/domain/report_models.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  // Endpoints de docente: requieren JWT de Logto.
  return GroupRepository(ref.watch(apiClientProvider));
});

class GroupRepository {
  GroupRepository(this._dio);

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

  Future<List<GroupInfo>> listGroups() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/groups');
      final items = response.data!['data'] as List<dynamic>;
      return items
          .map((item) => GroupInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  Future<GroupInfo> createGroup(String name) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/groups',
        data: {'name': name},
      );
      return GroupInfo.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  Future<GroupInfo> renameGroup(String id, String name) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/groups/$id',
        data: {'name': name},
      );
      return GroupInfo.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  Future<void> deleteGroup(String id) async {
    try {
      await _dio.delete<void>('/api/v1/groups/$id');
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  /// Historial de clases del grupo con sus reportes (analíticas por curso).
  Future<List<GroupSessionSummary>> listGroupSessions(String id) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/v1/groups/$id/sessions');
      final items = response.data!['data'] as List<dynamic>;
      return items
          .map((item) =>
              GroupSessionSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }
}
