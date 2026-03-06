import 'package:flutter_test/flutter_test.dart';
import 'package:front_arcobot/core/auth/auth_guard.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';

void main() {
  const loginPath = '/login';
  const homePath = '/dashboard';
  const publicPaths = {loginPath, '/teacher-login'};
  const guestOnlyPaths = {loginPath, '/teacher-login'};

  test('redirects unauthenticated users from private route to login', () {
    final redirect = authRedirect(
      authState: const AuthState(status: AuthStatus.unauthenticated),
      destination: '/dashboard',
      loginPath: loginPath,
      homePath: homePath,
      publicPaths: publicPaths,
      guestOnlyPaths: guestOnlyPaths,
    );

    expect(redirect, loginPath);
  });

  test('allows unauthenticated users to stay in public route', () {
    final redirect = authRedirect(
      authState: const AuthState(status: AuthStatus.unauthenticated),
      destination: loginPath,
      loginPath: loginPath,
      homePath: homePath,
      publicPaths: publicPaths,
      guestOnlyPaths: guestOnlyPaths,
    );

    expect(redirect, isNull);
  });

  test('redirects authenticated users from public route to home', () {
    final redirect = authRedirect(
      authState: const AuthState(status: AuthStatus.authenticated),
      destination: loginPath,
      loginPath: loginPath,
      homePath: homePath,
      publicPaths: publicPaths,
      guestOnlyPaths: guestOnlyPaths,
    );

    expect(redirect, homePath);
  });

  test('allows authenticated users to stay in private route', () {
    final redirect = authRedirect(
      authState: const AuthState(status: AuthStatus.authenticated),
      destination: homePath,
      loginPath: loginPath,
      homePath: homePath,
      publicPaths: publicPaths,
      guestOnlyPaths: guestOnlyPaths,
    );

    expect(redirect, isNull);
  });

  test('blocks private route while auth state is loading', () {
    final redirect = authRedirect(
      authState: const AuthState(status: AuthStatus.loading),
      destination: homePath,
      loginPath: loginPath,
      homePath: homePath,
      publicPaths: publicPaths,
      guestOnlyPaths: guestOnlyPaths,
    );

    expect(redirect, loginPath);
  });
}
