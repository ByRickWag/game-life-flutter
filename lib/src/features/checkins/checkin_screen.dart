import 'package:flutter/material.dart';

import '../../core/models/v3_commitment_models.dart';
import '../../core/repositories/checkin_repository.dart';
import '../../design_system/game_design_system.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final CheckInRepository _repository = CheckInRepository();

  CheckInSummary? _summary;
  List<DailyCheckIn> _recent = const [];
  int _previewCoins = 0;
  Object? _error;
  bool _loading = true;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await _repository.getSummary();
      final recent = await _repository.getRecentCheckIns(limit: 14);
      final previewCoins = await _repository.previewTodayCoins();

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _recent = recent;
        _previewCoins = previewCoins;
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

  Future<void> _checkInToday() async {
    if (_checkingIn) return;
    setState(() => _checkingIn = true);

    try {
      final result = await _repository.checkInToday();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.coinsGained > 0
                ? '${result.message} +${result.coinsGained} coins.'
                : result.message,
          ),
        ),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer check-in: $error')),
      );
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GameSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GameHighlightCard(
                accentColor: GameColors.reward,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: GameColors.reward, size: 36),
                    SizedBox(height: GameSpacing.sm),
                    Text('Ritmo diário', style: GameTextStyles.title),
                    SizedBox(height: GameSpacing.xs),
                    Text(
                      'Faça check-in todos os dias para manter sua sequência ativa e registrar presença na jornada.',
                      style: GameTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              if (_loading && _summary == null)
                const Center(child: CircularProgressIndicator())
              else if (_error != null && _summary == null)
                _CheckInError(error: _error.toString(), onRetry: _load)
              else ...[
                _CheckInActionCard(
                  summary: _summary ?? CheckInSummary.empty(),
                  previewCoins: _previewCoins,
                  checkingIn: _checkingIn,
                  onCheckIn: _checkInToday,
                ),
                const SizedBox(height: GameSpacing.md),
                _CheckInStats(summary: _summary ?? CheckInSummary.empty()),
                const SizedBox(height: GameSpacing.md),
                _RecentCheckIns(recent: _recent),
                const SizedBox(height: GameSpacing.md),
                const GameCard(
                  backgroundColor: GameColors.surfaceSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Como funciona', style: GameTextStyles.cardTitle),
                      SizedBox(height: GameSpacing.xs),
                      Text(
                        'O check-in é um compromisso simples de presença diária. Ele não substitui missões, objetivos ou sessões; ele marca que você voltou para a jornada hoje.',
                        style: GameTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: GameSpacing.lg),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Ritmo diário')),
      body: content,
    );
  }
}

class _CheckInActionCard extends StatelessWidget {
  const _CheckInActionCard({
    required this.summary,
    required this.previewCoins,
    required this.checkingIn,
    required this.onCheckIn,
  });

  final CheckInSummary summary;
  final int previewCoins;
  final bool checkingIn;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final canCheckIn = summary.canCheckInToday && !checkingIn;

    return GameCard(
      showShadow: true,
      borderColor: summary.canCheckInToday ? GameColors.reward.withValues(alpha: 0.42) : GameColors.success.withValues(alpha: 0.38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (summary.canCheckInToday ? GameColors.reward : GameColors.success).withValues(alpha: 0.16),
                ),
                child: Icon(
                  summary.canCheckInToday ? Icons.touch_app_rounded : Icons.check_circle_rounded,
                  color: summary.canCheckInToday ? GameColors.reward : GameColors.success,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.canCheckInToday ? 'Check-in disponível' : 'Check-in de hoje feito',
                      style: GameTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.canCheckInToday
                          ? 'Registre sua presença diária e mantenha a chama acesa.'
                          : 'Volte amanhã para continuar sua sequência.',
                      style: GameTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniCheckInStat(
                  label: 'Sequência',
                  value: '${summary.currentStreak}',
                  icon: Icons.local_fire_department_rounded,
                  color: GameColors.reward,
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              Expanded(
                child: _MiniCheckInStat(
                  label: 'Recompensa',
                  value: summary.canCheckInToday ? '+$previewCoins c' : 'Recebida',
                  icon: Icons.monetization_on_rounded,
                  color: GameColors.coin,
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          GamePrimaryButton(
            label: checkingIn
                ? 'Registrando...'
                : summary.canCheckInToday
                    ? 'Fazer check-in'
                    : 'Check-in feito hoje',
            icon: summary.canCheckInToday ? Icons.done_rounded : Icons.verified_rounded,
            onPressed: canCheckIn ? onCheckIn : null,
          ),
        ],
      ),
    );
  }
}

class _CheckInStats extends StatelessWidget {
  const _CheckInStats({required this.summary});

