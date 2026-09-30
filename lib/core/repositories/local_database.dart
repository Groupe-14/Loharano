import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/water_test_model.dart';

class LocalDatabase {
  LocalDatabase._();
  static final instance = LocalDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'hydrocheck.db'),
      version: 1,
      onCreate: (database, version) => database.execute('''
        CREATE TABLE water_tests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT NOT NULL,
          status TEXT NOT NULL,
          turbidity_score REAL NOT NULL,
          image_path TEXT,
          qr_code_id TEXT,
          is_synced INTEGER NOT NULL DEFAULT 0
        )
      '''),
    );
    return _database!;
  }

  Future<List<WaterTestModel>> getTests() async {
    final rows = await (await database).query('water_tests', orderBy: 'timestamp DESC');
    return rows.map(WaterTestModel.fromMap).toList();
  }

  Future<int> insertTest(WaterTestModel test) async {
    return (await database).insert('water_tests', test.toMap());
  }
}
