import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sai_official.dart';
import 'email_service.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== ADMIN AUTHENTICATION ====================

  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final adminDoc = await _firestore
          .collection('system_admins')
          .doc(user.uid)
          .get();

      return adminDoc.exists && (adminDoc.data()?['active'] == true);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Create initial admin user (run once during setup)
  static Future<void> createAdminUser(String email, String name) async {
    try {
      // This should be called with a predefined admin email
      final adminData = {
        'email': email,
        'name': name,
        'role': 'super_admin',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'permissions': {
          'approve_officials': true,
          'manage_system': true,
          'view_all_data': true,
          'export_data': true,
        }
      };

      // Note: In production, you'd create this manually in Firestore console
      // or through a secure server-side script
      await _firestore
          .collection('system_admins')
          .doc('ADMIN_USER_ID') // Replace with actual admin user ID
          .set(adminData);

      print('Admin user created successfully');
    } catch (e) {
      print('Error creating admin user: $e');
      rethrow;
    }
  }

  // ==================== PENDING APPROVALS ====================

  /// Get all pending SAI official approvals
  static Future<List<SAIOfficialModel>> getPendingApprovals() async {
    try {
      final querySnapshot = await _firestore
          .collection('sai_officials')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SAIOfficialModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting pending approvals: $e');
      rethrow;
    }
  }

  /// Get admin dashboard statistics
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // Get total officials count
      final officialsSnapshot = await _firestore
          .collection('sai_officials')
          .count()
          .get();

      // Get total athletes count
      final athletesSnapshot = await _firestore
          .collection('athletes')
          .count()
          .get();

      // Get pending approvals count
      final pendingSnapshot = await _firestore
          .collection('sai_officials')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      // Get approved officials count
      final approvedSnapshot = await _firestore
          .collection('sai_officials')
          .where('status', isEqualTo: 'approved')
          .count()
          .get();

      // Convert nullable counts to non-nullable with default value of 0
      final officialsCount = officialsSnapshot.count ?? 0;
      final athletesCount = athletesSnapshot.count ?? 0;
      final pendingCount = pendingSnapshot.count ?? 0;
      final approvedCount = approvedSnapshot.count ?? 0;

      return {
        'totalOfficials': officialsCount,
        'totalAthletes': athletesCount,
        'pendingApprovals': pendingCount,
        'approvedOfficials': approvedCount,
      };
    } catch (e) {
      print('Error getting admin stats: $e');
      return {
        'totalOfficials': 0,
        'totalAthletes': 0,
        'pendingApprovals': 0,
        'approvedOfficials': 0,
      };
    }
  }

  // ==================== APPROVAL ACTIONS ====================

  /// Approve an SAI official
  static Future<void> approveOfficial(String officialId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Admin not authenticated';

      // Check admin permissions
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) throw 'Insufficient permissions';

      final now = DateTime.now();

      // Update official status
      await _firestore
          .collection('sai_officials')
          .doc(officialId)
          .update({
        'status': 'approved',
        'approved': true,
        'approvedAt': Timestamp.fromDate(now),
        'approvedBy': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get official details for email
      final officialDoc = await _firestore
          .collection('sai_officials')
          .doc(officialId)
          .get();

      if (officialDoc.exists) {
        final officialData = officialDoc.data()!;

        // Send approval email
        await EmailService.sendApprovalEmail(
          email: officialData['email'],
          name: officialData['fullName'],
          approved: true,
        );

        // Log approval action
        await _logAdminAction(
          action: 'official_approved',
          targetId: officialId,
          details: {
            'official_name': officialData['fullName'],
            'official_email': officialData['email'],
          },
        );
      }

      print('Official approved successfully: $officialId');
    } catch (e) {
      print('Error approving official: $e');
      rethrow;
    }
  }

  /// Reject an SAI official
  static Future<void> rejectOfficial(String officialId, {String? reason}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Admin not authenticated';

      // Check admin permissions
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) throw 'Insufficient permissions';

      // Update official status
      await _firestore
          .collection('sai_officials')
          .doc(officialId)
          .update({
        'status': 'rejected',
        'approved': false,
        'rejectionReason': reason ?? 'Application did not meet requirements',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get official details for email
      final officialDoc = await _firestore
          .collection('sai_officials')
          .doc(officialId)
          .get();

      if (officialDoc.exists) {
        final officialData = officialDoc.data()!;

        // Send rejection email
        await EmailService.sendApprovalEmail(
          email: officialData['email'],
          name: officialData['fullName'],
          approved: false,
          reason: reason,
        );

        // Log rejection action
        await _logAdminAction(
          action: 'official_rejected',
          targetId: officialId,
          details: {
            'official_name': officialData['fullName'],
            'official_email': officialData['email'],
            'reason': reason ?? 'Not specified',
          },
        );
      }

      print('Official rejected successfully: $officialId');
    } catch (e) {
      print('Error rejecting official: $e');
      rethrow;
    }
  }

  // ==================== OFFICIAL MANAGEMENT ====================

  /// Get all SAI officials with filtering
  static Future<List<SAIOfficialModel>> getAllOfficials({
    String? status,
    String? designation,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('sai_officials')
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (designation != null) {
        query = query.where('designation', isEqualTo: designation);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => SAIOfficialModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all officials: $e');
      rethrow;
    }
  }

  /// Suspend an official
  static Future<void> suspendOfficial(String officialId, String reason) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Admin not authenticated';

      await _firestore
          .collection('sai_officials')
          .doc(officialId)
          .update({
        'status': 'suspended',
        'approved': false,
        'suspensionReason': reason,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedBy': currentUser.uid,
      });

      await _logAdminAction(
        action: 'official_suspended',
        targetId: officialId,
        details: {'reason': reason},
      );

      print('Official suspended: $officialId');
    } catch (e) {
      print('Error suspending official: $e');
      rethrow;
    }
  }

  /// Update official permissions
  static Future<void> updateOfficialPermissions(
      String officialId,
      Map<String, bool> permissions,
      ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Admin not authenticated';

      await _firestore
          .collection('sai_officials')
          .doc(officialId)
          .update({
        'permissions': permissions,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser.uid,
      });

      await _logAdminAction(
        action: 'permissions_updated',
        targetId: officialId,
        details: {'permissions': permissions},
      );

      print('Official permissions updated: $officialId');
    } catch (e) {
      print('Error updating permissions: $e');
      rethrow;
    }
  }

  // ==================== AUDIT & LOGGING ====================

  /// Log admin actions for audit trail
  static Future<void> _logAdminAction({
    required String action,
    required String targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final logData = {
        'action': action,
        'adminId': currentUser.uid,
        'adminEmail': currentUser.email,
        'targetId': targetId,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'ip': 'unknown', // In production, you'd capture real IP
      };

      await _firestore
          .collection('admin_logs')
          .add(logData);

    } catch (e) {
      print('Error logging admin action: $e');
      // Don't rethrow - logging failure shouldn't break main functionality
    }
  }

  /// Get admin activity logs
  static Future<List<Map<String, dynamic>>> getAdminLogs({
    int limit = 50,
    String? adminId,
    String? action,
  }) async {
    try {
      Query query = _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }

      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error getting admin logs: $e');
      return [];
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Get admin notifications (pending approvals, system alerts, etc.)
  static Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    try {
      final notifications = <Map<String, dynamic>>[];

      // Pending approvals notification
      final pendingCount = await _firestore
          .collection('sai_officials')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final pendingCountValue = pendingCount.count ?? 0;

      if (pendingCountValue > 0) {
        notifications.add({
          'type': 'pending_approvals',
          'title': 'Pending Approvals',
          'message': '$pendingCountValue officials awaiting approval',
          'count': pendingCountValue,
          'priority': 'high',
          'timestamp': DateTime.now(),
        });
      }

      // System health checks (placeholder)
      notifications.add({
        'type': 'system_health',
        'title': 'System Status',
        'message': 'All systems operational',
        'priority': 'info',
        'timestamp': DateTime.now(),
      });

      return notifications;
    } catch (e) {
      print('Error getting admin notifications: $e');
      return [];
    }
  }

  // ==================== BULK OPERATIONS ====================

  /// Bulk approve officials (for mass approvals)
  static Future<void> bulkApproveOfficials(List<String> officialIds) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Admin not authenticated';

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final officialId in officialIds) {
        final officialRef = _firestore
            .collection('sai_officials')
            .doc(officialId);

        batch.update(officialRef, {
          'status': 'approved',
          'approved': true,
          'approvedAt': Timestamp.fromDate(now),
          'approvedBy': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Log bulk action
      await _logAdminAction(
        action: 'bulk_approve',
        targetId: 'multiple',
        details: {
          'official_ids': officialIds,
          'count': officialIds.length,
        },
      );

      // Send emails to all approved officials
      for (final officialId in officialIds) {
        final officialDoc = await _firestore
            .collection('sai_officials')
            .doc(officialId)
            .get();

        if (officialDoc.exists) {
          final data = officialDoc.data()!;
          await EmailService.sendApprovalEmail(
            email: data['email'],
            name: data['fullName'],
            approved: true,
          );
        }
      }

      print('Bulk approved ${officialIds.length} officials');
    } catch (e) {
      print('Error in bulk approve: $e');
      rethrow;
    }
  }

  // ==================== ANALYTICS ====================

  /// Get approval analytics (approval rates, response times, etc.)
  static Future<Map<String, dynamic>> getApprovalAnalytics() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get recent applications
      final recentAppsSnapshot = await _firestore
          .collection('sai_officials')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final recentApps = recentAppsSnapshot.docs
          .map((doc) => SAIOfficialModel.fromJson(doc.data()))
          .toList();

      // Calculate metrics
      final totalApplications = recentApps.length;
      final approvedCount = recentApps.where((app) => app.status == 'approved').length;
      final rejectedCount = recentApps.where((app) => app.status == 'rejected').length;
      final pendingCount = recentApps.where((app) => app.status == 'pending').length;

      final approvalRate = totalApplications > 0 ? (approvedCount / totalApplications) * 100 : 0;

      // Calculate average approval time
      final approvedApps = recentApps.where((app) => app.status == 'approved' && app.approvedAt != null);
      double avgApprovalHours = 0;

      if (approvedApps.isNotEmpty) {
        final totalHours = approvedApps
            .map((app) => app.approvedAt!.difference(app.createdAt).inHours)
            .reduce((a, b) => a + b);
        avgApprovalHours = totalHours / approvedApps.length;
      }

      return {
        'totalApplications': totalApplications,
        'approvedCount': approvedCount,
        'rejectedCount': rejectedCount,
        'pendingCount': pendingCount,
        'approvalRate': approvalRate,
        'avgApprovalHours': avgApprovalHours,
        'periodDays': 30,
      };
    } catch (e) {
      print('Error getting approval analytics: $e');
      return {};
    }
  }
}