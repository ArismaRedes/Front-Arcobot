import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/superadmin/data/superadmin_repository.dart';
import 'package:front_arcobot/features/superadmin/presentation/superadmin_users_provider.dart';

class SuperadminScreen extends ConsumerStatefulWidget {
  const SuperadminScreen({super.key});

  static const routePath = '/superadmin';

  @override
  ConsumerState<SuperadminScreen> createState() => _SuperadminScreenState();
}

class _SuperadminScreenState extends ConsumerState<SuperadminScreen> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  String _search = '';
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final query = SuperadminUsersQuery(
      search: _search,
      page: _page,
      pageSize: _pageSize,
    );
    final usersAsync = ref.watch(superadminUsersProvider(query));
    final width = MediaQuery.sizeOf(context).width;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(
                      roles: authState.roles,
                      onSignOut: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                    ),
                    const SizedBox(height: ArcobotSpacing.lg),
                    _HeroSection(usersAsync: usersAsync, width: width),
                    const SizedBox(height: ArcobotSpacing.lg),
                    _UsersSection(
                      controller: _searchController,
                      search: _search,
                      onChanged: _handleSearchChanged,
                      onRefresh: () =>
                          ref.refresh(superadminUsersProvider(query).future),
                      usersAsync: usersAsync,
                      onPrevious: () => setState(() => _page -= 1),
                      onNext: () => setState(() => _page += 1),
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

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _search = value.trim();
        _page = 1;
      });
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.roles,
    required this.onSignOut,
  });

  final List<String> roles;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 760;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel Superadmin',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF102A43),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: ArcobotSpacing.xxs),
        Text(
          'Usuarios y roles resueltos por backend',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: ArcobotColors.textSecondary,
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: ArcobotSpacing.sm,
      runSpacing: ArcobotSpacing.sm,
      children: [
        if (roles.isNotEmpty)
          _StatusPill(
            label: roles.map(_humanizeRole).join(' · '),
            background: const Color(0xFFE8F7F1),
            foreground: const Color(0xFF0B6E5E),
          ),
        SizedBox(
          width: 172,
          child: FilledButton.tonalIcon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesion'),
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: ArcobotSpacing.md),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: ArcobotSpacing.md),
        actions,
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.usersAsync,
    required this.width,
  });

  final AsyncValue<SuperadminUsersPage> usersAsync;
  final double width;

  @override
  Widget build(BuildContext context) {
    final total = usersAsync.maybeWhen(
      data: (page) => page.total,
      orElse: () => null,
    );
    final visible = usersAsync.maybeWhen(
      data: (page) => page.users.length,
      orElse: () => null,
    );
    final page = usersAsync.maybeWhen(
      data: (data) => data.page,
      orElse: () => null,
    );

    final metrics = Wrap(
      spacing: ArcobotSpacing.sm,
      runSpacing: ArcobotSpacing.sm,
      children: [
        _MetricCard(
          label: 'Fuente',
          value: 'Logto M2M',
          tint: const Color(0xFFEAF2FF),
        ),
        _MetricCard(
          label: 'Usuarios visibles',
          value: visible?.toString() ?? '...',
          tint: const Color(0xFFE8F7F1),
        ),
        _MetricCard(
          label: 'Total',
          value: total?.toString() ?? '...',
          tint: const Color(0xFFFFF4DF),
        ),
        _MetricCard(
          label: 'Pagina',
          value: page?.toString() ?? '...',
          tint: const Color(0xFFF3ECFF),
        ),
      ],
    );

    if (width < 980) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeroBanner(),
          const SizedBox(height: ArcobotSpacing.md),
          metrics,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          flex: 7,
          child: _HeroBanner(),
        ),
        const SizedBox(width: ArcobotSpacing.md),
        Expanded(
          flex: 5,
          child: metrics,
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(ArcobotSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ArcobotRadii.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102A43),
            Color(0xFF1F4E79),
          ],
        ),
        boxShadow: ArcobotShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Centro de control de usuarios',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: ArcobotSpacing.sm),
          Text(
            'La organizacion y los roles se validan en backend. Esta vista solo representa datos ya autorizados.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFE8F0F7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: ArcobotSpacing.md,
        vertical: ArcobotSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(ArcobotRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: ArcobotSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ArcobotColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersSection extends StatelessWidget {
  const _UsersSection({
    required this.controller,
    required this.search,
    required this.onChanged,
    required this.onRefresh,
    required this.usersAsync,
    required this.onPrevious,
    required this.onNext,
  });

  final TextEditingController controller;
  final String search;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;
  final AsyncValue<SuperadminUsersPage> usersAsync;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ArcobotSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ArcobotRadii.xl),
        border: Border.all(color: ArcobotColors.softBorder),
        boxShadow: ArcobotShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UsersToolbar(
            controller: controller,
            search: search,
            onChanged: onChanged,
            onRefresh: onRefresh,
          ),
          const SizedBox(height: ArcobotSpacing.lg),
          usersAsync.when(
            data: (page) => _UsersPanel(
              page: page,
              onPrevious: page.page > 1 ? onPrevious : null,
              onNext: page.hasNextPage ? onNext : null,
            ),
            loading: () => const _UsersLoading(),
            error: (error, _) => _UsersError(
              message: 'No se pudo cargar la lista de usuarios.',
              details: error.toString(),
              onRetry: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersToolbar extends StatelessWidget {
  const _UsersToolbar({
    required this.controller,
    required this.search,
    required this.onChanged,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final String search;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usuarios de la organización',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF102A43),
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: ArcobotSpacing.xs),
        Text(
          search.isEmpty
              ? 'Consulta usuarios, roles y datos operativos.'
              : 'Filtro activo: "$search"',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ArcobotColors.textSecondary,
              ),
        ),
      ],
    );

    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, correo, usuario o ID',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFFF8FBFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArcobotRadii.lg),
          borderSide: const BorderSide(color: ArcobotColors.softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArcobotRadii.lg),
          borderSide: const BorderSide(color: ArcobotColors.softBorder),
        ),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: ArcobotSpacing.md),
          field,
          const SizedBox(height: ArcobotSpacing.sm),
          FilledButton.tonalIcon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualizar'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: ArcobotSpacing.md),
        Row(
          children: [
            Expanded(child: field),
            const SizedBox(width: ArcobotSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsersPanel extends StatelessWidget {
  const _UsersPanel({
    required this.page,
    this.onPrevious,
    this.onNext,
  });

  final SuperadminUsersPage page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final tableMode = MediaQuery.sizeOf(context).width >= 1080;

    if (page.users.isEmpty) {
      return const _UsersEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: ArcobotSpacing.sm,
          runSpacing: ArcobotSpacing.sm,
          children: [
            _MetricCard(
              label: 'Visibles',
              value: '${page.users.length}',
              tint: const Color(0xFFEAF2FF),
            ),
            _MetricCard(
              label: 'Total',
              value: '${page.total}',
              tint: const Color(0xFFE8F7F1),
            ),
            _MetricCard(
              label: 'Pagina',
              value: '${page.page}',
              tint: const Color(0xFFFFF4DF),
            ),
          ],
        ),
        const SizedBox(height: ArcobotSpacing.md),
        if (tableMode)
          _UsersTable(users: page.users)
        else
          _UsersCards(users: page.users),
        const SizedBox(height: ArcobotSpacing.md),
        _PaginationBar(
          page: page.page,
          pageSize: page.pageSize,
          total: page.total,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
      ],
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users});

  final List<SuperadminUser> users;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ArcobotRadii.lg),
        border: Border.all(color: ArcobotColors.softBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ArcobotRadii.lg),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF7FAFD)),
            horizontalMargin: 20,
            columnSpacing: 20,
            headingTextStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF102A43),
            ),
            columns: const [
              DataColumn(label: Text('Usuario')),
              DataColumn(label: Text('Correo')),
              DataColumn(label: Text('Roles')),
              DataColumn(label: Text('ID')),
            ],
            rows: users
                .map(
                  (user) => DataRow(
                    cells: [
                      DataCell(SizedBox(
                        width: 250,
                        child: _UserIdentity(user: user),
                      )),
                      DataCell(SizedBox(
                        width: 220,
                        child: Text(
                          user.primaryEmail ?? 'Sin correo',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      DataCell(SizedBox(
                        width: 220,
                        child: Wrap(
                          spacing: ArcobotSpacing.xs,
                          runSpacing: ArcobotSpacing.xs,
                          children: _buildRoleBadges(user.roles),
                        ),
                      )),
                      DataCell(SizedBox(
                        width: 220,
                        child: Text(
                          user.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ArcobotColors.textSecondary,
                          ),
                        ),
                      )),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _UsersCards extends StatelessWidget {
  const _UsersCards({required this.users});

  final List<SuperadminUser> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: users
          .map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: ArcobotSpacing.sm),
              child: _UserCard(user: user),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final SuperadminUser user;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ArcobotSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(ArcobotRadii.lg),
        border: Border.all(color: ArcobotColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserIdentity(user: user),
          const SizedBox(height: ArcobotSpacing.md),
          if (compact) ...[
            _InfoBlock(
              label: 'Correo',
              value: user.primaryEmail ?? 'Sin correo principal',
            ),
            const SizedBox(height: ArcobotSpacing.sm),
            _InfoBlock(
              label: 'ID',
              value: user.id,
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoBlock(
                    label: 'Correo',
                    value: user.primaryEmail ?? 'Sin correo principal',
                  ),
                ),
                const SizedBox(width: ArcobotSpacing.md),
                Expanded(
                  child: _InfoBlock(
                    label: 'ID',
                    value: user.id,
                  ),
                ),
              ],
            ),
          const SizedBox(height: ArcobotSpacing.md),
          Text(
            'Roles',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ArcobotColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: ArcobotSpacing.xs),
          Wrap(
            spacing: ArcobotSpacing.xs,
            runSpacing: ArcobotSpacing.xs,
            children: _buildRoleBadges(user.roles),
          ),
        ],
      ),
    );
  }
}

