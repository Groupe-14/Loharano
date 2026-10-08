import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/models/water_test_model.dart';
import '../../data/services/diagnostic_share_service.dart';

Future<void> showDiagnosticQrDialog(
  BuildContext context,
  WaterTestModel test,
) {
  final payload = const DiagnosticShareService().encode(test);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Partager le diagnostic'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 220,
              child: QrImageView(data: payload),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scannez ce code hors-ligne avec un autre téléphone.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(payload, maxLines: 2, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
