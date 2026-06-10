import 'package:flutter/material.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';

/// Avatares disponibles para estudiantes (deben coincidir con
/// STUDENT_AVATARS del backend).
class ArcoAvatars {
  const ArcoAvatars._();

  static const List<String> ids = [
    'bussy',
    'perrito',
    'ratoncito',
    'estrella',
    'cohete',
    'flor',
    'sol',
    'nube',
  ];
}

class ArcoAvatar extends StatelessWidget {
  const ArcoAvatar({
    required this.avatarId,
    this.size = 64,
    this.selected = false,
    super.key,
  });

  final String avatarId;
  final double size;
  final bool selected;

  static const Map<String, (String, Color)> _visuals = {
    'bussy': ('🐻', ArcobotColors.sunYellow),
    'perrito': ('🐶', ArcobotColors.skyBlue),
    'ratoncito': ('🐭', ArcobotColors.gameLilac),
    'estrella': ('⭐', Color(0xFFFFB020)),
    'cohete': ('🚀', ArcobotColors.coral),
    'flor': ('🌸', Color(0xFFEC4899)),
    'sol': ('☀️', Color(0xFFF59E0B)),
    'nube': ('☁️', ArcobotColors.guideTurquoise),
  };

  @override
  Widget build(BuildContext context) {
    final (emoji, color) = _visuals[avatarId] ?? ('🙂', ArcobotColors.skyBlue);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: selected ? 0.32 : 0.16),
        border: Border.all(
          color: selected ? color : color.withValues(alpha: 0.45),
          width: selected ? 3.5 : 2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.46)),
    );
  }
}
