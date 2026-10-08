import '../../../../core/models/water_test_model.dart';

/// Résultat d'une analyse visuelle d'eau.
///
/// Contient les paramètres physico-chimiques extraits par l'algorithme
/// RVB/HSV offline ainsi que les recommandations de purification.
class WaterDiagnostic {
  const WaterDiagnostic({
    required this.status,
    required this.turbidityScore,
    required this.colorHex,
    required this.timestamp,
    required this.recommendations,
    this.phValue,
    this.chlorineLevel,
    this.confidence = 0.85,
  });

  final WaterDiagnosticStatus status;

  /// Score de turbidité normalisé [0.0 – 1.0].
  final double turbidityScore;

  /// Couleur hexadécimale représentative de l'état de l'eau.
  final String colorHex;

  final DateTime timestamp;

  /// Recommandations de purification adaptées au diagnostic.
  final List<String> recommendations;

  /// Valeur de pH estimée (idéal : 6.5 – 8.5).
  final double? phValue;

  /// Concentration en chlore / contaminants (mg/L).
  final double? chlorineLevel;

  /// Score de confiance de l'analyse [0.0 – 1.0].
  final double confidence;

  /// Turbidité en NTU (unité normalisée).
  double get ntu => turbidityScore * 100;

  /// Résumé court du statut pour l'UI.
  String get statusLabel => status.label;

  /// Construit un [WaterDiagnostic] à partir des scores normalisés
  /// produits par l'algorithme chromatique ou TFLite.
  factory WaterDiagnostic.fromModelScores({
    required WaterDiagnosticStatus status,
    required double turbidityScore,
    required double confidence,
    double? phValue,
    double? chlorineLevel,
  }) {
    final confidencePercent = (confidence * 100).round();
    return WaterDiagnostic(
      status: status,
      turbidityScore: turbidityScore.clamp(0.0, 1.0),
      phValue: phValue,
      chlorineLevel: chlorineLevel,
      confidence: confidence.clamp(0.0, 1.0),
      colorHex: switch (status) {
        WaterDiagnosticStatus.safe => '#18864B',
        WaterDiagnosticStatus.warning => '#F0A202',
        WaterDiagnosticStatus.danger => '#D64545',
      },
      timestamp: DateTime.now(),
      recommendations: switch (status) {
        WaterDiagnosticStatus.safe => [
            'L\'eau semble claire et potable.',
            'Conservez-la dans un récipient propre et fermé.',
            'Confiance de l\'analyse : $confidencePercent %.',
          ],
        WaterDiagnosticStatus.warning => [
            'Filtrez l\'eau avant consommation.',
            'Contrôlez à nouveau après purification.',
            'Confiance de l\'analyse : $confidencePercent %.',
          ],
        WaterDiagnosticStatus.danger => [
            'Ne buvez PAS cette eau.',
            'Faites-la bouillir ou utilisez une méthode de purification adaptée.',
            'Confiance de l\'analyse : $confidencePercent %.',
          ],
      },
    );
  }

  /// Convertit en [WaterTestModel] pour la persistance SQLite.
  WaterTestModel toWaterTestModel({String? imagePath}) => WaterTestModel(
        timestamp: timestamp,
        status: status.toWaterTestStatus(),
        turbidityScore: ntu,
        imagePath: imagePath,
      );
}

// ──────────────────────────────────────────────────
// Enum & extensions
// ──────────────────────────────────────────────────

enum WaterDiagnosticStatus { safe, warning, danger }

extension WaterDiagnosticStatusX on WaterDiagnosticStatus {
  String get label => switch (this) {
        WaterDiagnosticStatus.safe => 'Sûre',
        WaterDiagnosticStatus.warning => 'Attention',
        WaterDiagnosticStatus.danger => 'Danger',
      };

  WaterTestStatus toWaterTestStatus() => switch (this) {
        WaterDiagnosticStatus.safe => WaterTestStatus.safe,
        WaterDiagnosticStatus.warning => WaterTestStatus.warning,
        WaterDiagnosticStatus.danger => WaterTestStatus.danger,
      };
}
