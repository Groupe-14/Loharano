import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'features/audio_qr/presentation/qr_scanner_view.dart';
import 'features/camera_ai/camera_ai_view.dart';
import 'features/local_db/test_history_view.dart';
import 'features/purification/purification_guide_view.dart';
import 'features/pwa_offline/offline_badge_widget.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'HydroCheck AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue), scaffoldBackgroundColor: AppColors.background, useMaterial3: true),
        home: const _HydroShell(),
      );
}

class _HydroShell extends StatefulWidget {
  const _HydroShell();

  @override
  State<_HydroShell> createState() => _HydroShellState();
}

class _HydroShellState extends State<_HydroShell> {
  int _index = 0;
  final _views = const [CameraAiView(), PurificationGuideView(), QrScannerView(), TestHistoryView()];
  final _titles = const ['Analyse', 'Purification', 'Pompe', 'Historique'];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/image/Logo.jpeg', 
                  height: 32,
                  colorBlendMode: BlendMode.multiply, // Rend le fond blanc transparent !
                  color: Colors.white, // Nécessaire pour que le multiply s'applique au fond blanc
                ),
              ),
              const SizedBox(width: 10),
              Text('HydrocheckAI · ${_titles[_index]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: const [OfflineBadgeWidget(), SizedBox(width: 8)],
        ),
        body: _views[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.camera_alt_outlined), label: 'Analyse'),
            NavigationDestination(icon: Icon(Icons.water_drop_outlined), label: 'Purifier'),
            NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
            NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
          ],
        ),
      );
}
