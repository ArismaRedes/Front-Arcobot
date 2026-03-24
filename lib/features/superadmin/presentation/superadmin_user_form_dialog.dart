import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/features/superadmin/data/superadmin_repository.dart';
import 'package:front_arcobot/features/superadmin/presentation/superadmin_users_provider.dart';

enum SuperadminUserFormMode { create, edit }

class SuperadminUserFormResult {
  const SuperadminUserFormResult({
    required this.name,
    required this.username,
    required this.primaryEmail,
    required this.primaryPhone,
    required this.avatar,
    required this.password,
    required this.isSuspended,
    required this.organizationRoleNames,
  });

  final String name;
  final String username;
  final String primaryEmail;
  final String primaryPhone;
  final String avatar;
  final String password;
  final bool isSuspended;
  final List<String> organizationRoleNames;
}

Future<SuperadminUserFormResult?> showSuperadminUserFormDialog(
  BuildContext context, {
  required SuperadminUserFormMode mode,
  SuperadminUser? initialUser,
}) {
  return showDialog<SuperadminUserFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SuperadminUserFormDialog(
      mode: mode,
      initialUser: initialUser,
    ),
  );
}

class _SuperadminUserFormDialog extends ConsumerStatefulWidget {
  const _SuperadminUserFormDialog({
    required this.mode,
    this.initialUser,
  });

  final SuperadminUserFormMode mode;
  final SuperadminUser? initialUser;

  @override
  ConsumerState<_SuperadminUserFormDialog> createState() =>
      _SuperadminUserFormDialogState();
}

