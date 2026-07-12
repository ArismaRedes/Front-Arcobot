import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/app_theme.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/dashboard/presentation/dashboard_screen.dart';
import 'package:front_arcobot/features/sessions/data/group_repository.dart';
import 'package:front_arcobot/features/sessions/domain/report_models.dart';
import 'package:front_arcobot/features/sessions/presentation/groups_provider.dart';
import 'package:front_arcobot/features/sessions/presentation/session_report_dialog.dart';
import 'package:go_router/go_router.dart';

/// Grupos (cursos) del docente: historial de clases y analíticas por grupo.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  static const routePath = '/teacher/groups';

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  GroupInfo? _selected;

  Future<void> _createGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ArcobotPanelColors.card,
        title: const Text(
          'Nuevo grupo',
          style: TextStyle(
            color: ArcobotPanelColors.textOnDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          style: const TextStyle(
            color: ArcobotPanelColors.textOnDark,
            fontSize: 14,
          ),
          decoration: const InputDecoration(
            hintText: 'Ej. 2°B',
            counterText: '',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) {
      return;
    }
    try {
      await ref.read(groupRepositoryProvider).createGroup(name);
      ref.invalidate(groupsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear el grupo.')),
        );
      }
    }
  }

  Future<void> _deleteGroup(GroupInfo group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ArcobotPanelColors.card,
        title: const Text(
          '¿Borrar grupo?',
          style: TextStyle(
            color: ArcobotPanelColors.textOnDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Se borrará "${group.name}". Las clases del historial quedarán '
          'sueltas (no se pierden).',
          style: const TextStyle(
            color: ArcobotPanelColors.subtle,
            fontSize: 13.5,
          ),
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
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(group.id);
      ref.invalidate(groupsProvider);
      if (_selected?.id == group.id) {
        setState(() => _selected = null);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo borrar el grupo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsProvider);
    final selected = _selected;

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: ArcobotPanelColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ArcobotPanelColors.textOnDark,
          leading: IconButton(
            onPressed: () {
              if (selected != null) {
                setState(() => _selected = null);
              } else {
                context.go(DashboardScreen.routePath);
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            selected == null ? 'Mis grupos' : selected.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          actions: [
            if (selected == null)
              IconButton(
                tooltip: 'Crear grupo',
                onPressed: _createGroup,
                icon: const Icon(
                  Icons.add_rounded,
                  color: ArcobotColors.guideTurquoise,
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: selected == null
              ? _GroupList(
                  groupsState: groupsState,
                  onOpen: (group) => setState(() => _selected = group),
                  onDelete: _deleteGroup,
                  onCreate: _createGroup,
                )
              : _GroupHistory(groupId: selected.id),
        ),
      ),
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({
    required this.groupsState,
    required this.onOpen,
    required this.onDelete,
    required this.onCreate,
  });

  final AsyncValue<List<GroupInfo>> groupsState;
  final ValueChanged<GroupInfo> onOpen;
  final ValueChanged<GroupInfo> onDelete;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return groupsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text(
          'No se pudieron cargar tus grupos.',
          style: TextStyle(color: ArcobotPanelColors.subtle),
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 46,
                  color: ArcobotPanelColors.hint,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Todavía no tienes grupos.',
                  style: TextStyle(
                    color: ArcobotPanelColors.textOnDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Crea un grupo (ej. "2°B") para acumular el historial '
                  'de sus clases.',
                  style: TextStyle(
                    color: ArcobotPanelColors.subtle,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Crear grupo'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: ArcobotPanelColors.card,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onOpen(group),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ArcobotPanelColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: ArcobotColors.guideTurquoise,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ArcobotPanelColors.textOnDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Borrar grupo',
                          onPressed: () => onDelete(group),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: ArcobotPanelColors.hint,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: ArcobotPanelColors.subtle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Historial de clases del grupo; las terminadas abren su podio.
class _GroupHistory extends ConsumerWidget {
  const _GroupHistory({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(groupSessionsProvider(groupId));

    return sessionsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text(
          'No se pudo cargar el historial.',
          style: TextStyle(color: ArcobotPanelColors.subtle),
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(
            child: Text(
              'Este grupo todavía no tiene clases.\n'
              'Elige el grupo al crear una sesión de aula.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ArcobotPanelColors.subtle,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final ended = session.endedAt != null;
            final report = session.report;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: ArcobotPanelColors.card,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: report == null
                      ? null
                      : () => showSessionReportDialog(
                            context,
                            report,
                            title: session.name,
                          ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ArcobotPanelColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ended
                              ? Icons.emoji_events_rounded
                              : Icons.podcasts_rounded,
                          color: ended
                              ? ArcobotColors.sunYellow
                              : ArcobotColors.guideTurquoise,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ArcobotPanelColors.textOnDark,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(session.createdAt)} · '
                                '${session.studentCount} estudiantes'
                                '${ended ? '' : ' · en curso'}',
                                style: const TextStyle(
                                  color: ArcobotPanelColors.subtle,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (report != null)
                          const Text(
                            'Ver podio',
                            style: TextStyle(
                              color: ArcobotColors.guideTurquoise,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
