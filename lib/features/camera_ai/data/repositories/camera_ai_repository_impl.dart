import '../../domain/entities/water_diagnostic.dart';
import '../../domain/repositories/i_camera_ai_repository.dart';
import '../datasources/camera_ai_local_datasource.dart';
import '../../../../core/repositories/local_database.dart';

/// Implémentation concrète de [ICameraAiRepository].
///
/// Orchestre :
/// - [CameraAiLocalDataSource] → extraction chromatique RVB/HSV offline
/// - [LocalDatabase] → persistance SQLite
class CameraAiRepositoryImpl implements ICameraAiRepository {
  CameraAiRepositoryImpl({
    CameraAiLocalDataSource? dataSource,
    LocalDatabase? database,
  })  : _dataSource = dataSource ?? const CameraAiLocalDataSource(),
        _db = database ?? LocalDatabase.instance;

  final CameraAiLocalDataSource _dataSource;
  final LocalDatabase _db;

  @override
  Future<WaterDiagnostic> analyzeImage(String imagePath) async {
    // Délègue l'analyse 100% offline à la source de données.
    return _dataSource.analyze(imagePath);
  }

  @override
  Future<int> saveDiagnostic(
    WaterDiagnostic diagnostic, {
    String? imagePath,
  }) async {
    final model = diagnostic.toWaterTestModel(imagePath: imagePath);
    return _db.insertTest(model);
  }
}
