import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/app_theme.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/core/widgets/arco_avatar.dart';
import 'package:front_arcobot/core/widgets/arco_character.dart';
import 'package:front_arcobot/features/dashboard/presentation/dashboard_screen.dart';
import 'package:front_arcobot/features/sessions/domain/session_models.dart';
import 'package:front_arcobot/features/sessions/presentation/live_board_view.dart';
import 'package:front_arcobot/features/sessions/presentation/teacher_session_provider.dart';
import 'package:front_arcobot/features/simulator/presentation/command_blocks.dart';
import 'package:front_arcobot/features/tracks/domain/track_models.dart';
import 'package:front_arcobot/features/tracks/presentation/track_preview.dart';
import 'package:front_arcobot/features/tracks/presentation/tracks_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Vista del docente durante la clase: por defecto el monitor de
/// seguimiento; la proyección (PIN gigante) se activa para el aula.
enum _SessionViewMode { monitor, projection }

class TeacherSessionScreen extends ConsumerStatefulWidget {
  const TeacherSessionScreen({super.key});

  static const routePath = '/teacher/session';

  @override
  ConsumerState<TeacherSessionScreen> createState() =>
      _TeacherSessionScreenState();
}

class _TeacherSessionScreenState extends ConsumerState<TeacherSessionScreen> {
  late final TextEditingController _nameController;
  final Set<String> _selectedTrackIds = {};
  _SessionViewMode _viewMode = _SessionViewMode.projection;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Mi clase');
    ref.read(teacherSessionProvider.notifier).attachMonitor();
  }

  @override
  void dispose() {
    ref.read(teacherSessionProvider.notifier).detachMonitor();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final tracks = ref.read(tracksProvider).valueOrNull ?? const [];
    // Conserva el orden de la biblioteca, no el orden de selección.
    final trackIds = [
      for (final track in tracks)
        if (_selectedTrackIds.contains(track.id)) track.id,
    ];
    final created = await ref.read(teacherSessionProvider.notifier).create(
          name: name.isEmpty ? 'Mi clase' : name,
          trackIds: trackIds,
        );
    if (created && mounted) {
      // Al crear, arranca proyectando el PIN para que la clase entre.
      setState(() => _viewMode = _SessionViewMode.projection);
    }
  }

  Future<void> _confirmEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Terminar la sesión?'),
        content: const Text(
          'Los estudiantes saldrán de la clase y el PIN dejará de funcionar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: ArcobotColors.coral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(teacherSessionProvider.notifier).end();
    if (mounted) {
      context.go(DashboardScreen.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherSessionProvider);

    if (state.status == TeacherSessionStatus.active ||
        state.status == TeacherSessionStatus.ending) {
      if (_viewMode == _SessionViewMode.projection) {
        return _ProjectionView(
          state: state,
          onEnd: _confirmEnd,
          onMonitor: () => setState(() => _viewMode = _SessionViewMode.monitor),
        );
      }
      return _MonitorView(
        state: state,
        onEnd: _confirmEnd,
        onProject: () =>
            setState(() => _viewMode = _SessionViewMode.projection),
        onBack: () => context.go(DashboardScreen.routePath),
      );
    }

    return _CreateView(
      nameController: _nameController,
      creating: state.status == TeacherSessionStatus.creating,
      errorMessage: state.errorMessage,
      selectedTrackIds: _selectedTrackIds,
      onToggleTrack: (id) => setState(() {
        if (!_selectedTrackIds.remove(id)) {
          _selectedTrackIds.add(id);
        }
      }),
      onCreate: _create,
      onBack: () => context.go(DashboardScreen.routePath),
    );
  }
}

/// Fase 1: formulario del docente (tema oscuro del panel).
class _CreateView extends ConsumerWidget {
  const _CreateView({
    required this.nameController,
    required this.creating,
    required this.errorMessage,
    required this.selectedTrackIds,
    required this.onToggleTrack,
    required this.onCreate,
    required this.onBack,
  });