class _SuperadminUserFormDialogState
    extends ConsumerState<_SuperadminUserFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;
  late final TextEditingController _passwordController;
  late bool _isSuspended;
  late String? _selectedRole;
  String? _validationMessage;

  bool get _isCreate => widget.mode == SuperadminUserFormMode.create;

  @override
  void initState() {
    super.initState();
    final initialUser = widget.initialUser;
    _nameController = TextEditingController(text: initialUser?.name ?? '');
    _usernameController = TextEditingController(text: initialUser?.username ?? '');
    _emailController =
        TextEditingController(text: initialUser?.primaryEmail ?? '');
    _phoneController =
        TextEditingController(text: initialUser?.primaryPhone ?? '');
    _avatarController = TextEditingController(text: initialUser?.avatar ?? '');
    _passwordController = TextEditingController();
    _isSuspended = initialUser?.isSuspended ?? false;
    _selectedRole = initialUser?.roles.isNotEmpty == true
        ? initialUser!.roles.first.trim()
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(superadminOrganizationRolesProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth < 640 ? screenWidth - 24 : 560.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3E8E1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 12, 20),
                  decoration: const BoxDecoration(
                    color: _DialogPalette.textPrimary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isCreate
                              ? Icons.person_add_alt_1_rounded
                              : Icons.edit_note_rounded,
                          color: _DialogPalette.brandGreen,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCreate ? 'Crear usuario' : 'Editar usuario',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _isCreate
                                  ? 'Crea el usuario en Logto y asigna su rol de organizacion.'
                                  : 'Actualiza los datos visibles, estado y rol del usuario.',
                              style: const TextStyle(
                                color: Color(0xFFB8C6D5),
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(
                        title: 'INFORMACION PERSONAL',
                        subtitle: 'Datos base del usuario dentro del sistema.',
                      ),
                      const SizedBox(height: 12),
                      _ContentCard(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final twoColumns = constraints.maxWidth >= 470;

                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _FieldShell(
                                  width: _fieldWidth(constraints.maxWidth, twoColumns),
                                  child: _AppTextField(
                                    controller: _nameController,
                                    label: 'Nombre',
                                    hintText: 'Nombre visible',
                                  ),
                                ),
                                _FieldShell(
                                  width: _fieldWidth(constraints.maxWidth, twoColumns),
                                  child: _AppTextField(
                                    controller: _usernameController,
                                    label: 'Username',
                                    hintText: 'Ej. usuario123',
                                  ),
                                ),
                                _FieldShell(
                                  width: _fieldWidth(constraints.maxWidth, twoColumns),
                                  child: _AppTextField(
                                    controller: _emailController,
                                    label: 'Correo principal',
                                    hintText: 'usuario@dominio.com',
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                _FieldShell(
                                  width: _fieldWidth(constraints.maxWidth, twoColumns),
                                  child: _AppTextField(
                                    controller: _phoneController,
                                    label: 'Telefono principal',
                                    hintText: 'Opcional',
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                _FieldShell(
                                  width: constraints.maxWidth,
                                  child: _AppTextField(
                                    controller: _avatarController,
                                    label: 'Avatar URL',
                                    hintText: 'https://...',
                                    keyboardType: TextInputType.url,
                                  ),
                                ),
                                if (_isCreate)
                                  _FieldShell(
                                    width: constraints.maxWidth,
                                    child: _AppTextField(
                                      controller: _passwordController,
                                      label: 'Contrasena',
                                      hintText: 'Minimo 6 caracteres',
                                      obscureText: true,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel(
                        title: 'ACCESO Y ROL',
                        subtitle: 'Controla la suspension y el rol organizacional.',
                      ),
                      const SizedBox(height: 12),
                      _ContentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: _isSuspended,
                              onChanged: (value) => setState(() => _isSuspended = value),
                              activeThumbColor: _DialogPalette.brandGreen,
                              title: const Text(
                                'Usuario suspendido',
                                style: TextStyle(
                                  color: _DialogPalette.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text(
                                'Controla si el usuario queda suspendido en Logto.',
                                style: TextStyle(
                                  color: _DialogPalette.textMuted,
                                  fontSize: 12,
                                ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFE1E8E0)),
                              const SizedBox(height: 12),
                              const Text(
                                'Rol de organizacion',
                                style: TextStyle(
                                color: _DialogPalette.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Solo se permite un rol por usuario. Puedes dejarlo sin rol.',
                              style: TextStyle(
                                color: _DialogPalette.textMuted,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            rolesAsync.when(
                              data: (roles) {
                                if (roles.isEmpty) {
                                  return const Text(
                                    'No hay roles disponibles en la organizacion.',
                                    style: TextStyle(
                                      color: _DialogPalette.textMuted,
                                      fontSize: 12,
                                    ),
                                  );
                                }

                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: roles
                                      .map(
                                        (role) => ChoiceChip(
                                          label: Text(role.name),
                                          selected: _selectedRole == role.name,
                                          onSelected: (selected) {
                                            setState(() {
                                              _selectedRole =
                                                  selected ? role.name : null;
                                            });
                                          },
                                          selectedColor: const Color(0xFFE1F5EE),
                                          backgroundColor: Colors.white,
                                          checkmarkColor: _DialogPalette.brandGreen,
                                          side: const BorderSide(
                                            color: Color(0xFFDCE4DB),
                                          ),
                                          labelStyle: const TextStyle(
                                            color: _DialogPalette.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  color: _DialogPalette.brandGreen,
                                ),
                              ),
                              error: (error, _) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No se pudo cargar el catalogo de roles.\n$error',
                                    style: const TextStyle(
                                      color: Color(0xFF9A4F23),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: () {
                                      ref.invalidate(superadminOrganizationRolesProvider);
                                    },
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            ),
                              if (_selectedRole != null) ...[
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: () => setState(() => _selectedRole = null),
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  label: const Text('Quitar rol'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _DialogPalette.textMuted,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ),
                      if (_validationMessage != null) ...[
                        const SizedBox(height: 14),
                        _DialogError(message: _validationMessage!),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                foregroundColor: _DialogPalette.textPrimary,
                                side: const BorderSide(color: Color(0xFFD8DED4)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _submit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                backgroundColor: _DialogPalette.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Text(
                                _isCreate ? 'Crear usuario' : 'Guardar cambios',
                              ),
                            ),
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
      ),
    );
  }

  void _submit() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (_isCreate &&
        username.isEmpty &&
        email.isEmpty &&
        phone.isEmpty) {
      setState(() {
        _validationMessage =
            'Debes escribir al menos username, correo o telefono.';
      });
      return;
    }

    if (_isCreate && password.isNotEmpty && password.length < 6) {
      setState(() {
        _validationMessage =
            'La contrasena debe tener al menos 6 caracteres.';
      });
      return;
    }

    setState(() => _validationMessage = null);

    Navigator.of(context).pop(
      SuperadminUserFormResult(
        name: _nameController.text.trim(),
        username: username,
        primaryEmail: email,
        primaryPhone: phone,
        avatar: _avatarController.text.trim(),
        password: password,
        isSuspended: _isSuspended,
        organizationRoleNames:
            _selectedRole == null ? const <String>[] : <String>[_selectedRole!],
      ),
    );
  }

  double _fieldWidth(double maxWidth, bool twoColumns) {
    if (!twoColumns) {
      return maxWidth;
    }

    return (maxWidth - 12) / 2;
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _DialogPalette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _DialogPalette.textMuted,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8E1)),
      ),
      child: child,
    );
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF1EB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0C8B5)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB2431D),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _DialogPalette.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(
            color: _DialogPalette.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF92A0AF),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFFCFDFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCE4DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCE4DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _DialogPalette.brandGreen),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogPalette {
  const _DialogPalette._();

  static const textPrimary = Color(0xFF1A2E44);
  static const textMuted = Color(0xFF6B7A8D);
  static const brandGreen = Color(0xFF4ECBA0);
}
