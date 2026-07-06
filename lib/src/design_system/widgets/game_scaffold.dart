import 'package:flutter/material.dart';

import '../game_colors.dart';
import '../game_spacing.dart';
import '../game_text_styles.dart';

class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.withSafeArea = true,
    this.padding = GameSpacing.screen,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool withSafeArea;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: body,
    );

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: GameTextStyles.caption.copyWith(color: GameColors.textMuted),
              ),
          ],
        ),
        actions: actions,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: GameColors.appBackgroundGradient),
        child: withSafeArea ? SafeArea(child: content) : content,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
