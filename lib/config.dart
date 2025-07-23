import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // //PC to emulator
  // static const String defaultBaseUrl =
  //     'http://10.0.2.2:8000'; // For Android emulator

  // // PC to physical device
  static const String baseUrl = 'http://192.168.254.174:8000';

  // Add the IP address for your ESP32
  static const String esp32Ip =
      '192.168.1.100'; // <-- CHANGE THIS to your ESP32's IP

  // online db to physical device
  // static const String baseUrl = 'https://soilsync.pythonanywhere.com';

  // Timeout durations
  static const int connectionTimeout = 5; // seconds
  static const int receiveTimeout = 10; // seconds

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('server_ip');
    if (saved == null || saved.isEmpty) {
      return baseUrl;
    }
    // If saved value starts with 'http', return as is
    if (saved.startsWith('http')) {
      return saved;
    }
    // If saved value is just an IP, add http:// and :8000
    return 'http://$saved:8000';
  }

  static Future<void> setBaseUrl(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    // Note: This adds http:// and :8000 when saving
    await prefs.setString('server_ip', 'http://$ip:8000');
  }
}