  final TextEditingController nameController;
  final bool creating;
  final String? errorMessage;
  final Set<String> selectedTrackIds;
  final ValueChanged<String> onToggleTrack;
  final VoidCallback onCreate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksState = ref.watch(tracksProvider);

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: ArcobotPanelColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ArcobotPanelColors.textOnDark,
          leading: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Nueva sesión de aula',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: ArcobotPanelColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: ArcobotPanelColors.border,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Crea una sesión para tu clase',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Se generará un PIN de 6 dígitos y un código QR. '
                      'Proyéctalos para que tus estudiantes entren.',
                      style: TextStyle(
                        color: ArcobotPanelColors.subtle,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ArcobotPanelColors.errorSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ArcobotPanelColors.errorBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: ArcobotPanelColors.errorText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const Text(
                      'NOMBRE DE LA SESIÓN',
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
                      enabled: !creating,
                      maxLength: 60,
                      style: const TextStyle(
                        color: ArcobotPanelColors.textOnDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ej. Matemáticas 2°B',
                        counterText: '',
                      ),
                      onSubmitted: (_) => onCreate(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'PISTAS DE LA SESIÓN',
                      style: TextStyle(
                        color: ArcobotPanelColors.subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TrackPicker(
                      tracksState: tracksState,
                      selectedTrackIds: selectedTrackIds,
                      enabled: !creating,
                      onToggleTrack: onToggleTrack,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: creating ? null : onCreate,
                        icon: creating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ArcobotPanelColors.onAccent,
                                ),
                              )
                            : const Icon(Icons.cast_for_education_rounded,
                                size: 18),
                        label: Text(
                          creating ? 'Creando...' : 'Crear sesión',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector de pistas propias para la sesión. Sin selección se usan las
/// pistas de demostración incluidas en la app.
class _TrackPicker extends StatelessWidget {
  const _TrackPicker({
    required this.tracksState,
    required this.selectedTrackIds,
    required this.enabled,
    required this.onToggleTrack,
  });

  final AsyncValue<List<TrackInfo>> tracksState;
  final Set<String> selectedTrackIds;
  final bool enabled;
  final ValueChanged<String> onToggleTrack;

  @override
  Widget build(BuildContext context) {
    return tracksState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ArcobotPanelColors.accent,
            ),
          ),
        ),
      ),
      error: (_, __) => const Text(
        'No se pudieron cargar tus pistas. La sesión usará las pistas '
        'de demostración.',
        style: TextStyle(
          color: ArcobotPanelColors.hint,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Text(
            'Aún no tienes pistas propias: la sesión usará las pistas de '
            'demostración. Créalas en "Mis pistas".',
            style: TextStyle(
              color: ArcobotPanelColors.hint,
              fontSize: 12.5,
              height: 1.4,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 230),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final track in tracks)
                      _TrackPickerTile(
                        track: track,
                        selected: selectedTrackIds.contains(track.id),
                        enabled: enabled,
                        onTap: () => onToggleTrack(track.id),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedTrackIds.isEmpty
                  ? 'Sin selección se usarán las pistas de demostración.'
                  : '${selectedTrackIds.length} pista'
                      '${selectedTrackIds.length == 1 ? '' : 's'} '
                      'seleccionada${selectedTrackIds.length == 1 ? '' : 's'}.',
              style: const TextStyle(
                color: ArcobotPanelColors.hint,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrackPickerTile extends StatelessWidget {
  const _TrackPickerTile({
    required this.track,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final TrackInfo track;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? ArcobotColors.guideTurquoise.withValues(alpha: 0.10)
            : ArcobotPanelColors.input,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? ArcobotColors.guideTurquoise
                    : ArcobotPanelColors.border,
                width: selected ? 1.2 : 0.5,
              ),
            ),
            child: Row(
              children: [
                TrackPreview(
                  start: track.start,
                  startHeading: track.startHeading,
                  goal: track.goal,
                  obstacles: track.obstacles,
                  cellSize: 7,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ArcobotPanelColors.textOnDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected
                      ? ArcobotColors.guideTurquoise
                      : ArcobotPanelColors.hint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Monitor del docente: seguimiento en vivo de cada estudiante.
class _MonitorView extends StatelessWidget {
  const _MonitorView({
    required this.state,
    required this.onEnd,
    required this.onProject,
    required this.onBack,
  });

  final TeacherSessionState state;
  final VoidCallback onEnd;
  final VoidCallback onProject;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final session = state.session!;
    final students = state.students;
    final ending = state.status == TeacherSessionStatus.ending;
    final totalSuccesses = students.fold<int>(0, (sum, s) => sum + s.successes);
    final playingNow = students
        .where((s) =>
            s.lastActivityAt != null &&
            DateTime.now().difference(s.lastActivityAt!) <
                const Duration(minutes: 2))
        .length;

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: ArcobotPanelColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ArcobotPanelColors.textOnDark,
          leading: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Volver al panel (la sesión sigue activa)',
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  session.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ArcobotPanelColors.input,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ArcobotPanelColors.border,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'PIN ${session.pin}',
                  style: const TextStyle(
                    color: ArcobotColors.guideTurquoise,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: onProject,
              icon: const Icon(Icons.connected_tv_rounded, size: 16),
              label: const Text('Proyectar PIN'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: ending ? null : onEnd,
              icon: const Icon(Icons.stop_circle_outlined, size: 16),
              label: Text(ending ? 'Terminando...' : 'Terminar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ArcobotPanelColors.errorText,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatChip(
                    icon: Icons.group_rounded,
                    label: '${students.length} en clase',
                    color: ArcobotColors.skyBlue,
                  ),
                  _StatChip(
                    icon: Icons.bolt_rounded,
                    label: '$playingNow activos ahora',
                    color: ArcobotColors.guideTurquoise,
                  ),
                  _StatChip(
                    icon: Icons.emoji_events_rounded,
                    label: '$totalSuccesses metas logradas',
                    color: ArcobotColors.sunYellow,
                  ),
                  _StatChip(
                    icon: state.liveConnected
                        ? Icons.wifi_tethering_rounded
                        : Icons.wifi_tethering_off_rounded,
                    label: state.liveConnected
                        ? 'Tiempo real'
                        : 'Actualizando cada 3 s',
                    color: state.liveConnected
                        ? ArcobotColors.successGreen
                        : ArcobotColors.sunYellow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: students.isEmpty
                  ? const _MonitorEmpty()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            (constraints.maxWidth / 330).floor().clamp(1, 4);
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisExtent: 118,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: students.length,
                          itemBuilder: (context, index) => _StudentMonitorCard(
                            key: ValueKey(students[index].id),
                            student: students[index],
                            onTap: () => _showStudentLiveDialog(
                              context,
                              students[index].id,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ArcobotPanelColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ArcobotPanelColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: ArcobotPanelColors.textOnDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitorEmpty extends StatelessWidget {
  const _MonitorEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 44,
            color: ArcobotPanelColors.hint,
          ),
          SizedBox(height: 12),
          Text(
            'Esperando estudiantes...',
            style: TextStyle(
              color: ArcobotPanelColors.textOnDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Proyecta el PIN para que entren a la clase.',
            style: TextStyle(
              color: ArcobotPanelColors.subtle,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre el "ojo en la pantalla": réplica en vivo del simulador del niño.
/// Con WebSocket conectado se refresca al instante; sin él, cada 3 s.
Future<void> _showStudentLiveDialog(
  BuildContext context,
  String studentId,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => Theme(
      data: AppTheme.dark,
      child: Consumer(
        builder: (context, ref, _) {
          final sessionState = ref.watch(teacherSessionProvider);
          SessionStudentInfo? student;
          for (final item in sessionState.students) {
            if (item.id == studentId) {
              student = item;
              break;
            }
          }
          if (student == null) {
            // El estudiante salió de la sesión: cerramos el ojo.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
            return const SizedBox.shrink();
          }
          return _StudentLiveDialog(
            student: student,
            realtime: sessionState.liveConnected,
          );
        },
      ),
    ),
  );
}

class _StudentLiveDialog extends StatelessWidget {
  const _StudentLiveDialog({required this.student, required this.realtime});

  final SessionStudentInfo student;

  /// true = WebSocket conectado (actualización instantánea).
  final bool realtime;

  (String, Color) get _phaseInfo {
    switch (student.live?.phase) {
      case 'running':
        return ('Ejecutando su programa', ArcobotColors.skyBlue);
      case 'success':
        return ('¡Llegó a la meta!', ArcobotColors.successGreen);
      case 'blocked':
        return ('Chocó — corrigiendo', ArcobotColors.coral);
      case 'editing':
        return ('Armando su programa', ArcobotColors.guideTurquoise);
      default:
        return ('Sin señal todavía', ArcobotPanelColors.subtle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = student.live;
    final (phaseLabel, phaseColor) = _phaseInfo;

    return Dialog(
      backgroundColor: ArcobotPanelColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: ArcobotPanelColors.border, width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ArcoAvatar(avatarId: student.avatar, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.alias,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ArcobotPanelColors.textOnDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          student.lastTrack == null
                              ? 'Sin pista abierta'
                              : 'Pista: ${student.lastTrack}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ArcobotPanelColors.subtle,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: ArcobotPanelColors.subtle,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: phaseColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        phaseLabel,
                        style: TextStyle(
                          color: phaseColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      realtime ? 'TIEMPO REAL' : 'CADA 3 SEG',
                      style: TextStyle(
                        color: phaseColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (live == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Este estudiante todavía no abre el simulador.\n'
                      'Su pantalla aparecerá aquí en cuanto juegue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ArcobotPanelColors.subtle,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
              else ...[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: LiveBoardView(live: live),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SU PROGRAMA',
                  style: TextStyle(
                    color: ArcobotPanelColors.subtle,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                live.program.isEmpty
                    ? const Text(
                        'Todavía no pone tarjetas.',
                        style: TextStyle(
                          color: ArcobotPanelColors.hint,
                          fontSize: 12.5,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final (index, command) in live.program.indexed)
                            _LiveProgramCard(
                              visual: CommandVisual.of(command),
                              active: index == live.activeStep,
                              done: live.activeStep != null &&
                                  index < live.activeStep!,
                            ),
                        ],
                      ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _MiniMetric(
                    icon: Icons.replay_rounded,
                    value: '${student.attempts}',
                    label: 'intentos',
                  ),
                  const SizedBox(width: 14),
                  _MiniMetric(
                    icon: Icons.emoji_events_rounded,
                    value: '${student.successes}',
                    label: 'logros',
                  ),
                  const Spacer(),
                  if (student.lastActivityAt != null)
                    Text(
                      _liveTimeAgo(student.lastActivityAt!),
                      style: const TextStyle(
                        color: ArcobotPanelColors.hint,
                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta del programa del niño vista por el docente: mismo color e
/// icono que ve el niño; la activa brilla, las ya ejecutadas se apagan.
class _LiveProgramCard extends StatelessWidget {
  const _LiveProgramCard({
    required this.visual,
    required this.active,
    required this.done,
  });

  final CommandVisual visual;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: active
            ? visual.color
            : visual.color.withValues(alpha: done ? 0.10 : 0.22),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: active
              ? visual.color
              : visual.color.withValues(alpha: done ? 0.25 : 0.55),
          width: active ? 1.5 : 0.8,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: visual.color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Icon(
        visual.icon,
        size: 19,
        color: active
            ? Colors.white
            : visual.color.withValues(alpha: done ? 0.45 : 0.95),
      ),
    );
  }
}

String _liveTimeAgo(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inSeconds < 15) {
    return 'actualizado ahora';
  }
  if (diff.inMinutes < 1) {
    return 'hace ${diff.inSeconds} s';
  }
  if (diff.inHours < 1) {
    return 'hace ${diff.inMinutes} min';
  }
  return 'hace ${diff.inHours} h';
}

/// Tarjeta de seguimiento de un estudiante en el monitor.
class _StudentMonitorCard extends StatelessWidget {
  const _StudentMonitorCard({
    required this.student,
    required this.onTap,
    super.key,
  });

  final SessionStudentInfo student;
  final VoidCallback onTap;

  (String, Color) get _statusInfo {
    switch (student.lastOutcome) {
      case StudentOutcome.playing:
        return ('Jugando', ArcobotColors.skyBlue);
      case StudentOutcome.success:
        return ('¡Meta lograda!', ArcobotColors.successGreen);
      case StudentOutcome.blocked:
        return ('Chocó, reintentando', ArcobotColors.coral);
      case null:
        return ('Recién entró', ArcobotPanelColors.subtle);
    }
  }

  String get _activityLabel {
    final at = student.lastActivityAt;
    if (at == null) {
      return 'sin actividad aún';
    }
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 15) {
      return 'ahora mismo';
    }
    if (diff.inMinutes < 1) {
      return 'hace ${diff.inSeconds} s';
    }
    if (diff.inHours < 1) {
      return 'hace ${diff.inMinutes} min';
    }
    return 'hace ${diff.inHours} h';
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusInfo;

    return Material(
      color: ArcobotPanelColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ArcobotPanelColors.border, width: 0.5),
          ),
          child: _cardContent(statusLabel, statusColor),
        ),
      ),
    );
  }

  Widget _cardContent(String statusLabel, Color statusColor) {
    final live = student.live;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Mini pantalla en vivo: el docente ve todos los tableros de un
        // vistazo sin abrir el detalle.
        if (live != null) ...[
          TrackPreview(
            start: live.start,
            startHeading: live.startHeading,
            goal: live.goal,
            obstacles: live.obstacles,
            robotCell: live.robotCell,
            robotHeading: live.robotHeading,
            cellSize: 8,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(child: _cardInfo(statusLabel, statusColor)),
      ],
    );
  }

  Widget _cardInfo(String statusLabel, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ArcoAvatar(avatarId: student.avatar, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.alias,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ArcobotPanelColors.textOnDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    student.lastTrack == null
                        ? 'Todavía no abre una pista'
                        : 'Pista: ${student.lastTrack}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ArcobotPanelColors.subtle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            _MiniMetric(
              icon: Icons.replay_rounded,
              value: '${student.attempts}',
              label: 'intentos',
            ),
            const SizedBox(width: 14),
            _MiniMetric(
              icon: Icons.emoji_events_rounded,
              value: '${student.successes}',
              label: 'logros',
            ),
            const Spacer(),
            Flexible(
              child: Text(
                _activityLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ArcobotPanelColors.hint,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ArcobotPanelColors.subtle),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: const TextStyle(
            color: ArcobotPanelColors.subtle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Proyección para el aula: clara, gigante, pensada para que los niños
/// lean el PIN desde lejos.
class _ProjectionView extends StatelessWidget {
  const _ProjectionView({
    required this.state,
    required this.onEnd,
    required this.onMonitor,
  });

  final TeacherSessionState state;
  final VoidCallback onEnd;
  final VoidCallback onMonitor;

  @override
  Widget build(BuildContext context) {
    final session = state.session!;
    final wide = MediaQuery.sizeOf(context).width >= 860;

    final pinPanel = _PinPanel(
      pin: session.pin,
      name: session.name,
      ending: state.status == TeacherSessionStatus.ending,
      onEnd: onEnd,
      onMonitor: onMonitor,
    );
    final studentsPanel = _StudentsPanel(students: state.students);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: ArcobotColors.screenGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: pinPanel),
                      const SizedBox(width: 20),
                      Expanded(flex: 6, child: studentsPanel),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        pinPanel,
                        const SizedBox(height: 20),
                        SizedBox(height: 420, child: studentsPanel),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PinPanel extends StatelessWidget {
  const _PinPanel({
    required this.pin,
    required this.name,
    required this.ending,
    required this.onEnd,
    required this.onMonitor,
  });

  final String pin;
  final String name;
  final bool ending;
  final VoidCallback onEnd;
  final VoidCallback onMonitor;

  String get _formattedPin =>
      pin.length == 6 ? '${pin.substring(0, 3)} ${pin.substring(3)}' : pin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ArcobotRadii.xl),
        border: Border.all(color: ArcobotColors.softBorder),
        boxShadow: ArcobotShadows.soft,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ArcobotColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Entra con este código:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ArcobotColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formattedPin,
              style: const TextStyle(
                color: ArcobotColors.guideTurquoise,
                fontSize: 96,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ArcobotColors.softBorder, width: 2),
            ),
            child: QrImageView(
              data: pin,
              version: QrVersions.auto,
              size: 190,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: ArcobotColors.textPrimary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: ArcobotColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'o escanea el QR con la app',
            style: TextStyle(
              color: ArcobotColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onMonitor,
                icon: const Icon(Icons.monitor_heart_rounded, size: 18),
                label: const Text('Ir al monitor'),
                style: FilledButton.styleFrom(
                  backgroundColor: ArcobotColors.guideTurquoise,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: ending ? null : onEnd,
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: Text(ending ? 'Terminando...' : 'Terminar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArcobotColors.coral,
                  side:
                      const BorderSide(color: ArcobotColors.coral, width: 1.5),
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _StudentsPanel extends StatelessWidget {
  const _StudentsPanel({required this.students});

  final List<SessionStudentInfo> students;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ArcobotRadii.xl),
        border: Border.all(color: ArcobotColors.softBorder),
        boxShadow: ArcobotShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Estudiantes',
                style: TextStyle(
                  color: ArcobotColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ArcobotColors.guideTurquoise,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${students.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: students.isEmpty
                ? const _EmptyStudents()
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        for (final student in students)
                          _StudentChip(
                            key: ValueKey(student.id),
                            alias: student.alias,
                            avatar: student.avatar,
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStudents extends StatelessWidget {
  const _EmptyStudents();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          ArcoCharacterView(
            character: ArcoCharacter.bussy,
            mood: ArcoMood.waiting,
            size: 110,
          ),
          SizedBox(height: 12),
          Text(
            'Esperando estudiantes...',
            style: TextStyle(
              color: ArcobotColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentChip extends StatelessWidget {
  const _StudentChip({
    required this.alias,
    required this.avatar,
    super.key,
  });

  final String alias;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ArcobotColors.softBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArcoAvatar(avatarId: avatar, size: 38),
            const SizedBox(width: 10),
            Text(
              alias,
              style: const TextStyle(
                color: ArcobotColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
