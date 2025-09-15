// File: lib/screens/test_screens/vertical_jump_test.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/vertical_jump_ml_service.dart';
import '../../services/firestore_service.dart';
import '../../models/test_result.dart';

class VerticalJumpTest extends StatefulWidget {
  const VerticalJumpTest({Key? key}) : super(key: key);

  @override
  State<VerticalJumpTest> createState() => _VerticalJumpTestState();
}

class _VerticalJumpTestState extends State<VerticalJumpTest> {
  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  JumpAnalysisResult? _analysisResult;

  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  String? _videoPath;
  String _currentStep = 'setup'; // setup, record, review, analyze, results

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeML();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
        );
        await _cameraController!.initialize();
        setState(() {});
      }
    } catch (e) {
      _showMessage('Camera initialization failed: $e');
    }
  }

  Future<void> _initializeML() async {
    try {
      await VerticalJumpMLService.initializeModel();
    } catch (e) {
      _showMessage('ML model initialization failed: $e');
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showMessage('Camera not ready');
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _currentStep = 'record';
      });
      _showMessage('Recording started! Perform your vertical jump.', isError: false);
    } catch (e) {
      _showMessage('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final video = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoPath = video.path;
        _currentStep = 'review';
      });

      await _initializeVideoPlayer();
      _showMessage('Recording stopped! Review your jump.', isError: false);
    } catch (e) {
      _showMessage('Failed to stop recording: $e');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoPath == null) return;

    try {
      _videoPlayerController = VideoPlayerController.file(File(_videoPath!));
      await _videoPlayerController!.initialize();
      setState(() {});
    } catch (e) {
      _showMessage('Failed to load video: $e');
    }
  }

  Future<void> _pickVideoFromStorage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _videoPath = result.files.single.path!;
          _currentStep = 'review';
        });

        await _initializeVideoPlayer();
        _showMessage('Video loaded successfully!', isError: false);
      }
    } catch (e) {
      _showMessage('Failed to pick video: $e');
    }
  }

  Future<void> _analyzeJump() async {
    if (_videoPath == null) {
      _showMessage('No video to analyze');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _currentStep = 'analyze';
    });

    try {
      _analysisResult = await VerticalJumpMLService.analyzeJumpVideo(_videoPath!);

      if (_analysisResult!.hasError) {
        _showMessage('Analysis failed: ${_analysisResult!.errorMessage}');
      } else {
        await _saveResults();
        setState(() {
          _hasAnalyzed = true;
          _currentStep = 'results';
        });
        _showMessage('Analysis completed!', isError: false);
      }
    } catch (e) {
      _showMessage('Analysis error: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveResults() async {
    if (_analysisResult == null || !_analysisResult!.isValid) return;

    try {
      final testResult = TestResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        testType: 'vertical_jump',
        score: _analysisResult!.maxHeight,
        timestamp: DateTime.now(),
        isValid: _analysisResult!.isValid,
        videoPath: _videoPath,
        rawAnalysis: _analysisResult!.toJson(),
        // Add the new required parameters
        athleteId: 'current_athlete_id', // You'll need to get this from your auth system
        scoreCategory: _getScoreCategory(_analysisResult!.maxHeight), // Implement this function
      );

      await FirestoreService.saveTestResult(testResult);
    } catch (e) {
      _showMessage('Failed to save results: $e');
    }
  }

// Add this helper function to determine score category
  String _getScoreCategory(double height) {
    if (height >= 70) return 'excellent';
    if (height >= 50) return 'good';
    if (height >= 30) return 'average';
    return 'poor';
  }

  void _retakeTest() {
    setState(() {
      _videoPath = null;
      _analysisResult = null;
      _hasAnalyzed = false;
      _currentStep = 'setup';
    });
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vertical Jump Test'),
        backgroundColor: const Color(0xFF0A2E6D),
        foregroundColor: Colors.white,
      ),
      body: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 'setup':
        return _buildSetupStep();
      case 'record':
        return _buildRecordStep();
      case 'review':
        return _buildReviewStep();
      case 'analyze':
        return _buildAnalyzeStep();
      case 'results':
        return _buildResultsStep();
      default:
        return _buildSetupStep();
    }
  }

  Widget _buildSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.fitness_center,
            size: 80,
            color: Color(0xFF0A2E6D),
          ),
          const SizedBox(height: 20),
          const Text(
            'Vertical Jump Test',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2E6D),
            ),
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('• Position camera at side view, 2-3 meters away'),
                  Text('• Ensure good lighting and clear background'),
                  Text('• Stand in center of camera frame'),
                  Text('• Jump as high as possible when ready'),
                  Text('• AI will analyze your jump height and technique'),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (_cameraController?.value.isInitialized == true)
            SizedBox(
              height: 200,
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record Jump'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickVideoFromStorage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Video'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordStep() {
    return Column(
      children: [
        if (_cameraController?.value.isInitialized == true)
          Expanded(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Recording in progress...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('Perform your vertical jump now!'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Recording'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        if (_videoPlayerController?.value.isInitialized == true)
          Expanded(
            child: AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController!),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Review Your Jump',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      _videoPlayerController?.seekTo(Duration.zero);
                      _videoPlayerController?.play();
                    },
                    icon: const Icon(Icons.play_arrow),
                  ),
                  IconButton(
                    onPressed: () => _videoPlayerController?.pause(),
                    icon: const Icon(Icons.pause),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _analyzeJump,
                      child: const Text('Analyze Jump'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _retakeTest,
                      child: const Text('Retake'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeStep() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2E6D)),
          ),
          SizedBox(height: 20),
          Text(
            'Analyzing your jump...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('AI is processing your video to measure jump height and technique'),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    if (_analysisResult == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.analytics,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          const Text(
            'Jump Analysis Results',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2E6D),
            ),
          ),
          const SizedBox(height: 30),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildResultItem(
                    'Maximum Height',
                    '${_analysisResult!.maxHeight.toStringAsFixed(1)} cm',
                    Icons.height,
                  ),
                  _buildResultItem(
                    'Average Height',
                    '${_analysisResult!.avgHeight.toStringAsFixed(1)} cm',
                    Icons.trending_up,
                  ),
                  _buildResultItem(
                    'Technique Score',
                    '${(_analysisResult!.techniqueScore * 100).toStringAsFixed(0)}%',
                    Icons.star,
                  ),
                  _buildResultItem(
                    'Consistency',
                    '${(_analysisResult!.consistency * 100).toStringAsFixed(0)}%',
                    Icons.linear_scale,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _retakeTest,
                  child: const Text('Take Another Test'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0A2E6D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2E6D),
            ),
          ),
        ],
      ),
    );
  }
}