import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'config.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'services/weather_service.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _nitrogenController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _phController = TextEditingController();
  final _rainfallController = TextEditingController();
  bool _isLoading = false;
  bool _isAutomaticMode = true;
  String? _predictionResult;
  List<Map<String, dynamic>> _predictionHistory = [];
  List<Map<String, dynamic>>? _similarCases;
  Timer? _sensorTimer;
  bool _isPredicting = false;
  int _selectedIndex = 0;
  final WeatherService _weatherService = WeatherService();
  List<Map<String, dynamic>>? _latestTopCrops; // Store latest top crops

  @override
  void initState() {
    super.initState();
    _loadPredictionHistory();
    _getSensorData();
    _startSensorTimer();
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _phController.dispose();
    _rainfallController.dispose();
    super.dispose();
  }

  void _startSensorTimer() {
    // Cancel existing timer if any
    _sensorTimer?.cancel();

    // Start new timer that runs every 30 seconds
    _sensorTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isAutomaticMode && !_isPredicting) {
        _getSensorData();
      }
    });
  }

  Future<void> _loadPredictionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      print('Loading prediction history...');
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/predict/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Prediction history response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _predictionHistory = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('Error loading prediction history: ${response.body}');
      }
    } catch (e) {
      print('Error loading prediction history: $e');
    }
  }

  Future<void> _predictSoil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPredicting = true;
      _predictionResult = null;
      _similarCases = null;
      _latestTopCrops = null; // Reset before new prediction
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      final requestBody = {
        'nitrogen': double.parse(_nitrogenController.text),
        'phosphorus': double.parse(_phosphorusController.text),
        'potassium': double.parse(_potassiumController.text),
        'temperature': double.parse(_temperatureController.text),
        'humidity': double.parse(_humidityController.text),
        'ph': double.parse(_phController.text),
        'rainfall': double.parse(_rainfallController.text),
      };

      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/predict/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          _predictionResult = data['prediction'];
          _predictionHistory.insert(0, data['data']);
          _similarCases =
              List<Map<String, dynamic>>.from(data['similar_cases']);
          if (data['top_crops'] != null && data['top_crops'] is List) {
            _latestTopCrops =
                List<Map<String, dynamic>>.from(data['top_crops']);
          } else {
            _latestTopCrops = null;
          }
        });

        if (!_isAutomaticMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Prediction successful: ${data['prediction']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = json.decode(response.body);
        if (!_isAutomaticMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['error'] ?? 'Prediction failed!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!_isAutomaticMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isPredicting = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _getSensorData() async {
    if (_isPredicting) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get real rainfall data from weather API
      final weatherData =
          await _weatherService.getCurrentWeather(forceRefresh: true);

      print('Dashboard received rainfall data: $weatherData');

      // Generate mock data for soil parameters (nitrogen, phosphorus, potassium, pH)
      // In a real implementation, these would come from actual soil sensors
      setState(() {
        _nitrogenController.text =
            (20 + Random().nextDouble() * 10).toStringAsFixed(2);
        _phosphorusController.text =
            (30 + Random().nextDouble() * 20).toStringAsFixed(2);
        _potassiumController.text =
            (40 + Random().nextDouble() * 30).toStringAsFixed(2);

        // Use mock data for temperature and humidity (will be replaced by soil sensor)
        _temperatureController.text =
            (25 + Random().nextDouble() * 5).toStringAsFixed(2);
        _humidityController.text =
            (60 + Random().nextDouble() * 20).toStringAsFixed(2);
        _phController.text =
            (6.5 + Random().nextDouble() * 1.2).toStringAsFixed(2);

        // Use rainfall accumulation from weather API
        _rainfallController.text =
            (weatherData['rainfall_accumulation'] as double).toStringAsFixed(2);
      });

      // Automatically predict when in sensor mode
      if (_isAutomaticMode) {
        await _predictSoil();
      }
    } catch (e) {
      // Fallback to mock data if weather service fails
      setState(() {
        _nitrogenController.text =
            (20 + Random().nextDouble() * 10).toStringAsFixed(2);
        _phosphorusController.text =
            (30 + Random().nextDouble() * 20).toStringAsFixed(2);
        _potassiumController.text =
            (40 + Random().nextDouble() * 30).toStringAsFixed(2);
        _temperatureController.text =
            (25 + Random().nextDouble() * 5).toStringAsFixed(2);
        _humidityController.text =
            (60 + Random().nextDouble() * 20).toStringAsFixed(2);
        _phController.text =
            (6.5 + Random().nextDouble() * 1.5).toStringAsFixed(2);
        _rainfallController.text =
            (100 + Random().nextDouble() * 50).toStringAsFixed(2);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weather data unavailable, using fallback values: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: null,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[700],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'SoilSync',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.green[700]),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.green[700]),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.green[700]),
              title: Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await _logout();
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[700]!, Colors.green[50]!],
            stops: [0.0, 0.2],
          ),
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPredictionForm(),
                  SizedBox(height: 16),
                  _buildPredictionResult(),
                ],
              ),
            ),
            _buildPredictionHistory(),
            _buildAnalytics(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionForm() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isAutomaticMode ? 'Sensor Input Mode' : 'Manual Input Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Switch(
                  value: _isAutomaticMode,
                  onChanged: (value) {
                    setState(() {
                      _isAutomaticMode = value;
                      if (value) {
                        _getSensorData();
                        _startSensorTimer();
                      } else {
                        _sensorTimer?.cancel();
                      }
                    });
                  },
                  activeColor: Colors.green[700],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              _isAutomaticMode
                  ? 'Reading soil parameters from sensors...'
                  : 'Enter soil parameters manually',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (_isAutomaticMode) ...[
              SizedBox(height: 8),
              Text(
                'Auto-refreshing every 30 seconds',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInputField(
                    controller: _nitrogenController,
                    label: 'Nitrogen (N)',
                    icon: Icons.science,
                    unit: 'mg/kg',
                  ),
                  _buildInputField(
                    controller: _phosphorusController,
                    label: 'Phosphorus (P)',
                    icon: Icons.science,
                    unit: 'mg/kg',
                  ),
                  _buildInputField(
                    controller: _potassiumController,
                    label: 'Potassium (K)',
                    icon: Icons.science,
                    unit: 'mg/kg',
                  ),
                  _buildInputField(
                    controller: _temperatureController,
                    label: 'Temperature',
                    icon: Icons.thermostat,
                    unit: '°C',
                  ),
                  _buildInputField(
                    controller: _humidityController,
                    label: 'Humidity',
                    icon: Icons.water_drop,
                    unit: '%',
                  ),
                  _buildInputField(
                    controller: _phController,
                    label: 'pH',
                    icon: Icons.science,
                    unit: '',
                  ),
                  _buildInputField(
                    controller: _rainfallController,
                    label: 'Rainfall',
                    icon: Icons.water,
                    unit: 'mm',
                  ),
                  SizedBox(height: 20),
                  if (!_isAutomaticMode)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _predictSoil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Predict Crop',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  if (_isAutomaticMode)
                    Text(
                      'Predictions are automatic in sensor mode',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionResult() {
    if (_predictionResult == null) {
      return Center(
        child: Text(
          'No prediction yet',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prediction Result',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.green[700], size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _predictionResult!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Recommended Crop',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionHistory() {
    if (_predictionHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No prediction history yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _predictionHistory.length,
      itemBuilder: (context, index) {
        final prediction = _predictionHistory[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Icon(Icons.history, color: Colors.green[700]),
            ),
            title: Text(
              prediction['prediction'] ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green[900],
              ),
            ),
            subtitle: Text(
              'Date: ' + _formatPredictionDate(prediction),
              style: TextStyle(color: Colors.grey[600]),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHistoryDetailRow(
                        'Nitrogen', '${prediction['nitrogen']} mg/kg'),
                    _buildHistoryDetailRow(
                        'Phosphorus', '${prediction['phosphorus']} mg/kg'),
                    _buildHistoryDetailRow(
                        'Potassium', '${prediction['potassium']} mg/kg'),
                    _buildHistoryDetailRow(
                        'Temperature', '${prediction['temperature']}°C'),
                    _buildHistoryDetailRow(
                        'Humidity', '${prediction['humidity']}%'),
                    _buildHistoryDetailRow('pH', prediction['ph'].toString()),
                    _buildHistoryDetailRow(
                        'Rainfall', '${prediction['rainfall']} mm'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatPredictionDate(Map<String, dynamic> prediction) {
    final dateStr = prediction['created_at'] ??
        prediction['created'] ??
        prediction['timestamp'] ??
        prediction['date'];
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  Widget _buildHistoryDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    if (_predictionResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Make a prediction to see analytics',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Use _latestTopCrops for analytics
    final List<Map<String, dynamic>>? topCropsFromState = _latestTopCrops;

    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top 5 Crops Card
          if (topCropsFromState != null && topCropsFromState.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recommended Crops',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Based on soil analysis',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...topCropsFromState.asMap().entries.take(5).map((entry) {
                      final crop = entry.value;
                      final index = entry.key;
                      final confidenceScore = crop['confidence'] != null
                          ? (crop['confidence'] * 100).toStringAsFixed(1)
                          : 'N/A';

                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crop['label']?.toString() ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[900],
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$confidenceScore% confidence',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.green[900],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          unit,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEnvironmentItem(
      String label, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color[700], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color[700],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String unit,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          prefixIcon: Icon(icon, color: Colors.green[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green[700]!),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }
}
