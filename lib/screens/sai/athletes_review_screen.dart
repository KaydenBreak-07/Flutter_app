// File: lib/screens/sai/athletes_review_screen.dart
import 'package:flutter/material.dart';

class AthletesReviewScreen extends StatelessWidget {
  const AthletesReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Athletes Review'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Athletes Review Screen\n\nThis will show:\n• All registered athletes\n• Their test results\n• Performance rankings\n• Flagged cases\n\nComing Soon...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}