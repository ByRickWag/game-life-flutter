import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/health_repository.dart';
import '../../design_system/game_design_system.dart';
import '../habits/habit_form_screen.dart';
import '../habits/habit_list_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _repository = HealthRepository();
  late Future<HealthOverview> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.getOverview();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.getOverview());
    await _future;
  }

  Future<void> _addWater(double amount) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final result = await _repository.addWater(amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao registrar água: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addCustomWater() async {
    final value = await _askNumber(
      title: 'Registrar água',
      label: 'Quantidade em ml',
      initialValue: '250',
      icon: Icons.water_drop_rounded,
    );
    if (value == null) return;
    await _addWater(value);
  }

  Future<void> _addFoodLog(Habit habit) async {
    final result = await showDialog<_FoodLogInput>(
      context: context,
      builder: (context) => _FoodLogDialog(habit: habit),
    );

    if (result == null || _busy) return;
    setState(() => _busy = true);

    try {
      final logResult = await _repository.addFoodLog(
        habit: habit,
        value: result.value,
        note: result.note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(logResult.message)));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao registrar consumo: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claimFoodLimit(Habit habit) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final result = await _repository.claimFoodLimit(habit);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao validar limite: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<double?> _askNumber({
    required String title,
    required String label,
    required String initialValue,
    required IconData icon,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Registrar')),
        ],
      ),
    );

    if (confirmed != true) return null;
    final parsed = double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
    if (parsed <= 0) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um valor maior que zero.')));
      return null;
    }
    return parsed;
  }

  Future<void> _openHabitForm() async {
    await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const HabitFormScreen()));
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openHabitList() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HabitListScreen()));
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<HealthOverview>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data;

            if (snapshot.connectionState == ConnectionState.waiting && data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && data == null) {
              return Center(
                child: Padding(
                  padding: GameSpacing.screen,
                  child: GameEmptyState(
                    title: 'Erro ao carregar saúde',
                    message: snapshot.error.toString(),
                    icon: Icons.error_outline_rounded,
                    actionLabel: 'Tentar de novo',
                    onAction: _refresh,
                  ),
                ),
              );
            }

            final overview = data ?? const HealthOverview(water: null, foodLimits: []);
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: GameSpacing.screen.copyWith(bottom: 96),
                children: [
                  const GameHighlightCard(
                    accentColor: GameColors.vigor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.health_and_safety_rounded, color: GameColors.vigor, size: 34),
                        SizedBox(height: GameSpacing.sm),
                        Text('Saúde prática', style: GameTextStyles.title),
                        SizedBox(height: GameSpacing.xs),
                        Text(
                          'Registre água e acompanhe limites alimentares com redução gradual. Nada de modo monge desesperado: aqui é constância com inteligência.',
                          style: GameTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GameSpacing.md),
                  _HealthSummary(overview: overview),
                  const SizedBox(height: GameSpacing.md),
                  _WaterCard(
                    item: overview.water,
                    busy: _busy,
                    onAdd250: () => _addWater(250),
                    onAdd500: () => _addWater(500),
                    onAdd1000: () => _addWater(1000),
                    onCustom: _addCustomWater,
                    onCreateHabit: _openHabitForm,
                  ),
                  const SizedBox(height: GameSpacing.md),
                  _FoodLimitsSection(
                    items: overview.foodLimits,
                    busy: _busy,
                    onLog: _addFoodLog,
                    onClaim: _claimFoodLimit,
                    onOpenHabits: _openHabitList,
                  ),
                  const SizedBox(height: GameSpacing.md),
                  GameCard(
                    backgroundColor: GameColors.surfaceSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Regra do sprint', style: GameTextStyles.cardTitle),
                        const SizedBox(height: GameSpacing.xs),
                        const Text(
                          'Água é meta diária. Refrigerante, doces, ultraprocessados, salgados e fast-food são limites semanais. Você registra o consumo real e deixa o app mostrar se ainda está no plano.',
                          style: GameTextStyles.body,
                        ),
                        const SizedBox(height: GameSpacing.sm),
                        GameSecondaryButton(
                          label: 'Abrir todos os hábitos',
                          icon: Icons.repeat_rounded,
                          onPressed: _openHabitList,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HealthSummary extends StatelessWidget {
  const _HealthSummary({required this.overview});

  final HealthOverview overview;

  @override
  Widget build(BuildContext context) {
    final water = overview.water;
    final waterText = water == null
        ? '0 ml'
        : '${formatNumber(water.stats.totalLogged)} / ${formatNumber(water.habit.targetValue)} ml';

    return Row(
      children: [
        Expanded(
          child: _HealthMiniStat(
            label: 'Água hoje',
            value: waterText,
            icon: Icons.water_drop_rounded,
            color: GameColors.info,
          ),
        ),
        const SizedBox(width: GameSpacing.sm),
        Expanded(
          child: _HealthMiniStat(
            label: 'Limites ok',
            value: '${overview.foodInsidePlan}/${overview.foodLimits.length}',
            icon: Icons.restaurant_rounded,
            color: overview.foodAlerts > 0 ? GameColors.warning : GameColors.success,
          ),
        ),
      ],
    );
  }
}

class _HealthMiniStat extends StatelessWidget {
  const _HealthMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.sm),
      backgroundColor: GameColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: GameSpacing.xs),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.item,
    required this.busy,
    required this.onAdd250,
    required this.onAdd500,
    required this.onAdd1000,
    required this.onCustom,
    required this.onCreateHabit,
  });

  final HabitWithStats? item;
  final bool busy;
  final VoidCallback onAdd250;
  final VoidCallback onAdd500;
  final VoidCallback onAdd1000;
  final VoidCallback onCustom;
  final VoidCallback onCreateHabit;

  @override
  Widget build(BuildContext context) {
    final current = item;
    if (current == null) {
      return GameCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Água', style: GameTextStyles.cardTitle),
            const SizedBox(height: GameSpacing.xs),
            const Text(
              'Nenhum hábito de água ativo foi encontrado. Crie um hábito com unidade ml ou restaure o hábito base.',
              style: GameTextStyles.body,
            ),
            const SizedBox(height: GameSpacing.sm),
            GamePrimaryButton(
              label: 'Criar hábito de água',
              icon: Icons.add_rounded,
              onPressed: onCreateHabit,
            ),
          ],
        ),
      );
    }

    final habit = current.habit;
    final stats = current.stats;
    final progress = stats.progressFor(habit);
    final completed = stats.isSuccessFor(habit);

    return GameCard(
      borderColor: completed ? GameColors.success.withValues(alpha: 0.7) : GameColors.borderSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.info.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.water_drop_rounded, color: GameColors.info),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.valueTextFor(habit)} • ${stats.statusTextFor(habit)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.caption.copyWith(color: completed ? GameColors.successSoft : GameColors.textMuted),
                    ),
                  ],
                ),
              ),
              GameChip(
                label: '+${habit.xpReward} XP',
                icon: Icons.bolt_rounded,
                color: GameColors.reward,
                selected: stats.rewarded,
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: progress, color: GameColors.info),
          const SizedBox(height: GameSpacing.sm),
          Row(
            children: [
              Expanded(child: _QuickHealthButton(label: '+250', enabled: !busy, onTap: onAdd250)),
              const SizedBox(width: GameSpacing.xs),
              Expanded(child: _QuickHealthButton(label: '+500', enabled: !busy, onTap: onAdd500)),
              const SizedBox(width: GameSpacing.xs),
              Expanded(child: _QuickHealthButton(label: '+1000', enabled: !busy, onTap: onAdd1000)),
            ],
          ),
          const SizedBox(height: GameSpacing.xs),
          GameSecondaryButton(
            label: 'Outro valor',
            icon: Icons.edit_rounded,
            onPressed: busy ? null : onCustom,
          ),
        ],
      ),
    );
  }
}

