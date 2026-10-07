import '../entities/water_diagnostic.dart';

/// Contrat du dépôt camera_ai.
///
/// L'implémentation [CameraAiRepositoryImpl] orchestre :
/// 1. l'analyse d'image via [CameraAiLocalDataSource] (RVB/HSV offline),
/// 2. la persistance du résultat en base de données SQLite locale.
abstract interface class ICameraAiRepository {
  /// Analyse l'image localisée à [imagePath] et retourne un [WaterDiagnostic].
  ///
  /// Lance une [AnalysisException] si l'image est invalide, trop sombre
  /// ou floue.
  Future<WaterDiagnostic> analyzeImage(String imagePath);

  /// Persiste le [diagnostic] dans la base SQLite locale.
  ///
  /// Retourne l'identifiant de la ligne insérée.
  Future<int> saveDiagnostic(WaterDiagnostic diagnostic, {String? imagePath});
}

/// Exception levée lorsque l'analyse d'image échoue.
class AnalysisException implements Exception {
  const AnalysisException(this.message);
  final String message;

  @override
  String toString() => 'AnalysisException: $message';
}
