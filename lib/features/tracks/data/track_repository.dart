import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/network/api_client.dart';
import 'package:front_arcobot/features/sessions/data/session_repository.dart';
import 'package:front_arcobot/features/tracks/domain/track_models.dart';

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  // Usa el Dio autenticado: las pistas son del docente (JWT de Logto).
  return TrackRepository(ref.watch(apiClientProvider));
});

class TrackRepository {
  TrackRepository(this._dio);

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

  Future<List<TrackInfo>> listTracks() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/tracks');
      final items = response.data!['data'] as List<dynamic>;
      return items
          .map((item) => TrackInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  Future<TrackInfo> createTrack(TrackInfo draft) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/tracks',
        data: draft.toJson(),
      );
      return TrackInfo.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  Future<TrackInfo> updateTrack(TrackInfo track) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/tracks/${track.id}',
        data: track.toJson(),
      );
      return TrackInfo.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }

  Future<void> deleteTrack(String id) async {
    try {
      await _dio.delete<void>('/api/v1/tracks/$id');
    } on DioException catch (error) {
      _throwFrom(error);
    }
  }
}
