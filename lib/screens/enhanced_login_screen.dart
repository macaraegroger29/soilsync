import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../admin_dashboard.dart';
import '../user_dashboard.dart';
import 'enhanced_register_screen.dart';
import '../config.dart';

class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final TextEditingController _serverIpController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String errorMessage = '';
  bool isServerAvailable = false;
  String serverIp = '';

  @override
  void initState() {
    super.initState();
    print('EnhancedLoginScreen: initState called');

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
    _emailController.dispose();
    _passwordController.dispose();
    _serverIpController.dispose();
    super.dispose();
  }

  Future<void> _checkServerAvailability() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      isServerAvailable = false;
      errorMessage = '';
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

    if (mounted) {
      setState(() {
        isServerAvailable = available;
        _isLoading = false;
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
  }

  Future<void> _showIpSettings() async {
    final TextEditingController serverIpController =
        TextEditingController(text: _serverIpController.text);

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
              if (newServerIp.isNotEmpty) {
                await AppConfig.setBaseUrl(newServerIp);
                setState(() {
                  serverIp = newServerIp;
                  _serverIpController.text = newServerIp;
                  errorMessage = '';
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('server_ip', newServerIp);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/farm_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Section
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        Text(
                          'SoilSync',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        Text(
                          'Smart Farming Solutions',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),

                        SizedBox(height: 48),

                        // Login Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Username or Email Field
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Username or Email',
                                    hint: 'Enter your username or email',
                                    icon: Icons.person_outlined,
                                    keyboardType: TextInputType.text,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your username or email';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 16),

                                  // Password Field
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),

                                  SizedBox(height: 16),

                                  // Remember Me & Forgot Password
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                              activeColor: Color(0xFF2E7D32),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Remember me',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Spacer(),
                                      TextButton(
                                        onPressed: () {
                                          // Navigate to forgot password
                                        },
                                        child: Text(
                                          'Forgot?',
                                          style: TextStyle(
                                            color:
                                                Color.fromARGB(255, 26, 84, 29),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 24),

                                  // Login Button
                                  ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            if (_formKey.currentState
                                                    ?.validate() ??
                                                false) {
                                              _handleLogin();
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF2E7D32),
                                      minimumSize: Size(double.infinity, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),

                                  SizedBox(height: 24),

                                  // Sign Up Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EnhancedRegisterScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            color:
                                                Color.fromARGB(255, 26, 84, 29),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Floating server settings button (top right)
          Positioned(
            top: 48,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _showIpSettings,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.settings,
                      color: Color(0xFF2E7D32), size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Color(0xFF2E7D32)),
        suffixIcon: suffixIcon,
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
        fillColor: Colors.grey[50]!.withOpacity(0.9),
      ),
      validator: validator,
    );
  }

  Future<void> _handleLogin() async {
    print('Starting login process...');
    print('Username or Email: ${_emailController.text}');
    print('Password length: ${_passwordController.text.length}');

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
      _isLoading = true;
      errorMessage = '';
    });

    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final loginUrl = '$baseUrl/api/token/';
      print('DEBUG: Attempting login to $loginUrl');

      final String username = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      print('Trimmed Username or Email: $username');

      final requestBody = {
        'username_or_email': username,
        'password': password,
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
          errorMessage = 'Invalid username/email or password';
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
        setState(() {
          errorMessage = specificError;
        });
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
