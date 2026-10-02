import 'package:flutter/material.dart';

enum WaterStatus {
  contaminated,
  turbid,
  safe,
}

class WaterStatusCard extends StatelessWidget {
  final WaterStatus status;
  final VoidCallback onSeeSolutions;

  const WaterStatusCard({
    super.key,
    required this.status,
    required this.onSeeSolutions,
  });

  @override
  Widget build(BuildContext context) {
    // Configuration selon l'état de l'eau
    final Color backgroundColor;
    final IconData icon;
    final String title;
    final String subtitle;

    switch (status) {
      case WaterStatus.contaminated:
        backgroundColor = const Color(0xFFD32F2F); // Rouge
        icon = Icons.warning_amber_rounded;
        title = 'Danger — Contaminée';
        subtitle = 'Ne buvez pas. Faites bouillir.';
        break;
      case WaterStatus.turbid:
        backgroundColor = const Color(0xFFE68A00); // Orange
        icon = Icons.warning_amber_rounded;
        title = 'Eau Trouble — Filtrer';
        subtitle = 'Filtrez avant de boire.';
        break;
      case WaterStatus.safe:
        backgroundColor = const Color(0xFF008744); // Vert
        icon = Icons.check_circle_outline;
        title = 'Eau Saine';
        subtitle = 'Vous pouvez boire cette eau.';
        break;
    }

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Icône centrale
          Icon(
            icon,
            size: 96,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          // Titre
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Sous-titre
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          // Bouton "Voir les solutions"
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC), // Bleu maquette
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: onSeeSolutions,
              child: const Text(
                'Voir les solutions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
