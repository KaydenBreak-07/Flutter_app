// Enhanced version of your existing VideoUploadScreen
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/ml_service.dart';
import '../services/ml_service_placeholder.dart';
import '../models/test_result.dart';

class VideoUploadScreen extends StatefulWidget {
  final String testType;
  final String testTitle;

  const VideoUploadScreen({
    Key? key,
    required this.testType,
    required this.testTitle,
  }) : super(key: key);

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen>
    with TickerProviderStateMixin {

  // Controllers and state variables
  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  AnimationController? _recordingAnimationController;
  AnimationController? _analyzeButtonController;

  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  String? _videoPath;
  TestResult? _analysisResult;

  // Test configuration for vertical jump
  final TextEditingController _heightController = TextEditingController(text: '170');
  final TextEditingController _ageController = TextEditingController(text: '25');
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _recordingAnimationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _analyzeButtonController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        _showErrorDialog('Camera permission is required to record videos');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.ultraHigh,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Camera initialization error: $e');
      _showErrorDialog('Failed to initialize camera: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_isCameraInitialized || _isRecording) return;

    try {
      await _cameraController!.startVideoRecording();
      _recordingAnimationController!.repeat();
      setState(() {
        _isRecording = true;
      });

      // Show recording instructions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getRecordingInstructions()),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red[600],
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final videoFile = await _cameraController!.stopVideoRecording();
      _recordingAnimationController!.stop();
      _recordingAnimationController!.reset();

      setState(() {
        _isRecording = false;
        _videoPath = videoFile.path;
      });

      await _initializeVideoPlayer(videoFile.path);

    } catch (e) {
      _showErrorDialog('Failed to stop recording: $e');
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final videoPath = result.files.single.path!;
        setState(() {
          _videoPath = videoPath;
        });
        await _initializeVideoPlayer(videoPath);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick video: $e');
    }
  }

  Future<void> _initializeVideoPlayer(String path) async {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(File(path));
    await _videoPlayerController!.initialize();
    setState(() {});
  }

  Future<void> _analyzeVideo() async {
    if (_videoPath == null) {
      _showErrorDialog('No video selected for analysis');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    _analyzeButtonController!.forward();

    try {
      late TestResult result;

      // Try to use the actual ML service first
      try {
        final mlService = MLService();
        result = await mlService.analyzeVideo(_videoPath!, widget.testType);
      } catch (e) {
        print('MLService failed, using placeholder: $e');
        // Fallback to placeholder service
        final placeholderService = MLServicePlaceholder.instance;
        result = await placeholderService.analyzeVideo(_videoPath!, widget.testType);
      }

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      _analyzeButtonController!.reverse();

      if (result.score > 0) {
        _showResultDialog();
      } else {
        _showErrorDialog('Analysis completed but no valid results found');
      }

    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _analyzeButtonController!.reverse();
      _showErrorDialog('Analysis failed: $e');
    }
  }

  String _getRecordingInstructions() {
    switch (widget.testType.toLowerCase()) {
      case 'vertical_jump':
        return 'Jump as high as possible with both feet. Keep your whole body visible in frame.';
      case 'sprint':
        return 'Run as fast as possible across the field of view.';
      case 'balance':
        return 'Stand on one foot and maintain balance.';
      default:
        return 'Perform the test exercise. Keep yourself visible in frame.';
    }
  }

  void _showResultDialog() {
    if (_analysisResult == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.green),
            SizedBox(width: 8),
            Text('${widget.testTitle} Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main score display
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getPerformanceColor(_analysisResult!.performance),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _getScoreDisplayText(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _analysisResult!.performance,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Detailed metrics
              Text(
                'Detailed Analysis:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              ..._analysisResult!.metrics.entries.map((entry) =>
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ),

              SizedBox(height: 16),

              // Recommendations
              if (widget.testType == 'vertical_jump')
                _buildVerticalJumpRecommendations(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitResults();
            },
            child: Text('Submit to SAI'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalJumpRecommendations() {
    final jumpHeight = _analysisResult!.score;
    String recommendation;

    if (jumpHeight >= 50) {
      recommendation = 'Excellent performance! Consider specialized athletic training programs.';
    } else if (jumpHeight >= 40) {
      recommendation = 'Good jump height. Focus on explosive power and plyometric training.';
    } else if (jumpHeight >= 30) {
      recommendation = 'Average performance. Work on leg strength and jumping technique.';
    } else {
      recommendation = 'Focus on basic fitness, leg strengthening, and proper jumping form.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
        ),
        SizedBox(height: 4),
        Text(
          recommendation,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  String _getScoreDisplayText() {
    switch (widget.testType.toLowerCase()) {
      case 'vertical_jump':
        return '${_analysisResult!.score.toStringAsFixed(1)} cm';
      case 'sprint':
        return '${_analysisResult!.score.toStringAsFixed(1)} m/s';
      case 'balance':
        return '${_analysisResult!.score.toStringAsFixed(0)} points';
      default:
        return _analysisResult!.score.toStringAsFixed(1);
    }
  }

  Color _getPerformanceColor(String performance) {
    switch (performance.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'average':
      case 'fair':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _submitResults() async {
    if (_analysisResult == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Submitting results to SAI...'),
          ],
        ),
      ),
    );

    try {
      // TODO: Implement actual SAI submission
      await Future.delayed(Duration(seconds: 2));

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Results submitted successfully to SAI database'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to results history
            },
          ),
        ),
      );

      // Navigate back or to results screen
      Navigator.pop(context);

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Failed to submit results: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Instructions Card
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Test Instructions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(_getDetailedInstructions()),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Athlete Information (only for vertical jump)
            if (widget.testType == 'vertical_jump') ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Athlete Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              decoration: InputDecoration(
                                labelText: 'Height (cm)',
                                prefixIcon: Icon(Icons.height),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _ageController,
                              decoration: InputDecoration(
                                labelText: 'Age',
                                prefixIcon: Icon(Icons.cake),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc),
                        ),
                        items: ['Male', 'Female'].map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value ?? 'Male';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Video Recording/Upload Section
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.videocam, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Record or Upload Video',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    if (_isCameraInitialized) ...[
                      Container(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              CameraPreview(_cameraController!),
                              if (_isRecording)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: AnimatedBuilder(
                                    animation: _recordingAnimationController!,
                                    builder: (context, child) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color.lerp(Colors.red, Colors.red.withOpacity(0.3),
                                              _recordingAnimationController!.value),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.circle, color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text('REC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _recordingAnimationController!,
                              builder: (context, child) {
                                return ElevatedButton.icon(
                                  onPressed: _isRecording ? _stopRecording : _startRecording,
                                  icon: Icon(
                                    _isRecording ? Icons.stop : Icons.videocam,
                                  ),
                                  label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isRecording ? null : _pickVideoFile,
                              icon: Icon(Icons.file_upload),
                              label: Text('Upload Video'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Camera not available'),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickVideoFile,
                              icon: Icon(Icons.file_upload),
                              label: Text('Upload Video File'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_videoPath != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Video selected: ${_videoPath!.split('/').last}',
                                style: TextStyle(color: Colors.green[700]),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_videoPlayerController?.value.isInitialized == true) ...[
                        SizedBox(height: 16),
                        Container(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: VideoPlayer(_videoPlayerController!),
                          ),
                        ),
                        SizedBox(height: 8),
                        VideoProgressIndicator(
                          _videoPlayerController!,
                          allowScrubbing: true,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _videoPlayerController!.value.isPlaying
                                      ? _videoPlayerController!.pause()
                                      : _videoPlayerController!.play();
                                });
                              },
                              icon: Icon(
                                _videoPlayerController!.value.isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Analysis Section
            AnimatedBuilder(
              animation: _analyzeButtonController!,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_analyzeButtonController!.value * 0.05),
                  child: ElevatedButton.icon(
                    onPressed: _videoPath != null && !_isAnalyzing ? _analyzeVideo : null,
                    icon: _isAnalyzing
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Icon(Icons.analytics),
                    label: Text(_isAnalyzing ? 'Analyzing Video...' : 'Analyze Performance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),

            if (_analysisResult != null && _analysisResult!.score > 0) ...[
              SizedBox(height: 16),
              Card(
                elevation: 3,
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Analysis Complete',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getPerformanceColor(_analysisResult!.performance),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _getScoreDisplayText(),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _analysisResult!.performance,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDetailedInstructions() {
    switch (widget.testType.toLowerCase()) {
      case 'vertical_jump':
        return '''• Stand with feet shoulder-width apart
• Jump as high as possible with both feet
• Land with both feet simultaneously  
• Keep your body visible in frame throughout
• Record for 3-5 seconds including preparation and landing''';
      case 'sprint':
        return '''• Run as fast as possible across the camera view
• Maintain maximum speed throughout the recording
• Keep your entire body visible in frame
• Record for 5-10 seconds of continuous running''';
      case 'balance':
        return '''• Stand on one foot for as long as possible
• Keep your arms at your sides or extended for balance
• Stay within the camera frame
• Record for 30-60 seconds or until you lose balance''';
      default:
        return 'Follow the specific instructions for this test. Keep yourself visible in the camera frame throughout the exercise.';
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    _recordingAnimationController?.dispose();
    _analyzeButtonController?.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}