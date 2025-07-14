import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DebugWeatherWidget extends StatefulWidget {
  const DebugWeatherWidget({Key? key}) : super(key: key);

  @override
  State<DebugWeatherWidget> createState() => _DebugWeatherWidgetState();
}

class _DebugWeatherWidgetState extends State<DebugWeatherWidget> {
  Map<String, dynamic>? backendData;
  Map<String, dynamic>? openMeteoData;
  bool isLoading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌧️ Weather Data Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _testBothAPIs,
              child: const Text('🔍 Test Both APIs'),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red[100],
                child: Text('❌ Error: $error'),
              )
            else ...[
              if (backendData != null)
                _buildDataCard('Backend API', backendData!, Colors.green),
              if (openMeteoData != null)
                _buildDataCard('Open-Meteo API', openMeteoData!, Colors.blue),
            ],
            const SizedBox(height: 20),
            const Text(
              '💡 How to verify real vs random data:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
                '• Run this test multiple times - real data should vary'),
            const Text('• Compare with weather websites'),
            const Text('• Check if values make sense for your location'),
            const Text('• Real data should have timestamps'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String title, Map<String, dynamic> data, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
                'Rainfall: ${data['rainfall'] ?? data['precipitation'] ?? 'N/A'} mm'),
            Text('Temperature: ${data['temperature'] ?? 'N/A'}°C'),
            Text('Humidity: ${data['humidity'] ?? 'N/A'}%'),
            if (data['source'] != null) Text('Source: ${data['source']}'),
            if (data['time'] != null) Text('Time: ${data['time']}'),
            const SizedBox(height: 10),
            Text(
              'Raw Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text(
                const JsonEncoder.withIndent('  ').convert(data),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testBothAPIs() async {
    setState(() {
      isLoading = true;
      error = null;
      backendData = null;
      openMeteoData = null;
    });

    try {
      // Test Backend API
      try {
        final backendResponse = await http.get(
          Uri.parse(
              'http://192.168.254.174:8000/api/weather/?latitude=14.5995&longitude=120.9842'),
        );

        if (backendResponse.statusCode == 200) {
          setState(() {
            backendData = json.decode(backendResponse.body);
          });
        }
      } catch (e) {
        print('Backend API Error: $e');
      }

      // Test Open-Meteo API
      try {
        final openMeteoResponse = await http.get(
          Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=14.5995&longitude=120.9842&current=precipitation&timezone=auto'),
        );

        if (openMeteoResponse.statusCode == 200) {
          final data = json.decode(openMeteoResponse.body);
          setState(() {
            openMeteoData = {
              'precipitation': data['current']['precipitation'],
              'time': data['current']['time'],
              'source': 'open-meteo'
            };
          });
        }
      } catch (e) {
        print('Open-Meteo API Error: $e');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
