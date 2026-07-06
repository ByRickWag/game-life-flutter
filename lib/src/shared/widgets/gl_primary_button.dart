import 'package:flutter/material.dart';

import '../../design_system/game_design_system.dart';

/// Compatibilidade V1.
///
/// Na V2, prefira usar [GamePrimaryButton] diretamente.
class GlPrimaryButton extends StatelessWidget {
  const GlPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GamePrimaryButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
    );
  }
}
