import 'package:flutter/material.dart';
import 'grid_sampling_result_screen.dart';

class GridSamplingCompleteScreen extends StatelessWidget {
  const GridSamplingCompleteScreen({super.key});

  Map<String, double> _sampleAverages() {
    return {
      'N': 85.0,
      'P': 42.0,
      'K': 60.0,
      'pH': 6.4,
      'temperature': 28.0,
      'humidity': 58.0,
      'rainfall': 12.0,
    };
  }

  String _getCropImage(String crop) {
    final normalized = crop.toLowerCase();
    final map = {
      'rice': 'assets/icons/rice.png',
      'maize': 'assets/icons/corn.png',
      'corn': 'assets/icons/corn.png',
      'banana': 'assets/icons/banana.png',
      'mango': 'assets/icons/mango.png',
      'coffee': 'assets/icons/coffee.png',
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GridSamplingResultScreen(
                          cropName: 'Recommended Crop: Rice',
                          cropImagePath: _getCropImage('rice'),
                          averages: _sampleAverages(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_graph),
                  label: const Text('Generate Final Recommendation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
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
