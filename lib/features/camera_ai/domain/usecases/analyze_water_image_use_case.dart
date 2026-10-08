import '../entities/water_diagnostic.dart';
import '../repositories/i_camera_ai_repository.dart';

/// Use-case principal : analyse une image d'eau et persiste le résultat.
///
/// Orchestre dans l'ordre :
/// 1. Validation du chemin d'image.
/// 2. Délégation de l'analyse au dépôt.
/// 3. Persistance automatique du diagnostic.
class AnalyzeWaterImageUseCase {
  const AnalyzeWaterImageUseCase(this._repository);

  final ICameraAiRepository _repository;

  /// Exécute le use-case complet.
  ///
  /// [imagePath] — chemin absolu vers le fichier image sur le disque.
  ///
  /// Retourne un [AnalysisResult] contenant le diagnostic ET l'id persisté.
  /// Lance [AnalysisException] si l'analyse échoue.
  Future<AnalysisResult> call(String imagePath) async {
    if (imagePath.isEmpty) {
      throw const AnalysisException(
          'Le chemin de l\'image est vide ou invalide.');
    }

    // 1. Analyse offline par extraction RVB/HSV
    final diagnostic = await _repository.analyzeImage(imagePath);

    // 2. Persistance immédiate dans SQLite
    final savedId =
        await _repository.saveDiagnostic(diagnostic, imagePath: imagePath);

    return AnalysisResult(diagnostic: diagnostic, savedId: savedId);
  }
}

/// Résultat complet du use-case : diagnostic + identifiant DB.
class AnalysisResult {
  const AnalysisResult({required this.diagnostic, required this.savedId});

  final WaterDiagnostic diagnostic;

  /// Identifiant de la ligne insérée dans `water_tests`.
  final int savedId;
}