class _QuickHealthButton extends StatelessWidget {
  const _QuickHealthButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      child: Text(label),
    );
  }
}

class _FoodLimitsSection extends StatelessWidget {
  const _FoodLimitsSection({
    required this.items,
    required this.busy,
    required this.onLog,
    required this.onClaim,
    required this.onOpenHabits,
  });

  final List<HabitWithStats> items;
  final bool busy;
  final ValueChanged<Habit> onLog;
  final ValueChanged<Habit> onClaim;
  final VoidCallback onOpenHabits;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GameSectionHeader(
          title: 'Alimentação gradual',
          subtitle: 'Registre consumo e acompanhe limites semanais sem cortar tudo no susto.',
          icon: Icons.restaurant_rounded,
        ),
        if (items.isEmpty)
          GameEmptyState(
            title: 'Nenhum limite alimentar ativo',
            message: 'Os limites base aparecem aqui: refrigerante, doces/ultraprocessados e salgados/fast-food.',
            icon: Icons.restaurant_menu_rounded,
            actionLabel: 'Abrir hábitos',
            onAction: onOpenHabits,
          )
        else
          for (final item in items) ...[
            _FoodLimitCard(
              item: item,
              busy: busy,
              onLog: () => onLog(item.habit),
              onClaim: () => onClaim(item.habit),
            ),
            const SizedBox(height: GameSpacing.sm),
          ],
      ],
    );
  }
}

