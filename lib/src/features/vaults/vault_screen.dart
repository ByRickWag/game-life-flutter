import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/vault_repository.dart';
import '../../design_system/game_design_system.dart';
import 'vault_form_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _repository = const VaultRepository();
  VaultOverview _overview = VaultOverview.empty;
  List<VaultWithSummary> _vaults = const [];
  List<VaultEntry> _recentEntries = const [];
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
      final overview = await _repository.getOverview();
      final vaults = await _repository.getVaultsWithSummary();
      final entries = await _repository.getRecentEntries(limit: 8);
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _vaults = vaults;
        _recentEntries = entries;
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

  Future<void> _openForm([Vault? vault]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VaultFormScreen(vault: vault)),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _addEntry(VaultWithSummary item, String type) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final isDeposit = type == 'deposit';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isDeposit ? 'Registrar depósito' : 'Registrar retirada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDeposit
                    ? 'Quanto você guardou em “${item.vault.name}”?'
                    : 'Quanto você retirou de “${item.vault.name}”?',
              ),
              const SizedBox(height: GameSpacing.sm),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor em reais',
                  hintText: 'Ex.: 50,00',
                  prefixIcon: Icon(Icons.attach_money_rounded),
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

    final amountText = amountController.text;
    final noteText = noteController.text;
    amountController.dispose();
    noteController.dispose();
    if (confirmed != true) return;

    final amount = _parseMoney(amountText);
    if (amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um valor maior que zero.')));
      return;
    }

    try {
      final result = await _repository.addEntry(
        vaultId: item.vault.id,
        type: type,
        amount: amount,
        note: noteText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao movimentar cofre: $error')));
    }
  }

  Future<void> _archive(Vault vault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar cofre?'),
        content: Text('“${vault.name}” sairá da lista ativa. O histórico financeiro continuará salvo.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Arquivar')),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _repository.archiveVault(vault.id);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao arquivar cofre: $error')));
    }
  }

  double _parseMoney(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return 0;
    final clean = raw.contains(',')
        ? raw.replaceAll('.', '').replaceAll(',', '.')
        : raw;
    return double.tryParse(clean) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Cofre'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _vaults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _vaults.isEmpty) {
      return Center(
        child: Padding(
          padding: GameSpacing.screen,
          child: GameEmptyState(
            title: 'Erro ao carregar cofres',
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
          GameHighlightCard(
            accentColor: GameColors.reward,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.savings_rounded, color: GameColors.reward, size: 34),
                const SizedBox(height: GameSpacing.sm),
                const Text('Cofre do Reino', style: GameTextStyles.title),
                const SizedBox(height: GameSpacing.xs),
                const Text(
                  'Registre dinheiro real guardado fora do app e transforme metas financeiras em progresso visível.',
                  style: GameTextStyles.body,
                ),
                const SizedBox(height: GameSpacing.md),
                GameProgressBar(value: _overview.progress, color: GameColors.reward),
                const SizedBox(height: GameSpacing.xs),
                Text(
                  _overview.totalGoals > 0
                      ? '${formatCurrency(_overview.totalBalance)} guardados de ${formatCurrency(_overview.totalGoals)}'
                      : '${formatCurrency(_overview.totalBalance)} guardados no total',
                  style: GameTextStyles.caption.copyWith(color: GameColors.rewardSoft, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: GameSpacing.md),
          _OverviewRow(overview: _overview),
          const SizedBox(height: GameSpacing.md),
          const GameSectionHeader(
            title: 'Cofres ativos',
            subtitle: 'Deposite, retire, acompanhe metas e prepare futuras compras da loja.',
            icon: Icons.account_balance_wallet_rounded,
          ),
          if (_vaults.isEmpty)
            GameEmptyState(
              title: 'Nenhum cofre criado',
              message: 'Crie um cofre para reserva, viagem, curso, GamePad ou qualquer meta real.',
              icon: Icons.savings_rounded,
              actionLabel: 'Criar cofre',
              onAction: () => _openForm(),
            )
          else
            for (final item in _vaults) ...[
              _VaultCard(
                item: item,
                onDeposit: () => _addEntry(item, 'deposit'),
                onWithdraw: () => _addEntry(item, 'withdraw'),
                onEdit: () => _openForm(item.vault),
                onArchive: () => _archive(item.vault),
              ),
              const SizedBox(height: GameSpacing.sm),
            ],
          const SizedBox(height: GameSpacing.md),
          const GameSectionHeader(
            title: 'Movimentações recentes',
            subtitle: 'Últimos depósitos e retiradas registrados.',
            icon: Icons.receipt_long_rounded,
          ),
          if (_recentEntries.isEmpty)
            const GameCard(
              backgroundColor: GameColors.surfaceSoft,
              child: Text('Nenhuma movimentação registrada ainda.', style: GameTextStyles.body),
            )
          else
            for (final entry in _recentEntries) ...[
              _EntryTile(entry: entry),
              const SizedBox(height: GameSpacing.xs),
            ],
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.overview});

  final VaultOverview overview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniStat(label: 'Cofres', value: '${overview.activeVaults}', icon: Icons.savings_rounded, color: GameColors.reward)),
        const SizedBox(width: GameSpacing.sm),
        Expanded(child: _MiniStat(label: 'Saldo', value: formatCurrency(overview.totalBalance), icon: Icons.account_balance_wallet_rounded, color: GameColors.success)),
        const SizedBox(width: GameSpacing.sm),
        Expanded(child: _MiniStat(label: 'Metas', value: formatCurrency(overview.totalGoals), icon: Icons.flag_rounded, color: GameColors.info)),
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
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
        ],
      ),
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard({
    required this.item,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onEdit,
    required this.onArchive,
  });

  final VaultWithSummary item;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final vault = item.vault;
    final summary = item.summary;
    final reachedGoal = vault.hasGoal && summary.balance >= vault.goalAmount;

    return GameCard(
      borderColor: reachedGoal ? GameColors.success.withValues(alpha: 0.7) : GameColors.borderSoft,
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
                  color: GameColors.reward.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.savings_rounded, color: GameColors.reward),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vault.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      vault.description.isEmpty ? vault.goalText : vault.description,
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
                  if (value == 'archive') onArchive();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'archive', child: Text('Arquivar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: item.progress, color: reachedGoal ? GameColors.success : GameColors.reward),
          const SizedBox(height: GameSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.progressLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.caption.copyWith(
                    color: reachedGoal ? GameColors.success : GameColors.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (vault.hasGoal) ...[
                const SizedBox(width: GameSpacing.xs),
                Text('Faltam ${formatCurrency(item.remainingAmount)}', style: GameTextStyles.caption),
              ],
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Row(
            children: [
              Expanded(
                child: GamePrimaryButton(
                  label: 'Depositar',
                  icon: Icons.add_rounded,
                  onPressed: onDeposit,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: GameSecondaryButton(
                  label: 'Retirar',
                  icon: Icons.remove_rounded,
                  onPressed: summary.balance <= 0 ? null : onWithdraw,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.isDeposit ? GameColors.success : GameColors.danger;
    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.sm),
      backgroundColor: GameColors.surfaceSoft,
      child: Row(
        children: [
          Icon(entry.isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 20),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.typeLabel, style: GameTextStyles.cardTitle),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(entry.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
                ],
              ],
            ),
          ),
          Text(
            entry.signedAmountText,
            style: GameTextStyles.cardTitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
