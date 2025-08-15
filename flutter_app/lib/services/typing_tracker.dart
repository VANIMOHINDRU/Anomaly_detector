import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class TypingTracker {
  final String backendUrl;
  final String userId;

  List<Map<String, dynamic>> typingEvents = [];
  DateTime? _lastKeyUpTime;

  TypingTracker({
    required this.backendUrl,
    required this.userId,
  });

  /// Call this on each key press (keydown)
  void recordKeyPress(DateTime pressTime) {
    // Store press time for hold duration calculation
    _lastKeyUpTime = pressTime;
  }

  /// Call this on each key release (keyup)
  void recordKeyRelease(DateTime releaseTime) {
    if (_lastKeyUpTime != null) {
      double holdTime =
          releaseTime.difference(_lastKeyUpTime!).inMilliseconds.toDouble();

      double flightTime = typingEvents.isNotEmpty
          ? releaseTime
              .difference(DateTime.parse(typingEvents.last['timestamp']))
              .inMilliseconds
              .toDouble()
          : 0.0;

      typingEvents.add({
        'timestamp': releaseTime.toIso8601String(),
        'hold_time': holdTime,
        'flight_time': flightTime,
      });

      // If we have collected enough events, send batch to backend
      if (typingEvents.length >= 10) {
        sendTypingData();
      }
    }
  }

  /// Calculate a simple typing score (inverse of average hold time)
  double calculateTypingScore(List<Map<String, dynamic>> events) {
    if (events.isEmpty) return 0.0;
    double avgHold = events
            .map((e) => (e['hold_time'] as num).toDouble())
            .reduce((a, b) => a + b) /
        events.length;
    return avgHold > 0 ? 1.0 / avgHold : 0.0;
  }

  /// Send collected typing data to backend
  Future<void> sendTypingData() async {
    if (typingEvents.isEmpty) return;

    double typingScore = calculateTypingScore(typingEvents);

    final payload = {
      'user': userId,
      'events': typingEvents,
      'typing_score': typingScore,
    };

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/typing'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("Typing data sent successfully!");
      } else {
        print("Failed to send typing data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending typing data: $e");
    }

    // Clear events after sending
    typingEvents.clear();
  }
}