class _FoodLimitCard extends StatelessWidget {
  const _FoodLimitCard({
    required this.item,
    required this.busy,
    required this.onLog,
    required this.onClaim,
  });

  final HabitWithStats item;
  final bool busy;
  final VoidCallback onLog;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final habit = item.habit;
    final stats = item.stats;
    final danger = stats.totalLogged > habit.limitValue;
    final progress = stats.progressFor(habit);
    final remaining = (habit.limitValue - stats.totalLogged).clamp(0, habit.limitValue).toDouble();

    return GameCard(
      borderColor: danger ? GameColors.danger.withValues(alpha: 0.8) : GameColors.borderSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (danger ? GameColors.danger : GameColors.warning).withValues(alpha: 0.16),
                ),
                child: Icon(_iconForCategory(habit.healthCategory), color: danger ? GameColors.danger : GameColors.warning),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      '${habit.healthCategoryLabel} • ${stats.valueTextFor(habit)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: progress, color: danger ? GameColors.danger : GameColors.success),
          const SizedBox(height: GameSpacing.xs),
          Text(
            danger
                ? 'Limite semanal estourado. Sem drama, mas registra a verdade e ajusta a próxima jogada.'
                : 'Restante no plano: ${formatNumber(remaining)} ${habit.unitLabel}.',
            style: GameTextStyles.caption.copyWith(
              color: danger ? GameColors.danger : GameColors.textMuted,
              fontWeight: danger ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: GameSpacing.sm),
          Row(
            children: [
              Expanded(
                child: GamePrimaryButton(
                  label: 'Registrar',
                  icon: Icons.add_rounded,
                  onPressed: busy ? null : onLog,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: GameSecondaryButton(
                  label: stats.rewarded ? 'Recebido' : 'Validar',
                  icon: Icons.verified_rounded,
                  onPressed: busy || stats.rewarded ? null : onClaim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    return switch (category) {
      'soda' => Icons.local_drink_rounded,
      'ultra_processed' => Icons.cookie_rounded,
      'fast_food' => Icons.lunch_dining_rounded,
      _ => Icons.restaurant_rounded,
    };
  }
}

class _FoodLogDialog extends StatefulWidget {
  const _FoodLogDialog({required this.habit});

  final Habit habit;

  @override
  State<_FoodLogDialog> createState() => _FoodLogDialogState();
}

class _FoodLogDialogState extends State<_FoodLogDialog> {
  final _valueController = TextEditingController(text: '1');
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Registrar ${widget.habit.healthCategoryLabel.toLowerCase()}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quantas vezes isso entrou no consumo da semana?'),
          const SizedBox(height: GameSpacing.sm),
          TextField(
            controller: _valueController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valor em ${widget.habit.unitLabel}',
              prefixIcon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: GameSpacing.sm),
          TextField(
            controller: _noteController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observação opcional',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Registrar')),
      ],
    );
  }

  void _submit() {
    final value = double.tryParse(_valueController.text.trim().replaceAll(',', '.')) ?? 0;
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um valor maior que zero.')));
      return;
    }

    Navigator.of(context).pop(_FoodLogInput(value: value, note: _noteController.text));
  }
}

class _FoodLogInput {
  const _FoodLogInput({required this.value, required this.note});

  final double value;
  final String note;
}
