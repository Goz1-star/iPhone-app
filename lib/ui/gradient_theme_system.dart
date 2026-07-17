import 'package:flutter/material.dart';

class GradientThemeSystem {
  const GradientThemeSystem._();

  static const deepViolet = Color(0xFF5525B6);
  static const fortuneGold = Color(0xFFFFC84D);
  static const tangerine = Color(0xFFFF7A3D);
  static const rose = Color(0xFFFF3F8B);
  static const ink = Color(0xFF261136);
  static const card = Color(0xFFFFFCF5);
  static const cardSoft = Color(0xFFFFF1D9);

  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [fortuneGold, tangerine, rose, deepViolet],
    stops: [0.0, 0.34, 0.68, 1.0],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, cardSoft],
  );

  static const actionGradient = LinearGradient(
    colors: [Color(0xFFFFD76B), Color(0xFFFF5C74), Color(0xFF7E4DFF)],
  );

  static BoxDecoration glassCard({double radius = 28}) {
    return BoxDecoration(
      gradient: cardGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.66), width: 1.4),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5B1D73).withOpacity(0.18),
          blurRadius: 28,
          offset: const Offset(0, 18),
        ),
      ],
    );
  }
}
