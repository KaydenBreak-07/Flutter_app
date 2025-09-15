// File: lib/models/test_result.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TestResult {
  final String id;
  final String testType;
  final String athleteId;
  final Map<String, dynamic> rawAnalysis;
  final double score;
  final bool isValid;
  final DateTime timestamp;
  final String? videoPath;
  final String? videoUrl; // Firebase Storage URL
  final Map<String, dynamic>? cheatDetectionResults;
  final String scoreCategory; // Excellent, Very Good, Good, Average, Poor
  final int attemptNumber;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? aiAnalysis;

  TestResult({
    required this.id,
    required this.testType,
    required this.athleteId,
    required this.rawAnalysis,
    required this.score,
    required this.isValid,
    required this.timestamp,
    this.videoPath,
    this.videoUrl,
    this.cheatDetectionResults,
    this.aiAnalysis,
    required this.scoreCategory,
    this.attemptNumber = 1,
    this.metadata,
  });

  // Calculate score category based on score
  static String calculateScoreCategory(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Very Good';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Average';
    return 'Needs Improvement';
  }

  // Get score color based on category
  static int getScoreColor(String category) {
    switch (category.toLowerCase()) {
      case 'excellent':
        return 0xFF4CAF50; // Green
      case 'very good':
        return 0xFF8BC34A; // Light Green
      case 'good':
        return 0xFFFF9800; // Orange
      case 'average':
        return 0xFFFFC107; // Amber
      default:
        return 0xFFF44336; // Red
    }
  }

  // Check if cheat was detected
  bool get isCheatDetected {
    return cheatDetectionResults?['isCheatDetected'] ?? false;
  }

  // Get cheat detection confidence
  double get cheatDetectionConfidence {
    return (cheatDetectionResults?['confidence'] ?? 0.0).toDouble();
  }

  // Get test-specific formatted results
  Map<String, String> get formattedResults {
    switch (testType.toLowerCase()) {
      case 'vertical_jump':
        return {
          'Jump Height': '${(rawAnalysis['jumpHeight'] ?? 0).toStringAsFixed(1)} cm',
          'Air Time': '${(rawAnalysis['airTime'] ?? 0).toStringAsFixed(2)} sec',
          'Landing Stability': '${((rawAnalysis['landingStability'] ?? 0) * 100).toInt()}%',
          'Takeoff Angle': '${(rawAnalysis['takeoffAngle'] ?? 0).toStringAsFixed(1)}°',
        };

      case 'situps':
        return {
          'Total Reps': '${rawAnalysis['totalCount'] ?? 0}',
          'Valid Reps': '${rawAnalysis['validCount'] ?? 0}',
          'Form Score': '${((rawAnalysis['formScore'] ?? 0) * 100).toInt()}%',
          'Average Speed': '${(rawAnalysis['averageSpeed'] ?? 0).toStringAsFixed(1)} reps/sec',
        };

      case 'shuttle_run':
        return {
          'Total Time': '${(rawAnalysis['totalTime'] ?? 0).toStringAsFixed(2)} sec',
          'Average Speed': '${(rawAnalysis['speed'] ?? 0).toStringAsFixed(1)} m/s',
          'Agility Score': '${((rawAnalysis['changeOfDirectionEfficiency'] ?? 0) * 100).toInt()}%',
          'Consistency': '${((rawAnalysis['consistencyScore'] ?? 0) * 100).toInt()}%',
        };

      case 'endurance_run':
        return {
          'Distance Covered': '${rawAnalysis['totalDistance'] ?? 0} meters',
          'Average Speed': '${(rawAnalysis['averageSpeed'] ?? 0).toStringAsFixed(2)} m/s',
          'Pace Consistency': '${((rawAnalysis['paceConsistency'] ?? 0) * 100).toInt()}%',
          'Running Form': '${((rawAnalysis['runningForm'] ?? 0) * 100).toInt()}%',
        };

      default:
        return {
          'Score': score.toStringAsFixed(1),
          'Valid': isValid ? 'Yes' : 'No',
        };
    }
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testType': testType,
      'athleteId': athleteId,
      'rawAnalysis': rawAnalysis,
      'score': score,
      'isValid': isValid,
      'timestamp': Timestamp.fromDate(timestamp),
      'videoPath': videoPath,
      'videoUrl': videoUrl,
      'aiAnalysis': aiAnalysis,
      'cheatDetectionResults': cheatDetectionResults,
      'scoreCategory': scoreCategory,
      'attemptNumber': attemptNumber,
      'metadata': metadata ?? {
        'appVersion': '1.0.0',
        'deviceInfo': 'Unknown',
        'analysisVersion': '1.0.0',
      },
    };
  }

  // Create from Firestore document
  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'] ?? '',
      testType: json['testType'] ?? '',
      athleteId: json['athleteId'] ?? '',
      rawAnalysis: Map<String, dynamic>.from(json['rawAnalysis'] ?? {}),
      score: (json['score'] ?? 0).toDouble(),
      isValid: json['isValid'] ?? false,
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      videoPath: json['videoPath'],
      videoUrl: json['videoUrl'],
      cheatDetectionResults: json['cheatDetectionResults'] != null
          ? Map<String, dynamic>.from(json['cheatDetectionResults'])
          : null,
      scoreCategory: json['scoreCategory'] ?? calculateScoreCategory((json['score'] ?? 0).toDouble()),
      attemptNumber: json['attemptNumber'] ?? 1,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  // Create a new test result
  factory TestResult.create({
    required String testType,
    required String athleteId,
    required Map<String, dynamic> rawAnalysis,
    required double score,
    required bool isValid,
    String? videoPath,
    String? videoUrl,
    Map<String, dynamic>? cheatDetectionResults,
    int attemptNumber = 1,
    Map<String, dynamic>? metadata,
  }) {
    return TestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      testType: testType,
      athleteId: athleteId,
      rawAnalysis: rawAnalysis,
      score: score,
      isValid: isValid,
      timestamp: DateTime.now(),
      videoPath: videoPath,
      videoUrl: videoUrl,
      cheatDetectionResults: cheatDetectionResults,
      scoreCategory: calculateScoreCategory(score),
      attemptNumber: attemptNumber,
      metadata: metadata,
    );
  }

  // Copy with method for easy updates
  TestResult copyWith({
    String? id,
    String? testType,
    String? athleteId,
    Map<String, dynamic>? rawAnalysis,
    double? score,
    bool? isValid,
    DateTime? timestamp,
    String? videoPath,
    String? videoUrl,
    Map<String, dynamic>? cheatDetectionResults,
    String? scoreCategory,
    int? attemptNumber,
    Map<String, dynamic>? metadata,
  }) {
    return TestResult(
      id: id ?? this.id,
      testType: testType ?? this.testType,
      athleteId: athleteId ?? this.athleteId,
      rawAnalysis: rawAnalysis ?? this.rawAnalysis,
      score: score ?? this.score,
      isValid: isValid ?? this.isValid,
      timestamp: timestamp ?? this.timestamp,
      videoPath: videoPath ?? this.videoPath,
      videoUrl: videoUrl ?? this.videoUrl,
      cheatDetectionResults: cheatDetectionResults ?? this.cheatDetectionResults,
      scoreCategory: scoreCategory ?? this.scoreCategory,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'TestResult{id: $id, testType: $testType, score: $score, category: $scoreCategory}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum for test types
enum TestType {
  verticalJump('vertical_jump', 'Vertical Jump'),
  situps('situps', 'Sit-ups'),
  shuttleRun('shuttle_run', 'Shuttle Run'),
  enduranceRun('endurance_run', 'Endurance Run');

  const TestType(this.value, this.displayName);

  final String value;
  final String displayName;

  static TestType fromString(String value) {
    return TestType.values.firstWhere(
          (type) => type.value == value,
      orElse: () => TestType.verticalJump,
    );
  }
}

// Test result statistics for analytics
class TestResultStats {
  final String testType;
  final int totalAttempts;
  final double bestScore;
  final double averageScore;
  final double improvementPercentage;
  final DateTime? firstAttempt;
  final DateTime? lastAttempt;
  final List<TestResult> allResults;

  TestResultStats({
    required this.testType,
    required this.totalAttempts,
    required this.bestScore,
    required this.averageScore,
    required this.improvementPercentage,
    this.firstAttempt,
    this.lastAttempt,
    required this.allResults,
  });

  factory TestResultStats.fromResults(String testType, List<TestResult> results) {
    if (results.isEmpty) {
      return TestResultStats(
        testType: testType,
        totalAttempts: 0,
        bestScore: 0.0,
        averageScore: 0.0,
        improvementPercentage: 0.0,
        allResults: [],
      );
    }

    // Sort by timestamp
    results.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final validResults = results.where((r) => r.isValid).toList();
    final scores = validResults.map((r) => r.score).toList();

    final bestScore = scores.isNotEmpty ? scores.reduce((a, b) => a > b ? a : b) : 0.0;
    final averageScore = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;

    // Calculate improvement percentage (first vs last valid attempt)
    double improvementPercentage = 0.0;
    if (validResults.length >= 2) {
      final firstScore = validResults.first.score;
      final lastScore = validResults.last.score;
      if (firstScore > 0) {
        improvementPercentage = ((lastScore - firstScore) / firstScore) * 100;
      }
    }

    return TestResultStats(
      testType: testType,
      totalAttempts: results.length,
      bestScore: bestScore,
      averageScore: averageScore,
      improvementPercentage: improvementPercentage,
      firstAttempt: results.isNotEmpty ? results.first.timestamp : null,
      lastAttempt: results.isNotEmpty ? results.last.timestamp : null,
      allResults: results,
    );
  }
}