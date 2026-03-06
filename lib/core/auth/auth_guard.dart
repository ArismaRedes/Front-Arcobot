import 'package:front_arcobot/features/auth/presentation/auth_state.dart';

String? authRedirect({
  required AuthState authState,
  required String destination,
  required String loginPath,
  required String homePath,
  required Set<String> publicPaths,
  required Set<String> guestOnlyPaths,
}) {
  final isAtPublicPath = publicPaths.contains(destination);
  final isAtGuestOnlyPath = guestOnlyPaths.contains(destination);

  switch (authState.status) {
    case AuthStatus.unknown:
    case AuthStatus.loading:
      return isAtPublicPath ? null : loginPath;
    case AuthStatus.unauthenticated:
    case AuthStatus.failure:
      return isAtPublicPath ? null : loginPath;
    case AuthStatus.authenticated:
      return isAtGuestOnlyPath ? homePath : null;
  }
}
