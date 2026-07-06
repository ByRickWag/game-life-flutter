import 'package:sqflite/sqflite.dart';

class MissionReward {
  const MissionReward({
    required this.xp,
    required this.coins,
  });

  final int xp;
  final int coins;
}

class ObjectiveReward {
  const ObjectiveReward({
    required this.xp,
    required this.coins,
  });

  final int xp;
  final int coins;
}

class SessionReward {
  const SessionReward({
    required this.xp,
    required this.coins,
    required this.reachedCap,
    required this.xpCap,
  });

  final int xp;
  final int coins;
  final bool reachedCap;
  final int xpCap;
}

class ProjectReward {
  const ProjectReward({
    required this.xp,
    required this.coins,
  });

  final int xp;
  final int coins;
}

class RewardService {
  const RewardService(this.db);

  final Database db;

  static const int sessionXpCap = 150;

  static int missionXpCap({
    required String type,
    required String difficulty,
  }) {
    if (type == 'special' && difficulty == 'very_hard') return 300;

    return switch (difficulty) {
      'easy' => 20,
      'normal' => 30,
      'medium' => 40,
      'hard' => 60,
      'very_hard' => 100,
      _ => 30,
    };
  }

  static int objectiveXpCap({required String difficulty}) {
    return switch (difficulty) {
      'easy' => 20,
      'normal' => 30,
      'medium' => 40,
      'hard' => 60,
      'very_hard' => 300,
      _ => 30,
    };
  }

  static int clampXpToCap({
    required int value,
    required int cap,
  }) {
    if (value <= 0) return 1;
    if (value > cap) return cap;
    return value;
  }

  Future<int> missionXpCapFromSettings({
    required String type,
    required String difficulty,
  }) async {
    final settings = await _loadSettings();

    if (type == 'special' && difficulty == 'very_hard') {
      return _readInt(
        settings,
        'xp_cap_special_very_hard',
        missionXpCap(type: type, difficulty: difficulty),
      );
    }

    return _readInt(
      settings,
      'xp_cap_mission_$difficulty',
      missionXpCap(type: type, difficulty: difficulty),
    );
  }

  Future<int> objectiveXpCapFromSettings({required String difficulty}) async {
    return _readInt(
      await _loadSettings(),
      'xp_cap_objective_$difficulty',
      objectiveXpCap(difficulty: difficulty),
    );
  }

  Future<int> sessionXpCapFromSettings() async {
    return _readInt(await _loadSettings(), 'xp_cap_session', sessionXpCap);
  }

  Future<MissionReward> calculateMissionReward({
    required String type,
    required String difficulty,
  }) async {
    final settings = await _loadSettings();
    final xp = await missionXpCapFromSettings(type: type, difficulty: difficulty);
    final coins = _readInt(settings, 'coins_$difficulty', _defaultCoins(difficulty));
    return MissionReward(xp: xp, coins: coins);
  }

  Future<ObjectiveReward> calculateObjectiveReward({
    required String difficulty,
  }) async {
    final settings = await _loadSettings();
    final xp = await objectiveXpCapFromSettings(difficulty: difficulty);
    final coins = _readInt(settings, 'coins_$difficulty', _defaultCoins(difficulty));
    return ObjectiveReward(
      xp: xp,
      coins: (coins * 4 * _objectiveCoinMultiplier(difficulty)).round(),
    );
  }

  Future<SessionReward> calculateSessionReward({
    required int durationMinutes,
  }) async {
    final settings = await _loadSettings();
    final safeMinutes = durationMinutes <= 0 ? 1 : durationMinutes;
    final blocksOf15 = ((safeMinutes + 14) ~/ 15).clamp(1, 96).toInt();
    final xpPer15 = _readInt(settings, 'session_xp_per_15min', 5);
    final xpCap = _readInt(settings, 'xp_cap_session', sessionXpCap);
    final rawXp = blocksOf15 * xpPer15;
    final xp = rawXp > xpCap ? xpCap : rawXp;
    final coins = ((blocksOf15 + 1) ~/ 2).clamp(1, 80).toInt();

    return SessionReward(
      xp: xp,
      coins: coins,
      reachedCap: rawXp >= xpCap,
      xpCap: xpCap,
    );
  }

  Future<ProjectReward> calculateProjectReward({
    required String difficulty,
  }) async {
    final settings = await _loadSettings();
    return ProjectReward(
      xp: _readInt(settings, 'project_completion_xp', 150),
      coins: _readInt(settings, 'project_completion_coins', 50),
    );
  }

  Future<int> projectTaskDefaultXp() async {
    return _readInt(await _loadSettings(), 'project_task_xp_default', 5);
  }

  Future<int> projectTaskXpCap() async {
    return _readInt(await _loadSettings(), 'project_task_xp_cap', 10);
  }

  Future<int> clampProjectTaskXp(int value) async {
    final cap = await projectTaskXpCap();
    if (value <= 0) return 1;
    if (value > cap) return cap;
    return value;
  }

  int _defaultCoins(String difficulty) {
    return switch (difficulty) {
      'easy' => 3,
      'normal' => 5,
      'medium' => 7,
      'hard' => 10,
      'very_hard' => 15,
      _ => 5,
    };
  }

  double _objectiveCoinMultiplier(String difficulty) {
    return switch (difficulty) {
      'easy' => 0.75,
      'normal' => 1.0,
      'medium' => 1.2,
      'hard' => 1.5,
      'very_hard' => 2.0,
      _ => 1.0,
    };
  }

  Future<Map<String, String>> _loadSettings() async {
    final rows = await db.query('settings');
    return {
      for (final row in rows) row['key'].toString(): row['value'].toString(),
    };
  }

  int _readInt(Map<String, String> settings, String key, int fallback) {
    final parsed = int.tryParse(settings[key] ?? '');
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }
}
