import 'package:flutter_test/flutter_test.dart';
import 'package:front_arcobot/core/auth/auth_guard.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';

void main() {
  const loginPath = '/login';
  const homePath = '/dashboard';
  const superadminPath = '/superadmin';
  const publicPaths = {loginPath, '/teacher-login'};
  const guestOnlyPaths = {loginPath, '/teacher-login'};

  test('redirects unauthenticated users from private route to login', () {
    final redirect = authRedirect(
      authState: const AuthState(status: AuthStatus.unauthenticated),
      destination: '/dashboard',
      loginPath: loginPath,
      homePath: homePath,
      superadminPath: superadminPath,
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
      superadminPath: superadminPath,
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
      superadminPath: superadminPath,
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
      superadminPath: superadminPath,
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
      superadminPath: superadminPath,
      publicPaths: publicPaths,
      guestOnlyPaths: guestOnlyPaths,
    );

    expect(redirect, loginPath);
  });

  test('redirects superadmin users from guest route to superadmin home', () {
    final redirect = authRedirect(
      authState: const AuthState(
        status: AuthStatus.authenticated,
        roles: ['superadmin'],
      ),
      destination: loginPath,
      loginPath: loginPath,
      homePath: homePath,
      superadminPath: superadminPath,
      publicPaths: publicPaths,
      guestOnlyPaths: guestOnlyPaths,
    );

    expect(redirect, superadminPath);
  });

  test('blocks non-superadmin users from superadmin route', () {
    final redirect = authRedirect(
      authState: const AuthState(
        status: AuthStatus.authenticated,
        roles: ['teacher'],
      ),
      destination: superadminPath,
      loginPath: loginPath,
      homePath: homePath,
      superadminPath: superadminPath,
      publicPaths: publicPaths,
      guestOnlyPaths: guestOnlyPaths,
    );

    expect(redirect, homePath);
  });
}
