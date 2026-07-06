import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/shop_repository.dart';
import '../../design_system/game_design_system.dart';
import 'shop_item_form_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _repository = const ShopRepository();
  ShopOverview _overview = ShopOverview.empty;
  List<ShopItem> _items = const [];
  List<ShopPurchase> _purchases = const [];
  int _heroCoins = 0;
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
      final items = await _repository.getItems();
      final purchases = await _repository.getRecentPurchases();
      final coins = await _repository.getHeroCoins();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _items = items;
        _purchases = purchases;
        _heroCoins = coins;
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

  Future<void> _openForm([ShopItem? item]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ShopItemFormScreen(item: item)),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _archive(ShopItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar item?'),
        content: Text('“${item.title}” sairá da loja ativa. Compras antigas continuam no histórico.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Arquivar')),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _repository.archiveItem(item.id);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao arquivar item: $error')));
    }
  }

  Future<void> _buy(ShopItem item) async {
    final blockReason = item.buyBlockReason(_heroCoins);
    if (blockReason.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(blockReason)));
      return;
    }

    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.isRealPurchase ? 'Liberar compra real?' : 'Comprar recompensa?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item: ${item.title}'),
              const SizedBox(height: GameSpacing.xs),
              Text('Custo: ${item.coinCostText}'),
              if (item.isRealPurchase) ...[
                const SizedBox(height: GameSpacing.xs),
                Text('Cofre: ${item.moneyRequirementText}'),
              ],
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
              if (item.isRealPurchase) ...[
                const SizedBox(height: GameSpacing.sm),
                const Text(
                  'O app não movimenta dinheiro real. Ele só confere se o cofre vinculado tem saldo suficiente.',
                  style: GameTextStyles.caption,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Comprar')),
          ],
        );
      },
    );

    final note = noteController.text;
    noteController.dispose();
    if (confirmed != true) return;

    try {
      final result = await _repository.purchaseItem(item.id, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao comprar: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Item'),
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
            title: 'Erro ao carregar loja',
            message: _error.toString(),
            icon: Icons.error_outline_rounded,
            actionLabel: 'Tentar de novo',
            onAction: _load,
          ),
        ),
      );
    }

    final rewardItems = _items.where((item) => item.isReward).toList();
    final realItems = _items.where((item) => item.isRealPurchase).toList();

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
                const Icon(Icons.storefront_rounded, color: GameColors.reward, size: 34),
                const SizedBox(height: GameSpacing.sm),
                const Text('Loja do Reino', style: GameTextStyles.title),
                const SizedBox(height: GameSpacing.xs),
                const Text(
                  'Troque coins por recompensas planejadas e libere compras reais apenas quando o cofre estiver preparado.',
                  style: GameTextStyles.body,
                ),
                const SizedBox(height: GameSpacing.md),
                Wrap(
                  spacing: GameSpacing.xs,
                  runSpacing: GameSpacing.xs,
                  children: [
                    GameChip(label: '$_heroCoins coins', icon: Icons.monetization_on_rounded, color: GameColors.coin, selected: true),
                    GameChip(label: '${_overview.purchases} compras', icon: Icons.shopping_bag_rounded, color: GameColors.info),
                    GameChip(label: '${_overview.coinsSpent} coins gastos', icon: Icons.receipt_long_rounded, color: GameColors.reward),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: GameSpacing.md),
          const GameSectionHeader(
            title: 'Recompensas simples',
            subtitle: 'Lazer planejado comprado com coins. Nada de recompensa no impulso, meu nobre.',
            icon: Icons.redeem_rounded,
          ),
          if (rewardItems.isEmpty)
            GameEmptyState(
              title: 'Sem recompensas cadastradas',
              message: 'Crie vouchers de jogo, filme, descanso ou outras recompensas controladas.',
              icon: Icons.redeem_rounded,
              actionLabel: 'Criar item',
              onAction: () => _openForm(),
            )
          else
            for (final item in rewardItems) ...[
              _ShopItemCard(
                item: item,
                heroCoins: _heroCoins,
                onBuy: () => _buy(item),
                onEdit: () => _openForm(item),
                onArchive: () => _archive(item),
              ),
              const SizedBox(height: GameSpacing.sm),
            ],
          const SizedBox(height: GameSpacing.md),
          const GameSectionHeader(
            title: 'Compras reais planejadas',
            subtitle: 'Exigem coins e saldo real suficiente no cofre vinculado.',
            icon: Icons.shopping_bag_rounded,
          ),
          if (realItems.isEmpty)
            const GameCard(
              backgroundColor: GameColors.surfaceSoft,
              child: Text('Nenhuma compra real planejada ainda.', style: GameTextStyles.body),
            )
          else
            for (final item in realItems) ...[
              _ShopItemCard(
                item: item,
                heroCoins: _heroCoins,
                onBuy: () => _buy(item),
                onEdit: () => _openForm(item),
                onArchive: () => _archive(item),
              ),
              const SizedBox(height: GameSpacing.sm),
            ],
          const SizedBox(height: GameSpacing.md),
          const GameSectionHeader(
            title: 'Compras recentes',
            subtitle: 'Últimas recompensas e compras liberadas.',
            icon: Icons.history_rounded,
          ),
          if (_purchases.isEmpty)
            const GameCard(
              backgroundColor: GameColors.surfaceSoft,
              child: Text('Nenhuma compra registrada ainda.', style: GameTextStyles.body),
            )
          else
            for (final purchase in _purchases) ...[
              _PurchaseTile(purchase: purchase),
              const SizedBox(height: GameSpacing.xs),
            ],
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.heroCoins,
    required this.onBuy,
    required this.onEdit,
    required this.onArchive,
  });

  final ShopItem item;
  final int heroCoins;
  final VoidCallback onBuy;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final canBuy = item.canBuy(heroCoins);
    final blockReason = item.buyBlockReason(heroCoins);
    final accent = item.isRealPurchase ? GameColors.reward : GameColors.primary;

    return GameCard(
      borderColor: canBuy ? accent.withValues(alpha: 0.55) : GameColors.borderSoft,
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
                  color: accent.withValues(alpha: 0.16),
                ),
                child: Icon(item.isRealPurchase ? Icons.shopping_bag_rounded : Icons.redeem_rounded, color: accent),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      item.description.isEmpty ? item.typeLabel : item.description,
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
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(label: item.typeLabel, icon: item.isRealPurchase ? Icons.shopping_bag_rounded : Icons.redeem_rounded, color: accent),
              GameChip(label: item.coinCostText, icon: Icons.monetization_on_rounded, color: GameColors.coin),
            ],
          ),
          if (item.isRealPurchase) ...[
            const SizedBox(height: GameSpacing.sm),
            Text(item.moneyRequirementText, style: GameTextStyles.caption),
            const SizedBox(height: GameSpacing.xs),
            GameProgressBar(
              value: item.requiredMoneyAmount <= 0 ? 0 : (item.linkedVaultBalance / item.requiredMoneyAmount).clamp(0, 1).toDouble(),
              color: item.moneyRequirementMet ? GameColors.success : GameColors.reward,
            ),
          ],
          const SizedBox(height: GameSpacing.sm),
          if (!canBuy && blockReason.isNotEmpty) ...[
            Text(blockReason, style: GameTextStyles.caption.copyWith(color: GameColors.warning, fontWeight: FontWeight.w800)),
            const SizedBox(height: GameSpacing.xs),
          ],
          GamePrimaryButton(
            label: item.isRealPurchase ? 'Liberar compra' : 'Comprar',
            icon: item.isRealPurchase ? Icons.shopping_cart_checkout_rounded : Icons.redeem_rounded,
            onPressed: canBuy ? onBuy : null,
          ),
        ],
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.purchase});

  final ShopPurchase purchase;

  @override
  Widget build(BuildContext context) {
    final color = purchase.isRealPurchase ? GameColors.reward : GameColors.primary;
    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.sm),
      backgroundColor: GameColors.surfaceSoft,
      child: Row(
        children: [
          Icon(purchase.isRealPurchase ? Icons.shopping_bag_rounded : Icons.redeem_rounded, color: color, size: 20),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(purchase.titleSnapshot, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text('${purchase.typeLabel} • ${purchase.dateText}', style: GameTextStyles.caption),
              ],
            ),
          ),
          Text(purchase.coinsText, style: GameTextStyles.cardTitle.copyWith(color: GameColors.coin)),
        ],
      ),
    );
  }
}
