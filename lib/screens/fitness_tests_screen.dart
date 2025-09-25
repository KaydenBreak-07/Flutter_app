import 'package:flutter/material.dart';
import 'video_upload_screen.dart'; // Your new video upload screen
import '../models/test_result.dart';
import '../services/firestore_service.dart';

class FitnessTestsScreen extends StatefulWidget {
  const FitnessTestsScreen({Key? key}) : super(key: key);

  @override
  _FitnessTestsScreenState createState() => _FitnessTestsScreenState();
}

class _FitnessTestsScreenState extends State<FitnessTestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<TestResult> _recentResults = [];

  @override
  void initState() {
    super.initState();
    _loadRecentResults();
  }

  Future<void> _loadRecentResults() async {
    try {
      // Load recent test results for current user
      final results = await FirestoreService.getRecentTestResults();
      setState(() {
        _recentResults = results;
      });
    } catch (e) {
      print('Error loading recent results: $e');
    }
  }

  Future<void> _navigateToTest(String testType) async {
    // Show pose instructions first
    bool? shouldProceed = await _showPoseInstructions(testType);

    if (shouldProceed == true) {
      // Navigate to video upload screen
      final TestResult? result = await Navigator.push<TestResult>(
        context,
        MaterialPageRoute(
          builder: (context) => VideoUploadScreen(testType: testType, testTitle: 'Jump',),
        ),
      );

      if (result != null) {
        // Save result and refresh the list
        await FirestoreService.saveTestResult(result);
        _loadRecentResults();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${testType.replaceAll('_', ' ').toUpperCase()} test completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<bool?> _showPoseInstructions(String testType) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${testType.replaceAll('_', ' ').toUpperCase()} Instructions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getInstructions(testType)),
              const SizedBox(height: 16),
              const Text(
                'Make sure you:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Have good lighting'),
              const Text('• Keep the camera steady'),
              const Text('• Perform the movement clearly'),
              const Text('• Stay in the camera frame'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  String _getInstructions(String testType) {
    switch (testType) {
      case 'vertical_jump':
        return 'Stand with feet shoulder-width apart. Jump as high as you can with both feet leaving the ground simultaneously. Land softly on both feet.';
      case 'sprint':
        return 'Run at maximum speed for the designated distance. Maintain proper running form throughout.';
      case 'balance':
        return 'Stand on one foot for 30 seconds. Keep your balance without touching the ground with your other foot.';
      default:
        return 'Follow the standard procedure for this test.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Tests'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentResults,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test Categories
              Text(
                'Available Tests',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Test Cards
              _buildTestCard(
                'Vertical Jump',
                'vertical_jump',
                'Measure your explosive leg power',
                Icons.arrow_upward,
                Colors.blue,
              ),
              const SizedBox(height: 12),

              _buildTestCard(
                'Sprint Test',
                'sprint',
                'Analyze your running speed and form',
                Icons.directions_run,
                Colors.green,
              ),
              const SizedBox(height: 12),

              _buildTestCard(
                'Balance Test',
                'balance',
                'Evaluate your stability and balance',
                Icons.accessibility,
                Colors.orange,
              ),

              const SizedBox(height: 32),

              // Recent Results Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Results',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full results history
                      Navigator.pushNamed(context, '/test_history');
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recent Results List
              if (_recentResults.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assessment,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No test results yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete a fitness test to see your results here',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _recentResults.take(3).map((result) => _buildResultCard(result)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(String title, String testType, String description, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToTest(testType),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(TestResult result) {
    Color performanceColor;
    switch (result.performance.toLowerCase()) {
      case 'excellent':
        performanceColor = Colors.green;
        break;
      case 'good':
        performanceColor = Colors.blue;
        break;
      case 'average':
        performanceColor = Colors.orange;
        break;
      default:
        performanceColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  result.testType.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: performanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.performance,
                    style: TextStyle(
                      color: performanceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: ${result.score.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  _formatDate(result.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}