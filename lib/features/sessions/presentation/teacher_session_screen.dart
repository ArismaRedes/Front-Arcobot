import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/app_theme.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/core/widgets/arco_avatar.dart';
import 'package:front_arcobot/core/widgets/arco_character.dart';
import 'package:front_arcobot/features/dashboard/presentation/dashboard_screen.dart';
import 'package:front_arcobot/features/sessions/domain/session_models.dart';
import 'package:front_arcobot/features/sessions/presentation/teacher_session_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TeacherSessionScreen extends ConsumerStatefulWidget {
  const TeacherSessionScreen({super.key});

  static const routePath = '/teacher/session';

  @override
  ConsumerState<TeacherSessionScreen> createState() =>
      _TeacherSessionScreenState();
}

class _TeacherSessionScreenState extends ConsumerState<TeacherSessionScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Mi clase');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    await ref.read(teacherSessionProvider.notifier).create(
          name: name.isEmpty ? 'Mi clase' : name,
        );
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
      return _ProjectionView(
        state: state,
        onEnd: _confirmEnd,
      );
    }

    return _CreateView(
      nameController: _nameController,
      creating: state.status == TeacherSessionStatus.creating,
      errorMessage: state.errorMessage,
      onCreate: _create,
      onBack: () => context.go(DashboardScreen.routePath),
    );
  }
}

/// Fase 1: formulario del docente (tema oscuro del panel).
class _CreateView extends StatelessWidget {
  const _CreateView({
    required this.nameController,
    required this.creating,
    required this.errorMessage,
    required this.onCreate,
    required this.onBack,
  });

  final TextEditingController nameController;
  final bool creating;
  final String? errorMessage;
  final VoidCallback onCreate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 420),
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

/// Fase 2: vista proyectable — clara, gigante, pensada para el aula.
class _ProjectionView extends StatelessWidget {
  const _ProjectionView({required this.state, required this.onEnd});

  final TeacherSessionState state;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final session = state.session!;
    final wide = MediaQuery.sizeOf(context).width >= 860;

    final pinPanel = _PinPanel(
      pin: session.pin,
      name: session.name,
      ending: state.status == TeacherSessionStatus.ending,
      onEnd: onEnd,
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
  });

  final String pin;
  final String name;
  final bool ending;
  final VoidCallback onEnd;

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
          OutlinedButton.icon(
            onPressed: ending ? null : onEnd,
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            label: Text(ending ? 'Terminando...' : 'Terminar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArcobotColors.coral,
              side: const BorderSide(color: ArcobotColors.coral, width: 1.5),
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
