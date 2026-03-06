import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';
import 'package:front_arcobot/features/auth/presentation/login_screen.dart';
import 'package:go_router/go_router.dart';

class TeacherLoginScreen extends ConsumerWidget {
  const TeacherLoginScreen({super.key});

  static const routePath = '/teacher-login';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.status == AuthStatus.loading;
    final theme = Theme.of(context);

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
          child: Stack(
            children: [
              const Positioned(
                top: -80,
                right: -40,
                child: _BackgroundBubble(
                  size: 210,
                  color: Color(0x333A86FF),
                ),
              ),
              const Positioned(
                bottom: -90,
                left: -20,
                child: _BackgroundBubble(
                  size: 240,
                  color: Color(0x3319BFB7),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Container(
                      padding: const EdgeInsets.all(ArcobotSpacing.xl),
                      decoration: BoxDecoration(
                        color: ArcobotColors.surface,
                        borderRadius: BorderRadius.circular(ArcobotRadii.xl),
                        border: Border.all(color: ArcobotColors.softBorder),
                        boxShadow: ArcobotShadows.soft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton.filledTonal(
                              onPressed: () =>
                                  context.go(LoginScreen.routePath),
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Volver',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFEAF2FF),
                                foregroundColor: ArcobotColors.skyBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: ArcobotSpacing.xs),
                          Text(
                            'Panel de profesor',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: ArcobotSpacing.xs),
                          Text(
                            'Accede para gestionar tu clase',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: ArcobotColors.textSecondary,
                            ),
                          ),
                          if (authState.errorMessage != null) ...[
                            const SizedBox(height: ArcobotSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEEEB),
                                borderRadius:
                                    BorderRadius.circular(ArcobotRadii.md),
                                border:
                                    Border.all(color: const Color(0xFFFFCDC6)),
                              ),
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFC2410C),
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: ArcobotSpacing.lg),
                          FilledButton.icon(
                            onPressed: loading
                                ? null
                                : () => ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithTeacherCredentials(),
                            icon: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_open_rounded),
                            label: Text(
                              loading
                                  ? 'Conectando...'
                                  : 'Iniciar sesion con Logto',
                            ),
                          ),
                          const SizedBox(height: ArcobotSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: loading
                                ? null
                                : () => ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithFacebook(),
                            icon: const Icon(Icons.facebook),
                            label: const Text('Continuar con Facebook'),
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
