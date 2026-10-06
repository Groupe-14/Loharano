import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
    final frame = isDetected ? const Color(0xFFD7EBE6) : Colors.white;
    return Stack(
      children: [
        Center(
          child: CustomPaint(
            size: const Size.square(220),
            painter: _ScanFramePainter(color: frame),
          ),
        ),
        Positioned(
          top: 12,
          right: 8,
          child: Row(
            children: [
              _TorchButton(controller: controller),
              IconButton(
                tooltip: 'Basculer caméra',
                onPressed: () => controller.switchCamera(),
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 20,
          right: 20,
          bottom: 16,
          child: Text(
            'Cadrez le QR du point d’eau',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const arm = 32.0;
    final path = Path()
      ..moveTo(0, arm)
      ..lineTo(0, 0)
      ..lineTo(arm, 0)
      ..moveTo(size.width - arm, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, arm)
      ..moveTo(size.width, size.height - arm)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - arm, size.height)
      ..moveTo(arm, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.color != color;
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
    return IconButton(
      tooltip: 'Flash',
      onPressed: () async {
        await widget.controller.toggleTorch();
        setState(() => _isTorchOn = !_isTorchOn);
      },
      icon: Icon(
        _isTorchOn ? Icons.flash_on : Icons.flash_off,
        color: _isTorchOn ? const Color(0xFFF8EDD8) : Colors.white,
      ),
    );
  }
}
