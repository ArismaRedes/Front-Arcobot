enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState {
  const AuthState({
    required this.status,
    this.errorMessage,
    this.roles = const <String>[],
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final String? errorMessage;
  final List<String> roles;

  String? get primaryRole => roles.isEmpty ? null : roles.first;
  bool get isSuperadmin =>
      roles.any((role) => role.trim().toLowerCase() == 'superadmin');

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    List<String>? roles,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      roles: roles ?? this.roles,
    );
  }
}
