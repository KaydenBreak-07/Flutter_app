// File: lib/screens/test_screens/vertical_jump_test.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/vertical_jump_ml_service.dart';
import '../../services/firestore_service.dart';
import '../../models/test_result.dart';

class VerticalJumpTest extends StatefulWidget {
  const VerticalJumpTest({Key? key}) : super(key: key);

  @override
  State<VerticalJumpTest> createState() => _VerticalJumpTestState();
}

class _VerticalJumpTestState extends State<VerticalJumpTest> {
  final VerticalJumpMLService _mlService = VerticalJumpMLService();

  bool _isModelLoaded = false;
  bool _isAnalyzing = false;
  bool _isTestComplete = false;

  File? _selectedVideoFile;
  String? _videoFileName;
  int _videoSizeKB = 0;

  double? _jumpHeight;
  double? _hangTime;
  double? _confidenceScore;
  String? _analysisError;

  List<TestResult> _previousResults = [];
  int _attemptNumber = 1;
  final int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initializeML();
    _loadPreviousResults();
  }

  @override
  void dispose() {
    _mlService.dispose();
    super.dispose();
  }

  Future<void> _initializeML() async {
    try {
      await _mlService.loadModel();
      if (mounted) {
        setState(() {
          _isModelLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisError = 'Failed to load ML model: $e';
        });
      }
    }
  }

  Future<void> _loadPreviousResults() async {
    try {
      final results = await FirestoreService.getTestResults('vertical_jump');
      if (mounted) {
        setState(() {
          _previousResults = results.take(5).toList(); // Show last 5 results
          _attemptNumber = results.length + 1;
        });
      }
    } catch (e) {
      print('Error loading previous results: $e');
    }
  }

  Future<void> _selectVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: false, // Don't load data immediately for large files
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSizeBytes = await file.length();
        final fileSizeKB = fileSizeBytes ~/ 1024;

        // Check file size (limit to 50MB)
        if (fileSizeKB > 50 * 1024) {
          _showError('Video file is too large. Please select a file smaller than 50MB.');
          return;
        }

        // Check file extension
        final fileName = result.files.single.name.toLowerCase();
        if (!fileName.endsWith('.mp4') &&
            !fileName.endsWith('.mov') &&
            !fileName.endsWith('.avi')) {
          _showError('Please select a video file (MP4, MOV, or AVI).');
          return;
        }

        setState(() {
          _selectedVideoFile = file;
          _videoFileName = result.files.single.name;
          _videoSizeKB = fileSizeKB;
          _analysisError = null;
          _jumpHeight = null;
          _hangTime = null;
          _confidenceScore = null;
          _isTestComplete = false;
        });

        _showSuccessSnackBar('Video selected successfully! Ready to analyze.');
      }
    } catch (e) {
      _showError('Error selecting video: $e');
    }
  }

  Future<void> _analyzeVideo() async {
    if (_selectedVideoFile == null || !_isModelLoaded) return;

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      // Read video file as bytes
      final videoBytes = await _selectedVideoFile!.readAsBytes();

      // Analyze with ML model
      final result = await _mlService.analyzeJumpFromVideo(videoBytes);

      if (result != null && mounted) {
        setState(() {
          _jumpHeight = result['jumpHeight'];
          _hangTime = result['hangTime'];
          _confidenceScore = result['confidence'];
          _isAnalyzing = false;
          _isTestComplete = true;
        });

        // Auto-save if confidence is high enough
        if (_confidenceScore != null && _confidenceScore! > 0.7) {
          await _saveTestResult();
        } else {
          _showWarning('Low confidence score. Please review results before saving.');
        }
      } else {
        setState(() {
          _analysisError = 'Could not analyze the video. Please ensure it shows a clear vertical jump.';
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisError = 'Analysis failed: $e';
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _saveTestResult() async {
    if (_jumpHeight == null) return;

    try {
      final testResult = TestResult(
        testType: 'vertical_jump',
        score: _jumpHeight!,
        unit: 'cm',
        timestamp: DateTime.now(),
        isValid: true,
        rawData: {
          'jumpHeight': _jumpHeight,
          'hangTime': _hangTime,
          'confidence': _confidenceScore,
          'attemptNumber': _attemptNumber,
          'videoFileName': _videoFileName,
          'analysisMethod': 'ml_video_analysis',
        },
      );

      await FirestoreService.saveTestResult(testResult);

      if (mounted) {
        _showSuccessSnackBar('Test result saved successfully!');
        await _loadPreviousResults(); // Refresh results
        _resetTest();
      }
    } catch (e) {
      _showError('Error saving result: $e');
    }
  }

  void _resetTest() {
    setState(() {
      _selectedVideoFile = null;
      _videoFileName = null;
      _videoSizeKB = 0;
      _jumpHeight = null;
      _hangTime = null;
      _confidenceScore = null;
      _analysisError = null;
      _isTestComplete = false;
      _isAnalyzing = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A2E6D),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Card
            _buildInstructionsCard(),
            const SizedBox(height: 20),

            // ML Model Status
            _buildMLStatusCard(),
            const SizedBox(height: 20),

            // Video Upload Section
            _buildVideoUploadCard(),
            const SizedBox(height: 20),

            // Analysis Results
            if (_isTestComplete) _buildResultsCard(),
            if (_analysisError != null) _buildErrorCard(),
            const SizedBox(height: 20),

            // Previous Results
            if (_previousResults.isNotEmpty) _buildPreviousResultsCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A2E6D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF0A2E6D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'How to Record Your Jump',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2E6D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionItem(
            '1.',
            'Record a side-view video of your vertical jump',
          ),
          _buildInstructionItem(
            '2.',
            'Ensure you are clearly visible against a plain background',
          ),
          _buildInstructionItem(
            '3.',
            'Jump straight up and land in the same spot',
          ),
          _buildInstructionItem(
            '4.',
            'Keep the camera steady and at a good distance',
          ),
          _buildInstructionItem(
            '5.',
            'Video should be 3-10 seconds long in MP4/MOV format',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0A2E6D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isModelLoaded ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isModelLoaded ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isModelLoaded ? Icons.check_circle : Icons.hourglass_empty,
            color: _isModelLoaded ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isModelLoaded
                  ? 'AI Model Loaded - Ready for Analysis'
                  : 'Loading AI Model...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isModelLoaded ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoUploadCard() {
    return Container(
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
            'Upload Video',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2E6D),
            ),
          ),
          const SizedBox(height: 16),

          // Video Selection
          GestureDetector(
            onTap: _isModelLoaded && !_isAnalyzing ? _selectVideoFile : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _selectedVideoFile != null
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedVideoFile != null
                      ? Colors.green
                      : Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedVideoFile != null
                        ? Icons.video_file
                        : Icons.upload_file,
                    size: 48,
                    color: _selectedVideoFile != null
                        ? Colors.green
                        : Colors.grey[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedVideoFile != null
                        ? 'Video Selected'
                        : 'Tap to Select Video',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedVideoFile != null
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
                  ),
                  if (_videoFileName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _videoFileName!,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${(_videoSizeKB / 1024).toStringAsFixed(1)} MB',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Analyze Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedVideoFile != null && _isModelLoaded && !_isAnalyzing)
                  ? _analyzeVideo
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2E6D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isAnalyzing
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Analyzing...'),
                ],
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics),
                  SizedBox(width: 8),
                  Text(
                    'Analyze Jump',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Analysis Results',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2E6D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Score
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2E6D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Jump Height',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_jumpHeight?.toStringAsFixed(1)} cm',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2E6D),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Additional Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Hang Time',
                  '${_hangTime?.toStringAsFixed(2)} sec',
                  Icons.timer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Confidence',
                  '${((_confidenceScore ?? 0) * 100).toStringAsFixed(0)}%',
                  Icons.psychology,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveTestResult,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save Result'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetTest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A2E6D),
                    side: const BorderSide(color: Color(0xFF0A2E6D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2E6D),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _analysisError!,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousResultsCard() {
    return Container(
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
            'Previous Results',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2E6D),
            ),
          ),
          const SizedBox(height: 16),
          ...(_previousResults.map((result) => _buildResultItem(result)).toList()),
        ],
      ),
    );
  }

  Widget _buildResultItem(TestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2E6D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.height,
              color: Color(0xFF0A2E6D),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.score.toStringAsFixed(1)} cm',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2E6D),
                  ),
                ),
                Text(
                  _formatResultDate(result.timestamp),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (result.rawData?['confidence'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getConfidenceColor(result.rawData!['confidence']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${((result.rawData!['confidence'] as double) * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _getConfidenceColor(result.rawData!['confidence']),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatResultDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }
}