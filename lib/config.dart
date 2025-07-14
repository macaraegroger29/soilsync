import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // //PC to emulator
  // static const String defaultBaseUrl =
  //     'http://10.0.2.2:8000'; // For Android emulator

  // // PC to physical device
  static const String baseUrl = 'http://192.168.254.174:8000';

  // online db to physical device
  // static const String baseUrl = 'https://soilsync.pythonanywhere.com';

  // Timeout durations
  static const int connectionTimeout = 5; // seconds
  static const int receiveTimeout = 10; // seconds

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_ip') ?? baseUrl;
  }

  static Future<void> setBaseUrl(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    // Note: This adds http:// and :8000 when saving
    await prefs.setString('server_ip', 'http://$ip:8000');
  }
}
