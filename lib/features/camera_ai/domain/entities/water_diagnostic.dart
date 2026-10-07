import '../../../../core/models/water_test_model.dart';

/// Result of a visual water analysis.
class WaterDiagnostic {
  const WaterDiagnostic({
    required this.status,
    required this.turbidityScore,
    required this.colorHex,
    required this.timestamp,
    required this.recommendations,
  });

  final WaterDiagnosticStatus status;
  final double turbidityScore;
  final String colorHex;
  final DateTime timestamp;
  final List<String> recommendations;

  double get ntu => turbidityScore * 100;

  factory WaterDiagnostic.fromModelScores({
    required WaterDiagnosticStatus status,
    required double turbidityScore,
    required double confidence,
  }) {
    final confidencePercent = (confidence * 100).round();
    return WaterDiagnostic(
      status: status,
      turbidityScore: turbidityScore.clamp(0.0, 1.0),
      colorHex: switch (status) {
        WaterDiagnosticStatus.safe => '#18864B',
        WaterDiagnosticStatus.warning => '#F0A202',
        WaterDiagnosticStatus.danger => '#D64545',
      },
      timestamp: DateTime.now(),
      recommendations: switch (status) {
        WaterDiagnosticStatus.safe => [
            'L’eau semble claire. Conservez-la dans un récipient propre.',
            'Confiance de l’analyse : $confidencePercent %.'
          ],
        WaterDiagnosticStatus.warning => [
            'Filtrez l’eau avant consommation.',
            'Contrôlez à nouveau après purification.',
            'Confiance de l’analyse : $confidencePercent %.'
          ],
        WaterDiagnosticStatus.danger => [
            'Ne buvez pas cette eau.',
            'Faites-la bouillir ou utilisez une méthode de purification adaptée.',
            'Confiance de l’analyse : $confidencePercent %.'
          ],
      },
    );
  }

  /// Allows consumers such as the purification guide to use the shared model.
  WaterTestModel toWaterTestModel() => WaterTestModel(
        timestamp: timestamp,
        status: status.toWaterTestStatus(),
        turbidityScore: ntu,
      );
}

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
