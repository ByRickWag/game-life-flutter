import 'package:flutter/material.dart';

import '../../design_system/game_design_system.dart';

/// Compatibilidade V1.
///
/// Na V2, prefira usar [GameCard] diretamente.
class GlCard extends StatelessWidget {
  const GlCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      padding: padding,
      child: child,
    );
  }
}
