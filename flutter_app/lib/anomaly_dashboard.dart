import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'services/main_controller.dart'; // import your MainController

class AnomalyDashboard extends StatefulWidget {
  final String backendUrl;
  const AnomalyDashboard({super.key, required this.backendUrl});

  @override
  _AnomalyDashboardState createState() => _AnomalyDashboardState();
}

class _AnomalyDashboardState extends State<AnomalyDashboard> {
  late MainController _controller;
  bool _tracking = false;
  double _fusionScore = 0.0;
  bool _anomalyDetected = false;
  Timer? _periodicFlush;

  @override
  void initState() {
    super.initState();

    _controller = MainController(
      backendUrl: widget.backendUrl,
      userId: "user_123",
      onAnomaly: (source, score) {
        setState(() {
          _fusionScore = score;
          _anomalyDetected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Anomaly detected from $source! Score: $score"),
          ),
        );
      },
    );
  }

  void _startTracking() {
    _controller.startAll();
    setState(() {
      _tracking = true;
      _anomalyDetected = false;
      _fusionScore = 0.0;
    });

    // Start periodic flush & anomaly check every 10 seconds
    _periodicFlush = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_tracking) {
        timer.cancel();
        return;
      }
      await _flushAndCheckAnomaly();
    });
  }

  void _stopTracking() {
    _controller.stopAll();
    _periodicFlush?.cancel();
    setState(() {
      _tracking = false;
    });
  }

  /// Flush local data, send to backend, and update fusion score
  /// Flush local data, send to backend, and update fusion score
  Future<void> _flushAndCheckAnomaly() async {
    // Capture current batch before flushing, so we actually send it
    final payload = {
      'typing': List.from(_controller.typingTracker.typingEvents),
      'app_usage': List.from(_controller.appTracker.usageData),
      'sensor': List.from(_controller.sensorCollector.batch),
    };

    // Flush all trackers (sends to backend & clears local lists)
    await _controller.flushAllData();

    try {
      final response = await http.post(
        Uri.parse('${widget.backendUrl}/check_anomaly'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fusionScore = (data['fusion_score'] as num).toDouble();
          _anomalyDetected = data['anomaly'] as bool;
        });

        // Show SnackBar only when anomaly is detected
        if (_anomalyDetected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Anomaly detected! Fusion Score: ${_fusionScore.toStringAsFixed(4)}"),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint("Failed to send data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error sending data: $e");
    }
  }

  Future<void> _sendData() async {
    await _flushAndCheckAnomaly();
  }

  @override
  void dispose() {
    _controller.stopAll();
    _periodicFlush?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomaly Detection Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.deepPurple.shade50,
              child: ListTile(
                title: const Text("Tracking Status"),
                subtitle: Text(_tracking ? "Running" : "Stopped"),
                trailing: Switch(
                  value: _tracking,
                  onChanged: (val) {
                    val ? _startTracking() : _stopTracking();
                  },
                  activeColor: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: _anomalyDetected
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: ListTile(
                title: const Text("Fusion Score"),
                subtitle: Text(_fusionScore.toStringAsFixed(4)),
                trailing: _anomalyDetected
                    ? const Icon(Icons.warning, color: Colors.red, size: 32)
                    : const Icon(Icons.check_circle,
                        color: Colors.green, size: 32),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _sendData,
              icon: const Icon(Icons.send),
              label: const Text("Flush Data / Check Anomaly"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
