import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/config/env.dart';
import 'package:front_arcobot/core/realtime/realtime_client.dart';
import 'package:front_arcobot/features/sessions/data/session_repository.dart';
import 'package:front_arcobot/features/sessions/data/teacher_session_repository.dart';
import 'package:front_arcobot/features/sessions/domain/report_models.dart';
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
    this.liveConnected = false,
  });

  final TeacherSessionStatus status;
  final ClassSessionInfo? session;
  final List<SessionStudentInfo> students;
  final String? errorMessage;

  /// true si el WebSocket del monitor está conectado (tiempo real);
  /// false = respaldo por polling.
  final bool liveConnected;

  TeacherSessionState copyWith({
    TeacherSessionStatus? status,
    ClassSessionInfo? session,
    List<SessionStudentInfo>? students,
    String? errorMessage,
    bool? liveConnected,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return TeacherSessionState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      students: students ?? this.students,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      liveConnected: liveConnected ?? this.liveConnected,
    );
  }
}

class TeacherSessionController extends StateNotifier<TeacherSessionState> {
  TeacherSessionController(this._repository)
      : super(const TeacherSessionState()) {
    _realtime = RealtimeClient(ticketProvider: _requestRealtimeUri);
    _realtimeEventSubscription = _realtime.events.listen(_onRealtimeEvent);
    _realtimeStatusSubscription = _realtime.statuses.listen(_onRealtimeStatus);
  }

  /// Con WebSocket vivo el polling queda de reconciliación lenta;
  /// sin WS vuelve a ser la fuente principal.
  static const _pollIntervalRealtime = Duration(seconds: 15);
  static const _pollIntervalFallback = Duration(seconds: 3);

  final TeacherSessionRepository _repository;
  late final RealtimeClient _realtime;
  late final StreamSubscription<RealtimeEvent> _realtimeEventSubscription;
  late final StreamSubscription<RealtimeConnectionStatus>
      _realtimeStatusSubscription;
  Timer? _pollTimer;
  bool _monitorAttached = false;

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

  Future<bool> create({
    required String name,
    List<String> trackIds = const [],
    String? groupId,
  }) async {
    state = state.copyWith(
      status: TeacherSessionStatus.creating,
      clearError: true,
    );
    try {
      final session = await _repository.createSession(
        name: name,
        trackIds: trackIds,
        groupId: groupId,
      );
      state = TeacherSessionState(
        status: TeacherSessionStatus.active,
        session: session,
      );
      _startLiveMonitor();
      return true;
    } catch (error) {
      state = TeacherSessionState(
        status: TeacherSessionStatus.idle,
        errorMessage: friendlyError(error),
      );
      return false;
    }
  }

  // ─── Tiempo real (WebSocket) ───────────────────────────────────────

  /// La pantalla docente controla explícitamente la conexión. Al salir al
  /// dashboard la sesión sigue activa, pero socket y polling se apagan.
  void attachMonitor() {
    if (_monitorAttached) {
      return;
    }
    _monitorAttached = true;
    _startLiveMonitor();
  }

  void detachMonitor() {
    if (!_monitorAttached) {
      return;
    }
    _monitorAttached = false;
    _stopPolling();
    unawaited(_realtime.stop());
    if (mounted && state.liveConnected) {
      state = state.copyWith(liveConnected: false);
    }
  }

  void _startLiveMonitor() {
    if (!_monitorAttached || state.status != TeacherSessionStatus.active) {
      return;
    }
    _startPolling(_pollIntervalFallback);
    _realtime.start();
  }

  Future<Uri> _requestRealtimeUri() async {
    final pin = state.session?.pin;
    if (pin == null ||
        state.status != TeacherSessionStatus.active ||
        !_monitorAttached) {
      throw StateError('No hay un monitor de sesión activo');
    }
    final ticket = await _repository.createLiveTicket(pin);
    return ticket.toWebSocketUri(Env.apiBaseUrl);
  }

  void _onRealtimeStatus(RealtimeConnectionStatus status) {
    if (!mounted ||
        !_monitorAttached ||
        state.status != TeacherSessionStatus.active) {
      return;
    }
    final connected = status == RealtimeConnectionStatus.connected;
    state = state.copyWith(liveConnected: connected);
    _startPolling(
      connected ? _pollIntervalRealtime : _pollIntervalFallback,
    );
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!mounted) {
      return;
    }

    switch (event.type) {
      case 'students':
        final items = event.data as List<dynamic>? ?? const [];
        final students = [
          for (final item in items)
            SessionStudentInfo.fromJson(item as Map<String, dynamic>),
        ]..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
        state = state.copyWith(students: students, clearError: true);
      case 'student_upsert':
        final data = event.data;
        if (data is! Map<String, dynamic>) {
          return;
        }
        final student = SessionStudentInfo.fromJson(data);
        final students = [...state.students];
        final index = students.indexWhere((item) => item.id == student.id);
        if (index >= 0) {
          students[index] = student;
        } else {
          students.add(student);
          students.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
        }
        state = state.copyWith(students: students, clearError: true);
      case 'session_ended':
        if (state.status == TeacherSessionStatus.active) {
          _stopPolling();
          unawaited(_realtime.stop());
          state = state.copyWith(
            status: TeacherSessionStatus.idle,
            clearSession: true,
            errorMessage: 'La sesión terminó.',
          );
        }
    }
  }

  // ─── Polling de respaldo/reconciliación ────────────────────────────

  void _startPolling(Duration interval) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _refreshStudents());
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
        unawaited(_realtime.stop());
        state = state.copyWith(
          status: TeacherSessionStatus.idle,
          clearSession: true,
          errorMessage: friendlyError(error),
        );
      }
    }
  }

  /// Termina la clase y devuelve las analíticas para mostrar el podio.
  Future<SessionReportStats?> end() async {
    final pin = state.session?.pin;
    if (pin == null) {
      return null;
    }
    _stopPolling();
    await _realtime.stop();
    state = state.copyWith(status: TeacherSessionStatus.ending);
    SessionReportStats? report;
    try {
      report = await _repository.endSession(pin);
    } catch (error) {
      debugPrint('No se pudo cerrar la sesión en backend: $error');
      // La sesión expira sola por TTL; no bloqueamos al docente.
    }
    state = const TeacherSessionState();
    return report;
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    unawaited(_realtimeEventSubscription.cancel());
    unawaited(_realtimeStatusSubscription.cancel());
    unawaited(_realtime.dispose());
    super.dispose();
  }
}
