import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineBadgeWidget extends StatelessWidget {
  const OfflineBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final offline = snapshot.data?.contains(ConnectivityResult.none) ?? true;
        return Chip(
          avatar: Icon(Icons.circle, size: 10, color: offline ? Colors.red : Colors.green),
          label: Text(offline ? 'Mode Hors-Ligne Actif' : 'Connecté'),
        );
      },
    );
  }
}
