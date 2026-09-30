enum WaterTestStatus { safe, warning, danger }

class WaterTestModel {
  const WaterTestModel({
    this.id,
    required this.timestamp,
    required this.status,
    required this.turbidityScore,
    this.imagePath,
    this.qrCodeId,
    this.isSynced = false,
  });

  final int? id;
  final DateTime timestamp;
  final WaterTestStatus status;
  final double turbidityScore;
  final String? imagePath;
  final String? qrCodeId;
  final bool isSynced;

  Map<String, Object?> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'turbidity_score': turbidityScore,
        'image_path': imagePath,
        'qr_code_id': qrCodeId,
        'is_synced': isSynced ? 1 : 0,
      };

  factory WaterTestModel.fromMap(Map<String, Object?> map) {
    return WaterTestModel(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: WaterTestStatus.values.byName(map['status'] as String),
      turbidityScore: (map['turbidity_score'] as num).toDouble(),
      imagePath: map['image_path'] as String?,
      qrCodeId: map['qr_code_id'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }
}
