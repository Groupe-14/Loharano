import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../../core/models/water_test_model.dart';

class DiagnosticShareService {
  const DiagnosticShareService();

  String encode(WaterTestModel test) {
    final json = jsonEncode({
      'version': 1,
      'id': test.id,
      'ntu': test.turbidityScore,
      'latitude': test.latitude,
      'longitude': test.longitude,
      'timestamp': test.timestamp.toUtc().toIso8601String(),
      'status': test.status.name,
    });
    final compressed = GZipEncoder().encode(utf8.encode(json));
    return base64UrlEncode(Uint8List.fromList(compressed));
  }
}
