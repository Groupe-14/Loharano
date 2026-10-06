import 'package:flutter/material.dart';

import 'core/audio/speech.dart';
import 'core/db/local_database.dart';
import 'core/theme/app_theme.dart';
import 'core/models/measurement.dart';
import 'core/risk/risk_result.dart';
import 'features/audio_qr/presentation/qr_scanner_view.dart';
import 'features/local_db/test_history_view.dart';
import 'features/map/water_map_view.dart';
import 'features/purification/purification_guide_view.dart';
import 'features/pwa_offline/offline_badge_widget.dart';
import 'features/sync/sync_service.dart';
import 'features/test_flow/test_flow_view.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _speech = Speech();
  final _sync = SyncService();
  static const _sections = [
    'Tester',
    'Purifier',
    'Carte',
    'Historique',
    'Scanner',
  ];
  var _index = 0;
  var _stepsRequest = 0;
  var _loading = true;
  Object? _error;
  List<Measurement> _items = [];
  RiskResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final items = await LocalDatabase.instance.getMeasurements();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
        _lastResult ??= items.isEmpty ? null : items.first.toResult();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Widget _body() {
    if (_index == 4) return const QrScannerView();
    final map = _index == 2
        ? WaterMapView(
            measurements: _items,
            onSync: () async {
              final report = await _sync.pushPending();
              await _reload();
              return report;
            })
        : const SizedBox.shrink();
    return IndexedStack(
      index: _index,
      children: [
        TestFlowView(onSaved: _save, onOpenGuide: _openGuide),
        PurificationGuideView(
            result: _lastResult,
            stepsRequest: _stepsRequest,
            onSpeak: _speech.speak,
            onFinish: () => setState(() => _index = 0)),
        map,
        TestHistoryView(items: _items, error: _error, loading: _loading),
      ],
    );
  }

  void _openGuide(RiskResult result) {
    setState(() {
      _lastResult = result;
      _stepsRequest += 1;
      _index = 1;
    });
  }

  Future<void> _save(Measurement measurement) async {
    await LocalDatabase.instance.insertMeasurement(measurement);
    setState(() => _lastResult = measurement.toResult());
    await _reload();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Loharano',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          appBar: _index == 4
              ? null
              : AppBar(
                  title: Text('Loharano · ${_sections[_index]}'),
                  actions: const [OfflineBadgeWidget(), SizedBox(width: 12)]),
          body: _body(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined), label: 'Tester'),
              NavigationDestination(
                  icon: Icon(Icons.water_drop_outlined), label: 'Purifier'),
              NavigationDestination(
                  icon: Icon(Icons.map_outlined), label: 'Carte'),
              NavigationDestination(
                  icon: Icon(Icons.history), label: 'Historique'),
              NavigationDestination(
                  icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
            ],
          ),
        ),
      );
}
