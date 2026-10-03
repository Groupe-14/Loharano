import 'package:flutter/material.dart';

/// Modèle représentant une étape de guidage synchronisée avec l'audio.
class GuidedStep {
  const GuidedStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.startTime,
    required this.duration,
  });

  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final Duration startTime;
  final Duration duration;

  Duration get endTime => startTime + duration;

  bool isActiveAt(Duration currentPosition) {
    return currentPosition >= startTime && currentPosition < endTime;
  }
}

/// Modèle représentant un point d'eau / pompe identifié par QR Code.
class PumpData {
  const PumpData({
    required this.id,
    required this.name,
    required this.location,
    required this.audioAsset,
    required this.steps,
    this.status = 'Fonctionnelle',
    this.flowRate = '15 L/min',
  });

  final String id;
  final String name;
  final String location;
  final String audioAsset;
  final List<GuidedStep> steps;
  final String status;
  final String flowRate;

  /// Retourne l'index de l'étape active selon la position audio actuelle.
  int getActiveStepIndex(Duration currentPosition) {
    for (int i = 0; i < steps.length; i++) {
      if (steps[i].isActiveAt(currentPosition)) {
        return i;
      }
    }
    if (steps.isNotEmpty && currentPosition >= steps.last.endTime) {
      return steps.length - 1;
    }
    return 0;
  }
}
