import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

class SensorDataCollector {
  final int batchSize;
  final Duration collectionInterval;

  Timer? _timer;
  List<Map<String, dynamic>> _batch = [];

  double _accelX = 0, _accelY = 0, _accelZ = 0;
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;

  SensorDataCollector({
    this.batchSize = 10,
    this.collectionInterval = const Duration(seconds: 2),
  });

  void start({required String userId}) {
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
    // Pass the userId to the collection method
    _timer = Timer.periodic(collectionInterval, (_) {
      _collectAndBatch(userId);
    });
  }

  void stop() {
    _timer?.cancel();
  }

  // Modified to accept userId
  void _collectAndBatch(String userId) {
    final timestamp = DateTime.now().toIso8601String();

    final dataPoint = {
      'user': userId, // Add the user field
      'timestamp': timestamp,
      'accel_x': _accelX,
      'accel_y': _accelY,
      'accel_z': _accelZ,
      'gyro_x': _gyroX,
      'gyro_y': _gyroY,
      'gyro_z': _gyroZ,
    };

    _batch.add(dataPoint);
  }

  List<Map<String, dynamic>> getSensorData() {
    return List.from(_batch);
  }

  void clearData() {
    _batch.clear();
  }
}
