import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/audio/arco_audio.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';
import 'package:front_arcobot/features/simulator/domain/path_optimizer.dart';

final simulatorProvider =
    StateNotifierProvider.autoDispose<SimulatorController, SimulatorState>(
  (ref) => SimulatorController(ref.watch(arcoAudioProvider)),
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

  factory SimulatorState.forLevel(int index) {
    final level = demoLevels[index % demoLevels.length];
    return SimulatorState(
      levelIndex: index % demoLevels.length,
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
  SimulatorController(this._audio) : super(SimulatorState.forLevel(0));

  static const stepDuration = Duration(milliseconds: 650);

  final ArcoAudio _audio;
  bool _cancelRun = false;

  void addCommand(RobotCommand command) {
    if (state.phase != SimPhase.editing ||
        state.program.length >= SimulatorState.maxProgramLength) {
      return;
    }
    _audio.sfx(ArcoSfx.tap);
    state = state.copyWith(program: [...state.program, command]);
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
  }

  void removeCommandAt(int index) {
    if (state.phase != SimPhase.editing) {
      return;
    }
    _audio.sfx(ArcoSfx.tap);
    final program = [...state.program]..removeAt(index);
    state = state.copyWith(program: program);
  }

  void clearProgram() {
    if (state.phase != SimPhase.editing) {
      return;
    }
    state = state.copyWith(program: const []);
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
  }

  void nextLevel() {
    _cancelRun = true;
    state = SimulatorState.forLevel(state.levelIndex + 1);
  }

  void restartLevel() {
    _cancelRun = true;
    state = SimulatorState.forLevel(state.levelIndex);
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
        return;
      }
      if (step.kind == StepKind.goalReached) {
        await Future<void>.delayed(stepDuration);
        if (!mounted) return;
        unawaited(_audio.sfx(ArcoSfx.celebrate));
        state = state.copyWith(phase: SimPhase.success, clearActiveStep: true);
        return;
      }
      await Future<void>.delayed(stepDuration);
    }

    if (!mounted || _cancelRun) {
      return;
    }
    // Terminó las tarjetas sin llegar a la meta: vuelta amable a edición.
    unawaited(_audio.sfx(ArcoSfx.error));
    state = state.copyWith(phase: SimPhase.blocked, clearActiveStep: true);
  }
}
