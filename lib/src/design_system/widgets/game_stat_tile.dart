import 'package:flutter/material.dart';

import '../game_colors.dart';
import '../game_spacing.dart';
import '../game_text_styles.dart';
import 'game_compact_card.dart';

class GameStatTile extends StatelessWidget {
  const GameStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = GameColors.primary,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GameCompactCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.statValue),
                const SizedBox(height: 2),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
