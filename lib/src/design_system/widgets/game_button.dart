import 'package:flutter/material.dart';

import '../game_colors.dart';
import '../game_motion.dart';
import '../game_radius.dart';
import '../game_spacing.dart';
import '../game_text_styles.dart';

enum _GameButtonKind { primary, secondary, danger }

class GamePrimaryButton extends StatelessWidget {
  const GamePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return _GameButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isExpanded: isExpanded,
      kind: _GameButtonKind.primary,
    );
  }
}

class GameSecondaryButton extends StatelessWidget {
  const GameSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return _GameButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isExpanded: isExpanded,
      kind: _GameButtonKind.secondary,
    );
  }
}

class GameDangerButton extends StatelessWidget {
  const GameDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return _GameButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isExpanded: isExpanded,
      kind: _GameButtonKind.danger,
    );
  }
}

class _GameButton extends StatefulWidget {
  const _GameButton({
    required this.label,
    required this.onPressed,
    required this.kind,
    this.icon,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;
  final _GameButtonKind kind;

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colors = _colorsFor(widget.kind, enabled);

    final button = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: GameMotion.fast,
      curve: GameMotion.curve,
      child: Material(
        color: colors.background,
        borderRadius: GameRadius.button,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          splashColor: colors.foreground.withValues(alpha: 0.10),
          highlightColor: colors.foreground.withValues(alpha: 0.06),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: GameSpacing.button,
            decoration: BoxDecoration(
              borderRadius: GameRadius.button,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: colors.foreground, size: 20),
                  const SizedBox(width: GameSpacing.xs),
                ],
                if (widget.isExpanded)
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GameTextStyles.button.copyWith(color: colors.foreground),
                    ),
                  )
                else
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GameTextStyles.button.copyWith(color: colors.foreground),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isExpanded) return SizedBox(width: double.infinity, child: button);
    return button;
  }

  _ButtonColors _colorsFor(_GameButtonKind kind, bool enabled) {
    if (!enabled) {
      return const _ButtonColors(
        background: GameColors.surfaceOverlay,
        foreground: GameColors.textDisabled,
        border: GameColors.borderSoft,
      );
    }

    return switch (kind) {
      _GameButtonKind.primary => const _ButtonColors(
          background: GameColors.primary,
          foreground: GameColors.textPrimary,
          border: GameColors.primary,
        ),
      _GameButtonKind.secondary => const _ButtonColors(
          background: GameColors.surfaceRaised,
          foreground: GameColors.textPrimary,
          border: GameColors.border,
        ),
      _GameButtonKind.danger => const _ButtonColors(
          background: GameColors.danger,
          foreground: GameColors.textPrimary,
          border: GameColors.danger,
        ),
    };
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
