// File: lib/services/vertical_jump_ml_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class VerticalJumpMLService {
  static Interpreter? _interpreter;
  static bool _isModelLoaded = false;

  // Model configuration - adjust based on your model's requirements
  static const String _modelPath = 'assets/ml_models/jump_height_model.tflite';
  static const int _inputSize = 224; // Common input size, adjust as needed
  static const int _batchSize = 1;
  static const int _channels = 3; // RGB channels

  /// Initialize the ML model
  static Future<bool> initializeModel() async {
    try {
      if (_isModelLoaded) return true;

      // Load model from assets
      final modelData = await rootBundle.load(_modelPath);
      final modelBytes = modelData.buffer.asUint8List();

      _interpreter = Interpreter.fromBuffer(modelBytes);

      // Allocate tensors
      _interpreter!.allocateTensors();

      _isModelLoaded = true;
      print('Vertical Jump ML Model loaded successfully');
      return true;
    } catch (e) {
      print('Error loading ML model: $e');
      return false;
    }
  }

  /// Process video and predict jump height
  static Future<JumpAnalysisResult> analyzeJumpVideo(String videoPath) async {
    try {
      if (!_isModelLoaded) {
        final initialized = await initializeModel();
        if (!initialized) {
          throw Exception('Failed to initialize ML model');
        }
      }

      // Extract frames from video
      final frames = await _extractVideoFrames(videoPath);
      if (frames.isEmpty) {
        throw Exception('No frames extracted from video');
      }

      // Process frames through the model
      final results = <double>[];
      for (final frame in frames) {
        final prediction = await _predictSingleFrame(frame);
        results.add(prediction);
      }

      // Analyze results to determine jump metrics
      return _analyzeJumpResults(results, frames.length);

    } catch (e) {
      print('Error analyzing jump video: $e');
      return JumpAnalysisResult.error(e.toString());
    }
  }

  /// Extract frames from video file using FFmpeg
  static Future<List<Uint8List>> _extractVideoFrames(String videoPath) async {
    final frames = <Uint8List>[];

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPattern = '${tempDir.path}/frame_%03d.jpg';

      print('Running FFmpeg to extract frames from: $videoPath');

      // Extract frames at 10 FPS
      await FFmpegKit.execute('-i $videoPath -vf fps=10 $outputPattern');

      // Collect extracted frames
      final files = Directory(tempDir.path)
          .listSync()
          .where((file) => file.path.contains('frame_') && file.path.endsWith('.jpg'))
          .toList();

      files.sort((a, b) => a.path.compareTo(b.path)); // ensure chronological order

      for (final file in files) {
        final data = await File(file.path).readAsBytes();
        frames.add(data);
      }

      print('Extracted ${frames.length} frames');
      return frames;
    } catch (e) {
      print('Error extracting video frames: $e');
      return [];
    }
  }

  /// Predict jump height from a single frame
  static Future<double> _predictSingleFrame(Uint8List frameData) async {
    try {
      // Preprocess the frame
      final processedFrame = await _preprocessFrame(frameData);

      // Prepare input tensor
      final input = [processedFrame];

      // Prepare output tensor
      final output = List.filled(1, 0.0).reshape([1, 1]);

      // Run inference
      _interpreter!.run(input, output);

      // Extract prediction
      final prediction = output[0][0] as double;
      return prediction;

    } catch (e) {
      print('Error predicting single frame: $e');
      return 0.0;
    }
  }

  /// Preprocess frame for model input
  static Future<List<List<List<double>>>> _preprocessFrame(Uint8List frameData) async {
    try {
      // Decode image
      final image = img.decodeImage(frameData);
      if (image == null) throw Exception('Failed to decode image');

      // Resize to model input size
      final resized = img.copyResize(image, width: _inputSize, height: _inputSize);

      // Convert to normalized float array
      final input = List.generate(
        _inputSize,
            (y) => List.generate(
          _inputSize,
              (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 255.0),   // Normalize red to 0-1
              (pixel.g / 255.0),   // Normalize green to 0-1
              (pixel.b / 255.0),   // Normalize blue to 0-1
            ];
          },
        ),
      );

      return input;
    } catch (e) {
      print('Error preprocessing frame: $e');
      throw Exception('Frame preprocessing failed: $e');
    }
  }

  /// Analyze jump results from frame predictions
  static JumpAnalysisResult _analyzeJumpResults(List<double> predictions, int frameCount) {
    if (predictions.isEmpty) {
      return JumpAnalysisResult.error('No predictions available');
    }

    try {
      // Find the maximum jump height from predictions
      final maxHeight = predictions.reduce((a, b) => a > b ? a : b);
      final avgHeight = predictions.reduce((a, b) => a + b) / predictions.length;

      // Find the frame index where max jump occurred
      final maxHeightFrame = predictions.indexOf(maxHeight);
      final jumpProgressPercent = (maxHeightFrame / frameCount) * 100;

      // Calculate additional metrics
      final consistency = _calculateConsistency(predictions);
      final technique = _analyzeTechnique(predictions);

      return JumpAnalysisResult(
        maxHeight: maxHeight,
        avgHeight: avgHeight,
        jumpProgressPercent: jumpProgressPercent,
        consistency: consistency,
        techniqueScore: technique,
        frameCount: frameCount,
        isValid: maxHeight > 0.1, // Minimum height threshold
      );

    } catch (e) {
      return JumpAnalysisResult.error('Analysis failed: $e');
    }
  }

  /// Calculate jump consistency
  static double _calculateConsistency(List<double> predictions) {
    if (predictions.length < 2) return 1.0;

    final mean = predictions.reduce((a, b) => a + b) / predictions.length;
    final variance = predictions
        .map((x) => (x - mean) * (x - mean))
        .reduce((a, b) => a + b) / predictions.length;

    // Convert variance to consistency score (0-1, higher is better)
    return 1.0 / (1.0 + variance);
  }

  /// Analyze jump technique
  static double _analyzeTechnique(List<double> predictions) {
    if (predictions.length < 5) return 0.5;

    // Look for smooth jump curve (takeoff -> peak -> landing)
    final hasProperTakeoff = predictions.take(predictions.length ~/ 3)
        .any((h) => h > predictions.first * 1.5);

    final hasClearPeak = predictions.any((h) => h == predictions.reduce((a, b) => a > b ? a : b));

    final hasProperLanding = predictions.skip(predictions.length * 2 ~/ 3)
        .any((h) => h < predictions.last * 2);

    double score = 0.0;
    if (hasProperTakeoff) score += 0.33;
    if (hasClearPeak) score += 0.34;
    if (hasProperLanding) score += 0.33;

    return score;
  }

  /// Dispose resources
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}

/// Result class for jump analysis
class JumpAnalysisResult {
  final double maxHeight;
  final double avgHeight;
  final double jumpProgressPercent;
  final double consistency;
  final double techniqueScore;
  final int frameCount;
  final bool isValid;
  final String? errorMessage;

  JumpAnalysisResult({
    required this.maxHeight,
    required this.avgHeight,
    required this.jumpProgressPercent,
    required this.consistency,
    required this.techniqueScore,
    required this.frameCount,
    required this.isValid,
    this.errorMessage,
  });

  JumpAnalysisResult.error(String error)
      : maxHeight = 0.0,
        avgHeight = 0.0,
        jumpProgressPercent = 0.0,
        consistency = 0.0,
        techniqueScore = 0.0,
        frameCount = 0,
        isValid = false,
        errorMessage = error;

  bool get hasError => errorMessage != null;

  Map<String, dynamic> toJson() => {
    'maxHeight': maxHeight,
    'avgHeight': avgHeight,
    'jumpProgressPercent': jumpProgressPercent,
    'consistency': consistency,
    'techniqueScore': techniqueScore,
    'frameCount': frameCount,
    'isValid': isValid,
    'errorMessage': errorMessage,
    'analyzedAt': DateTime.now().toIso8601String(),
  };
}
