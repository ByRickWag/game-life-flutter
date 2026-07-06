import 'package:flutter/material.dart';

import '../game_colors.dart';
import '../game_spacing.dart';
import '../game_text_styles.dart';
import 'game_button.dart';
import 'game_highlight_card.dart';

class GameEmptyState extends StatelessWidget {
  const GameEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return GameHighlightCard(
      accentColor: GameColors.primary,
      showCrownGlow: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameColors.primary.withValues(alpha: 0.18),
              border: Border.all(color: GameColors.primary.withValues(alpha: 0.32)),
            ),
            child: Icon(icon, color: GameColors.primarySoft, size: 30),
          ),
          const SizedBox(height: GameSpacing.md),
          Text(title, textAlign: TextAlign.center, style: GameTextStyles.cardTitle),
          const SizedBox(height: GameSpacing.xs),
          Text(message, textAlign: TextAlign.center, style: GameTextStyles.body),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: GameSpacing.md),
            GameSecondaryButton(
              label: actionLabel!,
              icon: Icons.add_rounded,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
