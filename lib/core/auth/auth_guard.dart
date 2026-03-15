import 'package:front_arcobot/features/auth/presentation/auth_state.dart';

String? authRedirect({
  required AuthState authState,
  required String destination,
  required String loginPath,
  required String homePath,
  required String superadminPath,
  required Set<String> publicPaths,
  required Set<String> guestOnlyPaths,
}) {
  final isAtPublicPath = publicPaths.contains(destination);
  final isAtGuestOnlyPath = guestOnlyPaths.contains(destination);
  final isAtSuperadminPath = destination == superadminPath;
  final effectiveHomePath =
      authState.isSuperadmin ? superadminPath : homePath;

  switch (authState.status) {
    case AuthStatus.unknown:
    case AuthStatus.loading:
      return isAtPublicPath ? null : loginPath;
    case AuthStatus.unauthenticated:
    case AuthStatus.failure:
      return isAtPublicPath ? null : loginPath;
    case AuthStatus.authenticated:
      if (authState.isSuperadmin && destination == homePath) {
        return superadminPath;
      }
      if (!authState.isSuperadmin && isAtSuperadminPath) {
        return homePath;
      }
      return isAtGuestOnlyPath ? effectiveHomePath : null;
  }
}
