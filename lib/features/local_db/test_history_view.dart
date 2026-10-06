import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/measurement.dart';
import '../../core/models/risk_level.dart';

class TestHistoryView extends StatelessWidget {
  const TestHistoryView(
      {super.key,
      required this.items,
      required this.error,
      required this.loading});

  final List<Measurement> items;
  final Object? error;
  final bool loading;

  Future<void> _export(BuildContext context) async {
    final buffer = StringBuffer(
        'id,created_at,source,risk_level,confidence,lat,lng,precision,demo,reasons\n');
    for (final item in items) {
      buffer.writeln(
          '${item.id},${item.createdAt.toIso8601String()},${item.sourceType.name},${item.riskLevel.name},${item.confidence},${item.lat ?? ''},${item.lng ?? ''},${item.locationPrecision},${item.isDemo},"${item.reasons.join(' / ').replaceAll('"', '\'')}"');
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/loharano-mesures.csv');
    await file.writeAsString(buffer.toString());
    await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Mesures Loharano'));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null)
      return Center(
          child: Text('Impossible de lire l’historique.\n$error',
              textAlign: TextAlign.center));
    if (items.isEmpty)
      return const Center(child: Text('Aucun dépistage enregistré'));
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
              onPressed: () => _export(context),
              icon: const Icon(Icons.ios_share),
              label: const Text('Exporter le CSV')),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading:
                    Icon(Icons.circle, color: _color(item.riskLevel), size: 16),
                title: Text(item.riskLevel.label),
                subtitle: Text(
                    '${item.createdAt.toLocal()} · ${item.sourceType.label}${item.isDemo ? ' · DÉMO' : ''}'),
                trailing: Text('${(item.confidence * 100).round()} %'),
              );
            },
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
