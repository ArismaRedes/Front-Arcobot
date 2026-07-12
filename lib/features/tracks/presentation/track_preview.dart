import 'package:flutter/material.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';
import 'package:front_arcobot/features/simulator/presentation/board_widget.dart';

/// Miniatura de una pista para listas y selectores del panel docente.
/// Reusa el `BoardWidget` del juego (apaisado, mismas rocas/estrella/robot)
/// con la paleta oscura; sin robot en vivo lo muestra en la salida.
class TrackPreview extends StatelessWidget {
  const TrackPreview({
    required this.start,
    required this.startHeading,
    required this.goal,
    required this.obstacles,
    this.robotCell,
    this.robotHeading = Heading.up,
    this.cellSize = 12,
    super.key,
  });

  final Cell start;
  final Heading startHeading;
  final Cell goal;
  final Set<Cell> obstacles;

  /// Posición actual del robot (monitor en vivo); null = solo la pista.
  final Cell? robotCell;
  final Heading robotHeading;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final level = BoardLevel(
      name: '',
      start: start,
      startHeading: startHeading,
      goal: goal,
      obstacles: obstacles,
    );
    final robot = robotCell == null
        ? level.initialState
        : RobotState(robotCell!, robotHeading);
    return SizedBox(
      width: kVisualCols * cellSize,
      height: kVisualRows * cellSize,
      child: BoardWidget(
        level: level,
        robot: robot,
        ghostCells: const [],
        showGhost: false,
        celebrating: false,
        crashed: false,
        style: BoardStyle.panel,
        borderRadius: 8,
      ),
    );
  }
}
