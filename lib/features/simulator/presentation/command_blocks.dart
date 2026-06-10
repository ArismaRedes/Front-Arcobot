import 'package:flutter/material.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';

/// Visual de cada tarjeta de navegación. Sin texto: icono + color
/// (UI textless para pre-lectores).
class CommandVisual {
  const CommandVisual._(this.icon, this.color, this.semantics);

  final IconData icon;
  final Color color;
  final String semantics;

  static CommandVisual of(RobotCommand command) => switch (command) {
        RobotCommand.forward => const CommandVisual._(
            Icons.arrow_upward_rounded, ArcobotColors.skyBlue, 'Avanzar'),
        RobotCommand.backward => const CommandVisual._(
            Icons.arrow_downward_rounded, ArcobotColors.gameLilac, 'Retroceder'),
        RobotCommand.turnLeft => const CommandVisual._(
            Icons.rotate_left_rounded, ArcobotColors.sunYellow, 'Girar a la izquierda'),
        RobotCommand.turnRight => const CommandVisual._(
            Icons.rotate_right_rounded, ArcobotColors.successGreen, 'Girar a la derecha'),
      };
}

class CommandCard extends StatelessWidget {
  const CommandCard({
    required this.command,
    this.size = 56,
    this.dimmed = false,
    super.key,
  });

  final RobotCommand command;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final visual = CommandVisual.of(command);
    return Semantics(
      label: visual.semantics,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: dimmed
              ? visual.color.withValues(alpha: 0.35)
              : visual.color,
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: dimmed
              ? null
              : [
                  BoxShadow(
                    color: visual.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Icon(visual.icon, color: Colors.white, size: size * 0.58),
      ),
    );
  }
}

/// Paleta de tarjetas: tap agrega al final, drag permite soltarla en la
/// secuencia (mouse en web, dedo en móvil — Draggable soporta ambos).
class CommandPalette extends StatelessWidget {
  const CommandPalette({
    required this.enabled,
    required this.onAdd,
    this.cardSize = 56,
    super.key,
  });

  final bool enabled;
  final ValueChanged<RobotCommand> onAdd;
  final double cardSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final command in RobotCommand.values)
          Draggable<RobotCommand>(
            data: command,
            maxSimultaneousDrags: enabled ? 1 : 0,
            feedback: Material(
              color: Colors.transparent,
              child: CommandCard(command: command, size: cardSize * 1.15),
            ),
            childWhenDragging:
                CommandCard(command: command, size: cardSize, dimmed: true),
            child: GestureDetector(
              onTap: enabled ? () => onAdd(command) : null,
              child: CommandCard(
                command: command,
                size: cardSize,
                dimmed: !enabled,
              ),
            ),
          ),
      ],
    );
  }
}

/// Secuencia programada: acepta drops de la paleta, tap quita la tarjeta.
class ProgramStrip extends StatelessWidget {
  const ProgramStrip({
    required this.program,
    required this.enabled,
    required this.activeIndex,
    required this.onDropAdd,
    required this.onRemoveAt,
    this.cardSize = 48,
    super.key,
  });

  final List<RobotCommand> program;
  final bool enabled;

  /// Índice de la tarjeta ejecutándose (resaltada durante el run).
  final int? activeIndex;
  final ValueChanged<RobotCommand> onDropAdd;
  final ValueChanged<int> onRemoveAt;
  final double cardSize;

  @override
  Widget build(BuildContext context) {
    return DragTarget<RobotCommand>(
      onAcceptWithDetails: enabled ? (details) => onDropAdd(details.data) : null,
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: BoxConstraints(minHeight: cardSize + 24),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFE9F6FF) : const Color(0xFFF5F8FB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlighted
                  ? ArcobotColors.skyBlue
                  : ArcobotColors.softBorder,
              width: highlighted ? 2.5 : 2,
            ),
          ),
          child: program.isEmpty
              ? SizedBox(
                  height: cardSize,
                  child: Center(
                    child: Text(
                      'Arrastra o toca las tarjetas',
                      style: TextStyle(
                        color: ArcobotColors.textSecondary
                            .withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < program.length; i++)
                      GestureDetector(
                        onTap: enabled ? () => onRemoveAt(i) : null,
                        child: AnimatedScale(
                          scale: activeIndex == i ? 1.18 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CommandCard(
                                command: program[i],
                                size: cardSize,
                                dimmed: activeIndex != null && activeIndex != i,
                              ),
                              if (enabled)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    width: 17,
                                    height: 17,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 13,
                                      color: ArcobotColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
