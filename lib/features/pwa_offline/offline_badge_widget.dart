import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineBadgeWidget extends StatefulWidget {
  const OfflineBadgeWidget({super.key});

  @override
  State<OfflineBadgeWidget> createState() => _OfflineBadgeWidgetState();
}

class _OfflineBadgeWidgetState extends State<OfflineBadgeWidget> {
  final _connectivity = Connectivity();
  bool? _offline;

  @override
  void initState() {
    super.initState();
    _read();
    _connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _offline = _isOffline(results));
    });
  }

  Future<void> _read() async {
    final results = await _connectivity.checkConnectivity();
    if (!mounted) return;
    setState(() => _offline = _isOffline(results));
  }

  bool _isOffline(List<ConnectivityResult> results) =>
      results.isEmpty ||
      results.every((result) => result == ConnectivityResult.none);

  @override
  Widget build(BuildContext context) {
    final offline = _offline;
    final label = offline == null
        ? 'Réseau…'
        : offline
            ? 'Hors ligne'
            : 'Réseau détecté';
    final color = offline == null
        ? Colors.grey
        : offline
            ? Colors.red
            : Colors.green;
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(label),
    );
  }
}
