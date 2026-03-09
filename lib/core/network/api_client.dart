import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/config/env.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authController = ref.read(authControllerProvider.notifier);
  var invalidationInProgress = false;

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? accessToken;
        try {
          accessToken = await authRepository.getAccessToken();
        } catch (error) {
          // Token refresh can fail for temporary network issues; defer session
          // invalidation to an actual 401 response from the protected API.
          debugPrint('No se pudo obtener token de acceso: $error');
        }

        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 && !invalidationInProgress) {
          invalidationInProgress = true;
          authController.invalidateSession(
            errorMessage: 'Sesion invalida. Inicia sesion nuevamente.',
          );
          invalidationInProgress = false;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
