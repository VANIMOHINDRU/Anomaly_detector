import 'package:flutter/material.dart';
import 'anomaly_dashboard.dart'; // adjust path

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anomaly App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const AnomalyDashboard(
        backendUrl: "http://192.168.56.1:8000", // replace with your backend URL
      ),
    );
  }
}
