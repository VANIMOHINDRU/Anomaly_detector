import 'dart:async';
import 'package:flutter/material.dart';
import 'services/main_controller.dart';

class AnomalyDashboard extends StatefulWidget {
  final String backendUrl;
  const AnomalyDashboard({super.key, required this.backendUrl});

  @override
  _AnomalyDashboardState createState() => _AnomalyDashboardState();
}

class _AnomalyDashboardState extends State<AnomalyDashboard> {
  late MainController _controller;
  bool _tracking = false;
  bool _isProcessing = false;
  double _fusionScore = 0.0;
  bool _anomalyDetected = false;
  Timer? _periodicFlush;
  final String _userId = "user_123"; // Declare userId here for easy access

  @override
  void initState() {
    super.initState();
    _controller = MainController(
      backendUrl: widget.backendUrl,
      userId: _userId, // Pass the declared userId to the controller
      onAnomaly: (score, detected) {
        setState(() {
          _fusionScore = score;
          _anomalyDetected = detected;
          _isProcessing = false;
        });

        if (detected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "⚠️ Anomaly detected! Fusion Score: ${score.toStringAsFixed(4)}",
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
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

    _periodicFlush = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!_tracking) {
        timer.cancel();
        return;
      }
      _flushAndCheckAnomaly();
    });
  }

  void _stopTracking() {
    _controller.stopAll();
    _periodicFlush?.cancel();
    setState(() {
      _tracking = false;
    });
  }

  Future<void> _flushAndCheckAnomaly() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    await _controller.flushAllDataAndCheckAnomaly();
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
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  _tracking ? Icons.track_changes : Icons.stop_circle,
                  color: _tracking ? Colors.green : Colors.grey,
                ),
                title: const Text(
                  "Tracking Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_tracking ? "Running..." : "Stopped"),
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
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: _anomalyDetected
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: ListTile(
                leading: Icon(
                  _anomalyDetected ? Icons.warning : Icons.check_circle,
                  color: _anomalyDetected ? Colors.red : Colors.green,
                  size: 32,
                ),
                title: const Text(
                  "Fusion Score",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_fusionScore.toStringAsFixed(4)),
                trailing: Text(
                  _anomalyDetected ? "ANOMALY" : "NORMAL",
                  style: TextStyle(
                    color: _anomalyDetected ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Generate Typing & App Usage Data",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Enter text here...",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.keyboard),
                      ),
                      onChanged: (_) {
                        final now = DateTime.now();
                        _controller.onKeyDown(now);
                        _controller.onKeyUp(now);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isProcessing
                ? const CircularProgressIndicator(color: Colors.deepPurple)
                : ElevatedButton.icon(
                    onPressed: _flushAndCheckAnomaly,
                    icon: const Icon(Icons.send),
                    label: const Text("Flush Data & Check Anomaly"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
