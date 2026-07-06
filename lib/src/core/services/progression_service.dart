import 'package:sqflite/sqflite.dart';

class LevelProgressSnapshot {
  const LevelProgressSnapshot({
    required this.level,
    required this.totalXp,
    required this.currentLevelXp,
    required this.requiredForNextLevel,
    required this.progress,
    required this.maxLevel,
    required this.difficultyMode,
    required this.curveMultiplier,
  });

  final int level;
  final int totalXp;
  final int currentLevelXp;
  final int requiredForNextLevel;
  final double progress;
  final int maxLevel;
  final String difficultyMode;
  final double curveMultiplier;

  bool get isMaxLevel => level >= maxLevel;
}

class ProgressionService {
  const ProgressionService._();

  static const int defaultMaxLevel = 100;

  static int baseXpRequiredForNextLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    final step = safeLevel - 1;
    return 100 + (step * step * 50);
  }

  static double defaultCurveMultiplierForMode(String mode) {
    return switch (mode) {
      'hard' => 1.25,
      'hardcore' => 1.5,
      _ => 1.0,
    };
  }

  static int xpRequiredForNextLevelSync(
    int level, {
    String difficultyMode = 'normal',
    double? curveMultiplier,
  }) {
    final multiplier = curveMultiplier ?? defaultCurveMultiplierForMode(difficultyMode);
    final required = (baseXpRequiredForNextLevel(level) * multiplier).round();
    return required < 1 ? 1 : required;
  }

  static LevelProgressSnapshot snapshotFromXpSync(
    int xp, {
    String difficultyMode = 'normal',
    double? curveMultiplier,
    int maxLevel = defaultMaxLevel,
  }) {
    final safeMaxLevel = maxLevel < 1 ? defaultMaxLevel : maxLevel;
    final safeXp = xp < 0 ? 0 : xp;
    final multiplier = curveMultiplier ?? defaultCurveMultiplierForMode(difficultyMode);
    var level = 1;
    var remaining = safeXp;

    while (level < safeMaxLevel) {
      final required = xpRequiredForNextLevelSync(
        level,
        difficultyMode: difficultyMode,
        curveMultiplier: multiplier,
      );

      if (remaining < required) {
        return LevelProgressSnapshot(
          level: level,
          totalXp: safeXp,
          currentLevelXp: remaining,
          requiredForNextLevel: required,
          progress: (remaining / required).clamp(0.0, 1.0).toDouble(),
          maxLevel: safeMaxLevel,
          difficultyMode: difficultyMode,
          curveMultiplier: multiplier,
        );
      }

      remaining -= required;
      level++;
    }

    return LevelProgressSnapshot(
      level: safeMaxLevel,
      totalXp: safeXp,
      currentLevelXp: 1,
      requiredForNextLevel: 1,
      progress: 1,
      maxLevel: safeMaxLevel,
      difficultyMode: difficultyMode,
      curveMultiplier: multiplier,
    );
  }

  static Future<LevelProgressSnapshot> snapshotFromXp(
    DatabaseExecutor executor,
    int xp,
  ) async {
    final settings = await _loadSettings(executor);
    final mode = _readString(settings, 'active_difficulty_mode', 'normal');
    final multiplier = _readDouble(
      settings,
      'level_curve_multiplier_$mode',
      defaultCurveMultiplierForMode(mode),
    );
    final maxLevel = _readInt(settings, 'hero_max_level', defaultMaxLevel);

    return snapshotFromXpSync(
      xp,
      difficultyMode: mode,
      curveMultiplier: multiplier,
      maxLevel: maxLevel,
    );
  }

  static Future<int> levelFromXp(DatabaseExecutor executor, int xp) async {
    return (await snapshotFromXp(executor, xp)).level;
  }

  static Future<void> refreshHeroLevel(
    DatabaseExecutor executor, {
    String heroId = 'main_hero',
    String? nowIso,
  }) async {
    final rows = await executor.query(
      'hero_profiles',
      where: 'id = ?',
      whereArgs: [heroId],
      limit: 1,
    );

    if (rows.isEmpty) return;

    final xp = _readIntFromMap(rows.first, 'xp');
    final level = await levelFromXp(executor, xp);

    await executor.update(
      'hero_profiles',
      {
        'level': level,
        'updated_at': nowIso ?? DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [heroId],
    );
  }

  static Future<Map<String, String>> _loadSettings(DatabaseExecutor executor) async {
    final rows = await executor.query('settings');
    return {
      for (final row in rows) row['key'].toString(): row['value'].toString(),
    };
  }

  static String _readString(
    Map<String, String> settings,
    String key,
    String fallback,
  ) {
    final value = settings[key]?.trim();
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  static int _readInt(Map<String, String> settings, String key, int fallback) {
    final parsed = int.tryParse(settings[key] ?? '');
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }

  static double _readDouble(Map<String, String> settings, String key, double fallback) {
    final parsed = double.tryParse((settings[key] ?? '').replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }

  static int _readIntFromMap(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
