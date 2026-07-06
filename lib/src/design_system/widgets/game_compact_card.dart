import 'package:flutter/material.dart';

import '../game_colors.dart';
import '../game_spacing.dart';
import 'game_card.dart';

class GameCompactCard extends StatelessWidget {
  const GameCompactCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(GameSpacing.sm),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      padding: padding,
      backgroundColor: GameColors.surfaceSoft,
      child: child,
    );
  }
}
