import 'package:flutter/material.dart';

import '../../design_system/game_design_system.dart';

class AttributeMultiSelectField extends StatelessWidget {
  const AttributeMultiSelectField({
    super.key,
    required this.attributes,
    required this.selectedIds,
    required this.onChanged,
    this.maxSelection = 3,
    this.title = 'Atributos vinculados',
    this.subtitle = 'Escolha até 3 atributos. O primeiro selecionado será o principal.',
  });

  final List<Map<String, Object?>> attributes;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final int maxSelection;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (attributes.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: const Icon(Icons.auto_awesome_rounded),
        ),
        child: Text(
          'Nenhum atributo encontrado.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final reachedLimit = selectedIds.length >= maxSelection;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: title,
        prefixIcon: const Icon(Icons.auto_awesome_rounded),
        helperText: '$subtitle\n${selectedIds.length}/$maxSelection selecionados.',
        helperMaxLines: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedIds.isNotEmpty) ...[
            _SelectedOrderBar(
              attributes: attributes,
              selectedIds: selectedIds,
              onChanged: onChanged,
            ),
            const SizedBox(height: GameSpacing.sm),
            Divider(color: GameColors.borderSoft.withValues(alpha: 0.7), height: 1),
            const SizedBox(height: GameSpacing.sm),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final attribute in attributes)
                _AttributePill(
                  id: _readString(attribute, 'id'),
                  name: _readString(attribute, 'name', fallback: 'Atributo'),
                  selectedIds: selectedIds,
                  reachedLimit: reachedLimit,
                  maxSelection: maxSelection,
                  onChanged: onChanged,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _readString(
    Map<String, Object?> map,
    String key, {
    String fallback = '',
  }) {
    final value = map[key];
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _SelectedOrderBar extends StatelessWidget {
  const _SelectedOrderBar({
    required this.attributes,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<Map<String, Object?>> attributes;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ordem de peso: 1º principal • 2º apoio • 3º suporte',
          style: GameTextStyles.caption.copyWith(color: GameColors.textSecondary),
        ),
        const SizedBox(height: GameSpacing.xs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < selectedIds.length; index++)
              _SelectedOrderChip(
                name: _attributeName(selectedIds[index]),
                index: index,
                total: selectedIds.length,
                onMoveLeft: index == 0 ? null : () => _move(index, index - 1),
                onMoveRight: index >= selectedIds.length - 1 ? null : () => _move(index, index + 1),
                onRemove: () => _remove(index),
              ),
          ],
        ),
      ],
    );
  }

  String _attributeName(String id) {
    for (final attribute in attributes) {
      if ((attribute['id']?.toString() ?? '') == id) {
        final name = attribute['name']?.toString().trim() ?? '';
        return name.isEmpty ? 'Atributo' : name;
      }
    }
    return 'Atributo';
  }

  void _move(int from, int to) {
    final next = List<String>.of(selectedIds);
    final item = next.removeAt(from);
    next.insert(to, item);
    onChanged(next);
  }

  void _remove(int index) {
    final next = List<String>.of(selectedIds)..removeAt(index);
    onChanged(next);
  }
}

class _SelectedOrderChip extends StatelessWidget {
  const _SelectedOrderChip({
    required this.name,
    required this.index,
    required this.total,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onRemove,
  });

  final String name;
  final int index;
  final int total;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GameRadius.md),
        color: GameColors.surfaceOverlay.withValues(alpha: 0.8),
        border: Border.all(color: GameColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameColors.primary.withValues(alpha: 0.18),
              border: Border.all(color: GameColors.primary.withValues(alpha: 0.45)),
            ),
            child: Text(
              '${index + 1}',
              style: GameTextStyles.caption.copyWith(
                color: GameColors.primarySoft,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: GameTextStyles.caption.copyWith(
              color: GameColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (total > 1) ...[
            const SizedBox(width: 2),
            _TinyIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Subir prioridade',
              onPressed: onMoveLeft,
            ),
            _TinyIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Diminuir prioridade',
              onPressed: onMoveRight,
            ),
          ],
          _TinyIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Remover atributo',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _TinyIconButton extends StatelessWidget {
  const _TinyIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(GameRadius.pill),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? GameColors.textDisabled : GameColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AttributePill extends StatelessWidget {
  const _AttributePill({
    required this.id,
    required this.name,
    required this.selectedIds,
    required this.reachedLimit,
    required this.maxSelection,
    required this.onChanged,
  });

  final String id;
  final String name;
  final List<String> selectedIds;
  final bool reachedLimit;
  final int maxSelection;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = selectedIds.indexOf(id);
    final selected = selectedIndex >= 0;
    final disabled = reachedLimit && !selected;
    final opacity = disabled ? 0.42 : 1.0;

    return AnimatedOpacity(
      duration: GameMotion.fast,
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(GameRadius.pill),
          onTap: disabled ? null : () => _toggle(context),
          child: AnimatedContainer(
            duration: GameMotion.fast,
            curve: GameMotion.curve,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GameRadius.pill),
              color: selected
                  ? GameColors.primary.withValues(alpha: 0.18)
                  : GameColors.surfaceRaised.withValues(alpha: disabled ? 0.45 : 1),
              border: Border.all(
                color: selected
                    ? GameColors.primary
                    : disabled
                        ? GameColors.borderSoft.withValues(alpha: 0.6)
                        : GameColors.border,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: GameColors.primary.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: GameMotion.fast,
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? GameColors.primary
                        : GameColors.surfaceOverlay,
                    border: Border.all(
                      color: selected ? GameColors.primary : GameColors.borderSoft,
                    ),
                  ),
                  child: selected
                      ? Text(
                          '${selectedIndex + 1}',
                          style: GameTextStyles.caption.copyWith(
                            color: GameColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : Icon(
                          Icons.add_rounded,
                          size: 15,
                          color: disabled ? GameColors.textDisabled : GameColors.textSecondary,
                        ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: GameTextStyles.body.copyWith(
                    color: selected
                        ? GameColors.primarySoft
                        : disabled
                            ? GameColors.textDisabled
                            : GameColors.textPrimary,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(BuildContext context) {
    final next = List<String>.of(selectedIds);

    if (next.contains(id)) {
      next.remove(id);
      onChanged(next);
      return;
    }

    if (next.length >= maxSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Escolha no máximo $maxSelection atributos.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    next.add(id);
    onChanged(next);
  }
}
