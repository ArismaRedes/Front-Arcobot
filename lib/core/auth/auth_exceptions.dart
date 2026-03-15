enum AppAuthExceptionCode {
  invalidInput,
  signInCancelled,
  authCallbackFailed,
  sessionExpired,
  backendUnauthorized,
  backendInvalidProfile,
  organizationMismatch,
}

class AppAuthException implements Exception {
  const AppAuthException(this.code, {this.cause});

  final AppAuthExceptionCode code;
  final Object? cause;

  @override
  String toString() => 'AppAuthException($code)';
}
