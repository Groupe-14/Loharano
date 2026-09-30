import 'dart:async';

import 'package:flutter/material.dart';

class PurificationGuideView extends StatefulWidget {
  const PurificationGuideView({super.key});

  @override
  State<PurificationGuideView> createState() => _PurificationGuideViewState();
}

class _PurificationGuideViewState extends State<PurificationGuideView> {
  final _volumes = const ['1 L', '5 L', '20 L'];
  int _volumeIndex = 0;
  int _seconds = 60;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) timer.cancel();
      if (mounted) setState(() => _seconds = _seconds <= 1 ? 0 : _seconds - 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<int>(
              segments: [for (var i = 0; i < _volumes.length; i++) ButtonSegment(value: i, label: Text(_volumes[i]))],
              selected: {_volumeIndex},
              onSelectionChanged: (value) => setState(() => _volumeIndex = value.first),
            ),
            const SizedBox(height: 16),
            for (final step in const [
              ('Faire bouillir', Icons.local_fire_department, 'Porter l’eau à ébullition.'),
              ('Filtrer au sable', Icons.filter_alt, 'Filtrer lentement avec un sable propre.'),
              ('Chlorer', Icons.science, 'Respecter le dosage recommandé.'),
            ])
              Card(child: ListTile(leading: Icon(step.$2), title: Text(step.$1), subtitle: Text(step.$3))),
            Card(child: ListTile(title: const Text('Temps restant'), trailing: Text('$_seconds s', style: Theme.of(context).textTheme.headlineSmall), onTap: _startTimer)),
            FilledButton.icon(onPressed: _startTimer, icon: const Icon(Icons.timer), label: const Text('Démarrer le compte à rebours')),
          ],
        ),
      );
}
