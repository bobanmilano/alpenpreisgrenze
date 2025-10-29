import 'package:flutter/material.dart';

class AppColors {
  // Primärfarben
  static const Color primary = Color(0xFF6F4E9C);     // Milka-Lila (mittel)
  static const Color secondary = Color(0xFFFFD700);   // Goldgelb (wie auf Milka-Packung)
  static const Color accent = Color(0xFF4A2C70);      // Dunkleres Lila für Akzente

  // Hintergrundfarben
  static const Color background = Color(0xFFFFFFFF);  // Weiß
  static const Color cardBackground = Color(0xFFF9F5FF); // Sehr helles Lila als Hintergrund

  // Textfarben
  static const Color textPrimary = Color(0xFF212121); // Dunkelgrau
  static const Color textSecondary = Color(0xFF757575); // Mittelgrau
  static const Color textDisabled = Color(0xFFBDBDBD); // Hellgrau

  // Statusfarben
  static const Color success = Color(0xFF4CAF50);     // Grün für günstiger
  static const Color warning = Color(0xFFFF9800);     // Orange für Aufschläge
  static const Color error = Color(0xFFF44336);       // Rot für Fehler
}

class AppTypography {
  // Schriftgrößen
  static const double headline1 = 32.0;
  static const double headline2 = 24.0;
  static const double headline3 = 20.0;
  static const double title = 18.0;
  static const double bodyLarge = 16.0;
  static const double body = 14.0;
  static const double bodySmall = 12.0;
  static const double caption = 10.0;

  // Schriftfamilien
  static const String primaryFont = 'Roboto';
  static const String secondaryFont = 'OpenSans';
}

class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 12.0;
  static const double xl = 16.0;
  static const double circular = 50.0;
}