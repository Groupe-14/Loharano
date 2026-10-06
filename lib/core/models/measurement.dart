import 'dart:convert';

import 'risk_level.dart';
import '../risk/risk_result.dart';

class Measurement {
  const Measurement({
    required this.id,
    required this.createdAt,
    required this.testType,
    required this.riskLevel,
    required this.confidence,
    required this.reasons,
    required this.actions,
    this.sourceType = SourceType.unknown,
    this.lat,
    this.lng,
    this.locationAccuracyM,
    this.locationPrecision = 'approx_100m',
    this.imagePath,
    this.waterPointId,
    this.isDemo = false,
    this.syncState = 'pending',
    this.syncedAt,
  });

  final String id;
  final DateTime createdAt;
  final String testType;
  final SourceType sourceType;
  final double? lat;
  final double? lng;
  final double? locationAccuracyM;
  final String locationPrecision;
  final RiskLevel riskLevel;
  final double confidence;
  final List<String> reasons;
  final List<GuideAction> actions;
  final String? imagePath;
  final String? waterPointId;
  final bool isDemo;
  final String syncState;
  final DateTime? syncedAt;

  RiskResult toResult() => RiskResult(
        level: riskLevel,
        confidence: confidence,
        reasons: reasons,
        actions: actions,
        testType: testType,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'created_at': createdAt.toUtc().millisecondsSinceEpoch,
        'test_type': testType,
        'source_type': sourceType.name,
        'lat': lat,
        'lng': lng,
        'location_accuracy_m': locationAccuracyM,
        'location_precision': locationPrecision,
        'risk_level': riskLevel.name,
        'confidence': confidence,
        'reasons_json': jsonEncode(reasons),
        'actions_json':
            jsonEncode(actions.map((action) => action.name).toList()),
        'image_path': imagePath,
        'water_point_id': waterPointId,
        'is_demo': isDemo ? 1 : 0,
        'sync_state': syncState,
        'synced_at': syncedAt?.toUtc().millisecondsSinceEpoch,
      };

  factory Measurement.fromMap(Map<String, Object?> map) {
    final reasons = (jsonDecode(map['reasons_json'] as String? ?? '[]') as List)
        .cast<String>();
    final actions = (jsonDecode(map['actions_json'] as String? ?? '[]') as List)
        .map((item) => GuideAction.parse(item as String))
        .toList();
    final synced = map['synced_at'] as int?;
    return Measurement(
      id: map['id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int,
          isUtc: true),
      testType: map['test_type'] as String,
      sourceType: SourceType.parse(map['source_type'] as String?),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      locationAccuracyM: (map['location_accuracy_m'] as num?)?.toDouble(),
      locationPrecision: map['location_precision'] as String? ?? 'approx_100m',
      riskLevel: RiskLevel.parse(map['risk_level'] as String),
      confidence: (map['confidence'] as num).toDouble(),
      reasons: reasons,
      actions: actions,
      imagePath: map['image_path'] as String?,
      waterPointId: map['water_point_id'] as String?,
      isDemo: (map['is_demo'] as int? ?? 0) == 1,
      syncState: map['sync_state'] as String? ?? 'pending',
      syncedAt: synced == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(synced, isUtc: true),
    );
  }
}

class WaterPoint {
  const WaterPoint({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.pointType = 'other',
    this.isDemo = false,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final String pointType;
  final bool isDemo;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'point_type': pointType,
        'is_demo': isDemo ? 1 : 0,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      };

  factory WaterPoint.fromMap(Map<String, Object?> map) => WaterPoint(
        id: map['id'] as String,
        name: map['name'] as String? ?? 'Point d’eau',
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        pointType: map['point_type'] as String? ?? 'other',
        isDemo: (map['is_demo'] as int? ?? 0) == 1,
      );
}
