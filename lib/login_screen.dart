import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';
import 'register_screen.dart'; // Import the registration screen
import 'config.dart'; // Add this import

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController _serverIpController = TextEditingController();
  final TextEditingController _esp32IpController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';
  bool isServerAvailable = false;
  String serverIp = '';

  @override
  void initState() {
    super.initState();
    print('LoginScreen: initState called');

    // Delay server check to avoid startup issues
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkServerAvailability();
        _loadServerIp();
        _loadSavedIps();
      }
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkServerAvailability() async {
    if (!mounted) return;

    // Set loading state immediately
    setState(() {
      isLoading = true; // Use isLoading for the check as well
      isServerAvailable = false; // Assume not available initially
      errorMessage = ''; // Clear previous errors
    });

    String? checkError;
    bool available = false;

    try {
      final baseUrl = await AppConfig.getBaseUrl();
      print('DEBUG: baseUrl from AppConfig.getBaseUrl() = $baseUrl');
      print('Checking server availability at: $baseUrl/');
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print('Server check response status: ${response.statusCode}');
      print('Server check response body: ${response.body}');

      // Check for expected 200 OK from our root view
      if (response.statusCode == 200) {
        try {
          print('Attempting to decode JSON response...');
          final responseData = jsonDecode(response.body);
          print('JSON decoded successfully: $responseData');
          if (responseData['status'] == 'ok') {
            available = true;
            print('Server is available and responded correctly.');
          } else {
            checkError = 'Server responded unexpectedly (status != ok).';
            print('Server check error: $checkError Data: $responseData');
          }
        } catch (e) {
          checkError = 'Failed to parse server response (JSON Decode Error).';
          print('Server check error: $checkError Error: $e');
        }
      } else {
        checkError = 'Server responded with status ${response.statusCode}.';
        print('Server check error: $checkError');
      }
    } on TimeoutException {
      checkError = 'Connection to server timed out.';
      print('Server check error: $checkError');
    } on SocketException catch (e) {
      checkError = 'Could not connect to server (Network Error).';
      print('Server check error: $checkError Details: $e');
    } catch (e) {
      checkError = 'An unknown error occurred during server check.';
      print('Server check error: $checkError Details: $e');
    }

    print('Server check finished. Is available: $available');

    // Update state after checks are complete
    if (mounted) {
      setState(() {
        isServerAvailable = available;
        isLoading = false;
        // Optionally display the checkError if needed, but maybe not on startup
        // errorMessage = checkError ?? '';
      });
    }
  }

  Future<void> _loadServerIp() async {
    final baseUrl = await AppConfig.getBaseUrl();
    print('Full server URL: $baseUrl');
    setState(() {
      serverIp = baseUrl.replaceAll('http://', '').replaceAll(':8000', '');
    });
  }

  Future<void> _loadSavedIps() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIpController.text = prefs.getString('server_ip') ?? '';
    _esp32IpController.text = prefs.getString('esp32_ip') ?? '';
  }

  Future<void> _saveIps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', _serverIpController.text.trim());
    await prefs.setString('esp32_ip', _esp32IpController.text.trim());
  }

  Future<void> _showIpSettings() async {
    final TextEditingController serverIpController =
        TextEditingController(text: _serverIpController.text);
    final TextEditingController esp32IpController =
        TextEditingController(text: _esp32IpController.text);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: serverIpController,
              decoration: const InputDecoration(
                labelText: 'Server IP Address',
                hintText: 'e.g., 192.168.1.100',
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: esp32IpController,
              decoration: const InputDecoration(
                labelText: 'ESP32 IP Address',
                hintText: 'e.g., 192.168.1.101',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newServerIp = serverIpController.text.trim();
              final newEsp32Ip = esp32IpController.text.trim();
              if (newServerIp.isNotEmpty) {
                await AppConfig.setBaseUrl(newServerIp);
                setState(() {
                  serverIp = newServerIp;
                  _serverIpController.text = newServerIp;
                  _esp32IpController.text = newEsp32Ip;
                  errorMessage = '';
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('server_ip', newServerIp);
                await prefs.setString('esp32_ip', newEsp32Ip);
                Navigator.pop(context);
                await _checkServerAvailability();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server IP Address cannot be empty')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _login() async {
    print('Starting login process...');
    print('Username: ${usernameController.text}');
    // Don't log actual passwords in production
    print('Password length: ${passwordController.text.length}');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    if (!isServerAvailable) {
      print('Server not available. Current server IP: $serverIp');
      _showError('Server is not available. Please try again later.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final loginUrl = '$baseUrl/api/token/';
      print('DEBUG: Attempting login to $loginUrl');

      // Trim whitespace from username and password
      final String username = usernameController.text.trim();
      final String password = passwordController.text.trim();
      print('Trimmed Username: $username'); // Log trimmed username

      final requestBody = {
        'username': username, // Use trimmed username
        'password': password, // Use trimmed password
      };
      print(
          'Debug: Request headers: {Content-Type: application/json, Accept: application/json}');

      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: 30));

      print('Debug: Response status: ${response.statusCode}');
      print('Debug: Response headers: ${response.headers}');
      print('Debug: Response body raw: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Debug: Decoded response data: $data');

        // Verify token data
        print('Debug: Access token present: ${data.containsKey('access')}');
        print('Debug: Refresh token present: ${data.containsKey('refresh')}');
        print('Debug: Role present: ${data.containsKey('role')}');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        await prefs.setString('role', data['role'] ?? 'user');
        await prefs.setString('token', data['access']);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                data['role'] == 'admin' ? AdminDashboard() : UserDashboard(),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'Invalid username or password';
        });
        _showError(errorMessage);
      }
    } catch (e) {
      print('Login error details: $e');
      String specificError =
          'An error occurred during login. Please try again.';
      if (e is TimeoutException) {
        specificError = 'Connection to server timed out during login.';
      } else if (e is SocketException) {
        specificError =
            'Could not connect to server during login (Network Error).';
      } else if (e is http.ClientException) {
        specificError = 'Network error during login. Please check connection.';
      } else if (e is FormatException) {
        specificError = 'Received invalid data from server.';
      }

      if (mounted) {
        // Check mounted before setState
        setState(() {
          errorMessage = specificError;
        });
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6FCF97),
                  Color(0xFF219150),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Container(
                        child: Column(
                          children: [
                            Icon(Icons.eco, size: 80, color: Colors.white),
                            SizedBox(height: 24),
                            Text(
                              'SoilSync',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Modern Farming Made Simple',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                      Card(
                        color: Color(0xFFF8FAF5),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: usernameController,
                                  decoration: InputDecoration(
                                    hintText: 'Username',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your username';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 18),
                                TextFormField(
                                  controller: passwordController,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    prefixIcon: Icon(Icons.lock),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF219150),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: isLoading
                                        ? CircularProgressIndicator(
                                            color: Colors.white)
                                        : Text(
                                            'Login',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Don\'t have an account? Register',
                          style: TextStyle(
                            color: Color(0xFF219150),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Floating server settings button (top right)
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _showIpSettings,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      Icon(Icons.settings, color: Color(0xFF219150), size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
