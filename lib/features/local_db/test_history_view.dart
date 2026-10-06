import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/measurement.dart';

class TestHistoryView extends StatelessWidget {
  const TestHistoryView(
      {super.key,
      required this.items,
      required this.error,
      required this.loading});

  final List<Measurement> items;
  final Object? error;
  final bool loading;

  Future<void> _export() async {
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
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
          child: Text('Impossible de lire l’historique.\n$error',
              textAlign: TextAlign.center));
    }
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Aucun dépistage enregistré.\nFaites un test dans Tester pour le retrouver ici.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.ios_share),
              label: const Text('Exporter le CSV')),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final tone = AppColors.forRisk(item.riskLevel);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: tone,
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8)),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text(item.riskLevel.label),
                          subtitle: Text(
                              '${_when(item.createdAt)} · ${item.sourceType.label}${item.isDemo ? ' · DÉMO' : ''}'),
                          trailing:
                              Text('${(item.confidence * 100).round()} %'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _when(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year}  ${two(local.hour)}:${two(local.minute)}';
  }
}
