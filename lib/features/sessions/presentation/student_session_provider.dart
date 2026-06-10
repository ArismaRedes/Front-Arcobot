import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/features/sessions/data/session_repository.dart';
import 'package:front_arcobot/features/sessions/domain/session_models.dart';

final studentSessionProvider =
    StateNotifierProvider<StudentSessionController, AsyncValue<StudentSession?>>(
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
      final session = await _repository.joinSession(
        pin: pin,
        alias: alias,
        avatar: avatar,
      );
      state = AsyncValue.data(session);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  void leave() {
    state = const AsyncValue.data(null);
  }
}
