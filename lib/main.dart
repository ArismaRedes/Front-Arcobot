import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/config/env.dart';
import 'package:front_arcobot/core/config/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Env.validate();
  runApp(const ProviderScope(child: ArcobotApp()));
}

class ArcobotApp extends ConsumerWidget {
  const ArcobotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ArcoBot',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
