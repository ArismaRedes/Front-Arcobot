import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/app_theme.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/simulator/domain/board_model.dart';
import 'package:front_arcobot/features/simulator/domain/path_optimizer.dart';
import 'package:front_arcobot/features/simulator/presentation/board_widget.dart';
import 'package:front_arcobot/features/tracks/domain/track_models.dart';
import 'package:front_arcobot/features/tracks/presentation/tracks_provider.dart';
import 'package:front_arcobot/features/tracks/presentation/tracks_screen.dart';
import 'package:go_router/go_router.dart';

/// Herramienta activa del editor de pistas.
enum _EditorTool { start, goal, obstacle, erase }

/// Editor de pistas del docente: tablero 5×8 donde marca inicio (con
/// orientación), meta y obstáculos. La pista se guarda en backend.
class TrackEditorScreen extends ConsumerStatefulWidget {
  const TrackEditorScreen({this.track, super.key});

  static const routePath = '/teacher/tracks/editor';

  /// Pista a editar; null = crear nueva.
  final TrackInfo? track;

  @override
  ConsumerState<TrackEditorScreen> createState() => _TrackEditorScreenState();
}

class _TrackEditorScreenState extends ConsumerState<TrackEditorScreen> {
  late final TextEditingController _nameController;
  late Cell _start;
  late Heading _startHeading;
  late Cell _goal;
  late Set<Cell> _obstacles;
  _EditorTool _tool = _EditorTool.obstacle;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final track = widget.track;
    _nameController = TextEditingController(text: track?.name ?? '');
    _start = track?.start ?? const Cell(2, 6);
    _startHeading = track?.startHeading ?? Heading.up;
    _goal = track?.goal ?? const Cell(2, 1);
    _obstacles = {...?track?.obstacles};
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  BoardLevel get _level => BoardLevel(
        name: _nameController.text.trim(),
        start: _start,
        startHeading: _startHeading,
        goal: _goal,
        obstacles: _obstacles,
      );

  int? get _optimalCards => findOptimalCommands(_level)?.length;

