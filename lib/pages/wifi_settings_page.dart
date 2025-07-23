import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:soilsync/config.dart';

class WifiSettingsPage extends StatefulWidget {
  const WifiSettingsPage({super.key});

  @override
  State<WifiSettingsPage> createState() => _WifiSettingsPageState();
}

class _WifiSettingsPageState extends State<WifiSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isHidden = false; // State for the hidden network checkbox

  Future<void> _saveWifiCredentials() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final body = {
          'ssid': _ssidController.text,
          'password': _passwordController.text,
        };
        if (_isHidden) {
          body['hidden'] = 'true';
        }

        final response = await http.post(
          Uri.parse('http://${AppConfig.esp32Ip}/settings'),
          body: body,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Credentials saved. ESP32 is restarting.')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to save credentials: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to ESP32: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _ssidController,
                decoration: const InputDecoration(
                  labelText: 'WiFi SSID',
                  hintText: 'Enter your WiFi network name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an SSID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your WiFi password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Hidden Network'),
                subtitle: const Text(
                    'Check this if your WiFi does not broadcast its name (SSID).'),
                value: _isHidden,
                onChanged: (bool? value) {
                  setState(() {
                    _isHidden = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveWifiCredentials,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Save and Restart ESP32'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
