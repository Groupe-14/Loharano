import 'package:flutter/foundation.dart';

import '../../data/repositories/camera_ai_repository_impl.dart';
import '../../data/services/simulated_ai_service.dart';
import '../../data/services/tflite_ai_service.dart';
import '../../domain/entities/water_diagnostic.dart';
import '../../domain/repositories/i_camera_ai_repository.dart';
import '../../domain/usecases/analyze_water_image_use_case.dart';

/// Enum représentant l'état global du controller.
enum CameraAiStatus {
  idle,
  modelLoading,
  capturing,
  analyzing,
  success,
  error,
}

/// Controller ChangeNotifier pour le module camera_ai.
///
/// Stratégie d'analyse en 3 niveaux (par ordre de priorité) :
/// 1. **TFLite** : si le modèle `assets/models/model_unquant.tflite` est
///    disponible et chargé avec succès.
/// 2. **RVB/HSV** : algorithme chromatique offline via [CameraAiRepositoryImpl]
///    + [CameraAiLocalDataSource] — TOUJOURS disponible, jamais mocké.
/// 3. **Simulé** : uniquement en dernier recours si les deux précédents
///    échouent (impossible en production car RVB/HSV n'a pas de dépendance).
class CameraAiController extends ChangeNotifier {
  CameraAiController({
    ICameraAiRepository? repository,
    SimulatedAiService? simulatedService,
    TfliteAiService? tfliteService,
  })  : _repository = repository ?? CameraAiRepositoryImpl(),
        _simulatedService = simulatedService ?? const SimulatedAiService(),
        _tfliteService = tfliteService ?? TfliteAiService() {
    _modelInitialization = _initModel();
  }

  final ICameraAiRepository _repository;
  final SimulatedAiService _simulatedService;
  final TfliteAiService _tfliteService;

  late final Future<void> _modelInitialization;

  CameraAiStatus _status = CameraAiStatus.modelLoading;
  WaterDiagnostic? _diagnostic;
  int? _lastSavedId;
  String? _errorMessage;
  bool _useTflite = false;
  bool _disposed = false;

  // ─── Getters publics ──────────────────────────────────────────────────────

  CameraAiStatus get status => _status;
  WaterDiagnostic? get diagnostic => _diagnostic;
  int? get lastSavedId => _lastSavedId;
  String? get errorMessage => _errorMessage;

  /// true quand le modèle TFLite est actif (meilleure précision).
  bool get isTfliteActive => _useTflite;

  // Alias de commodité pour la vue existante
  bool get isAnalyzing =>
      _status == CameraAiStatus.analyzing ||
      _status == CameraAiStatus.capturing;
  bool get isModelLoading => _status == CameraAiStatus.modelLoading;

  // ─── Initialisation modèle ───────────────────────────────────────────────

  Future<void> _initModel() async {
    _setStatus(CameraAiStatus.modelLoading);
    try {
      await _tfliteService.loadModel();
      _useTflite = true;
    } catch (_) {
      // TFLite indisponible → fallback sur RVB/HSV (toujours fonctionnel)
      _useTflite = false;
    } finally {
      _setStatus(CameraAiStatus.idle);
    }
  }

  // ─── Actions publiques ────────────────────────────────────────────────────

  /// Point d'entrée principal : analyse une image capturée ou importée.
  ///
  /// [imagePath] — chemin absolu vers le fichier sur le disque.
  /// Le résultat est automatiquement persisté dans SQLite.
  Future<void> processCapturedImage(String imagePath) async {
    await _modelInitialization;
    await _run(imagePath);
  }

  /// Alias utilisé par la vue quand [imageData] peut être null ou un chemin.
  Future<void> captureAndAnalyze({Object? imageData}) async {
    if (imageData is String && imageData.isNotEmpty) {
      await processCapturedImage(imageData);
      return;
    }
    // Pas d'image réelle → simulation pour démo
    await _runSimulated();
  }

  /// Force un statut pour la démo (long-press sur le viewfinder).
  Future<void> forceStatus(WaterDiagnosticStatus status) async {
    _setStatus(CameraAiStatus.analyzing);
    _errorMessage = null;
    final result = await _simulatedService.analyzeForced(status);
    _diagnostic = result;
    _setStatus(CameraAiStatus.success);
  }

  /// Remet le controller à son état initial.
  void reset() {
    _diagnostic = null;
    _lastSavedId = null;
    _errorMessage = null;
    _setStatus(CameraAiStatus.idle);
  }

  // ─── Logique d'analyse ────────────────────────────────────────────────────

  Future<void> _run(String imagePath) async {
    _setStatus(CameraAiStatus.analyzing);
    _errorMessage = null;

    try {
      if (_useTflite) {
        // Niveau 1 : TFLite (meilleure précision)
        try {
          final diag = await _tfliteService.analyzeImage(imagePath);
          final savedId =
              await _repository.saveDiagnostic(diag, imagePath: imagePath);
          _diagnostic = diag;
          _lastSavedId = savedId;
          _setStatus(CameraAiStatus.success);
          return;
        } catch (_) {
          // TFLite a échoué mid-inference → bascule sur RVB/HSV
          _useTflite = false;
        }
      }

      // Niveau 2 : algorithme RVB/HSV offline (ne peut pas échouer
      // si l'image est lisible)
      final useCase = AnalyzeWaterImageUseCase(_repository);
      final result = await useCase(imagePath);
      _diagnostic = result.diagnostic;
      _lastSavedId = result.savedId;
      _setStatus(CameraAiStatus.success);
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setStatus(CameraAiStatus.error);
    }
  }

  Future<void> _runSimulated() async {
    _setStatus(CameraAiStatus.analyzing);
    _errorMessage = null;
    try {
      _diagnostic = await _simulatedService.analyze();
      _setStatus(CameraAiStatus.success);
    } catch (_) {
      _errorMessage = 'Impossible d\'analyser cet échantillon.';
      _setStatus(CameraAiStatus.error);
    }
  }

  // ─── Utilitaires ─────────────────────────────────────────────────────────

  void _setStatus(CameraAiStatus newStatus) {
    _status = newStatus;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tfliteService.dispose();
    super.dispose();
  }
}
