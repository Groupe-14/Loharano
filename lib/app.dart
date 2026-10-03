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
        title: 'HydroCheck Offline',
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
        appBar: AppBar(title: Text('HydroCheck Offline · ${_titles[_index]}'), actions: const [OfflineBadgeWidget(), SizedBox(width: 8)]),
        body: IndexedStack(index: _index, children: _views),
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
