import 'package:flutter/foundation.dart';

/// Tablero oficial de ArcoBot: 5 columnas × 8 filas (requerimiento PDF).
const int kBoardCols = 5;
const int kBoardRows = 8;

enum Heading { up, right, down, left }

extension HeadingOps on Heading {
  Heading get turnedLeft =>
      Heading.values[(index + Heading.values.length - 1) % Heading.values.length];

  Heading get turnedRight => Heading.values[(index + 1) % Heading.values.length];

  /// Cuartos de vuelta para rotar el sprite del robot.
  int get quarterTurns => index;

  (int dc, int dr) get delta => switch (this) {
        Heading.up => (0, -1),
        Heading.right => (1, 0),
        Heading.down => (0, 1),
        Heading.left => (-1, 0),
      };
}

/// Tarjetas de navegación que el niño arrastra (Adelante, Atrás, Giros).
enum RobotCommand { forward, backward, turnLeft, turnRight }

@immutable
class Cell {
  const Cell(this.col, this.row);

  final int col;
  final int row;

  bool get insideBoard =>
      col >= 0 && col < kBoardCols && row >= 0 && row < kBoardRows;

  Cell shifted(int dc, int dr) => Cell(col + dc, row + dr);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => '($col,$row)';
}

@immutable
class RobotState {
  const RobotState(this.cell, this.heading);

  final Cell cell;
  final Heading heading;
}

/// Nivel jugable: dónde empieza el robot, la meta y los obstáculos.
@immutable
class BoardLevel {
  const BoardLevel({
    required this.name,
    required this.start,
    required this.startHeading,
    required this.goal,
    this.obstacles = const {},
  });

  final String name;
  final Cell start;
  final Heading startHeading;
  final Cell goal;
  final Set<Cell> obstacles;

  RobotState get initialState => RobotState(start, startHeading);

  bool isBlocked(Cell cell) => !cell.insideBoard || obstacles.contains(cell);
}

enum StepKind { move, turn, blocked, goalReached }

@immutable
class SimStep {
  const SimStep({
    required this.command,
    required this.before,
    required this.after,
    required this.kind,
  });

  final RobotCommand command;
  final RobotState before;
  final RobotState after;
  final StepKind kind;
}

enum SimOutcome { success, blocked, incomplete }

@immutable
class SimulationResult {
  const SimulationResult({required this.steps, required this.outcome});

  final List<SimStep> steps;
  final SimOutcome outcome;

  /// Celdas que pisa el robot, en orden (para la línea fantasma).
  List<Cell> get visitedCells {
    final cells = <Cell>[];
    if (steps.isNotEmpty) {
      cells.add(steps.first.before.cell);
    }
    for (final step in steps) {
      if (step.after.cell != (cells.isEmpty ? null : cells.last)) {
        cells.add(step.after.cell);
      }
    }
    return cells;
  }
}

RobotState _apply(RobotState state, RobotCommand command) {
  switch (command) {
    case RobotCommand.turnLeft:
      return RobotState(state.cell, state.heading.turnedLeft);
    case RobotCommand.turnRight:
      return RobotState(state.cell, state.heading.turnedRight);
    case RobotCommand.forward:
      final (dc, dr) = state.heading.delta;
      return RobotState(state.cell.shifted(dc, dr), state.heading);
    case RobotCommand.backward:
      final (dc, dr) = state.heading.delta;
      return RobotState(state.cell.shifted(-dc, -dr), state.heading);
  }
}

/// Ejecuta la secuencia. Se detiene al chocar (blocked) o al pisar la
/// meta (goalReached); ese feedback inmediato es el adecuado para
/// pre-lectores.
SimulationResult simulate(BoardLevel level, List<RobotCommand> commands) {
  var state = level.initialState;
  final steps = <SimStep>[];

  for (final command in commands) {
    final next = _apply(state, command);
    final isMove =
        command == RobotCommand.forward || command == RobotCommand.backward;

    if (isMove && level.isBlocked(next.cell)) {
      steps.add(SimStep(
        command: command,
        before: state,
        after: state,
        kind: StepKind.blocked,
      ));
      return SimulationResult(steps: steps, outcome: SimOutcome.blocked);
    }

    final reachedGoal = isMove && next.cell == level.goal;
    steps.add(SimStep(
      command: command,
      before: state,
      after: next,
      kind: reachedGoal
          ? StepKind.goalReached
          : (isMove ? StepKind.move : StepKind.turn),
    ));
    state = next;

    if (reachedGoal) {
      return SimulationResult(steps: steps, outcome: SimOutcome.success);
    }
  }

  return SimulationResult(steps: steps, outcome: SimOutcome.incomplete);
}

/// Niveles demo (hasta que exista el Content Studio).
final List<BoardLevel> demoLevels = [
  const BoardLevel(
    name: 'Primer paseo',
    start: Cell(2, 6),
    startHeading: Heading.up,
    goal: Cell(2, 2),
  ),
  BoardLevel(
    name: 'Esquiva la roca',
    start: Cell(0, 7),
    startHeading: Heading.up,
    goal: Cell(4, 4),
    obstacles: {Cell(2, 5), Cell(2, 6), Cell(3, 4)},
  ),
  BoardLevel(
    name: 'El laberinto',
    start: Cell(0, 0),
    startHeading: Heading.down,
    goal: Cell(4, 7),
    obstacles: {
      Cell(1, 1),
      Cell(1, 2),
      Cell(3, 0),
      Cell(3, 2),
      Cell(2, 4),
      Cell(3, 4),
      Cell(4, 4),
      Cell(0, 6),
      Cell(1, 6),
    },
  ),
];
