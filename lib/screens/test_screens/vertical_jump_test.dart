// File: lib/screens/test_screens/vertical_jump_test.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/ml_service.dart';

class VerticalJumpTest extends StatefulWidget {
  const VerticalJumpTest({Key? key}) : super(key: key);

  @override
  State<VerticalJumpTest> createState() => _VerticalJumpTestState();
}

class _VerticalJumpTestState extends State<VerticalJumpTest> {
  int _currentStep = 0;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  String? _videoPath;
  Map<String, dynamic>? _analysisResults;
  TestResult? _testResult;

  final VerticalJumpMLService _mlService = VerticalJumpMLService();

  final List<String> _instructions = [
    "Position your phone 2-3 meters away at waist height",
    "Stand with feet shoulder-width apart",
    "Keep your arms at your sides",
    "When ready, jump as high as possible",
    "Land safely on both feet",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Vertical Jump Test',
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
      body: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildInstructionsStep();
      case 1:
        return _buildRecordingStep();
      case 2:
        return _buildAnalysisStep();
      case 3:
        return _buildResultsStep();
      default:
        return _buildInstructionsStep();
    }
  }

  Widget _buildInstructionsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Test Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange,
                  Colors.deepOrange,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.keyboard_double_arrow_up,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vertical Jump Test',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Measures explosive leg power and jump height',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTestSpecs(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Instructions',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2E6D),
            ),
          ),

          const SizedBox(height: 16),

          // Instructions List
          ...List.generate(_instructions.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _instructions[index],
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Color(0xFF0A2E6D),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 32),

          // Safety Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safety First!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ensure you have adequate space and a safe landing area. Warm up before attempting the test.',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Start Test Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Test',
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
    );
  }

  Widget _buildTestSpecs() {
    return Row(
      children: [
        _buildSpecItem(Icons.access_time, '5 min', 'Duration'),
        const SizedBox(width: 20),
        _buildSpecItem(Icons.videocam, '30s', 'Recording'),
        const SizedBox(width: 20),
        _buildSpecItem(Icons.straighten, '3 attempts', 'Tries'),
      ],
    );
  }

  Widget _buildSpecItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Camera Preview Placeholder
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isRecording ? Colors.red : Colors.grey,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  // Camera preview would go here
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam,
                          size: 80,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Camera Preview',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Recording indicator
                  if (_isRecording)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'REC',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Guidelines overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: JumpGuidelinesPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recording Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Back Button
              IconButton(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.all(16),
                ),
              ),

              // Record Button
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Colors.orange,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : Colors.orange).withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

              // Switch Camera Button
              IconButton(
                onPressed: () {
                  // TODO: Implement camera switch
                },
                icon: const Icon(Icons.flip_camera_ios, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            _isRecording ? 'Recording... Perform your jump!' : 'Tap to start recording',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: _isRecording ? Colors.red : const Color(0xFF0A2E6D),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnalysisStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Analysis Animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                Icon(
                  Icons.analytics,
                  size: 40,
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Analyzing Your Jump',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2E6D),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Our AI is analyzing your vertical jump performance...',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Analysis Steps
          Column(
            children: [
              _buildAnalysisStepItem('Detecting jump phases', true),
              _buildAnalysisStepItem('Measuring jump height', _isAnalyzing),
              _buildAnalysisStepItem('Analyzing technique', false),
              _buildAnalysisStepItem('Calculating score', false),
            ],
          ),

          const SizedBox(height: 32),

          if (!_isAnalyzing)
            ElevatedButton(
              onPressed: () {
                // Simulate going back to record again
                setState(() => _currentStep = 1);
              },
              child: const Text('Record Again'),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisStepItem(String text, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.orange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.orange : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isActive ? Colors.orange : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: isActive
                ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: isActive ? Colors.orange : Colors.grey[600],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    if (_testResult == null) return const Center(child: CircularProgressIndicator());

    final results = _testResult!.rawAnalysis;
    final score = _testResult!.score;
    final jumpHeight = results['jumpHeight'] as double? ?? 0.0;
    final airTime = results['airTime'] as double? ?? 0.0;
    final landingStability = results['landingStability'] as double? ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Score Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getScoreColor(score),
                  _getScoreColor(score).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '${score.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Your Score',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getScoreCategory(score),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Detailed Results
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Details',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2E6D),
                  ),
                ),
                const SizedBox(height: 16),
                _buildResultRow('Jump Height', '${jumpHeight.toStringAsFixed(1)} cm', Icons.height),
                _buildResultRow('Air Time', '${airTime.toStringAsFixed(2)} sec', Icons.timer),
                _buildResultRow('Landing Stability', '${(landingStability * 100).toInt()}%', Icons.balance),
                _buildResultRow('Technique Score', '${((landingStability * 100).toInt())}%', Icons.sports_gymnastics),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveResult,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Save Result',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF0A2E6D),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() async {
    if (!_isRecording) {
      // Start recording
      setState(() => _isRecording = true);

      // TODO: Implement actual video recording
      // Example: Start camera recording

      // Simulate 10-second recording
      await Future.delayed(const Duration(seconds: 10));

      setState(() => _isRecording = false);

      // Simulate video path
      _videoPath = '/path/to/recorded/video.mp4';

      // Move to analysis step
      setState(() => _currentStep = 2);

      // Start AI analysis
      _analyzeVideo();
    } else {
      // Stop recording
      setState(() => _isRecording = false);
    }
  }

  void _analyzeVideo() async {
    if (_videoPath == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // Run ML analysis
      final results = await _mlService.analyzeVideo(_videoPath!);

      // Validate test execution
      final isValid = await _mlService.validateTestExecution(_videoPath!);

      // Calculate score
      final score = await _mlService.calculateScore(results);

      // Create test result
      _testResult = TestResult(
        testType: 'vertical_jump',
        rawAnalysis: results,
        score: score,
        isValid: isValid,
        timestamp: DateTime.now(),
        videoPath: _videoPath!,
      );

      setState(() {
        _analysisResults = results;
        _isAnalyzing = false;
        _currentStep = 3;
      });

    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveResult() {
    if (_testResult != null) {
      // TODO: Save to Firebase/local storage
      // TODO: Update test completion status

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreCategory(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Very Good';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Average';
    return 'Needs Improvement';
  }
}

// Custom painter for jump guidelines overlay
class JumpGuidelinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Draw ground line
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      paint,
    );

    // Draw jump zone rectangle
    final rect = Rect.fromLTWH(
      size.width * 0.3,
      size.height * 0.2,
      size.width * 0.4,
      size.height * 0.6,
    );

    canvas.drawRect(rect, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}