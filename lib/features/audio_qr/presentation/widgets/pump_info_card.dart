import 'package:flutter/material.dart';

import '../../data/services/audio_engine_service.dart';
import '../../domain/entities/pump_data.dart';
import 'audio_controls_widget.dart';
import 'guided_steps_widget.dart';

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_drop_outlined, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.pump.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${widget.pump.id} · ${widget.pump.status}',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF5E675F)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up),
                          tooltip: _isExpanded ? 'Réduire' : 'Déplier',
                          onPressed: () =>
                              setState(() => _isExpanded = !_isExpanded),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
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
