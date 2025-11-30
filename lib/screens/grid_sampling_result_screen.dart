import 'package:flutter/material.dart';

class GridSamplingResultScreen extends StatelessWidget {
  final String cropName;
  final String cropImagePath;
  final Map<String, double> averages;

  const GridSamplingResultScreen({
    super.key,
    required this.cropName,
    required this.cropImagePath,
    required this.averages,
  });

  @override
  Widget build(BuildContext context) {
    final entries = [
      _AverageField('Nitrogen', 'N', 'mg/kg'),
      _AverageField('Phosphorus', 'P', 'mg/kg'),
      _AverageField('Potassium', 'K', 'mg/kg'),
      _AverageField('pH', 'ph', ''),
      _AverageField('Temperature', 'temperature', '°C'),
      _AverageField('Humidity', 'humidity', '%'),
      _AverageField('Rainfall', 'rainfall', 'mm'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grid Sampling Result'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            cropImagePath,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 120,
                              height: 120,
                              color: Colors.green[50],
                              child: Icon(Icons.eco,
                                  color: Colors.green[700], size: 48),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          cropName,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Based on combined soil data from 4 farm areas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Soil Averages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: entries
                          .map(
                            (field) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: _AverageRow(
                                label: field.label,
                                value:
                                    averages[field.key]?.toStringAsFixed(1) ??
                                        '--',
                                unit: field.unit,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Dashboard'),
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

class _AverageField {
  final String label;
  final String key;
  final String unit;

  const _AverageField(this.label, this.key, this.unit);
}

class _AverageRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _AverageRow({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green[900],
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          unit,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
