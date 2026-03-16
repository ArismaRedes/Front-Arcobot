import 'package:front_arcobot/core/auth/auth_config_loader.dart';
import 'package:front_arcobot/core/auth/auth_runtime_config.dart';
import 'package:front_arcobot/core/config/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/config/router.dart';
import 'package:front_arcobot/core/theme/app_theme.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  Env.validate();
  runApp(const ArcobotBootstrapApp());
}

class ArcobotBootstrapApp extends StatefulWidget {
  const ArcobotBootstrapApp({super.key});

  @override
  State<ArcobotBootstrapApp> createState() => _ArcobotBootstrapAppState();
}

class _ArcobotBootstrapAppState extends State<ArcobotBootstrapApp> {
  late Future<AuthRuntimeConfig> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = loadAuthRuntimeConfig();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthRuntimeConfig>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapShell(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _BootstrapShell(
            child: _BootstrapErrorView(
              error: snapshot.error,
              onRetry: () {
                setState(() {
                  _bootstrapFuture = loadAuthRuntimeConfig();
                });
              },
            ),
          );
        }

        return ProviderScope(
          overrides: [
            authRuntimeConfigProvider.overrideWithValue(snapshot.data!),
          ],
          child: const ArcobotApp(),
        );
      },
    );
  }
}

class ArcobotApp extends ConsumerWidget {
  const ArcobotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ArcoBot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

class _BootstrapShell extends StatelessWidget {
  const _BootstrapShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF7FBFF),
                    Color(0xFFEAF5FF),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BootstrapErrorView extends StatelessWidget {
  const _BootstrapErrorView({
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxHeight: 440),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1414315C),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFB7791F),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo iniciar la app',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fallo la carga inicial de configuracion desde backend.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              'API_BASE_URL: ${Env.apiBaseUrl}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              '${error ?? 'Error desconocido'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
