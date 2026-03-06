import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _goToTeacherLogin,
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('Soy profesor'),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ArcoBot',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ingresa el codigo de la clase',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _classCodeController,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Codigo de clase',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _joinClass(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _joinClass,
                            child: const Text('Entrar a clase'),
                          ),
                        ),
                      ],
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
