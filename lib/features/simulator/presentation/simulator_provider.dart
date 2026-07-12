import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/audio/arco_audio.dart';
import 'package:front_arcobot/features/sessions/presentation/student_session_provider.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';
import 'package:front_arcobot/features/simulator/domain/path_optimizer.dart';
import 'package:front_arcobot/features/tracks/domain/track_models.dart';

/// Si el niño está en una sesión de clase juega las pistas del docente y
/// reporta su progreso; suelto (sin sesión) usa las pistas demo.
final simulatorProvider =
    StateNotifierProvider.autoDispose<SimulatorController, SimulatorState>(
  (ref) {
    final session = ref.watch(studentSessionProvider).valueOrNull;
    final levels = [
      for (final TrackInfo track in session?.tracks ?? const [])
        track.toBoardLevel(),
    ];
    return SimulatorController(
      ref.watch(arcoAudioProvider),
      levels: levels,
      onProgress: session == null
          ? null
          : (trackName, outcome, cardsUsed, snapshot) =>
              ref.read(studentSessionProvider.notifier).reportProgress(
                    trackName: trackName,
                    outcome: outcome,
                    cardsUsed: cardsUsed,
                    snapshot: snapshot,
                  ),
    );
  },
);

typedef SimProgressReporter = void Function(
  String trackName,
  String outcome,
  int cardsUsed,
  Map<String, dynamic>? snapshot,
);

enum SimPhase { editing, running, success, blocked }

@immutable
class SimulatorState {
  const SimulatorState({
    required this.levelIndex,
    required this.level,
    required this.program,
    required this.robot,
    required this.phase,
    required this.showGhost,
    this.optimalCount,
    this.lastRunSteps = 0,
    this.activeStep,
  });

  factory SimulatorState.forLevel(List<BoardLevel> levels, int index) {
    final level = levels[index % levels.length];
    return SimulatorState(
      levelIndex: index % levels.length,
      level: level,
      program: const [],
      robot: level.initialState,
      phase: SimPhase.editing,
      showGhost: true,
      optimalCount: findOptimalCommands(level)?.length,
    );
  }

  final int levelIndex;
  final BoardLevel level;
  final List<RobotCommand> program;
  final RobotState robot;
  final SimPhase phase;
  final bool showGhost;
  final int? optimalCount;
  final int lastRunSteps;

  /// Índice de la tarjeta que se está ejecutando (null fuera de un run).
  final int? activeStep;

  static const int maxProgramLength = 20;

  bool get canRun => phase == SimPhase.editing && program.isNotEmpty;

  /// Trayectoria fantasma: previsualiza el programa actual antes de
  /// ejecutarlo (requerimiento "Ghost Path").
  List<Cell> get ghostCells => simulate(level, program).visitedCells;

  /// Sugerencia del optimizador tras un éxito con más tarjetas de las
  /// necesarias.
  bool get hasShorterRoute =>
      phase == SimPhase.success &&
      optimalCount != null &&
      lastRunSteps > optimalCount!;

  SimulatorState copyWith({
    List<RobotCommand>? program,
    RobotState? robot,
    SimPhase? phase,
    bool? showGhost,
    int? lastRunSteps,
    int? activeStep,
    bool clearActiveStep = false,
  }) {
    return SimulatorState(
      levelIndex: levelIndex,
      level: level,
      program: program ?? this.program,
      robot: robot ?? this.robot,
      phase: phase ?? this.phase,
      showGhost: showGhost ?? this.showGhost,
      optimalCount: optimalCount,
      lastRunSteps: lastRunSteps ?? this.lastRunSteps,
      activeStep: clearActiveStep ? null : (activeStep ?? this.activeStep),
    );
  }
}

class SimulatorController extends StateNotifier<SimulatorState> {
  SimulatorController(
    this._audio, {
    List<BoardLevel> levels = const [],
    this.onProgress,
  })  : _levels = levels.isEmpty ? demoLevels : levels,
        super(
          SimulatorState.forLevel(levels.isEmpty ? demoLevels : levels, 0),
        ) {
    _reportLevelStart();
  }

  static const stepDuration = Duration(milliseconds: 650);

  /// Mínimo entre snapshots "en vivo" para no inundar el backend
  /// (el docente sondea cada 3 s, así que 1.5 s alcanza de sobra).
  static const _liveInterval = Duration(milliseconds: 1500);

  final ArcoAudio _audio;
  final List<BoardLevel> _levels;

  /// Avisa al monitor del docente (null si el niño juega sin sesión).
  final SimProgressReporter? onProgress;
  bool _cancelRun = false;
  DateTime _lastLiveReport = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _liveTimer;

