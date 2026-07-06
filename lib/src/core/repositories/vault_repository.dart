import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../utils/id_generator.dart';
import 'achievement_repository.dart';

class CreateVaultInput {
  const CreateVaultInput({
    required this.name,
    required this.description,
    required this.goalAmount,
  });

  final String name;
  final String description;
  final double goalAmount;
}

class VaultEntryResult {
  const VaultEntryResult({
    required this.message,
    required this.balance,
  });

  final String message;
  final double balance;
}

class VaultRepository {
  const VaultRepository();

  Future<VaultOverview> getOverview() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM vaults WHERE status = 'active') AS active_vaults,
        COALESCE(SUM(CASE WHEN vault_entries.type = 'deposit' THEN vault_entries.amount WHEN vault_entries.type = 'withdraw' THEN -vault_entries.amount ELSE 0 END), 0) AS total_balance,
        (SELECT COALESCE(SUM(goal_amount), 0) FROM vaults WHERE status = 'active') AS total_goals,
        COALESCE(SUM(CASE WHEN vault_entries.type = 'deposit' THEN vault_entries.amount ELSE 0 END), 0) AS total_deposits,
        COALESCE(SUM(CASE WHEN vault_entries.type = 'withdraw' THEN vault_entries.amount ELSE 0 END), 0) AS total_withdrawals
      FROM vaults
      LEFT JOIN vault_entries ON vault_entries.vault_id = vaults.id
      WHERE vaults.status = 'active';
    ''');

    if (rows.isEmpty) return VaultOverview.empty;
    return VaultOverview.fromMap(rows.first);
  }

  Future<List<VaultWithSummary>> getVaultsWithSummary({bool includeArchived = false}) async {
    final db = await AppDatabase.instance.database;
    final where = includeArchived ? '' : "WHERE vaults.status = 'active'";
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
      $where
      GROUP BY vaults.id
      ORDER BY vaults.status ASC, vaults.created_at DESC;
    ''');

    return rows.map((row) {
      return VaultWithSummary(
        vault: Vault.fromMap(row),
        summary: VaultSummary.fromMap(row),
      );
    }).toList();
  }

  Future<Vault?> getVaultById(String vaultId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'vaults',
      where: 'id = ?',
      whereArgs: [vaultId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Vault.fromMap(rows.first);
  }

  Future<VaultSummary> getSummary(String vaultId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'deposit' THEN amount WHEN type = 'withdraw' THEN -amount ELSE 0 END), 0) AS balance,
        COALESCE(SUM(CASE WHEN type = 'deposit' THEN amount ELSE 0 END), 0) AS deposits_total,
        COALESCE(SUM(CASE WHEN type = 'withdraw' THEN amount ELSE 0 END), 0) AS withdrawals_total,
        COUNT(id) AS entries_count,
        COALESCE(MAX(created_at), '') AS last_entry_at
      FROM vault_entries
      WHERE vault_id = ?;
    ''', [vaultId]);

    if (rows.isEmpty) return VaultSummary.empty;
    return VaultSummary.fromMap(rows.first);
  }

  Future<List<VaultEntry>> getRecentEntries({String? vaultId, int limit = 20}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'vault_entries',
      where: vaultId == null ? null : 'vault_id = ?',
      whereArgs: vaultId == null ? null : [vaultId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(VaultEntry.fromMap).toList();
  }

  Future<String> createVault(CreateVaultInput input) async {
    _validateVaultInput(input);

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final vaultId = IdGenerator.create('vault');

    await db.transaction((txn) async {
      await txn.insert(
        'vaults',
        {
          'id': vaultId,
          'name': input.name.trim(),
          'description': input.description.trim(),
          'goal_amount': input.goalAmount < 0 ? 0 : input.goalAmount,
          'icon': 'savings',
          'color': 'amber',
          'status': 'active',
          'created_at': now,
          'updated_at': now,
          'archived_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _insertHistory(
        txn,
        title: 'Cofre criado: ${input.name.trim()}',
        description: input.goalAmount > 0
            ? 'Novo cofre com meta de ${formatCurrency(input.goalAmount)}.'
            : 'Novo cofre financeiro criado.',
        type: 'vault_created',
        nowIso: now,
      );
    });

    await AchievementRepository().refreshAutomaticAchievements();
    return vaultId;
  }

  Future<void> updateVault({
    required String vaultId,
    required CreateVaultInput input,
  }) async {
    _validateVaultInput(input);

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'vaults',
        {
          'name': input.name.trim(),
          'description': input.description.trim(),
          'goal_amount': input.goalAmount < 0 ? 0 : input.goalAmount,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [vaultId],
      );

      await _insertHistory(
        txn,
        title: 'Cofre editado: ${input.name.trim()}',
        description: 'Configuração do cofre financeiro atualizada.',
        type: 'vault_updated',
        nowIso: now,
      );
    });
  }

  Future<void> archiveVault(String vaultId) async {
    final db = await AppDatabase.instance.database;
    final vault = await getVaultById(vaultId);
    if (vault == null) return;

    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        'vaults',
        {
          'status': 'archived',
          'updated_at': now,
          'archived_at': now,
        },
        where: 'id = ?',
        whereArgs: [vaultId],
      );

      await _insertHistory(
        txn,
        title: 'Cofre arquivado: ${vault.name}',
        description: 'O cofre saiu da lista ativa, mas o histórico continua salvo.',
        type: 'vault_archived',
        nowIso: now,
      );
    });
  }

  Future<VaultEntryResult> addEntry({
    required String vaultId,
    required String type,
    required double amount,
    String note = '',
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Informe um valor maior que zero.');
    }
    if (type != 'deposit' && type != 'withdraw') {
      throw ArgumentError('Tipo de movimentação inválido.');
    }

    final db = await AppDatabase.instance.database;
    final vault = await getVaultById(vaultId);
    if (vault == null) {
      throw StateError('Cofre não encontrado.');
    }
    if (!vault.isActive) {
      throw StateError('Não é possível movimentar um cofre arquivado.');
    }

    final currentSummary = await getSummary(vaultId);
    if (type == 'withdraw' && amount > currentSummary.balance) {
      throw ArgumentError('Retirada maior que o saldo do cofre.');
    }

    final now = DateTime.now().toIso8601String();
    final nextBalance = type == 'deposit'
        ? currentSummary.balance + amount
        : currentSummary.balance - amount;

    await db.transaction((txn) async {
      await txn.insert(
        'vault_entries',
        {
          'id': IdGenerator.create('vault_entry'),
          'vault_id': vaultId,
          'type': type,
          'amount': amount,
          'note': note.trim(),
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await txn.update(
        'vaults',
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [vaultId],
      );

      await _insertHistory(
        txn,
        title: type == 'deposit'
            ? 'Depósito no cofre: ${vault.name}'
            : 'Retirada do cofre: ${vault.name}',
        description: type == 'deposit'
            ? '${formatCurrency(amount)} guardados no Cofre do Reino.'
            : '${formatCurrency(amount)} retirados do Cofre do Reino.',
        type: type == 'deposit' ? 'vault_deposit' : 'vault_withdraw',
        nowIso: now,
      );
    });

    await AchievementRepository().refreshAutomaticAchievements();

    return VaultEntryResult(
      message: type == 'deposit'
          ? 'Depósito registrado. Saldo: ${formatCurrency(nextBalance)}.'
          : 'Retirada registrada. Saldo: ${formatCurrency(nextBalance)}.',
      balance: nextBalance,
    );
  }

  void _validateVaultInput(CreateVaultInput input) {
    if (input.name.trim().isEmpty) {
      throw ArgumentError('Informe um nome para o cofre.');
    }
    if (input.goalAmount < 0) {
      throw ArgumentError('A meta não pode ser negativa.');
    }
  }

  Future<void> _insertHistory(
    DatabaseExecutor executor, {
    required String title,
    required String description,
    required String type,
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
        'coins_delta': 0,
        'occurred_at': nowIso,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}
