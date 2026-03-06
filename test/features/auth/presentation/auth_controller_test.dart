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
    this.signInWithEmailAndPasswordHandler,
    this.getAccessTokenHandler,
  });

  final Future<bool> Function() hasSessionHandler;
  final Future<void> Function()? signInHandler;
  final Future<void> Function()? signInWithFacebookHandler;
  final Future<void> Function()? signOutHandler;
  final Future<void> Function(String email, String password)?
  signInWithEmailAndPasswordHandler;
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
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return signInWithEmailAndPasswordHandler?.call(email, password) ??
        Future.value();
  }

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

  test(
    'restoreSession sets unauthenticated when session does not exist',
    () async {
      final controller = AuthController(
        FakeAuthRepository(hasSessionHandler: () async => false),
        autoRestore: false,
      );
      addTearDown(controller.dispose);

      await controller.restoreSession();

      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.errorMessage, isNull);
    },
  );

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
    expect(
      controller.state.errorMessage,
      'No pudimos restaurar tu sesion. Inicia sesion nuevamente.',
    );
  });

  test('signInWithEmailAndPassword sets authenticated on success', () async {
    final controller = AuthController(
      FakeAuthRepository(
        hasSessionHandler: () async => false,
        signInWithEmailAndPasswordHandler: (_, __) async {},
      ),
      autoRestore: false,
    );
    addTearDown(controller.dispose);

    await controller.signInWithEmailAndPassword(
      email: 'docente@colegio.edu',
      password: 'test1234',
    );

    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.errorMessage, isNull);
  });

  test(
    'signInWithEmailAndPassword sets failure when repository throws',
    () async {
      final controller = AuthController(
        FakeAuthRepository(
          hasSessionHandler: () async => false,
          signInWithEmailAndPasswordHandler: (_, __) async =>
              throw Exception('login error'),
        ),
        autoRestore: false,
      );
      addTearDown(controller.dispose);

      await controller.signInWithEmailAndPassword(
        email: 'docente@colegio.edu',
        password: 'bad-password',
      );

      expect(controller.state.status, AuthStatus.failure);
      expect(
        controller.state.errorMessage,
        'No se pudo iniciar sesion. Intenta nuevamente.',
      );
    },
  );

  test(
    'signInWithEmailAndPassword maps guard.invalid_input to friendly text',
    () async {
      final controller = AuthController(
        FakeAuthRepository(
          hasSessionHandler: () async => false,
          signInWithEmailAndPasswordHandler: (_, __) async =>
              throw Exception('guard.invalid_input'),
        ),
        autoRestore: false,
      );
      addTearDown(controller.dispose);

      await controller.signInWithEmailAndPassword(
        email: 'docente@colegio.edu',
        password: 'bad-password',
      );

      expect(controller.state.status, AuthStatus.failure);
      expect(
        controller.state.errorMessage,
        'No pudimos validar los datos. Revisa el correo y la contrasena.',
      );
    },
  );
}
