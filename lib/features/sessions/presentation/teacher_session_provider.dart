import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/features/sessions/data/session_repository.dart';
import 'package:front_arcobot/features/sessions/data/teacher_session_repository.dart';
import 'package:front_arcobot/features/sessions/domain/session_models.dart';

final teacherSessionProvider =
    StateNotifierProvider<TeacherSessionController, TeacherSessionState>(
  (ref) => TeacherSessionController(
    ref.watch(teacherSessionRepositoryProvider),
  ),
);

enum TeacherSessionStatus { idle, creating, active, ending }

@immutable
class TeacherSessionState {
  const TeacherSessionState({
    this.status = TeacherSessionStatus.idle,
    this.session,
    this.students = const [],
    this.errorMessage,
  });

  final TeacherSessionStatus status;
  final ClassSessionInfo? session;
  final List<SessionStudentInfo> students;
  final String? errorMessage;

  TeacherSessionState copyWith({
    TeacherSessionStatus? status,
    ClassSessionInfo? session,
    List<SessionStudentInfo>? students,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return TeacherSessionState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      students: students ?? this.students,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TeacherSessionController extends StateNotifier<TeacherSessionState> {
  TeacherSessionController(this._repository)
      : super(const TeacherSessionState());

  static const _pollInterval = Duration(seconds: 3);

  final TeacherSessionRepository _repository;
  Timer? _pollTimer;

  static String friendlyError(Object error) {
    if (error is SessionRepositoryException) {
      switch (error.code) {
        case 'NETWORK':
          return 'Sin conexión con el servidor. Revisa internet.';
        case 'SESSION_NOT_FOUND':
          return 'La sesión expiró o fue cerrada.';
        case 'AUTH_MISSING_TOKEN':
          return 'Tu sesión expiró. Inicia sesión nuevamente.';
      }
    }
    return 'Algo salió mal. Intenta de nuevo.';
  }

  Future<bool> create({required String name}) async {
    state = state.copyWith(
      status: TeacherSessionStatus.creating,
      clearError: true,
    );
    try {
      final session = await _repository.createSession(name: name);
      state = TeacherSessionState(
        status: TeacherSessionStatus.active,
        session: session,
      );
      _startPolling();
      return true;
    } catch (error) {
      state = TeacherSessionState(
        status: TeacherSessionStatus.idle,
        errorMessage: friendlyError(error),
      );
      return false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshStudents());
    unawaited(_refreshStudents());
  }

  Future<void> _refreshStudents() async {
    final pin = state.session?.pin;
    if (pin == null || state.status != TeacherSessionStatus.active) {
      return;
    }
    try {
      final students = await _repository.listStudents(pin);
      if (!mounted || state.status != TeacherSessionStatus.active) {
        return;
      }
      students.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
      state = state.copyWith(students: students, clearError: true);
    } catch (error) {
      // Falla puntual de polling: no rompemos la pantalla proyectada,
      // solo dejamos constancia y reintentamos en el próximo tick.
      debugPrint('Polling de estudiantes falló: $error');
      if (error is SessionRepositoryException &&
          error.code == 'SESSION_NOT_FOUND' &&
          mounted) {
        _stopPolling();
        state = state.copyWith(
          status: TeacherSessionStatus.idle,
          clearSession: true,
          errorMessage: friendlyError(error),
        );
      }
    }
  }

  Future<void> end() async {
    final pin = state.session?.pin;
    if (pin == null) {
      return;
    }
    _stopPolling();
    state = state.copyWith(status: TeacherSessionStatus.ending);
    try {
      await _repository.endSession(pin);
    } catch (error) {
      debugPrint('No se pudo cerrar la sesión en backend: $error');
      // La sesión expira sola por TTL; no bloqueamos al docente.
    }
    state = const TeacherSessionState();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
