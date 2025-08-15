import 'dart:async';
import 'dart:convert';
import 'package:app_usage/app_usage.dart';
import 'package:http/http.dart' as http;

class AppUsageTracker {
  final String backendUrl;
  final String userId;
  final void Function(double score)? anomalyCallback;

  Timer? _timer;
  List<Map<String, dynamic>> _usageData = [];

  AppUsageTracker({
    required this.backendUrl,
    required this.userId,
    this.anomalyCallback,
  });

  /// Start tracking app usage periodically
  void startTracking({Duration interval = const Duration(minutes: 1)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (timer) async {
      await _collectUsage();
    });
  }

  void stopTracking() {
    _timer?.cancel();
  }

  /// Collect usage stats for last interval
  Future<void> _collectUsage() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(minutes: 1));

      AppUsage appUsage = AppUsage();
      List<AppUsageInfo> infos = await appUsage.getAppUsage(startDate, endDate);

      for (var info in infos) {
        _usageData.add({
          'timestamp': endDate.toIso8601String(),
          'app': info.packageName,
          'duration_minutes': info.usage.inMinutes.toDouble(),
        });
      }

      if (_usageData.length >= 5) {
        await sendUsageData();
      }
    } catch (e) {
      print("Error collecting app usage: $e");
    }
  }

  /// Calculate a simple anomaly score (example: long sessions may indicate anomaly)
  double _calculateAppScore(List<Map<String, dynamic>> batch) {
    if (batch.isEmpty) return 0.0;
    double avgDuration = batch
            .map((e) => (e['duration_minutes'] as num).toDouble())
            .reduce((a, b) => a + b) /
        batch.length;
    return avgDuration; // higher duration => more anomalous
  }

  List<Map<String, dynamic>> get usageData => _usageData;

  /// Send collected usage data to backend
  Future<void> sendUsageData() async {
    if (_usageData.isEmpty) return;

    final payload = {
      'user': userId,
      'usage': _usageData,
    };

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/app_usage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("App usage data sent successfully!");
      } else {
        print("Failed to send app usage data: ${response.statusCode}");
      }

      // Check anomaly
      double score = _calculateAppScore(_usageData);
      if (anomalyCallback != null && score > 7.0) {
        // threshold example
        anomalyCallback!(score);
      }
    } catch (e) {
      print("Error sending app usage data: $e");
    }

    _usageData.clear();
  }
}
