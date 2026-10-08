# Changelog

Toutes les modifications notables apportées à ce projet sont documentées dans ce fichier.

## [Unreleased] - 2026-10-08

### Added

- **Module Purification (`feat/purification`) :**
  - Interface interactive `PurificationGuideView` fournissant des consignes pas à pas (décantation, ébullition, chloration, filtration) adaptées au niveau de turbidité.
  - Intégration des cartes de statut `WaterStatusCard` et `StepItemCard`.
- **Module Camera AI (`feat/camera-ai`) :**
  - Moteur d'analyse hybride à 3 niveaux : Modèle TFLite Teachable Machine (`model_unquant.tflite`), fallback offline chromatique RVB/HSV et mode simulation.
  - Mise à jour des configurations de build Android (Kotlin 2.0.21, JDK 17).
- **Module Audio & QR (`feat/audio-qr-rebased`) :**
  - Scanner QR code et extraction/synthèse audio des diagnostics.
  - Service de partage d'urgence encodé en base64/GZip (`DiagnosticShareService`).

### Fixed

- Correction des tests unitaires et d'intégration UI pour `PurificationGuideView` et `App`.
- Correction des avertissements de null-safety (`unnecessary_null_comparison`) dans le service de partage de diagnostic.
