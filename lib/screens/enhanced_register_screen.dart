import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class EnhancedRegisterScreen extends StatefulWidget {
  const EnhancedRegisterScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedRegisterScreen> createState() => _EnhancedRegisterScreenState();
}

class _EnhancedRegisterScreenState extends State<EnhancedRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final TextEditingController _serverIpController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool isServerAvailable = false;
  String serverIp = '';

  String? _selectedCropType;
  final List<String> _cropTypes = [
    'Rice',
    'Corn',
    'Wheat',
    'Sugarcane',
    'Coconut',
    'Banana',
    'Mango',
    'Vegetables',
    'Coffee',
    'Cotton',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    print('EnhancedRegisterScreen: initState called');

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
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _farmNameController.dispose();
    _farmSizeController.dispose();
    _serverIpController.dispose();
    super.dispose();
  }

  Future<void> _checkServerAvailability() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      isServerAvailable = false;
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
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('server_ip', newServerIp);
                Navigator.pop(context);
                await _checkServerAvailability();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Server IP Address cannot be empty')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/farm_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      children: [
                        // Header Section
                        Container(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.agriculture,
                                  size: 50,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Join SoilSync',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Start your farming journey',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Registration Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 26, 84, 29),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fill in your details to get started',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Personal Information Section
                                  _buildSectionTitle('Personal Information'),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _usernameController,
                                    label: 'Username',
                                    hint: 'johndoe123',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter a username';
                                      }
                                      if (value!.length < 3) {
                                        return 'Username must be at least 3 characters';
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9]+$')
                                          .hasMatch(value)) {
                                        return 'Username can only contain letters and numbers';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    hint: 'John Doe',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter your full name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hint: 'farmer@example.com',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value!)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    hint: '+63 912 345 6789',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter your phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  // Farm Information Section
                                  _buildSectionTitle('Farm Information'),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _farmNameController,
                                    label: 'Farm Name',
                                    hint: 'Green Valley Farm',
                                    icon: Icons.home_work_outlined,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter your farm name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _buildDropdownField(
                                    label: 'Primary Crop Type',
                                    icon: Icons.grass_outlined,
                                    value: _selectedCropType,
                                    items: _cropTypes,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCropType = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select your primary crop';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _farmSizeController,
                                    label: 'Farm Size (hectares)',
                                    hint: 'e.g., 5.5',
                                    icon: Icons.straighten_outlined,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter your farm size';
                                      }
                                      if (double.tryParse(value!) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  // Security Section
                                  _buildSectionTitle('Security'),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'At least 8 characters',
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter a password';
                                      }
                                      if (value!.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    hint: 'Re-enter your password',
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Terms and Conditions
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _agreeToTerms,
                                          onChanged: (value) {
                                            setState(() {
                                              _agreeToTerms = value ?? false;
                                            });
                                          },
                                          activeColor: const Color(0xFF2E7D32),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                            children: const [
                                              TextSpan(text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms of Service',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 26, 84, 29),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 26, 84, 29),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),

                                  // Register Button
                                  ElevatedButton(
                                    onPressed: _agreeToTerms && !_isLoading
                                        ? () {
                                            if (_formKey.currentState
                                                    ?.validate() ??
                                                false) {
                                              _handleRegistration();
                                            }
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      minimumSize:
                                          const Size(double.infinity, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Login Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account? ",
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Sign In',
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
              Positioned(
                top: 16,
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
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 26, 84, 29),
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF2E7D32)),
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
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      _showError('Please agree to the Terms of Service and Privacy Policy');
      return;
    }

    if (!isServerAvailable) {
      print('Server not available. Current server IP: $serverIp');
      _showError(
          'Server is not available. Please check your network settings.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final registerUrl = '$baseUrl/api/register/';

      print('Attempting registration to: $registerUrl');
      print('Username: ${_usernameController.text}');
      print('Email: ${_emailController.text}');
      print('Password length: ${_passwordController.text.length}');
      print('Role: user');

      final response = await http
          .post(
            Uri.parse(registerUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': _usernameController.text.trim(),
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
              'role': 'user',
            }),
          )
          .timeout(Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Registration successful');
        if (mounted) {
          _showSuccess(
              'Registration successful! Please login with your new account.');
          Navigator.pop(context); // Go back to login screen
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['detail'] ?? errorData['error'] ?? 'Registration failed!';
        print('Registration failed with error: $errorMessage');
        _showError(errorMessage);
      }
    } catch (e) {
      print('Error during registration: $e');
      String specificError =
          'Connection error. Please check your internet connection.';
      if (e is TimeoutException) {
        specificError = 'Connection to server timed out during registration.';
      } else if (e is SocketException) {
        specificError =
            'Could not connect to server during registration (Network Error).';
      } else if (e is http.ClientException) {
        specificError =
            'Network error during registration. Please check connection.';
      } else if (e is FormatException) {
        specificError = 'Received invalid data from server.';
      }
      _showError(specificError);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
