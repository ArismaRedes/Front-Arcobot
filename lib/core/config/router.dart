import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/auth/auth_guard.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/auth/presentation/login_screen.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';
import 'package:front_arcobot/features/auth/presentation/teacher_login_screen.dart';
import 'package:front_arcobot/features/dashboard/presentation/dashboard_screen.dart';
import 'package:front_arcobot/features/preload/presentation/preload_screen.dart';
import 'package:front_arcobot/features/superadmin/presentation/superadmin_screen.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ValueNotifier<AuthState>(
    ref.read(authControllerProvider),
  );

  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authStateNotifier.value = next;
  });

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: authStateNotifier,
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => PreloadScreen.routePath,
      ),
      GoRoute(
        path: PreloadScreen.routePath,
        builder: (_, __) => const PreloadScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: TeacherLoginScreen.routePath,
        builder: (_, __) => const TeacherLoginScreen(),
      ),
      GoRoute(
        path: DashboardScreen.routePath,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: SuperadminScreen.routePath,
        builder: (_, __) => const SuperadminScreen(),
      ),
    ],
    redirect: (_, state) {
      return authRedirect(
        authState: authStateNotifier.value,
        destination: state.matchedLocation,
        loginPath: LoginScreen.routePath,
        homePath: DashboardScreen.routePath,
        superadminPath: SuperadminScreen.routePath,
        publicPaths: const {
          PreloadScreen.routePath,
          LoginScreen.routePath,
          TeacherLoginScreen.routePath,
        },
        guestOnlyPaths: const {
          LoginScreen.routePath,
          TeacherLoginScreen.routePath,
        },
      );
    },
  );

  ref.onDispose(() {
    router.dispose();
    authStateNotifier.dispose();
  });

  return router;
});
