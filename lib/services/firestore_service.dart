// File: lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/athlete_profile.dart';
import '../models/test_result.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // ==================== USER PROFILE OPERATIONS ====================

  /// Create or update athlete profile
  static Future<void> saveAthleteProfile(AthleteProfile profile) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      await _firestore
          .collection('athletes')
          .doc(currentUserId)
          .set(profile.toJson(), SetOptions(merge: true));

      print('Profile saved successfully for user: $currentUserId');
    } catch (e) {
      print('Error saving profile: $e');
      rethrow;
    }
  }

  /// Get athlete profile
  static Future<AthleteProfile?> getAthleteProfile([String? userId]) async {
    try {
      final uid = userId ?? currentUserId;
      if (uid == null) throw 'User not authenticated';

      final doc = await _firestore.collection('athletes').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return AthleteProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting profile: $e');
      rethrow;
    }
  }

  /// Update specific profile fields
  static Future<void> updateProfileFields(Map<String, dynamic> updates) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('athletes')
          .doc(currentUserId)
          .update(updates);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // ==================== TEST RESULTS OPERATIONS ====================

  /// Save test result
  static Future<String> saveTestResult(TestResult testResult) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      final docRef = _firestore
          .collection('athletes')
          .doc(currentUserId)
          .collection('test_results')
          .doc(testResult.id);

      await docRef.set(testResult.toJson());

      // Update test completion status
      await updateTestStatus(testResult.testType, true);

      print('Test result saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving test result: $e');
      rethrow;
    }
  }

  /// Get all test results for current user
  static Future<List<TestResult>> getTestResults([String? testType]) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      Query query = _firestore
          .collection('athletes')
          .doc(currentUserId)
          .collection('test_results')
          .orderBy('timestamp', descending: true);

      if (testType != null) {
        query = query.where('testType', isEqualTo: testType);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) =>
          TestResult.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting test results: $e');
      rethrow;
    }
  }

  /// Get best score for a specific test
  static Future<TestResult?> getBestTestResult(String testType) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      final querySnapshot = await _firestore
          .collection('athletes')
          .doc(currentUserId)
          .collection('test_results')
          .where('testType', isEqualTo: testType)
          .where('isValid', isEqualTo: true)
          .orderBy('score', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return TestResult.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting best result: $e');
      rethrow;
    }
  }

  // ==================== TEST STATUS TRACKING ====================

  /// Update test completion status
  static Future<void> updateTestStatus(String testType, bool completed) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      await _firestore.collection('athletes').doc(currentUserId).update({
        'testStatus.$testType': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating test status: $e');
      rethrow;
    }
  }

  /// Get test completion status
  static Future<Map<String, bool>> getTestStatus() async {
    try {
      if (currentUserId == null) return {};

      final doc =
      await _firestore.collection('athletes').doc(currentUserId).get();

      final data = doc.data();
      if (data != null && data['testStatus'] != null) {
        return Map<String, bool>.from(data['testStatus']);
      }

      // Return default status for all tests
      return {
        'vertical_jump': false,
        'situps': false,
        'shuttle_run': false,
        'endurance_run': false,
      };
    } catch (e) {
      print('Error getting test status: $e');
      return {};
    }
  }

  // ==================== LEADERBOARD OPERATIONS ====================

  /// Get top performers for a specific test
  static Future<List<Map<String, dynamic>>> getLeaderboard(
      String testType, {
        int limit = 10,
        String? ageGroup,
        String? gender,
      }) async {
    try {
      Query query = _firestore
          .collectionGroup('test_results')
          .where('testType', isEqualTo: testType)
          .where('isValid', isEqualTo: true)
          .orderBy('score', descending: true)
          .limit(limit);

      final querySnapshot = await query.get();

      List<Map<String, dynamic>> leaderboard = [];

      for (var doc in querySnapshot.docs) {
        final testData = doc.data() as Map<String, dynamic>;

        // Get athlete info
        final athletePath = doc.reference.parent.parent;
        if (athletePath != null) {
          final athleteDoc = await athletePath.get();
          final athleteData = athleteDoc.data() as Map<String, dynamic>?;

          if (athleteData != null) {
            // Filter by age group and gender if specified
            if (ageGroup != null && athleteData['ageGroup'] != ageGroup) {
              continue;
            }
            if (gender != null && athleteData['gender'] != gender) {
              continue;
            }

            leaderboard.add({
              'athleteId': athleteDoc.id,
              'athleteName': athleteData['fullName'] ?? 'Anonymous',
              'score': testData['score'],
              'testType': testData['testType'],
              'timestamp': testData['timestamp'],
              'location':
              '${athleteData['district'] ?? ''}, ${athleteData['state'] ?? ''}',
            });
          }
        }
      }

      return leaderboard;
    } catch (e) {
      print('Error getting leaderboard: $e');
      rethrow;
    }
  }

  /// Get user's rank for a specific test
  static Future<int> getUserRank(String testType) async {
    try {
      if (currentUserId == null) return 0;

      final userBestResult = await getBestTestResult(testType);
      if (userBestResult == null) return 0;

      final betterScoresCount = await _firestore
          .collectionGroup('test_results')
          .where('testType', isEqualTo: testType)
          .where('isValid', isEqualTo: true)
          .where('score', isGreaterThan: userBestResult.score)
          .count()
          .get();

      return betterScoresCount.count! + 1;
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  // ==================== ANALYTICS & INSIGHTS ====================

  /// Get user's performance analytics
  static Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      if (currentUserId == null) return {};

      final testResults = await getTestResults();
      final testStatus = await getTestStatus();

      // Calculate completion percentage
      int completedTests =
          testStatus.values.where((completed) => completed).length;
      double completionPercentage =
          (completedTests / testStatus.length) * 100;

      // Calculate average scores per test type
      Map<String, List<double>> scoresByType = {};
      for (var result in testResults) {
        scoresByType.putIfAbsent(result.testType, () => []);
        scoresByType[result.testType]!.add(result.score);
      }

      Map<String, double> averageScores = {};
      scoresByType.forEach((testType, scores) {
        if (scores.isNotEmpty) {
          averageScores[testType] =
              scores.reduce((a, b) => a + b) / scores.length;
        }
      });

      return {
        'totalTests': testResults.length,
        'completedTestTypes': completedTests,
        'completionPercentage': completionPercentage,
        'averageScores': averageScores,
        'lastTestDate': testResults.isNotEmpty
            ? testResults.first.timestamp.toIso8601String()
            : null,
        'testsByType': scoresByType.map((k, v) => MapEntry(k, v.length)),
      };
    } catch (e) {
      print('Error getting analytics: $e');
      rethrow;
    }
  }

  // ==================== ADMIN/SAI OPERATIONS ====================

  /// Submit assessment to SAI (for review)
  static Future<void> submitAssessmentToSAI() async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      final profile = await getAthleteProfile();
      final testResults = await getTestResults();
      final analytics = await getUserAnalytics();

      if (profile == null) throw 'Profile not found';

      // Check if all tests are completed
      final testStatus = await getTestStatus();
      bool allTestsCompleted =
      testStatus.values.every((completed) => completed);

      if (!allTestsCompleted) {
        throw 'Please complete all fitness tests before submitting to SAI';
      }

      final submissionData = {
        'athleteId': currentUserId,
        'profile': profile.toJson(),
        'testResults': testResults.map((result) => result.toJson()).toList(),
        'analytics': analytics,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending_review', // pending_review, approved, rejected
        'submissionId': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      await _firestore
          .collection('sai_submissions')
          .doc(currentUserId)
          .set(submissionData);

      // Update athlete profile with submission status
      await updateProfileFields({
        'submittedToSAI': true,
        'submissionDate': FieldValue.serverTimestamp(),
      });

      print('Assessment submitted to SAI successfully');
    } catch (e) {
      print('Error submitting to SAI: $e');
      rethrow;
    }
  }

  /// Check submission status
  static Future<Map<String, dynamic>?> getSubmissionStatus() async {
    try {
      if (currentUserId == null) return null;

      final doc =
      await _firestore.collection('sai_submissions').doc(currentUserId).get();

      return doc.data();
    } catch (e) {
      print('Error getting submission status: $e');
      return null;
    }
  }

  // ==================== REAL-TIME LISTENERS ====================

  /// Listen to profile changes
  static Stream<AthleteProfile?> listenToProfile() {
    if (currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('athletes')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return AthleteProfile.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  /// Listen to test results
  static Stream<List<TestResult>> listenToTestResults() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('athletes')
        .doc(currentUserId)
        .collection('test_results')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TestResult.fromJson(doc.data())).toList();
    });
  }

  // ==================== APP METADATA (TEST STANDARDS) ====================

  /// Get test standard by testType + ageGroup + gender
  static Future<Map<String, dynamic>?> getTestStandard(
      String testType, String ageGroup, String gender) async {
    try {
      final doc = await _firestore
          .collection('app_metadata')
          .doc('test_standards')
          .collection(testType)
          .doc('$ageGroup-$gender')
          .get();

      return doc.data();
    } catch (e) {
      print('Error getting test standard: $e');
      return null;
    }
  }

  /// Update or create a test standard (admin use only)
  static Future<void> setTestStandard(
      String testType, String ageGroup, String gender, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('app_metadata')
          .doc('test_standards')
          .collection(testType)
          .doc('$ageGroup-$gender')
          .set(data, SetOptions(merge: true));

      print('Test standard set for $testType | $ageGroup | $gender');
    } catch (e) {
      print('Error setting test standard: $e');
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Delete all user data (for account deletion)
  static Future<void> deleteUserData() async {
    try {
      if (currentUserId == null) return;

      // Delete test results subcollection
      final testResults = await _firestore
          .collection('athletes')
          .doc(currentUserId)
          .collection('test_results')
          .get();

      for (var doc in testResults.docs) {
        await doc.reference.delete();
      }

      // Delete main profile document
      await _firestore.collection('athletes').doc(currentUserId).delete();

      // Delete SAI submission if exists
      await _firestore.collection('sai_submissions').doc(currentUserId).delete();

      print('User data deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }

  /// Batch operations for better performance
  static Future<void> batchUpdateTestResults(List<TestResult> results) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      WriteBatch batch = _firestore.batch();

      for (var result in results) {
        final docRef = _firestore
            .collection('athletes')
            .doc(currentUserId)
            .collection('test_results')
            .doc(result.id);

        batch.set(docRef, result.toJson());
      }

      await batch.commit();
      print('Batch update completed for ${results.length} test results');
    } catch (e) {
      print('Error in batch update: $e');
      rethrow;
    }
  }
}
