import '../../domain/entities/water_diagnostic.dart';

/// Small on-device ML stand-in used until the production model is integrated.
class SimulatedAiService {
  const SimulatedAiService();

  Future<WaterDiagnostic> analyze({Object? imageData}) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));

    // A deterministic value keeps the demo predictable while still modelling
    // an asynchronous image-analysis operation.
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
      < 0.7 => WaterDiagnosticStatus.warning,
      _ => WaterDiagnosticStatus.danger,
    };

    return WaterDiagnostic(
      status: status,
      turbidityScore: score,
      colorHex: switch (status) {
        WaterDiagnosticStatus.safe => '#18864B',
        WaterDiagnosticStatus.warning => '#F0A202',
        WaterDiagnosticStatus.danger => '#D64545',
      },
      timestamp: DateTime.now(),
      recommendations: switch (status) {
        WaterDiagnosticStatus.safe => [
            'L’eau semble claire. Conservez-la dans un récipient propre.'
          ],
        WaterDiagnosticStatus.warning => [
            'Filtrez l’eau avant consommation.',
            'Contrôlez à nouveau après purification.'
          ],
        WaterDiagnosticStatus.danger => [
            'Ne buvez pas cette eau.',
            'Faites-la bouillir ou utilisez une méthode de purification adaptée.'
          ],
      },
    );
  }
}
