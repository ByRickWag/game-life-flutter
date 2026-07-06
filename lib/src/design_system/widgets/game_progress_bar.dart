import 'package:flutter/material.dart';

import '../game_colors.dart';
import '../game_motion.dart';
import '../game_radius.dart';

class GameProgressBar extends StatelessWidget {
  const GameProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color = GameColors.success,
    this.backgroundColor = GameColors.surfaceOverlay,
    this.showGlow = false,
  });

  final double value;
  final double height;
  final Color color;
  final Color backgroundColor;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: GameRadius.chip,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: GameColors.borderSoft.withValues(alpha: 0.48)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: GameMotion.slow,
                curve: GameMotion.curve,
                height: height,
                width: constraints.maxWidth * clamped,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.78),
                      color,
                      GameColors.textPrimary.withValues(alpha: 0.16),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: showGlow
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
