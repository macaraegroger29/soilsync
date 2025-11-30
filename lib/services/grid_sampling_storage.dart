import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents soil data collected from a single grid area
class GridAreaData {
  final int areaNumber;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double ph;
  final double temperature;
  final double humidity;
  final double rainfall;
  final DateTime collectedAt;

  GridAreaData({
    required this.areaNumber,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ph,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    DateTime? collectedAt,
  }) : collectedAt = collectedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'area_number': areaNumber,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'ph': ph,
        'temperature': temperature,
        'humidity': humidity,
        'rainfall': rainfall,
        'collected_at': collectedAt.toIso8601String(),
      };

  factory GridAreaData.fromJson(Map<String, dynamic> json) => GridAreaData(
        areaNumber: json['area_number'] as int,
        nitrogen: (json['nitrogen'] as num).toDouble(),
        phosphorus: (json['phosphorus'] as num).toDouble(),
        potassium: (json['potassium'] as num).toDouble(),
        ph: (json['ph'] as num).toDouble(),
        temperature: (json['temperature'] as num).toDouble(),
        humidity: (json['humidity'] as num).toDouble(),
        rainfall: (json['rainfall'] as num).toDouble(),
        collectedAt: DateTime.tryParse(json['collected_at'] ?? '') ?? DateTime.now(),
      );
}

/// Service for storing and managing grid sampling data
class GridSamplingStorage {
  static const String _key = 'grid_sampling_data_v1';
  static final GridSamplingStorage _instance = GridSamplingStorage._internal();

  factory GridSamplingStorage() => _instance;

  GridSamplingStorage._internal();

  /// Save soil data for a specific area
  Future<void> saveAreaData(GridAreaData data) async {
    final prefs = await SharedPreferences.getInstance();
    final allData = await loadAllAreaData();

    // Remove existing data for this area if it exists
    allData.removeWhere((d) => d.areaNumber == data.areaNumber);

    // Add new data
    allData.add(data);

    // Save back to storage
    final raw = json.encode(allData.map((d) => d.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  /// Load all area data
  Future<List<GridAreaData>> loadAllAreaData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = json.decode(raw);
      return list
          .map((e) => GridAreaData.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Load data for a specific area
  Future<GridAreaData?> loadAreaData(int areaNumber) async {
    final allData = await loadAllAreaData();
    try {
      return allData.firstWhere((d) => d.areaNumber == areaNumber);
    } catch (_) {
      return null;
    }
  }

  /// Check if all 4 areas have data
  Future<bool> isComplete() async {
    final allData = await loadAllAreaData();
    return allData.length >= 4;
  }

  /// Calculate averages from all 4 areas
  Future<Map<String, double>> calculateAverages() async {
    final allData = await loadAllAreaData();
    if (allData.length != 4) {
      throw Exception('Need data from all 4 areas to calculate averages');
    }

    double totalN = 0, totalP = 0, totalK = 0, totalPh = 0;
    double totalTemp = 0, totalHumidity = 0, totalRainfall = 0;

    for (final data in allData) {
      totalN += data.nitrogen;
      totalP += data.phosphorus;
      totalK += data.potassium;
      totalPh += data.ph;
      totalTemp += data.temperature;
      totalHumidity += data.humidity;
      totalRainfall += data.rainfall;
    }

    return {
      'N': totalN / 4,
      'P': totalP / 4,
      'K': totalK / 4,
      'ph': totalPh / 4,
      'temperature': totalTemp / 4,
      'humidity': totalHumidity / 4,
      'rainfall': totalRainfall / 4,
    };
  }

  /// Clear all stored data
  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
