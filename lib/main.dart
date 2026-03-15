import 'package:front_arcobot/core/auth/auth_config_loader.dart';
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
  final authRuntimeConfig = await loadAuthRuntimeConfig();
  runApp(
    ProviderScope(
      overrides: [
        authRuntimeConfigProvider.overrideWithValue(authRuntimeConfig),
      ],
      child: const ArcobotApp(),
    ),
  );
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
