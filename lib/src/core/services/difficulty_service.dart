import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../models/v3_commitment_models.dart';
import '../utils/id_generator.dart';
import '../utils/period_utils.dart';
import 'progression_service.dart';

class DifficultyPenaltyPreview {
  const DifficultyPenaltyPreview({
    required this.mode,
    required this.xpReward,
    required this.penaltyPercent,
    required this.xpPenalty,
  });

  final String mode;
  final int xpReward;
  final int penaltyPercent;
  final int xpPenalty;
}

class HardcoreEligibility {
  const HardcoreEligibility({
    required this.validCheckIns,
    required this.requiredCheckIns,
  });

  final int validCheckIns;
  final int requiredCheckIns;

  bool get isUnlocked => validCheckIns >= requiredCheckIns;

  int get remainingCheckIns {
    final remaining = requiredCheckIns - validCheckIns;
    return remaining > 0 ? remaining : 0;
  }

  double get progress {
    if (requiredCheckIns <= 0) return 1;
    return (validCheckIns / requiredCheckIns).clamp(0.0, 1.0).toDouble();
  }

  String get progressLabel =>
      '$validCheckIns de $requiredCheckIns check-ins v\u00e1lidos';
}

class HardcoreLockedException implements Exception {
  const HardcoreLockedException(this.eligibility);

  final HardcoreEligibility eligibility;

  @override
  String toString() {
    return 'Hardcore exige ${eligibility.requiredCheckIns} check-ins v\u00e1lidos. '
        'Progresso atual: ${eligibility.progressLabel}.';
  }
}

class DifficultyModeSummary {
  const DifficultyModeSummary({
    required this.activeMode,
    required this.activeName,
    required this.penaltyPercent,
    required this.curveMultiplier,
    required this.failurePenaltyEnabled,
    required this.maxLevel,
    required this.hardcoreEligibility,
  });

  final String activeMode;
  final String activeName;
  final int penaltyPercent;
  final double curveMultiplier;
  final bool failurePenaltyEnabled;
  final int maxLevel;
  final HardcoreEligibility hardcoreEligibility;

  bool get canActivateHardcore {
    return activeMode == 'hardcore' || hardcoreEligibility.isUnlocked;
  }

  String get penaltyLabel {
    if (!failurePenaltyEnabled || penaltyPercent <= 0) {
      return 'Sem perda de XP por falha.';
    }
    return 'Falhas removem $penaltyPercent% do XP da missão.';
  }

  String get curveLabel =>
      'Curva de nível ${curveMultiplier.toStringAsFixed(2).replaceAll('.', ',')}x';
}

class DifficultyPenaltySettlementResult {
  const DifficultyPenaltySettlementResult({
    required this.checked,
    required this.applied,
    required this.totalXpLost,
  });

  final int checked;
  final int applied;
  final int totalXpLost;

  String get message {
    if (applied <= 0) return 'Nenhuma penalidade pendente encontrada.';
    return '$applied penalidade(s) aplicada(s). -$totalXpLost XP no total.';
  }
}

class DifficultyService {
  DifficultyService({Future<Database> Function()? databaseProvider})
    : _databaseProvider = databaseProvider ?? _defaultDatabaseProvider;

  static const int hardcoreRequiredCheckIns = 7;

  final Future<Database> Function() _databaseProvider;

  static Future<Database> _defaultDatabaseProvider() {
    return AppDatabase.instance.database;
  }

  static String normalizeMode(String mode) {
    return switch (mode) {
      'hard' => 'hard',
      'hardcore' => 'hardcore',
      _ => 'normal',
    };
  }

  Future<List<DifficultyProfile>> getProfiles() async {
    final db = await _databaseProvider();
    return _getProfiles(db);
  }

  Future<List<DifficultyProfile>> _getProfiles(
    DatabaseExecutor executor,
  ) async {
    final rows = await executor.query(
      'difficulty_profiles',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'penalty_percent ASC',
    );
    return rows.map(DifficultyProfile.fromMap).toList();
  }

  Future<String> getActiveMode() async {
    final db = await _databaseProvider();
    return _getActiveMode(db);
  }

