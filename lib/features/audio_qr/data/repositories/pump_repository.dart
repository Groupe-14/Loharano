import 'package:flutter/material.dart';

import '../../domain/entities/pump_data.dart';

class PumpRepository {
  /// Base de données locale de pompes pour l'identification hors-ligne.
  static final Map<String, PumpData> _pumpDatabase = {
    'POMPE-001': const PumpData(
      id: 'POMPE-001',
      name: 'Pompe Manuelle Analamahitsy',
      location: 'Secteur Nord - Analamahitsy',
      audioAsset: 'audio/pump-guide.mp3',
      status: 'DÉMO — fiche d’exemple, pas une mesure',
      flowRate: 'non mesuré',
      steps: [
        GuidedStep(
          stepNumber: 1,
          title: 'Identification du point d\'eau',
          description:
              'Vérifiez le numéro d\'identification de la pompe et la propreté de la buse.',
          icon: Icons.qr_code_scanner,
          startTime: Duration.zero,
          duration: Duration(seconds: 4),
        ),
        GuidedStep(
          stepNumber: 2,
          title: 'Rinçage préalable',
          description:
              'Pompez à vide pendant 10 secondes pour éliminer les résidus d\'eau stagnante.',
          icon: Icons.water_drop_outlined,
          startTime: Duration(seconds: 4),
          duration: Duration(seconds: 5),
        ),
        GuidedStep(
          stepNumber: 3,
          title: 'Remplissage du récipient',
          description:
              'Placez votre récipient propre directement sous le bec verseur.',
          icon: Icons.local_drink,
          startTime: Duration(seconds: 9),
          duration: Duration(seconds: 5),
        ),
        GuidedStep(
          stepNumber: 4,
          title: 'Fermeture et sécurité',
          description:
              'Fermez hermétiquement le récipient pour éviter la recontamination.',
          icon: Icons.verified_user_outlined,
          startTime: Duration(seconds: 14),
          duration: Duration(seconds: 4),
        ),
      ],
    ),
  };

  static PumpData? findKnown(String qrValue) {
    final cleanValue =
        qrValue.trim().toUpperCase().replaceFirst('LOHARANO://WP/', '');
    return _pumpDatabase[cleanValue];
  }
}
