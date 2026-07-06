import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../services/progression_service.dart';
import '../utils/id_generator.dart';
import 'achievement_repository.dart';

class CreateShopItemInput {
  const CreateShopItemInput({
    required this.title,
    required this.description,
    required this.type,
    required this.coinCost,
    required this.requiredMoneyAmount,
    required this.linkedVaultId,
  });

  final String title;
  final String description;
  final String type;
  final int coinCost;
  final double requiredMoneyAmount;
  final String? linkedVaultId;
}

class ShopPurchaseResult {
  const ShopPurchaseResult({
    required this.message,
    required this.remainingCoins,
  });

  final String message;
  final int remainingCoins;
}

class ShopOverview {
  const ShopOverview({
    required this.activeItems,
    required this.purchases,
    required this.coinsSpent,
    required this.rewardPurchases,
    required this.realPurchases,
  });

  final int activeItems;
  final int purchases;
  final int coinsSpent;
  final int rewardPurchases;
  final int realPurchases;

  static const empty = ShopOverview(
    activeItems: 0,
    purchases: 0,
    coinsSpent: 0,
    rewardPurchases: 0,
    realPurchases: 0,
  );

  factory ShopOverview.fromMap(Map<String, Object?> map) {
    return ShopOverview(
      activeItems: readInt(map, 'active_items'),
      purchases: readInt(map, 'purchases'),
      coinsSpent: readInt(map, 'coins_spent'),
      rewardPurchases: readInt(map, 'reward_purchases'),
      realPurchases: readInt(map, 'real_purchases'),
    );
  }
}

class ShopRepository {
  const ShopRepository();