class _UserIdentity extends StatelessWidget {
  const _UserIdentity({required this.user});

  final SuperadminUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial =
        user.displayLabel.isEmpty ? '?' : user.displayLabel[0].toUpperCase();

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFEAF2FF),
          backgroundImage:
              user.avatar != null ? NetworkImage(user.avatar!) : null,
          child: user.avatar == null
              ? Text(
                  initial,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF1F4E79),
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
        const SizedBox(width: ArcobotSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF102A43),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: ArcobotSpacing.xxs),
              Text(
                user.username == null ? 'sin username' : '@${user.username}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ArcobotColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ArcobotColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: ArcobotSpacing.xs),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF102A43),
            fontWeight: FontWeight.w600,
          ),
          softWrap: true,
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final accent = _roleAccent(role);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArcobotSpacing.sm,
        vertical: ArcobotSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ArcobotRadii.pill),
      ),
      child: Text(
        _humanizeRole(role),
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.pageSize,
    required this.total,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final int pageSize;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = total == 0 ? 0 : (page * pageSize).clamp(0, total);
    final compact = MediaQuery.sizeOf(context).width < 640;

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: onPrevious,
          child: const Text('Anterior'),
        ),
        const SizedBox(width: ArcobotSpacing.sm),
        FilledButton(
          onPressed: onNext,
          child: const Text('Siguiente'),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mostrando $start-$end de $total usuarios'),
          const SizedBox(height: ArcobotSpacing.sm),
          controls,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: Text('Mostrando $start-$end de $total usuarios')),
        controls,
      ],
    );
  }
}

