import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/app_theme.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/dashboard/presentation/dashboard_screen.dart';
import 'package:front_arcobot/features/simulator/domain/path_optimizer.dart';
import 'package:front_arcobot/features/tracks/domain/track_models.dart';
import 'package:front_arcobot/features/tracks/presentation/track_editor_screen.dart';
import 'package:front_arcobot/features/tracks/presentation/track_preview.dart';
import 'package:front_arcobot/features/tracks/presentation/tracks_provider.dart';
import 'package:go_router/go_router.dart';

/// Biblioteca de pistas del docente: listar, crear, editar y borrar.
class TracksScreen extends ConsumerWidget {
  const TracksScreen({super.key});

  static const routePath = '/teacher/tracks';

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TrackInfo track,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar la pista?'),
        content: Text(
          '"${track.name}" se eliminará para siempre. '
          'Las sesiones nuevas ya no podrán usarla.',
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    final error = await ref.read(tracksProvider.notifier).delete(track.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

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
            onPressed: () => context.go(DashboardScreen.routePath),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Mis pistas',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: () => context.go(TrackEditorScreen.routePath),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva pista'),
              ),
            ),
          ],
        ),
        body: tracksState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: ArcobotPanelColors.accent,
            ),
          ),
          error: (error, _) => _ErrorView(
            message: TracksController.friendlyError(error),
            onRetry: () => ref.read(tracksProvider.notifier).load(),
          ),
          data: (tracks) => tracks.isEmpty
              ? _EmptyTracks(
                  onCreate: () => context.go(TrackEditorScreen.routePath),
                )
              : _TracksGrid(
                  tracks: tracks,
                  onEdit: (track) => context.go(
                    TrackEditorScreen.routePath,
                    extra: track,
                  ),
                  onDelete: (track) => _confirmDelete(context, ref, track),
                ),
        ),
      ),
    );
  }
}

class _TracksGrid extends StatelessWidget {
  const _TracksGrid({
    required this.tracks,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TrackInfo> tracks;
  final ValueChanged<TrackInfo> onEdit;
  final ValueChanged<TrackInfo> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 340).floor().clamp(1, 4);
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 152,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: tracks.length,
          itemBuilder: (context, index) => _TrackCard(
            track: tracks[index],
            onEdit: () => onEdit(tracks[index]),
            onDelete: () => onDelete(tracks[index]),
          ),
        );
      },
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.onEdit,
    required this.onDelete,
  });

  final TrackInfo track;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final optimal = findOptimalCommands(track.toBoardLevel())?.length;

    return Material(
      color: ArcobotPanelColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ArcobotPanelColors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrackPreview(
                start: track.start,
                startHeading: track.startHeading,
                goal: track.goal,
                obstacles: track.obstacles,
                cellSize: 15,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ArcobotPanelColors.textOnDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${track.obstacles.length} obstáculos',
                      style: const TextStyle(
                        color: ArcobotPanelColors.subtle,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      optimal == null
                          ? 'Sin solución'
                          : 'Ruta óptima: $optimal tarjetas',
                      style: TextStyle(
                        color: optimal == null
                            ? ArcobotPanelColors.errorText
                            : ArcobotPanelColors.subtle,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _SmallAction(
                          icon: Icons.edit_rounded,
                          label: 'Editar',
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 8),
                        _SmallAction(
                          icon: Icons.delete_outline_rounded,
                          label: 'Eliminar',
                          color: ArcobotPanelColors.errorText,
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color ?? ArcobotPanelColors.subtle,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyTracks extends StatelessWidget {
  const _EmptyTracks({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.route_rounded,
              size: 56,
              color: ArcobotPanelColors.hint,
            ),
            const SizedBox(height: 14),
            const Text(
              'Todavía no tienes pistas',
              style: TextStyle(
                color: ArcobotPanelColors.textOnDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Diseña recorridos para tus estudiantes: elige dónde '
              'empieza el robot, la meta y los obstáculos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ArcobotPanelColors.subtle,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear mi primera pista'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: ArcobotPanelColors.errorText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
