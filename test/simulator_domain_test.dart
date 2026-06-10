import 'package:flutter_test/flutter_test.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';
import 'package:front_arcobot/features/simulator/domain/path_optimizer.dart';

void main() {
  group('simulate', () {
    const level = BoardLevel(
      name: 'test',
      start: Cell(2, 6),
      startHeading: Heading.up,
      goal: Cell(2, 4),
    );

    test('llega a la meta avanzando', () {
      final result = simulate(level, [
        RobotCommand.forward,
        RobotCommand.forward,
      ]);
      expect(result.outcome, SimOutcome.success);
      expect(result.steps.last.kind, StepKind.goalReached);
      expect(result.steps.last.after.cell, const Cell(2, 4));
    });

    test('éxito inmediato al pisar la meta, ignora tarjetas sobrantes', () {
      final result = simulate(level, [
        RobotCommand.forward,
        RobotCommand.forward,
        RobotCommand.forward,
        RobotCommand.turnLeft,
      ]);
      expect(result.outcome, SimOutcome.success);
      expect(result.steps.length, 2);
    });

    test('chocar contra el borde bloquea', () {
      const borderLevel = BoardLevel(
        name: 'borde',
        start: Cell(0, 0),
        startHeading: Heading.up,
        goal: Cell(4, 7),
      );
      final result = simulate(borderLevel, [RobotCommand.forward]);
      expect(result.outcome, SimOutcome.blocked);
      expect(result.steps.single.kind, StepKind.blocked);
      // No se movió.
      expect(result.steps.single.after.cell, const Cell(0, 0));
    });

    test('chocar contra obstáculo bloquea', () {
      final obstacleLevel = BoardLevel(
        name: 'roca',
        start: Cell(2, 6),
        startHeading: Heading.up,
        goal: Cell(2, 0),
        obstacles: {Cell(2, 5)},
      );
      final result = simulate(obstacleLevel, [RobotCommand.forward]);
      expect(result.outcome, SimOutcome.blocked);
    });

    test('giros cambian orientación sin mover', () {
      final result = simulate(level, [
        RobotCommand.turnRight,
        RobotCommand.turnRight,
      ]);
      expect(result.outcome, SimOutcome.incomplete);
      expect(result.steps.last.after.heading, Heading.down);
      expect(result.steps.last.after.cell, level.start);
    });

    test('atrás se mueve en sentido opuesto', () {
      final result = simulate(level, [RobotCommand.backward]);
      expect(result.steps.single.after.cell, const Cell(2, 7));
    });
  });

  group('findOptimalCommands', () {
    test('línea recta: solo avanzar', () {
      const level = BoardLevel(
        name: 'recta',
        start: Cell(2, 6),
        startHeading: Heading.up,
        goal: Cell(2, 2),
      );
      final commands = findOptimalCommands(level);
      expect(commands, isNotNull);
      expect(commands!.length, 4);
      expect(commands.every((c) => c == RobotCommand.forward), isTrue);
    });

    test('la ruta óptima realmente llega a la meta', () {
      for (final level in demoLevels) {
        final commands = findOptimalCommands(level);
        expect(commands, isNotNull, reason: 'nivel ${level.name} sin solución');
        final result = simulate(level, commands!);
        expect(
          result.outcome,
          SimOutcome.success,
          reason: 'óptimo no llega en ${level.name}',
        );
      }
    });

    test('nivel imposible devuelve null', () {
      final walled = BoardLevel(
        name: 'imposible',
        start: Cell(0, 0),
        startHeading: Heading.down,
        goal: Cell(4, 7),
        obstacles: {Cell(1, 0), Cell(0, 1), Cell(1, 1)},
      );
      expect(findOptimalCommands(walled), isNull);
    });

    test('óptimo nunca es más largo que una solución manual', () {
      const level = BoardLevel(
        name: 'L',
        start: Cell(0, 7),
        startHeading: Heading.up,
        goal: Cell(2, 5),
      );
      final manual = [
        RobotCommand.forward,
        RobotCommand.forward,
        RobotCommand.turnRight,
        RobotCommand.forward,
        RobotCommand.forward,
      ];
      expect(simulate(level, manual).outcome, SimOutcome.success);
      final optimal = findOptimalCommands(level)!;
      expect(optimal.length, lessThanOrEqualTo(manual.length));
    });
  });
}
