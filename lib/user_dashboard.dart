import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/sensor_bus.dart';
import 'screens/enhanced_login_screen.dart';
import 'config.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'services/weather_service.dart';
import 'widgets/location_settings_widget.dart'; // Add this import
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'screens/crop_search_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with WidgetsBindingObserver {
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

  // Add ESP32 IP address here (update as needed)
  String esp32Ip = '';
  Timer? _esp32Timer;

  // Soil sensor values
  double? soilMoisture;
  double? soilTemperature;
  double? soilPh;
  int? soilNitrogen;
  int? soilPhosphorus;
  int? soilPotassium;
  String esp32Status = 'Unknown'; // Connected, Disconnected, Error

  // Bluetooth fields
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? btConnection;
  List<BluetoothDevice> btDevicesList = [];
  BluetoothDevice? btSelectedDevice;
  bool btIsConnecting = false;
  bool btIsConnected = false;
  String btStatus = 'Idle';
  static const String _lastDeviceKey = 'last_connected_bt_device';

  // Discovery
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;
  List<BluetoothDiscoveryResult> _discoveredDevices = [];
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    _loadPredictionHistory();
    _getSensorData();
    _startSensorTimer();
    _btRequestPermissions().then((granted) {
      if (granted) {
        _btGetBondedDevices();
        // _btAutoConnectLastDevice(); // Removed auto-connect on startup
      } else {
        setState(() {
          btStatus =
              'Bluetooth permissions denied. Please enable permissions in app settings.';
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getSensorData();
  }

  // Remove _autoDetectEsp32AndStartTimer and findEsp32Ip methods

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _sensorTimer?.cancel();
    _esp32Timer?.cancel();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _phController.dispose();
    _rainfallController.dispose();
    _discoveryStreamSubscription?.cancel();
    btConnection?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When returning to the dashboard, refresh weather data
      _getSensorData();
    }
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

  void _startEsp32Timer() {
    print('Starting ESP32 timer');
    _esp32Timer?.cancel();
    _esp32Timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchEsp32SensorData();
    });
    _fetchEsp32SensorData();
  }

  Future<void> _loadPredictionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EnhancedLoginScreen()),
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
          // Convert all predictions in the history to crop names
          _predictionHistory =
              List<Map<String, dynamic>>.from(data).map((item) {
            final convertedItem = Map<String, dynamic>.from(item);
            convertedItem['prediction'] =
                _convertCropIdToName(item['prediction']?.toString() ?? '');
            return convertedItem;
          }).toList();
        });
      } else {
        print('Error loading prediction history: ${response.body}');
      }
    } catch (e) {
      print('Error loading prediction history: $e');
    }
  }

  Future<void> _predictSoil() async {
    // Prevent prediction in sensor input mode if sensor is disconnected
    if (_isAutomaticMode && !btIsConnected) {
      setState(() {
        _predictionResult = null;
        _latestTopCrops = null;
      });
      return;
    }
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
          MaterialPageRoute(builder: (context) => const EnhancedLoginScreen()),
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
          _predictionResult =
              _convertCropIdToName(data['prediction']?.toString() ?? '');
          // Convert the prediction in the data before adding to history
          final historyData = Map<String, dynamic>.from(data['data']);
          historyData['prediction'] =
              _convertCropIdToName(data['prediction']?.toString() ?? '');
          _predictionHistory.insert(0, historyData);
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
              content: Text(
                  'Prediction successful: ${_convertCropIdToName(data['prediction']?.toString() ?? '')}'),
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
      MaterialPageRoute(builder: (context) => const EnhancedLoginScreen()),
    );
  }

  Future<void> _getSensorData() async {
    if (_isPredicting) return;
    if (!_isAutomaticMode) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      // If in sensor input mode and sensor is disconnected, do not predict
      if (_isAutomaticMode && !btIsConnected) {
        setState(() {
          _predictionResult = null;
          _latestTopCrops = null;
        });
        return;
      }
      // Add debug print before weather API call
      print('Calling weather API for rainfall...');
      // Get real rainfall data from weather API
      final weatherData =
          await _weatherService.getCurrentWeather(forceRefresh: true);
      print('Weather data fetched: $weatherData');
      setState(() {
        if (soilNitrogen != null &&
            soilPhosphorus != null &&
            soilPotassium != null &&
            soilTemperature != null &&
            soilMoisture != null &&
            soilPh != null) {
          if (_isAutomaticMode) {
            _nitrogenController.text = soilNitrogen.toString();
            _phosphorusController.text = soilPhosphorus.toString();
            _potassiumController.text = soilPotassium.toString();
            _temperatureController.text = soilTemperature.toString();
            _humidityController.text = soilMoisture.toString();
            _phController.text = soilPh.toString();
          }
          soilMoisture = soilMoisture;
          soilTemperature = soilTemperature;
          soilPh = soilPh;
          soilNitrogen = soilNitrogen;
          soilPhosphorus = soilPhosphorus;
          soilPotassium = soilPotassium;
        } else {
          if (_isAutomaticMode) {
            _nitrogenController.text = '0';
            _phosphorusController.text = '0';
            _potassiumController.text = '0';
            _temperatureController.text = '0';
            _humidityController.text = '0';
            _phController.text = '0';
          }
          soilMoisture = 0;
          soilTemperature = 0;
          soilPh = 0;
          soilNitrogen = 0;
          soilPhosphorus = 0;
          soilPotassium = 0;
        }
        // Set rainfall from API robustly
        final rainfall = weatherData['rainfall'];
        print('Rainfall from API: $rainfall');
        if (rainfall != null && rainfall is num) {
          if (_isAutomaticMode) {
            _rainfallController.text = rainfall.toStringAsFixed(2);
          }
        } else {
          if (_isAutomaticMode) {
            _rainfallController.text = '0.00';
          }
        }
      });
      if (_isAutomaticMode) {
        await _predictSoil();
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startDiscovery() {
    _discoveryStreamSubscription?.cancel();
    setState(() {
      _discoveredDevices.clear();
      _isDiscovering = true;
    });
    _discoveryStreamSubscription = bluetooth.startDiscovery().listen((r) {
      setState(() {
        // Avoid duplicates by address
        if (!_discoveredDevices
            .any((d) => d.device.address == r.device.address)) {
          _discoveredDevices.add(r);
        }
      });
    }, onError: (e) {
      setState(() {
        _isDiscovering = false;
      });
    }, onDone: () {
      setState(() {
        _isDiscovering = false;
      });
    });
    // Add a manual timeout as a fallback
    Future.delayed(Duration(seconds: 15), () {
      if (_isDiscovering) {
        _discoveryStreamSubscription?.cancel();
        setState(() {
          _isDiscovering = false;
        });
      }
    });
  }

  void _pairDevice(BluetoothDevice device) async {
    try {
      bool bonded = false;
      if (!device.isBonded) {
        bonded = (await FlutterBluetoothSerial.instance
                .bondDeviceAtAddress(device.address)) ==
            true;
      }
      if (bonded) {
        await _btGetBondedDevices();
        _startDiscovery(); // Restart discovery to update discovered devices
        setState(() {
          btStatus = 'Device paired!';
        });
      } else {
        setState(() {
          btStatus = 'Pairing failed or cancelled.';
        });
      }
    } catch (e) {
      setState(() {
        btStatus = 'Pairing error: $e';
      });
    }
  }

  // Add unpair method
  void _unpairDevice(BluetoothDevice device) async {
    try {
      bool removed = (await FlutterBluetoothSerial.instance
              .removeDeviceBondWithAddress(device.address)) ==
          true;
      if (removed) {
        await _btGetBondedDevices();
        _startDiscovery(); // Restart discovery to update discovered devices
        setState(() {
          btStatus = 'Device unpaired!';
        });
        // Show user-friendly dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Device Unpaired'),
              content: Text(
                  'If you don\'t see your device in the list, restart your ESP32 and tap Scan again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          btStatus = 'Failed to unpair device.';
        });
      }
    } catch (e) {
      setState(() {
        btStatus = 'Unpairing error: $e';
      });
    }
  }

  // --- Sensor Page Widget ---
  Widget _buildSensorPage() {
    return BluetoothClassicSensorPage(
      devicesList: btDevicesList,
      discoveredDevices: _discoveredDevices,
      isConnected: btIsConnected,
      isConnecting: btIsConnecting,
      selectedDevice: btSelectedDevice,
      status: btStatus,
      isDiscovering: _isDiscovering,
      onRefresh: _btGetBondedDevices,
      onScan: _startDiscovery,
      onConnect: _btConnect,
      onDisconnect: _btDisconnect,
      onPair: _pairDevice,
      onUnpair: _unpairDevice,
    );
  }

  Future<void> _fetchEsp32SensorData() async {
    print('Calling _fetchEsp32SensorData()');
    try {
      print('ESP32 IP: $esp32Ip');
      final response = await http
          .get(Uri.parse('http://$esp32Ip/sensor'))
          .timeout(Duration(seconds: 35));
      print('ESP32 response: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed ESP32 data: $data');
        setState(() {
          soilMoisture = (data['moisture'] as num?)?.toDouble();
          soilTemperature = (data['temperature'] as num?)?.toDouble();
          soilPh = (data['ph'] as num?)?.toDouble();
          soilNitrogen = (data['nitrogen'] as num?)?.toInt();
          soilPhosphorus = (data['phosphorus'] as num?)?.toInt();
          soilPotassium = (data['potassium'] as num?)?.toInt();
          esp32Status = 'Connected';
          if (_isAutomaticMode) {
            _nitrogenController.text = soilNitrogen?.toString() ?? '';
            _phosphorusController.text = soilPhosphorus?.toString() ?? '';
            _potassiumController.text = soilPotassium?.toString() ?? '';
            _temperatureController.text = soilTemperature?.toString() ?? '';
            _phController.text = soilPh?.toString() ?? '';
            _humidityController.text = soilMoisture?.toString() ?? '';
          }
        });
        print(
            'Set state: $soilMoisture, $soilTemperature, $soilPh, $soilNitrogen, $soilPhosphorus, $soilPotassium');
      } else {
        setState(() {
          esp32Status = 'Error';
          soilMoisture = 0;
          soilTemperature = 0;
          soilPh = 0;
          soilNitrogen = 0;
          soilPhosphorus = 0;
          soilPotassium = 0;
        });
      }
    } catch (e) {
      print('ESP32 fetch error: $e');
      setState(() {
        esp32Status = 'Disconnected';
        soilMoisture = 0;
        soilTemperature = 0;
        soilPh = 0;
        soilNitrogen = 0;
        soilPhosphorus = 0;
        soilPotassium = 0;
      });
    }
  }

  // Bluetooth helper methods
  Future<bool> _btRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    bool allGranted = statuses.values.every((s) => s.isGranted);
    return allGranted;
  }

  Future<void> _btGetBondedDevices() async {
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      setState(() {
        btDevicesList = devices;
        btStatus = btDevicesList.isEmpty
            ? 'No paired Bluetooth devices found. Pair in Bluetooth settings.'
            : 'Select device to connect.';
      });
    } catch (e) {
      setState(() {
        btStatus = 'Failed to get paired devices: $e';
      });
    }
  }

  Future<void> _btAutoConnectLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAddress = prefs.getString(_lastDeviceKey);
    if (lastAddress != null && btDevicesList.isNotEmpty) {
      final device = btDevicesList.firstWhere(
        (d) => d.address == lastAddress,
        orElse: () => btDevicesList.first,
      );
      if (!btIsConnected && !btIsConnecting) {
        _btConnect(device, auto: true);
      }
    }
  }

  void _btConnect(BluetoothDevice device, {bool auto = false}) async {
    if (btIsConnecting || btIsConnected) return;
    setState(() {
      btIsConnecting = true;
      btStatus = auto ? 'Auto-connecting...' : 'Connecting...';
      btSelectedDevice = device;
    });
    try {
      btConnection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        btIsConnected = true;
        btIsConnecting = false;
        btStatus = 'Connected! Waiting for data...';
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastDeviceKey, device.address);
      btConnection!.input!.listen(_btOnDataReceived).onDone(() {
        setState(() {
          btIsConnected = false;
          btStatus = 'Disconnected.';
        });
      });
    } catch (e) {
      setState(() {
        btIsConnecting = false;
        btStatus = 'Connection failed: $e';
      });
      if (auto) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_lastDeviceKey);
      }
    }
  }

  void _btDisconnect() async {
    await btConnection?.close();
    setState(() {
      btIsConnected = false;
      btStatus = 'Disconnected.';
      btSelectedDevice = null;
      // Reset sensor values and controllers to zero
      soilMoisture = 0;
      soilTemperature = 0;
      soilPh = 0;
      soilNitrogen = 0;
      soilPhosphorus = 0;
      soilPotassium = 0;
      _nitrogenController.text = '0';
      _phosphorusController.text = '0';
      _potassiumController.text = '0';
      _temperatureController.text = '0';
      _phController.text = '0';
      _humidityController.text = '0';
    });
  }

  void _btOnDataReceived(Uint8List data) {
    String dataStr = String.fromCharCodes(data).trim();
    for (var line in dataStr.split('\n')) {
      var parts = line.split(',');
      if (parts.length == 6) {
        setState(() {
          soilMoisture = double.tryParse(parts[0]);
          soilTemperature = double.tryParse(parts[1]);
          soilPh = double.tryParse(parts[2]);
          soilNitrogen = int.tryParse(parts[3]);
          soilPhosphorus = int.tryParse(parts[4]);
          soilPotassium = int.tryParse(parts[5]);
          // Update controllers for live display
          if (_isAutomaticMode) {
            _nitrogenController.text = soilNitrogen?.toString() ?? '';
            _phosphorusController.text = soilPhosphorus?.toString() ?? '';
            _potassiumController.text = soilPotassium?.toString() ?? '';
            _temperatureController.text = soilTemperature?.toString() ?? '';
            _phController.text = soilPh?.toString() ?? '';
            _humidityController.text = soilMoisture?.toString() ?? '';
          }
        });

        // Publish reading to SensorBus for auto-collection consumers
        final n = (soilNitrogen ?? 0).toDouble();
        final p = (soilPhosphorus ?? 0).toDouble();
        final k = (soilPotassium ?? 0).toDouble();
        final t = soilTemperature ?? 0.0;
        final h = soilMoisture ?? 0.0; // treat moisture as humidity input
        final phVal = soilPh ?? 7.0;
        final rainfall = 0.0; // not provided by BT payload; default to 0
        SensorBus.instance.publish(SensorReading(
          nitrogen: n,
          phosphorus: p,
          potassium: k,
          temperature: t,
          humidity: h,
          ph: phVal,
          rainfall: rainfall,
        ));
      }
    }
  }

  // Helper method to convert crop ID to crop name
  String _convertCropIdToName(String cropIdOrName) {
    // If it's already a valid crop name, return as is
    final availableCrops = [
      'rice',
      'maize',
      'chickpea',
      'kidneybeans',
      'pigeonpeas',
      'mothbeans',
      'blackgram',
      'lentil',
      'pomegranate',
      'banana',
      'mango',
      'grapes',
      'watermelon',
      'muskmelon',
      'apple',
      'orange',
      'papaya',
      'coconut',
      'cotton',
      'jute',
      'coffee'
    ];

    final lowerCropIdOrName = cropIdOrName.toLowerCase().trim();
    if (availableCrops.contains(lowerCropIdOrName)) {
      return lowerCropIdOrName;
    }

    // If it's a number, try to map it to a crop name
    final cropId = int.tryParse(cropIdOrName);
    if (cropId != null && cropId >= 0 && cropId < availableCrops.length) {
      return availableCrops[cropId];
    }

    // Fallback: return the original value
    return cropIdOrName;
  }

  // Helper method to get crop icon path
  String _getCropIconPath(String cropName) {
    // Convert crop name to lowercase and handle special cases
    final normalizedName = cropName.toLowerCase().trim();

    // Map crop names to their corresponding asset file names
    final cropIconMap = {
      'apple': 'assets/icons/apple.png',
      'banana': 'assets/icons/banana.png',
      'blackgram': 'assets/icons/black gram.png',
      'black gram': 'assets/icons/black gram.png',
      'chickpea': 'assets/icons/chickpea.png',
      'coconut': 'assets/icons/coconut.png',
      'coffee': 'assets/icons/coffee.png',
      'corn': 'assets/icons/corn.png',
      'maize': 'assets/icons/corn.png', // Alternative name for corn
      'cotton': 'assets/icons/cotton.png',
      'grapes': 'assets/icons/grapes.png',
      'jute': 'assets/icons/jute.png',
      'kidneybeans': 'assets/icons/kidneybeans.png',
      'kidney beans': 'assets/icons/kidneybeans.png',
      'lentil': 'assets/icons/lentil.png',
      'mango': 'assets/icons/mango.png',
      'mothbeans': 'assets/icons/mothbeans.png',
      'moth beans': 'assets/icons/mothbeans.png',
      'mungbean': 'assets/icons/mung bean.png',
      'mung bean': 'assets/icons/mung bean.png',
      'muskmelon': 'assets/icons/muskmelon.png',
      'orange': 'assets/icons/orange.png',
      'papaya': 'assets/icons/papaya.png',
      'pigeonpeas': 'assets/icons/pigeonpeas.png',
      'pigeon peas': 'assets/icons/pigeonpeas.png',
      'pomegranate': 'assets/icons/pomegranate.png',
      'rice': 'assets/icons/rice.png',
      'watermelon': 'assets/icons/watermelon.png',
    };

    return cropIconMap[normalizedName] ??
        'assets/icons/rice.png'; // Default to rice icon
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove hamburger/back button
        title: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to eco icon if image fails to load
                    return Icon(Icons.eco, color: Colors.white, size: 24);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SoilSync',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CropSearchScreen(),
                ),
              );
            },
            tooltip: 'Search Crops',
          ),
        ],
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
                  GestureDetector(
                    onTap: _predictionResult != null
                        ? () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24)),
                              ),
                              builder: (context) => Padding(
                                padding: const EdgeInsets.only(
                                    top: 16, left: 12, right: 12, bottom: 24),
                                child: _buildAnalytics(),
                              ),
                            );
                          }
                        : null,
                    child: _buildPredictionResult(),
                  ),
                ],
              ),
            ),
            // Insert Sensor page between Home and History
            _buildSensorPage(),
            _buildPredictionHistory(),
            ProfilePage(),
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
            icon: Icon(Icons.sensors),
            label: 'Sensor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDataCard() {
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
            Text('Soil Sensor (ESP32)',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700])),
            SizedBox(height: 12),
            _buildSensorRow('Moisture', soilMoisture, '%'),
            _buildSensorRow('Temperature', soilTemperature, '°C'),
            _buildSensorRow('pH', soilPh, ''),
            _buildSensorRow('Nitrogen', soilNitrogen, 'mg/kg'),
            _buildSensorRow('Phosphorus', soilPhosphorus, 'mg/kg'),
            _buildSensorRow('Potassium', soilPotassium, 'mg/kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, dynamic value, String unit) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          Text(
            value != null ? '$value $unit' : '--',
            style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionForm() {
    return Card(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isAutomaticMode ? 'Sensor Input Mode' : 'Manual Input Mode',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double gridWidth = constraints.maxWidth;
                    return Column(
                      children: [
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(1),
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            TableRow(children: [
                              _buildSquareInputField(
                                controller: _nitrogenController,
                                label: 'Nitrogen (N)',
                                icon: Icons.science,
                                unit: 'mg/kg',
                              ),
                              _buildSquareInputField(
                                controller: _phosphorusController,
                                label: 'Phosphorus (P)',
                                icon: Icons.science,
                                unit: 'mg/kg',
                              ),
                            ]),
                            TableRow(children: [
                              _buildSquareInputField(
                                controller: _potassiumController,
                                label: 'Potassium (K)',
                                icon: Icons.science,
                                unit: 'mg/kg',
                              ),
                              _buildSquareInputField(
                                controller: _phController,
                                label: 'pH',
                                icon: Icons.science,
                                unit: '',
                              ),
                            ]),
                            TableRow(children: [
                              _buildSquareInputField(
                                controller: _temperatureController,
                                label: 'Temperature',
                                icon: Icons.thermostat,
                                unit: '°C',
                              ),
                              _buildSquareInputField(
                                controller: _humidityController,
                                label: 'Humidity',
                                icon: Icons.water_drop,
                                unit: '%',
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 0),
                        SizedBox(
                          width: gridWidth,
                          child: _buildFullWidthInputField(
                            controller: _rainfallController,
                            label: 'Rainfall',
                            icon: Icons.water,
                            unit: 'mm',
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_isAutomaticMode)
                          SizedBox(
                            width: gridWidth,
                            child: ElevatedButton.icon(
                              onPressed: _isPredicting ? null : _predictSoil,
                              icon: _isPredicting
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Icon(Icons.analytics),
                              label: Text(
                                  _isPredicting ? 'Predicting...' : 'Predict'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New: Square input field builder for Wrap
  Widget _buildSquareInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String unit,
  }) {
    final double size = (MediaQuery.of(context).size.width - 64) / 2;
    final bool isReadOnly = _isAutomaticMode && label != 'Rainfall';
    final String value = controller.text;

    return SizedBox(
      width: size,
      height: size,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              if (isReadOnly)
                Column(
                  children: [
                    Text(
                      value.isEmpty ? '--' : value,
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (unit.isNotEmpty)
                      Text(
                        unit,
                        style: TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                  ],
                )
              else
                Column(
                  children: [
                    TextFormField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '';
                        if (double.tryParse(value) == null) return '';
                        return null;
                      },
                    ),
                    if (unit.isNotEmpty)
                      Text(
                        unit,
                        style: TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this new builder for the full-width rainfall card
  Widget _buildFullWidthInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String unit,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Builder(
              builder: (context) {
                final bool isReadOnly = _isAutomaticMode;
                final String value = controller.text;
                if (isReadOnly) {
                  return Column(
                    children: [
                      Text(
                        value.isEmpty ? '--' : value,
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (unit.isNotEmpty)
                        Text(
                          unit,
                          style: TextStyle(fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      TextFormField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return '';
                          if (double.tryParse(value) == null) return '';
                          return null;
                        },
                      ),
                      if (unit.isNotEmpty)
                        Text(
                          unit,
                          style: TextStyle(fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  );
                }
              },
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        _getCropIconPath(_predictionResult!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to eco icon if image fails to load
                          return Icon(Icons.eco,
                              color: Colors.green[700], size: 32);
                        },
                      ),
                    ),
                  ),
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
              child: Image.asset(
                _getCropIconPath(_convertCropIdToName(
                    prediction['prediction']?.toString() ?? '')),
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.eco, color: Colors.green[700]);
                },
              ),
            ),
            title: Text(
              _convertCropIdToName(prediction['prediction']?.toString() ?? ''),
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
                                    _convertCropIdToName(
                                        crop['label']?.toString() ?? 'Unknown'),
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
    bool? enabled,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: true,
        readOnly: _isAutomaticMode,
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

class BluetoothClassicSensorPage extends StatelessWidget {
  final List<BluetoothDevice> devicesList;
  final List<BluetoothDiscoveryResult> discoveredDevices;
  final bool isConnected;
  final bool isConnecting;
  final BluetoothDevice? selectedDevice;
  final String status;
  final bool isDiscovering;
  final VoidCallback onRefresh;
  final VoidCallback onScan;
  final Function(BluetoothDevice, {bool auto}) onConnect;
  final VoidCallback onDisconnect;
  final Function(BluetoothDevice) onPair;
  final Function(BluetoothDevice) onUnpair;

  const BluetoothClassicSensorPage({
    Key? key,
    required this.devicesList,
    required this.discoveredDevices,
    required this.isConnected,
    required this.isConnecting,
    required this.selectedDevice,
    required this.status,
    required this.isDiscovering,
    required this.onRefresh,
    required this.onScan,
    required this.onConnect,
    required this.onDisconnect,
    required this.onPair,
    required this.onUnpair,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Merge paired and discovered devices, prefer paired
    final Map<String, BluetoothDevice> allDevices = {};
    for (var d in devicesList) {
      allDevices[d.address] = d;
    }
    for (var r in discoveredDevices) {
      if (!allDevices.containsKey(r.device.address)) {
        allDevices[r.device.address] = r.device;
      }
    }
    final mergedDeviceList = allDevices.values.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bluetooth Soil Sensor (Classic)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          if (!isConnected) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnecting ? null : onRefresh,
                    icon: Icon(Icons.refresh),
                    label: Text('Refresh Paired'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isDiscovering ? null : onScan,
                    icon: Icon(Icons.search),
                    label: Text(isDiscovering ? 'Scanning...' : 'Scan'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (mergedDeviceList.isEmpty)
              Text('No paired or discovered Bluetooth devices found.'),
            if (mergedDeviceList.isNotEmpty)
              ...mergedDeviceList.map((d) => ListTile(
                    title: Text(d.name?.isNotEmpty == true
                        ? d.name!
                        : "Unknown Device"),
                    subtitle: d.isBonded ? Text('Paired') : Text('Unpaired'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (d.isBonded)
                          ElevatedButton(
                            onPressed: isConnecting
                                ? null
                                : () => onConnect(d, auto: false),
                            child: Text(isConnecting && selectedDevice == d
                                ? 'Connecting...'
                                : 'Connect'),
                          ),
                        if (!d.isBonded)
                          ElevatedButton(
                            onPressed: () => onPair(d),
                            child: Text('Pair'),
                          ),
                        if (d.isBonded) SizedBox(width: 8),
                        if (d.isBonded)
                          ElevatedButton(
                            onPressed: () => onUnpair(d),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                      ],
                    ),
                  )),
            SizedBox(height: 12),
            Text('Status: $status', style: TextStyle(fontSize: 16)),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Connected to ${selectedDevice?.name ?? "Unknown"}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green[700])),
                ElevatedButton(
                  onPressed: onDisconnect,
                  child: Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Status: $status', style: TextStyle(fontSize: 16)),
          ]
        ],
      ),
    );
  }
}
