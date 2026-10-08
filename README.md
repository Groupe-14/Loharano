# Loharano 💧

**Loharano** (HydroCheck AI) est une application Flutter _offline-first_ conçue pour évaluer la qualité de l'eau en zones reculées et guider les utilisateurs à travers des étapes de purification adaptées.

L'application combine une analyse visuelle de la turbidité par Intelligence Artificielle (TFLite), un guide de purification pas à pas, de la synthèse vocale, et un système de partage de diagnostics par QR code léger (compressé en base64/GZip).

---

## 🚀 Fonctionnalités Principales

- 📷 **Analyse de la Turbidité par IA (`camera_ai`)**
  - Traitement d'image via modèle **TensorFlow Lite** (`model_unquant.tflite` issu de Google Teachable Machine).
  - Algorithme de secours (_fallback_) basé sur la chrominance et la saturation (espace colorimétrique RVB / HSV) en cas d'incompatibilité matérielle.
  - Jauge de turbidité en NTU et classification par niveau de risque (`Safe`, `Warning`, `Danger`).

- 🚰 **Guide de Purification Interactif (`purification`)**
  - Recommandations personnalisées selon le niveau de turbidité calculé (NTU).
  - Conseils structurés étape par étape : décantation, filtration sur tissu/sable/gravier, ébullition chrono (10 min) et chloration.
  - Synthèse vocale intégrée pour lire les consignes à voix haute (_Text-To-Speech_).

- 📡 **Partage QR Code & Audio (`audio_qr`)**
  - Génération de QR codes compacts contenant le diagnostic d'eau compressé (GZip + Base64Url).
  - Scanner de QR codes intégré pour transmettre le diagnostic d'un téléphone à un autre sans réseau Internet ou réseau cellulaire.

- 💾 **Historique Hors-Ligne (`local_db`)**
  - Sauvegarde locale SQLite de toutes les analyses d'eau réalisées.
  - Visualisation de l'historique et moteur de synchronisation.

---

## 🛠️ Stack Technique & Architecture

- **Framework :** Flutter (Dart 3.x, Material 3)
- **Architecture :** Clean Architecture orientée fonctionnalités (_Feature-First_)
- **IA / Inférence :** TensorFlow Lite, Google Teachable Machine
- **Réseau & Web :** Support Offline-first / PWA
- **Tests :** Flutter Test Framework (Tests de Widgets et d'intégration)

---

## 📁 Structure du Projet

```text
lib/
├── app.dart                  # Shell principal et navigation globale
├── main.dart                 # Point d'entrée de l'application
├── core/                     # Modèles, constantes et bases de données partagées
│   ├── constants/            # Couleurs et thèmes (AppColors)
│   ├── models/               # Modèles de données (WaterTestModel)
│   └── repositories/         # Base de données SQLite locale
└── features/                 # Modules fonctionnels de l'application
    ├── camera_ai/            # Prise de vue, analyse TFLite & fallback RVB/HSV
    ├── purification/         # Guide de purification pas à pas & cartes de statut
    ├── audio_qr/             # Scanner QR code, encodage GZip & synthèse vocale
    ├── local_db/             # Gestion de l'historique et export de données
    └── pwa_offline/          # Indicateur d'état du réseau hors-ligne
```

## ⚙️ Configuration & Installation

### Prérequis

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.19.0 ou supérieur)
- Java Development Kit (JDK 17)
- Android SDK (avec Kotlin 2.0.21)

### Installation

1. **Cloner le projet :**
   ```bash
   git clone [https://github.com/Groupe-14/Loharano.git](https://github.com/Groupe-14/Loharano.git)
   cd Loharano
   ```
2. **Cloner le projet :**
   ```bash
   flutter pub get
   ```
3. **Exécuter l'application :**

   ```bash
   # Sur un appareil ou émulateur Android
   flutter run
   ```

## 🚀 Fonctionnalités Principales

- 📷 **Analyse de la Turbidité par IA (`camera_ai`)**
  - Traitement d'image via modèle **TensorFlow Lite** (`model_unquant.tflite` issu de Google Teachable Machine).
  - Algorithme de secours (_fallback_) basé sur la chrominance et la saturation (espace colorimétrique RVB / HSV) en cas d'incompatibilité matérielle.
  - Jauge de turbidité en NTU et classification par niveau de risque (`Safe`, `Warning`, `Danger`).

- 🚰 **Guide de Purification Interactif (`purification`)**
  - Recommandations personnalisées selon le niveau de turbidité calculé (NTU).
  - Conseils structurés étape par étape : décantation, filtration sur tissu/sable/gravier, ébullition chrono (10 min) et chloration.
  - Synthèse vocale intégrée pour lire les consignes à voix haute (_Text-To-Speech_).

- 📡 **Partage QR Code & Audio (`audio_qr`)**
  - Génération de QR codes compacts contenant le diagnostic d'eau compressé (GZip + Base64Url).
  - Scanner de QR codes intégré pour transmettre le diagnostic d'un téléphone à un autre sans réseau Internet ou réseau cellulaire.

- 💾 **Historique Hors-Ligne (`local_db`)**
  - Sauvegarde locale SQLite de toutes les analyses d'eau réalisées.
  - Visualisation de l'historique et moteur de synchronisation.

---

## 🛠️ Stack Technique & Architecture

- **Framework :** Flutter (Dart 3.x, Material 3)
- **Architecture :** Clean Architecture orientée fonctionnalités (_Feature-First_)
- **IA / Inférence :** TensorFlow Lite, Google Teachable Machine
- **Réseau & Web :** Support Offline-first / PWA
- **Tests :** Flutter Test Framework (Tests de Widgets et d'intégration)

---

## 📁 Structure du Projet

```text

lib/
├── app.dart                  # Shell principal et navigation globale
├── main.dart                 # Point d'entrée de l'application
├── core/                     # Modèles, constantes et bases de données partagées
│   ├── constants/            # Couleurs et thèmes (AppColors)
│   ├── models/               # Modèles de données (WaterTestModel)
│   └── repositories/         # Base de données SQLite locale
└── features/                 # Modules fonctionnels de l'application
    ├── camera_ai/            # Prise de vue, analyse TFLite & fallback RVB/HSV
    ├── purification/         # Guide de purification pas à pas & cartes de statut
    ├── audio_qr/             # Scanner QR code, encodage GZip & synthèse vocale
    ├── local_db/             # Gestion de l'historique et export de données
    └── pwa_offline/          # Indicateur d'état du réseau hors-ligne
```

## 🧪 Tests & Analyse de Code

Pour s'assurer que le code respecte les normes et que les widgets fonctionnent correctement :

```bash
# Analyse statique du code Dart
flutter analyze

# Lancement des tests unitaires et de widgets
flutter test
```

## 👥 Équipe de Développement (Groupe 14)

Projet réalisé dans le cadre du développement de la solution Loharano / HydroCheck AI.
