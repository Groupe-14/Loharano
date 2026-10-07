import '../../../../core/models/water_test_model.dart';
import '../../../../core/repositories/local_database.dart';

/// Feature-level gateway for offline test persistence.
class LocalDbService {
  LocalDbService._();

  static final instance = LocalDbService._();

  Future<void> saveTest(WaterTestModel test) async {
    await LocalDatabase.instance.insertTest(test);
  }

  Future<List<WaterTestModel>> getAllTests() async {
    final tests = await LocalDatabase.instance.getTests();
    tests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return tests;
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final database = await LocalDatabase.instance.database;
    final numericIds = ids.map(int.tryParse).whereType<int>().toList();
    if (numericIds.isEmpty) return;
    final placeholders = List.filled(numericIds.length, '?').join(',');
    await database.rawUpdate(
      'UPDATE water_tests SET is_synced = 1 WHERE id IN ($placeholders)',
      numericIds,
    );
  }
}
