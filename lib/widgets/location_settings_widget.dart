import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/location_data_service.dart'; // Added import for LocationDataService

class LocationSettingsWidget extends StatefulWidget {
  const LocationSettingsWidget({Key? key}) : super(key: key);

  @override
  State<LocationSettingsWidget> createState() => _LocationSettingsWidgetState();
}

class _LocationSettingsWidgetState extends State<LocationSettingsWidget>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;
  String? _currentLocation;

  // --- Location (Philippines) state ---
  Map<String, dynamic> _locationData = {};
  String _selectedRegionCode = '01';
  String _selectedProvince = 'PANGASINAN';
  String _selectedCity = 'BAYAMBANG';
  bool _locationLoaded = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _initLocationData();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _regionController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final location = await _locationService.getLocationFromSettings();
      if (location != null) {
        _latitudeController.text =
            location['latitude']?.toStringAsFixed(6) ?? '14.5995';
        _longitudeController.text =
            location['longitude']?.toStringAsFixed(6) ?? '120.9842';
        _regionController.text = location['region'] as String? ?? 'NCR';
        _provinceController.text =
            location['province'] as String? ?? 'Metro Manila';
        _cityController.text = location['city'] as String? ?? 'Manila';
        _currentLocation =
            '${location['latitude']?.toStringAsFixed(4) ?? '14.5995'}, ${location['longitude']?.toStringAsFixed(4) ?? '120.9842'}';
      } else {
        // Try to get device location
        final deviceLocation = await _locationService.getCurrentLocation();
        _latitudeController.text =
            deviceLocation['latitude']?.toStringAsFixed(6) ?? '14.5995';
        _longitudeController.text =
            deviceLocation['longitude']?.toStringAsFixed(6) ?? '120.9842';
        _regionController.text = deviceLocation['region'] as String? ?? 'NCR';
        _provinceController.text =
            deviceLocation['province'] as String? ?? 'Metro Manila';
        _cityController.text = deviceLocation['city'] as String? ?? 'Manila';
        _currentLocation =
            '${deviceLocation['latitude']?.toStringAsFixed(4) ?? '14.5995'}, ${deviceLocation['longitude']?.toStringAsFixed(4) ?? '120.9842'}';
      }
    } catch (e) {
      // Use default location
      _latitudeController.text = '14.5995';
      _longitudeController.text = '120.9842';
      _regionController.text = 'NCR';
      _provinceController.text = 'Metro Manila';
      _cityController.text = 'Manila';
      _currentLocation = '14.5995, 120.9842 (Manila)';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLocation() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
          'user_latitude', double.parse(_latitudeController.text));
      await prefs.setDouble(
          'user_longitude', double.parse(_longitudeController.text));
      await prefs.setString('user_region', _regionController.text);
      await prefs.setString('user_province', _provinceController.text);
      await prefs.setString('user_city', _cityController.text);

      setState(() {
        _currentLocation =
            '${_latitudeController.text}, ${_longitudeController.text}';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location settings saved!')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save location: $e')),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final location = await _locationService.getCurrentLocation();
      _latitudeController.text =
          location['latitude']?.toStringAsFixed(6) ?? '14.5995';
      _longitudeController.text =
          location['longitude']?.toStringAsFixed(6) ?? '120.9842';
      _regionController.text = location['region'] as String? ?? 'NCR';
      _provinceController.text =
          location['province'] as String? ?? 'Metro Manila';
      _cityController.text = location['city'] as String? ?? 'Manila';
      setState(() {
        _currentLocation =
            '${location['latitude']?.toStringAsFixed(4) ?? '14.5995'}, ${location['longitude']?.toStringAsFixed(4) ?? '120.9842'}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '📍 Using current location: ${location['latitude']?.toStringAsFixed(4) ?? '14.5995'}, ${location['longitude']?.toStringAsFixed(4) ?? '120.9842'}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      _showError('Error getting current location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLocation() async {
    await _locationService.clearLocationFromSettings();
    setState(() {
      _currentLocation = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Location cleared from settings'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _initLocationData() async {
    final data = await LocationDataService().getLocationData();
    setState(() {
      _locationData = data;
      _locationLoaded = true;
    });
    _loadLocationFromPrefs();
  }

  Future<void> _loadLocationFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRegionCode = prefs.getString('region_code') ?? '01';
      List<String> provinces = _getProvinces();
      _selectedProvince = provinces.contains(prefs.getString('province'))
          ? prefs.getString('province')!
          : (provinces.isNotEmpty ? provinces[0] : '');
      List<String> cities = _getCities();
      _selectedCity = cities.contains(prefs.getString('city'))
          ? prefs.getString('city')!
          : (cities.isNotEmpty ? cities[0] : '');
    });
  }

  Future<void> _savePhilippinesLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('region_code', _selectedRegionCode);
    await prefs.setString('province', _selectedProvince);
    await prefs.setString('city', _selectedCity);

    // Look up coordinates for the selected city
    final coords = _getCoordinatesForSelectedCity();
    if (coords != null && coords['lat'] != null && coords['lon'] != null) {
      await prefs.setDouble('user_latitude', coords['lat']!);
      await prefs.setDouble('user_longitude', coords['lon']!);
      // Synchronize the custom tab fields
      setState(() {
        _latitudeController.text = coords['lat']!.toStringAsFixed(6);
        _longitudeController.text = coords['lon']!.toStringAsFixed(6);
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Philippines location saved!')),
    );
  }

  /// Helper to get coordinates for the selected city from _locationData
  Map<String, double>? _getCoordinatesForSelectedCity() {
    try {
      final cityData = _locationData[_selectedRegionCode]['province_list']
          [_selectedProvince]['municipality_list'][_selectedCity];
      if (cityData != null &&
          cityData['lat'] != null &&
          cityData['lon'] != null) {
        return {
          'lat': (cityData['lat'] as num).toDouble(),
          'lon': (cityData['lon'] as num).toDouble(),
        };
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  List<String> _getRegionCodes() {
    return _locationData.keys.toList();
  }

  String _getRegionName(String code) {
    return _locationData[code]?['region_name'] ?? code;
  }

  List<String> _getProvinces() {
    if (_locationData[_selectedRegionCode]?['province_list'] == null) return [];
    return (_locationData[_selectedRegionCode]['province_list']
            as Map<String, dynamic>)
        .keys
        .toList();
  }

  List<String> _getCities() {
    if (_locationData[_selectedRegionCode]?['province_list']?[_selectedProvince]
            ?['municipality_list'] ==
        null) return [];
    return (_locationData[_selectedRegionCode]['province_list']
            [_selectedProvince]['municipality_list'] as Map<String, dynamic>)
        .keys
        .toList();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Settings'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TabBar for location mode ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.green[700],
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    indicatorPadding: const EdgeInsets.all(2),
                    tabs: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Set Location'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Custom'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 621, // increased by 21 pixels
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // --- Location (Philippines) Section ---
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: !_locationLoaded
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location (Philippines)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedRegionCode,
                                    decoration: const InputDecoration(
                                      labelText: 'Region',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _getRegionCodes()
                                        .map((code) => DropdownMenuItem(
                                              value: code,
                                              child: Text(_getRegionName(code)),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null &&
                                          value != _selectedRegionCode) {
                                        setState(() {
                                          _selectedRegionCode = value;
                                          final provinces = _getProvinces();
                                          _selectedProvince =
                                              provinces.isNotEmpty
                                                  ? provinces[0]
                                                  : '';
                                          final cities = _getCities();
                                          _selectedCity = cities.isNotEmpty
                                              ? cities[0]
                                              : '';
                                          _savePhilippinesLocation();
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _selectedProvince,
                                    decoration: const InputDecoration(
                                      labelText: 'Province',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _getProvinces()
                                        .map((province) => DropdownMenuItem(
                                              value: province,
                                              child: Text(province),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null &&
                                          value != _selectedProvince) {
                                        setState(() {
                                          _selectedProvince = value;
                                          final cities = _getCities();
                                          _selectedCity = cities.isNotEmpty
                                              ? cities[0]
                                              : '';
                                          _savePhilippinesLocation();
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCity,
                                    decoration: const InputDecoration(
                                      labelText: 'City/Municipality',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _getCities()
                                        .map((city) => DropdownMenuItem(
                                              value: city,
                                              child: Text(city),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null &&
                                          value != _selectedCity) {
                                        setState(() {
                                          _selectedCity = value;
                                          _savePhilippinesLocation();
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _savePhilippinesLocation,
                                    icon: const Icon(Icons.save),
                                    label:
                                        const Text('Save Philippines Location'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    // --- Set Custom Location Section ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Set Custom Location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _latitudeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Latitude',
                                          hintText: 'e.g., 14.5995',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^-?\d*\.?\d*')),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextField(
                                        controller: _longitudeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Longitude',
                                          hintText: 'e.g., 120.9842',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^-?\d*\.?\d*')),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isLoading ? null : _saveLocation,
                                        icon: const Icon(Icons.save),
                                        label: const Text('Save Location'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _useCurrentLocation,
                                        icon: const Icon(Icons.my_location),
                                        label: const Text('Use GPS'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _isLoading ? null : _clearLocation,
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Clear Saved Location'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quick Locations',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildQuickLocationButton(
                                        'Manila', 14.5995, 120.9842),
                                    _buildQuickLocationButton(
                                        'Cebu', 10.3157, 123.8854),
                                    _buildQuickLocationButton(
                                        'Davao', 7.1907, 125.4553),
                                    _buildQuickLocationButton(
                                        'Baguio', 16.4023, 120.5960),
                                    _buildQuickLocationButton(
                                        'Iloilo', 10.7203, 122.5621),
                                    _buildQuickLocationButton(
                                        'Zamboanga', 6.9214, 122.0790),
                                    _buildQuickLocationButton(
                                        'Pangasinan', 15.9940, 120.2363),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLocationButton(String name, double lat, double lon) {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () {
              _latitudeController.text = lat.toStringAsFixed(6);
              _longitudeController.text = lon.toStringAsFixed(6);
              _saveLocation();
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
      ),
      child: Text(name),
    );
  }
}
