import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/water_diagnostic.dart';
import '../controllers/camera_ai_controller.dart';
import '../widgets/pitch_demo_panel.dart';
import '../widgets/turbidity_gauge_widget.dart';
import '../../../local_db/data/services/local_db_service.dart';
import '../../../local_db/data/services/sync_engine_service.dart';
import '../../../purification/purification_guide_view.dart';

class CameraScannerView extends StatefulWidget {
  const CameraScannerView({super.key, this.controller, this.onDiagnostic});

  final CameraAiController? controller;
  final ValueChanged<WaterDiagnostic>? onDiagnostic;

  @override
  State<CameraScannerView> createState() => _CameraScannerViewState();
}

class _CameraScannerViewState extends State<CameraScannerView> {
  late final CameraAiController _controller;
  late final bool _ownsController;
  DateTime? _savedDiagnosticTimestamp;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CameraAiController();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final diagnostic = _controller.diagnostic;
    if (diagnostic != null &&
        _savedDiagnosticTimestamp != diagnostic.timestamp) {
      _savedDiagnosticTimestamp = diagnostic.timestamp;
      widget.onDiagnostic?.call(diagnostic);
      unawaited(_saveAndSync(diagnostic));
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveAndSync(WaterDiagnostic diagnostic) async {
    final waterTest = diagnostic.toWaterTestModel();
    try {
      await LocalDbService.instance.saveTest(waterTest);
      unawaited(SyncEngineService.instance.syncPendingTests());
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PurificationGuideView(waterTest: waterTest),
          ),
        );
      }
    } catch (_) {
      // The analysis result remains visible if offline persistence fails.
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Placez le verre dans le cadre',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            GestureDetector(
              onLongPress: () => PitchDemoPanel.show(context,
                  onStatusSelected: _controller.forceStatus),
              child: AspectRatio(
                aspectRatio: 0.95,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(24)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.water_drop,
                          color: Colors.white24, size: 88),
                      Container(
                        width: 190,
                        height: 240,
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.primaryBlue, width: 3),
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      const Positioned(
                          bottom: 16,
                          child: Text('Caméra indisponible · aperçu simulé',
                              style: TextStyle(color: Colors.white70))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_controller.isAnalyzing)
              const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator())
            else
              FilledButton.icon(
                onPressed: () => _controller.captureAndAnalyze(),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capturer et analyser'),
              ),
            if (_controller.errorMessage != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_controller.errorMessage!,
                      style: const TextStyle(color: AppColors.danger))),
            if (_controller.diagnostic case final diagnostic?) ...[
              const SizedBox(height: 16),
              TurbidityGaugeWidget(diagnostic: diagnostic),
            ],
          ],
        ),
      );
}
