import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            colors: [Color(0xFFF9FCFF), Color(0xFFF1F6FB)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: FilledButton.icon(
                  onPressed: _goToTeacherLogin,
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: const Text('Soy profesor'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 72, bottom: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: _buildFormCard(theme),
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

  Widget _buildFormCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ArcoBot',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0B6E5E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa tu codigo de clase',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _classCodeController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Codigo de clase',
                prefixIcon: Icon(Icons.password_rounded),
              ),
              onSubmitted: (_) => _joinClass(),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _scanClassCode,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Escanear codigo'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _joinClass,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Entrar a clase'),
            ),
          ],
        ),
      ),
    );
  }
}
