// File: lib/screens/sai/analytics_screen.dart
import 'package:flutter/material.dart';

class SAIAnalyticsScreen extends StatelessWidget {
  const SAIAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'SAI Analytics Screen\n\nThis will show:\n• Performance trends\n• State-wise statistics\n• Test type analytics\n• Demographic insights\n\nComing Soon...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