  Future<int> getHeroCoins() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'hero_profiles',
      columns: ['coins'],
      where: 'id = ?',
      whereArgs: ['main_hero'],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return readInt(rows.first, 'coins');
  }

  Future<ShopOverview> getOverview() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM shop_items WHERE status = 'active') AS active_items,
        (SELECT COUNT(*) FROM shop_purchases) AS purchases,
        (SELECT COALESCE(SUM(coin_cost_paid), 0) FROM shop_purchases) AS coins_spent,
        (SELECT COUNT(*) FROM shop_purchases WHERE type_snapshot = 'reward') AS reward_purchases,
        (SELECT COUNT(*) FROM shop_purchases WHERE type_snapshot = 'real_purchase') AS real_purchases;
    ''');
    if (rows.isEmpty) return ShopOverview.empty;
    return ShopOverview.fromMap(rows.first);
  }

  Future<List<ShopItem>> getItems({bool includeArchived = false}) async {
    final db = await AppDatabase.instance.database;
    final where = includeArchived ? '' : "WHERE shop_items.status = 'active'";
    final rows = await db.rawQuery('''
      SELECT
        shop_items.*,
        COALESCE(vaults.name, '') AS linked_vault_name,
        COALESCE((
          SELECT SUM(CASE
            WHEN vault_entries.type = 'deposit' THEN vault_entries.amount
            WHEN vault_entries.type = 'withdraw' THEN -vault_entries.amount
            ELSE 0
          END)
          FROM vault_entries
          WHERE vault_entries.vault_id = shop_items.linked_vault_id
        ), 0) AS linked_vault_balance
      FROM shop_items
      LEFT JOIN vaults ON vaults.id = shop_items.linked_vault_id
      $where
      ORDER BY shop_items.status ASC, shop_items.type ASC, shop_items.coin_cost ASC, shop_items.created_at DESC;
    ''');
    return rows.map(ShopItem.fromMap).toList();
  }

  Future<ShopItem?> getItemById(String itemId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        shop_items.*,
        COALESCE(vaults.name, '') AS linked_vault_name,
        COALESCE((
          SELECT SUM(CASE
            WHEN vault_entries.type = 'deposit' THEN vault_entries.amount
            WHEN vault_entries.type = 'withdraw' THEN -vault_entries.amount
            ELSE 0
          END)
          FROM vault_entries
          WHERE vault_entries.vault_id = shop_items.linked_vault_id
        ), 0) AS linked_vault_balance
      FROM shop_items
      LEFT JOIN vaults ON vaults.id = shop_items.linked_vault_id
      WHERE shop_items.id = ?
      LIMIT 1;
    ''', [itemId]);
    if (rows.isEmpty) return null;
    return ShopItem.fromMap(rows.first);
  }

  Future<List<VaultWithSummary>> getActiveVaultOptions() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        vaults.*,
        COALESCE(SUM(CASE WHEN vault_entries.type = 'deposit' THEN vault_entries.amount WHEN vault_entries.type = 'withdraw' THEN -vault_entries.amount ELSE 0 END), 0) AS balance,
        COALESCE(SUM(CASE WHEN vault_entries.type = 'deposit' THEN vault_entries.amount ELSE 0 END), 0) AS deposits_total,
        COALESCE(SUM(CASE WHEN vault_entries.type = 'withdraw' THEN vault_entries.amount ELSE 0 END), 0) AS withdrawals_total,
        COUNT(vault_entries.id) AS entries_count,
        COALESCE(MAX(vault_entries.created_at), '') AS last_entry_at
      FROM vaults
      LEFT JOIN vault_entries ON vault_entries.vault_id = vaults.id
      WHERE vaults.status = 'active'
      GROUP BY vaults.id
      ORDER BY vaults.created_at DESC;
    ''');

    return rows.map((row) {
      return VaultWithSummary(
        vault: Vault.fromMap(row),
        summary: VaultSummary.fromMap(row),
      );
    }).toList();
  }

  Future<List<ShopPurchase>> getRecentPurchases({int limit = 12}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'shop_purchases',
      orderBy: 'purchased_at DESC',
      limit: limit,
    );
    return rows.map(ShopPurchase.fromMap).toList();
  }

  Future<String> createItem(CreateShopItemInput input) async {
    _validateInput(input);

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final itemId = IdGenerator.create('shop_item');

    await db.transaction((txn) async {
      await txn.insert(
        'shop_items',
        {
          'id': itemId,
          'title': input.title.trim(),
          'description': input.description.trim(),
          'type': input.type,
          'coin_cost': input.coinCost,
          'required_money_amount': input.type == 'real_purchase' ? input.requiredMoneyAmount : 0,
          'linked_vault_id': input.type == 'real_purchase' ? input.linkedVaultId : null,
          'icon': input.type == 'real_purchase' ? 'shopping_bag' : 'redeem',
          'color': input.type == 'real_purchase' ? 'amber' : 'purple',
          'status': 'active',
          'created_at': now,
          'updated_at': now,
          'archived_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _insertHistory(
        txn,
        title: 'Item criado na loja: ${input.title.trim()}',
        description: input.type == 'real_purchase'
            ? 'Novo item real planejado criado na Loja do Reino.'
            : 'Nova recompensa criada na Loja do Reino.',
        type: 'shop_item_created',
        coinsDelta: 0,
        nowIso: now,
      );
    });

    return itemId;
  }

  Future<void> updateItem({
    required String itemId,
    required CreateShopItemInput input,
  }) async {
    _validateInput(input);

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'shop_items',
        {
          'title': input.title.trim(),
          'description': input.description.trim(),
          'type': input.type,
          'coin_cost': input.coinCost,
          'required_money_amount': input.type == 'real_purchase' ? input.requiredMoneyAmount : 0,
          'linked_vault_id': input.type == 'real_purchase' ? input.linkedVaultId : null,
          'icon': input.type == 'real_purchase' ? 'shopping_bag' : 'redeem',
          'color': input.type == 'real_purchase' ? 'amber' : 'purple',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );

      await _insertHistory(
        txn,
        title: 'Item editado na loja: ${input.title.trim()}',
        description: 'Configuração do item da Loja do Reino atualizada.',
        type: 'shop_item_updated',
        coinsDelta: 0,
        nowIso: now,
      );
    });
  }

  Future<void> archiveItem(String itemId) async {
    final db = await AppDatabase.instance.database;
    final item = await getItemById(itemId);
    if (item == null) return;

    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        'shop_items',
        {
          'status': 'archived',
          'updated_at': now,
          'archived_at': now,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );

      await _insertHistory(
        txn,
        title: 'Item arquivado na loja: ${item.title}',
        description: 'O item saiu da loja ativa, mas o histórico de compras continua salvo.',
        type: 'shop_item_archived',
        coinsDelta: 0,
        nowIso: now,
      );
    });
  }

  Future<ShopPurchaseResult> purchaseItem(String itemId, {String note = ''}) async {
    final db = await AppDatabase.instance.database;
    final item = await getItemById(itemId);
    if (item == null || !item.isActive) {
      throw StateError('Item da loja não encontrado ou arquivado.');
    }

    final heroRows = await db.query(
      'hero_profiles',
      where: 'id = ?',
      whereArgs: ['main_hero'],
      limit: 1,
    );
    if (heroRows.isEmpty) {
      throw StateError('Herói principal não encontrado.');
    }

    final currentCoins = readInt(heroRows.first, 'coins');
    if (currentCoins < item.coinCost) {
      throw StateError('Coins insuficientes para comprar este item.');
    }

    if (item.isRealPurchase && !item.moneyRequirementMet) {
      if ((item.linkedVaultId ?? '').isEmpty) {
        throw StateError('Vincule um cofre a este item real antes de comprar.');
      }
      throw StateError('O cofre vinculado ainda não tem dinheiro suficiente para esta compra.');
    }

    final now = DateTime.now().toIso8601String();
    final nextCoins = (currentCoins - item.coinCost).clamp(0, 1 << 31).toInt();

    await db.transaction((txn) async {
      await txn.insert(
        'shop_purchases',
        {
          'id': IdGenerator.create('shop_purchase'),
          'shop_item_id': item.id,
          'title_snapshot': item.title,
          'type_snapshot': item.type,
          'coin_cost_paid': item.coinCost,
          'required_money_snapshot': item.requiredMoneyAmount,
          'linked_vault_id': item.linkedVaultId,
          'note': note.trim(),
          'purchased_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await txn.update(
        'hero_profiles',
        {
          'coins': nextCoins,
          'level': await ProgressionService.levelFromXp(txn, readInt(heroRows.first, 'xp')),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: ['main_hero'],
      );

      await _insertHistory(
        txn,
        title: item.isRealPurchase ? 'Compra real liberada: ${item.title}' : 'Compra na loja: ${item.title}',
        description: item.isRealPurchase
            ? 'Item real comprado com coins e requisito do cofre cumprido. Faça a compra real fora do app com responsabilidade.'
            : 'Recompensa comprada com coins na Loja do Reino.',
        type: item.isRealPurchase ? 'shop_real_purchase' : 'shop_purchase',
        coinsDelta: -item.coinCost,
        nowIso: now,
      );
    });

    await AchievementRepository().refreshAutomaticAchievements();

    return ShopPurchaseResult(
      message: item.isRealPurchase
          ? 'Compra real liberada. Coins restantes: $nextCoins.'
          : 'Recompensa comprada. Coins restantes: $nextCoins.',
      remainingCoins: nextCoins,
    );
  }

  void _validateInput(CreateShopItemInput input) {
    if (input.title.trim().isEmpty) {
      throw ArgumentError('Informe um título para o item.');
    }
    if (input.type != 'reward' && input.type != 'real_purchase') {
      throw ArgumentError('Tipo de item inválido.');
    }
    if (input.coinCost < 0) {
      throw ArgumentError('O custo em coins não pode ser negativo.');
    }
    if (input.requiredMoneyAmount < 0) {
      throw ArgumentError('O valor real necessário não pode ser negativo.');
    }
    if (input.type == 'real_purchase' && input.requiredMoneyAmount > 0 && (input.linkedVaultId ?? '').isEmpty) {
      throw ArgumentError('Vincule um cofre para compras reais com requisito em dinheiro.');
    }
  }

  Future<void> _insertHistory(
    DatabaseExecutor executor, {
    required String title,
    required String description,
    required String type,
    required int coinsDelta,
    required String nowIso,
  }) async {
    await executor.insert(
      'history_events',
      {
        'id': IdGenerator.create('history'),
        'title': title,
        'description': description,
        'type': type,
        'xp_delta': 0,
        'coins_delta': coinsDelta,
        'occurred_at': nowIso,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}
