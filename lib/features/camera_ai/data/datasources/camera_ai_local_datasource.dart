import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../../domain/entities/water_diagnostic.dart';
import '../../domain/repositories/i_camera_ai_repository.dart';

/// Source de données locale : analyse d'image offline par extraction
/// de dominante chromatique RVB/HSV sur plusieurs régions d'intérêt (ROI).
///
/// Algorithme en 5 étapes :
/// 1. Décodage et redimensionnement de l'image.
/// 2. Vérification de luminosité et de netteté (Laplacien).
/// 3. Extraction des moyennes RVB sur 3 ROI (centre, quart-sup, quart-inf).
/// 4. Conversion en HSV pour extraire teinte, saturation, valeur.
/// 5. Calcul des paramètres physico-chimiques (turbidité, pH, chlore).
class CameraAiLocalDataSource {
  const CameraAiLocalDataSource();

  // ─── Constantes d'analyse ───────────────────────────────────────────────

  /// Largeur cible de l'image redimensionnée pour l'analyse.
  static const int _targetWidth = 224;
  static const int _targetHeight = 224;

  /// Luminosité minimale acceptable (valeur V en HSV, 0–255).
  static const double _minBrightness = 40.0;

  /// Variance du Laplacien minimale pour détecter une image nette.
  static const double _minSharpness = 15.0;

  // ────────────────────────────────────────────────────────────────────────

  /// Analyse l'image à [imagePath] et retourne un [WaterDiagnostic].
  ///
  /// Lance [AnalysisException] si :
  /// - le fichier est illisible ou corrompu,
  /// - la luminosité est insuffisante,
  /// - l'image est trop floue.
  Future<WaterDiagnostic> analyze(String imagePath) async {
    // 1. Lecture + décodage ------------------------------------------------
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const AnalysisException(
          'Impossible de décoder l\'image. Vérifiez le format du fichier.');
    }

    // 2. Redimensionnement uniforme ----------------------------------------
    final resized = img.copyResize(
      decoded,
      width: _targetWidth,
      height: _targetHeight,
      interpolation: img.Interpolation.linear,
    );

    // 3. Vérification de qualité -------------------------------------------
    _checkImageQuality(resized);

    // 4. Extraction des régions d'intérêt (ROI) ----------------------------
    final centerRoi = _extractRoi(resized, 0.25, 0.25, 0.75, 0.75);
    final topRoi = _extractRoi(resized, 0.15, 0.05, 0.85, 0.45);
    final bottomRoi = _extractRoi(resized, 0.15, 0.55, 0.85, 0.95);

    // 5. Moyennes RVB pondérées (centre=60%, haut=20%, bas=20%) ------------
    final avgR =
        (centerRoi.r * 0.6 + topRoi.r * 0.2 + bottomRoi.r * 0.2).clamp(0, 255);
    final avgG =
        (centerRoi.g * 0.6 + topRoi.g * 0.2 + bottomRoi.g * 0.2).clamp(0, 255);
    final avgB =
        (centerRoi.b * 0.6 + topRoi.b * 0.2 + bottomRoi.b * 0.2).clamp(0, 255);

    // 6. Conversion RVB → HSV ----------------------------------------------
    final hsv = _rgbToHsv(avgR.toDouble(), avgG.toDouble(), avgB.toDouble());
    final hue = hsv[0]; // 0–360°
    final saturation = hsv[1]; // 0–1
    final value = hsv[2]; // 0–1 (luminosité)

    // 7. Calcul des paramètres physico-chimiques ---------------------------
    final turbidityScore = _estimateTurbidity(value, saturation, avgR.toDouble(), avgG.toDouble(), avgB.toDouble());
    final phValue = _estimatePh(hue, saturation, value);
    final chlorineLevel = _estimateChlorine(hue, saturation, value);
    final confidence = _computeConfidence(saturation, value);

    // 8. Classification finale --------------------------------------------
    final status = _classify(turbidityScore, phValue, chlorineLevel);

