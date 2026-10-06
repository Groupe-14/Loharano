import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/risk_level.dart';

class WaterStatusCard extends StatelessWidget {
  const WaterStatusCard(
      {super.key, required this.level, required this.onSeeSteps, this.onSpeak});

  final RiskLevel level;
  final VoidCallback onSeeSteps;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    final background = switch (level) {
      RiskLevel.low => AppColors.low,
      RiskLevel.medium => AppColors.medium,
      RiskLevel.high => AppColors.high,
      RiskLevel.unknown => AppColors.unknown,
    };
    final icon = switch (level) {
      RiskLevel.low => Icons.info_outline,
      RiskLevel.medium => Icons.warning_amber_rounded,
      RiskLevel.high => Icons.report_outlined,
      RiskLevel.unknown => Icons.help_outline,
    };
    final subtitle = switch (level) {
      RiskLevel.low =>
        'Ce n’est pas une garantie. En cas de doute, faites bouillir.',
      RiskLevel.medium => 'Traitez l’eau avant de la boire.',
      RiskLevel.high => 'Ne buvez pas cette eau sans traitement.',
      RiskLevel.unknown => 'Le dépistage ne permet pas de conclure.',
    };

    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(icon, size: 96, color: Colors.white),
            const SizedBox(height: 24),
            Text(level.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 16),
            IconButton(
              style: IconButton.styleFrom(backgroundColor: Colors.white24),
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 28),
              tooltip: 'Écouter le résultat',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue),
                onPressed: onSeeSteps,
                child: const Text('Voir les actions',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
