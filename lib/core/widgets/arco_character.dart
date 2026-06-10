import 'package:flutter/material.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';

/// Personajes de Miniarco.
enum ArcoCharacter { bussy, perrito, ratoncito }

/// Estados emocionales según Architecture.md: celebran, se entristecen,
/// se sorprenden, esperan.
enum ArcoMood { happy, sad, celebrating, waiting, surprised }

/// Muestra un personaje en un estado emocional.
///
/// Busca el asset `assets/images/characters/{personaje}_{estado}.png`
/// (ej. `bussy_sad.png`). Mientras no existan las ilustraciones finales,
/// dibuja una carita de respaldo con el color y la expresión del personaje,
/// así las pantallas ya pueden integrarse sin esperar los assets.
class ArcoCharacterView extends StatelessWidget {
  const ArcoCharacterView({
    required this.character,
    required this.mood,
    this.size = 64,
    super.key,
  });

  final ArcoCharacter character;
  final ArcoMood mood;
  final double size;

  String get _assetPath =>
      'assets/images/characters/${character.name}_${mood.name}.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _FallbackFace(
          character: character,
          mood: mood,
          size: size,
        ),
      ),
    );
  }
}

class _FallbackFace extends StatelessWidget {
  const _FallbackFace({
    required this.character,
    required this.mood,
    required this.size,
  });

  final ArcoCharacter character;
  final ArcoMood mood;
  final double size;

  Color get _color => switch (character) {
        ArcoCharacter.bussy => ArcobotColors.sunYellow,
        ArcoCharacter.perrito => ArcobotColors.skyBlue,
        ArcoCharacter.ratoncito => ArcobotColors.gameLilac,
      };

  IconData get _faceIcon => switch (mood) {
        ArcoMood.happy => Icons.sentiment_satisfied_alt_rounded,
        ArcoMood.sad => Icons.sentiment_dissatisfied_rounded,
        ArcoMood.celebrating => Icons.sentiment_very_satisfied_rounded,
        ArcoMood.waiting => Icons.sentiment_neutral_rounded,
        ArcoMood.surprised => Icons.sentiment_very_dissatisfied_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withValues(alpha: 0.22),
        border: Border.all(color: _color, width: size * 0.045),
      ),
      alignment: Alignment.center,
      child: Icon(
        _faceIcon,
        size: size * 0.62,
        color: Color.lerp(_color, ArcobotColors.textPrimary, 0.35),
      ),
    );
  }
}
