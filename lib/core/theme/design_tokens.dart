import 'package:flutter/material.dart';

class ArcobotColors {
  const ArcobotColors._();

  static const Color guideTurquoise = Color(0xFF19BFB7);
  static const Color skyBlue = Color(0xFF3A86FF);
  static const Color sunYellow = Color(0xFFFFCB47);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color successGreen = Color(0xFF55C271);
  static const Color gameLilac = Color(0xFFA78BFA);

  static const Color backgroundCloud = Color(0xFFF7FBFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2A37);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color softBorder = Color(0xFFDDE7F0);

  static const List<Color> screenGradient = [
    Color(0xFFF7FBFF),
    Color(0xFFEAF5FF),
  ];

  static const List<Color> heroGradient = [
    Color(0xFF19BFB7),
    Color(0xFF3A86FF),
  ];
}

/// Paleta para pantallas de niños (pre-lectores y lectores tempranos).
/// Colores saturados, alegres y de alto contraste sobre fondos claros.
class ArcobotKidColors {
  const ArcobotKidColors._();

  static const Color action = ArcobotColors.guideTurquoise;
  static const Color actionDark = Color(0xFF0E9C95);
  static const Color textPrimary = Color(0xFF1A2E44);
  static const Color textSecondary = Color(0xFF6B7E95);

  static const Color bubbleBlue = Color(0xFFBFE3FF);
  static const Color bubbleMint = Color(0xFFB5F0E4);
  static const Color bubbleSun = Color(0xFFFFE9B8);
  static const Color bubblePink = Color(0xFFFFD6EC);

  static const Color errorSurface = Color(0xFFFFF3ED);
  static const Color errorBorder = Color(0xFFFFD7C8);
  static const Color errorText = Color(0xFFC95A2B);

  static const List<Color> screenGradient = [
    Color(0xFFE8F4FF),
    Color(0xFFEDF9FF),
    Color(0xFFE6FFF6),
  ];

  static const List<Color> actionGradient = [
    Color(0xFF2BD4CB),
    Color(0xFF15A8A1),
  ];
}

/// Paleta oscura para el panel de adultos (docentes y admins).
class ArcobotPanelColors {
  const ArcobotPanelColors._();

  static const Color bg = Color(0xFF0F1E2E);
  static const Color card = Color(0xFF162536);
  static const Color border = Color(0xFF2A3F55);
  static const Color input = Color(0xFF1E3347);
  static const Color accent = ArcobotColors.guideTurquoise;
  static const Color onAccent = Color(0xFF06302D);
  static const Color textOnDark = Color(0xFFE8F0F8);
  static const Color subtle = Color(0xFF7C97B2);
  static const Color hint = Color(0xFF4A6580);
  static const Color errorSurface = Color(0xFF3A1A1A);
  static const Color errorBorder = Color(0xFF6B2A2A);
  static const Color errorText = Color(0xFFF0857A);
}

class ArcobotSpacing {
  const ArcobotSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

class ArcobotRadii {
  const ArcobotRadii._();

  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double pill = 999;
}

class ArcobotShadows {
  const ArcobotShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x1A14315C),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
