import 'package:flutter/foundation.dart';

import '../../data/services/simulated_ai_service.dart';
import '../../data/services/tflite_ai_service.dart';
import '../../domain/entities/water_diagnostic.dart';

class CameraAiController extends ChangeNotifier {
  CameraAiController({
    SimulatedAiService? simulatedService,
    TfliteAiService? tfliteService,
  })  : _simulatedService = simulatedService ?? const SimulatedAiService(),
        _tfliteService = tfliteService ?? TfliteAiService() {
    _modelInitialization = _initModel();
  }

  final SimulatedAiService _simulatedService;
  final TfliteAiService _tfliteService;
  late final Future<void> _modelInitialization;
  WaterDiagnostic? _diagnostic;
  bool _isAnalyzing = false;
  bool _isModelLoading = true;
  bool _useFallback = false;
  String? _errorMessage;
  bool _disposed = false;

  WaterDiagnostic? get diagnostic => _diagnostic;
  bool get isAnalyzing => _isAnalyzing;
  bool get isModelLoading => _isModelLoading;
  bool get isUsingFallback => _useFallback;
  String? get errorMessage => _errorMessage;

  Future<void> _initModel() async {
    try {
      await _tfliteService.loadModel();
    } catch (error) {
      _useFallback = true;
      _errorMessage = 'Modèle local indisponible : analyse simulée activée.';
    } finally {
      _isModelLoading = false;
      _notify();
    }
  }

  Future<void> processCapturedImage(String path) async {
    await _modelInitialization;
    await _run(() => _useFallback
        ? _simulatedService.analyze(imageData: path)
        : _tfliteService.analyzeImage(path));
  }

  Future<void> captureAndAnalyze({Object? imageData}) async {
    if (imageData is String) {
      await processCapturedImage(imageData);
      return;
    }
    await _run(() => _simulatedService.analyze(imageData: imageData));
  }

  Future<void> forceStatus(WaterDiagnosticStatus status) async {
    await _run(() => _simulatedService.analyzeForced(status));
  }

  Future<void> _run(Future<WaterDiagnostic> Function() operation) async {
    _isAnalyzing = true;
    _errorMessage = null;
    _notify();
    try {
      _diagnostic = await operation();
    } catch (error) {
      if (!_useFallback) {
        _useFallback = true;
        _errorMessage =
            'Inférence TFLite indisponible : analyse simulée activée.';
        _diagnostic = await _simulatedService.analyze();
        return;
      }
      _errorMessage = 'Impossible d’analyser cet échantillon.';
    } finally {
      _isAnalyzing = false;
      _notify();
    }
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
