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
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
