import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_arcobot/features/auth/presentation/auth_provider.dart';
import 'package:front_arcobot/features/auth/presentation/class_code_scanner_screen.dart';
import 'package:front_arcobot/features/auth/presentation/teacher_login_screen.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _classCodeController;
  late final AnimationController _ambientController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _classCodeController = TextEditingController();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _classCodeController.dispose();
    super.dispose();
  }

  void _goToTeacherLogin() {
    context.go(TeacherLoginScreen.routePath);
  }

  void _joinClass() {
    final code = _classCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el codigo de la clase')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Codigo ingresado: $code')));
  }

  Future<void> _scanClassCode() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ClassCodeScannerScreen()),
    );

    if (!mounted || scannedCode == null || scannedCode.isEmpty) {
      return;
    }

    _classCodeController.text = scannedCode;
    _joinClass();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final compact = MediaQuery.sizeOf(context).width < 440;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.92, -0.64),
            end: Alignment(0.92, 0.64),
            colors: [Color(0xFFE8F4FF), Color(0xFFEDF9FF), Color(0xFFE6FFF6)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _BubblePositioned(
                top: -72,
                left: -56,
                size: 200,
                color: Color(0xFFC8E6FF),
              ),
              const _BubblePositioned(
                bottom: -42,
                right: -34,
                size: 160,
                color: Color(0xFFB8F0E0),
              ),
              const _BubblePositioned(
                top: 260,
                right: 34,
                size: 80,
                color: Color(0xFFFFE4B8),
              ),
              const _BubblePositioned(
                top: 48,
                left: 24,
                size: 50,
                color: Color(0xFFFFD6F0),
              ),
              Center(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    scrollbars: false,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 24,
                      24,
                      compact ? 16 : 24,
                      24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x55FFFFFF),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0x66FFFFFF),
                                ),
                              ),
                              child: const Text(
                                'Mini aventura',
                                style: TextStyle(
                                  color: _MiniArcoPalette.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _LoginCard(
                            controller: _classCodeController,
                            errorMessage: authState.errorMessage,
                            ambientController: _ambientController,
                            floatAnimation: _floatAnimation,
                            onScan: _scanClassCode,
                            onJoin: _joinClass,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: compact ? 16 : 24,
                child: _TeacherAccessButton(
                  onPressed: _goToTeacherLogin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherAccessButton extends StatelessWidget {
  const _TeacherAccessButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.school_rounded,
        size: 16,
        color: _MiniArcoPalette.guideGreen,
      ),
      label: const Text(
        'Soy profesor',
        style: TextStyle(
          color: _MiniArcoPalette.guideGreen,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: _MiniArcoPalette.textPrimary,
        side: const BorderSide(color: _MiniArcoPalette.guideGreen, width: 1.5),
        elevation: 0,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.controller,
    required this.errorMessage,
    required this.ambientController,
    required this.floatAnimation,
    required this.onScan,
    required this.onJoin,
  });

  final TextEditingController controller;
  final String? errorMessage;
  final AnimationController ambientController;
  final Animation<double> floatAnimation;
  final VoidCallback onScan;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF4F3F8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 32,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ACCESO DE CLASE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB0B8C9),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            _CharacterStage(
              ambientController: ambientController,
              floatAnimation: floatAnimation,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Mini Arco!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _MiniArcoPalette.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Empieza la aventura con tu clase',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _MiniArcoPalette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD7C8),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC95A2B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _QrScanButton(onPressed: onScan),
            const SizedBox(height: 18),
            const _DividerLabel(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ClassCodeField(
                    controller: controller,
                    onSubmitted: (_) => onJoin(),
                  ),
                ),
                const SizedBox(width: 10),
                _ClassJoinButton(onPressed: onJoin),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterStage extends StatelessWidget {
  const _CharacterStage({
    required this.ambientController,
    required this.floatAnimation,
  });

  final AnimationController ambientController;
  final Animation<double> floatAnimation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            right: 18,
            bottom: 26,
            child: Container(
              height: 118,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8FCFF),
                    Color(0xFFF1FAF6),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE7F1EF),
                  width: 1,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 6,
            child: Container(
              width: 148,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: _MiniArcoPalette.guideGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: const Text(
                '¡Hola! Escribe el código de tu clase',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, floatAnimation.value - 6),
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 250,
                  child: Image.asset(
                    _bussyAssetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 230,
                        height: 168,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FBFF),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE7EFFB),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🚌', style: TextStyle(fontSize: 34)),
                            SizedBox(height: 8),
                            Text(
                              'Agrega perrito_ventana.png',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _MiniArcoPalette.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: _AnimatedStarsRow(controller: ambientController),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStarsRow extends StatelessWidget {
  const _AnimatedStarsRow({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StarPulse(phase: _starPhase(controller.value, 0)),
            const SizedBox(width: 10),
            _StarPulse(phase: _starPhase(controller.value, 0.4 / 3)),
            const SizedBox(width: 10),
            _StarPulse(phase: _starPhase(controller.value, 0.8 / 3)),
          ],
        );
      },
    );
  }
}

class _StarPulse extends StatelessWidget {
  const _StarPulse({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    final opacity = 0.35 + (0.65 * phase);
    final scale = 0.82 + (0.26 * phase);

    return FadeTransition(
      opacity: AlwaysStoppedAnimation(opacity),
      child: ScaleTransition(
        scale: AlwaysStoppedAnimation(scale),
        child: const Text('⭐', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _QrScanButton extends StatelessWidget {
  const _QrScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4ECBA0), Color(0xFF2BA87A)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0x254ECBA0),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Escanear código QR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFFF0EDE8), thickness: 1, height: 1),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o escríbelo tú mismo',
            style: TextStyle(
              color: Color(0xFFC0BECE),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFFF0EDE8), thickness: 1, height: 1),
        ),
      ],
    );
  }
}

class _ClassCodeField extends StatelessWidget {
  const _ClassCodeField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: _MiniArcoPalette.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        hintText: 'Código de clase',
        hintStyle: const TextStyle(
          color: Color(0xFF9DA9BF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E8FF), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E8FF), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _MiniArcoPalette.guideGreen,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        LengthLimitingTextInputFormatter(8),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return TextEditingValue(
            text: newValue.text.toUpperCase(),
            selection: newValue.selection,
          );
        }),
      ],
      onSubmitted: onSubmitted,
    );
  }
}

class _ClassJoinButton extends StatelessWidget {
  const _ClassJoinButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _MiniArcoPalette.textPrimary,
          foregroundColor: _MiniArcoPalette.guideGreen,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Icon(Icons.arrow_forward_rounded, size: 24),
      ),
    );
  }
}

class _BubblePositioned extends StatelessWidget {
  const _BubblePositioned({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

double _starPhase(double value, double offset) {
  final shifted = (value + offset) % 1;
  final wave = shifted < 0.5 ? shifted * 2 : (1 - shifted) * 2;
  return Curves.easeInOut.transform(wave);
}

class _MiniArcoPalette {
  const _MiniArcoPalette._();

  static const textPrimary = Color(0xFF1A2E44);
  static const textSecondary = Color(0xFF8A9AB0);
  static const guideGreen = Color(0xFF4ECBA0);
}

const String _bussyAssetPath = 'assets/images/perrito_ventana.png';
