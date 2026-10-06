import 'package:flutter/material.dart';

import '../../data/services/audio_engine_service.dart';
import '../../domain/entities/pump_data.dart';

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
        Text(
          'Étape ${activeIndex + 1} sur ${steps.length}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5E675F)),
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
              label:
                  'Étape ${step.stepNumber}: ${step.title}. ${step.description}',
              child: InkWell(
                onTap: () => audioEngine.seek(step.startTime),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFD7EBE6)
                        : const Color(0xFFFFFCF7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF0F5C56)
                          : const Color(0xFFDDD4C4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        step.icon,
                        size: 20,
                        color: isActive
                            ? const Color(0xFF0F5C56)
                            : const Color(0xFF5E675F),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${step.stepNumber}. ${step.title}',
                              style: TextStyle(
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
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
                                color:
                                    isActive ? Colors.black87 : Colors.black54,
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
                            color: Color(0xFF0F5C56),
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
