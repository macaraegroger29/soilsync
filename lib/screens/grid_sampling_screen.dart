import 'package:flutter/material.dart';
import 'grid_area_input_screen.dart';
import 'grid_sampling_complete_screen.dart';
import 'package:soilsync/services/grid_sampling_storage.dart';

class GridSamplingScreen extends StatefulWidget {
  const GridSamplingScreen({super.key});

  @override
  State<GridSamplingScreen> createState() => _GridSamplingScreenState();
}

class _GridSamplingScreenState extends State<GridSamplingScreen> {
  final List<bool> _areaCompleted = List<bool>.filled(4, false);

  bool get _allAreasComplete => _areaCompleted.every((status) => status);

  void _toggleArea(int index) {
    setState(() {
      _areaCompleted[index] = !_areaCompleted[index];
    });
  }

  Future<void> _openAreaInput(int index) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GridAreaInputScreen(
          areaName: 'Area ${index + 1}',
        ),
      ),
    );
    if (result == true) {
      setState(() {
        _areaCompleted[index] = true;
      });
    }
  }

  void _resetGrid() async {
    final storage = GridSamplingStorage();
    await storage.clearData();

    setState(() {
      for (var i = 0; i < _areaCompleted.length; i++) {
        _areaCompleted[i] = false;
      }
    });
  }

  void _completeAll() {
    setState(() {
      for (var i = 0; i < _areaCompleted.length; i++) {
        _areaCompleted[i] = true;
      }
    });
  }

  Future<void> _openCompletionScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GridSamplingCompleteScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2×2 Grid Sampling'),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Farm Sampling Mode',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Walk through each area of the field and tap to mark it complete once samples are collected. Enter different soil readings for each area to get accurate crop recommendations.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: 4,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final isDone = _areaCompleted[index];
                      return GestureDetector(
                        onTap: () => _openAreaInput(index),
                        onLongPress: () => _toggleArea(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green[100] : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDone
                                  ? Colors.green[600]!
                                  : Colors.grey[300]!,
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
                                radius: 28,
                                backgroundColor: isDone
                                    ? Colors.green[600]
                                    : Colors.green[50],
                                child: Icon(
                                  isDone ? Icons.check : Icons.crop_square,
                                  color:
                                      isDone ? Colors.white : Colors.green[700],
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Area ${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isDone ? 'Completed' : 'Tap to enter soil data',
                                style: TextStyle(
                                  color: isDone
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                                  fontWeight: isDone
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetGrid,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[700],
                          side: BorderSide(color: Colors.green[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _completeAll,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark All Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_allAreasComplete) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openCompletionScreen,
                    icon: const Icon(Icons.auto_graph),
                    label: const Text('Generate Final Recommendation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
