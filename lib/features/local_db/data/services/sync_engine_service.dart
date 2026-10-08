import 'dart:convert';

import '../../../../core/models/water_test_model.dart';
import 'local_db_service.dart';

/// Offline-first synchronisation boundary for B2G/NGO transmission.
class SyncEngineService {
  SyncEngineService._();

  static final instance = SyncEngineService._();

  Future<int> syncPendingTests({
    String region = 'unknown',
    double? latitude,
    double? longitude,
  }) async {
    final pending = (await LocalDbService.instance.getAllTests())
        .where((test) => !test.isSynced)
        .toList();
    if (pending.isEmpty) return 0;

    final payload = jsonEncode({
      'version': 1,
      'region': region,
      'sent_at': DateTime.now().toUtc().toIso8601String(),
      'tests': pending
          .map((test) => _testPayload(test, region, latitude, longitude))
          .toList(),
    });

    await _sendToB2gNgo(payload);
    await LocalDbService.instance.markAsSynced(
      pending
          .map((test) => test.id)
          .whereType<int>()
          .map((id) => '$id')
          .toList(),
    );
    return pending.length;
  }

  Map<String, Object?> _testPayload(
    WaterTestModel test,
    String region,
    double? defaultLatitude,
    double? defaultLongitude,
  ) =>
      {
        'id': test.id,
        'timestamp': test.timestamp.toUtc().toIso8601String(),
        'status': test.status.name,
        'ntu': test.turbidityScore,
        'region': region,
        'latitude': test.latitude ?? defaultLatitude,
        'longitude': test.longitude ?? defaultLongitude,
      };

  Future<void> _sendToB2gNgo(String payload) async {
    // Replace this seam with the authenticated B2G/ONG API client.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (payload.isEmpty) {
      throw StateError('Cannot synchronise an empty payload.');
    }
  }
}
