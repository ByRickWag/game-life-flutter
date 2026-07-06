import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../database/app_database.dart';
import '../utils/id_generator.dart';

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  static const ReminderSettings defaults = ReminderSettings(
    enabled: false,
    hour: 20,
    minute: 0,
  );

  String get timeLabel {
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hourText:$minuteText';
  }
}

class ReminderSummary {
  const ReminderSummary({
    required this.activeMissions,
    required this.activeObjectives,
    required this.pendingTasks,
  });

  final int activeMissions;
  final int activeObjectives;
  final int pendingTasks;

  int get total => activeMissions + activeObjectives + pendingTasks;

  String get shortText {
    if (total == 0) {
      return 'Nenhuma pendência ativa no momento.';
    }

    return '$activeMissions missões • $activeObjectives objetivos • $pendingTasks tarefas';
  }

  String get notificationBody {
    if (total == 0) {
      return 'Abra o app para planejar sua próxima ação da jornada.';
    }

    return 'Você tem $activeMissions missões, $activeObjectives objetivos e $pendingTasks tarefas para revisar.';
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int dailyReminderId = 2901;
  static const int testReminderId = 2902;
  static const String _channelId = 'game_life_daily_reminders';
  static const String _channelName = 'Lembretes do Game Life';
  static const String _channelDescription =
      'Lembretes leves para revisar missões, objetivos e tarefas.';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    timezone_data.initializeTimeZones();

    try {
      timezone.setLocalLocation(timezone.getLocation('America/Sao_Paulo'));
    } catch (_) {
      // Mantém a configuração padrão se o timezone não puder ser carregado.
    }

    const androidSettings = AndroidInitializationSettings('ic_stat_game_life');
    const initializationSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;

    final db = await AppDatabase.instance.database;
    await ensureReminderSettings(db);
  }

  Future<void> ensureReminderSettings(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'settings',
      {
        'key': 'notifications_daily_enabled',
        'value': ReminderSettings.defaults.enabled ? '1' : '0',
        'value_type': 'bool',
        'description': 'Ativa ou desativa o lembrete diário do Game Life.',
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.insert(
      'settings',
      {
        'key': 'notifications_daily_hour',
        'value': ReminderSettings.defaults.hour.toString(),
        'value_type': 'int',
        'description': 'Hora do lembrete diário.',
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.insert(
      'settings',
      {
        'key': 'notifications_daily_minute',
        'value': ReminderSettings.defaults.minute.toString(),
        'value_type': 'int',
        'description': 'Minuto do lembrete diário.',
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<ReminderSettings> getReminderSettings() async {
    await initialize();

    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'settings',
      where: 'key IN (?, ?, ?)',
      whereArgs: [
        'notifications_daily_enabled',
        'notifications_daily_hour',
        'notifications_daily_minute',
      ],
    );

    String valueFor(String key, String fallback) {
      for (final row in rows) {
        if (row['key'] == key) return row['value']?.toString() ?? fallback;
      }
      return fallback;
    }

    final enabled = valueFor('notifications_daily_enabled', '0') == '1';
    final hour = int.tryParse(valueFor('notifications_daily_hour', '20')) ?? 20;
    final minute = int.tryParse(valueFor('notifications_daily_minute', '0')) ?? 0;

    return ReminderSettings(
      enabled: enabled,
      hour: hour.clamp(0, 23).toInt(),
      minute: minute.clamp(0, 59).toInt(),
    );
  }

  Future<ReminderSummary> getTodaySummary() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM missions WHERE is_active = 1) AS active_missions,
        (SELECT COUNT(*) FROM objectives WHERE status = 'active') AS active_objectives,
        (SELECT COUNT(*) FROM project_tasks
          INNER JOIN projects ON projects.id = project_tasks.project_id
          WHERE project_tasks.is_done = 0 AND projects.status = 'active') AS pending_tasks;
    ''');

    if (rows.isEmpty) {
      return const ReminderSummary(
        activeMissions: 0,
        activeObjectives: 0,
        pendingTasks: 0,
      );
    }

    final row = rows.first;
    return ReminderSummary(
      activeMissions: _readInt(row, 'active_missions'),
      activeObjectives: _readInt(row, 'active_objectives'),
      pendingTasks: _readInt(row, 'pending_tasks'),
    );
  }

  Future<bool> requestPermission() async {
    await initialize();

    if (!defaultTargetPlatformIsAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await initialize();

    if (enabled) {
      final granted = await requestPermission();
      if (!granted) {
        throw StateError('Permissão de notificações não concedida.');
      }
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'settings',
      {
        'value': enabled ? '1' : '0',
        'updated_at': now,
      },
      where: 'key = ?',
      whereArgs: ['notifications_daily_enabled'],
    );

    if (enabled) {
      await scheduleDailyReminder();
    } else {
      await cancelDailyReminder();
    }

    await _insertHistory(
      title: enabled ? 'Lembretes ativados' : 'Lembretes desativados',
      description: enabled
          ? 'O lembrete diário do Game Life foi ativado.'
          : 'O lembrete diário do Game Life foi desativado.',
    );
  }

  Future<void> setDailyReminderTime({
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final cleanHour = hour.clamp(0, 23).toInt();
    final cleanMinute = minute.clamp(0, 59).toInt();
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'settings',
        {'value': cleanHour.toString(), 'updated_at': now},
        where: 'key = ?',
        whereArgs: ['notifications_daily_hour'],
      );

      await txn.update(
        'settings',
        {'value': cleanMinute.toString(), 'updated_at': now},
        where: 'key = ?',
        whereArgs: ['notifications_daily_minute'],
      );
    });

    final settings = await getReminderSettings();
    if (settings.enabled) {
      await scheduleDailyReminder();
    }
  }

  Future<void> scheduleDailyReminder() async {
    await initialize();

    final settings = await getReminderSettings();
    if (!settings.enabled) return;

    await cancelDailyReminder();

    await _plugin.zonedSchedule(
      id: dailyReminderId,
      title: 'Game Life',
      body: 'Revise suas missões, objetivos e tarefas de hoje.',
      scheduledDate: _nextInstanceOfTime(settings.hour, settings.minute),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  Future<void> cancelDailyReminder() async {
    await initialize();
    await _plugin.cancel(id: dailyReminderId);
  }

  Future<void> showTestReminder() async {
    await initialize();

    final granted = await requestPermission();
    if (!granted) {
      throw StateError('Permissão de notificações não concedida.');
    }

    final summary = await getTodaySummary();

    await _plugin.show(
      id: testReminderId,
      title: 'Game Life',
      body: summary.notificationBody,
      notificationDetails: _notificationDetails(),
      payload: 'test_reminder',
    );
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
    );

    return const NotificationDetails(android: androidDetails);
  }

  timezone.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  Future<void> _insertHistory({
    required String title,
    required String description,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'history_events',
      {
        'id': IdGenerator.create('history'),
        'title': title,
        'description': description,
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}

bool get defaultTargetPlatformIsAndroid => defaultTargetPlatform.isAndroid;
