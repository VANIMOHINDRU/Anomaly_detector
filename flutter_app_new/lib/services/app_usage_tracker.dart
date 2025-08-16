import 'dart:async';
import 'package:app_usage/app_usage.dart';

class AppUsageTracker {
  Timer? _timer;
  List<Map<String, dynamic>> _usageData = [];

  AppUsageTracker();

  /// Start tracking app usage periodically
  void startTracking({
    required String userId,
    Duration interval = const Duration(minutes: 1),
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (timer) async {
      await _collectUsage(userId);
    });
  }

  void stopTracking() {
    _timer?.cancel();
  }

  /// Collect usage stats for the last interval
  Future<void> _collectUsage(String userId) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(minutes: 1));

      AppUsage appUsage = AppUsage();
      List<AppUsageInfo> infos = await appUsage.getAppUsage(startDate, endDate);

      for (var info in infos) {
        _usageData.add({
          'user': userId, // Add the user field
          'timestamp': endDate.toIso8601String(),
          'app': info.packageName,
          'duration_minutes': info.usage.inMinutes.toDouble(),
        });
      }
    } catch (e) {
      print("Error collecting app usage: $e");
    }
  }

  /// Returns the currently collected usage data.
  List<Map<String, dynamic>> getUsageData() {
    return List.from(_usageData);
  }

  /// Clears the locally stored usage data.
  void clearData() {
    _usageData.clear();
  }
}
