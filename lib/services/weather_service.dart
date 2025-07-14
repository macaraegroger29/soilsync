import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'location_service.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // Open-Meteo API (free, no API key required)
  static const String _openMeteoUrl = 'https://api.open-meteo.com/v1';
  final LocationService _locationService = LocationService();

  /// Get current weather and rainfall data for a location
  Future<Map<String, dynamic>> getCurrentWeather({
    double? latitude,
    double? longitude,
    String? city,
    bool forceRefresh = false,
  }) async {
    try {
      // Get location if not provided
      if (latitude == null || longitude == null) {
        final location = await _locationService.getCurrentLocation();
        latitude = location['latitude'];
        longitude = location['longitude'];
      }

      // Ensure we have valid coordinates
      if (latitude == null || longitude == null) {
        throw Exception('Invalid coordinates');
      }

      print('Fetching rainfall data for location: $latitude, $longitude');

      // Try backend API first
      try {
        final baseUrl = await AppConfig.getBaseUrl();
        final url =
            Uri.parse('$baseUrl/api/weather/?lat=$latitude&lon=$longitude');

        print('Trying backend API: $url');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final currentWeather = data['current_weather'];

          print('Backend API response: $currentWeather');

          // Fallback: just return current rainfall, no accumulation
          final weatherData = {
            'rainfall': currentWeather['rainfall'] ?? 0.0,
            'rainfall_accumulation': currentWeather['rainfall'] ?? 0.0,
            'weather_code': currentWeather['weather_code'] ?? 0,
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now().toIso8601String(),
          };

          print('Parsed rainfall data: $weatherData');
          return weatherData;
        } else {
          print('Backend API failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print('Backend weather API failed, trying direct API: $e');
      }

      // Fallback to direct Open-Meteo API - only rainfall data
      final url = Uri.parse(
          '$_openMeteoUrl/forecast?latitude=$latitude&longitude=$longitude'
          '&current=precipitation,rain,weather_code'
          '&hourly=rain'
          '&timezone=auto');

      print('Trying direct Open-Meteo API: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = _parseRainfallData(data, latitude, longitude);
        print('Direct API rainfall data: $weatherData');

        // Get accumulation period from settings
        final prefs = await SharedPreferences.getInstance();
        final period =
            prefs.getString('rainfall_accumulation_period') ?? '24 hours';
        final accumulation = getRainfallAccumulation(weatherData, period);
        weatherData['rainfall_accumulation'] = accumulation;
        return weatherData;
      } else {
        print('Direct API failed with status: ${response.statusCode}');
        throw Exception('Failed to load rainfall data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting rainfall data: $e');
      // Return fallback data
      return _getFallbackRainfallData();
    }
  }

  /// Parse weather data from API response
  Map<String, dynamic> _parseRainfallData(
      Map<String, dynamic> data, double lat, double lon) {
    final current = data['current'];
    final hourly = data['hourly'];

    // Get current rainfall (mm)
    double currentRainfall = 0.0;
    if (current != null && current['rain'] != null) {
      currentRainfall = (current['rain'] as num).toDouble();
    } else if (current != null && current['precipitation'] != null) {
      currentRainfall = (current['precipitation'] as num).toDouble();
    }

    // Calculate hourly rainfall for next 24 hours
    List<double> hourlyRainfall = [];
    if (hourly != null && hourly['rain'] != null) {
      final rainData = hourly['rain'] as List;
      hourlyRainfall =
          rainData.take(24).map((value) => (value as num).toDouble()).toList();
    }

    return {
      'rainfall': currentRainfall,
      'hourly_rainfall': hourlyRainfall,
      'weather_code': current?['weather_code'] ?? 0,
      'latitude': lat,
      'longitude': lon,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Calculate rainfall accumulation for a given period
  double getRainfallAccumulation(
      Map<String, dynamic> weatherData, String period) {
    final List<dynamic>? hourly =
        weatherData['hourly_rainfall'] as List<dynamic>?;
    if (hourly == null || hourly.isEmpty) return 0.0;
    int count = 24;
    if (period == '7 days') count = 168;
    if (hourly.length < count) count = hourly.length;
    return hourly.take(count).fold(0.0, (a, b) => a + (b as double));
  }

  /// Get weather description from weather code
  String getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Light drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  /// Get weather icon from weather code
  String getWeatherIcon(int weatherCode) {
    if (weatherCode >= 51 && weatherCode <= 67) return '🌧️'; // Rain
    if (weatherCode >= 71 && weatherCode <= 77) return '❄️'; // Snow
    if (weatherCode >= 80 && weatherCode <= 86) return '🌦️'; // Showers
    if (weatherCode >= 95 && weatherCode <= 99) return '⛈️'; // Thunderstorm
    if (weatherCode >= 0 && weatherCode <= 3)
      return '☀️'; // Clear/Partly cloudy
    if (weatherCode >= 45 && weatherCode <= 48) return '🌫️'; // Fog
    return '🌤️'; // Default
  }

  /// Fallback weather data when API fails
  Map<String, dynamic> _getFallbackRainfallData() {
    return {
      'rainfall': 0.0,
      'hourly_rainfall': List.generate(24, (index) => 0.0),
      'weather_code': 0,
      'latitude': 14.5995, // Default to Manila coordinates
      'longitude': 120.9842,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Save weather data to shared preferences
  Future<void> saveWeatherData(Map<String, dynamic> weatherData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_weather_data', json.encode(weatherData));
    await prefs.setString(
        'weather_timestamp', DateTime.now().toIso8601String());
  }

  /// Load cached weather data from shared preferences
  Future<Map<String, dynamic>?> loadCachedWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    final weatherDataString = prefs.getString('last_weather_data');
    final timestampString = prefs.getString('weather_timestamp');

    if (weatherDataString != null && timestampString != null) {
      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();

      // Return cached data if it's less than 30 minutes old
      if (now.difference(timestamp).inMinutes < 30) {
        return json.decode(weatherDataString);
      }
    }

    return null;
  }

  /// Clear cached weather data
  Future<void> clearCachedWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_weather_data');
    await prefs.remove('weather_timestamp');
    print('Weather cache cleared');
  }
}
