import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/core/auth/auth_guard.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/auth/presentation/login_screen.dart';
import 'package:front_arcobot/features/auth/presentation/teacher_login_screen.dart';
import 'package:front_arcobot/features/dashboard/presentation/dashboard_screen.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: LoginScreen.routePath,
    routes: [
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
    ],
    redirect: (_, state) {
      return authRedirect(
        authState: authState,
        destination: state.matchedLocation,
        loginPath: LoginScreen.routePath,
        homePath: DashboardScreen.routePath,
        publicPaths: const {
          LoginScreen.routePath,
          TeacherLoginScreen.routePath,
        },
      );
    },
  );
});
