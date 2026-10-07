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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(data: payload, size: 220),
          const SizedBox(height: 8),
          const Text('Scannez ce code hors-ligne avec un autre téléphone.'),
          SelectableText(payload, maxLines: 2),
        ],
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
