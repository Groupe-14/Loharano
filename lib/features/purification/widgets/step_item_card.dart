import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class StepItemCard extends StatelessWidget {
  const StepItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAudioPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAudioPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, color: AppColors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: text.bodySmall),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Écouter',
                onPressed: onAudioPressed,
                icon: const Icon(Icons.volume_up_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
