import 'package:flutter/material.dart';
import 'package:front_arcobot/core/config/app_assets.dart';
import 'package:front_arcobot/core/widgets/arco_character.dart';
import 'package:front_arcobot/features/preload/presentation/preload_screen.dart'
    show decodePreloadDotLottie;
import 'package:lottie/lottie.dart';

/// Indicador de carga con personalidad: animación Lottie de Arco en loop.
/// Si el asset falla, muestra un personaje esperando con pulso suave —
/// nunca un spinner genérico (requisito de Architecture.md).
class ArcoLoader extends StatelessWidget {
  const ArcoLoader({
    this.size = 140,
    this.message,
    super.key,
  });

  final double size;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            AppAssets.preloadLottie,
            fit: BoxFit.contain,
            repeat: true,
            decoder: decodePreloadDotLottie,
            errorBuilder: (_, __, ___) => _WaitingCharacter(size: size),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 10),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _WaitingCharacter extends StatefulWidget {
  const _WaitingCharacter({required this.size});

  final double size;

  @override
  State<_WaitingCharacter> createState() => _WaitingCharacterState();
}

class _WaitingCharacterState extends State<_WaitingCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.04).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: ArcoCharacterView(
        character: ArcoCharacter.bussy,
        mood: ArcoMood.waiting,
        size: widget.size * 0.8,
      ),
    );
  }
}