  final CheckInSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GameSectionHeader(
          title: 'Sequência',
          subtitle: 'Medidores de presença diária na jornada.',
          icon: Icons.insights_rounded,
        ),
        Row(
          children: [
            Expanded(
              child: GameStatTile(
                label: 'Atual',
                value: '${summary.currentStreak}d',
                icon: Icons.local_fire_department_rounded,
                color: GameColors.reward,
              ),
            ),
            const SizedBox(width: GameSpacing.xs),
            Expanded(
              child: GameStatTile(
                label: 'Melhor',
                value: '${summary.bestStreak}d',
                icon: Icons.military_tech_rounded,
                color: GameColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.xs),
        Row(
          children: [
            Expanded(
              child: GameStatTile(
                label: 'Total',
                value: '${summary.totalCheckIns}',
                icon: Icons.event_available_rounded,
                color: GameColors.info,
              ),
            ),
            const SizedBox(width: GameSpacing.xs),
            Expanded(
              child: GameStatTile(
                label: 'Último',
                value: summary.lastCheckInDate.isEmpty ? '—' : _shortDate(summary.lastCheckInDate),
                icon: Icons.today_rounded,
                color: GameColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentCheckIns extends StatelessWidget {
  const _RecentCheckIns({required this.recent});

  final List<DailyCheckIn> recent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GameSectionHeader(
          title: 'Histórico de check-ins',
          subtitle: 'Últimos registros de presença diária.',
          icon: Icons.history_rounded,
        ),
        if (recent.isEmpty)
          const GameEmptyState(
            title: 'Nenhum check-in ainda',
            message: 'Faça o primeiro check-in para iniciar sua sequência.',
            icon: Icons.local_fire_department_rounded,
          )
        else
          Column(
            children: [
              for (final item in recent.take(10)) ...[
                GameCard(
                  padding: const EdgeInsets.all(GameSpacing.sm),
                  backgroundColor: GameColors.surfaceSoft,
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GameColors.reward.withValues(alpha: 0.14),
                        ),
                        child: const Icon(Icons.local_fire_department_rounded, color: GameColors.reward, size: 20),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_fullDate(item.checkInDate), style: GameTextStyles.cardTitle),
                            const SizedBox(height: 2),
                            Text('Sequência no dia: ${item.streakCount}', style: GameTextStyles.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: GameSpacing.xs),
                      Text('+${item.coinsGained} c', style: GameTextStyles.caption.copyWith(color: GameColors.coin)),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.xs),
              ],
            ],
          ),
      ],
    );
  }
}

class _MiniCheckInStat extends StatelessWidget {
  const _MiniCheckInStat({
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
    return Container(
      padding: const EdgeInsets.all(GameSpacing.sm),
      decoration: BoxDecoration(
        color: GameColors.surfaceSoft,
        borderRadius: BorderRadius.circular(GameRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: GameSpacing.xs),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.statValue),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
        ],
      ),
    );
  }
}

class _CheckInError extends StatelessWidget {
  const _CheckInError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: GameColors.danger),
          const SizedBox(height: GameSpacing.sm),
          Text('Erro ao carregar check-in', style: GameTextStyles.sectionTitle),
          const SizedBox(height: GameSpacing.xs),
          Text(error, style: GameTextStyles.body),
          const SizedBox(height: GameSpacing.md),
          GamePrimaryButton(
            label: 'Tentar novamente',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

String _shortDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return value;
  return '${parts[2]}/${parts[1]}';
}

String _fullDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return value;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}
