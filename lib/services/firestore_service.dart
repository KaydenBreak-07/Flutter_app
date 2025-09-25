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

  // ==================== USER ROLE MANAGEMENT ====================

  /// Set user role with approval status
  static Future<void> setUserRole(String userId, String role) async {
    try {
      Map<String, dynamic> userData = {
        'uid': userId,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Set status based on role
      if (role == 'sai_official') {
        userData['status'] = 'pending'; // SAI officials need approval
      } else {
        userData['status'] = 'approved'; // Athletes and others are auto-approved
      }

      // Save in users collection
      await _firestore.collection('users').doc(userId).set(userData, SetOptions(merge: true));

      // Also save in role-specific collection for sai_officials
      if (role == 'sai_official') {
        await _firestore.collection('sai_officials').doc(userId).set(userData, SetOptions(merge: true));
      }

      print('User role set: $userId -> $role with status: ${userData['status']}');
    } catch (e) {
      print('Error setting user role: $e');
      rethrow;
    }
  }

  /// Get user role and all data including status
  static Future<Map<String, dynamic>> getUserRole(String userId) async {
    try {
      print('=== getUserRole DEBUG START ===');
      print('Checking user ID: $userId');

      // First check if user is admin (highest priority)
      final adminDoc = await _firestore.collection('system_admins').doc(userId).get();
      print('Admin doc exists: ${adminDoc.exists}');
      if (adminDoc.exists && adminDoc.data() != null) {
        final data = adminDoc.data()!;
        data['role'] = 'admin'; // Ensure role is set
        print('Admin data: $data');
        return data;
      }

      // Check sai_officials collection
      final saiDoc = await _firestore.collection('sai_officials').doc(userId).get();
      print('SAI doc exists: ${saiDoc.exists}');
      if (saiDoc.exists && saiDoc.data() != null) {
        final data = saiDoc.data()!;
        print('SAI raw data: $data');
        print('SAI status: "${data['status']}" (${data['status']?.runtimeType})');

        // Ensure consistent role naming
        if (data['role'] == 'official') {
          data['role'] = 'sai_official';
        }

        // Ensure status exists and is properly formatted
        if (data['status'] == null) {
          data['status'] = 'pending'; // Default for SAI officials
        }

        print('SAI processed data: $data');
        return data;
      }

      // Check users collection (fallback for athletes or old data)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      print('Users doc exists: ${userDoc.exists}');
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        print('Users data: $data');

        // Default status for athletes
        if (data['role'] == 'athlete' && data['status'] == null) {
          data['status'] = 'approved';
        }

        return data;
      }

      final athleteDoc = await _firestore.collection('athletes').doc(userId).get();
      print('Athletes doc exists: ${athleteDoc.exists}');
      if (athleteDoc.exists && athleteDoc.data() != null) {
        print('Found athlete profile, setting role to athlete');
        return {
          'role': 'athlete',
          'status': 'approved',
          'uid': userId,
        };
      }

      print('No documents found anywhere - user likely needs to select role');
      return {
        'role': null,
        'status': null,
        'uid': userId,
      };

    } catch (e) {
      print('Error getting user role: $e');
      return {
        'role': null,
        'status': null,
        'error': e.toString(),
      };
    } finally {
      print('=== getUserRole DEBUG END ===');
    }
  }

  // ==================== ATHLETE PROFILE OPERATIONS ====================

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

      final doc = await _firestore
          .collection('athletes')
          .doc(uid)
          .get();

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

  // ==================== ATHLETE DATA FOR SAI OFFICIALS ====================

  /// Get recent athletes for SAI dashboard
  static Future<List<Map<String, dynamic>>> getRecentAthletes({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('athletes')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting recent athletes: $e');
      return [];
    }
  }

  /// Get all athletes for SAI officials to browse
  static Future<List<Map<String, dynamic>>> getAllAthletes() async {
    try {
      final querySnapshot = await _firestore
          .collection('athletes')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all athletes: $e');
      return [];
    }
  }

  // ==================== TEST RESULTS OPERATIONS ====================

  /// Save test result
  static Future<String> saveTestResult(TestResult testResult) async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      final docRef = await _firestore
          .collection('athletes')
          .doc(currentUserId)
          .collection('test_results')
          .add(testResult.toJson());

      // Update test completion status
      await updateTestStatus(testResult.testType, true);

      // Increment daily test count
      await incrementDailyTestCount();

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
          .map((doc) => TestResult.fromJson(doc.data() as Map<String, dynamic>))
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

      await _firestore
          .collection('athletes')
          .doc(currentUserId)
          .update({
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

      final doc = await _firestore
          .collection('athletes')
          .doc(currentUserId)
          .get();

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

  // ==================== SAI OFFICIAL OPERATIONS ====================

  /// Create SAI official profile
  static Future<void> createSAIOfficialProfile(Map<String, dynamic> officialData) async {
    try {
      final userId = officialData['uid'];

      await _firestore
          .collection('sai_officials')
          .doc(userId)
          .set(officialData);

      print('SAI official profile created for user: $userId');
    } catch (e) {
      print('Error creating SAI official profile: $e');
      rethrow;
    }
  }

  /// Get SAI official profile
  static Future<Map<String, dynamic>?> getSAIOfficialProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('sai_officials')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting SAI official profile: $e');
      rethrow;
    }
  }

  /// Get SAI dashboard statistics - FIXED VERSION
  static Future<Map<String, dynamic>> getSAIDashboardStats() async {
    try {
      print('Getting SAI dashboard stats...');

      // Get total athletes count
      final athletesSnapshot = await _firestore.collection('athletes').count().get();
      final totalAthletes = athletesSnapshot.count ?? 0;
      print('Total athletes: $totalAthletes');

      // Get today's assessments - REMOVED COLLECTION GROUP QUERY
      int assessmentsToday = 0;

      // Alternative approach: Get assessments from individual athlete collections
      try {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        // Instead of collectionGroup query, we'll use a simpler approach
        final recentTestsQuery = await _firestore
            .collection('daily_test_counts')
            .doc('${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}')
            .get();

        if (recentTestsQuery.exists) {
          assessmentsToday = recentTestsQuery.data()?['count'] ?? 0;
        }
      } catch (e) {
        print('Error getting today assessments: $e');
        assessmentsToday = 0;
      }

      // Get pending submissions
      int pendingReviews = 0;
      try {
        final pendingSubmissionsSnapshot = await _firestore
            .collection('sai_submissions')
            .where('status', isEqualTo: 'pending_review')
            .count()
            .get();
        pendingReviews = pendingSubmissionsSnapshot.count ?? 0;
      } catch (e) {
        print('Error getting pending reviews: $e');
        pendingReviews = 0;
      }

      // Get flagged cases - SIMPLIFIED VERSION
      int flaggedCases = 0;
      try {
        // Instead of collectionGroup query, check a flagged_cases collection
        final flaggedCasesSnapshot = await _firestore
            .collection('flagged_cases')
            .where('resolved', isEqualTo: false)
            .count()
            .get();
        flaggedCases = flaggedCasesSnapshot.count ?? 0;
      } catch (e) {
        print('Error getting flagged cases: $e');
        flaggedCases = 0;
      }

      final stats = {
        'totalAthletes': totalAthletes,
        'assessmentsToday': assessmentsToday,
        'pendingReviews': pendingReviews,
        'flaggedCases': flaggedCases,
      };

      print('Dashboard stats loaded successfully: $stats');
      return stats;

    } catch (e) {
      print('Error getting SAI dashboard stats: $e');
      // Return default values instead of throwing error
      return {
        'totalAthletes': 0,
        'assessmentsToday': 0,
        'pendingReviews': 0,
        'flaggedCases': 0,
        'error': e.toString(),
      };
    }
  }

  // Add this method to your FirestoreService class

  /// Get recent test results for current user (add this method)
  static Future<List<TestResult>> getRecentTestResults({int limit = 5}) async {
    try {
      if (currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('athletes')
          .doc(currentUserId)
          .collection('test_results')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => TestResult.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting recent test results: $e');
      return [];
    }
  }




  // ==================== ADMIN CHECK METHODS ====================

  /// Check if user is system admin
  static Future<bool> isUserAdmin([String? userId]) async {
    try {
      final uid = userId ?? currentUserId;
      if (uid == null) return false;

      final adminDoc = await _firestore
          .collection('system_admins')
          .doc(uid)
          .get();

      return adminDoc.exists && (adminDoc.data()?['active'] == true);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Listen to SAI official status changes
  static Stream<String> listenToOfficialStatus(String userId) {
    return _firestore
        .collection('sai_officials')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!['status'] ?? 'pending';
      }
      return 'pending';
    });
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
      return snapshot.docs
          .map((doc) => TestResult.fromJson(doc.data()))
          .toList();
    });
  }

  // ==================== ADMIN/SAI OPERATIONS ====================

  /// Submit assessment to SAI (for review)
  static Future<void> submitAssessmentToSAI() async {
    try {
      if (currentUserId == null) throw 'User not authenticated';

      final profile = await getAthleteProfile();
      final testResults = await getTestResults();

      if (profile == null) throw 'Profile not found';

      // Check if all tests are completed
      final testStatus = await getTestStatus();
      bool allTestsCompleted = testStatus.values.every((completed) => completed);

      if (!allTestsCompleted) {
        throw 'Please complete all fitness tests before submitting to SAI';
      }

      final submissionData = {
        'athleteId': currentUserId,
        'profile': profile.toJson(),
        'testResults': testResults.map((result) => result.toJson()).toList(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending_review',
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

      final doc = await _firestore
          .collection('sai_submissions')
          .doc(currentUserId)
          .get();

      return doc.data();
    } catch (e) {
      print('Error getting submission status: $e');
      return null;
    }
  }

  // ==================== APPROVAL SYSTEM METHODS ====================

  /// Get all pending SAI official accounts
  static Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('sai_officials')
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> pendingUsers = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userData = doc.data();
        userData['userId'] = doc.id;
        pendingUsers.add(userData);
      }

      return pendingUsers;
    } catch (e) {
      print('Failed to load pending users: $e');
      throw Exception('Failed to load pending users: $e');
    }
  }

  /// Approve a SAI official account
  static Future<void> approveUser(String userId) async {
    try {
      await _firestore.collection('sai_officials').doc(userId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Also update in users collection if exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }

      // Send approval notification to user
      await _sendApprovalNotification(userId, approved: true);

      print('User approved: $userId');
    } catch (e) {
      print('Failed to approve user: $e');
      throw Exception('Failed to approve user: $e');
    }
  }

  /// Reject a SAI official account
  static Future<void> rejectUser(String userId) async {
    try {
      await _firestore.collection('sai_officials').doc(userId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Also update in users collection if exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      }

      // Send rejection notification to user
      await _sendApprovalNotification(userId, approved: false);

      print('User rejected: $userId');
    } catch (e) {
      print('Failed to reject user: $e');
      throw Exception('Failed to reject user: $e');
    }
  }

  /// Send notification to user about approval status
  static Future<void> _sendApprovalNotification(String userId, {required bool approved}) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': approved ? 'Account Approved' : 'Account Rejected',
        'message': approved
            ? 'Your SAI official account has been approved. You can now access the system.'
            : 'Your SAI official account application has been rejected. Please contact support for more information.',
        'type': 'account_status',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Notification sent to user $userId: ${approved ? 'approved' : 'rejected'}');
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  /// Check user approval status
  static Future<String> getUserStatus(String userId) async {
    try {
      // Check sai_officials collection first
      final saiDoc = await _firestore.collection('sai_officials').doc(userId).get();
      if (saiDoc.exists) {
        return saiDoc.data()?['status'] ?? 'pending';
      }

      // Check users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['status'] ?? 'approved'; // default to approved for old users
      }

      return 'not_found';
    } catch (e) {
      print('Failed to get user status: $e');
      throw Exception('Failed to get user status: $e');
    }
  }

  /// Set user as admin (use this carefully)
  static Future<void> setUserAsAdmin(String userId) async {
    try {
      await _firestore.collection('system_admins').doc(userId).set({
        'uid': userId,
        'role': 'admin',
        'status': 'approved',
        'active': true,
        'adminSince': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('User set as admin: $userId');
    } catch (e) {
      print('Error setting user as admin: $e');
      rethrow;
    }
  }

  /// One-time method to make current user admin (for initial setup)
  static Future<void> makeCurrentUserAdmin() async {
    if (currentUserId != null) {
      await setUserAsAdmin(currentUserId!);
      print('Current user is now admin: $currentUserId');
    }
  }

  // Add this method to your FirestoreService class for debugging
  static Future<void> debugUserCollections(String userId) async {
    try {
      print('\n=== COMPLETE USER COLLECTIONS DEBUG ===');
      print('User ID: $userId');

      // Check all possible collections
      final collections = [
        'system_admins',
        'sai_officials',
        'users',
        'athletes'
      ];

      for (String collectionName in collections) {
        try {
          final doc = await _firestore.collection(collectionName).doc(userId).get();
          print('\n--- $collectionName Collection ---');
          print('Exists: ${doc.exists}');
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            print('Data: $data');
            print('Role: ${data['role']} (${data['role']?.runtimeType})');
            print('Status: ${data['status']} (${data['status']?.runtimeType})');
          } else {
            print('No data in $collectionName');
          }
        } catch (e) {
          print('Error checking $collectionName: $e');
        }
      }

      print('\n=== END COMPLETE DEBUG ===\n');

    } catch (e) {
      print('Error in debug method: $e');
    }
  }

  /// Force-fix user data if needed
  static Future<void> fixUserRole(String userId, String correctRole, String correctStatus) async {
    try {
      print('Fixing user role: $userId -> $correctRole ($correctStatus)');

      if (correctRole == 'sai_official') {
        // Update sai_officials collection
        await _firestore.collection('sai_officials').doc(userId).set({
          'uid': userId,
          'role': correctRole,
          'status': correctStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Also update users collection
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'role': correctRole,
          'status': correctStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (correctRole == 'athlete') {
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'role': correctRole,
          'status': correctStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print('User role fixed successfully');
    } catch (e) {
      print('Error fixing user role: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Use this to increment daily test counts
  static Future<void> incrementDailyTestCount() async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('daily_test_counts')
          .doc(dateKey)
          .set({
        'count': FieldValue.increment(1),
        'date': Timestamp.fromDate(today),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error incrementing daily test count: $e');
      // Don't throw error, this is not critical
    }
  }

  /// Use this to add flagged cases
  static Future<void> addFlaggedCase(String athleteId, String testType, String reason) async {
    try {
      await _firestore
          .collection('flagged_cases')
          .add({
        'athleteId': athleteId,
        'testType': testType,
        'reason': reason,
        'resolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding flagged case: $e');
      // Don't throw error, this is not critical
    }
  }

  /// Fix current user data
  static Future<void> fixCurrentUserData() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('No current user found');
        return;
      }

      print('Fixing user data for: $userId');

      // Based on your console logs, your user should be sai_official with approved status
      await _firestore.collection('sai_officials').doc(userId).set({
        'uid': userId,
        'role': 'sai_official',
        'status': 'approved', // Make sure this is approved
        'fullName': 'Pranshu',
        'employeeId': '123456',
        'designation': 'Sports Officer',
        'department': 'cric',
        'email': 'pran@gov.in',
        'permissions': {
          'review_results': true,
          'manage_users': false,
          'export_data': false,
          'view_athletes': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also ensure users collection has correct data
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'role': 'sai_official',
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('User data fixed successfully! Status set to approved.');

    } catch (e) {
      print('Error fixing user data: $e');
      rethrow;
    }
  }

  /// Check and display current user status
  static Future<void> checkCurrentUserStatus() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('No current user found');
        return;
      }

      print('\n=== CURRENT USER STATUS CHECK ===');
      print('User ID: $userId');

      // Check sai_officials collection
      final saiDoc = await _firestore.collection('sai_officials').doc(userId).get();
      if (saiDoc.exists) {
        final data = saiDoc.data()!;
        print('SAI Officials Collection:');
        print('  Role: ${data['role']}');
        print('  Status: ${data['status']}');
        print('  Full Data: $data');
      } else {
        print('SAI Officials Collection: No document found');
      }

      // Check users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        print('Users Collection:');
        print('  Role: ${data['role']}');
        print('  Status: ${data['status']}');
        print('  Full Data: $data');
      } else {
        print('Users Collection: No document found');
      }

      print('=== END STATUS CHECK ===\n');

    } catch (e) {
      print('Error checking user status: $e');
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
      await _firestore
          .collection('athletes')
          .doc(currentUserId)
          .delete();

      // Delete SAI submission if exists
      await _firestore
          .collection('sai_submissions')
          .doc(currentUserId)
          .delete();

      // Delete user role document
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .delete();

      print('User data deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }
}