// File: lib/screens/sai/settings_screen.dart
import 'package:flutter/material.dart';

class SAISettingsScreen extends StatelessWidget {
  const SAISettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'SAI Settings Screen\n\nThis will include:\n• Account settings\n• Permission management\n• Data export options\n• System preferences\n\nComing Soon...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}