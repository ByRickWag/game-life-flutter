import '../database/app_database.dart';
import '../models/game_models.dart';
import 'habit_repository.dart';

class HealthOverview {
  const HealthOverview({
    required this.water,
    required this.foodLimits,
  });

  final HabitWithStats? water;
  final List<HabitWithStats> foodLimits;

  int get foodAlerts {
    return foodLimits
        .where((item) => item.stats.totalLogged > item.habit.limitValue)
        .length;
  }

  int get foodInsidePlan {
    return foodLimits.length - foodAlerts;
  }

  double get waterLogged => water?.stats.totalLogged ?? 0;
  double get waterTarget => water?.habit.targetValue ?? 0;

  double get waterProgress {
    final item = water;
    if (item == null) return 0;
    return item.stats.progressFor(item.habit);
  }
}

class HealthRepository {
  HealthRepository({HabitRepository? habitRepository})
      : _habitRepository = habitRepository ?? HabitRepository();

  final HabitRepository _habitRepository;

  Future<HealthOverview> getOverview() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT habits.*, areas.name AS area_name, attributes.name AS attribute_name
      FROM habits
      LEFT JOIN areas ON areas.id = habits.area_id
      LEFT JOIN attributes ON attributes.id = habits.attribute_id
      WHERE habits.is_active = 1
        AND habits.health_kind IN ('water', 'food_limit')
      ORDER BY
        CASE habits.health_kind
          WHEN 'water' THEN 1
          WHEN 'food_limit' THEN 2
          ELSE 3
        END,
        CASE habits.health_category
          WHEN 'soda' THEN 1
          WHEN 'ultra_processed' THEN 2
          WHEN 'fast_food' THEN 3
          ELSE 4
        END,
        habits.created_at ASC;
    ''');

    HabitWithStats? water;
    final foodLimits = <HabitWithStats>[];

    for (final row in rows) {
      final habit = Habit.fromMap(row);
      final item = HabitWithStats(
        habit: habit,
        stats: await _habitRepository.getCurrentStats(habit),
      );

      if (habit.isWaterTracked && water == null) {
        water = item;
      } else if (habit.isFoodLimitTracked) {
        foodLimits.add(item);
      }
    }

    return HealthOverview(water: water, foodLimits: foodLimits);
  }

  Future<HabitLogResult> addWater(double milliliters) async {
    final overview = await getOverview();
    final waterHabit = overview.water?.habit;
    if (waterHabit == null) {
      throw StateError('Nenhum hábito de água ativo foi encontrado.');
    }

    return _habitRepository.addLog(habit: waterHabit, value: milliliters);
  }

  Future<HabitLogResult> addFoodLog({
    required Habit habit,
    required double value,
    String note = '',
  }) async {
    if (!habit.isFoodLimitTracked) {
      throw StateError('Esse hábito não é um rastreador alimentar.');
    }

    return _habitRepository.addLog(habit: habit, value: value, note: note);
  }

  Future<HabitLogResult> claimFoodLimit(Habit habit) async {
    if (!habit.isFoodLimitTracked) {
      throw StateError('Esse hábito não é um rastreador alimentar.');
    }

    return _habitRepository.claimReductionPeriodSuccess(habit);
  }
}
