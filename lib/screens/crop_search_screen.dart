import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class CropSearchScreen extends StatefulWidget {
  const CropSearchScreen({super.key});

  @override
  _CropSearchScreenState createState() => _CropSearchScreenState();
}

class _CropSearchScreenState extends State<CropSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  Map<String, dynamic>? _soilRecommendations;
  Map<String, Map<String, dynamic>> _recommendationsCache = {};

  // Available crops list
  final List<String> _availableCrops = [
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
    'pakwan',
    'talong',
    'onion',
    'muskmelon',
    'apple',
    'orange',
    'papaya',
    'coconut',
    'cotton',
    'jute',
    'coffee'
  ];

  @override
  void initState() {
    super.initState();
    _initializeCrops();
    _preloadAllSoilRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeCrops() {
    // Initialize with local crop data for instant loading
    setState(() {
      _searchResults = _availableCrops
          .map((crop) => {
                'name': crop,
                'label': crop.toUpperCase(),
                'description': _getCropDescription(crop),
              })
          .toList();
    });
  }

  void _searchCrops(String query) {
    if (query.isEmpty) {
      _initializeCrops();
      return;
    }

    setState(() {
      _searchResults = _availableCrops
          .where((crop) => crop.toLowerCase().contains(query.toLowerCase()))
          .map((crop) => {
                'name': crop,
                'label': crop.toUpperCase(),
                'description': _getCropDescription(crop),
              })
          .toList();
    });
  }

  String _getCropDescription(String crop) {
    final descriptions = {
      'rice': 'Staple grain crop, requires high water and warm climate',
      'maize': 'Corn crop, versatile and widely grown',
      'chickpea': 'Legume crop, good for soil nitrogen fixation',
      'kidneybeans': 'Protein-rich legume, good for crop rotation',
      'pigeonpeas': 'Drought-resistant legume crop',
      'mothbeans': 'Small legume, good for arid regions',
      'blackgram': 'Black gram legume, high protein content',
      'lentil': 'Nutritious legume, good for soil health',
      'pomegranate': 'Fruit tree, requires well-drained soil',
      'banana': 'Tropical fruit, requires warm climate',
      'mango': 'Tropical fruit tree, requires good drainage',
      'grapes': 'Vine fruit, requires specific soil conditions',
      'watermelon': 'Summer fruit, requires sandy soil',
      'pakwan':
          'Watermelon (alternate name), summer fruit, requires sandy soil',
      'talong':
          'Eggplant vegetable, requires well-drained soil and warm climate',
      'onion': 'Bulb vegetable, prefers sandy-loam soil and moderate climate',
      'muskmelon': 'Melon crop, requires warm climate',
      'apple': 'Temperate fruit tree, requires cold winters',
      'orange': 'Citrus fruit, requires subtropical climate',
      'papaya': 'Tropical fruit, fast-growing tree',
      'coconut': 'Tropical palm, requires coastal climate',
      'cotton': 'Fiber crop, requires warm climate',
      'jute': 'Fiber crop, requires humid climate',
      'coffee': 'Beverage crop, requires high altitude and shade',
    };
    return descriptions[crop] ?? 'Agricultural crop';
  }

  String _normalizeCropName(String crop) {
    final map = {
      'maize': 'corn',
      'blackgram': 'black gram',
    };
    return map[crop.toLowerCase()] ?? crop.toLowerCase();
  }

  Future<void> _preloadAllSoilRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/all-crop-soil-recommendations/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['all_recommendations'] != null) {
          setState(() {
            _recommendationsCache = Map<String, Map<String, dynamic>>.from(
                (data['all_recommendations'] as Map).map((k, v) =>
                    MapEntry(k.toString(), Map<String, dynamic>.from(v))));
          });
        }
      }
    } catch (e) {
      // Ignore preload errors for now
    }
  }

  Future<void> _getSoilRecommendations(String crop) async {
    final normalizedCrop = _normalizeCropName(crop);
    // Use cache if available
    if (_recommendationsCache.containsKey(normalizedCrop)) {
      setState(() {
        _soilRecommendations = _recommendationsCache[normalizedCrop];
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/crop-soil-recommendations/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'crop': normalizedCrop}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _soilRecommendations = data['recommendations'];
          _recommendationsCache[normalizedCrop] =
              data['recommendations']; // Cache the result
        });
      } else {
        _showError('Failed to get soil recommendations');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSoilRecommendationsModal(String crop) {
    showDialog(
      context: context,
      builder: (context) => SoilRecommendationsModal(
        crop: crop,
        recommendations: _soilRecommendations,
        isLoading: _isLoading,
      ),
    );
  }

  String _getCropIconPath(String cropName) {
    final normalizedName = cropName.toLowerCase().trim();
    final cropIconMap = {
      'apple': 'assets/icons/apple.png',
      'banana': 'assets/icons/banana.png',
      'blackgram': 'assets/icons/black gram.png',
      'black gram': 'assets/icons/black gram.png',
      'chickpea': 'assets/icons/chickpea.png',
      'coconut': 'assets/icons/coconut.png',
      'coffee': 'assets/icons/coffee.png',
      'maize': 'assets/icons/corn.png',
      'cotton': 'assets/icons/cotton.png',
      'grapes': 'assets/icons/grapes.png',
      'jute': 'assets/icons/jute.png',
      'kidneybeans': 'assets/icons/kidneybeans.png',
      'lentil': 'assets/icons/lentil.png',
      'mango': 'assets/icons/mango.png',
      'mothbeans': 'assets/icons/mothbeans.png',
      'mungbean': 'assets/icons/mung bean.png',
      'muskmelon': 'assets/icons/muskmelon.png',
      'orange': 'assets/icons/orange.png',
      'papaya': 'assets/icons/papaya.png',
      'pigeonpeas': 'assets/icons/pigeonpeas.png',
      'pomegranate': 'assets/icons/pomegranate.png',
      'rice': 'assets/icons/rice.png',
      'watermelon': 'assets/icons/watermelon.png',
      'pakwan': 'assets/icons/pakwan.png',
      'talong': 'assets/icons/talong.png',
      'onion': 'assets/icons/sibuyas.png',
    };
    return cropIconMap[normalizedName] ?? 'assets/icons/rice.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crop Search',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchCrops,
                decoration: InputDecoration(
                  hintText: 'Search for a crop...',
                  prefixIcon: Icon(Icons.search, color: Colors.green[700]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _searchCrops('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            // Results
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No crops found',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final crop = _searchResults[index];
                            final cropName =
                                crop['name'] ?? crop['label'] ?? '';

                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      _getCropIconPath(cropName),
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(Icons.eco,
                                            color: Colors.green[700]);
                                      },
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cropName.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green[900],
                                  ),
                                ),
                                subtitle: Text(
                                  crop['description'] ?? 'Agricultural crop',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.green[700],
                                  size: 16,
                                ),
                                onTap: () {
                                  _getSoilRecommendations(cropName);
                                  _showSoilRecommendationsModal(cropName);
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Soil Recommendations Modal
class SoilRecommendationsModal extends StatelessWidget {
  final String crop;
  final Map<String, dynamic>? recommendations;
  final bool isLoading;

  const SoilRecommendationsModal({
    Key? key,
    required this.crop,
    this.recommendations,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Soil Requirements for ${crop.toUpperCase()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                      ),
                    )
                  : recommendations == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'No recommendations available',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRecommendationCard(
                                'Optimal pH Range',
                                '${recommendations!['ph_min'] ?? 'N/A'} - ${recommendations!['ph_max'] ?? 'N/A'}',
                                Icons.science,
                                Colors.blue,
                              ),
                              SizedBox(height: 12),
                              _buildRecommendationCard(
                                'Temperature Range',
                                '${recommendations!['temp_min'] ?? 'N/A'}°C - ${recommendations!['temp_max'] ?? 'N/A'}°C',
                                Icons.thermostat,
                                Colors.orange,
                              ),
                              SizedBox(height: 12),
                              _buildRecommendationCard(
                                'Humidity Range',
                                '${recommendations!['humidity_min'] ?? 'N/A'}% - ${recommendations!['humidity_max'] ?? 'N/A'}%',
                                Icons.water_drop,
                                Colors.blue,
                              ),
                              SizedBox(height: 12),
                              _buildRecommendationCard(
                                'Rainfall Range',
                                '${recommendations!['rainfall_min'] ?? 'N/A'}mm - ${recommendations!['rainfall_max'] ?? 'N/A'}mm',
                                Icons.water,
                                Colors.blue,
                              ),
                              SizedBox(height: 12),
                              _buildRecommendationCard(
                                'Nitrogen Requirements',
                                '${recommendations!['nitrogen_min'] ?? 'N/A'} - ${recommendations!['nitrogen_max'] ?? 'N/A'} mg/kg',
                                Icons.science,
                                Colors.green,
                              ),
                              SizedBox(height: 12),
                              _buildRecommendationCard(
                                'Phosphorus Requirements',
                                '${recommendations!['phosphorus_min'] ?? 'N/A'} - ${recommendations!['phosphorus_max'] ?? 'N/A'} mg/kg',
                                Icons.science,
                                Colors.green,
                              ),
                              SizedBox(height: 12),
                              _buildRecommendationCard(
                                'Potassium Requirements',
                                '${recommendations!['potassium_min'] ?? 'N/A'} - ${recommendations!['potassium_max'] ?? 'N/A'} mg/kg',
                                Icons.science,
                                Colors.green,
                              ),
                              if (recommendations!['notes'] != null) ...[
                                SizedBox(height: 20),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.green[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Additional Notes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        recommendations!['notes'],
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
      String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color[700], size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color[700],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
