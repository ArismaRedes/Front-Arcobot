import 'package:flutter_test/flutter_test.dart';
import 'package:front_arcobot/features/auth/data/auth_repository.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    required this.hasSessionHandler,
    this.signInHandler,
    this.signInWithFacebookHandler,
    this.signOutHandler,
    this.signInWithTeacherCredentialsHandler,
    this.getAccessTokenHandler,
  });

  final Future<bool> Function() hasSessionHandler;
  final Future<void> Function()? signInHandler;
  final Future<void> Function()? signInWithFacebookHandler;
  final Future<void> Function()? signOutHandler;
  final Future<void> Function()? signInWithTeacherCredentialsHandler;
  final Future<String?> Function()? getAccessTokenHandler;

  @override
  Future<bool> hasSession() => hasSessionHandler();

  @override
  Future<void> signIn() => signInHandler?.call() ?? Future.value();

  @override
  Future<void> signInWithFacebook() =>
      signInWithFacebookHandler?.call() ?? Future.value();

  @override
  Future<void> signOut() => signOutHandler?.call() ?? Future.value();

  @override
  Future<void> signInWithTeacherCredentials() =>
      signInWithTeacherCredentialsHandler?.call() ?? Future.value();

  @override
  Future<String?> getAccessToken() =>
      getAccessTokenHandler?.call() ?? Future.value(null);
}

void main() {
  test('restoreSession sets authenticated when session exists', () async {
    final controller = AuthController(
      FakeAuthRepository(hasSessionHandler: () async => true),
      autoRestore: false,
    );
    addTearDown(controller.dispose);

    await controller.restoreSession();

    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.errorMessage, isNull);
  });

  test('restoreSession sets unauthenticated when session does not exist',
      () async {
    final controller = AuthController(
      FakeAuthRepository(hasSessionHandler: () async => false),
      autoRestore: false,
    );
    addTearDown(controller.dispose);

    await controller.restoreSession();

    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(controller.state.errorMessage, isNull);
  });

  test('restoreSession sets failure when session check throws', () async {
    final controller = AuthController(
      FakeAuthRepository(
        hasSessionHandler: () async => throw Exception('session check failed'),
      ),
      autoRestore: false,
    );
    addTearDown(controller.dispose);

    await controller.restoreSession();

    expect(controller.state.status, AuthStatus.failure);
    expect(controller.state.errorMessage, contains('session check failed'));
  });
}
