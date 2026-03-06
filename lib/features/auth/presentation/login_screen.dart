import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/features/auth/presentation/class_code_scanner_screen.dart';
import 'package:front_arcobot/features/auth/presentation/teacher_login_screen.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _classCodeController;

  @override
  void initState() {
    super.initState();
    _classCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    super.dispose();
  }

  void _goToTeacherLogin() {
    context.go(TeacherLoginScreen.routePath);
  }

  void _joinClass() {
    final code = _classCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el codigo de la clase')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Codigo ingresado: $code')),
    );
  }

  Future<void> _scanClassCode() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ClassCodeScannerScreen(),
      ),
    );

    if (!mounted || scannedCode == null || scannedCode.isEmpty) {
      return;
    }

    _classCodeController.text = scannedCode;
    _joinClass();
  }

  @override
  Widget build(BuildContext context) {
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
                left: -40,
                child: _BackgroundBubble(
                  size: 210,
                  color: Color(0x443A86FF),
                ),
              ),
              const Positioned(
                bottom: -90,
                right: -20,
                child: _BackgroundBubble(
                  size: 240,
                  color: Color(0x4419BFB7),
                ),
              ),
              Positioned(
                top: ArcobotSpacing.xs,
                right: ArcobotSpacing.xs,
                child: FilledButton.icon(
                  onPressed: _goToTeacherLogin,
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: const Text('Soy profesor'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: ArcobotColors.sunYellow,
                    foregroundColor: ArcobotColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ArcobotRadii.pill),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: ArcobotSpacing.lg),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 72, bottom: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _buildFormPanel(theme),
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

  Widget _buildFormPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(ArcobotSpacing.xl),
      decoration: BoxDecoration(
        color: ArcobotColors.surface,
        borderRadius: BorderRadius.circular(ArcobotRadii.xl),
        border: Border.all(color: ArcobotColors.softBorder),
        boxShadow: ArcobotShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mini Arco',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: ArcobotColors.skyBlue,
            ),
          ),
          const SizedBox(height: ArcobotSpacing.xs),
          Text(
            'Ingresa tu codigo y empieza la aventura',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: ArcobotColors.textSecondary,
            ),
          ),
          const SizedBox(height: ArcobotSpacing.lg),
          const _ArcobotGuideBubble(
            message: 'Hola, escribe el codigo de tu clase',
          ),
          const SizedBox(height: ArcobotSpacing.lg),
          TextField(
            controller: _classCodeController,
            textInputAction: TextInputAction.done,
            style: theme.textTheme.titleLarge,
            decoration: const InputDecoration(
              labelText: 'Codigo de clase',
              prefixIcon: Icon(Icons.code_rounded),
            ),
            onSubmitted: (_) => _joinClass(),
          ),
          const SizedBox(height: ArcobotSpacing.sm),
          OutlinedButton(
            onPressed: _scanClassCode,
            child: const Text('Escanear codigo'),
          ),
          const SizedBox(height: ArcobotSpacing.md),
          FilledButton(
            onPressed: _joinClass,
            child: const Text('Entrar a mi clase'),
          ),
        ],
      ),
    );
  }
}

class _ArcobotGuideBubble extends StatelessWidget {
  const _ArcobotGuideBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArcobotSpacing.md,
        vertical: ArcobotSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F6),
        borderRadius: BorderRadius.circular(ArcobotRadii.lg),
        border: Border.all(color: const Color(0xFFBFEAE6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: ArcobotColors.guideTurquoise,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: ArcobotSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: ArcobotColors.textPrimary,
              ),
            ),
          ),
        ],
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
