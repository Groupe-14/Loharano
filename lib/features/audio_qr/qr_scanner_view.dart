import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final _scanner = MobileScannerController();
  final _player = AudioPlayer();
  String? _pumpId;

  Future<void> _onDetect(BarcodeCapture capture) async {
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value == _pumpId) return;
    setState(() => _pumpId = value);
    // Replace this asset with the recorded, localized pump instruction.
    await _player.play(AssetSource('audio/pump-guide.mp3'));
  }

  @override
  void dispose() {
    _scanner.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            MobileScanner(controller: _scanner, onDetect: _onDetect),
            Center(child: Container(width: 240, height: 240, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(16)))),
            if (_pumpId != null) Align(alignment: Alignment.bottomCenter, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Pompe reconnue: $_pumpId')))),
          ],
        ),
      );
}
