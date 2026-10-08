import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/water_diagnostic.dart';

class TurbidityGaugeWidget extends StatelessWidget {
  const TurbidityGaugeWidget({super.key, required this.diagnostic});

  final WaterDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final color = switch (diagnostic.status) {
      WaterDiagnosticStatus.safe => AppColors.safe,
      WaterDiagnosticStatus.warning => AppColors.warning,
      WaterDiagnosticStatus.danger => AppColors.danger,
    };
    final score = (diagnostic.turbidityScore * 100).round();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Turbidité',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('$score %',
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
                value: diagnostic.turbidityScore, color: color, minHeight: 8),
            const SizedBox(height: 12),
            Text(diagnostic.status.label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ...diagnostic.recommendations.map(
              (recommendation) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $recommendation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
