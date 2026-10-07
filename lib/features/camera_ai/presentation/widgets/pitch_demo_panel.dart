import 'package:flutter/material.dart';

import '../../domain/entities/water_diagnostic.dart';

/// Deliberately opened by a long press so the pitch controls stay unobtrusive.
class PitchDemoPanel extends StatelessWidget {
  const PitchDemoPanel({super.key, required this.onStatusSelected});

  final ValueChanged<WaterDiagnosticStatus> onStatusSelected;

  static Future<void> show(BuildContext context,
      {required ValueChanged<WaterDiagnosticStatus> onStatusSelected}) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => PitchDemoPanel(onStatusSelected: onStatusSelected),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mode démonstration',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Forcer instantanément un résultat pour le pitch.'),
              const SizedBox(height: 12),
              ...WaterDiagnosticStatus.values.map(
                (status) => ListTile(
                  leading: Icon(Icons.circle, color: _colorFor(status)),
                  title: Text(status.label),
                  onTap: () {
                    Navigator.pop(context);
                    onStatusSelected(status);
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Color _colorFor(WaterDiagnosticStatus status) => switch (status) {
        WaterDiagnosticStatus.safe => Colors.green,
        WaterDiagnosticStatus.warning => Colors.orange,
        WaterDiagnosticStatus.danger => Colors.red,
      };
}
