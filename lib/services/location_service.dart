import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Default location (Manila, Philippines)
  static const double _defaultLatitude = 14.5995;
  static const double _defaultLongitude = 120.9842;

  /// Get the current location from settings or device GPS
  Future<Map<String, double>> getCurrentLocation() async {
    try {
      // First, try to get location from settings
      final locationFromSettings = await _getLocationFromSettings();
      if (locationFromSettings != null) {
        print(
            '📍 Using location from settings: ${locationFromSettings['latitude']}, ${locationFromSettings['longitude']}');
        return locationFromSettings;
      }

      // If no location in settings, try device GPS
      final position = await _getDeviceLocation();
      print(
          '📍 Using device GPS location: ${position.latitude}, ${position.longitude}');
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('📍 Location error, using default: $e');
      return {
        'latitude': _defaultLatitude,
        'longitude': _defaultLongitude,
      };
    }
  }

  /// Get location from app settings
  Future<Map<String, double>?> _getLocationFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble('user_latitude');
      final longitude = prefs.getDouble('user_longitude');

      if (latitude != null && longitude != null) {
        return {
          'latitude': latitude,
          'longitude': longitude,
        };
      }
    } catch (e) {
      print('Error reading location from settings: $e');
    }
    return null;
  }

  /// Get device GPS location
  Future<Position> _getDeviceLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Save location to settings
  Future<void> saveLocationToSettings(double latitude, double longitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_latitude', latitude);
      await prefs.setDouble('user_longitude', longitude);
      print('📍 Location saved to settings: $latitude, $longitude');
    } catch (e) {
      print('Error saving location to settings: $e');
    }
  }

  /// Get current location from settings (without GPS fallback)
  Future<Map<String, double>?> getLocationFromSettings() async {
    return await _getLocationFromSettings();
  }

  /// Clear location from settings
  Future<void> clearLocationFromSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_latitude');
      await prefs.remove('user_longitude');
      print('📍 Location cleared from settings');
    } catch (e) {
      print('Error clearing location from settings: $e');
    }
  }

  /// Check if location is set in settings
  Future<bool> hasLocationInSettings() async {
    final location = await _getLocationFromSettings();
    return location != null;
  }
}
