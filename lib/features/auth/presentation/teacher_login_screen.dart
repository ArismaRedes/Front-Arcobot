import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/auth/presentation/auth_state.dart';
import 'package:front_arcobot/features/auth/presentation/login_screen.dart';
import 'package:go_router/go_router.dart';

class TeacherLoginScreen extends ConsumerStatefulWidget {
  const TeacherLoginScreen({super.key});

  static const routePath = '/teacher-login';

  @override
  ConsumerState<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends ConsumerState<TeacherLoginScreen> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo valido')),
      );
      return;
    }
    await ref.read(authControllerProvider.notifier).signInWithEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final loading = authState.status == AuthStatus.loading;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 440;

    return Scaffold(
      backgroundColor: _Palette.bg,
      body: CustomPaint(
        painter: const _GridPainter(),
        child: Stack(
          children: [
            const Positioned(
              top: -140,
              right: -100,
              child: _Blob(size: 420, color: Color(0x284ECBA0)),
            ),
            const Positioned(
              bottom: -160,
              left: -120,
              child: _Blob(size: 400, color: Color(0x281A4A68)),
            ),
            SafeArea(
              child: Align(
                alignment: const Alignment(0, -0.2),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _LoginCard(
                      emailController: _emailController,
                      loading: loading,
                      errorMessage: authState.errorMessage,
                      onBack: () => context.go(LoginScreen.routePath),
                      onEmailSubmitted: _submitEmail,
                      onGoogleSignIn: () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(),
                      onFacebookSignIn: () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithFacebook(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailController,
    required this.loading,
    required this.errorMessage,
    required this.onBack,
    required this.onEmailSubmitted,
    required this.onGoogleSignIn,
    required this.onFacebookSignIn,
  });

  final TextEditingController emailController;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onEmailSubmitted;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onFacebookSignIn;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 440;
    final h = compact ? 20.0 : 36.0;
    final v = compact ? 24.0 : 40.0;

    return Container(
      padding: EdgeInsets.fromLTRB(h, 20, h, v),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.border, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: _BackButton(onPressed: onBack),
          ),
          const SizedBox(height: 8),
          const _Brand(),
          const SizedBox(height: 24),
          const Text(
            'Acceso al panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Inicia sesion para gestionar tus estudiantes.',
            style: TextStyle(
              color: _Palette.subtle,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: errorMessage!),
          ],
          const SizedBox(height: 22),
          const Text(
            'CORREO INSTITUCIONAL',
            style: TextStyle(
              color: _Palette.subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          _EmailField(
            controller: emailController,
            enabled: !loading,
            onSubmitted: (_) => onEmailSubmitted(),
          ),
          const SizedBox(height: 8),
          const Text(
            'La contrasena se ingresara de forma segura en Logto.',
            style: TextStyle(
              color: _Palette.hint,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onEmailSubmitted,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _Palette.bg,
                      ),
                    )
                  : const Icon(
                      Icons.login_rounded,
                      color: _Palette.bg,
                      size: 17,
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: _Palette.accent,
                disabledBackgroundColor: _Palette.accent.withValues(alpha: 0.6),
                foregroundColor: _Palette.bg,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              label: Text(loading ? 'Conectando...' : 'Continuar con correo'),
            ),
          ),
          const SizedBox(height: 20),
          const _Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialBtn(
                onPressed: loading ? null : onGoogleSignIn,
                child: SvgPicture.string(_googleSvg, width: 22, height: 22),
              ),
              const SizedBox(width: 10),
              _SocialBtn(
                onPressed: loading ? null : onFacebookSignIn,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1877F2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'f',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: _Palette.accent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'AB',
            style: TextStyle(
              color: _Palette.bg,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'ArcoBot',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' / docentes',
                style: TextStyle(
                  color: _Palette.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: _Palette.input,
          foregroundColor: _Palette.subtle,
          side: const BorderSide(color: _Palette.border, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: const Icon(Icons.arrow_back_rounded, size: 15),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6B2A2A), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFF0857A),
              size: 15,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFF0857A),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: Color(0xFFE8F0F8),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'tu.correo@institucion.edu',
        hintStyle: const TextStyle(color: _Palette.hint, fontSize: 13),
        prefixIcon: const Icon(
          Icons.mail_outline_rounded,
          color: _Palette.subtle,
          size: 17,
        ),
        filled: true,
        fillColor: _Palette.input,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Palette.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Palette.accent, width: 1),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Palette.border, width: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      onSubmitted: onSubmitted,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: _Palette.input, thickness: 1, height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o tambien',
            style: TextStyle(
              color: _Palette.hint,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: _Palette.input, thickness: 1, height: 1),
        ),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: _Palette.input,
          side: const BorderSide(color: _Palette.border, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 40.0;
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Palette {
  const _Palette._();

  static const bg = Color(0xFF0F1E2E);
  static const card = Color(0xFF162536);
  static const border = Color(0xFF2A3F55);
  static const input = Color(0xFF1E3347);
  static const accent = Color(0xFF4ECBA0);
  static const subtle = Color(0xFF5A7A96);
  static const hint = Color(0xFF3A5570);
}

const String _googleSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M21.805 12.23c0-.682-.055-1.368-.173-2.04H12.24v3.862h5.38a4.604 4.604 0 0 1-1.994 3.021v2.505h3.228c1.896-1.745 2.951-4.323 2.951-7.348Z" fill="#4285F4"/>
  <path d="M12.24 22c2.686 0 4.952-.882 6.603-2.422l-3.228-2.505c-.898.611-2.055.957-3.375.957-2.6 0-4.806-1.754-5.595-4.112H3.314v2.583A9.966 9.966 0 0 0 12.24 22Z" fill="#34A853"/>
  <path d="M6.645 13.918a5.98 5.98 0 0 1 0-3.836V7.5H3.314a9.966 9.966 0 0 0 0 8.999l3.331-2.58Z" fill="#FBBC04"/>
  <path d="M12.24 5.97c1.462 0 2.776.503 3.81 1.491l2.836-2.836C17.188 3.043 14.925 2 12.24 2A9.966 9.966 0 0 0 3.314 7.5l3.331 2.583C7.434 7.724 9.64 5.97 12.24 5.97Z" fill="#EA4335"/>
</svg>
''';