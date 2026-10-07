import '../../domain/entities/water_diagnostic.dart';

/// Service de simulation utilisé en mode démo ou lorsque l'algorithme
/// principal n'est pas disponible.
///
/// Produit des résultats déterministes et cohérents avec l'interface
/// [WaterDiagnostic] enrichie (phValue, chlorineLevel, confidence).
class SimulatedAiService {
  const SimulatedAiService();

  Future<WaterDiagnostic> analyze({Object? imageData}) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));
    // Score légèrement variable selon la présence ou non d'imageData.
    final score = imageData == null ? 0.24 : 0.34;
    return _diagnosticForScore(score);
  }

  Future<WaterDiagnostic> analyzeForced(WaterDiagnosticStatus status) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _diagnosticForScore(switch (status) {
      WaterDiagnosticStatus.safe => 0.18,
      WaterDiagnosticStatus.warning => 0.52,
      WaterDiagnosticStatus.danger => 0.86,
    });
  }

  WaterDiagnostic _diagnosticForScore(double score) {
    final status = switch (score) {
      < 0.35 => WaterDiagnosticStatus.safe,
      < 0.70 => WaterDiagnosticStatus.warning,
      _ => WaterDiagnosticStatus.danger,
    };

    // Paramètres physico-chimiques simulés cohérents avec le statut
    final (ph, chlorine) = switch (status) {
      WaterDiagnosticStatus.safe => (7.2, 0.8),
      WaterDiagnosticStatus.warning => (6.1, 2.4),
      WaterDiagnosticStatus.danger => (4.8, 5.5),
    };

    return WaterDiagnostic.fromModelScores(
      status: status,
      turbidityScore: score,
      confidence: 0.72,
      phValue: ph,
      chlorineLevel: chlorine,
    );
  }
}
