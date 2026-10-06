import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class OfflineBadgeWidget extends StatefulWidget {
  const OfflineBadgeWidget({super.key});

  @override
  State<OfflineBadgeWidget> createState() => _OfflineBadgeWidgetState();
}

class _OfflineBadgeWidgetState extends State<OfflineBadgeWidget> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool? _offline;

  @override
  void initState() {
    super.initState();
    _read();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _offline = _isOffline(results));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
            : 'Réseau';
    final color = offline == null
        ? AppColors.muted
        : offline
            ? AppColors.high
            : AppColors.low;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
      ],
    );
  }
}
