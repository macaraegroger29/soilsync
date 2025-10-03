/// Represents a single soil/environmental record for a crop.
class CropRecord {
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double temperature;
  final double humidity;
  final double ph;
  final double rainfall;
  final DateTime createdAt;

  CropRecord({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.temperature,
    required this.humidity,
    required this.ph,
    required this.rainfall,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'N': nitrogen,
        'P': phosphorus,
        'K': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'ph': ph,
        'rainfall': rainfall,
        'created_at': createdAt.toIso8601String(),
      };

  factory CropRecord.fromJson(Map<String, dynamic> json) => CropRecord(
        nitrogen: (json['N'] as num).toDouble(),
        phosphorus: (json['P'] as num).toDouble(),
        potassium: (json['K'] as num).toDouble(),
        temperature: (json['temperature'] as num).toDouble(),
        humidity: (json['humidity'] as num).toDouble(),
        ph: (json['ph'] as num).toDouble(),
        rainfall: (json['rainfall'] as num).toDouble(),
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}

/// Represents a crop collection session with its metadata and records.
class CropCollectionSession {
  final String id;
  final String cropName;
  final String? description;
  final Map<String, dynamic>? metadata;
  final List<CropRecord> records;
  final int targetCount;
  final DateTime createdAt;

  CropCollectionSession({
    required this.id,
    required this.cropName,
    this.description,
    this.metadata,
    List<CropRecord>? records,
    this.targetCount = 100,
    DateTime? createdAt,
  })  : records = records ?? <CropRecord>[],
        createdAt = createdAt ?? DateTime.now();

  int get progressCount => records.length;
  double get progressRatio =>
      targetCount == 0 ? 0 : records.length / targetCount;
  bool get isComplete => progressCount >= targetCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_name': cropName,
        'description': description,
        'metadata': metadata,
        'target_count': targetCount,
        'created_at': createdAt.toIso8601String(),
        'records': records.map((r) => r.toJson()).toList(),
      };

  factory CropCollectionSession.fromJson(Map<String, dynamic> json) =>
      CropCollectionSession(
        id: json['id'] as String,
        cropName: json['crop_name'] as String,
        description: json['description'] as String?,
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
        targetCount: (json['target_count'] as num?)?.toInt() ?? 100,
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        records: ((json['records'] as List?) ?? [])
            .map((e) => CropRecord.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  /// Export this session's records into CSV lines using dataset headers.
  /// The header row is: N,P,K,temperature,humidity,ph,rainfall,label
  List<String> toCsvLines() {
    return records
        .map((r) =>
            '${r.nitrogen},${r.phosphorus},${r.potassium},${r.temperature},${r.humidity},${r.ph},${r.rainfall},${csvEscape(cropName)}')
        .toList();
  }
}

String csvEscape(String value) {
  final needsQuotes =
      value.contains(',') || value.contains('"') || value.contains('\n');
  var escaped = value.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}