  Future<String> _getActiveMode(DatabaseExecutor executor) async {
    final rows = await executor.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['active_difficulty_mode'],
      limit: 1,
    );
    if (rows.isEmpty) return 'normal';
    final value = rows.first['value']?.toString() ?? 'normal';
    return value.isEmpty ? 'normal' : value;
  }

  Future<HardcoreEligibility> getHardcoreEligibility() async {
    final db = await _databaseProvider();
    return _getHardcoreEligibility(db);
  }

  Future<HardcoreEligibility> _getHardcoreEligibility(
    DatabaseExecutor executor,
  ) async {
    final rows = await executor.rawQuery('''
      SELECT COUNT(DISTINCT checkin_date) AS total
      FROM daily_checkins
      WHERE length(checkin_date) = 10
        AND checkin_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
        AND date(checkin_date, '+0 days') = checkin_date;
    ''');
    final rawTotal = rows.isEmpty ? null : rows.first['total'];
    final validCheckIns = rawTotal is num
        ? rawTotal.toInt()
        : int.tryParse(rawTotal?.toString() ?? '') ?? 0;
    return HardcoreEligibility(
      validCheckIns: validCheckIns,
      requiredCheckIns: hardcoreRequiredCheckIns,
    );
  }

  Future<HardcoreEligibility> validateModeChange(String mode) async {
    final normalized = normalizeMode(mode);
    final db = await _databaseProvider();
    final activeMode = await _getActiveMode(db);
    final eligibility = await _getHardcoreEligibility(db);
    _ensureModeChangeAllowed(
      activeMode: activeMode,
      requestedMode: normalized,
      eligibility: eligibility,
    );
    return eligibility;
  }

  Future<DifficultyModeSummary> getSummary() async {
    final db = await _databaseProvider();
    final settings = await _loadSettings(db);
    final mode = _readString(settings, 'active_difficulty_mode', 'normal');
    final profiles = await _getProfiles(db);
    final profile = _profileFor(profiles, mode);
    final hardcoreEligibility = await _getHardcoreEligibility(db);
    final curveMultiplier = _readDouble(
      settings,
      'level_curve_multiplier_$mode',
      ProgressionService.defaultCurveMultiplierForMode(mode),
    );

    return DifficultyModeSummary(
      activeMode: mode,
      activeName: profile?.name ?? _modeLabel(mode),
      penaltyPercent: profile?.penaltyPercent ?? 0,
      curveMultiplier: curveMultiplier,
      failurePenaltyEnabled: _readBool(
        settings,
        'mission_failure_penalty_enabled',
        true,
      ),
      maxLevel: _readInt(
        settings,
        'hero_max_level',
        ProgressionService.defaultMaxLevel,
      ),
      hardcoreEligibility: hardcoreEligibility,
    );
  }

  Future<void> setActiveMode(String mode) async {
    final normalized = normalizeMode(mode);
    final db = await _databaseProvider();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) => _setActiveMode(txn, normalized, nowIso: now));
  }

  Future<void> setActiveModeInTransaction(
    Transaction transaction,
    String mode, {
    String? nowIso,
  }) {
    return _setActiveMode(
      transaction,
      normalizeMode(mode),
      nowIso: nowIso ?? DateTime.now().toIso8601String(),
    );
  }

  Future<void> _setActiveMode(
    DatabaseExecutor executor,
    String normalized, {
    required String nowIso,
  }) async {
    final activeMode = await _getActiveMode(executor);
    if (activeMode != normalized) {
      final eligibility = await _getHardcoreEligibility(executor);
      _ensureModeChangeAllowed(
        activeMode: activeMode,
        requestedMode: normalized,
        eligibility: eligibility,
      );
    }

    await executor.insert('settings', {
      'key': 'active_difficulty_mode',
      'value': normalized,
      'value_type': 'string',
      'description': 'Modo de dificuldade ativo da campanha atual.',
      'updated_at': nowIso,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await executor.update(
      'settings',
      {'value': normalized, 'updated_at': nowIso},
      where: 'key = ?',
      whereArgs: ['active_difficulty_mode'],
    );

    await _syncActiveCampaignMode(executor, normalized, nowIso);
    if (activeMode == normalized) return;

    await ProgressionService.refreshHeroLevel(executor, nowIso: nowIso);

    await executor.insert('history_events', {
      'id': IdGenerator.create('history'),
      'title': 'Dificuldade alterada: ${_modeLabel(normalized)}',
      'description': 'A campanha agora usa o modo ${_modeLabel(normalized)}.',
      'type': 'difficulty_changed',
      'xp_delta': 0,
      'coins_delta': 0,
      'occurred_at': nowIso,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<DifficultyPenaltyPreview> previewPenalty({
    required int xpReward,
    String? mode,
  }) async {
    final selectedMode = mode ?? await getActiveMode();
    final profiles = await getProfiles();
    final profile = _profileFor(profiles, selectedMode);
    final penaltyPercent = profile?.penaltyPercent ?? 0;
    final penalty = ((xpReward * penaltyPercent) / 100).round();
    return DifficultyPenaltyPreview(
      mode: selectedMode,
      xpReward: xpReward,
      penaltyPercent: penaltyPercent,
      xpPenalty: penalty,
    );
  }

  Future<DifficultyPenaltySettlementResult>
  applyPendingMissionPenalties() async {
    final db = await _databaseProvider();
    final settings = await _loadSettings(db);
    final enabled = _readBool(
      settings,
      'mission_failure_penalty_enabled',
      true,
    );
    final mode = _readString(settings, 'active_difficulty_mode', 'normal');
    final profiles = await getProfiles();
    final profile = _profileFor(profiles, mode);
    final penaltyPercent = profile?.penaltyPercent ?? 0;

    if (!enabled || penaltyPercent <= 0) {
      return const DifficultyPenaltySettlementResult(
        checked: 0,
        applied: 0,
        totalXpLost: 0,
      );
    }

    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final missions = await db.query(
      'missions',
      where: "is_active = ? AND type IN ('daily', 'weekly', 'monthly')",
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );

    var checked = 0;
    var applied = 0;
    var totalXpLost = 0;

    await db.transaction((txn) async {
      for (final mission in missions) {
        final type = readString(mission, 'type', fallback: 'daily');
        final range = _previousRangeForMissionType(type, now);
        final createdAt = DateTime.tryParse(readString(mission, 'created_at'));

        if (createdAt != null && createdAt.isAfter(range.start)) continue;

        checked++;
        final missionId = readString(mission, 'id');
        if (missionId.isEmpty) continue;

        final completionRows = await txn.query(
          'mission_completions',
          columns: ['id'],
          where: 'mission_id = ? AND completed_on >= ? AND completed_on < ?',
          whereArgs: [missionId, range.startIso, range.endIso],
          limit: 1,
        );
        if (completionRows.isNotEmpty) continue;

        final penaltyRows = await txn.query(
          'difficulty_penalties',
          columns: ['id'],
          where: 'item_type = ? AND item_id = ? AND period_start = ?',
          whereArgs: ['mission', missionId, range.startIso],
          limit: 1,
        );
        if (penaltyRows.isNotEmpty) continue;

        final xpReward = readInt(mission, 'xp_reward');
        final xpPenalty = ((xpReward * penaltyPercent) / 100).round();
        if (xpPenalty <= 0) continue;

        await _applyHeroXpPenalty(
          txn: txn,
          xpPenalty: xpPenalty,
          nowIso: nowIso,
        );

        await txn.insert('difficulty_penalties', {
          'id': IdGenerator.create('penalty'),
          'item_type': 'mission',
          'item_id': missionId,
          'period_start': range.startIso,
          'period_end': range.endIso,
          'difficulty_mode': mode,
          'penalty_percent': penaltyPercent,
          'xp_penalty': xpPenalty,
          'applied_at': nowIso,
        }, conflictAlgorithm: ConflictAlgorithm.abort);

        await txn.insert('history_events', {
          'id': IdGenerator.create('history'),
          'title': 'Penalidade aplicada: ${readString(mission, 'title')}',
          'description':
              'Missão ${_typeLabel(type).toLowerCase()} não concluída no período anterior. -$xpPenalty XP no modo ${_modeLabel(mode)}.',
          'type': 'difficulty_penalty',
          'xp_delta': -xpPenalty,
          'coins_delta': 0,
          'occurred_at': nowIso,
        }, conflictAlgorithm: ConflictAlgorithm.abort);

        applied++;
        totalXpLost += xpPenalty;
      }
    });

    return DifficultyPenaltySettlementResult(
      checked: checked,
      applied: applied,
      totalXpLost: totalXpLost,
    );
  }

  void _ensureModeChangeAllowed({
    required String activeMode,
    required String requestedMode,
    required HardcoreEligibility eligibility,
  }) {
    final activatesHardcore =
        requestedMode == 'hardcore' && activeMode != 'hardcore';
    if (activatesHardcore && !eligibility.isUnlocked) {
      throw HardcoreLockedException(eligibility);
    }
  }

  Future<void> _syncActiveCampaignMode(
    DatabaseExecutor executor,
    String mode,
    String nowIso,
  ) {
    return executor.update(
      'campaigns',
      {'difficulty_mode': mode, 'updated_at': nowIso},
      where:
          'is_active = ? AND (difficulty_mode IS NULL OR difficulty_mode != ?)',
      whereArgs: [1, mode],
    );
  }

  Future<void> _applyHeroXpPenalty({
    required Transaction txn,
    required int xpPenalty,
    required String nowIso,
  }) async {
    final heroRows = await txn.query(
      'hero_profiles',
      where: 'id = ?',
      whereArgs: ['main_hero'],
      limit: 1,
    );

    if (heroRows.isEmpty) return;

    final currentXp = readInt(heroRows.first, 'xp');
    final newXp = (currentXp - xpPenalty).clamp(0, 1 << 31).toInt();
    final newLevel = await ProgressionService.levelFromXp(txn, newXp);

    await txn.update(
      'hero_profiles',
      {'xp': newXp, 'level': newLevel, 'updated_at': nowIso},
      where: 'id = ?',
      whereArgs: ['main_hero'],
    );
  }

  PeriodRange _previousRangeForMissionType(String type, DateTime reference) {
    final current = PeriodUtils.rangeForMissionType(type, reference);

    if (type == 'monthly') {
      final previousStart = DateTime(
        current.start.year,
        current.start.month - 1,
        1,
      );
      return PeriodRange(start: previousStart, end: current.start);
    }

    final duration = current.end.difference(current.start);
    final previousStart = current.start.subtract(duration);
    return PeriodRange(start: previousStart, end: current.start);
  }

  DifficultyProfile? _profileFor(
    List<DifficultyProfile> profiles,
    String mode,
  ) {
    for (final profile in profiles) {
      if (profile.code == mode) return profile;
    }
    return null;
  }

  String _modeLabel(String mode) {
    return switch (mode) {
      'hard' => 'Difícil',
      'hardcore' => 'Hardcore',
      _ => 'Normal',
    };
  }

  String _typeLabel(String type) {
    return switch (type) {
      'weekly' => 'Missão semanal',
      'monthly' => 'Missão mensal',
      _ => 'Missão diária',
    };
  }

  Future<Map<String, String>> _loadSettings(DatabaseExecutor executor) async {
    final rows = await executor.query('settings');
    return {
      for (final row in rows) row['key'].toString(): row['value'].toString(),
    };
  }

  String _readString(
    Map<String, String> settings,
    String key,
    String fallback,
  ) {
    final value = settings[key]?.trim();
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  int _readInt(Map<String, String> settings, String key, int fallback) {
    final parsed = int.tryParse(settings[key] ?? '');
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }

  double _readDouble(
    Map<String, String> settings,
    String key,
    double fallback,
  ) {
    final parsed = double.tryParse((settings[key] ?? '').replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }

  bool _readBool(Map<String, String> settings, String key, bool fallback) {
    final value = settings[key]?.trim().toLowerCase();
    if (value == null || value.isEmpty) return fallback;
    return value == 'true' || value == '1' || value == 'yes';
  }
}
