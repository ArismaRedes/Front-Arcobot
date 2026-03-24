import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/widgets/app_confirmation_dialog.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/superadmin/data/superadmin_repository.dart';
import 'package:front_arcobot/features/superadmin/presentation/superadmin_user_form_dialog.dart';
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
  bool _isMutating = false;
  String? _busyUserId;
  String? _lastUsersDebugKey;
  static const int _pageSize = 20;

  SuperadminUsersQuery get _query => SuperadminUsersQuery(
        search: _search,
        page: _page,
        pageSize: _pageSize,
      );

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
    final authConfig = ref.watch(authRuntimeConfigProvider);
    final query = _query;
    final usersAsync = ref.watch(superadminUsersProvider(query));
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final activeRole = _resolveSessionRole(authState.roles);
    final currentUserId = authState.subject;

    usersAsync.whenData((page) {
      final debugKey =
          '${page.page}:${page.pageSize}:${page.total}:${page.users.map((user) => user.id).join(',')}';
      if (_lastUsersDebugKey == debugKey) {
        return;
      }

      _lastUsersDebugKey = debugKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint(
          'Superadmin users loaded (${page.users.length}): '
          '${page.users.map((user) => {
                'id': user.id,
                'name': user.name,
                'username': user.username,
                'primaryEmail': user.primaryEmail,
                'roles': user.roles,
              }).toList(growable: false)}',
        );
      });
    });

    return Scaffold(
      backgroundColor: _SuperadminPalette.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              compact: compact,
              roleLabel: activeRole,
              onSignOut: _confirmSignOut,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatsGrid(
                          compact: compact,
                          activeRole: activeRole,
                          search: _search,
                          usersAsync: usersAsync,
                        ),
                        const SizedBox(height: 18),
                        _UsersSection(
                          compact: compact,
                          controller: _searchController,
                          search: _search,
                          organizationId: authConfig.organizationId,
                          isMutating: _isMutating,
                          currentUserId: currentUserId,
                          busyUserId: _busyUserId,
                          onChanged: _handleSearchChanged,
                          onRefresh: _refreshUsers,
                          onCreate: _openCreateUserDialog,
                          onEdit: _openEditUserDialog,
                          onDelete: _confirmDeleteUser,
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
          ],
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

  Future<void> _refreshUsers() async {
    ref.invalidate(superadminUsersProvider(_query));
  }

  Future<void> _openCreateUserDialog() async {
    final formResult = await showSuperadminUserFormDialog(
      context,
      mode: SuperadminUserFormMode.create,
    );

    if (formResult == null || !mounted) {
      return;
    }

    await _runUserMutation(
      busyUserId: null,
      action: () async {
        await ref.read(superadminRepositoryProvider).createUser(
              CreateSuperadminUserInput(
                name: formResult.name,
                username: formResult.username,
                primaryEmail: formResult.primaryEmail,
                primaryPhone: formResult.primaryPhone,
                avatar: formResult.avatar,
                password: formResult.password,
                isSuspended: formResult.isSuspended,
                organizationRoleNames: formResult.organizationRoleNames,
              ),
            );
      },
      successMessage: 'Usuario creado correctamente.',
      errorFallback: 'No se pudo crear el usuario.',
    );
  }

  Future<void> _openEditUserDialog(SuperadminUser user) async {
    final formResult = await showSuperadminUserFormDialog(
      context,
      mode: SuperadminUserFormMode.edit,
      initialUser: user,
    );

    if (formResult == null || !mounted) {
      return;
    }

    await _runUserMutation(
      busyUserId: user.id,
      action: () async {
        await ref.read(superadminRepositoryProvider).updateUser(
              user.id,
              UpdateSuperadminUserInput(
                name: _changedStringField(formResult.name, user.name),
                username: _changedStringField(formResult.username, user.username),
                primaryEmail:
                    _changedStringField(formResult.primaryEmail, user.primaryEmail),
                primaryPhone:
                    _changedStringField(formResult.primaryPhone, user.primaryPhone),
                avatar: _changedStringField(formResult.avatar, user.avatar),
                isSuspended:
                    formResult.isSuspended == user.isSuspended
                        ? superadminNoChange
                        : formResult.isSuspended,
                organizationRoleNames:
                    _sameRoles(formResult.organizationRoleNames, user.roles)
                        ? superadminNoChange
                        : formResult.organizationRoleNames,
              ),
            );
      },
      successMessage: 'Usuario actualizado correctamente.',
      errorFallback: 'No se pudo actualizar el usuario.',
    );
  }

  Future<void> _confirmDeleteUser(SuperadminUser user) async {
    if (user.id == ref.read(authControllerProvider).subject) {
      _showMessage(
        'No puedes eliminar el usuario con la sesion actual.',
        isError: true,
      );
      return;
    }

    final shouldDelete = await showAppConfirmationDialog(
      context,
      title: 'Eliminar usuario',
      message:
          'Se eliminara ${user.displayLabel} en Logto. Esta accion no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _runUserMutation(
      busyUserId: user.id,
      action: () => ref.read(superadminRepositoryProvider).deleteUser(user.id),
      successMessage: 'Usuario eliminado correctamente.',
      errorFallback: 'No se pudo eliminar el usuario.',
    );
  }

  Future<void> _runUserMutation({
    required String? busyUserId,
    required Future<void> Function() action,
    required String successMessage,
    required String errorFallback,
  }) async {
    setState(() {
      _isMutating = true;
      _busyUserId = busyUserId;
    });

    try {
      await action();
      await _refreshUsers();
      if (!mounted) {
        return;
      }
      _showMessage(successMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        _readSuperadminErrorMessage(error, fallback: errorFallback),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
          _busyUserId = null;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF9A4F23) : null,
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showAppConfirmationDialog(
      context,
      title: 'Cerrar sesion',
      message: 'Estas seguro de cerrar sesion?',
      confirmLabel: 'Cerrar sesion',
    );

    if (shouldSignOut == true && mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.compact,
    required this.roleLabel,
    required this.onSignOut,
  });

  final bool compact;
  final String roleLabel;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SuperadminPalette.topBarBackground,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBarBrand(),
                      const SizedBox(height: 12),
                      _TopBarActions(
                        roleLabel: roleLabel,
                        onSignOut: onSignOut,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Expanded(child: _TopBarBrand()),
                      const SizedBox(width: 16),
                      _TopBarActions(
                        roleLabel: roleLabel,
                        onSignOut: onSignOut,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _TopBarBrand extends StatelessWidget {
  const _TopBarBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _SuperadminPalette.brandGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'ArcoBot',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' / superadmin',
                style: TextStyle(
                  color: _SuperadminPalette.topBarMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBarActions extends StatelessWidget {
  const _TopBarActions({
    required this.roleLabel,
    required this.onSignOut,
  });

  final String roleLabel;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _SuperadminPalette.topBarChipBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            roleLabel.toUpperCase(),
            style: const TextStyle(
              color: _SuperadminPalette.brandGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: onSignOut,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(124, 34),
            foregroundColor: _SuperadminPalette.topBarMuted,
            side: const BorderSide(
              color: _SuperadminPalette.topBarButtonBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: const Text(
            'Cerrar sesion',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.compact,
    required this.activeRole,
    required this.search,
    required this.usersAsync,
  });

  final bool compact;
  final String activeRole;
  final String search;
  final AsyncValue<SuperadminUsersPage> usersAsync;

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
    final currentPage = usersAsync.maybeWhen(
      data: (page) => page.page,
      orElse: () => null,
    );

    final cards = [
      _StatCard(
        label: 'Usuarios visibles',
        value: visible?.toString() ?? '--',
      ),
      _StatCard(
        label: 'Total registrado',
        value: total?.toString() ?? '--',
      ),
      _StatCard(
        label: 'Pagina actual',
        value: currentPage?.toString() ?? '--',
      ),
      _StatCard(
        label: search.isEmpty ? 'Rol activo' : 'Filtro activo',
        value: search.isEmpty ? _humanizeRole(activeRole) : search,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact ? 2 : 4;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: card,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _SuperadminPalette.cardBorder,
          width: 0.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _SuperadminPalette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _SuperadminPalette.footerText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersSection extends StatelessWidget {
  const _UsersSection({
    required this.compact,
    required this.controller,
    required this.search,
    required this.organizationId,
    required this.isMutating,
    required this.currentUserId,
    required this.busyUserId,
    required this.onChanged,
    required this.onRefresh,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.usersAsync,
    required this.onPrevious,
    required this.onNext,
  });

  final bool compact;
  final TextEditingController controller;
  final String search;
  final String? organizationId;
  final bool isMutating;
  final String? currentUserId;
  final String? busyUserId;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onCreate;
  final Future<void> Function(SuperadminUser user) onEdit;
  final Future<void> Function(SuperadminUser user) onDelete;
  final AsyncValue<SuperadminUsersPage> usersAsync;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _SuperadminPalette.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UsersToolbar(
            compact: compact,
            controller: controller,
            search: search,
            organizationId: organizationId,
            isMutating: isMutating,
            onChanged: onChanged,
            onRefresh: onRefresh,
            onCreate: onCreate,
          ),
          const Divider(
            height: 1,
            thickness: 0.5,
            color: _SuperadminPalette.cardBorder,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: usersAsync.when(
              data: (page) => _UsersPanel(
                compact: compact,
                page: page,
                currentUserId: currentUserId,
                busyUserId: busyUserId,
                isMutating: isMutating,
                onEdit: onEdit,
                onDelete: onDelete,
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
          ),
        ],
      ),
    );
  }
}

class _UsersToolbar extends StatelessWidget {
  const _UsersToolbar({
    required this.compact,
    required this.controller,
    required this.search,
    required this.organizationId,
    required this.isMutating,
    required this.onChanged,
    required this.onRefresh,
    required this.onCreate,
  });

  final bool compact;
  final TextEditingController controller;
  final String search;
  final String? organizationId;
  final bool isMutating;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    final titleRow = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Usuarios autorizados',
          style: TextStyle(
            color: _SuperadminPalette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        _OrganizationChip(organizationId: organizationId),
      ],
    );

    final searchField = _SearchField(
      controller: controller,
      onChanged: onChanged,
      hintText: search.isEmpty
          ? 'Buscar nombre, correo, handle o ID'
          : 'Filtrando por "$search"',
    );

    final refreshButton = OutlinedButton(
      onPressed: isMutating ? null : onRefresh,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(118, 42),
        foregroundColor: _SuperadminPalette.textPrimary,
        side: const BorderSide(color: _SuperadminPalette.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Actualizar',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );

    final createButton = FilledButton.icon(
      onPressed: isMutating ? null : onCreate,
      style: FilledButton.styleFrom(
        minimumSize: const Size(148, 42),
        backgroundColor: _SuperadminPalette.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
      label: const Text(
        'Crear usuario',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          const SizedBox(height: 14),
          if (compact) ...[
            searchField,
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                createButton,
                const SizedBox(height: 10),
                refreshButton,
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                refreshButton,
                const SizedBox(width: 12),
                createButton,
              ],
            ),
        ],
      ),
    );
  }
}

class _OrganizationChip extends StatelessWidget {
  const _OrganizationChip({required this.organizationId});

  final String? organizationId;

  @override
  Widget build(BuildContext context) {
    final label = organizationId?.trim().isNotEmpty == true
        ? organizationId!
        : 'sin org id';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _SuperadminPalette.cardBorder,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _SuperadminPalette.brandGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _SuperadminPalette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final FocusNode _focusNode;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasBorder = _hovered || _focusNode.hasFocus;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        decoration: BoxDecoration(
          color: _SuperadminPalette.pageBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasBorder
                ? _SuperadminPalette.searchBorder
                : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          style: const TextStyle(
            color: _SuperadminPalette.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              color: _SuperadminPalette.topBarMuted,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _SuperadminPalette.topBarMuted,
              size: 18,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _UsersPanel extends StatelessWidget {
  const _UsersPanel({
    required this.compact,
    required this.page,
    required this.currentUserId,
    required this.busyUserId,
    required this.isMutating,
    required this.onEdit,
    required this.onDelete,
    this.onPrevious,
    this.onNext,
  });

  final bool compact;
  final SuperadminUsersPage page;
  final String? currentUserId;
  final String? busyUserId;
  final bool isMutating;
  final Future<void> Function(SuperadminUser user) onEdit;
  final Future<void> Function(SuperadminUser user) onDelete;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (page.users.isEmpty) {
      return const _UsersEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) const SizedBox(height: 8),
        if (compact)
          _MobileUsersList(
            users: page.users,
            currentUserId: currentUserId,
            busyUserId: busyUserId,
            isMutating: isMutating,
            onEdit: onEdit,
            onDelete: onDelete,
          )
        else
          _DesktopUsersTable(
            users: page.users,
            currentUserId: currentUserId,
            busyUserId: busyUserId,
            isMutating: isMutating,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        const Divider(
          height: 1,
          thickness: 0.5,
          color: _SuperadminPalette.cardBorder,
        ),
        _PaginationFooter(
          compact: compact,
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

class _DesktopUsersTable extends StatelessWidget {
  const _DesktopUsersTable({
    required this.users,
    required this.currentUserId,
    required this.busyUserId,
    required this.isMutating,
    required this.onEdit,
    required this.onDelete,
  });

  final List<SuperadminUser> users;
  final String? currentUserId;
  final String? busyUserId;
  final bool isMutating;
  final Future<void> Function(SuperadminUser user) onEdit;
  final Future<void> Function(SuperadminUser user) onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: _desktopTableWidth),
        child: Column(
          children: [
            const _TableHeader(),
            const Divider(
              height: 1,
              thickness: 0.5,
              color: _SuperadminPalette.cardBorder,
            ),
            ...List.generate(users.length, (index) {
              final isLast = index == users.length - 1;
              final user = users[index];

              return Column(
                children: [
                  _TableRow(
                    user: user,
                    canDelete: user.id != currentUserId,
                    isBusy: isMutating && busyUserId == user.id,
                    onEdit: () => onEdit(user),
                    onDelete: () => onDelete(user),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: _SuperadminPalette.cardBorder,
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 18, 0, 16),
      child: Row(
        children: [
          SizedBox(width: _userColumnWidth, child: _HeaderText('USUARIO')),
          SizedBox(width: _emailColumnWidth, child: _HeaderText('CORREO')),
          SizedBox(width: _roleColumnWidth, child: _HeaderText('ROL')),
          SizedBox(width: _idColumnWidth, child: _HeaderText('ID')),
          SizedBox(width: _actionsColumnWidth, child: _HeaderText('ACCIONES')),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _SuperadminPalette.tableHeaderText,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.user,
    required this.canDelete,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final SuperadminUser user;
  final bool canDelete;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: _userColumnWidth, child: _UserIdentity(user: user)),
          SizedBox(
            width: _emailColumnWidth,
            child: Text(
              user.primaryEmail ?? 'sin correo principal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _SuperadminPalette.emailText,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(
            width: _roleColumnWidth,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildRoleBadges(user.roles),
            ),
          ),
          SizedBox(
            width: _idColumnWidth,
            child: Text(
              user.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _SuperadminPalette.idText,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: _actionsColumnWidth,
            child: _UserRowActions(
              compact: false,
              canDelete: canDelete,
              isBusy: isBusy,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileUsersList extends StatelessWidget {
  const _MobileUsersList({
    required this.users,
    required this.currentUserId,
    required this.busyUserId,
    required this.isMutating,
    required this.onEdit,
    required this.onDelete,
  });

  final List<SuperadminUser> users;
  final String? currentUserId;
  final String? busyUserId;
  final bool isMutating;
  final Future<void> Function(SuperadminUser user) onEdit;
  final Future<void> Function(SuperadminUser user) onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: users
            .map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MobileUserCard(
                  user: user,
                  canDelete: user.id != currentUserId,
                  isBusy: isMutating && busyUserId == user.id,
                  onEdit: () => onEdit(user),
                  onDelete: () => onDelete(user),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _MobileUserCard extends StatelessWidget {
  const _MobileUserCard({
    required this.user,
    required this.canDelete,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final SuperadminUser user;
  final bool canDelete;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _SuperadminPalette.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserIdentity(user: user),
          const SizedBox(height: 14),
          const _HeaderText('CORREO'),
          const SizedBox(height: 6),
          Text(
            user.primaryEmail ?? 'sin correo principal',
            style: const TextStyle(
              color: _SuperadminPalette.emailText,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          const _HeaderText('ROL'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildRoleBadges(user.roles),
          ),
          const SizedBox(height: 12),
          const _HeaderText('ID'),
          const SizedBox(height: 6),
          Text(
            user.id,
            style: const TextStyle(
              color: _SuperadminPalette.idText,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _UserRowActions(
            compact: true,
            canDelete: canDelete,
            isBusy: isBusy,
            onEdit: onEdit,
            onDelete: onDelete,
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
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: _SuperadminPalette.avatarBackground,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _userInitials(user),
            style: const TextStyle(
              color: _SuperadminPalette.avatarForeground,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SuperadminPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (user.isSuspended) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEBDC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'SUSPENDIDO',
                        style: TextStyle(
                          color: Color(0xFF9A4F23),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                user.username == null ? '@sin_handle' : '@${user.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _SuperadminPalette.handleText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserRowActions extends StatelessWidget {
  const _UserRowActions({
    required this.compact,
    required this.canDelete,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final bool compact;
  final bool canDelete;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final editButton = OutlinedButton.icon(
      onPressed: isBusy ? null : onEdit,
      style: OutlinedButton.styleFrom(
        foregroundColor: _SuperadminPalette.textPrimary,
        side: const BorderSide(color: _SuperadminPalette.cardBorder),
        minimumSize: Size(compact ? 0 : 86, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: isBusy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.edit_outlined, size: 16),
      label: const Text(
        'Editar',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );

    final deleteButton = OutlinedButton.icon(
      onPressed: (!canDelete || isBusy) ? null : onDelete,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF9A4F23),
        side: const BorderSide(color: Color(0xFFF0D8C4)),
        minimumSize: Size(compact ? 0 : 92, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.delete_outline_rounded, size: 16),
      label: const Text(
        'Eliminar',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );

    final blockedHint = !canDelete
        ? const Text(
            'Sesion actual',
            style: TextStyle(
              color: _SuperadminPalette.footerText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          )
        : null;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [editButton, deleteButton],
          ),
          if (blockedHint != null) ...[
            const SizedBox(height: 8),
            blockedHint,
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [editButton, deleteButton],
        ),
        if (blockedHint != null) ...[
          const SizedBox(height: 8),
          blockedHint,
        ],
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final style = _roleBadgeStyle(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.trim().isEmpty ? 'SIN ROL' : role.toUpperCase(),
        style: TextStyle(
          color: style.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.compact,
    required this.page,
    required this.pageSize,
    required this.total,
    this.onPrevious,
    this.onNext,
  });

  final bool compact;
  final int page;
  final int pageSize;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = total == 0 ? 0 : (page * pageSize).clamp(0, total);
    final totalPages = total == 0 ? 1 : (total / pageSize).ceil();

    final info = Text(
      'Mostrando $start-$end de $total usuarios. Pagina $page de $totalPages.',
      style: const TextStyle(
        color: _SuperadminPalette.footerText,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );

    final controls = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton(
          onPressed: onPrevious,
          style: _paginationButtonStyle(),
          child: const Text('Anterior'),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _SuperadminPalette.pageBackground,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            'Pagina $page',
            style: const TextStyle(
              color: _SuperadminPalette.footerText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: onNext,
          style: _paginationButtonStyle(),
          child: const Text('Siguiente'),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 12),
                controls,
              ],
            )
          : Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 12),
                controls,
              ],
            ),
    );
  }

  ButtonStyle _paginationButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _SuperadminPalette.textPrimary,
      side: const BorderSide(color: _SuperadminPalette.cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      minimumSize: const Size(84, 34),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

class _UsersLoading extends StatelessWidget {
  const _UsersLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: _SuperadminPalette.textPrimary,
          ),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF0D8C4),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: _SuperadminPalette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              details,
              style: const TextStyle(
                color: _SuperadminPalette.footerText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: _SuperadminPalette.textPrimary,
                side: const BorderSide(color: _SuperadminPalette.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersEmpty extends StatelessWidget {
  const _UsersEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Text(
            'No hay usuarios para mostrar',
            style: TextStyle(
              color: _SuperadminPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Prueba otro filtro o actualiza la consulta.',
            style: TextStyle(
              color: _SuperadminPalette.footerText,
              fontSize: 12,
            ),
          ),
        ],
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

String _resolveSessionRole(List<String> roles) {
  for (final role in roles) {
    if (role.trim().toLowerCase() == 'superadmin') {
      return role;
    }
  }

  return roles.isEmpty ? 'sin rol' : roles.first;
}

String _userInitials(SuperadminUser user) {
  final source = user.name?.trim().isNotEmpty == true
      ? user.name!.trim()
      : user.username?.trim().isNotEmpty == true
          ? user.username!.trim()
          : user.id.trim();
  final parts = source
      .split(RegExp(r'[\s._-]+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  if (parts.isEmpty) {
    return '?';
  }

  final single = parts.first;
  return single.substring(0, single.length >= 2 ? 2 : 1).toUpperCase();
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

Object? _changedStringField(String nextValue, String? currentValue) {
  final normalizedNext = nextValue.trim();
  final normalizedCurrent = currentValue?.trim() ?? '';
  if (normalizedNext == normalizedCurrent) {
    return superadminNoChange;
  }

  return normalizedNext;
}

bool _sameRoles(List<String> left, List<String> right) {
  final normalizedLeft = [...left.map((role) => role.trim()).where((role) => role.isNotEmpty)]
    ..sort();
  final normalizedRight = [...right.map((role) => role.trim()).where((role) => role.isNotEmpty)]
    ..sort();

  if (normalizedLeft.length != normalizedRight.length) {
    return false;
  }

  for (var index = 0; index < normalizedLeft.length; index += 1) {
    if (normalizedLeft[index] != normalizedRight[index]) {
      return false;
    }
  }

  return true;
}

String _readSuperadminErrorMessage(Object error, {required String fallback}) {
  if (error is DioException) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      final errorData = payload['error'];
      if (errorData is Map<String, dynamic>) {
        final details = errorData['details'];
        if (details is String && details.trim().isNotEmpty) {
          return details.trim();
        }

        final message = errorData['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    }

    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return message.trim();
    }
  }

  final text = error.toString().trim();
  if (text.isNotEmpty) {
    return text;
  }

  return fallback;
}

_BadgeColors _roleBadgeStyle(String role) {
  switch (role.trim().toLowerCase()) {
    case 'superadmin':
      return const _BadgeColors(
        background: _SuperadminPalette.textPrimary,
        foreground: _SuperadminPalette.brandGreen,
      );
    case 'admin':
      return const _BadgeColors(
        background: Color(0xFFE6F1FB),
        foreground: Color(0xFF185FA5),
      );
    case 'teacher':
      return const _BadgeColors(
        background: Color(0xFFE8F7EF),
        foreground: Color(0xFF1A7A4A),
      );
    default:
      return const _BadgeColors(
        background: Color(0xFFFAEEDA),
        foreground: Color(0xFF854F0B),
      );
  }
}

class _BadgeColors {
  const _BadgeColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

const double _userColumnWidth = 320;
const double _emailColumnWidth = 250;
const double _roleColumnWidth = 220;
const double _idColumnWidth = 190;
const double _actionsColumnWidth = 190;
const double _desktopTableWidth =
    _userColumnWidth +
    _emailColumnWidth +
    _roleColumnWidth +
    _idColumnWidth +
    _actionsColumnWidth;

class _SuperadminPalette {
  const _SuperadminPalette._();

  static const pageBackground = Color(0xFFF5F3EE);
  static const topBarBackground = Color(0xFF1A2E44);
  static const topBarChipBackground = Color(0xFF253C55);
  static const topBarButtonBorder = Color(0xFF2E4A63);
  static const topBarMuted = Color(0xFF7A9BBE);
  static const brandGreen = Color(0xFF4ECBA0);
  static const cardBorder = Color(0xFFE8E5E0);
  static const textPrimary = Color(0xFF1A2E44);
  static const tableHeaderText = Color(0xFF9AA5B1);
  static const handleText = Color(0xFF8B98A7);
  static const emailText = Color(0xFF6B7A8D);
  static const idText = Color(0xFFB0ADA8);
  static const footerText = Color(0xFF98A1AB);
  static const searchBorder = Color(0xFFD8D3CB);
  static const avatarBackground = Color(0xFFE1F5EE);
  static const avatarForeground = Color(0xFF0F6E56);
}
