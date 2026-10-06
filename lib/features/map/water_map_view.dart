import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/measurement.dart';
import '../../core/models/risk_level.dart';
import '../../features/sync/sync_service.dart';

class WaterMapView extends StatelessWidget {
  const WaterMapView(
      {super.key, required this.measurements, required this.onSync});

  final List<Measurement> measurements;
  final Future<SyncReport> Function() onSync;

  static const _antananarivo = LatLng(-18.8792, 47.5079);

  @override
  Widget build(BuildContext context) {
    final located = measurements
        .where((item) => item.lat != null && item.lng != null)
        .toList();
    final counts = <RiskLevel, int>{
      for (final level in RiskLevel.values) level: 0
    };
    for (final item in measurements) {
      counts[item.riskLevel] = (counts[item.riskLevel] ?? 0) + 1;
    }
    return Column(
      children: [
        Material(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${measurements.length} dépistage(s) sur ce téléphone',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    'Faible ${counts[RiskLevel.low]} · Moyen ${counts[RiskLevel.medium]} · Élevé ${counts[RiskLevel.high]} · Inconnu ${counts[RiskLevel.unknown]}'),
                const Text(
                    'Indicatif, non certifié. Les tuiles de fond demandent un passage en ligne la première fois.'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                      onPressed: () async {
                        final report = await onSync();
                        if (!context.mounted) return;
                        final message = report.skippedBecauseUnconfigured
                            ? 'Supabase n’est pas configuré. Les mesures restent ici.'
                            : 'Envoyées : ${report.sent}. Échecs : ${report.failed}.';
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(message)));
                      },
                      child: const Text('Envoyer les mesures en attente')),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FlutterMap(
            options:
                const MapOptions(initialCenter: _antananarivo, initialZoom: 12),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'mg.loharano.app',
              ),
              MarkerLayer(
                markers: [
                  for (final item in located)
                    Marker(
                      point: LatLng(item.lat!, item.lng!),
                      width: 36,
                      height: 36,
                      child: Tooltip(
                        message:
                            '${item.riskLevel.label}${item.isDemo ? ' · DÉMO' : ''}',
                        child: Icon(Icons.place,
                            color: _color(item.riskLevel), size: 32),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _color(RiskLevel level) => switch (level) {
        RiskLevel.low => AppColors.low,
        RiskLevel.medium => AppColors.medium,
        RiskLevel.high => AppColors.high,
        RiskLevel.unknown => AppColors.unknown,
      };
}
