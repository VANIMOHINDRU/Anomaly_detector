// main_controller.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_usage_tracker.dart';
import 'typing_tracker.dart';
import 'sensor_data_collector.dart';

/// The callback signature for notifying the UI about the final anomaly score.
typedef AnomalyCallback =
    void Function(double fusionScore, bool anomalyDetected);

class MainController {
  final String backendUrl;
  final String userId;
  final AnomalyCallback? onAnomaly;

  // The individual agents that collect data.
  final AppUsageTracker appTracker;
  final TypingTracker typingTracker;
  final SensorDataCollector sensorCollector;

  MainController({
    required this.backendUrl,
    required this.userId,
    this.onAnomaly,
  }) : appTracker = AppUsageTracker(),
       typingTracker = TypingTracker(),
       sensorCollector = SensorDataCollector();

  /// Starts all individual data collection agents.
  void startAll() {
    appTracker.startTracking(userId: userId); // Pass userId here
    sensorCollector.start(userId: userId); // Pass userId here
    print("All trackers started.");
  }

  /// Stops all individual data collection agents.
  void stopAll() {
    appTracker.stopTracking();
    sensorCollector.stop();
    print("All trackers stopped.");
  }

  /// Records a key press event for the typing agent.
  void onKeyDown(DateTime time) =>
      typingTracker.recordKeyPress(time, userId); // Pass userId here

  /// Records a key release event for the typing agent.
  void onKeyUp(DateTime time) =>
      typingTracker.recordKeyRelease(time, userId); // Pass userId here

  /// Centralized method to flush all collected data and send to the backend for analysis.
  Future<void> flushAllDataAndCheckAnomaly() async {
    // 1. Get all collected data from the agents.
    final payload = {
      'typing': typingTracker.getTypingData(),
      'app_usage': appTracker.getUsageData(),
      'sensor': sensorCollector.getSensorData(),
      'user_id': userId,
    };

    // 2. Clear the local data in each agent after collection to avoid sending duplicates.
    typingTracker.clearData();
    appTracker.clearData();
    sensorCollector.clearData();

    try {
      // 3. Send the unified payload to the backend for analysis.
      final response = await http.post(
        Uri.parse('$backendUrl/check_anomaly'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // 4. Handle the response and call the final UI callback.
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fusionScore = (data['fusion_score'] as num).toDouble();
        final anomalyDetected = data['anomaly'] as bool;

        // Notify the UI of the final, fused result.
        if (onAnomaly != null) {
          onAnomaly!(fusionScore, anomalyDetected);
        }
      } else {
        print("Failed to send data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending data to backend: $e");
    }
  }
}
