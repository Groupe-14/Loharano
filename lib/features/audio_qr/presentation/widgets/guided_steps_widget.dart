import 'package:flutter/material.dart';

import '../../data/services/audio_engine_service.dart';
import '../../domain/entities/pump_data.dart';

/// Affichage synchrone des étapes de guidage visuel en correlation avec le moteur audio.
class GuidedStepsWidget extends StatelessWidget {
  const GuidedStepsWidget({
    super.key,
    required this.steps,
    required this.audioEngine,
  });

  final List<GuidedStep> steps;
  final AudioEngineService audioEngine;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getActiveIndex();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Instructions pas-à-pas :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Étape ${activeIndex + 1} / ${steps.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final step = steps[index];
            final isActive = index == activeIndex;

            return Semantics(
              selected: isActive,
              label: 'Étape ${step.stepNumber}: ${step.title}. ${step.description}',
              child: InkWell(
                onTap: () => audioEngine.seek(step.startTime),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        child: Icon(
                          step.icon,
                          size: 18,
                          color: isActive ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${step.stepNumber}. ${step.title}',
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                fontSize: 13,
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive ? Colors.black87 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive && audioEngine.isPlaying)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.volume_up,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _getActiveIndex() {
    if (steps.isEmpty) return 0;
    final currentPos = audioEngine.position;
    for (int i = 0; i < steps.length; i++) {
      if (steps[i].isActiveAt(currentPos)) return i;
    }
    if (currentPos >= steps.last.endTime) return steps.length - 1;
    return 0;
  }
}
