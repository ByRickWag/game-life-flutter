import 'package:flutter/material.dart';

import '../game_colors.dart';
import '../game_motion.dart';
import '../game_radius.dart';
import '../game_shadows.dart';
import '../game_spacing.dart';

class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = GameSpacing.card,
    this.backgroundColor = GameColors.surface,
    this.borderColor = GameColors.borderSoft,
    this.showShadow = false,
    this.gradient,
    this.glowColor,
    this.accentColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final bool showShadow;
  final Gradient? gradient;
  final Color? glowColor;
  final Color? accentColor;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = GameRadius.card;
    final shadow = widget.glowColor == null
        ? (widget.showShadow ? GameShadows.card : null)
        : GameShadows.softGlow(widget.glowColor!);

    Widget content = Stack(
      children: [
        if (widget.accentColor != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: widget.accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(GameRadius.lg),
                ),
              ),
            ),
          ),
        Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ],
    );

    if (widget.onTap != null) {
      content = InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        borderRadius: borderRadius,
        splashColor: GameColors.primary.withValues(alpha: 0.12),
        highlightColor: GameColors.primary.withValues(alpha: 0.05),
        child: content,
      );
    }

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: GameMotion.fast,
      curve: GameMotion.curve,
      child: AnimatedContainer(
        duration: GameMotion.fast,
        curve: GameMotion.curve,
        decoration: BoxDecoration(
          color: widget.gradient == null ? widget.backgroundColor : null,
          gradient: widget.gradient,
          borderRadius: borderRadius,
          border: Border.all(color: widget.borderColor),
          boxShadow: shadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      ),
    );
  }
}
