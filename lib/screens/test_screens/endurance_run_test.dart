import 'package:flutter/material.dart';

class EnduranceRunTest extends StatelessWidget {
  const EnduranceRunTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Endurance Run Test',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A2E6D),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                size: 80,
                color: Colors.blue,
              ),
              SizedBox(height: 24),
              Text(
                'Endurance Run Test',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2E6D),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This test will measure your cardiovascular fitness and stamina using the 12-minute Cooper test.\n\nImplement your ML model here following the same pattern as VerticalJumpTest.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Text(
                'Coming Soon...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}