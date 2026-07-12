import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/core/widgets/arco_character.dart';
import 'package:front_arcobot/features/simulator/presentation/board_widget.dart';
import 'package:front_arcobot/features/simulator/presentation/command_blocks.dart';
import 'package:front_arcobot/features/simulator/presentation/simulator_provider.dart';
import 'package:go_router/go_router.dart';

/// En móvil el juego se vive en horizontal: pantalla completa e inmersiva,
/// tablero a la izquierda y tarjetas a la derecha, como una consola.
bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

bool _isWideLayout(Size size) => size.width >= 760 || size.width > size.height;

class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});

  static const routePath = '/play';

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen> {
  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    if (_isMobile) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulatorProvider);
    final controller = ref.read(simulatorProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final wide = _isWideLayout(size);

    final board = BoardWidget(
      level: state.level,
      robot: state.robot,
      ghostCells: state.phase == SimPhase.editing ? state.ghostCells : const [],
      showGhost: state.showGhost,
      celebrating: state.phase == SimPhase.success,
      crashed: state.phase == SimPhase.blocked,
    );

    final controls = _ControlsPanel(state: state, controller: controller);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.92, -0.64),
            end: Alignment(0.92, 0.64),
            colors: ArcobotKidColors.screenGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                // Tablero protagonista: llena la altura; panel de tarjetas
                // con ancho fijo a la derecha. Sin espacios muertos.
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: Center(child: board)),
                          const SizedBox(width: 16),
                          SizedBox(
                            width:
                                (size.width * 0.34).clamp(300.0, 420.0),
                            child: Center(
                              child: SingleChildScrollView(child: controls),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _TopBar(state: state, controller: controller),
                          const SizedBox(height: 8),
                          Expanded(child: Center(child: board)),
                          const SizedBox(height: 8),
                          controls,
                        ],
                      ),
              ),
              if (state.phase == SimPhase.success)
                _ResultOverlay.success(
                  hasShorterRoute: state.hasShorterRoute,
                  optimalCount: state.optimalCount,
                  usedCount: state.lastRunSteps,
                  onNext: controller.nextLevel,
                  onRetry: controller.restartLevel,
                ),
              if (state.phase == SimPhase.blocked)
                _ResultOverlay.blocked(onRetry: controller.resetRun),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.controller});

  final SimulatorState state;
  final SimulatorController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArcobotKidColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            state.level.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ArcobotKidColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Ver ruta fantasma',
          onPressed: controller.toggleGhost,
          icon: Icon(
            state.showGhost
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: state.showGhost
                ? ArcobotColors.skyBlue
                : ArcobotKidColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({required this.state, required this.controller});

  final SimulatorState state;
  final SimulatorController controller;

  @override
  Widget build(BuildContext context) {
    final editing = state.phase == SimPhase.editing;
    final wide = _isWideLayout(MediaQuery.sizeOf(context));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F2F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide) ...[
            _TopBar(state: state, controller: controller),
            const SizedBox(height: 10),
          ],
          ProgramStrip(
            program: state.program,
            enabled: editing,
            activeIndex: state.activeStep,
            onDropAdd: controller.addCommand,
            onRemoveAt: controller.removeCommandAt,
          ),
          const SizedBox(height: 14),
          CommandPalette(
            enabled: editing,
            onAdd: controller.addCommand,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                tooltip: 'Borrar todo',
                onPressed:
                    editing && state.program.isNotEmpty
                        ? controller.clearProgram
                        : null,
                icon: const Icon(Icons.delete_outline_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: ArcobotColors.coral,
                  backgroundColor: const Color(0xFFFFF0F0),
                  minimumSize: const Size(52, 52),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.canRun ? controller.run : null,
                  icon: Icon(
                    state.phase == SimPhase.running
                        ? Icons.directions_run_rounded
                        : Icons.play_arrow_rounded,
                    size: 26,
                  ),
                  label: Text(
                    state.phase == SimPhase.running ? '¡Vamos!' : 'Jugar',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ArcobotKidColors.action,
                    disabledBackgroundColor:
                        ArcobotKidColors.action.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 56),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay.success({
    required this.hasShorterRoute,
    required this.optimalCount,
    required this.usedCount,
    required VoidCallback onNext,
    required this.onRetry,
  })  : success = true,
        onPrimary = onNext;

  const _ResultOverlay.blocked({required this.onRetry})
      : success = false,
        hasShorterRoute = false,
        optimalCount = null,
        usedCount = 0,
        onPrimary = onRetry;

  final bool success;
  final bool hasShorterRoute;
  final int? optimalCount;
  final int usedCount;
  final VoidCallback onPrimary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x66103040),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ArcoCharacterView(
                    character: ArcoCharacter.bussy,
                    mood: success ? ArcoMood.celebrating : ArcoMood.sad,
                    size: 110,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    success ? '¡Lo lograste!' : '¡Ups! Casi...',
                    style: const TextStyle(
                      color: ArcobotKidColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (success && hasShorterRoute) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFE2A8)),
                      ),
                      child: Text(
                        // Optimizador de Algoritmos: sugiere la ruta corta.
                        '💡 Usaste $usedCount tarjetas. '
                        '¡Se puede con $optimalCount!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF9A6B00),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (success)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onRetry,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              side: const BorderSide(
                                color: ArcobotColors.softBorder,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Icon(
                              Icons.replay_rounded,
                              color: ArcobotKidColors.textSecondary,
                            ),
                          ),
                        ),
                      if (success) const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: onPrimary,
                          icon: Icon(
                            success
                                ? Icons.arrow_forward_rounded
                                : Icons.build_rounded,
                          ),
                          label: Text(success ? 'Siguiente' : 'Arreglar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: success
                                ? ArcobotColors.successGreen
                                : ArcobotKidColors.action,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 52),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
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
