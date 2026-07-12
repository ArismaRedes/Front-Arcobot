import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/features/sessions/data/session_repository.dart';
import 'package:front_arcobot/features/sessions/domain/session_models.dart';

final studentSessionProvider = StateNotifierProvider<StudentSessionController,
    AsyncValue<StudentSession?>>(
  (ref) => StudentSessionController(ref.watch(sessionRepositoryProvider)),
);

class StudentSessionController
    extends StateNotifier<AsyncValue<StudentSession?>> {
  StudentSessionController(this._repository)
      : super(const AsyncValue.data(null));

  final SessionRepository _repository;

  /// Mensajes pensados para que un docente se los lea al niño.
  static String friendlyError(Object error) {
    if (error is SessionRepositoryException) {
      switch (error.code) {
        case 'SESSION_NOT_FOUND':
          return 'No encontramos esa clase. Revisa el código con tu profe.';
        case 'ALIAS_TAKEN':
          return 'Ese nombre ya lo eligió alguien. ¡Prueba con otro!';
        case 'SESSION_FULL':
          return 'La clase está llena. Avísale a tu profe.';
        case 'SESSION_INVALID_PIN':
          return 'Ese código no es de una clase. Revísalo con tu profe.';
        case 'NETWORK':
          return 'Sin conexión. Revisa internet e intenta de nuevo.';
      }
    }
    return 'Algo salió mal. Intenta de nuevo.';
  }

  Future<ClassSessionInfo> validatePin(String pin) {
    return _repository.fetchSession(pin);
  }

  Future<bool> join({
    required String pin,
    required String alias,
    required String avatar,
  }) async {
    state = const AsyncValue.loading();
    try {
      var session = await _repository.joinSession(
        pin: pin,
        alias: alias,
        avatar: avatar,
      );
      try {
        final tracks = await _repository.fetchSessionTracks(pin);
        session = session.withTracks(tracks);
      } catch (error) {
        // Sin pistas del docente jugamos con las de demostración.
        debugPrint('No se pudieron cargar las pistas de la sesión: $error');
      }
      state = AsyncValue.data(session);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Reporta actividad al monitor del docente. Fire-and-forget: si falla
  /// no interrumpe el juego del niño.
  void reportProgress({
    required String trackName,
    required String outcome,
    required int cardsUsed,
    Map<String, dynamic>? snapshot,
  }) {
    final session = state.valueOrNull;
    if (session == null) {
      return;
    }
    unawaited(
      _repository
          .reportProgress(
            pin: session.sessionPin,
            studentToken: session.token,
            trackName: trackName,
            outcome: outcome,
            cardsUsed: cardsUsed,
            snapshot: snapshot,
          )
          .catchError(
            (Object error) => debugPrint('Reporte de progreso falló: $error'),
          ),
    );
  }

  void leave() {
    state = const AsyncValue.data(null);
  }
}
