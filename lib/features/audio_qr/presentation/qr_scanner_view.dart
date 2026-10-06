import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/db/local_database.dart';
import '../../../core/models/measurement.dart';
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

    final pumpData = PumpRepository.findKnown(value);

    setState(() {
      _pumpId = value;
      _currentPump = pumpData;
    });

    if (pumpData != null) await _audioEngine.playAsset(pumpData.audioAsset);
  }

  Future<void> _saveUnknownPoint() async {
    final code = _pumpId;
    if (code == null) return;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau point d’eau'),
        content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nom')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, nameController.text.trim()),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      final position = await Geolocator.getCurrentPosition();
      await LocalDatabase.instance.insertWaterPoint(WaterPoint(
          id: code,
          name: name,
          lat: approx100m(position.latitude),
          lng: approx100m(position.longitude)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Point enregistré sur ce téléphone.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Position indisponible. Le point n’a pas été inventé.')));
    }
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
            if (_pumpId != null && _currentPump == null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                            'Point d’eau non reconnu. Aucune fiche n’est inventée pour ce code.'),
                        TextButton(
                            onPressed: _saveUnknownPoint,
                            child: const Text('Enregistrer ce point ici')),
                        TextButton(
                            onPressed: _resetScanner,
                            child: const Text('Fermer')),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
