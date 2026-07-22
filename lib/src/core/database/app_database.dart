import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_schema.dart';
import 'db_seeds.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'game_life_release_v1.db';
  static const int _databaseVersion = 16;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final opened = await _openDatabase();
    _database = opened;
    return opened;
  }

  Future<String> get databasePath async {
    final dbFolder = await getDatabasesPath();
    return join(dbFolder, _databaseName);
  }

  Future<Database> _openDatabase() async {
    final path = await databasePath;

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await DbSchema.create(db);
        await DbSeeds.run(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await DbSchema.upgrade(db, oldVersion, newVersion);
        await DbSeeds.run(db);
      },
      onOpen: (db) async {
        await DbSeeds.run(db);
      },
    );
  }

  Future<List<Map<String, Object?>>> queryAll(
    String table, {
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(table, orderBy: orderBy, limit: limit);
  }

  Future<Map<String, Object?>?> queryFirst(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    final rows = await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }
}
