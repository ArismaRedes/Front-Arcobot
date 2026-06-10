import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/audio/arco_audio.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/core/widgets/arco_avatar.dart';
import 'package:front_arcobot/core/widgets/arco_character.dart';
import 'package:front_arcobot/features/auth/presentation/login_screen.dart';
import 'package:front_arcobot/features/sessions/presentation/student_session_provider.dart';
import 'package:front_arcobot/features/simulator/presentation/simulator_screen.dart';
import 'package:go_router/go_router.dart';

/// Home temporal del estudiante tras unirse a la clase. Aquí irán los
/// mundos/actividades de la sesión; por ahora confirma la entrada con
/// una celebración.
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  static const routePath = '/class/home';

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(arcoAudioProvider).narrate('bienvenida_clase');
    });
  }

  void _leave() {
    ref.read(arcoAudioProvider).sfx(ArcoSfx.tap);
    ref.read(studentSessionProvider.notifier).leave();
    context.go(LoginScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studentSessionProvider).value;

    if (session == null) {
      // Sin sesión activa (ej. recarga en web): volver al login.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(LoginScreen.routePath);
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    ArcoCharacterView(
                      character: ArcoCharacter.bussy,
                      mood: ArcoMood.celebrating,
                      size: 140,
                    ),
                    const SizedBox(height: 18),
                    ArcoAvatar(avatarId: session.avatar, size: 72,
                        selected: true),
                    const SizedBox(height: 14),
                    Text(
                      '¡Hola, ${session.alias}!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ArcobotKidColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ya estás en "${session.sessionName}". '
                      '¡Hora de programar a Arco!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ArcobotKidColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: FilledButton.icon(
                        onPressed: () {
                          ref.read(arcoAudioProvider).sfx(ArcoSfx.join);
                          context.go(SimulatorScreen.routePath);
                        },
                        icon: const Icon(Icons.sports_esports_rounded,
                            size: 26),
                        label: const Text('¡A jugar!'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ArcobotKidColors.action,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _leave,
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: ArcobotKidColors.textSecondary,
                      ),
                      label: const Text(
                        'Salir de la clase',
                        style: TextStyle(
                          color: ArcobotKidColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
