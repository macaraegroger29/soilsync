import 'package:flutter/material.dart';
import 'dart:math' as math;

class ConfusionMatrixWidget extends StatelessWidget {
  final List<List<dynamic>> matrix;
  final List<dynamic> labels;

  const ConfusionMatrixWidget({
    Key? key,
    required this.matrix,
    required this.labels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confusion Matrix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    MaterialStateProperty.all(Colors.grey.shade100),
                columns: [
                  const DataColumn(label: Text('Actual \\ Predicted')),
                  ...labels.map((label) => DataColumn(
                        label: Text(
                          label.toString().length > 8
                              ? '${label.toString().substring(0, 8)}...'
                              : label.toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      )),
                ],
                rows: List.generate(matrix.length, (i) {
                  return DataRow(
                    color: MaterialStateProperty.all(
                      i % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                    ),
                    cells: [
                      DataCell(
                        Text(
                          labels[i].toString().length > 8
                              ? '${labels[i].toString().substring(0, 8)}...'
                              : labels[i].toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      ...matrix[i].map((cell) => DataCell(
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _getCellColor(cell.toDouble()),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cell.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: cell.toDouble() > 0
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          )),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCellColor(double value) {
    if (value == 0) return Colors.grey.shade200;
    if (value < 5) return Colors.blue.shade100;
    if (value < 10) return Colors.blue.shade300;
    if (value < 20) return Colors.blue.shade500;
    return Colors.blue.shade700;
  }
}

class FeatureImportanceChart extends StatelessWidget {
  final Map<String, dynamic> featureImportance;

  const FeatureImportanceChart({
    Key? key,
    required this.featureImportance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entries = featureImportance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feature Importance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) => _buildFeatureBar(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBar(String feature, double importance) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatFeatureName(feature),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                '${(importance * 100).toStringAsFixed(1)}%',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: importance,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getImportanceColor(importance),
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  String _formatFeatureName(String feature) {
    switch (feature.toLowerCase()) {
      case 'nitrogen':
        return 'Nitrogen (N)';
      case 'phosphorus':
        return 'Phosphorus (P)';
      case 'potassium':
        return 'Potassium (K)';
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'ph':
        return 'pH Level';
      case 'rainfall':
        return 'Rainfall';
      default:
        return feature.toUpperCase();
    }
  }

  Color _getImportanceColor(double importance) {
    if (importance > 0.2) return Colors.green;
    if (importance > 0.15) return Colors.blue;
    if (importance > 0.1) return Colors.orange;
    return Colors.red;
  }
}

class TrainingMetricsChart extends StatelessWidget {
  final Map<String, dynamic> trainingMetrics;

  const TrainingMetricsChart({
    Key? key,
    required this.trainingMetrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Training Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 16),
            _buildProgressChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      children: [
        _buildMetricCard(
          'Training Accuracy',
          '${(trainingMetrics['train_accuracy'] * 100).toStringAsFixed(1)}%',
          Colors.blue,
        ),
        _buildMetricCard(
          'Validation Accuracy',
          '${(trainingMetrics['val_accuracy'] * 100).toStringAsFixed(1)}%',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    final epochs = trainingMetrics['epochs'] as List<dynamic>;
    final trainLoss = trainingMetrics['train_loss'] as List<dynamic>;
    final valLoss = trainingMetrics['val_loss'] as List<dynamic>;

    return Container(
      height: 200,
      child: CustomPaint(
        painter: TrainingProgressPainter(
          epochs: epochs.map<double>((e) => e.toDouble()).toList(),
          trainLoss: trainLoss.map<double>((l) => l.toDouble()).toList(),
          valLoss: valLoss.map<double>((l) => l.toDouble()).toList(),
        ),
        child: Container(),
      ),
    );
  }
}

class TrainingProgressPainter extends CustomPainter {
  final List<double> epochs;
  final List<double> trainLoss;
  final List<double> valLoss;

  TrainingProgressPainter({
    required this.epochs,
    required this.trainLoss,
    required this.valLoss,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final valPath = Path();

    // Find min/max values for scaling
    final allValues = [...trainLoss, ...valLoss];
    final minVal = allValues.reduce(math.min);
    final maxVal = allValues.reduce(math.max);
    final range = maxVal - minVal;

    // Draw grid lines
    _drawGrid(canvas, size);

    // Draw training loss line
    paint.color = Colors.blue;
    for (int i = 0; i < epochs.length; i++) {
      final x = (epochs[i] / epochs.last) * size.width;
      final y = size.height - ((trainLoss[i] - minVal) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Draw validation loss line
    paint.color = Colors.red;
    for (int i = 0; i < epochs.length; i++) {
      final x = (epochs[i] / epochs.last) * size.width;
      final y = size.height - ((valLoss[i] - minVal) / range) * size.height;

      if (i == 0) {
        valPath.moveTo(x, y);
      } else {
        valPath.lineTo(x, y);
      }
    }
    canvas.drawPath(valPath, paint);

    // Draw legend
    _drawLegend(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Vertical grid lines
    for (int i = 0; i <= 5; i++) {
      final x = (i / 5) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = (i / 5) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLegend(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Training Loss',
        style: TextStyle(color: Colors.blue, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));

    final valTextPainter = TextPainter(
      text: const TextSpan(
        text: 'Validation Loss',
        style: TextStyle(color: Colors.red, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    valTextPainter.layout();
    valTextPainter.paint(canvas, Offset(10, 30));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ModelVersionCard extends StatelessWidget {
  final Map<String, dynamic> version;
  final VoidCallback? onDeploy;
  final VoidCallback? onViewDetails;

  const ModelVersionCard({
    Key? key,
    required this.version,
    this.onDeploy,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = version['is_active'] == true;
    final accuracy = version['accuracy'] as double? ?? 0.0;
    final datasetSize = version['dataset_size'] as int? ?? 0;
    final createdAt = DateTime.parse(version['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Version ${version['version']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green.shade700 : null,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMetricChip(
                    'Accuracy', '${(accuracy * 100).toStringAsFixed(1)}%'),
                const SizedBox(width: 8),
                _buildMetricChip('Dataset', '$datasetSize records'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${createdAt.toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isActive && onDeploy != null)
                  ElevatedButton.icon(
                    onPressed: onDeploy,
                    icon: const Icon(Icons.rocket_launch, size: 16),
                    label: const Text('Deploy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (onDeploy != null && isActive) const SizedBox(width: 8),
                if (onViewDetails != null)
                  OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
