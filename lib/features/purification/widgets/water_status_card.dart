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
    final text = Theme.of(context).textTheme;
    final tone = AppColors.forRisk(level);
    final subtitle = switch (level) {
      RiskLevel.low =>
        'Ce n’est pas une garantie. En cas de doute, faites bouillir.',
      RiskLevel.medium => 'Traitez l’eau avant de la boire.',
      RiskLevel.high => 'Ne buvez pas cette eau sans traitement.',
      RiskLevel.unknown => 'Le dépistage ne permet pas de conclure.',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(level.label, style: text.headlineSmall),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(level),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppColors.iconFor(level), color: tone),
                  const SizedBox(width: 12),
                  Expanded(child: Text(subtitle, style: text.bodyLarge)),
                ],
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onSpeak,
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Écouter'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSeeSteps,
              child: const Text('Voir les actions'),
            ),
          ),
        ],
      ),
    );
  }
}
