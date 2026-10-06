import 'package:flutter/material.dart';

import '../../data/services/audio_engine_service.dart';

/// Composant de contrôle de la lecture audio avec protection anti-overflow.
class AudioControlsWidget extends StatelessWidget {
  const AudioControlsWidget({
    super.key,
    required this.audioEngine,
  });

  final AudioEngineService audioEngine;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = audioEngine.isPlaying;
    final position = audioEngine.position;
    final duration = audioEngine.duration;
    final maxSeconds =
        duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
    final currentSeconds = position.inSeconds.toDouble().clamp(0.0, maxSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  _formatDuration(position),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: currentSeconds,
                    max: maxSeconds,
                    onChanged: (value) {
                      audioEngine.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  _formatDuration(duration),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Recommencer l\'audio depuis le début',
                button: true,
                child: IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  icon: const Icon(Icons.replay, size: 22),
                  tooltip: 'Recommencer',
                  onPressed: () => audioEngine.restart(),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Semantics(
                    label: isPlaying
                        ? 'Mettre en pause'
                        : 'Lancer l\'instruction audio',
                    button: true,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => audioEngine.togglePlayPause(),
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 20),
                      label: Text(
                        isPlaying ? 'Pause' : 'Écouter',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                label: 'Changer la vitesse de lecture audio',
                button: true,
                child: PopupMenuButton<double>(
                  tooltip: 'Vitesse de lecture',
                  padding: EdgeInsets.zero,
                  icon: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '${audioEngine.playbackRate}x',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  onSelected: (speed) => audioEngine.setPlaybackRate(speed),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 0.75, child: Text('0.75x (Lent)')),
                    PopupMenuItem(value: 1.0, child: Text('1.0x (Normal)')),
                    PopupMenuItem(value: 1.25, child: Text('1.25x (Rapide)')),
                  ],
                ),
              ),
            ],
          ),
          if (audioEngine.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              audioEngine.errorMessage!,
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.error),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
