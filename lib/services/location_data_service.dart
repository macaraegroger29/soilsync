import 'dart:convert';
import 'package:flutter/services.dart';

class LocationDataService {
  static final LocationDataService _instance = LocationDataService._internal();
  factory LocationDataService() => _instance;
  LocationDataService._internal();

  Map<String, dynamic>? _cachedData;
  Future<Map<String, dynamic>>? _loadingFuture;

  Future<Map<String, dynamic>> getLocationData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }
    if (_loadingFuture != null) {
      return _loadingFuture!;
    }
    _loadingFuture = _loadData();
    return _loadingFuture!;
  }

  Future<Map<String, dynamic>> _loadData() async {
    final String jsonString = await rootBundle.loadString(
        'assets/locations/philippine_provinces_cities_municipalities_and_barangays_2019v2.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    _cachedData = jsonData;
    return _cachedData!;
  }
}
