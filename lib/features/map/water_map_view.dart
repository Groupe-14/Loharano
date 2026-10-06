import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/measurement.dart';
import '../../core/models/risk_level.dart';
import '../sync/sync_service.dart';

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
    final total = measurements.length;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      total == 1
                          ? '1 dépistage sur ce téléphone'
                          : '$total dépistages sur ce téléphone',
                      style: text.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final report = await onSync();
                      if (!context.mounted) return;
                      final message = report.skippedBecauseUnconfigured
                          ? 'Supabase n’est pas configuré. Les mesures restent ici.'
                          : 'Envoyées : ${report.sent}. Échecs : ${report.failed}.';
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));
                    },
                    child: const Text('Envoyer'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _count('Faible', counts[RiskLevel.low] ?? 0, AppColors.low),
                  _count(
                      'Moyen', counts[RiskLevel.medium] ?? 0, AppColors.medium),
                  _count('Élevé', counts[RiskLevel.high] ?? 0, AppColors.high),
                  _count('Inconnu', counts[RiskLevel.unknown] ?? 0,
                      AppColors.unknown),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                located.isEmpty
                    ? 'Aucun point pour l’instant. Un dépistage enregistré avec la position apparaît ici. Le fond se charge une fois en ligne, puis les tuiles déjà vues restent sur le téléphone.'
                    : 'Indicatif, non certifié. Les tuiles déjà vues restent disponibles hors ligne.',
                style: text.bodySmall,
              ),
            ],
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
                            color: AppColors.forRisk(item.riskLevel), size: 32),
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

  Widget _count(String label, int value, Color tone) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text('$value $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
