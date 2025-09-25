// File: lib/providers/athlete_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/athlete_profile.dart';
import '../models/test_result.dart';
import 'dart:async';

class AthleteProvider extends ChangeNotifier {
  AthleteProfile? _profile;
  List<TestResult> _testResults = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<AthleteProfile?>? _profileSubscription;

  // Getters
  AthleteProfile? get profile => _profile;
  List<TestResult> get testResults => _testResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties
  double get completionPercentage {
    if (_profile == null) return 0.0;
    return _profile!.completionPercentage;
  }

  Map<String, bool> get testStatus => _profile?.testStatus ?? {
    'vertical_jump': false,
    'situps': false,
    'shuttle_run': false,
    'endurance_run': false,
  };

  bool get isProfileComplete => _profile?.isComplete ?? false;

  AthleteProvider() {
    _initializeProfileListener();
  }

  // Initialize real-time profile listener
  void _initializeProfileListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _profileSubscription = FirestoreService.listenToProfile().listen(
            (profile) {
          _profile = profile;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );
    }
  }

  // Load profile (for initial load)
  Future<void> loadProfile() async {
    _setLoading(true);
    try {
      _profile = await FirestoreService.getAthleteProfile();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Set profile (for initialization)
  void setProfile(AthleteProfile? profile) {
    _profile = profile;
    notifyListeners();
  }

  // Save profile
  Future<void> saveProfile(AthleteProfile profile) async {
    _setLoading(true);
    try {
      await FirestoreService.saveAthleteProfile(profile);
      // The real-time listener will update _profile automatically
      _error = null;
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Update specific profile fields
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_profile == null) return;

    _setLoading(true);
    try {
      await FirestoreService.updateProfileFields(updates);
      _error = null;
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Load test results
  Future<void> loadTestResults() async {
    try {
      _testResults = await FirestoreService.getTestResults();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Save test result
  Future<void> saveTestResult(TestResult result) async {
    try {
      await FirestoreService.saveTestResult(result);
      _testResults.add(result);

      // Update test status in profile
      if (_profile != null) {
        final updatedStatus = {..._profile!.testStatus};
        updatedStatus[result.testType] = true;

        // Update profile with new test status
        await updateProfile({'testStatus': updatedStatus});
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  // Get test results for specific test type
  List<TestResult> getTestResultsByType(String testType) {
    return _testResults.where((result) => result.testType == testType).toList();
  }

  // Get best result for a test type
  TestResult? getBestResult(String testType) {
    final results = getTestResultsByType(testType);
    if (results.isEmpty) return null;

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.first;
  }

  // Get analytics data
  Map<String, dynamic> getAnalytics() {
    if (_testResults.isEmpty) {
      return {
        'totalTests': 0,
        'averageScore': 0.0,
        'completedTestTypes': testStatus.values.where((completed) => completed).length,
        'improvementTrend': 'No data',
      };
    }

    final totalTests = _testResults.length;
    final averageScore = _testResults.map((r) => r.score).reduce((a, b) => a + b) / totalTests;
    final completedTestTypes = testStatus.values.where((completed) => completed).length;

    // Calculate improvement trend (comparing first and last test of each type)
    String improvementTrend = 'Stable';
    final testTypes = _testResults.map((r) => r.testType).toSet();

    for (final testType in testTypes) {
      final typeResults = getTestResultsByType(testType);
      if (typeResults.length >= 2) {
        typeResults.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final firstScore = typeResults.first.score;
        final lastScore = typeResults.last.score;

        if (lastScore > firstScore * 1.1) {
          improvementTrend = 'Improving';
          break;
        } else if (lastScore < firstScore * 0.9) {
          improvementTrend = 'Declining';
        }
      }
    }

    return {
      'totalTests': totalTests,
      'averageScore': averageScore,
      'completedTestTypes': completedTestTypes,
      'improvementTrend': improvementTrend,
      'bestScores': testTypes.map((type) {
        final best = getBestResult(type);
        return {
          'testType': type,
          'score': best?.score ?? 0,
          'date': best?.timestamp,
        };
      }).toList(),
    };
  }

  // Refresh all data
  Future<void> refresh() async {
    await loadProfile();
    await loadTestResults();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}