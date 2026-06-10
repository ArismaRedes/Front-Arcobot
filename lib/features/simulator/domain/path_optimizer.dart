import 'dart:collection';

import 'package:front_arcobot/features/simulator/domain/board_model.dart';

/// Optimizador de Algoritmos (requerimiento PDF): encuentra la secuencia
/// de tarjetas más corta entre el inicio y la meta usando BFS sobre el
/// espacio de estados (celda, orientación). Cada tarjeta cuesta 1, así la
/// "ruta más corta" significa menos tarjetas = menos energía y tiempo.
List<RobotCommand>? findOptimalCommands(BoardLevel level) {
  final start = level.initialState;
  if (start.cell == level.goal) {
    return const [];
  }

  String keyOf(RobotState s) => '${s.cell.col},${s.cell.row},${s.heading.index}';

  final queue = Queue<RobotState>()..add(start);
  final cameFrom = <String, (String, RobotCommand)>{};
  final visited = <String>{keyOf(start)};

  RobotState? goalState;

  while (queue.isNotEmpty && goalState == null) {
    final current = queue.removeFirst();
    final currentKey = keyOf(current);

    for (final command in const [
      RobotCommand.forward,
      RobotCommand.turnLeft,
      RobotCommand.turnRight,
    ]) {
      RobotState next;
      switch (command) {
        case RobotCommand.forward:
          final (dc, dr) = current.heading.delta;
          final cell = current.cell.shifted(dc, dr);
          if (level.isBlocked(cell)) {
            continue;
          }
          next = RobotState(cell, current.heading);
        case RobotCommand.turnLeft:
          next = RobotState(current.cell, current.heading.turnedLeft);
        case RobotCommand.turnRight:
          next = RobotState(current.cell, current.heading.turnedRight);
        case RobotCommand.backward:
          continue;
      }

      final nextKey = keyOf(next);
      if (visited.contains(nextKey)) {
        continue;
      }
      visited.add(nextKey);
      cameFrom[nextKey] = (currentKey, command);

      if (next.cell == level.goal) {
        goalState = next;
        break;
      }
      queue.add(next);
    }
  }

  if (goalState == null) {
    return null; // Nivel sin solución (no debería pasar en niveles bien diseñados).
  }

  // Reconstruir la secuencia caminando hacia atrás.
  final commands = <RobotCommand>[];
  var key = keyOf(goalState);
  final startKey = keyOf(start);
  while (key != startKey) {
    final (prevKey, command) = cameFrom[key]!;
    commands.add(command);
    key = prevKey;
  }
  return commands.reversed.toList();
}
