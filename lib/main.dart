import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:soilsync/screens/splash_screen.dart';
import 'package:soilsync/screens/enhanced_login_screen.dart';
import 'package:soilsync/screens/enhanced_register_screen.dart';
import 'package:soilsync/screens/grid_sampling_screen.dart';
import 'package:soilsync/screens/grid_area_input_screen.dart';
import 'package:soilsync/screens/grid_sampling_complete_screen.dart';
import 'package:soilsync/screens/grid_sampling_result_screen.dart';
import 'package:soilsync/user_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError caught: ${details.exceptionAsString()}');
    debugPrint('Stack trace: ${details.stack}');
    if (kReleaseMode) {
    } else {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error caught: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoilSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2E7D32),
          secondary: Color(0xFF8D6E63),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const EnhancedLoginScreen(),
        '/register': (context) => const EnhancedRegisterScreen(),
        '/dashboard': (context) => const UserDashboard(),
        '/gridSampling': (context) => const GridSamplingScreen(),
        '/gridAreaInput': (context) =>
            const GridAreaInputScreen(areaName: 'Area'),
        '/gridSamplingComplete': (context) =>
            const GridSamplingCompleteScreen(),
        '/gridSamplingResult': (context) => GridSamplingResultScreen(
              cropName: 'Recommended Crop: Rice',
              cropImagePath: 'assets/icons/rice.png',
              averages: const {
                'N': 0,
                'P': 0,
                'K': 0,
                'pH': 0,
                'temperature': 0,
                'humidity': 0,
                'rainfall': 0,
              },
            ),
      },
      home: const SplashScreen(),
    );
  }
}
