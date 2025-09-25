// File: lib/models/test_result.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TestResult {
  final String id;
  final String testType;
  final double score;
  final String performance;
  final Map<String, dynamic> metrics;
  final DateTime timestamp;
  final String? videoPath;
  final String? athleteId;

  TestResult({
    required this.id,
    required this.testType,
    required this.score,
    required this.performance,
    required this.metrics,
    required this.timestamp,
    this.videoPath,
    this.athleteId,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testType': testType,
      'score': score,
      'performance': performance,
      'metrics': metrics,
      'timestamp': timestamp.toIso8601String(),
      'videoPath': videoPath,
      'athleteId': athleteId,
    };
  }

  // Create from JSON
  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'] ?? '',
      testType: json['testType'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      performance: json['performance'] ?? '',
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      videoPath: json['videoPath'],
      athleteId: json['athleteId'],
    );
  }

  // Copy with method for updates
  TestResult copyWith({
    String? id,
    String? testType,
    double? score,
    String? performance,
    Map<String, dynamic>? metrics,
    DateTime? timestamp,
    String? videoPath,
    String? athleteId,
  }) {
    return TestResult(
      id: id ?? this.id,
      testType: testType ?? this.testType,
      score: score ?? this.score,
      performance: performance ?? this.performance,
      metrics: metrics ?? this.metrics,
      timestamp: timestamp ?? this.timestamp,
      videoPath: videoPath ?? this.videoPath,
      athleteId: athleteId ?? this.athleteId,
    );
  }

  @override
  String toString() {
    return 'TestResult(id: $id, testType: $testType, score: $score, performance: $performance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}