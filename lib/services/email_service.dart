import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send approval/rejection email to SAI official
  static Future<void> sendApprovalEmail({
    required String email,
    required String name,
    required bool approved,
    String? reason,
  }) async {
    try {
      // In production, this would integrate with your email service
      // For now, we'll store email requests in Firestore for processing

      final emailData = {
        'to': email,
        'template': approved ? 'official_approved' : 'official_rejected',
        'templateData': {
          'name': name,
          'approved': approved,
          'reason': reason,
          'loginUrl': 'https://your-app-domain.com/login',
          'supportEmail': 'support@sai.gov.in',
        },
        'subject': approved
            ? 'SAI Official Account Approved - Welcome to TalentFind'
            : 'SAI Official Account Application Update',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      // Add to email queue for processing by cloud function
      await _firestore.collection('email_queue').add(emailData);

      // Also create in-app notification
      await _createInAppNotification(
        email: email,
        title: approved ? 'Account Approved!' : 'Application Update',
        message: approved
            ? 'Your SAI official account has been approved. You can now access the platform.'
            : 'Your application has been reviewed. ${reason ?? 'Please contact support for details.'}',
        type: approved ? 'approval' : 'rejection',
      );

      print('Email queued for: $email (${approved ? 'approved' : 'rejected'})');
    } catch (e) {
      print('Error sending approval email: $e');
      // Don't rethrow - email failure shouldn't break approval process
    }
  }

  /// Send welcome email to new SAI official
  static Future<void> sendWelcomeEmail({
    required String email,
    required String name,
    required String designation,
  }) async {
    try {
      final emailData = {
        'to': email,
        'template': 'official_welcome',
        'templateData': {
          'name': name,
          'designation': designation,
          'dashboardUrl': 'https://your-app-domain.com/sai/dashboard',
          'guideUrl': 'https://your-app-domain.com/user-guide',
          'supportEmail': 'support@sai.gov.in',
        },
        'subject': 'Welcome to TalentFind - Your SAI Official Account is Ready',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      await _firestore.collection('email_queue').add(emailData);
      print('Welcome email queued for: $email');
    } catch (e) {
      print('Error sending welcome email: $e');
    }
  }

  /// Send notification to admins about new official signup
  static Future<void> notifyAdminsOfNewSignup({
    required String officialName,
    required String officialEmail,
    required String designation,
    required String department,
  }) async {
    try {
      // Get list of active admins
      final adminsSnapshot = await _firestore
          .collection('system_admins')
          .where('active', isEqualTo: true)
          .get();

      for (final adminDoc in adminsSnapshot.docs) {
        final adminData = adminDoc.data();
        final adminEmail = adminData['email'] as String?;

        if (adminEmail != null) {
          final emailData = {
            'to': adminEmail,
            'template': 'admin_new_signup',
            'templateData': {
              'adminName': adminData['name'] ?? 'Admin',
              'officialName': officialName,
              'officialEmail': officialEmail,
              'designation': designation,
              'department': department,
              'reviewUrl': 'https://your-app-domain.com/admin/approvals',
            },
            'subject': 'New SAI Official Signup - Review Required',
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          };

          await _firestore.collection('email_queue').add(emailData);
        }
      }

      print('Admin notification emails queued for new signup: $officialName');
    } catch (e) {
      print('Error notifying admins: $e');
    }
  }

  /// Create in-app notification
  static Future<void> _createInAppNotification({
    required String email,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final notificationData = {
        'userEmail': email,
        'title': title,
        'message': message,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      print('Error creating in-app notification: $e');
    }
  }

  /// Send system alert emails (for critical issues)
  static Future<void> sendSystemAlert({
    required String alertType,
    required String message,
    Map<String, dynamic>? details,
  }) async {
    try {
      final alertData = {
        'alertType': alertType,
        'message': message,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'severity': _getAlertSeverity(alertType),
      };

      // Store alert in database
      await _firestore.collection('system_alerts').add(alertData);

      // Send to admin emails if critical
      if (_getAlertSeverity(alertType) == 'critical') {
        final adminsSnapshot = await _firestore
            .collection('system_admins')
            .where('active', isEqualTo: true)
            .get();

        for (final adminDoc in adminsSnapshot.docs) {
          final adminEmail = adminDoc.data()['email'] as String?;

          if (adminEmail != null) {
            final emailData = {
              'to': adminEmail,
              'template': 'system_alert',
              'templateData': {
                'alertType': alertType,
                'message': message,
                'details': details?.toString() ?? '',
                'timestamp': DateTime.now().toIso8601String(),
              },
              'subject': 'CRITICAL: TalentFind System Alert - $alertType',
              'createdAt': FieldValue.serverTimestamp(),
              'status': 'pending',
              'priority': 'high',
            };

            await _firestore.collection('email_queue').add(emailData);
          }
        }
      }

      print('System alert sent: $alertType');
    } catch (e) {
      print('Error sending system alert: $e');
    }
  }

  /// Get alert severity based on type
  static String _getAlertSeverity(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'database_error':
      case 'auth_failure':
      case 'security_breach':
        return 'critical';
      case 'high_error_rate':
      case 'performance_issue':
        return 'warning';
      default:
        return 'info';
    }
  }

  /// Get email queue status (for admin monitoring)
  static Future<Map<String, dynamic>> getEmailQueueStatus() async {
    try {
      final pendingCount = await _firestore
          .collection('email_queue')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final failedCount = await _firestore
          .collection('email_queue')
          .where('status', isEqualTo: 'failed')
          .count()
          .get();

      final sentCount = await _firestore
          .collection('email_queue')
          .where('status', isEqualTo: 'sent')
          .count()
          .get();

      // Convert nullable ints to non-nullable with default value of 0
      final p = pendingCount.count ?? 0;
      final f = failedCount.count ?? 0;
      final s = sentCount.count ?? 0;

      return {
        'pending': p,
        'failed': f,
        'sent': s,
        'total': p + f + s,
      };
    } catch (e) {
      print('Error getting email queue status: $e');
      return {
        'pending': 0,
        'failed': 0,
        'sent': 0,
        'total': 0,
      };
    }
  }
}