import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;

class SensorDataCollector {
  final String backendUrl;
  final String userId;
  final void Function(double score)? anomalyCallback;

  final int batchSize;
  final Duration collectionInterval;
  List<Map<String, dynamic>> get batch => _batch;

  Timer? _timer;
  List<Map<String, dynamic>> _batch = [];

  double _accelX = 0, _accelY = 0, _accelZ = 0;
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;

  SensorDataCollector({
    required this.backendUrl,
    required this.userId,
    this.anomalyCallback,
    this.batchSize = 10,
    this.collectionInterval = const Duration(seconds: 2),
  });

  void start() {
    accelerometerEvents.listen((event) {
      _accelX = event.x;
      _accelY = event.y;
      _accelZ = event.z;
    });

    gyroscopeEvents.listen((event) {
      _gyroX = event.x;
      _gyroY = event.y;
      _gyroZ = event.z;
    });

    _timer?.cancel();
    _timer = Timer.periodic(collectionInterval, (_) {
      _collectAndBatch();
    });
  }

  void stop() {
    _timer?.cancel();
  }

  void _collectAndBatch() {
    final timestamp = DateTime.now().toIso8601String();
    final magnitude = _calculateFusionScore();

    final dataPoint = {
      'timestamp': timestamp,
      'accel_x': _accelX,
      'accel_y': _accelY,
      'accel_z': _accelZ,
      'gyro_x': _gyroX,
      'gyro_y': _gyroY,
      'gyro_z': _gyroZ,
      'fusion_score': magnitude,
    };

    _batch.add(dataPoint);

    // Trigger anomaly callback if magnitude exceeds threshold
    anomalyCallback?.call(magnitude);

    if (_batch.length >= batchSize) {
      _sendBatch();
    }
  }

  double _calculateFusionScore() {
    return sqrt(_accelX * _accelX + _accelY * _accelY + _accelZ * _accelZ);
  }

  Future<void> _sendBatch() async {
    final payload = {
      'user': userId,
      'sensor_data': _batch,
    };

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/sensor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("Sensor data batch sent successfully!");
      } else {
        print("Failed to send sensor data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending sensor data: $e");
    }

    _batch.clear();
  }

  /// Public flush method
  Future<void> flush() async {
    if (_batch.isNotEmpty) {
      await _sendBatch();
    }
  }
}
