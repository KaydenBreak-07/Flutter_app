import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import 'sai_dashboard.dart';
import '../auth/role_selection_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({Key? key}) : super(key: key);

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  Map<String, dynamic>? _officialData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfficialData();
    _startStatusListener();
  }

  // ADD THIS FUNCTION TO HANDLE BACK BUTTON
  void _handleBackButton() {
    // Sign out and navigate back to role selection
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
            (Route<dynamic> route) => false,
      );
    });
  }

  Future<void> _loadOfficialData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = await FirestoreService.getSAIOfficialProfile(user.uid);
        print('=== PENDING SCREEN DEBUG ===');
        print('User ID: ${user.uid}');
        print('Official data: $data');
        print('Status: ${data?['status']}');
        print('============================');

        setState(() {
          _officialData = data;
          _isLoading = false;
        });

        // IMMEDIATE CHECK: If already approved, navigate away
        if (data?['status'] == 'approved') {
          print('User is approved, navigating to SAI Dashboard');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SAIDashboard()),
          );
          return;
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading official data: $e');
    }
  }

  void _startStatusListener() {
    // Listen for status changes to automatically redirect when approved
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirestoreService.listenToOfficialStatus(user.uid).listen((status) {
        print('Status changed to: $status');
        if (status == 'approved' && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SAIDashboard()),
          );
        } else if (status == 'rejected' && mounted) {
          _showRejectionDialog();
        }
      });
    }
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Application Rejected',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unfortunately, your SAI official application has been rejected.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              if (_officialData?['rejectionReason'] != null) ...[
                const Text(
                  'Reason:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A2E6D),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _officialData!['rejectionReason'],
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can contact support@sai.gov.in for more information or to appeal this decision.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleBackButton();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    _handleBackButton();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2E6D)),
          ),
        ),
      );
    }

    final status = _officialData?['status'] ?? 'pending';
    final officialName = _officialData?['fullName'] ?? 'SAI Official';
    final submissionDate = _officialData?['createdAt'];

    return WillPopScope(
      // ADD WillPopScope TO HANDLE PHYSICAL BACK BUTTON
      onWillPop: () async {
        _handleBackButton();
        return false;
      },
      child: Scaffold(
        // ADD APP BAR WITH BACK BUTTON
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackButton,
          ),
          title: const Text('Pending Approval'),
          backgroundColor: const Color(0xFF0A2E6D),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    size: 60,
                    color: _getStatusColor(status),
                  ),
                ),

                const SizedBox(height: 32),

                // Status Title
                Text(
                  _getStatusTitle(status),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2E6D),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Status Message
                Text(
                  _getStatusMessage(status, officialName),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Application Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Application Details',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A2E6D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Name', officialName),
                      _buildDetailRow('Email', _officialData?['email'] ?? 'N/A'),
                      _buildDetailRow('Employee ID', _officialData?['employeeId'] ?? 'N/A'),
                      _buildDetailRow('Designation', _officialData?['designation'] ?? 'N/A'),
                      _buildDetailRow('Department', _officialData?['department'] ?? 'N/A'),
                      _buildDetailRow('Status', _getStatusDisplay(status)),
                      if (submissionDate != null)
                        _buildDetailRow('Submitted', _formatDate(submissionDate)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Information Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(
                        _getInfoMessage(status),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Refresh status
                          _loadOfficialData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A2E6D),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Refresh Status',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Color(0xFF0A2E6D),
                ),
              ),
            ),
          ],
        )
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'approved':
        return 'Account Approved!';
      case 'rejected':
        return 'Application Rejected';
      default:
        return 'Account Pending Approval';
    }
  }

  String _getStatusMessage(String status, String name) {
    switch (status) {
      case 'approved':
        return 'Congratulations $name! Your SAI official account has been approved.';
      case 'rejected':
        return 'Your application has been reviewed and unfortunately rejected.';
      default:
        return 'Your SAI official account is awaiting administrator approval. You will receive access once your credentials are verified.';
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'approved':
        return 'Approved ✓';
      case 'rejected':
        return 'Rejected ✗';
      default:
        return 'Pending Review ⏳';
    }
  }

  String _getInfoMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Contact your system administrator if this is taking longer than expected. Average approval time is 24-48 hours.';
      case 'rejected':
        return 'You can contact support@sai.gov.in for more information or to appeal this decision.';
      default:
        return 'Please wait while we verify your credentials and set up your account.';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}