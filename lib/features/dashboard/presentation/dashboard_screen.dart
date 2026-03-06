import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const routePath = '/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ArcoBot Dashboard')),
      body: Center(
        child: FilledButton(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          child: const Text('Cerrar sesion'),
        ),
      ),
    );
  }
}
