import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/repositories/pump_repository.dart';
import '../data/services/audio_engine_service.dart';
import '../domain/entities/pump_data.dart';
import 'widgets/pump_info_card.dart';
import 'widgets/scanner_overlay_widget.dart';

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final _scanner = MobileScannerController();
  final _audioEngine = AudioEngineService();

  String? _pumpId;
  PumpData? _currentPump;

  @override
  void initState() {
    super.initState();
    _audioEngine.onStateChanged = () {
      if (mounted) setState(() {});
    };
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value == _pumpId) return;

    final pumpData = PumpRepository.getPumpFromQr(value);

    setState(() {
      _pumpId = value;
      _currentPump = pumpData;
    });

    // Lecture synchrone de l'instruction audio enregistrée et localisée
    await _audioEngine.playAsset(pumpData.audioAsset);
  }

  void _resetScanner() {
    _audioEngine.pause();
    setState(() {
      _pumpId = null;
      _currentPump = null;
    });
  }

  @override
  void dispose() {
    _scanner.dispose();
    _audioEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            // Scanner QR Code physique
            MobileScanner(
              controller: _scanner,
              onDetect: _onDetect,
            ),

            // Cadre de cadrage visuel et contrôles matériels
            ScannerOverlayWidget(
              controller: _scanner,
              isDetected: _pumpId != null,
            ),

            // Panneau inférieur d'information et guidage audio synchronisé
            if (_pumpId != null && _currentPump != null)
              PumpInfoCard(
                pump: _currentPump!,
                audioEngine: _audioEngine,
                onReset: _resetScanner,
              ),
          ],
        ),
      );
}
