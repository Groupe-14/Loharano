import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Overlay du scanner QR Code avec contrôles caméra (flash/caméra) et repère visuel.
class ScannerOverlayWidget extends StatelessWidget {
  const ScannerOverlayWidget({
    super.key,
    required this.controller,
    required this.isDetected,
  });

  final MobileScannerController controller;
  final bool isDetected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDetected ? Colors.greenAccent : Colors.white,
                width: isDetected ? 4 : 3,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDetected ? Colors.greenAccent : Colors.black)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    isDetected
                        ? Icons.check_circle_outline
                        : Icons.qr_code_scanner,
                    color: (isDetected ? Colors.greenAccent : Colors.white)
                        .withValues(alpha: 0.5),
                    size: 64,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Card(
            color: Colors.black54,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TorchButton(controller: controller),
                  const SizedBox(width: 4),
                  Semantics(
                    label: 'Changer de caméra',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.cameraswitch, color: Colors.white),
                      tooltip: 'Basculer caméra',
                      onPressed: () => controller.switchCamera(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 24,
          left: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.64),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.center_focus_strong,
                      color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Pointez vers le QR Code',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TorchButton extends StatefulWidget {
  const _TorchButton({required this.controller});
  final MobileScannerController controller;

  @override
  State<_TorchButton> createState() => _TorchButtonState();
}

class _TorchButtonState extends State<_TorchButton> {
  bool _isTorchOn = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Activer ou désactiver le flash',
      button: true,
      child: IconButton(
        icon: Icon(
          _isTorchOn ? Icons.flash_on : Icons.flash_off,
          color: _isTorchOn ? Colors.amber : Colors.white,
        ),
        tooltip: 'Flash',
        onPressed: () async {
          await widget.controller.toggleTorch();
          setState(() => _isTorchOn = !_isTorchOn);
        },
      ),
    );
  }
}
