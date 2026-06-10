import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';

/// Tablero 5×8 con obstáculos, meta, línea fantasma y robot animado.
/// Escala a cualquier tamaño (móvil táctil y web con mouse).
class BoardWidget extends StatelessWidget {
  const BoardWidget({
    required this.level,
    required this.robot,
    required this.ghostCells,
    required this.showGhost,
    required this.celebrating,
    required this.crashed,
    super.key,
  });

  final BoardLevel level;
  final RobotState robot;
  final List<Cell> ghostCells;
  final bool showGhost;
  final bool celebrating;
  final bool crashed;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kBoardCols / kBoardRows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / kBoardCols;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ArcobotColors.softBorder, width: 2),
              boxShadow: ArcobotShadows.soft,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BoardPainter(
                        level: level,
                        ghostCells: showGhost ? ghostCells : const [],
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeInOutCubic,
                    alignment: _cellAlignment(robot.cell),
                    child: SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: _RobotSprite(
                        heading: robot.heading,
                        celebrating: celebrating,
                        crashed: crashed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Alignment _cellAlignment(Cell cell) {
    // Alignment va de -1 a 1; mapear índice de celda a su centro.
    final x = kBoardCols == 1 ? 0.0 : (cell.col / (kBoardCols - 1)) * 2 - 1;
    final y = kBoardRows == 1 ? 0.0 : (cell.row / (kBoardRows - 1)) * 2 - 1;
    return Alignment(x, y);
  }
}

class _RobotSprite extends StatelessWidget {
  const _RobotSprite({
    required this.heading,
    required this.celebrating,
    required this.crashed,
  });

  final Heading heading;
  final bool celebrating;
  final bool crashed;

  @override
  Widget build(BuildContext context) {
    final color = crashed
        ? ArcobotColors.coral
        : (celebrating ? ArcobotColors.successGreen : ArcobotColors.guideTurquoise);

    return Padding(
      padding: const EdgeInsets.all(5),
      child: AnimatedScale(
        scale: celebrating ? 1.12 : 1,
        duration: const Duration(milliseconds: 300),
        child: AnimatedRotation(
          turns: heading.quarterTurns / 4,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: c.maxWidth * 0.52,
                  ),
                  Align(
                    alignment: const Alignment(0, -0.82),
                    child: Icon(
                      Icons.arrow_drop_up_rounded,
                      color: Colors.white,
                      size: c.maxWidth * 0.34,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({required this.level, required this.ghostCells});

  final BoardLevel level;
  final List<Cell> ghostCells;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / kBoardCols;
    final ch = size.height / kBoardRows;

    // Celdas alternadas estilo tablero.
    final cellPaint = Paint()..color = const Color(0xFFF2F9F8);
    for (var r = 0; r < kBoardRows; r++) {
      for (var c = 0; c < kBoardCols; c++) {
        if ((r + c).isEven) {
          canvas.drawRect(Rect.fromLTWH(c * cw, r * ch, cw, ch), cellPaint);
        }
      }
    }

    // Líneas de la cuadrícula.
    final gridPaint = Paint()
      ..color = const Color(0xFFDCEBE9)
      ..strokeWidth = 1.4;
    for (var c = 1; c < kBoardCols; c++) {
      canvas.drawLine(Offset(c * cw, 0), Offset(c * cw, size.height), gridPaint);
    }
    for (var r = 1; r < kBoardRows; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(size.width, r * ch), gridPaint);
    }

    Offset center(Cell cell) =>
        Offset((cell.col + 0.5) * cw, (cell.row + 0.5) * ch);

    // Obstáculos: rocas redondeadas.
    final obstaclePaint = Paint()..color = const Color(0xFF8FA3B8);
    final obstacleShade = Paint()..color = const Color(0xFF6E8398);
    for (final cell in level.obstacles) {
      final c = center(cell);
      final radius = cw * 0.34;
      canvas.drawCircle(c.translate(0, ch * 0.05), radius, obstacleShade);
      canvas.drawCircle(c.translate(0, -ch * 0.03), radius, obstaclePaint);
    }

    // Meta: estrella amarilla.
    _drawStar(canvas, center(level.goal), cw * 0.32,
        Paint()..color = ArcobotColors.sunYellow);

    // Casilla de salida marcada suave.
    final startPaint = Paint()
      ..color = ArcobotColors.guideTurquoise.withValues(alpha: 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center(level.start), width: cw * 0.9, height: ch * 0.9),
        Radius.circular(cw * 0.16),
      ),
      startPaint,
    );

    // Ghost Path: línea fantasma punteada de la trayectoria programada.
    if (ghostCells.length > 1) {
      final ghostPaint = Paint()
        ..color = ArcobotColors.skyBlue.withValues(alpha: 0.65)
        ..strokeWidth = cw * 0.09
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < ghostCells.length - 1; i++) {
        _drawDashedLine(
          canvas,
          center(ghostCells[i]),
          center(ghostCells[i + 1]),
          ghostPaint,
          dash: cw * 0.16,
          gap: cw * 0.12,
        );
      }
      // Punto final de la previsualización.
      canvas.drawCircle(
        center(ghostCells.last),
        cw * 0.12,
        Paint()..color = ArcobotColors.skyBlue.withValues(alpha: 0.75),
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final total = (b - a).distance;
    final direction = (b - a) / total;
    var covered = 0.0;
    while (covered < total) {
      final end = (covered + dash).clamp(0.0, total);
      canvas.drawLine(a + direction * covered, a + direction * end, paint);
      covered = end + gap;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (i * math.pi / points) - math.pi / 2;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.ghostCells != ghostCells;
}
