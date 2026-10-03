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
      status: 'Eau potable contrôlée',
      flowRate: '18 L/min',
      steps: [
        GuidedStep(
          stepNumber: 1,
          title: 'Identification du point d\'eau',
          description: 'Vérifiez le numéro d\'identification de la pompe et la propreté de la buse.',
          icon: Icons.qr_code_scanner,
          startTime: Duration.zero,
          duration: Duration(seconds: 4),
        ),
        GuidedStep(
          stepNumber: 2,
          title: 'Rinçage préalable',
          description: 'Pompez à vide pendant 10 secondes pour éliminer les résidus d\'eau stagnante.',
          icon: Icons.water_drop_outlined,
          startTime: Duration(seconds: 4),
          duration: Duration(seconds: 5),
        ),
        GuidedStep(
          stepNumber: 3,
          title: 'Remplissage du récipient',
          description: 'Placez votre récipient propre directement sous le bec verseur.',
          icon: Icons.local_drink,
          startTime: Duration(seconds: 9),
          duration: Duration(seconds: 5),
        ),
        GuidedStep(
          stepNumber: 4,
          title: 'Fermeture et sécurité',
          description: 'Fermez hermétiquement le récipient pour éviter la recontamination.',
          icon: Icons.verified_user_outlined,
          startTime: Duration(seconds: 14),
          duration: Duration(seconds: 4),
        ),
      ],
    ),
  };

  /// Récupère les données d'une pompe par son ID de QR code,
  /// ou génère un modèle dynamique par défaut si la pompe est inconnue.
  static PumpData getPumpFromQr(String qrValue) {
    final cleanValue = qrValue.trim().toUpperCase();
    if (_pumpDatabase.containsKey(cleanValue)) {
      return _pumpDatabase[cleanValue]!;
    }

    return PumpData(
      id: qrValue,
      name: 'Pompe reconnue ($qrValue)',
      location: 'Localisation enregistrée hors-ligne',
      audioAsset: 'audio/pump-guide.mp3',
      status: 'Point d\'eau identifié',
      flowRate: '15 L/min',
      steps: const [
        GuidedStep(
          stepNumber: 1,
          title: 'Vérification visuelle',
          description: 'Examinez la buse de la pompe et assurez-vous qu\'elle est propre.',
          icon: Icons.search,
          startTime: Duration.zero,
          duration: Duration(seconds: 4),
        ),
        GuidedStep(
          stepNumber: 2,
          title: 'Actionnement du levier',
          description: 'Pompez régulièrement avec une pression constante.',
          icon: Icons.build_circle_outlined,
          startTime: Duration(seconds: 4),
          duration: Duration(seconds: 5),
        ),
        GuidedStep(
          stepNumber: 3,
          title: 'Collecte sécurisée',
          description: 'Remplissez un récipient propre jusqu\'au niveau désiré.',
          icon: Icons.opacity,
          startTime: Duration(seconds: 9),
          duration: Duration(seconds: 5),
        ),
      ],
    );
  }
}
