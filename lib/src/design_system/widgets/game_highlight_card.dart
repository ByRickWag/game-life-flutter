import 'package:flutter/material.dart';

import '../game_colors.dart';
import '../game_radius.dart';
import '../game_shadows.dart';
import '../game_spacing.dart';
import 'game_card.dart';

class GameHighlightCard extends StatelessWidget {
  const GameHighlightCard({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor = GameColors.primary,
    this.padding = GameSpacing.cardLarge,
    this.showCrownGlow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final bool showCrownGlow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: GameRadius.cardLarge,
        boxShadow: showCrownGlow
            ? GameShadows.softGlow(accentColor)
            : GameShadows.card,
      ),
      child: ClipRRect(
        borderRadius: GameRadius.cardLarge,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: GameColors.premiumGradient(accent: accentColor),
                ),
              ),
            ),
            Positioned(
              right: -48,
              top: -54,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.16),
                ),
              ),
            ),
            Positioned(
              left: -38,
              bottom: -46,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.reward.withValues(alpha: 0.08),
                ),
              ),
            ),
            GameCard(
              onTap: onTap,
              padding: padding,
              backgroundColor: Colors.transparent,
              borderColor: accentColor.withValues(alpha: 0.30),
              accentColor: accentColor.withValues(alpha: 0.70),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
