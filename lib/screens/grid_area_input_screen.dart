import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soilsync/services/sensor_bus.dart';
import 'package:soilsync/services/grid_sampling_storage.dart';

class GridAreaInputScreen extends StatefulWidget {
  final String areaName;

  const GridAreaInputScreen({
    super.key,
    required this.areaName,
  });

  @override
  State<GridAreaInputScreen> createState() => _GridAreaInputScreenState();
}

class _GridAreaInputScreenState extends State<GridAreaInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  StreamSubscription<SensorReading>? _sensorSubscription;
  bool _isAutoCollectEnabled = false;
  DateTime? _lastAutoCollectTime;
  SensorReading? _latestReading;

  final List<_SoilField> _fields = const [
    _SoilField(
      label: 'Nitrogen',
      unit: 'mg/kg',
      icon: Icons.science_outlined,
      keyName: 'nitrogen',
    ),
    _SoilField(
      label: 'Phosphorus',
      unit: 'mg/kg',
      icon: Icons.bubble_chart_outlined,
      keyName: 'phosphorus',
    ),
    _SoilField(
      label: 'Potassium',
      unit: 'mg/kg',
      icon: Icons.grain,
      keyName: 'potassium',
    ),
    _SoilField(
      label: 'pH',
      unit: '',
      icon: Icons.flare,
      keyName: 'ph',
    ),
    _SoilField(
      label: 'Temperature',
      unit: '°C',
      icon: Icons.thermostat,
      keyName: 'temperature',
    ),
    _SoilField(
      label: 'Humidity',
      unit: '%',
      icon: Icons.water_drop_outlined,
      keyName: 'humidity',
    ),
    _SoilField(
      label: 'Rainfall',
      unit: 'mm',
      icon: Icons.water,
      keyName: 'rainfall',
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final field in _fields) {
      _controllers[field.keyName] = TextEditingController();
    }
    _sensorSubscription = SensorBus.instance.stream.listen(_onSensorReading);
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveData() async {
    if (_formKey.currentState?.validate() != true) return;

    // Extract area number from area name (e.g., "Area 1" -> 1)
    final areaNumber = int.tryParse(widget.areaName.split(' ').last) ?? 1;

    // Create GridAreaData object
    final areaData = GridAreaData(
      areaNumber: areaNumber,
      nitrogen: double.tryParse(_controllers['nitrogen']!.text) ?? 0,
      phosphorus: double.tryParse(_controllers['phosphorus']!.text) ?? 0,
      potassium: double.tryParse(_controllers['potassium']!.text) ?? 0,
      ph: double.tryParse(_controllers['ph']!.text) ?? 7,
      temperature: double.tryParse(_controllers['temperature']!.text) ?? 25,
      humidity: double.tryParse(_controllers['humidity']!.text) ?? 50,
      rainfall: double.tryParse(_controllers['rainfall']!.text) ?? 100,
    );

    // Save to storage
    final storage = GridSamplingStorage();
    await storage.saveAreaData(areaData);

    // Pop with success flag
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _onSensorReading(SensorReading reading) {
    _latestReading = reading;
    if (_isAutoCollectEnabled) {
      _applySensorReading(reading);
    } else {
      setState(() {});
    }
  }

  void _applySensorReading(SensorReading reading) {
    void setValue(String key, double value, {int fractionDigits = 1}) {
      final controller = _controllers[key];
      if (controller == null) return;
      controller.text = value.toStringAsFixed(fractionDigits);
    }

    setValue('nitrogen', reading.nitrogen);
    setValue('phosphorus', reading.phosphorus);
    setValue('potassium', reading.potassium);
    setValue('ph', reading.ph, fractionDigits: 2);
    setValue('temperature', reading.temperature);
    setValue('humidity', reading.humidity);
    setValue('rainfall', reading.rainfall);

    setState(() {
      _lastAutoCollectTime = reading.timestamp;
    });
  }

  void _toggleAutoCollect(bool value) {
    setState(() {
      _isAutoCollectEnabled = value;
    });
    if (value && _latestReading != null) {
      _applySensorReading(_latestReading!);
    }
  }

  String _autoCollectStatusText() {
    if (!_isAutoCollectEnabled) {
      return 'Enter values manually.';
    }
    if (_lastAutoCollectTime == null) {
      return 'Waiting for live sensor data...';
    }
    final time = _lastAutoCollectTime!.toLocal();
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return 'Last auto-collect: $hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soil Data • ${widget.areaName}'),
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
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
                                Icons.eco,
                                color: Colors.green[700],
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.areaName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Enter soil readings for this sampling area.',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Use current soil kit or sensor readings. All fields are required.',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green[700]!.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green[100]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.sensors,
                                      color: Colors.green[700], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Auto collect from sensor',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[900],
                                          ),
                                        ),
                                        Text(
                                          _autoCollectStatusText(),
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: _isAutoCollectEnabled,
                                    activeColor: Colors.green[700],
                                    onChanged: _toggleAutoCollect,
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
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: _fields
                        .map(
                          (field) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _SoilInputCard(
                              field: field,
                              controller: _controllers[field.keyName]!,
                              isReadOnly: _isAutoCollectEnabled,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _saveData,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Soil Data for This Area'),
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

class _SoilField {
  final String label;
  final String unit;
  final IconData icon;
  final String keyName;

  const _SoilField({
    required this.label,
    required this.unit,
    required this.icon,
    required this.keyName,
  });
}

class _SoilInputCard extends StatelessWidget {
  final _SoilField field;
  final TextEditingController controller;
  final bool isReadOnly;

  const _SoilInputCard({
    required this.field,
    required this.controller,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    field.icon,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    field.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[900],
                    ),
                  ),
                ),
                if (field.unit.isNotEmpty)
                  Text(
                    field.unit,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              enabled: !isReadOnly,
              readOnly: isReadOnly,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter ${field.label.toLowerCase()}',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.green[600]!),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter ${field.label.toLowerCase()}';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
