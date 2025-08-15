import 'app_usage_tacker.dart';
import 'typing_tracker.dart';
import 'sensor_data_collector.dart';

typedef AnomalyCallback = void Function(String source, double score);

class MainController {
  final String backendUrl;
  final String userId;
  final AnomalyCallback? onAnomaly;

  late AppUsageTracker _appTracker;
  late TypingTracker _typingTracker;
  late SensorDataCollector _sensorCollector;

  MainController({
    required this.backendUrl,
    required this.userId,
    this.onAnomaly,
  }) {
    // Initialize trackers
    _appTracker = AppUsageTracker(
      backendUrl: backendUrl,
      userId: userId,
      anomalyCallback: (score) => _handleAnomaly("app", score),
    );

    _typingTracker = TypingTracker(
      backendUrl: backendUrl,
      userId: userId,
    );

    _sensorCollector = SensorDataCollector(
      backendUrl: backendUrl,
      userId: userId,
      anomalyCallback: (score) => _handleAnomaly("sensor", score),
    );
  }

  /// Start all trackers
  void startAll() {
    _appTracker.startTracking();
    _sensorCollector.start();
    print("All trackers started.");
  }

  /// Stop all trackers
  void stopAll() {
    _appTracker.stopTracking();
    _sensorCollector.stop();
    print("All trackers stopped.");
  }

  /// Typing events
  void onKeyDown(DateTime time) => _typingTracker.recordKeyPress(time);

  void onKeyUp(DateTime time) {
    _typingTracker.recordKeyRelease(time);

    if (_typingTracker.typingEvents.isNotEmpty) {
      final score =
          _typingTracker.calculateTypingScore(_typingTracker.typingEvents);
      if (score < 0.005) {
        _handleAnomaly("typing", score);
      }
    }
  }

  /// Flush all data manually
  Future<void> flushAllData() async {
    await _appTracker.sendUsageData();
    await _typingTracker.sendTypingData();
    await _sensorCollector.flush();
    print("All data flushed to backend.");
  }

  /// Expose private trackers and batches for the Flutter page
  TypingTracker get typingTracker => _typingTracker;
  SensorDataCollector get sensorCollector => _sensorCollector;
  AppUsageTracker get appTracker => _appTracker;

  /// Unified anomaly handler
  void _handleAnomaly(String source, double score) {
    print("Anomaly detected from $source! Score: $score");
    if (onAnomaly != null) {
      onAnomaly!(source, score);
    }
  }
}
