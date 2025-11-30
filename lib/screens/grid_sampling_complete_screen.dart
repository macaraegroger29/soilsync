import 'package:flutter/material.dart';
import 'grid_sampling_result_screen.dart';
import 'package:soilsync/services/grid_sampling_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class GridSamplingCompleteScreen extends StatefulWidget {
  const GridSamplingCompleteScreen({super.key});

  @override
  State<GridSamplingCompleteScreen> createState() => _GridSamplingCompleteScreenState();
}

class _GridSamplingCompleteScreenState extends State<GridSamplingCompleteScreen> {
  Map<String, double> _averages = {};
  String _recommendedCrop = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataAndCalculateRecommendation();
  }

  Future<void> _loadDataAndCalculateRecommendation() async {
    try {
      final storage = GridSamplingStorage();
      final averages = await storage.calculateAverages();

      setState(() {
        _averages = averages;
      });

      // Get recommendation using the same API as normal crop recommendation
      final recommendedCrop = await _getCropRecommendationFromAPI(averages);

      setState(() {
        _recommendedCrop = recommendedCrop;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _recommendedCrop = 'Error calculating recommendation';
        _isLoading = false;
      });
    }
  }

  Future<String> _getCropRecommendationFromAPI(Map<String, double> averages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/predict/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nitrogen': averages['N'] ?? 0,
          'phosphorus': averages['P'] ?? 0,
          'potassium': averages['K'] ?? 0,
          'temperature': averages['temperature'] ?? 25,
          'humidity': averages['humidity'] ?? 50,
          'ph': averages['ph'] ?? 7,
          'rainfall': averages['rainfall'] ?? 100,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['prediction'] ?? 'Unknown Crop';
      } else {
        throw Exception('Failed to get crop recommendation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }



  String _getCropImage(String crop) {
    final normalized = crop.toLowerCase();
    final map = {
      'rice': 'assets/icons/rice.png',
      'corn': 'assets/icons/corn.png',
      'banana': 'assets/icons/banana.png',
      'mango': 'assets/icons/mango.png',
      'coffee': 'assets/icons/coffee.png',
      'wheat': 'assets/icons/wheat.png',
      'grapes': 'assets/icons/grapes.png',
      'kidneybeans': 'assets/icons/kidneybeans.png',
      'cotton': 'assets/icons/cotton.png',
      'coconut': 'assets/icons/coconut.png',
      'muskmelon': 'assets/icons/muskmelon.png',
      'apple': 'assets/icons/apple.png',
      'black gram': 'assets/icons/blackgram.png',
      'chickpea': 'assets/icons/chickpea.png',
      'jute': 'assets/icons/jute.png',
      'lentil': 'assets/icons/lentil.png',
      'mothbeans': 'assets/icons/mothbeans.png',
      'mung bean': 'assets/icons/mungbean.png',
      'orange': 'assets/icons/orange.png',
      'pakwan': 'assets/icons/pakwan.png',
      'papaya': 'assets/icons/papaya.png',
      'pigeonpeas': 'assets/icons/pigeonpeas.png',
      'pomegranate': 'assets/icons/pomegranate.png',
      'sibuyas': 'assets/icons/sibuyas.png',
      'talong': 'assets/icons/talong.png',
      'watermelon': 'assets/icons/watermelon.png',
    };
    return map[normalized] ?? 'assets/icons/rice.png';
  }

  @override
  Widget build(BuildContext context) {
    final List<int> areas = [1, 2, 3, 4];

    return Scaffold(
      appBar: AppBar(
        title: const Text('2×2 Grid Completed'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[700]!, Colors.green[50]!],
            stops: const [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.green[50],
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sampling Complete!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'All 4 areas have verified soil readings. You can now generate the final recommendation.',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: areas.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final area = areas[index];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.green[600]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green[600],
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Area $area',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Data collected',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GridSamplingResultScreen(
                          cropName: 'Recommended Crop: $_recommendedCrop',
                          cropImagePath: _getCropImage(_recommendedCrop),
                          averages: _averages,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_graph),
                  label: _isLoading
                      ? const Text('Calculating...')
                      : const Text('Generate Final Recommendation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading ? Colors.grey : Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