    return WaterDiagnostic.fromModelScores(
      status: status,
      turbidityScore: turbidityScore,
      confidence: confidence,
      phValue: phValue,
      chlorineLevel: chlorineLevel,
    );
  }

  // ─── Contrôle qualité ────────────────────────────────────────────────────

  void _checkImageQuality(img.Image image) {
    final brightness = _computeBrightness(image);
    if (brightness < _minBrightness) {
      throw const AnalysisException(
          'Image trop sombre. Approchez-vous d\'une source lumineuse.');
    }

    final sharpness = _computeSharpness(image);
    if (sharpness < _minSharpness) {
      throw const AnalysisException(
          'Image floue. Stabilisez l\'appareil et réessayez.');
    }
  }

  /// Calcule la luminosité moyenne (canal V de HSV) sur un échantillon
  /// de l'image pour détecter les prises en conditions de faible éclairage.
  double _computeBrightness(img.Image image) {
    double total = 0;
    int count = 0;
    const step = 8; // sous-échantillonnage pour la performance
    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final hsv = _rgbToHsv(
            pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble());
        total += hsv[2] * 255; // valeur V en [0, 255]
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  /// Calcule la variance du Laplacien pour estimer la netteté de l'image.
  /// Une valeur élevée = image nette ; valeur basse = image floue.
  double _computeSharpness(img.Image image) {
    // Noyau Laplacien 3x3
    const kernel = [0, 1, 0, 1, -4, 1, 0, 1, 0];
    double sum = 0;
    double sumSq = 0;
    int count = 0;
    const step = 4;

    for (var y = 1; y < image.height - 1; y += step) {
      for (var x = 1; x < image.width - 1; x += step) {
        double conv = 0;
        for (var ky = -1; ky <= 1; ky++) {
          for (var kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            final grey =
                (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114);
            conv += grey * kernel[(ky + 1) * 3 + (kx + 1)];
          }
        }
        sum += conv;
        sumSq += conv * conv;
        count++;
      }
    }
    if (count == 0) return 0;
    final mean = sum / count;
    return (sumSq / count) - (mean * mean); // variance
  }

  // ─── Extraction ROI ──────────────────────────────────────────────────────

  /// Extrait les moyennes RVB d'une région d'intérêt définie
  /// en proportions de l'image [0.0 – 1.0].
  _RgbAverage _extractRoi(
    img.Image image,
    double x0Frac,
    double y0Frac,
    double x1Frac,
    double y1Frac,
  ) {
    final x0 = (x0Frac * image.width).round().clamp(0, image.width - 1);
    final y0 = (y0Frac * image.height).round().clamp(0, image.height - 1);
    final x1 = (x1Frac * image.width).round().clamp(0, image.width);
    final y1 = (y1Frac * image.height).round().clamp(0, image.height);

    double sumR = 0, sumG = 0, sumB = 0;
    int count = 0;
    const step = 2; // sous-échantillonnage

    for (var y = y0; y < y1; y += step) {
      for (var x = x0; x < x1; x += step) {
        final pixel = image.getPixel(x, y);
        sumR += pixel.r.toDouble();
        sumG += pixel.g.toDouble();
        sumB += pixel.b.toDouble();
        count++;
      }
    }

    if (count == 0) return const _RgbAverage(0, 0, 0);
    return _RgbAverage(sumR / count, sumG / count, sumB / count);
  }

  // ─── Conversion RVB → HSV ─────────────────────────────────────────────

  /// Retourne [H (0–360), S (0–1), V (0–1)].
  List<double> _rgbToHsv(double r, double g, double b) {
    final rNorm = r / 255.0;
    final gNorm = g / 255.0;
    final bNorm = b / 255.0;

    final max = math.max(rNorm, math.max(gNorm, bNorm));
    final min = math.min(rNorm, math.min(gNorm, bNorm));
    final delta = max - min;

    double hue = 0;
    if (delta > 0) {
      if (max == rNorm) {
        hue = 60 * (((gNorm - bNorm) / delta) % 6);
      } else if (max == gNorm) {
        hue = 60 * ((bNorm - rNorm) / delta + 2);
      } else {
        hue = 60 * ((rNorm - gNorm) / delta + 4);
      }
    }
    if (hue < 0) hue += 360;

    final saturation = max == 0 ? 0.0 : delta / max;
    final value = max;

    return [hue, saturation, value];
  }

  // ─── Estimation paramètres physico-chimiques ─────────────────────────────

  /// Estime la turbidité [0.0 – 1.0] à partir des canaux de couleur.
  ///
  /// L'eau trouble absorbe la lumière bleue et verte : si les canaux
  /// R et G dominent avec une faible luminosité, la turbidité est haute.
  double _estimateTurbidity(
    double value, // HSV V
    double saturation, // HSV S
    double r,
    double g,
    double b,
  ) {
    // Opacité : une faible composante B relative indique des particules en suspension.
    final total = r + g + b;
    final blueRatio = total > 0 ? b / total : 0.33;

    // Faible luminosité + faible ratio bleu = eau trouble
    final turbidityFromColor = (1 - blueRatio) * (1 - value);

    // Saturation élevée sur des teintes brunes/jaunes = particules organiques
    final brownBias = saturation * (1 - blueRatio);

    return ((turbidityFromColor * 0.6 + brownBias * 0.4) * 1.8).clamp(0.0, 1.0);
  }

  /// Estime le pH à partir de la teinte chromatique.
  ///
  /// Heuristique basée sur les indicateurs colorés des bandelettes test :
  /// - Hue ≈ 0–30° (rouge/orange)  → pH ≤ 4 (acide)
  /// - Hue ≈ 30–60° (jaune)        → pH 5–6
  /// - Hue ≈ 60–150° (jaune-vert)  → pH 6.5–7.5 (neutre/optimal)
  /// - Hue ≈ 150–240° (vert-bleu)  → pH 7.5–9
  /// - Hue ≈ 240–300° (bleu-violet)→ pH ≥ 9 (basique)
  double _estimatePh(double hue, double saturation, double value) {
    double ph;
    if (hue < 30) {
      // rouge → très acide
      ph = 3.0 + (hue / 30) * 2.0;
    } else if (hue < 60) {
      // orange/jaune → légèrement acide
      ph = 5.0 + ((hue - 30) / 30) * 1.5;
    } else if (hue < 150) {
      // jaune-vert → neutre (zone optimale)
      ph = 6.5 + ((hue - 60) / 90) * 1.5;
    } else if (hue < 240) {
      // vert-bleu → légèrement basique
      ph = 8.0 + ((hue - 150) / 90) * 1.5;
    } else {
      // bleu-violet → basique/trop basique
      ph = 9.5 + ((hue - 240) / 120) * 1.5;
    }

    // Correction par saturation : faible saturation = eau claire → pH neutre
    if (saturation < 0.15) {
      ph = ph * 0.3 + 7.0 * 0.7;
    }

    return ph.clamp(0.0, 14.0);
  }

  /// Estime le taux de chlore/contaminants (mg/L) à partir du canal bleu.
  ///
  /// L'eau chlorée tend vers des teintes bleu-vert translucides :
  /// - Forte composante bleue + faible saturation → chlore présent mais normal
  /// - Teinte jaunâtre ou brun = contamination organique
  double _estimateChlorine(double hue, double saturation, double value) {
    // Plage de chlore résiduel acceptée : 0.2–2.0 mg/L
    double chlorine;

    if (hue >= 180 && hue <= 240 && saturation < 0.4) {
      // Bleu translucide → chlore résiduel normal (0.5–1.5 mg/L)
      chlorine = 0.5 + saturation * 2.5;
    } else if (hue >= 30 && hue < 80 && saturation > 0.3) {
      // Jaune/brun → contamination organique élevée
      chlorine = 0.0;
    } else if (value < 0.3) {
      // Eau très sombre → possible contamination forte
      chlorine = 3.0 + (1 - value) * 4.0;
    } else {
      // Cas intermédiaire
      chlorine = saturation * 1.5;
    }

    return chlorine.clamp(0.0, 10.0);
  }

  /// Score de confiance basé sur la qualité colorimétrique du signal.
  ///
  /// Une forte saturation avec une bonne luminosité donne un signal
  /// chromatique fiable, donc une confiance élevée.
  double _computeConfidence(double saturation, double value) {
    // Confiance de base : 0.60 + bonus saturati + bonus luminosité
    final confidence = 0.60 + saturation * 0.20 + value * 0.20;
    return confidence.clamp(0.50, 0.97);
  }

  // ─── Classification finale ───────────────────────────────────────────────

  WaterDiagnosticStatus _classify(
      double turbidityScore, double ph, double chlorine) {
    // Critères de dangerosité (un seul suffit)
    final isDangerous = turbidityScore > 0.65 ||
        ph < 5.5 ||
        ph > 9.5 ||
        chlorine > 4.0;

    // Critères d'alerte
    final isWarning = turbidityScore > 0.30 ||
        ph < 6.5 ||
        ph > 8.5 ||
        chlorine > 2.0 ||
        chlorine < 0.1;

    if (isDangerous) return WaterDiagnosticStatus.danger;
    if (isWarning) return WaterDiagnosticStatus.warning;
    return WaterDiagnosticStatus.safe;
  }
}

// ─── Classe utilitaire interne ────────────────────────────────────────────

class _RgbAverage {
  const _RgbAverage(this.r, this.g, this.b);
  final double r;
  final double g;
  final double b;
}
