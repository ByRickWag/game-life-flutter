import 'package:flutter/material.dart';

import '../game_colors.dart';
import '../game_radius.dart';
import '../game_spacing.dart';
import '../game_text_styles.dart';

class GameChip extends StatelessWidget {
  const GameChip({
    super.key,
    required this.label,
    this.icon,
    this.color = GameColors.primary,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? GameColors.textPrimary : GameColors.textSecondary;

    return Material(
      color: Colors.transparent,
      borderRadius: GameRadius.chip,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: GameRadius.chip,
        child: Container(
          padding: GameSpacing.chip,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.24),
                      color.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : GameColors.surfaceSoft.withValues(alpha: 0.88),
            borderRadius: GameRadius.chip,
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.55) : GameColors.borderSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? color : GameColors.textMuted),
                const SizedBox(width: GameSpacing.xs),
              ],
              Text(
                label,
                style: GameTextStyles.caption.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
