import 'package:flutter/material.dart';

import 'game_colors.dart';

abstract final class GameShadows {
  const GameShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x44000000),
      blurRadius: 22,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 32,
      offset: Offset(0, 18),
    ),
  ];

  static const List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: GameColors.primaryGlow,
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static List<BoxShadow> softGlow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.22),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
      const BoxShadow(
        color: Color(0x33000000),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ];
  }
}
