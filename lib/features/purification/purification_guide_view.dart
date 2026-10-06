import 'package:flutter/material.dart';

import '../../core/models/risk_level.dart';
import '../../core/risk/risk_result.dart';
import 'guide_content.dart';
import 'widgets/step_item_card.dart';
import 'widgets/water_status_card.dart';

class PurificationGuideView extends StatefulWidget {
  const PurificationGuideView(
      {super.key, this.result, this.onSpeak, this.onFinish});

  final RiskResult? result;
  final Future<void> Function(String text)? onSpeak;
  final VoidCallback? onFinish;

  @override
  State<PurificationGuideView> createState() => _PurificationGuideViewState();
}

class _PurificationGuideViewState extends State<PurificationGuideView> {
  bool _showSteps = false;

  @override
  void didUpdateWidget(PurificationGuideView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result?.level != widget.result?.level) _showSteps = false;
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.result?.level ?? RiskLevel.unknown;
    if (!_showSteps) {
      return WaterStatusCard(
        level: level,
        onSeeSteps: () => setState(() => _showSteps = true),
        onSpeak: () => widget.onSpeak?.call(
            '${level.label}. ${widget.result?.reasons.join(' ') ?? 'Faites un dépistage dans l’onglet Tester.'}'),
      );
    }

    final steps = stepsFor(widget.result);
    return ColoredBox(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(level.label,
                style: const TextStyle(color: Colors.black54, fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return StepItemCard(
                    icon: step.icon,
                    title: step.title,
                    subtitle: step.subtitle,
                    onAudioPressed: () => widget.onSpeak?.call(step.speech),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () {
                  setState(() => _showSteps = false);
                  widget.onFinish?.call();
                },
                child: const Text('Terminer',
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