class _UsersLoading extends StatelessWidget {
  const _UsersLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ArcobotSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(ArcobotRadii.lg),
        border: Border.all(color: ArcobotColors.softBorder),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _UsersError extends StatelessWidget {
  const _UsersError({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(ArcobotSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F7),
        borderRadius: BorderRadius.circular(ArcobotRadii.lg),
        border: Border.all(color: const Color(0xFFFFD7D1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF7A1E12),
            ),
          ),
          const SizedBox(height: ArcobotSpacing.xs),
          Text(
            details,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8B4F47),
            ),
          ),
          const SizedBox(height: ArcobotSpacing.md),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _UsersEmpty extends StatelessWidget {
  const _UsersEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ArcobotSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(ArcobotRadii.lg),
        border: Border.all(color: ArcobotColors.softBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: ArcobotColors.skyBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: ArcobotSpacing.md),
          Text(
            'No hay usuarios para mostrar',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: ArcobotSpacing.xs),
          Text(
            'Prueba otro filtro o actualiza la consulta.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ArcobotColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArcobotSpacing.sm,
        vertical: ArcobotSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ArcobotRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

List<Widget> _buildRoleBadges(List<String> roles) {
  if (roles.isEmpty) {
    return const [_RoleBadge(role: 'sin rol')];
  }

  return roles.map((role) => _RoleBadge(role: role)).toList(growable: false);
}

Color _roleAccent(String role) {
  switch (role.trim().toLowerCase()) {
    case 'superadmin':
      return const Color(0xFFB7791F);
    case 'admin':
      return ArcobotColors.skyBlue;
    case 'teacher':
      return ArcobotColors.successGreen;
    default:
      return const Color(0xFF6B7280);
  }
}

String _humanizeRole(String role) {
  final trimmed = role.trim();
  if (trimmed.isEmpty) {
    return 'Sin rol';
  }

  return trimmed
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
