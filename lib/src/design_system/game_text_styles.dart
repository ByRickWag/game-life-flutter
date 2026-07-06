import 'package:flutter/material.dart';

import 'game_colors.dart';

abstract final class GameTextStyles {
  const GameTextStyles._();

  static const TextStyle display = TextStyle(
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.7,
    color: GameColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.35,
    color: GameColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w800,
    color: GameColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w800,
    color: GameColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: GameColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: GameColors.textMuted,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 20,
    height: 1.1,
    fontWeight: FontWeight.w900,
    color: GameColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );
}
