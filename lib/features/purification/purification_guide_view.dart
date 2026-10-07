import 'package:flutter/material.dart';

import '../../core/models/water_test_model.dart';
import '../audio_qr/data/services/speech_service.dart';
import '../audio_qr/presentation/widgets/diagnostic_qr_dialog.dart';
import 'widgets/step_item_card.dart';
import 'widgets/water_status_card.dart';

class PurificationGuideView extends StatefulWidget {
  final VoidCallback?
      onFinish; // Callback pour avertir le parent (ex: retour à l'onglet Analyse)
  final WaterTestModel? waterTest;
  const PurificationGuideView({
    super.key,
    this.onFinish,
    this.waterTest,
  });

  @override
  State<PurificationGuideView> createState() => _PurificationGuideViewState();
}

class _PurificationGuideViewState extends State<PurificationGuideView> {
  // Mock du résultat de l'IA (par défaut sur Eau Trouble pour tester)
  late WaterStatus _currentStatus;
  final _speech = SpeechService();

  // Bascule entre la carte de diagnostic et la liste des consignes
  bool _showSteps = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = _statusFor(widget.waterTest?.status);
  }

  WaterStatus _statusFor(WaterTestStatus? status) => switch (status) {
        WaterTestStatus.safe => WaterStatus.safe,
        WaterTestStatus.warning => WaterStatus.turbid,
        WaterTestStatus.danger => WaterStatus.contaminated,
        null => WaterStatus.safe,
      };

  // Données des consignes selon le diagnostic
  List<({String title, String subtitle, IconData icon})> _getStepsForStatus() {
    final ntu = widget.waterTest?.turbidityScore ?? 0;
    switch (_currentStatus) {
      case WaterStatus.contaminated:
        return [
          if (ntu >= 50)
            (
              title: '1. Décanter',
              subtitle: 'Laissez reposer l’eau trouble avant de la filtrer.',
              icon: Icons.hourglass_bottom
            ),
          (
            title: ntu >= 50 ? '2. Faire bouillir' : '1. Faire bouillir',
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
          (
            title: '4. Chloration',
            subtitle: 'Ajoutez le chlore selon le dosage local recommandé.',
            icon: Icons.science_outlined
          ),
        ];
      case WaterStatus.turbid:
        return [
          if (ntu >= 25)
            (
              title: '1. Décanter',
              subtitle: 'Laissez les particules se déposer.',
              icon: Icons.hourglass_bottom
            ),
          (
            title: ntu >= 25
                ? '2. Filtration sur tissu'
                : '1. Filtration sur tissu',
            subtitle: 'Coupez une bouteille en deux.',
            icon: Icons.water_drop_outlined
          ),
          (
            title: ntu >= 25 ? '3. Sable + gravier' : '2. Sable + gravier',
            subtitle: 'Sable fin, gravier, tissu propre.',
            icon: Icons.grid_view
          ),
          (
            title: ntu >= 25 ? '4. Filtrer' : '3. Filtrer',
            subtitle: 'Versez lentement, répétez 2 fois.',
            icon: Icons.check_circle_outline
          ),
        ];
      case WaterStatus.safe:
        return [
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

  String _stepsAsText(
    List<({String title, String subtitle, IconData icon})> steps,
  ) =>
      steps.map((step) => '${step.title}. ${step.subtitle}').join(' ');

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Guide de purification'),
        actions: [
          if (widget.waterTest != null)
            IconButton(
              tooltip: 'Partager par QR code',
              onPressed: () =>
                  showDiagnosticQrDialog(context, widget.waterTest!),
              icon: const Icon(Icons.qr_code_2),
            ),
          IconButton(
            tooltip: 'Lire les consignes',
            onPressed: () => _speech.speak(_stepsAsText(steps)),
            icon: const Icon(Icons.volume_up),
          ),
        ],
      ),
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
                        _speech.speak('${step.title}. ${step.subtitle}');
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
                      _showSteps =
                          false; // Retour à la carte de diagnostic, Réinitialise l'état interne
                    });
                    // Si le parent a fourni une action de redirection, on l'exécute !
                    if (widget.onFinish != null) {
                      widget.onFinish!();
                    }
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
