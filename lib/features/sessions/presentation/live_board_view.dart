import 'package:flutter/material.dart';
import 'package:front_arcobot/features/sessions/domain/session_models.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';
import 'package:front_arcobot/features/simulator/presentation/board_widget.dart';

/// Tablero en vivo del monitor: el mismo `BoardWidget` que ve el niño
/// (rocas, estrella, robot animado) con la paleta oscura del docente.
class LiveBoardView extends StatelessWidget {
  const LiveBoardView({required this.live, super.key});

  final StudentLiveState live;

  @override
  Widget build(BuildContext context) {
    final level = BoardLevel(
      name: '',
      start: live.start,
      startHeading: live.startHeading,
      goal: live.goal,
      obstacles: live.obstacles,
    );
    return BoardWidget(
      level: level,
      robot: RobotState(live.robotCell, live.robotHeading),
      ghostCells: const [],
      showGhost: false,
      celebrating: live.phase == 'success',
      crashed: live.phase == 'blocked',
      style: BoardStyle.panel,
    );
  }
}
