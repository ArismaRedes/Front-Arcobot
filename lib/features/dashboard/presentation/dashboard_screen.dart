import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const routePath = '/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final roleLabel = _humanizeRole(authState.primaryRole);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: ArcobotColors.screenGradient,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -90,
              right: -50,
              child: _BackgroundBubble(
                size: 220,
                color: Color(0x333A86FF),
              ),
            ),
            const Positioned(
              bottom: -110,
              left: -60,
              child: _BackgroundBubble(
                size: 260,
                color: Color(0x3319BFB7),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ArcobotColors.guideTurquoise,
                          boxShadow: ArcobotShadows.soft,
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: ArcobotSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, explorador',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              'Arcobot te guiará hoy',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (roleLabel != null)
                              Text(
                                'Rol: $roleLabel',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ArcobotColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: 'Cerrar sesion',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF4FF),
                          foregroundColor: ArcobotColors.skyBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ArcobotSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(ArcobotSpacing.lg),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ArcobotRadii.xl),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: ArcobotColors.heroGradient,
                      ),
                      boxShadow: ArcobotShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continuar aventura',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: ArcobotSpacing.xs),
                        Text(
                          'Te faltan 2 retos para encender la Isla Numeros',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFF1F8FF),
                          ),
                        ),
                        const SizedBox(height: ArcobotSpacing.md),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(ArcobotRadii.pill),
                          child: const LinearProgressIndicator(
                            value: 0.68,
                            minHeight: 14,
                            backgroundColor: Color(0x66FFFFFF),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ArcobotColors.sunYellow,
                            ),
                          ),
                        ),
                        const SizedBox(height: ArcobotSpacing.md),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: ArcobotColors.skyBlue,
                          ),
                          child: const Text('Jugar ahora'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ArcobotSpacing.lg),
                  Text('Mundos', style: theme.textTheme.titleLarge),
                  const SizedBox(height: ArcobotSpacing.sm),
                  SizedBox(
                    height: 168,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _WorldCard(
                          title: 'Letras',
                          subtitle: '12 actividades',
                          color: Color(0xFF55C271),
                          icon: Icons.auto_stories_rounded,
                        ),
                        SizedBox(width: ArcobotSpacing.sm),
                        _WorldCard(
                          title: 'Numeros',
                          subtitle: '8 actividades',
                          color: Color(0xFF3A86FF),
                          icon: Icons.calculate_rounded,
                        ),
                        SizedBox(width: ArcobotSpacing.sm),
                        _WorldCard(
                          title: 'Arte',
                          subtitle: '6 actividades',
                          color: Color(0xFFA78BFA),
                          icon: Icons.palette_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ArcobotSpacing.lg),
                  Text('Actividades rapidas',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: ArcobotSpacing.sm),
                  Wrap(
                    spacing: ArcobotSpacing.sm,
                    runSpacing: ArcobotSpacing.sm,
                    children: const [
                      _ActivityCard(
                        title: 'Emparejar letras',
                        icon: Icons.abc_rounded,
                        color: Color(0xFFE6F7F5),
                      ),
                      _ActivityCard(
                        title: 'Contar figuras',
                        icon: Icons.interests_rounded,
                        color: Color(0xFFEAF2FF),
                      ),
                      _ActivityCard(
                        title: 'Memoria visual',
                        icon: Icons.grid_view_rounded,
                        color: Color(0xFFF3ECFF),
                      ),
                      _ActivityCard(
                        title: 'Colores y formas',
                        icon: Icons.format_paint_rounded,
                        color: Color(0xFFFFF4DF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        height: 76,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public_rounded),
            label: 'Mundos',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Premios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
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

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 156,
      padding: const EdgeInsets.all(ArcobotSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ArcobotRadii.lg),
        border: Border.all(color: ArcobotColors.softBorder),
        boxShadow: ArcobotShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: ArcobotColors.textPrimary,
            ),
          ),
          const SizedBox(height: ArcobotSpacing.xs),
          Text(subtitle, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.all(ArcobotSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(ArcobotRadii.md),
          border: Border.all(color: ArcobotColors.softBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: ArcobotColors.textPrimary, size: 22),
            const SizedBox(width: ArcobotSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundBubble extends StatelessWidget {
  const _BackgroundBubble({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
