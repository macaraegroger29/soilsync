import 'dart:async';

/// Normalized sensor reading payload broadcast across the app.
class SensorReading {
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double temperature;
  final double humidity;
  final double ph;
  final double rainfall;
  final DateTime timestamp;

  SensorReading({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.temperature,
    required this.humidity,
    required this.ph,
    required this.rainfall,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Simple singleton event bus for publishing sensor readings.
class SensorBus {
  SensorBus._internal();
  static final SensorBus instance = SensorBus._internal();

  final StreamController<SensorReading> _controller =
      StreamController<SensorReading>.broadcast();

  Stream<SensorReading> get stream => _controller.stream;

  void publish(SensorReading reading) {
    if (!_controller.isClosed) {
      _controller.add(reading);
    }
  }

  void dispose() {
    _controller.close();
  }
}
