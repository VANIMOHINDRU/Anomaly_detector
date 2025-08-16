// typing_tracker.dart

class TypingTracker {
  // We no longer need these variables, as the MainController now holds them.
  // final String backendUrl;
  // final String userId;

  List<Map<String, dynamic>> _typingEvents = [];
  DateTime? _lastKeyUpTime;

  // The constructor no longer requires any arguments.
  TypingTracker();

  /// Records a key press event for the typing agent.
  void recordKeyPress(DateTime pressTime, String userId) {
    // Store press time for hold duration calculation.
    _lastKeyUpTime = pressTime;
  }

  /// Records a key release event for the typing agent.
  void recordKeyRelease(DateTime releaseTime, String userId) {
    if (_lastKeyUpTime != null) {
      double holdTime = releaseTime
          .difference(_lastKeyUpTime!)
          .inMilliseconds
          .toDouble();

      double flightTime = _typingEvents.isNotEmpty
          ? releaseTime
                .difference(DateTime.parse(_typingEvents.last['timestamp']))
                .inMilliseconds
                .toDouble()
          : 0.0;

      _typingEvents.add({
        'user': userId, // Add the user field here to match backend model
        'timestamp': releaseTime.toIso8601String(),
        'hold_time': holdTime,
        'flight_time': flightTime,
      });
    }
  }

  /// Returns the currently collected typing data.
  List<Map<String, dynamic>> getTypingData() {
    // Return a copy to prevent external modification of the internal list.
    return List.from(_typingEvents);
  }

  /// Clears the locally stored typing data.
  void clearData() {
    _typingEvents.clear();
  }
}
