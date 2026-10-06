import 'package:flutter/material.dart';

import '../../data/services/audio_engine_service.dart';
import '../../domain/entities/pump_data.dart';
import 'audio_controls_widget.dart';
import 'guided_steps_widget.dart';

/// Card affichant la pompe identifiée, le moteur audio et le guidage pas-à-pas synchrone.
class PumpInfoCard extends StatefulWidget {
  const PumpInfoCard({
    super.key,
    required this.pump,
    required this.audioEngine,
    required this.onReset,
  });

  final PumpData pump;
  final AudioEngineService audioEngine;
  final VoidCallback onReset;

  @override
  State<PumpInfoCard> createState() => _PumpInfoCardState();
}

class _PumpInfoCardState extends State<PumpInfoCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8),
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.60,
          ),
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.water_drop,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pompe reconnue: ${widget.pump.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${widget.pump.name} • ${widget.pump.status}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: Icon(_isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up),
                          tooltip: _isExpanded ? 'Réduire' : 'Déplier',
                          onPressed: () =>
                              setState(() => _isExpanded = !_isExpanded),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: const Icon(Icons.close, color: Colors.grey),
                          tooltip: 'Scanner à nouveau',
                          onPressed: widget.onReset,
                        ),
                      ],
                    ),
                    if (_isExpanded) ...[
                      const Divider(height: 12),
                      AudioControlsWidget(audioEngine: widget.audioEngine),
                      const SizedBox(height: 8),
                      GuidedStepsWidget(
                        steps: widget.pump.steps,
                        audioEngine: widget.audioEngine,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
