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
    this.subject,
    this.roles = const <String>[],
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final String? errorMessage;
  final String? subject;
  final List<String> roles;

  String? get primaryRole => roles.isEmpty ? null : roles.first;
  bool get isSuperadmin =>
      roles.any((role) => role.trim().toLowerCase() == 'superadmin');

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    Object? subject = _unset,
    List<String>? roles,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      subject: identical(subject, _unset) ? this.subject : subject as String?,
      roles: roles ?? this.roles,
    );
  }
}

const Object _unset = Object();
