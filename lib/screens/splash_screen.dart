import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../screens/enhanced_login_screen.dart';
import '../user_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    // Start navigation after minimum display time
    _startNavigation();
  }

  void _startNavigation() {
    // Wait minimum 2 seconds for splash to be visible
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;

    // Check if user is already logged in
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Navigate based on authentication status with seamless fade transition
    if (mounted) {
      final route = PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            token != null && token.isNotEmpty
                ? const UserDashboard()
                : const EnhancedLoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth fade transition
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      );

      Navigator.pushReplacement(context, route);
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Image.asset(
          'assets/images/launch_screen.png',
          width: size.width,
          height: size.height,
          fit: BoxFit.contain,
          // Cache the image for better performance
          cacheWidth: size.width.toInt(),
          cacheHeight: size.height.toInt(),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.white,
              child: const Center(
                child: Icon(
                  Icons.grass,
                  size: 70,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
