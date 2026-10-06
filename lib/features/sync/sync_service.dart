import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/db/local_database.dart';
import '../../core/models/measurement.dart';

/// Envoi optionnel vers Supabase (offre gratuite). Sans les deux clés, rien n'est contacté.
class SyncService {
  SyncService({http.Client? client, LocalDatabase? database})
      : _client = client ?? http.Client(),
        _database = database ?? LocalDatabase.instance;

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  final http.Client _client;
  final LocalDatabase _database;

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  Future<SyncReport> pushPending() async {
    if (!isConfigured) {
      return const SyncReport(
          sent: 0, failed: 0, skippedBecauseUnconfigured: true);
    }
    final pending = (await _database.getMeasurements())
        .where((item) => item.syncState != 'synced');
    var sent = 0;
    var failed = 0;
    for (final measurement in pending) {
      final ok = await _pushOne(measurement);
      if (ok) {
        await _database.markSynced(measurement.id);
        sent += 1;
      } else {
        await _database.markSyncFailed(measurement.id);
        failed += 1;
      }
    }
    return SyncReport(
        sent: sent, failed: failed, skippedBecauseUnconfigured: false);
  }

  Future<bool> _pushOne(Measurement measurement) async {
    final endpoint =
        Uri.parse('${url.replaceAll(RegExp(r'/+$'), '')}/rest/v1/measurements');
    final body = jsonEncode({
      'id': measurement.id,
      'created_at': measurement.createdAt.toUtc().millisecondsSinceEpoch,
      'test_type': measurement.testType,
      'source_type': measurement.sourceType.name,
      'lat': measurement.lat,
      'lng': measurement.lng,
      'location_precision': measurement.locationPrecision,
      'risk_level': measurement.riskLevel.name,
      'confidence': measurement.confidence,
      'reasons': measurement.reasons,
      'actions': measurement.actions.map((action) => action.name).toList(),
      'water_point_id': measurement.waterPointId,
      'is_demo': measurement.isDemo,
    });
    try {
      final response = await _client.post(
        endpoint,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=ignore-duplicates',
        },
        body: body,
      );
      return response.statusCode == 201 ||
          response.statusCode == 200 ||
          response.statusCode == 409;
    } catch (_) {
      return false;
    }
  }
}

class SyncReport {
  const SyncReport(
      {required this.sent,
      required this.failed,
      required this.skippedBecauseUnconfigured});

  final int sent;
  final int failed;
  final bool skippedBecauseUnconfigured;
}
