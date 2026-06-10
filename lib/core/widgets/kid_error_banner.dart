import 'package:flutter/material.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';
import 'package:front_arcobot/core/widgets/arco_character.dart';

/// Error amable para pantallas de niños: personaje triste + mensaje corto.
/// Nunca agresivo (requisito de Architecture.md).
class KidErrorBanner extends StatelessWidget {
  const KidErrorBanner({
    required this.message,
    this.character = ArcoCharacter.bussy,
    super.key,
  });

  final String message;
  final ArcoCharacter character;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ArcobotKidColors.errorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArcobotKidColors.errorBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ArcoCharacterView(character: character, mood: ArcoMood.sad, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ArcobotKidColors.errorText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
