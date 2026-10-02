import 'package:flutter/material.dart';
import 'widgets/step_item_card.dart';
import 'widgets/water_status_card.dart';

class PurificationGuideView extends StatefulWidget {
  const PurificationGuideView({super.key});

  @override
  State<PurificationGuideView> createState() => _PurificationGuideViewState();
}

class _PurificationGuideViewState extends State<PurificationGuideView> {
  // Mock du résultat de l'IA (par défaut sur Eau Trouble pour tester)
  WaterStatus _currentStatus = WaterStatus.turbid;

  // Bascule entre la carte de diagnostic et la liste des consignes
  bool _showSteps = false;

  // Données des consignes selon le diagnostic
  List<({String title, String subtitle, IconData icon})> _getStepsForStatus() {
    switch (_currentStatus) {
      case WaterStatus.contaminated:
        return const [
          (
            title: '1. Faire bouillir',
            subtitle: 'Feu vif jusqu’à gros bouillons.',
            icon: Icons.whatshot
          ),
          (
            title: '2. 10 minutes',
            subtitle: 'Comptez 10 minutes complètes.',
            icon: Icons.timer
          ),
          (
            title: '3. Refroidir',
            subtitle: 'Couvrez et laissez refroidir.',
            icon: Icons.ac_unit
          ),
        ];
      case WaterStatus.turbid:
        return const [
          (
            title: '1. Bouteille',
            subtitle: 'Coupez une bouteille en deux.',
            icon: Icons.water_drop_outlined
          ),
          (
            title: '2. Sable + gravier',
            subtitle: 'Sable fin, gravier, tissu propre.',
            icon: Icons.grid_view
          ),
          (
            title: '3. Filtrer',
            subtitle: 'Versez lentement, répétez 2 fois.',
            icon: Icons.check_circle_outline
          ),
        ];
      case WaterStatus.safe:
        return const [
          (
            title: '1. Couvrir',
            subtitle: 'Gardez le bidon fermé.',
            icon: Icons.water_drop
          ),
          (
            title: '2. Garder au frais',
            subtitle: 'À l’ombre, loin du soleil.',
            icon: Icons.ac_unit
          ),
          (
            title: '3. Boire',
            subtitle: 'Consommez dans 24 heures.',
            icon: Icons.check_circle_outline
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Affichage de la carte de statut colorée (Rouge, Orange ou Vert)
    if (!_showSteps) {
      return WaterStatusCard(
        status: _currentStatus,
        onSeeSolutions: () {
          setState(() {
            _showSteps = true;
          });
        },
      );
    }

    // 2. Affichage de la liste des consignes étape par étape
    final steps = _getStepsForStatus();

    return Scaffold(
      backgroundColor:
          const Color(0xFFE8F5E9), // Fond bleu/vert très clair de la maquette
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Étapes à suivre',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentStatus == WaterStatus.contaminated
                    ? 'Danger — Contaminée'
                    : _currentStatus == WaterStatus.turbid
                        ? 'Eau Trouble — Filtrer'
                        : 'Eau Saine',
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
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
                      onAudioPressed: () {
                        // Transmis à Lionnel ultérieurement pour la synthèse vocale
                      },
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _showSteps = false; // Retour à la carte de diagnostic
                    });
                  },
                  child: const Text(
                    'Terminer / Nouvel essai',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
