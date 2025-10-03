import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/location_settings_widget.dart';
import 'pages/wifi_settings_page.dart';
import 'pages/crop_data_dashboard.dart';
import 'pages/retraining_dashboard.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedUnit = 'Metric';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _isNotificationsEnabled = prefs.getBool('notifications') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _selectedUnit = prefs.getString('unit') ?? 'Metric';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setBool('notifications', _isNotificationsEnabled);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('unit', _selectedUnit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green[700],
        elevation: 0,
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildSettingTile(
                      'Dark Mode',
                      'Enable dark theme',
                      Icons.dark_mode,
                      Switch(
                        value: _isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _isDarkMode = value;
                            _saveSettings();
                          });
                        },
                        activeColor: Colors.green[700],
                      ),
                    ),
                    Divider(height: 1),
                    _buildSettingTile(
                      'Notifications',
                      'Enable push notifications',
                      Icons.notifications,
                      Switch(
                        value: _isNotificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isNotificationsEnabled = value;
                            _saveSettings();
                          });
                        },
                        activeColor: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildSettingTile(
                      'Language',
                      'Select app language',
                      Icons.language,
                      DropdownButton<String>(
                        value: _selectedLanguage,
                        items: ['English', 'Spanish', 'French', 'German']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedLanguage = newValue;
                              _saveSettings();
                            });
                          }
                        },
                        underline: Container(),
                      ),
                    ),
                    Divider(height: 1),
                    _buildSettingTile(
                      'Units',
                      'Select measurement units',
                      Icons.straighten,
                      DropdownButton<String>(
                        value: _selectedUnit,
                        items: ['Metric', 'Imperial'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedUnit = newValue;
                              _saveSettings();
                            });
                          }
                        },
                        underline: Container(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Move Location Settings card here
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.location_on, color: Colors.green[700]),
                  title: Text(
                    'Location Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                  subtitle: Text(
                    'Set precise location for rainfall data',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[600]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocationSettingsWidget(),
                      ),
                    );
                  },
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.wifi, color: Colors.green[700]),
                  title: Text(
                    'WiFi Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                  subtitle: Text(
                    'Configure ESP32 WiFi credentials',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[600]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WifiSettingsPage(),
                      ),
                    );
                  },
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.dataset, color: Colors.green[700]),
                  title: Text(
                    'Crop Data Collection',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                  subtitle: Text(
                    'Manage soil sensor data and crop records',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[600]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CropDataDashboardPage(),
                      ),
                    );
                  },
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.model_training, color: Colors.green[700]),
                  title: Text(
                    'Model Retraining',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                  subtitle: Text(
                    'Train and manage AI models for crop prediction',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[600]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RetrainingDashboardPage(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildSettingTile(
                      'About',
                      'App version and information',
                      Icons.info,
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'SoilSync',
                          applicationVersion: '1.0.0',
                          applicationIcon: Icon(
                            Icons.grass,
                            size: 50,
                            color: Colors.green[700],
                          ),
                          children: [
                            SizedBox(height: 16),
                            Text(
                              'SoilSync is an intelligent soil analysis and crop prediction app that helps farmers make data-driven decisions.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(height: 1),
                    _buildSettingTile(
                      'Help',
                      'How to use the soil sensor and app',
                      Icons.help,
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Row(
                              children: [
                                Icon(Icons.help, color: Colors.green[700]),
                                SizedBox(width: 8),
                                Text('Help for Farmers'),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• The soil sensor can accurately analyze soil properties for an area of up to 1 hectare (10,000 square meters) per reading.\n',
                                  ),
                                  Text(
                                    '• For larger farms, take multiple readings at different locations to get a more comprehensive soil profile.\n',
                                  ),
                                  Text(
                                    '• Place the sensor in the center of the area you want to analyze for best results.\n',
                                  ),
                                  Text(
                                    '• The app will use the sensor data and weather information to recommend the best crops for your land.\n',
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'If you need more help, contact your local agricultural extension office or refer to the SoilSync user manual.',
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Close',
                                    style: TextStyle(color: Colors.green[700])),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(height: 1),
                    _buildSettingTile(
                      'Privacy Policy',
                      'View privacy policy',
                      Icons.privacy_tip,
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        // TODO: Navigate to privacy policy
                      },
                    ),
                    Divider(height: 1),
                    _buildSettingTile(
                      'Terms of Service',
                      'View terms of service',
                      Icons.description,
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        // TODO: Navigate to terms of service
                      },
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

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    Widget trailing, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.green[700],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