  void _onCellTap(Cell cell) {
    setState(() {
      switch (_tool) {
        case _EditorTool.start:
          if (cell == _start) {
            // Tocar el inicio otra vez gira al robot.
            _startHeading = _startHeading.turnedRight;
          } else if (cell != _goal) {
            _start = cell;
            _obstacles.remove(cell);
          }
        case _EditorTool.goal:
          if (cell != _start) {
            _goal = cell;
            _obstacles.remove(cell);
          }
        case _EditorTool.obstacle:
          if (cell == _start || cell == _goal) {
            return;
          }
          if (_obstacles.contains(cell)) {
            _obstacles.remove(cell);
          } else {
            _obstacles.add(cell);
          }
        case _EditorTool.erase:
          _obstacles.remove(cell);
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a la pista.')),
      );
      return;
    }
    if (_optimalCards == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La meta no se puede alcanzar. Quita algún obstáculo.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final error = await ref.read(tracksProvider.notifier).save(
          TrackInfo(
            id: widget.track?.id ?? '',
            name: name,
            start: _start,
            startHeading: _startHeading,
            goal: _goal,
            obstacles: _obstacles,
          ),
        );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    context.go(TracksScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final optimal = _optimalCards;
    final wide = MediaQuery.sizeOf(context).width >= 760;

    final board = _EditorBoard(
      start: _start,
      startHeading: _startHeading,
      goal: _goal,
      obstacles: _obstacles,
      onCellTap: _onCellTap,
    );

    final sidePanel = _SidePanel(
      nameController: _nameController,
      tool: _tool,
      onToolChanged: (tool) => setState(() => _tool = tool),
      optimalCards: optimal,
      obstacleCount: _obstacles.length,
      saving: _saving,
      onSave: _save,
      isNew: widget.track == null,
    );

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: ArcobotPanelColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ArcobotPanelColors.textOnDark,
          leading: IconButton(
            onPressed: () => context.go(TracksScreen.routePath),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            widget.track == null ? 'Nueva pista' : 'Editar pista',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: wide
              ? Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(child: board),
                      ),
                    ),
                    SizedBox(
                      width: 340,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                        child: sidePanel,
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      sidePanel,
                      const SizedBox(height: 20),
                      board,
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.nameController,
    required this.tool,
    required this.onToolChanged,
    required this.optimalCards,
    required this.obstacleCount,
    required this.saving,
    required this.onSave,
    required this.isNew,
  });

  final TextEditingController nameController;
  final _EditorTool tool;
  final ValueChanged<_EditorTool> onToolChanged;
  final int? optimalCards;
  final int obstacleCount;
  final bool saving;
  final VoidCallback onSave;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArcobotPanelColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArcobotPanelColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOMBRE DE LA PISTA',
            style: TextStyle(
              color: ArcobotPanelColors.subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            maxLength: 60,
            style: const TextStyle(
              color: ArcobotPanelColors.textOnDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Ej. El laberinto del 2°B',
              counterText: '',
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'HERRAMIENTA',
            style: TextStyle(
              color: ArcobotPanelColors.subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToolChip(
                label: 'Inicio',
                icon: Icons.navigation_rounded,
                color: ArcobotColors.guideTurquoise,
                selected: tool == _EditorTool.start,
                onTap: () => onToolChanged(_EditorTool.start),
              ),
              _ToolChip(
                label: 'Meta',
                icon: Icons.flag_rounded,
                color: ArcobotColors.sunYellow,
                selected: tool == _EditorTool.goal,
                onTap: () => onToolChanged(_EditorTool.goal),
              ),
              _ToolChip(
                label: 'Obstáculo',
                icon: Icons.block_rounded,
                color: ArcobotColors.coral,
                selected: tool == _EditorTool.obstacle,
                onTap: () => onToolChanged(_EditorTool.obstacle),
              ),
              _ToolChip(
                label: 'Borrar',
                icon: Icons.cleaning_services_rounded,
                color: ArcobotPanelColors.subtle,
                selected: tool == _EditorTool.erase,
                onTap: () => onToolChanged(_EditorTool.erase),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tool == _EditorTool.start
                ? 'Toca una celda para mover el inicio. Toca el inicio '
                    'otra vez para girar al robot.'
                : tool == _EditorTool.goal
                    ? 'Toca una celda para mover la meta.'
                    : tool == _EditorTool.obstacle
                        ? 'Toca celdas para poner o quitar obstáculos.'
                        : 'Toca un obstáculo para quitarlo.',
            style: const TextStyle(
              color: ArcobotPanelColors.hint,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: optimalCards == null
                  ? ArcobotPanelColors.errorSurface
                  : ArcobotPanelColors.input,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: optimalCards == null
                    ? ArcobotPanelColors.errorBorder
                    : ArcobotPanelColors.border,
                width: 0.5,
              ),
            ),
            child: Text(
              optimalCards == null
                  ? '⚠ La meta no se puede alcanzar. Quita algún obstáculo.'
                  : 'Ruta óptima: $optimalCards tarjetas · '
                      '$obstacleCount obstáculos',
              style: TextStyle(
                color: optimalCards == null
                    ? ArcobotPanelColors.errorText
                    : ArcobotPanelColors.subtle,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ArcobotPanelColors.onAccent,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                saving
                    ? 'Guardando...'
                    : (isNew ? 'Guardar pista' : 'Guardar cambios'),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? color.withValues(alpha: 0.16) : ArcobotPanelColors.input,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : ArcobotPanelColors.border,
              width: selected ? 1.2 : 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? ArcobotPanelColors.textOnDark
                      : ArcobotPanelColors.subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tablero del editor: el mismo `BoardWidget` del juego (apaisado, paleta
/// docente); los taps se mapean de la celda visual a la celda lógica 5×8.
class _EditorBoard extends StatelessWidget {
  const _EditorBoard({
    required this.start,
    required this.startHeading,
    required this.goal,
    required this.obstacles,
    required this.onCellTap,
  });

  final Cell start;
  final Heading startHeading;
  final Cell goal;
  final Set<Cell> obstacles;
  final ValueChanged<Cell> onCellTap;

  @override
  Widget build(BuildContext context) {
    final level = BoardLevel(
      name: '',
      start: start,
      startHeading: startHeading,
      goal: goal,
      obstacles: obstacles,
    );
    return AspectRatio(
      aspectRatio: kVisualCols / kVisualRows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellW = constraints.maxWidth / kVisualCols;
          final cellH = constraints.maxHeight / kVisualRows;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final visual = Cell(
                (details.localPosition.dx / cellW)
                    .floor()
                    .clamp(0, kVisualCols - 1),
                (details.localPosition.dy / cellH)
                    .floor()
                    .clamp(0, kVisualRows - 1),
              );
              onCellTap(logicalCellFromVisual(visual));
            },
            child: BoardWidget(
              level: level,
              robot: level.initialState,
              ghostCells: const [],
              showGhost: false,
              celebrating: false,
              crashed: false,
              style: BoardStyle.panel,
            ),
          );
        },
      ),
    );
  }
}
