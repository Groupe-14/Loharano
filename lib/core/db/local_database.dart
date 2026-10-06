import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/measurement.dart';

class LocalDatabase {
  LocalDatabase._();
  static final instance = LocalDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'hydrocheck.db'),
      version: 2,
      onCreate: (database, version) async {
        await _createV2(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createV2(database);
      },
    );
    return _database!;
  }

  Future<void> _createV2(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS measurements (
        id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        test_type TEXT NOT NULL,
        source_type TEXT,
        lat REAL,
        lng REAL,
        location_accuracy_m REAL,
        location_precision TEXT,
        risk_level TEXT NOT NULL,
        confidence REAL NOT NULL,
        reasons_json TEXT,
        actions_json TEXT,
        image_path TEXT,
        water_point_id TEXT,
        is_demo INTEGER NOT NULL DEFAULT 0,
        sync_state TEXT NOT NULL DEFAULT 'pending',
        synced_at INTEGER
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS water_points (
        id TEXT PRIMARY KEY,
        name TEXT,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        point_type TEXT,
        is_demo INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER
      )
    ''');
  }

  Future<List<Measurement>> getMeasurements() async {
    final rows = await (await database)
        .query('measurements', orderBy: 'created_at DESC');
    return rows.map(Measurement.fromMap).toList();
  }

  Future<void> insertMeasurement(Measurement measurement) async {
    await (await database).insert('measurements', measurement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markSynced(String id) async {
    await (await database).update(
      'measurements',
      {
        'sync_state': 'synced',
        'synced_at': DateTime.now().toUtc().millisecondsSinceEpoch
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSyncFailed(String id) async {
    await (await database).update('measurements', {'sync_state': 'failed'},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WaterPoint>> getWaterPoints() async {
    final rows = await (await database)
        .query('water_points', orderBy: 'name COLLATE NOCASE');
    return rows.map(WaterPoint.fromMap).toList();
  }

  Future<WaterPoint?> findWaterPoint(String id) async {
    final rows = await (await database)
        .query('water_points', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return WaterPoint.fromMap(rows.first);
  }

  Future<void> insertWaterPoint(WaterPoint point) async {
    await (await database).insert('water_points', point.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Anciennes lignes v1 (statut safe/warning/danger) : conservées à part, jamais relues comme des mesures.
  Future<int> legacyRowCount() async {
    final database = await this.database;
    final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'water_tests'");
    if (tables.isEmpty) return 0;
    final count = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM water_tests'));
    return count ?? 0;
  }
}

/// Arrondit une coordonnée à environ 100 m (3 décimales).
double approx100m(double value) => (value * 1000).round() / 1000;
