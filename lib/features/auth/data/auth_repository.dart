import 'package:front_arcobot/core/auth/logto_service.dart';
import 'package:front_arcobot/core/config/env.dart';

class AuthRepository {
  const AuthRepository({required LogtoService logtoService})
      : _logtoService = logtoService;

  final LogtoService _logtoService;

  Future<void> signIn() async {
    await _logtoService.signIn();
  }

  Future<void> signInWithFacebook() async {
    await _logtoService.signInWithSocial(Env.logtoFacebookConnectorTarget);
  }

  Future<void> signInWithEmail(String email) async {
    await _logtoService.signInWithEmail(email);
  }

  Future<void> signOut() async {
    await _logtoService.signOut();
  }

  Future<bool> hasSession() {
    return _logtoService.isAuthenticated();
  }

  Future<String?> getAccessToken() {
    return _logtoService.getAccessToken();
  }
}
