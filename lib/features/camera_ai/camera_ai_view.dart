import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/water_test_model.dart';

class CameraAiView extends StatefulWidget {
  const CameraAiView({super.key});

  @override
  State<CameraAiView> createState() => _CameraAiViewState();
}

class _CameraAiViewState extends State<CameraAiView> {
  WaterTestStatus? _result;

  void _capture([WaterTestStatus? forcedStatus]) {
    setState(() {
      _result = forcedStatus ?? WaterTestStatus.values[DateTime.now().second % 3];
    });
  }

  void _forceNextStatus() {
    final current = _result?.index ?? -1;
    _capture(WaterTestStatus.values[(current + 1) % WaterTestStatus.values.length]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Placez le verre dans le cadre', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primaryBlue, width: 3),
                ),
                child: const Center(child: Icon(Icons.water_drop, color: Colors.white, size: 80)),
              ),
            ),
            const SizedBox(height: 20),
            if (_result != null) _ResultBanner(status: _result!),
            GestureDetector(
              onLongPress: _forceNextStatus,
              child: FilledButton.icon(
                onPressed: _capture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capturer et analyser'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.status});
  final WaterTestStatus status;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(status.name.toUpperCase(), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold)),
      );

  Color _statusColor(WaterTestStatus value) => switch (value) {
        WaterTestStatus.safe => AppColors.safe,
        WaterTestStatus.warning => AppColors.warning,
        WaterTestStatus.danger => AppColors.danger,
      };
}
