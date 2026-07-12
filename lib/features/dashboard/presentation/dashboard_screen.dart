import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/app_theme.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/sessions/domain/session_models.dart';
import 'package:front_arcobot/features/sessions/presentation/groups_screen.dart';
import 'package:front_arcobot/features/sessions/presentation/teacher_session_provider.dart';
import 'package:front_arcobot/features/sessions/presentation/teacher_session_screen.dart';
import 'package:front_arcobot/features/simulator/presentation/simulator_screen.dart';
import 'package:front_arcobot/features/tracks/presentation/tracks_provider.dart';
import 'package:front_arcobot/features/tracks/presentation/tracks_screen.dart';
import 'package:go_router/go_router.dart';

/// Panel del docente: crear sesiones de aula, diseñar pistas y hacer
/// seguimiento de la clase. Tema oscuro profesional (no infantil).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const routePath = '/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final sessionState = ref.watch(teacherSessionProvider);
    final tracksState = ref.watch(tracksProvider);
    final roleLabel = _humanizeRole(authState.primaryRole);

    final trackCount = tracksState.valueOrNull?.length;
    final hasActiveSession =
        sessionState.status == TeacherSessionStatus.active &&
            sessionState.session != null;

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: ArcobotPanelColors.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _Header(
                    roleLabel: roleLabel,
                    onSignOut: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                  ),
                  const SizedBox(height: 24),
                  if (hasActiveSession) ...[
                    _ActiveSessionBanner(
                      session: sessionState.session!,
                      studentCount: sessionState.students.length,
                      onOpen: () => context.go(TeacherSessionScreen.routePath),
                    ),
                    const SizedBox(height: 16),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 620;
                      final cards = [
                        _ActionCard(
                          icon: Icons.cast_for_education_rounded,
                          iconColor: ArcobotColors.guideTurquoise,
                          title: hasActiveSession
                              ? 'Sesión en curso'
                              : 'Nueva sesión de aula',
                          subtitle: hasActiveSession
                              ? 'Vuelve al monitor de tu clase'
                              : 'Genera un PIN y un QR para que tus '
                                  'estudiantes entren',
                          onTap: () =>
                              context.go(TeacherSessionScreen.routePath),
                        ),
                        _ActionCard(
                          icon: Icons.route_rounded,
                          iconColor: ArcobotColors.skyBlue,
                          title: 'Mis pistas',
                          subtitle: trackCount == null
                              ? 'Diseña los recorridos del robot'
                              : trackCount == 0
                                  ? 'Aún no tienes pistas. ¡Crea la primera!'
                                  : '$trackCount pista'
                                      '${trackCount == 1 ? '' : 's'} guardada'
                                      '${trackCount == 1 ? '' : 's'}',
                          onTap: () => context.go(TracksScreen.routePath),
                        ),
                        _ActionCard(
                          icon: Icons.groups_rounded,
                          iconColor: ArcobotColors.sunYellow,
                          title: 'Mis grupos',
                          subtitle: 'Historial de clases y analíticas '
                              'por curso',
                          onTap: () => context.go(GroupsScreen.routePath),
                        ),
                        _ActionCard(
                          icon: Icons.sports_esports_rounded,
                          iconColor: ArcobotColors.gameLilac,
                          title: 'Probar el simulador',
                          subtitle: 'Juega como lo verán tus estudiantes',
                          onTap: () => context.go(SimulatorScreen.routePath),
                        ),
                      ];

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final card in cards) ...[
                              Expanded(child: card),
                              if (card != cards.last) const SizedBox(width: 14),
                            ],
                          ],
                        );
                      }
                      return Column(
                        children: [
                          for (final card in cards) ...[
                            card,
                            if (card != cards.last) const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const _HowItWorks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _humanizeRole(String? role) {
  if (role == null || role.trim().isEmpty) {
    return null;
  }

  switch (role.trim().toLowerCase()) {
    case 'superadmin':
      return 'Superadmin';
    case 'admin':
      return 'Admin';
    case 'teacher':
    case 'docente':
      return 'Docente';
    case 'member':
      return 'Miembro';
    default:
      return role.trim();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.roleLabel, required this.onSignOut});

  final String? roleLabel;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: ArcobotPanelColors.input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ArcobotPanelColors.border,
              width: 0.5,
            ),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: ArcobotColors.guideTurquoise,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panel del docente',
                style: TextStyle(
                  color: ArcobotPanelColors.textOnDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                roleLabel == null ? 'ArcoBot' : 'ArcoBot · $roleLabel',
                style: const TextStyle(
                  color: ArcobotPanelColors.subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onSignOut,
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout_rounded, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: ArcobotPanelColors.input,
            foregroundColor: ArcobotPanelColors.subtle,
            side: const BorderSide(
              color: ArcobotPanelColors.border,
              width: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({
    required this.session,
    required this.studentCount,
    required this.onOpen,
  });

  final ClassSessionInfo session;
  final int studentCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ArcobotColors.guideTurquoise.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ArcobotColors.guideTurquoise.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ArcobotColors.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesión en curso · ${session.name}',
                      style: const TextStyle(
                        color: ArcobotPanelColors.textOnDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'PIN ${session.pin} · $studentCount estudiante'
                      '${studentCount == 1 ? '' : 's'} conectado'
                      '${studentCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: ArcobotPanelColors.subtle,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ArcobotColors.guideTurquoise,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ArcobotPanelColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ArcobotPanelColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: ArcobotPanelColors.textOnDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: ArcobotPanelColors.subtle,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        Icons.route_rounded,
        'Diseña tus pistas',
        'Marca inicio, meta y obstáculos en el tablero de 5×8.',
      ),
      (
        Icons.cast_for_education_rounded,
        'Crea la sesión',
        'Elige las pistas, proyecta el PIN y tus estudiantes entran '
            'sin cuenta.',
      ),
      (
        Icons.monitor_heart_rounded,
        'Sigue a cada niño',
        'El monitor muestra en vivo qué pista juega cada estudiante, '
            'sus intentos y logros.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArcobotPanelColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArcobotPanelColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CÓMO FUNCIONA',
            style: TextStyle(
              color: ArcobotPanelColors.subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          for (final (index, step) in steps.indexed) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(step.$1, size: 18, color: ArcobotColors.guideTurquoise),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$2,
                        style: const TextStyle(
                          color: ArcobotPanelColors.textOnDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.$3,
                        style: const TextStyle(
                          color: ArcobotPanelColors.subtle,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (index < steps.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
