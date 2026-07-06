import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/habit_repository.dart';
import '../../design_system/game_design_system.dart';
import 'habit_form_screen.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final _repository = HabitRepository();
  List<HabitWithStats> _items = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repository.getActiveHabitsWithStats();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openForm([Habit? habit]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => HabitFormScreen(habit: habit)),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _log(Habit habit) async {
    final valueController = TextEditingController(text: habit.unit == 'check' ? '1' : '');
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(habit.isReduction ? 'Registrar consumo' : 'Registrar progresso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                habit.isReduction
                    ? 'Quanto desse hábito você consumiu/fez agora?'
                    : 'Quanto você avançou nesse hábito?',
              ),
              const SizedBox(height: GameSpacing.sm),
              TextField(
                controller: valueController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor em ${habit.unitLabel}',
                  prefixIcon: const Icon(Icons.add_rounded),
                ),
              ),
              const SizedBox(height: GameSpacing.sm),
              TextField(
                controller: noteController,
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
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Registrar')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final value = double.tryParse(valueController.text.trim().replaceAll(',', '.')) ?? 0;
    if (value <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um valor maior que zero.')));
      return;
    }

    try {
      final result = await _repository.addLog(
        habit: habit,
        value: value,
        note: noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao registrar hábito: $error')));
    }
  }

  Future<void> _claim(Habit habit) async {
    try {
      final result = await _repository.claimReductionPeriodSuccess(habit);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao validar período: $error')));
    }
  }

  Future<void> _deactivate(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar hábito?'),
        content: Text('“${habit.title}” sairá da lista ativa, mas o histórico continuará salvo.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Arquivar')),
        ],
      ),
    );

    if (confirmed != true) return;
    await _repository.deactivateHabit(habit.id);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Hábito'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: GameSpacing.screen,
          child: GameEmptyState(
            title: 'Erro ao carregar hábitos',
            message: _error.toString(),
            icon: Icons.error_outline_rounded,
            actionLabel: 'Tentar de novo',
            onAction: _load,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: GameSpacing.screen.copyWith(bottom: 96),
        children: [
          const GameHighlightCard(
            accentColor: GameColors.success,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.repeat_rounded, color: GameColors.success, size: 34),
                SizedBox(height: GameSpacing.sm),
                Text('Hábitos', style: GameTextStyles.title),
                SizedBox(height: GameSpacing.xs),
                Text(
                  'Construa hábitos bons e reduza hábitos ruins de forma gradual, sem rebote e sem fantasia fitness de 48 horas.',
                  style: GameTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: GameSpacing.md),
          _SummaryRow(items: _items),
          const SizedBox(height: GameSpacing.md),
          const GameSectionHeader(
            title: 'Ritmo atual',
            subtitle: 'Registre progresso, consumo ou valide períodos dentro do limite.',
            icon: Icons.insights_rounded,
          ),
          if (_items.isEmpty)
            GameEmptyState(
              title: 'Nenhum hábito ativo',
              message: 'Crie hábitos como beber água, caminhar, ler Bíblia ou reduzir refrigerante.',
              icon: Icons.repeat_rounded,
              actionLabel: 'Criar hábito',
              onAction: () => _openForm(),
            )
          else
            for (final item in _items) ...[
              _HabitCard(
                item: item,
                onLog: () => _log(item.habit),
                onClaim: item.habit.isReduction ? () => _claim(item.habit) : null,
                onEdit: () => _openForm(item.habit),
                onDeactivate: () => _deactivate(item.habit),
              ),
              const SizedBox(height: GameSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.items});

  final List<HabitWithStats> items;

  @override
  Widget build(BuildContext context) {
    final active = items.length;
    final rewarded = items.where((item) => item.stats.rewarded).length;
    final inDanger = items.where((item) => item.habit.isReduction && item.stats.totalLogged > item.habit.limitValue).length;

    return Row(
      children: [
        Expanded(child: _MiniStat(label: 'Ativos', value: '$active', icon: Icons.repeat_rounded, color: GameColors.success)),
        const SizedBox(width: GameSpacing.sm),
        Expanded(child: _MiniStat(label: 'Recomp.', value: '$rewarded', icon: Icons.bolt_rounded, color: GameColors.reward)),
        const SizedBox(width: GameSpacing.sm),
        Expanded(child: _MiniStat(label: 'Alertas', value: '$inDanger', icon: Icons.warning_rounded, color: inDanger > 0 ? GameColors.danger : GameColors.info)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: GameSpacing.xs),
          Text(value, style: GameTextStyles.cardTitle),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.item,
    required this.onLog,
    required this.onEdit,
    required this.onDeactivate,
    this.onClaim,
  });

  final HabitWithStats item;
  final VoidCallback onLog;
  final VoidCallback? onClaim;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final habit = item.habit;
    final stats = item.stats;
    final color = GameColors.attributeById(habit.attributeId);
    final progress = stats.progressFor(habit);
    final danger = habit.isReduction && stats.totalLogged > habit.limitValue;

    return GameCard(
      borderColor: danger ? GameColors.danger.withValues(alpha: 0.8) : GameColors.borderSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                ),
                child: Icon(habit.isReduction ? Icons.trending_down_rounded : Icons.repeat_rounded, color: color),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      '${habit.typeLabel} • ${habit.frequencyLabel} • ${habit.goalText}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.caption,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'archive') onDeactivate();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'archive', child: Text('Arquivar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: progress, color: danger ? GameColors.danger : color),
          const SizedBox(height: GameSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${stats.valueTextFor(habit)} • ${stats.statusTextFor(habit)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.caption.copyWith(
                    color: danger ? GameColors.danger : GameColors.textMuted,
                    fontWeight: danger ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              _RewardPill(xp: habit.xpReward, coins: habit.coinsReward),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Row(
            children: [
              Expanded(
                child: GamePrimaryButton(
                  label: habit.isReduction ? 'Registrar' : 'Avançar',
                  icon: habit.isReduction ? Icons.add_rounded : Icons.check_rounded,
                  onPressed: onLog,
                ),
              ),
              if (habit.isReduction) ...[
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: GameSecondaryButton(
                    label: stats.rewarded ? 'Recebido' : 'Validar',
                    icon: Icons.verified_rounded,
                    onPressed: stats.rewarded ? null : onClaim,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.xp, required this.coins});

  final int xp;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final label = coins > 0 ? '+$xp XP • +$coins' : '+$xp XP';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: GameColors.reward.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(GameRadius.pill),
        border: Border.all(color: GameColors.reward.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: GameTextStyles.caption.copyWith(color: GameColors.rewardSoft, fontWeight: FontWeight.w900)),
    );
  }
}
