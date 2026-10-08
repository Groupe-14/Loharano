import 'dart:convert';

import '../../../../core/models/water_test_model.dart';

class DataExportService {
  const DataExportService();

  String toCsv(List<WaterTestModel> tests) {
    final rows = <List<String>>[
      ['ID', 'Timestamp', 'NTU', 'Latitude', 'Longitude', 'Status'],
      ...tests.map((test) => [
            '${test.id ?? ''}',
            test.timestamp.toUtc().toIso8601String(),
            test.turbidityScore.toStringAsFixed(2),
            '${test.latitude ?? ''}',
            '${test.longitude ?? ''}',
            test.status.name,
          ]),
    ];
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
  }

  String toJson(List<WaterTestModel> tests) => const JsonEncoder.withIndent(
        '  ',
      ).convert(tests.map(_toMap).toList());

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Map<String, Object?> _toMap(WaterTestModel test) => {
        'id': test.id,
        'timestamp': test.timestamp.toUtc().toIso8601String(),
        'ntu': test.turbidityScore,
        'latitude': test.latitude,
        'longitude': test.longitude,
        'status': test.status.name,
        'isSynced': test.isSynced,
      };
}
