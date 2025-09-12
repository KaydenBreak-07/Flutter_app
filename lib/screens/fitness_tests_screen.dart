// File: lib/screens/fitness_tests_screen.dart
import 'package:flutter/material.dart';
import 'test_screens/vertical_jump_test.dart';
import 'test_screens/situps_test.dart';
import 'test_screens/endurance_run_test.dart';
import 'test_screens/shuttle_run_test.dart';

class FitnessTestsScreen extends StatefulWidget {
  const FitnessTestsScreen({Key? key}) : super(key: key);

  @override
  State<FitnessTestsScreen> createState() => _FitnessTestsScreenState();
}

class _FitnessTestsScreenState extends State<FitnessTestsScreen> {
  // Test completion status (you can load from SharedPreferences/Firebase)
  Map<String, bool> testStatus = {
    'vertical_jump': false,
    'situps': false,
    'endurance_run': false,
    'shuttle_run': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Fitness Tests',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A2E6D),
                    Color(0xFF1565C0),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A2E6D).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SAI Fitness Assessment',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete all tests to get your talent assessment score',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Available Tests',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2E6D),
              ),
            ),

            const SizedBox(height: 16),

            // Test Cards
            _buildTestCard(
              title: 'Vertical Jump Test',
              description: 'Measure explosive leg power and jump height',
              icon: Icons.keyboard_double_arrow_up,
              color: Colors.orange,
              duration: '5 min',
              difficulty: 'Medium',
              completed: testStatus['vertical_jump']!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerticalJumpTest()),
              ),
            ),

            const SizedBox(height: 16),

            _buildTestCard(
              title: 'Sit-ups Test',
              description: 'Assess core strength and muscular endurance',
              icon: Icons.sports_gymnastics,
              color: Colors.green,
              duration: '2 min',
              difficulty: 'Easy',
              completed: testStatus['situps']!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SitupsTest()),
              ),
            ),

            const SizedBox(height: 16),

            _buildTestCard(
              title: 'Shuttle Run Test',
              description: 'Test agility, speed, and change of direction',
              icon: Icons.directions_run,
              color: Colors.purple,
              duration: '3 min',
              difficulty: 'Hard',
              completed: testStatus['shuttle_run']!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShuttleRunTest()),
              ),
            ),

            const SizedBox(height: 16),

            _buildTestCard(
              title: 'Endurance Run Test',
              description: 'Measure cardiovascular fitness and stamina',
              icon: Icons.timer,
              color: Colors.blue,
              duration: '12 min',
              difficulty: 'Hard',
              completed: testStatus['endurance_run']!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EnduranceRunTest()),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button (only show when all tests completed)
            if (_allTestsCompleted())
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _submitToSAI(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Assessment to SAI',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    int completedTests = testStatus.values.where((status) => status).length;
    double progress = completedTests / testStatus.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            Text(
              '$completedTests/${testStatus.length} tests',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String duration,
    required String difficulty,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: completed
              ? Border.all(color: Colors.green, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A2E6D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (completed)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(Icons.access_time, duration, Colors.blue),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.signal_cellular_alt,
                  difficulty,
                  difficulty == 'Easy' ? Colors.green :
                  difficulty == 'Medium' ? Colors.orange : Colors.red,
                ),
                const Spacer(),
                if (completed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  bool _allTestsCompleted() {
    return testStatus.values.every((status) => status);
  }

  void _submitToSAI() {
    // TODO: Implement SAI submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assessment submitted to SAI successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}