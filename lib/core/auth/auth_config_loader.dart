import 'package:dio/dio.dart';
import 'package:front_arcobot/core/auth/auth_runtime_config.dart';
import 'package:front_arcobot/core/config/env.dart';

Future<AuthRuntimeConfig> loadAuthRuntimeConfig() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  final response = await dio
      .get<Map<String, dynamic>>('/api/v1/auth/config')
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw DioException(
          requestOptions: RequestOptions(
            baseUrl: Env.apiBaseUrl,
            path: '/api/v1/auth/config',
          ),
          type: DioExceptionType.connectionTimeout,
          message: 'Timeout cargando configuracion inicial',
        ),
      );
  final remoteConfig = AuthRuntimeConfig.fromApiPayload(response.data);
  remoteConfig.validate();
  return remoteConfig;
}
