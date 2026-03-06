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