  /// Réplica mínima de la pantalla del niño para el "ojo" del docente.
  Map<String, dynamic> _snapshot() {
    final level = state.level;
    Map<String, int> cellJson(Cell cell) => {'col': cell.col, 'row': cell.row};
    return {
      'phase': state.phase.name,
      'program': [for (final command in state.program) command.name],
      if (state.activeStep != null) 'activeStep': state.activeStep,
      'robot': {
        ...cellJson(state.robot.cell),
        'heading': state.robot.heading.name,
      },
      'board': {
        'start': cellJson(level.start),
        'startHeading': level.startHeading.name,
        'goal': cellJson(level.goal),
        'obstacles': [for (final cell in level.obstacles) cellJson(cell)],
      },
    };
  }

  void _send(String outcome, {int cardsUsed = 0}) {
    _liveTimer?.cancel();
    _liveTimer = null;
    _lastLiveReport = DateTime.now();
    onProgress?.call(state.level.name, outcome, cardsUsed, _snapshot());
  }

  /// Snapshot 'playing' con throttle: inmediato si pasó la ventana; si no,
  /// difiere un envío al final para que la última edición siempre llegue.
  void _reportLive() {
    if (onProgress == null) {
      return;
    }
    final elapsed = DateTime.now().difference(_lastLiveReport);
    if (elapsed >= _liveInterval) {
      _send('playing');
      return;
    }
    _liveTimer ??= Timer(_liveInterval - elapsed, () {
      _liveTimer = null;
      if (mounted) {
        _send('playing');
      }
    });
  }

  void _reportLevelStart() {
    if (onProgress != null) {
      _send('playing');
    }
  }

  void addCommand(RobotCommand command) {
    if (state.phase != SimPhase.editing ||
        state.program.length >= SimulatorState.maxProgramLength) {
      return;
    }
    _audio.sfx(ArcoSfx.tap);
    state = state.copyWith(program: [...state.program, command]);
    _reportLive();
  }

  void insertCommand(int index, RobotCommand command) {
    if (state.phase != SimPhase.editing ||
        state.program.length >= SimulatorState.maxProgramLength) {
      return;
    }
    _audio.sfx(ArcoSfx.tap);
    final program = [...state.program];
    program.insert(index.clamp(0, program.length), command);
    state = state.copyWith(program: program);
    _reportLive();
  }

  void removeCommandAt(int index) {
    if (state.phase != SimPhase.editing) {
      return;
    }
    _audio.sfx(ArcoSfx.tap);
    final program = [...state.program]..removeAt(index);
    state = state.copyWith(program: program);
    _reportLive();
  }

  void clearProgram() {
    if (state.phase != SimPhase.editing) {
      return;
    }
    state = state.copyWith(program: const []);
    _reportLive();
  }

  void toggleGhost() {
    state = state.copyWith(showGhost: !state.showGhost);
  }

  /// Vuelve a edición conservando el programa (para corregirlo).
  void resetRun() {
    _cancelRun = true;
    state = state.copyWith(
      robot: state.level.initialState,
      phase: SimPhase.editing,
      clearActiveStep: true,
    );
    _reportLive();
  }

  void nextLevel() {
    _cancelRun = true;
    state = SimulatorState.forLevel(_levels, state.levelIndex + 1);
    _reportLevelStart();
  }

  void restartLevel() {
    _cancelRun = true;
    state = SimulatorState.forLevel(_levels, state.levelIndex);
    _reportLevelStart();
  }

  Future<void> run() async {
    if (!state.canRun) {
      return;
    }
    _cancelRun = false;
    final result = simulate(state.level, state.program);
    state = state.copyWith(
      phase: SimPhase.running,
      robot: state.level.initialState,
      lastRunSteps: state.program.length,
    );
    if (onProgress != null) {
      // Arranque de la ejecución: el docente ve la fase 'running' al tiro.
      _send('playing');
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    for (var i = 0; i < result.steps.length; i++) {
      final step = result.steps[i];
      if (_cancelRun || !mounted) {
        return;
      }
      state = state.copyWith(robot: step.after, activeStep: i);
      if (step.kind == StepKind.blocked) {
        unawaited(_audio.sfx(ArcoSfx.error));
        state = state.copyWith(phase: SimPhase.blocked, clearActiveStep: true);
        if (onProgress != null) {
          _send('blocked', cardsUsed: state.lastRunSteps);
        }
        return;
      }
      if (step.kind == StepKind.goalReached) {
        await Future<void>.delayed(stepDuration);
        if (!mounted) return;
        unawaited(_audio.sfx(ArcoSfx.celebrate));
        state = state.copyWith(phase: SimPhase.success, clearActiveStep: true);
        if (onProgress != null) {
          _send('success', cardsUsed: state.lastRunSteps);
        }
        return;
      }
      // Posición del robot en movimiento, con throttle.
      _reportLive();
      await Future<void>.delayed(stepDuration);
    }

    if (!mounted || _cancelRun) {
      return;
    }
    // Terminó las tarjetas sin llegar a la meta: vuelta amable a edición.
    unawaited(_audio.sfx(ArcoSfx.error));
    state = state.copyWith(phase: SimPhase.blocked, clearActiveStep: true);
    if (onProgress != null) {
      _send('blocked', cardsUsed: state.lastRunSteps);
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }
}
